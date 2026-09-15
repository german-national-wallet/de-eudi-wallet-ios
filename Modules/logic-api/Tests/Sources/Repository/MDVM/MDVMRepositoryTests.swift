//
//  MDVMRepositoryTests.swift
//  logic-api
//
//  Created by Tamas Dancsi on 18.02.26.
//

import Foundation
import Security
import Testing

@testable import logic_api
@testable import logic_business
@testable import logic_test

struct MDVMRepositoryTests {

  @Test
  func register_WhenResponseIsValid_SavesRegistration() async throws {
    let mockNetworkManager = FakeNetworkManager()
    let secureEnclaveController = FakeSecureEnclaveController()
    let sut: MDVMRepository = MDVMRepositoryImpl(
      networkManager: mockNetworkManager,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: secureEnclaveController
    )

    let responseData = """
      {
        "mdvm_wi_id": "mdvm-id-123",
        "mdvm_token": "mdvm-token-xyz"
      }
      """.data(using: .utf8)
    mockNetworkManager.mockResponse = NetworkResponse(data: responseData, headers: nil)

    let payload = MDVMRegistrationPayload(
      wiDeviceClass: MDVMDeviceClass(
        systemVersion: "18.0",
        model: "iPhone",
        hardwareModel: "iPhone17,1",
        identifierForVendor: "vendor-id",
        uname: "iPhone17,1",
        osVersion: "Version 18.0"
      ),
      wiMDVMAuthPubk: "public-key",
      papDeviceCheckAttestation: "attestation",
      papDeviceCheckAssertion: "assertion"
    )

    try await sut.register(
      payload: payload,
      authChallenge: "challenge-value",
      skipIntegrityChecks: false,
      privateKey: makePrivateKey()
    )

    #expect(sut.getStoredRegistration() == MDVMStoredRegistration(mdvmWIID: "mdvm-id-123", mdvmToken: "mdvm-token-xyz"))
  }

  @Test
  func renew_WhenResponseIsValid_UpdatesStoredToken() async throws {
    let mockNetworkManager = FakeNetworkManager()
    let secureEnclaveController = FakeSecureEnclaveController()
    secureEnclaveController.storeStringInKeychain(value: "mdvm-id-123", keyTag: .mdvmWIID)
    secureEnclaveController.storeStringInKeychain(value: "old-token", keyTag: .mdvmToken)

    let sut: MDVMRepository = MDVMRepositoryImpl(
      networkManager: mockNetworkManager,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: secureEnclaveController
    )

    let responseData = """
      {
        "mdvm_token": "new-mdvm-token"
      }
      """.data(using: .utf8)
    mockNetworkManager.mockResponse = NetworkResponse(data: responseData, headers: nil)

    let payload = MDVMRenewalPayload(
      wiDeviceClass: MDVMDeviceClass(
        systemVersion: "18.0",
        model: "iPhone",
        hardwareModel: "iPhone17,1",
        identifierForVendor: "vendor-id",
        uname: "iPhone17,1",
        osVersion: "Version 18.0"
      ),
      papDeviceCheckAssertion: "assertion"
    )

    try await sut.renew(
      payload: payload,
      mdvmWIID: "mdvm-id-123",
      authChallenge: "challenge-value",
      skipIntegrityChecks: false,
      privateKey: makePrivateKey()
    )

    #expect(sut.getStoredRegistration() == MDVMStoredRegistration(mdvmWIID: "mdvm-id-123", mdvmToken: "new-mdvm-token"))
  }

  @Test
  func fetchChallenge_WhenResponseDataIsMissing_ThrowsInvalidResponse() async {
    let mockNetworkManager = FakeNetworkManager()
    let secureEnclaveController = FakeSecureEnclaveController()
    let sut: MDVMRepository = MDVMRepositoryImpl(
      networkManager: mockNetworkManager,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: secureEnclaveController
    )
    mockNetworkManager.mockResponse = NetworkResponse(data: nil, headers: nil)

    await #expect(throws: MDVMRepositoryError.invalidResponse) {
      _ = try await sut.fetchChallenge()
    }
  }

  @Test
  func register_WhenServerReturnsBusinessError_ThrowsMappedServerError() async {
    let mockNetworkManager = FakeNetworkManager()
    let secureEnclaveController = FakeSecureEnclaveController()
    let sut: MDVMRepository = MDVMRepositoryImpl(
      networkManager: mockNetworkManager,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: secureEnclaveController
    )

    let errorData = """
      {
        "code": "MDVM_REGISTER_ERROR",
        "description": "registration failed",
        "trace_id": "trace-123"
      }
      """.data(using: .utf8)
    mockNetworkManager.mockResponse = NetworkResponse(data: errorData, headers: nil)

    let payload = MDVMRegistrationPayload(
      wiDeviceClass: MDVMDeviceClass(
        systemVersion: "18.0",
        model: "iPhone",
        hardwareModel: "iPhone17,1",
        identifierForVendor: "vendor-id",
        uname: "iPhone17,1",
        osVersion: "Version 18.0"
      ),
      wiMDVMAuthPubk: "public-key",
      papDeviceCheckAttestation: "attestation",
      papDeviceCheckAssertion: "assertion"
    )

    await #expect(
      throws: MDVMRepositoryError.serverError(
        code: "MDVM_REGISTER_ERROR",
        description: "registration failed",
        traceID: "trace-123"
      )
    ) {
      try await sut.register(
        payload: payload,
        authChallenge: "challenge-value",
        skipIntegrityChecks: false,
        privateKey: makePrivateKey()
      )
    }
  }

  @Test
  func getStoredRegistration_WhenNoStoredValuesExist_ReturnsNil() {
    let mockNetworkManager = FakeNetworkManager()
    let secureEnclaveController = FakeSecureEnclaveController()
    let sut: MDVMRepository = MDVMRepositoryImpl(
      networkManager: mockNetworkManager,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: secureEnclaveController
    )

    #expect(sut.getStoredRegistration() == nil)
  }

  @Test
  func getStoredRegistration_WhenTokenAndWIIDExist_ReturnsStoredRegistration() {
    let mockNetworkManager = FakeNetworkManager()
    let secureEnclaveController = FakeSecureEnclaveController()
    secureEnclaveController.storeStringInKeychain(value: "mdvm-token", keyTag: .mdvmToken)
    secureEnclaveController.storeStringInKeychain(value: "mdvm-wi-id", keyTag: .mdvmWIID)

    let sut: MDVMRepository = MDVMRepositoryImpl(
      networkManager: mockNetworkManager,
      httpSignatureService: HTTPSignatureServiceImpl(),
      secureEnclaveController: secureEnclaveController
    )

    #expect(sut.getStoredRegistration() == MDVMStoredRegistration(mdvmWIID: "mdvm-wi-id", mdvmToken: "mdvm-token"))
  }

  private func makePrivateKey() -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      fatalError("Failed to create test key: \(String(describing: error))")
    }
    return key
  }
}

private final class FakeSecureEnclaveController: SecureEnclaveController {
  private var stringStorage: [SecureEnclaveKeys: String] = [:]

  func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool { false }
  func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool { true }

  @discardableResult
  func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    stringStorage[keyTag] = value
    return true
  }

  func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String? {
    stringStorage[keyTag]
  }

  // The fake does not actually encrypt; it shares the same backing store as the plain variants.
  @discardableResult
  func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    stringStorage[keyTag] = value
    return true
  }

  func retrieveDecryptedString(keyTag: SecureEnclaveKeys) -> String? {
    stringStorage[keyTag]
  }

  func deleteKeychainItem(keyTag: SecureEnclaveKeys) {
    stringStorage.removeValue(forKey: keyTag)
  }

  func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func generatePublicKey(from privateKey: SecKey) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo {
    throw NSError(domain: "unused", code: -1)
  }
}
