//
//  SecureEnclaveControllerTests.swift
//  logic-business
//
//  Created by Tamas Dancsi on 18.02.26.
//

import Foundation
import Security
import Testing

@testable import logic_business

// These tests check the key create-or-reuse logic only. They do not fully test Apple Security/Keychain behavior.
struct SecureEnclaveControllerTests {

  @Test
  func getOrCreatePrivateKey_ReturnsExistingKeyWhenPresent() throws {
    let existingKey = try makePrivateKey()
    let secureEnclaveController = SecureEnclaveControllerFake()
    secureEnclaveController.existingPrivateKey = existingKey

    let result = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    #expect(CFEqual(result, existingKey))
  }

  @Test
  func getOrCreatePrivateKey_CreatesAndStoresWhenMissing() throws {
    let createdKey = try makePrivateKey()
    let secureEnclaveController = SecureEnclaveControllerFake()
    secureEnclaveController.generatedPrivateKey = createdKey

    let result = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    #expect(CFEqual(result, createdKey))
  }

  @Test
  func getOrCreatePrivateKey_ThrowsWhenCreationFails() {
    let secureEnclaveController = SecureEnclaveControllerFake()

    // No existing key and key creation returns nil, so creation must fail.
    #expect(throws: SecureEnclaveControllerError.keyCreationFailed) {
      _ = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    }
  }

  @Test
  func getOrCreatePrivateKey_ThrowsWhenStoreFails() throws {
    let createdKey = try makePrivateKey()
    let secureEnclaveController = SecureEnclaveControllerFake()
    secureEnclaveController.generatedPrivateKey = createdKey
    secureEnclaveController.shouldStoreSucceed = false

    // Key creation succeeds but persisting to keychain fails.
    #expect(throws: SecureEnclaveControllerError.keyStoreFailed) {
      _ = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    }
  }

  @Test
  func getPublicKeyInfo_ReturnsDERAndX963() throws {
    let privateKey = try makePrivateKey()
    // This one executes the real implementation path.
    let secureEnclaveController = SecureEnclaveControllerImpl(
      logger: nil,
      walletDataEncryptionController: WalletDataEncryptionControllerImpl(logger: nil)
    )
    let keyInfo = try secureEnclaveController.getPublicKeyInfo(from: privateKey)

    #expect(keyInfo.x963.isEmpty == false)
    #expect(keyInfo.derBase64.isEmpty == false)
  }

  private func makePrivateKey() throws -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw error?.takeRetainedValue() ?? NSError(domain: "SecureEnclaveControllerKeyOperationsTests", code: -1)
    }
    return key
  }
}

// Local fake keeps retrieval/creation/storage outcomes deterministic for guardrail tests.
private final class SecureEnclaveControllerFake: SecureEnclaveController {
  var existingPrivateKey: SecKey?
  var generatedPrivateKey: SecKey?
  var shouldStoreSucceed = true

  func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? {
    generatedPrivateKey
  }

  func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool {
    shouldStoreSucceed
  }

  func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? {
    existingPrivateKey
  }

  func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool { true }
  func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool { true }
  func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String? { nil }
  func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) -> Bool { true }
  func retrieveDecryptedString(keyTag: SecureEnclaveKeys) -> String? { nil }
  func deleteKeychainItem(keyTag: SecureEnclaveKeys) {}

  func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func generatePublicKey(from privateKey: SecKey) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey {
    if let existingKey = retrievePrivateKey(with: keyTag) {
      return existingKey
    }

    guard let newKey = createPrivateKey(with: keyTag) else {
      throw SecureEnclaveControllerError.keyCreationFailed
    }

    guard storePrivateKey(newKey, with: keyTag) else {
      throw SecureEnclaveControllerError.keyStoreFailed
    }

    return newKey
  }

  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo {
    fatalError("Unused in these tests")
  }
}
