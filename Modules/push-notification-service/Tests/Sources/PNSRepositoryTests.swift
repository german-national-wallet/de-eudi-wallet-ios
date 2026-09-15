//
//  PNSRepositoryTests.swift
//  push-notification-service
//

import Foundation
import Security
import Testing

@testable import push_notification_service
@testable import logic_api
@testable import logic_business

struct PNSRepositoryTests {

  // MARK: - fetchChallenge

  @Test
  func fetchChallenge_WhenResponseIsValid_ReturnsChallenge() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"pns_auth_challenge":"pns-challenge-abc"}"#.utf8Data,
      headers: nil
    )

    #expect(try await sut.fetchChallenge() == "pns-challenge-abc")
  }

  @Test
  func fetchChallenge_WhenResponseDataIsNil_ThrowsInvalidResponse() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: nil, headers: nil)

    await #expect(throws: PNSRepositoryError.invalidResponse) {
      _ = try await sut.fetchChallenge()
    }
  }

  @Test
  func fetchChallenge_WhenServerReturnsError_ThrowsServerError() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"code":"PNS_CHALLENGE_ERROR","description":"failed","trace_id":"t-1"}"#.utf8Data,
      headers: nil
    )

    await #expect(
      throws: PNSRepositoryError.serverError(code: "PNS_CHALLENGE_ERROR", description: "failed", traceID: "t-1")
    ) {
      _ = try await sut.fetchChallenge()
    }
  }

  // MARK: - register

  @Test
  func register_WhenResponseIsEmptyWithSuccessStatus_CompletesWithoutThrowing() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: Data(), headers: nil, statusCode: 200)

    try await sut.register(
      mppRegistrationToken: "mpp-token",
      mdvmToken: "mdvm-token",
      authChallenge: "challenge"
    )
  }

  @Test
  func register_SendsTokenInBodyAndSignsTheRequiredComponents() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: Data(), headers: nil, statusCode: 200)

    try await sut.register(
      mppRegistrationToken: "mpp-token",
      mdvmToken: "mdvm-token",
      authChallenge: "challenge"
    )

    let headers = try #require(network.capturedHeaders)
    #expect(headers["auth-challenge"] == "challenge")
    #expect(headers["mdvm-token"] == "mdvm-token")
    #expect(headers["Content-Type"] == "application/json")
    #expect(headers["Content-Digest"]?.hasPrefix("sha-256=:") == true)

    let signatureInput = try #require(headers["Signature-Input"])
    #expect(signatureInput.hasPrefix("pns-auth-sig="))
    #expect(signatureInput.contains(#""@method" "@path" "auth-challenge" "mdvm-token" "content-digest""#))
    #expect(signatureInput.contains(#"keyid="wi-mdvm-auth-key""#))
    #expect(signatureInput.contains(#"alg="ecdsa-p256-sha256""#))
    #expect(headers["Signature"]?.hasPrefix("pns-auth-sig=:") == true)

    let body = try #require(network.capturedBody)
    #expect(body == #"{"mpp_registration_token":"mpp-token"}"#.utf8Data)
  }

  @Test
  func register_WhenServerReturnsError_ThrowsServerError() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"code":"PNS_REG_ERROR","description":"rejected","trace_id":"t-2"}"#.utf8Data,
      headers: nil
    )

    await #expect(
      throws: PNSRepositoryError.serverError(code: "PNS_REG_ERROR", description: "rejected", traceID: "t-2")
    ) {
      try await sut.register(
        mppRegistrationToken: "mpp-token",
        mdvmToken: "mdvm-token",
        authChallenge: "challenge"
      )
    }
  }

  @Test
  func register_WhenServerRejectsWithAnEmptyBody_ThrowsInvalidResponse() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    /// `NetworkManager` surfaces non-2xx responses as values, and a 401 from the PNS carries no
    /// body, so nothing but the status code distinguishes this from a successful registration.
    /// Reading it as success would persist a registration that does not exist at the PNS and
    /// suppress every retry until the renewal interval elapsed.
    network.mockResponse = NetworkResponse(data: Data(), headers: nil, statusCode: 401)

    await #expect(throws: PNSRepositoryError.invalidResponse) {
      try await sut.register(
        mppRegistrationToken: "mpp-token",
        mdvmToken: "mdvm-token",
        authChallenge: "challenge"
      )
    }
  }

  @Test
  func register_WhenRedirectedWithoutABody_ThrowsInvalidResponse() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: nil, headers: [:], statusCode: 302)

    await #expect(throws: PNSRepositoryError.invalidResponse) {
      try await sut.register(
        mppRegistrationToken: "mpp-token",
        mdvmToken: "mdvm-token",
        authChallenge: "challenge"
      )
    }
  }

  @Test
  func register_WhenResponseBodyIsUnrecognisedWithSuccessStatus_Completes() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: #"{"unexpected":true}"#.utf8Data, headers: nil, statusCode: 200)

    try await sut.register(
      mppRegistrationToken: "mpp-token",
      mdvmToken: "mdvm-token",
      authChallenge: "challenge"
    )
  }

  // MARK: - Local registration state

  @Test
  func getStoredRegistration_WhenNothingStored_ReturnsNil() {
    #expect(makeSUT().getStoredRegistration() == nil)
  }

  @Test
  func storeRegistration_ThenGetStoredRegistration_RoundTripsTokenAndTimestamp() {
    let sut = makeSUT()
    /// Truncated to whole seconds: the record is persisted as an ISO 8601 string.
    let registeredAt = Date(timeIntervalSince1970: 1_770_000_000)
    let registration = PNSStoredRegistration(mppRegistrationToken: "mpp-token", registeredAt: registeredAt)

    sut.storeRegistration(registration)

    #expect(sut.getStoredRegistration() == registration)
  }

  @Test
  func getStoredRegistration_WhenStoredTokenIsEmpty_ReturnsNil() {
    let sut = makeSUT()
    sut.storeRegistration(PNSStoredRegistration(mppRegistrationToken: "", registeredAt: Date()))

    #expect(sut.getStoredRegistration() == nil)
  }

  @Test
  func getStoredRegistration_WhenStoredValueIsNotARecord_ReturnsNil() {
    let secureEnclave = FakeSecureEnclaveController()
    let sut = makeSUT(secureEnclave: secureEnclave)
    /// Guards the migration case: before this record existed the tag could hold a bare token.
    _ = secureEnclave.storeEncryptedString(value: "bare-legacy-token", keyTag: .mppRegistrationToken)

    #expect(sut.getStoredRegistration() == nil)
  }

  @Test
  func deleteStoredRegistration_AfterStoring_ReturnsNil() {
    let sut = makeSUT()
    sut.storeRegistration(PNSStoredRegistration(mppRegistrationToken: "mpp-token", registeredAt: Date()))

    sut.deleteStoredRegistration()

    #expect(sut.getStoredRegistration() == nil)
  }

  // MARK: - Helpers

  private func makeSUT(
    network: FakeNetworkManager = FakeNetworkManager(),
    secureEnclave: FakeSecureEnclaveController = FakeSecureEnclaveController()
  ) -> PNSRepositoryImpl {
    PNSRepositoryImpl(
      networkManager: network,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: secureEnclave
    )
  }
}

private final class FakeNetworkManager: NetworkManager, @unchecked Sendable {
  var mockResponse: NetworkResponse?
  var error: Error?
  var capturedHeaders: [String: String]?
  var capturedBody: Data?

  func prepare<R: NetworkRequest>(request: R, parameters: [NetworkParameter]?, baseHost: String) async -> URLRequest {
    URLRequest(url: URL(string: "https://example.com")!)
  }

  func execute<R: NetworkRequest>(with request: R, parameters: [NetworkParameter]?) async throws -> NetworkResponse {
    capturedHeaders = request.additionalHeaders
    capturedBody = request.body
    if let error { throw error }
    if let mockResponse { return mockResponse }
    throw NetworkError.invalidResponse
  }

  func log(request: URLRequest, responseData: Data?, responseHeader: HTTPURLResponse?) {}
}

private final class FakeSecureEnclaveController: SecureEnclaveController {
  private var stringStorage: [SecureEnclaveKeys: String] = [:]

  func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool { false }
  func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool { true }
  @discardableResult
  func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    stringStorage[keyTag] = value; return true
  }
  func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String? { stringStorage[keyTag] }
  // The fake does not actually encrypt; it shares the same backing store as the plain variants.
  @discardableResult
  func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) -> Bool { stringStorage[keyTag] = value; return true }
  func retrieveDecryptedString(keyTag: SecureEnclaveKeys) -> String? { stringStorage[keyTag] }
  func deleteKeychainItem(keyTag: SecureEnclaveKeys) { stringStorage.removeValue(forKey: keyTag) }
  func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey { throw NSError(domain: "unused", code: -1) }
  func generatePublicKey(from privateKey: SecKey) throws -> SecKey { throw NSError(domain: "unused", code: -1) }
  func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw NSError(domain: "SecKey", code: -1)
    }
    return key
  }
  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else { throw NSError(domain: "SecKey", code: -1) }
    var error: Unmanaged<CFError>?
    guard let derData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
      throw NSError(domain: "SecKey", code: -2)
    }
    return PublicKeyInfo(x963: derData, derBase64: derData.base64EncodedString())
  }
}

private extension String {
  var utf8Data: Data? { data(using: .utf8) }
}
