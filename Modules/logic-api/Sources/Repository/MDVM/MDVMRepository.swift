//
//  MDVMRepository.swift
//  logic-api
//

import Foundation
import Security
import logic_business

/// Endpoint documentation for each method: see `wiki/backend-api.md`.
public protocol MDVMRepository {

  /// Returns stored MDVM registration values when both token and wi id are available.
  func getStoredRegistration() -> MDVMStoredRegistration?

  func fetchChallenge() async throws -> String

  func register(
    payload: MDVMRegistrationPayload,
    authChallenge: String,
    skipIntegrityChecks: Bool,
    privateKey: SecKey
  ) async throws

  func renew(
    payload: MDVMRenewalPayload,
    mdvmWIID: String,
    authChallenge: String,
    skipIntegrityChecks: Bool,
    privateKey: SecKey
  ) async throws
}

final class MDVMRepositoryImpl: MDVMRepository {

  private typealias SignedHeader = (name: String, value: String)
  private struct SigningResult {
    let contentDigest: String
    let signatureInput: String
    let signature: String
  }

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

  // MARK: - Challenge

  func fetchChallenge() async throws -> String {
    let result = try await networkManager.execute(with: MDVMChallengeRequest(), parameters: nil)
    guard let data = result.data else {
      throw MDVMRepositoryError.invalidResponse
    }
    let challengeResponse: MDVMChallengeResponse
    do {
      challengeResponse = try JSONDecoder().decode(MDVMChallengeResponse.self, from: data)
    } catch {
      throw MDVMRepositoryError.decodingFailed
    }
    return challengeResponse.mdvmAuthChallenge
  }

  // MARK: - Registration

  func getStoredRegistration() -> MDVMStoredRegistration? {
    guard
      let mdvmToken = secureEnclaveController.retrieveDecryptedString(keyTag: .mdvmToken), !mdvmToken.isEmpty,
      let mdvmWIID = secureEnclaveController.retrieveDecryptedString(keyTag: .mdvmWIID), !mdvmWIID.isEmpty
    else {
      return nil
    }
    return MDVMStoredRegistration(mdvmWIID: mdvmWIID, mdvmToken: mdvmToken)
  }

  func register(
    payload: MDVMRegistrationPayload,
    authChallenge: String,
    skipIntegrityChecks: Bool,
    privateKey: SecKey
  ) async throws {
    let storedRegistration = getStoredRegistration()
    let body = try JSONEncoder().encode(payload)
    let contentDigest = httpSignatureService.createContentDigest(for: body)
    let signing = try prepareSigning(
      path: MDVMConstants.Path.register,
      contentDigest: contentDigest,
      fields: MDVMConstants.Signature.registerFields,
      signedHeaders: [
        (MDVMConstants.Header.authChallenge, authChallenge),
        (MDVMConstants.Header.mdvmToken, storedRegistration?.mdvmToken ?? ""),
        (MDVMConstants.Header.contentDigest, contentDigest),
        (MDVMConstants.Header.skipIntegrityChecks, String(skipIntegrityChecks))
      ],
      privateKey: privateKey
    )
    let headers = makeRegisterHeaders(
      authChallenge: authChallenge,
      skipIntegrityChecks: skipIntegrityChecks,
      contentDigest: signing.contentDigest,
      signatureInput: signing.signatureInput,
      signature: signing.signature,
      mdvmToken: storedRegistration?.mdvmToken
    )

    let result = try await networkManager.execute(
      with: MDVMRegisterRequest(body: body, additionalHeaders: headers),
      parameters: nil
    )

    let response: MDVMRegistrationResponse = try decodeResponse(from: result.data)
    saveRegistration(mdvmWIID: response.mdvmWIID, mdvmToken: response.mdvmToken)
  }

  private func makeRegisterHeaders(
    authChallenge: String,
    skipIntegrityChecks: Bool,
    contentDigest: String,
    signatureInput: String,
    signature: String,
    mdvmToken: String?
  ) -> [String: String] {
    var headers = [
      MDVMConstants.Header.contentType: MDVMConstants.Header.ContentType.json,
      MDVMConstants.Header.authChallenge: authChallenge,
      MDVMConstants.Header.skipIntegrityChecks: String(skipIntegrityChecks),
      MDVMConstants.Header.contentDigest: contentDigest,
      MDVMConstants.Header.signatureInput: "\(MDVMConstants.Signature.name)=\(signatureInput)",
      MDVMConstants.Header.signature: "\(MDVMConstants.Signature.name)=:\(signature):"
    ]
    if let mdvmToken, !mdvmToken.isEmpty {
      headers[MDVMConstants.Header.mdvmToken] = mdvmToken
    }
    return headers
  }

  private func saveRegistration(mdvmWIID: String, mdvmToken: String) {
    _ = secureEnclaveController.storeEncryptedString(value: mdvmWIID, keyTag: .mdvmWIID)
    _ = secureEnclaveController.storeEncryptedString(value: mdvmToken, keyTag: .mdvmToken)
  }

  // MARK: - Renewal

  func renew(
    payload: MDVMRenewalPayload,
    mdvmWIID: String,
    authChallenge: String,
    skipIntegrityChecks: Bool,
    privateKey: SecKey
  ) async throws {
    let body = try JSONEncoder().encode(payload)
    let contentDigest = httpSignatureService.createContentDigest(for: body)
    let signing = try prepareSigning(
      path: MDVMConstants.Path.renewal,
      contentDigest: contentDigest,
      fields: MDVMConstants.Signature.renewalFields,
      signedHeaders: [
        (MDVMConstants.Header.mdvmWIID, mdvmWIID),
        (MDVMConstants.Header.authChallenge, authChallenge),
        (MDVMConstants.Header.contentDigest, contentDigest),
        (MDVMConstants.Header.skipIntegrityChecks, String(skipIntegrityChecks))
      ],
      privateKey: privateKey
    )
    let headers = makeRenewalHeaders(
      mdvmWIID: mdvmWIID,
      authChallenge: authChallenge,
      skipIntegrityChecks: skipIntegrityChecks,
      contentDigest: signing.contentDigest,
      signatureInput: signing.signatureInput,
      signature: signing.signature
    )

    let result = try await networkManager.execute(
      with: MDVMRenewalRequest(body: body, additionalHeaders: headers),
      parameters: nil
    )

    let response: MDVMRenewalResponse = try decodeResponse(from: result.data)
    saveRegistration(mdvmWIID: mdvmWIID, mdvmToken: response.mdvmToken)
  }

  private func makeRenewalHeaders(
    mdvmWIID: String,
    authChallenge: String,
    skipIntegrityChecks: Bool,
    contentDigest: String,
    signatureInput: String,
    signature: String
  ) -> [String: String] {
    [
      MDVMConstants.Header.contentType: MDVMConstants.Header.ContentType.json,
      MDVMConstants.Header.mdvmWIID: mdvmWIID,
      MDVMConstants.Header.authChallenge: authChallenge,
      MDVMConstants.Header.skipIntegrityChecks: String(skipIntegrityChecks),
      MDVMConstants.Header.contentDigest: contentDigest,
      MDVMConstants.Header.signatureInput: "\(MDVMConstants.Signature.name)=\(signatureInput)",
      MDVMConstants.Header.signature: "\(MDVMConstants.Signature.name)=:\(signature):"
    ]
  }

  // MARK: - Helpers

  private func decodeResponse<T: Decodable>(from data: Data?) throws -> T {
    guard let data else {
      throw MDVMRepositoryError.invalidResponse
    }

    if let errorResponse = try? JSONDecoder().decode(MDVMErrorResponse.self, from: data) {
      logger?.e("MDVM serverError code=\(errorResponse.code) traceID=\(errorResponse.traceID ?? "")")
      throw MDVMRepositoryError.serverError(
        code: errorResponse.code,
        description: errorResponse.description,
        traceID: errorResponse.traceID ?? ""
      )
    }

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw MDVMRepositoryError.decodingFailed
    }
  }

  private func prepareSigning(
    path: String,
    contentDigest: String,
    fields: [String],
    signedHeaders: [SignedHeader],
    privateKey: SecKey
  ) throws -> SigningResult {
    let signatureInput = httpSignatureService.createSignatureInput(
      fields: fields,
      keyID: MDVMConstants.Signature.keyID,
      algorithm: MDVMConstants.Signature.algorithm
    )
    let signatureBase = httpSignatureService.createSignatureBase(
      method: MDVMConstants.Header.Method.post,
      path: "/\(path)",
      signedHeaders: signedHeaders,
      signatureInput: signatureInput
    )
    let signature = try createSignature(base: signatureBase, privateKey: privateKey)
    return SigningResult(
      contentDigest: contentDigest,
      signatureInput: signatureInput,
      signature: signature
    )
  }

  private func createSignature(base: String, privateKey: SecKey) throws -> String {
    do {
      return try httpSignatureService.createSignature(
        base: base,
        privateKey: privateKey,
        algorithm: .ecdsaSignatureMessageX962SHA256
      )
    } catch {
      throw MDVMRepositoryError.signingFailed
    }
  }
}
