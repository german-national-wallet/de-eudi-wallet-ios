//
//  WPBRepository.swift
//  wallet-backend
//

import Foundation
import Security
import logic_api
import logic_business

public protocol WPBRepository {
  func fetchChallenge() async throws -> String
  func getStoredWIID() -> String?
  func storeWIID(_ wiid: String)
  func deleteWIID()
  func storeRevocationCode(_ revocationCode: String)
  func deleteRevocationCode()
  func register(
    mdvmToken: String,
    authChallenge: String
  ) async throws -> WPBRegisterResponse
  func issueAttestation(
    mdvmToken: String,
    authChallenge: String,
    wbWIID: String,
    wiaPrivateKey: SecKey
  ) async throws -> WPBAttestationResponse
  func deleteAccount(
    mdvmToken: String,
    authChallenge: String,
    wbWIID: String
  ) async throws
}

public final class WPBRepositoryImpl: WPBRepository {

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
    let result = try await networkManager.execute(with: WPBChallengeRequest(), parameters: nil)
    let response: WPBChallengeResponse = try decodeResponse(from: result.data)
    return response.wbAuthChallenge
  }

  public func getStoredWIID() -> String? {
    guard let wiid = secureEnclaveController.retrieveDecryptedString(keyTag: .wbWIID), !wiid.isEmpty else {
      return nil
    }
    return wiid
  }

  public func storeWIID(_ wiid: String) {
    _ = secureEnclaveController.storeEncryptedString(value: wiid, keyTag: .wbWIID)
  }

  public func deleteWIID() {
    secureEnclaveController.deleteKeychainItem(keyTag: .wbWIID)
  }

  public func storeRevocationCode(_ revocationCode: String) {
    _ = secureEnclaveController.storeEncryptedString(value: revocationCode, keyTag: .wpbWiRevocationCode)
  }

  public func deleteRevocationCode() {
    secureEnclaveController.deleteKeychainItem(keyTag: .wpbWiRevocationCode)
  }

  public func register(
    mdvmToken: String,
    authChallenge: String
  ) async throws -> WPBRegisterResponse {
    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: WPBConstants.Header.Method.post,
        path: WPBConstants.Path.register,
        headers: [
          WPBConstants.Header.authChallenge: authChallenge,
          WPBConstants.Header.mdvmToken: mdvmToken
        ],
        contentTypeHeader: nil
      ),
      signatures: [
        HTTPMessageSignature(
          name: WPBConstants.Signature.nameAuthSig,
          keyID: WPBConstants.Signature.keyID,
          algorithm: WPBConstants.Signature.algorithm,
          fields: WPBConstants.Signature.registerFields,
          privateKey: mdvmPrivateKey,
        )
      ]
    )

    let result = try await networkManager.execute(
      with: WPBRegisterRequest(additionalHeaders: headers),
      parameters: nil
    )
    return try decodeResponse(from: result.data)
  }

  public func issueAttestation(
    mdvmToken: String,
    authChallenge: String,
    wbWIID: String,
    wiaPrivateKey: SecKey
  ) async throws -> WPBAttestationResponse {
    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    let wiaPublicKey = try secureEnclaveController.getPublicKeyInfo(from: wiaPrivateKey).derBase64
    let payload = WPBAttestationPayload(wiWIAPublicKey: wiaPublicKey)
    let body = try JSONEncoder().encode(payload)
    let contentDigest = httpSignatureService.createContentDigest(for: body)
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: WPBConstants.Header.Method.post,
        path: WPBConstants.Path.attestation,
        headers: [
          WPBConstants.Header.wbWIID: wbWIID,
          WPBConstants.Header.authChallenge: authChallenge,
          WPBConstants.Header.mdvmToken: mdvmToken,
          WPBConstants.Header.contentDigest: contentDigest
        ],
        contentTypeHeader: HTTPHeader(
          name: WPBConstants.Header.contentType,
          value: WPBConstants.Header.ContentType.json
        )
      ),
      signatures: [
        HTTPMessageSignature(
          name: WPBConstants.Signature.nameAuthSig,
          keyID: WPBConstants.Signature.keyID,
          algorithm: WPBConstants.Signature.algorithm,
          fields: WPBConstants.Signature.attestationFields,
          privateKey: mdvmPrivateKey,
        ),
        HTTPMessageSignature(
          name: WPBConstants.Signature.nameWIASig,
          keyID: WPBConstants.Signature.keyIDWIA,
          algorithm: WPBConstants.Signature.algorithm,
          fields: WPBConstants.Signature.attestationFields,
          privateKey: wiaPrivateKey,
        )
      ]
    )

    let result = try await networkManager.execute(
      with: WPBAttestationRequest(body: body, additionalHeaders: headers),
      parameters: nil
    )
    return try decodeResponse(from: result.data)
  }

  public func deleteAccount(
    mdvmToken: String,
    authChallenge: String,
    wbWIID: String
  ) async throws {
    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: WPBConstants.Header.Method.delete,
        path: WPBConstants.Path.deleteAccount,
        headers: [
          WPBConstants.Header.wbWIID: wbWIID,
          WPBConstants.Header.authChallenge: authChallenge,
          WPBConstants.Header.mdvmToken: mdvmToken
        ],
        contentTypeHeader: nil
      ),
      signatures: [
        HTTPMessageSignature(
          name: WPBConstants.Signature.nameAuthSig,
          keyID: WPBConstants.Signature.keyID,
          algorithm: WPBConstants.Signature.algorithm,
          fields: WPBConstants.Signature.deleteAccountFields,
          privateKey: mdvmPrivateKey,
        )
      ]
    )

    let result = try await networkManager.execute(
      with: WPBDeleteAccountRequest(additionalHeaders: headers),
      parameters: nil
    )
    try validateEmptyResponse(result.data)
  }

  private func decodeResponse<T: Decodable>(from data: Data?) throws -> T {
    guard let data else {
      throw WPBRepositoryError.invalidResponse
    }

    if let errorResponse = try? JSONDecoder().decode(WPBErrorResponse.self, from: data) {
      logger?.e("WPB serverError code=\(errorResponse.code) traceID=\(errorResponse.traceID ?? "")")
      throw WPBRepositoryError.serverError(
        code: errorResponse.code,
        description: errorResponse.description ?? "",
        traceID: errorResponse.traceID ?? ""
      )
    }

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw WPBRepositoryError.decodingFailed
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
        throw WPBRepositoryError.signingFailed
      case .missingSignedHeader(let field):
        throw WPBRepositoryError.missingSignedHeader(field)
      case .signingFailed:
        throw WPBRepositoryError.signingFailed
      }
    }
  }

  private func validateEmptyResponse(_ data: Data?) throws {
    guard let data, !data.isEmpty else {
      return
    }

    if let errorResponse = try? JSONDecoder().decode(WPBErrorResponse.self, from: data) {
      logger?.e("WPB serverError code=\(errorResponse.code) traceID=\(errorResponse.traceID ?? "")")
      throw WPBRepositoryError.serverError(
        code: errorResponse.code,
        description: errorResponse.description ?? "",
        traceID: errorResponse.traceID ?? ""
      )
    }

    throw WPBRepositoryError.decodingFailed
  }
}
