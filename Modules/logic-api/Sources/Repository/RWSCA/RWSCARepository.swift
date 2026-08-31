//
//  RWSCARepository.swift
//  logic-api
//

import Foundation
import Security
import logic_business

/// Endpoint documentation for each method: see `wiki/backend-api.md`.
public protocol RWSCARepository {
  func fetchChallenge() async throws -> String

  func register(mdvmToken: String, authChallenge: String, privateKey: SecKey) async throws

  func getRWSCAID() -> String?

  func startPinSession(mdvmToken: String, challenge: String, privateKey: SecKey, pinPrivateKey: SecKey, rwscaID: String) async throws -> RWSCAPinSessionResponse

  func initializePinAndStartPinSession(mdvmToken: String, challenge: String, rwscaID: String, pinPrivateKey: SecKey, mdvmPrivateKey: SecKey, payload: RWSCAInitializePinAndStartPinSessionPayload) async throws -> RWSCAPinSessionResponse

  func createKeys(mdvmToken: String, challenge: String, rwscaID: String, mdvmPrivateKey: SecKey, payload: RWSCACreateKeysPayload) async throws -> RWSCACreateKeysResponse

  func signData(mdvmToken: String, challenge: String, rwscaID: String, pinSessionToken: String, mdvmPrivateKey: SecKey, payload: RWSCASignDataPayload) async throws -> RWSCASignDataResponse

  func deleteAccount(mdvmToken: String, challenge: String, rwscaID: String, mdvmPrivateKey: SecKey) async throws
}

public final class RWSCARepositoryImpl: RWSCARepository {

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
    let result = try await networkManager.execute(with: RWSCAChallengeRequest(), parameters: nil)
    return try (decodeResponse(from: result.data) as RWSCAChallengeResponse).rwscaAuthChallenge
  }

  public func register(mdvmToken: String, authChallenge: String, privateKey: SecKey) async throws {
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.post,
        path: RWSCAConstants.Path.register,
        headers: [
          RWSCAConstants.Header.authChallenge: authChallenge,
          RWSCAConstants.Header.mdvmToken: mdvmToken
        ],
        contentTypeHeader: nil
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.registerFields,
          privateKey: privateKey
        )
      ]
    )

    let result = try await networkManager.execute(
      with: RWSCARegisterRequest(additionalHeaders: headers),
      parameters: nil
    )

    let response: RWSCARegistrationResponse = try decodeResponse(from: result.data)
    _ = secureEnclaveController.storeEncryptedString(
      value: response.rwscaAccountID,
      keyTag: .rwscaAccountID
    )
  }

  public func startPinSession(mdvmToken: String, challenge: String, privateKey: SecKey, pinPrivateKey: SecKey, rwscaID: String) async throws -> RWSCAPinSessionResponse {
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.post,
        path: RWSCAConstants.Path.startPinSession,
        headers: [
          RWSCAConstants.Header.authChallenge: challenge,
          RWSCAConstants.Header.mdvmToken: mdvmToken,
          RWSCAConstants.Header.rwscaAccountId: rwscaID
        ],
        contentTypeHeader: nil
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.startPinSessionFields,
          privateKey: privateKey
        ),
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.namePinSig,
          keyID: RWSCAConstants.Signature.keyIDPin,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.startPinSessionFields,
          privateKey: pinPrivateKey
        )
      ]
    )

    let result = try await networkManager.execute(
      with: RWSCAPinSessionRequest(
        body: nil,
        additionalHeaders: headers,
        path: RWSCAConstants.Path.startPinSession
      ),
      parameters: nil
    )

    let response: RWSCAPinSessionResponse = try decodeResponse(from: result.data)
    return response
  }

  public func initializePinAndStartPinSession(mdvmToken: String, challenge: String, rwscaID: String, pinPrivateKey: SecKey, mdvmPrivateKey: SecKey, payload: RWSCAInitializePinAndStartPinSessionPayload) async throws -> RWSCAPinSessionResponse {
    let body = try JSONEncoder().encode(payload)
    let contentDigest = httpSignatureService.createContentDigest(for: body)
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.post,
        path: RWSCAConstants.Path.initializePinAndStartPinSession,
        headers: [
          RWSCAConstants.Header.authChallenge: challenge,
          RWSCAConstants.Header.mdvmToken: mdvmToken,
          RWSCAConstants.Header.rwscaAccountId: rwscaID,
          RWSCAConstants.Header.contentDigest: contentDigest
        ],
        contentTypeHeader: HTTPHeader(
          name: RWSCAConstants.Header.contentType,
          value: RWSCAConstants.Header.ContentType.json
        )
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
          privateKey: mdvmPrivateKey
        ),
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.namePinSig,
          keyID: RWSCAConstants.Signature.keyIDPin,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
          privateKey: pinPrivateKey
        )
      ]
    )

    let result = try await networkManager.execute(
      with: RWSCAPinSessionRequest(
        body: body,
        additionalHeaders: headers,
        path: RWSCAConstants.Path.initializePinAndStartPinSession
      ),
      parameters: nil
    )

    let response: RWSCAPinSessionResponse = try decodeResponse(from: result.data)
    return response
  }

  public func createKeys(
    mdvmToken: String,
    challenge: String,
    rwscaID: String,
    mdvmPrivateKey: SecKey,
    payload: RWSCACreateKeysPayload
  ) async throws -> RWSCACreateKeysResponse {
    let body = try JSONEncoder().encode(payload)
    let contentDigest = httpSignatureService.createContentDigest(for: body)
    // createKeys uses only the MDVM possession-factor key for HTTP message signing.
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.post,
        path: RWSCAConstants.Path.createKeys,
        headers: [
          RWSCAConstants.Header.authChallenge: challenge,
          RWSCAConstants.Header.mdvmToken: mdvmToken,
          RWSCAConstants.Header.rwscaAccountId: rwscaID,
          RWSCAConstants.Header.contentDigest: contentDigest
        ],
        contentTypeHeader: HTTPHeader(
          name: RWSCAConstants.Header.contentType,
          value: RWSCAConstants.Header.ContentType.json
        )
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.createKeysFields,
          // This private key is the MDVM-attested possession factor used for HTTP message signing.
          privateKey: mdvmPrivateKey
        )
      ]
    )

    let result = try await networkManager.execute(
      with: RWSCACreateKeysRequest(body: body, additionalHeaders: headers),
      parameters: nil
    )

    let response: RWSCACreateKeysResponse = try decodeResponse(from: result.data)
    return response
  }

  public func signData(
    mdvmToken: String,
    challenge: String,
    rwscaID: String,
    pinSessionToken: String,
    mdvmPrivateKey: SecKey,
    payload: RWSCASignDataPayload
  ) async throws -> RWSCASignDataResponse {
    let body = try JSONEncoder().encode(payload)
    let contentDigest = httpSignatureService.createContentDigest(for: body)
    // signData combines the MDVM possession-factor signature with the short-lived PIN session token.
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.post,
        path: RWSCAConstants.Path.signData,
        headers: [
          RWSCAConstants.Header.authChallenge: challenge,
          RWSCAConstants.Header.mdvmToken: mdvmToken,
          RWSCAConstants.Header.rwscaAccountId: rwscaID,
          RWSCAConstants.Header.rwscaPinSessionToken: pinSessionToken,
          RWSCAConstants.Header.contentDigest: contentDigest
        ],
        contentTypeHeader: HTTPHeader(
          name: RWSCAConstants.Header.contentType,
          value: RWSCAConstants.Header.ContentType.json
        )
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.signDataFields,
          // This private key is the MDVM-attested possession factor used for HTTP message signing.
          privateKey: mdvmPrivateKey
        )
      ]
    )

    let result = try await networkManager.execute(
      with: RWSCASignDataRequest(body: body, additionalHeaders: headers),
      parameters: nil
    )

    let response: RWSCASignDataResponse = try decodeResponse(from: result.data)
    return response
  }

  public func deleteAccount(
    mdvmToken: String,
    challenge: String,
    rwscaID: String,
    mdvmPrivateKey: SecKey
  ) async throws {
    let headers = try makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.delete,
        path: RWSCAConstants.Path.deleteAccount,
        headers: [
          RWSCAConstants.Header.authChallenge: challenge,
          RWSCAConstants.Header.mdvmToken: mdvmToken,
          RWSCAConstants.Header.rwscaAccountId: rwscaID
        ],
        contentTypeHeader: nil
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.deleteAccountFields,
          privateKey: mdvmPrivateKey
        )
      ]
    )

    let result = try await networkManager.execute(
      with: RWSCADeleteAccountRequest(additionalHeaders: headers),
      parameters: nil
    )

    try validateDeleteAccountResponse(result.data)
    secureEnclaveController.deleteKeychainItem(keyTag: .rwscaAccountID)
  }

  public func getRWSCAID() -> String? {
    guard let rwscaAccountID = secureEnclaveController.retrieveDecryptedString(keyTag: .rwscaAccountID),
          !rwscaAccountID.isEmpty else {
      return nil
    }
    return rwscaAccountID
  }

  private func decodeResponse<T: Decodable>(from data: Data?) throws -> T {
    guard let data else {
      throw RWSCARepositoryError.invalidResponse
    }

    if let errorResponse = try? JSONDecoder().decode(MDVMErrorResponse.self, from: data) {
      logger?.e("RWSCA serverError code=\(errorResponse.code) traceID=\(errorResponse.traceID ?? "")")
      throw RWSCARepositoryError.serverError(
        code: errorResponse.code,
        description: errorResponse.description,
        traceID: errorResponse.traceID ?? ""
      )
    }

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw RWSCARepositoryError.decodingFailed
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
        throw RWSCARepositoryError.signingFailed
      case .missingSignedHeader(let field):
        throw RWSCARepositoryError.missingSignedHeader(field)
      case .signingFailed:
        throw RWSCARepositoryError.signingFailed
      }
    }
  }

  private func validateDeleteAccountResponse(_ data: Data?) throws {
    guard let data, !data.isEmpty else {
      return
    }

    if let errorResponse = try? JSONDecoder().decode(MDVMErrorResponse.self, from: data) {
      logger?.e("RWSCA serverError code=\(errorResponse.code) traceID=\(errorResponse.traceID ?? "")")
      throw RWSCARepositoryError.serverError(
        code: errorResponse.code,
        description: errorResponse.description,
        traceID: errorResponse.traceID ?? ""
      )
    }

    throw RWSCARepositoryError.decodingFailed
  }
}
