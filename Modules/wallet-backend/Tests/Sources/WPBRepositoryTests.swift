//
//  WPBRepositoryTests.swift
//  wallet-backend
//

import Foundation
import Security
import Testing

@testable import wallet_backend
@testable import logic_api
@testable import logic_business
@testable import logic_test

struct WPBRepositoryTests {

  private let wiaPrivateKey = makePrivateKey()

  // MARK: - fetchChallenge

  @Test
  func fetchChallenge_WhenResponseIsValid_ReturnsChallenge() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"wpb_auth_challenge":"challenge-abc"}"#.utf8Data,
      headers: nil
    )

    let result = try await sut.fetchChallenge()

    #expect(result == "challenge-abc")
  }

  @Test
  func fetchChallenge_WhenResponseDataIsNil_ThrowsInvalidResponse() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: nil, headers: nil)

    await #expect(throws: WPBRepositoryError.invalidResponse) {
      _ = try await sut.fetchChallenge()
    }
  }

  // MARK: - getStoredWIID / storeWIID / deleteWIID

  @Test
  func getStoredWIID_WhenNothingStored_ReturnsNil() {
    #expect(makeSUT().getStoredWIID() == nil)
  }

  @Test
  func storeWIID_ThenGetStoredWIID_ReturnsStoredValue() {
    let sut = makeSUT()
    sut.storeWIID("wi-id-123")
    #expect(sut.getStoredWIID() == "wi-id-123")
  }

  @Test
  func deleteWIID_AfterStoring_ReturnsNil() {
    let sut = makeSUT()
    sut.storeWIID("wi-id-123")
    sut.deleteWIID()
    #expect(sut.getStoredWIID() == nil)
  }

  // MARK: - register

  @Test
  func register_WhenResponseIsValid_ReturnsWIID() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"wpb_wi_id":"wi-id-123","wpb_wi_revocation_code":"rev-code-123"}"#.utf8Data,
      headers: nil
    )

    let result = try await sut.register(mdvmToken: "token", authChallenge: "challenge")

    #expect(result.wbWIID == "wi-id-123")
    #expect(result.wpbWiRevocationCode == "rev-code-123")
  }

  @Test
  func register_WhenServerReturnsError_ThrowsServerError() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"code":"WPB_REG_ERROR","description":"failed","trace_id":"t-1"}"#.utf8Data,
      headers: nil
    )

    await #expect(
      throws: WPBRepositoryError.serverError(code: "WPB_REG_ERROR", description: "failed", traceID: "t-1")
    ) {
      _ = try await sut.register(mdvmToken: "token", authChallenge: "challenge")
    }
  }

  // MARK: - issueAttestation

  @Test
  func issueAttestation_WhenResponseIsValid_ReturnsWIA() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"wpb_wia":"wia-token-xyz"}"#.utf8Data,
      headers: nil
    )

    let result = try await sut.issueAttestation(
      mdvmToken: "token",
      authChallenge: "challenge",
      wbWIID: "wi-id-123",
      wiaPrivateKey: wiaPrivateKey
    )

    #expect(result.wbWIA == "wia-token-xyz")
  }

  @Test
  func issueAttestation_WhenResponseDataIsNil_ThrowsInvalidResponse() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: nil, headers: nil)

    await #expect(throws: WPBRepositoryError.invalidResponse) {
      _ = try await sut.issueAttestation(
        mdvmToken: "token",
        authChallenge: "challenge",
        wbWIID: "wi-id-123",
        wiaPrivateKey: wiaPrivateKey
      )
    }
  }

  // MARK: - deleteAccount

  @Test
  func deleteAccount_WhenResponseIsEmpty_CompletesWithoutThrowing() async throws {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)
    network.mockResponse = NetworkResponse(data: Data(), headers: nil)

    try await sut.deleteAccount(mdvmToken: "token", authChallenge: "challenge", wbWIID: "wi-id-123")
  }

  @Test
  func deleteAccount_WhenServerReturnsError_ThrowsServerError() async {
    let network = FakeNetworkManager()
    let sut = makeSUT(network: network)

    network.mockResponse = NetworkResponse(
      data: #"{"code":"WPB_DEL_ERROR","description":"not found","trace_id":"t-2"}"#.utf8Data,
      headers: nil
    )

    await #expect(
      throws: WPBRepositoryError.serverError(code: "WPB_DEL_ERROR", description: "not found", traceID: "t-2")
    ) {
      try await sut.deleteAccount(mdvmToken: "token", authChallenge: "challenge", wbWIID: "wi-id-123")
    }
  }

  // MARK: - Helpers

  private func makeSUT(network: FakeNetworkManager = FakeNetworkManager()) -> WPBRepositoryImpl {
    WPBRepositoryImpl(
      networkManager: network,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: FakeSecureEnclaveController()
    )
  }

  private static func makePrivateKey() -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      fatalError("Failed to create key: \(String(describing: error))")
    }
    return key
  }
}

private final class FakeNetworkManager: NetworkManager {
  var mockResponse: NetworkResponse?
  var error: Error?

  func prepare<R: NetworkRequest>(request: R, parameters: [NetworkParameter]?, baseHost: String) async -> URLRequest {
    URLRequest(url: URL(string: "https://example.com")!)
  }

  func execute<R: NetworkRequest>(with request: R, parameters: [NetworkParameter]?) async throws -> NetworkResponse {
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
    let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits as String: 256]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else { throw NSError(domain: "SecKey", code: -1) }
    return key
  }
  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else { throw NSError(domain: "SecKey", code: -1) }
    var error: Unmanaged<CFError>?
    guard let derData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else { throw NSError(domain: "SecKey", code: -2) }
    return PublicKeyInfo(x963: derData, derBase64: derData.base64EncodedString())
  }
}

private extension String {
  var utf8Data: Data? { data(using: .utf8) }
}
