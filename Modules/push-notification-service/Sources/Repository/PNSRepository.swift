//
//  PNSRepository.swift
//  push-notification-service
//

import Foundation
import Security
import logic_api
import logic_business

public protocol PNSRepository {
  /// Fetches the unauthenticated `pns_auth_challenge`. The WI treats it as an opaque string.
  func fetchChallenge() async throws -> String

  /// Creates or refreshes the account for this Wallet Instance by storing the
  /// `mpp_registration_token` at the PNS, authenticated with the `wi_pns_auth_pop`.
  func register(
    mppRegistrationToken: String,
    mdvmToken: String,
    authChallenge: String
  ) async throws

  func getStoredRegistration() -> PNSStoredRegistration?
  func storeRegistration(_ registration: PNSStoredRegistration)
  func deleteStoredRegistration()
}

public final class PNSRepositoryImpl: PNSRepository {

  private let networkManager: NetworkManager
  private let httpSignatureService: HTTPSignatureService
  private let secureEnclaveController: SecureEnclaveController
  private let logger: Logging?

  init(
    networkManager: NetworkManager,
    httpSignatureService: HTTPSignatureService,
    secureEnclaveController: SecureEnclaveController,
    logger: Logging? = nil
  ) {
    self.networkManager = networkManager
    self.httpSignatureService = httpSignatureService
    self.secureEnclaveController = secureEnclaveController
    self.logger = logger
  }

  public func fetchChallenge() async throws -> String {
    let result = try await networkManager.execute(with: PNSChallengeRequest(), parameters: nil)
    let response: PNSChallengeResponse = try decodeResponse(from: result.data)
    return response.pnsAuthChallenge
  }

  public func register(
    mppRegistrationToken: String,
    mdvmToken: String,
    authChallenge: String
  ) async throws {
    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    let payload = PNSRegisterPayload(mppRegistrationToken: mppRegistrationToken)
    let body = try JSONEncoder().encode(payload)
    let contentDigest = httpSignatureService.createContentDigest(for: body)
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: PNSConstants.Header.Method.post,
        path: PNSConstants.Path.register,
        headers: [
          PNSConstants.Header.authChallenge: authChallenge,
          PNSConstants.Header.mdvmToken: mdvmToken,
          PNSConstants.Header.contentDigest: contentDigest
        ],
        contentTypeHeader: HTTPHeader(
          name: PNSConstants.Header.contentType,
          value: PNSConstants.Header.ContentType.json
        )
      ),
      signatures: [
        HTTPMessageSignature(
          name: PNSConstants.Signature.nameAuthSig,
          keyID: PNSConstants.Signature.keyID,
          algorithm: PNSConstants.Signature.algorithm,
          fields: PNSConstants.Signature.registerFields,
          privateKey: mdvmPrivateKey
        )
      ]
    )

    let result = try await networkManager.execute(
      with: PNSRegisterRequest(body: body, additionalHeaders: headers),
      parameters: nil
    )
    try validateConfirmation(result)
  }

  // MARK: - Local registration state

  public func getStoredRegistration() -> PNSStoredRegistration? {
    guard
      let stored = secureEnclaveController.retrieveDecryptedString(keyTag: .mppRegistrationToken),
      let data = stored.data(using: .utf8),
      let registration = try? Self.decoder.decode(PNSStoredRegistration.self, from: data),
      !registration.mppRegistrationToken.isEmpty
    else {
      return nil
    }
    return registration
  }

  public func storeRegistration(_ registration: PNSStoredRegistration) {
    guard
      let data = try? Self.encoder.encode(registration),
      let value = String(data: data, encoding: .utf8)
    else {
      logger?.e("[PNS] unable to encode the local registration record")
      return
    }
    _ = secureEnclaveController.storeEncryptedString(value: value, keyTag: .mppRegistrationToken)
  }

  public func deleteStoredRegistration() {
    secureEnclaveController.deleteKeychainItem(keyTag: .mppRegistrationToken)
  }

  // MARK: - Helpers

  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }()

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()

  private func decodeResponse<T: Decodable>(from data: Data?) throws -> T {
    guard let data else {
      throw PNSRepositoryError.invalidResponse
    }

    if let errorResponse = try? JSONDecoder().decode(PNSErrorResponse.self, from: data) {
      logger?.e("PNS serverError code=\(errorResponse.code) traceID=\(errorResponse.traceID ?? "")")
      throw PNSRepositoryError.serverError(
        code: errorResponse.code,
        description: errorResponse.description ?? "",
        traceID: errorResponse.traceID ?? ""
      )
    }

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw PNSRepositoryError.decodingFailed
    }
  }

  private func validateConfirmation(_ response: NetworkResponse) throws {
    if let data = response.data, !data.isEmpty {
      if let errorResponse = try? JSONDecoder().decode(PNSErrorResponse.self, from: data) {
        logger?.e("PNS serverError code=\(errorResponse.code) traceID=\(errorResponse.traceID ?? "")")
        throw PNSRepositoryError.serverError(
          code: errorResponse.code,
          description: errorResponse.description ?? "",
          traceID: errorResponse.traceID ?? ""
        )
      }
    }

    guard response.isSuccessStatusCode else {
      logger?.e("PNS register was not confirmed, status=\(response.statusCode.map(String.init) ?? "none")")
      throw PNSRepositoryError.invalidResponse
    }
  }

  private func makeSignatureHeaders(
    context: HTTPMessageSigningContext,
    signatures: [HTTPMessageSignature]
  ) throws -> [String: String] {
    do {
      return try httpSignatureService.makeSignatureHeaders(
        context: context,
        signatures: signatures
      )
    } catch let error as HTTPMessageSigningError {
      switch error {
      case .missingSignatures:
        throw PNSRepositoryError.signingFailed
      case .missingSignedHeader(let field):
        throw PNSRepositoryError.missingSignedHeader(field)
      case .signingFailed:
        throw PNSRepositoryError.signingFailed
      }
    }
  }
}
