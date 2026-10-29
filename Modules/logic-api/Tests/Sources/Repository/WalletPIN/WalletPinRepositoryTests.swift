//
//  WalletPinRepositoryTests.swift
//  logic-api
//

import Foundation
import Security
import Testing

@testable import logic_api
@testable import logic_business

struct WalletPinRepositoryTests {

  @Test
  func getPinPrivateKey_WhenSaltStored_UsesStoredSaltAndDoesNotStoreAgain() async throws {
    let secureEnclave = FakeSecureEnclaveController()
    secureEnclave.storeStringInKeychain(value: "stored-salt", keyTag: .rwscaAuthPrivateKeySalt)
    let sut = WalletPinRepositoryImpl(secureEnclaveController: secureEnclave)

    _ = try await sut.getPinPrivateKey(pin: "123456")

    #expect(secureEnclave.derivedWith == ["stored-salt"])
    #expect(secureEnclave.storeEncryptedCallCount == 0)
  }

  @Test
  func getPinPrivateKey_WhenSaltMissing_GeneratesStoresAndUsesNewSalt() async throws {
    let secureEnclave = FakeSecureEnclaveController()
    let sut = WalletPinRepositoryImpl(secureEnclaveController: secureEnclave)

    _ = try await sut.getPinPrivateKey(pin: "123456")

    let salt = try #require(secureEnclave.retrieveStringFromKeychain(keyTag: .rwscaAuthPrivateKeySalt))
    #expect(Data(base64Encoded: salt)?.count == 16)
    #expect(secureEnclave.derivedWith == [salt])
  }

  @Test
  func getPinPrivateKey_WhenSaltUnreadable_ThrowsAndNeverReplacesSalt() async {
    let secureEnclave = FakeSecureEnclaveController()
    secureEnclave.storeStringInKeychain(value: "stored-salt", keyTag: .rwscaAuthPrivateKeySalt)
    secureEnclave.decryptionError = SecureEnclaveControllerError.encryptedValueAuthenticationFailed
    let sut = WalletPinRepositoryImpl(secureEnclaveController: secureEnclave)

    // A corrupt salt must not be silently replaced: a new salt derives a different key and the backend
    // would count every attempt as a wrong PIN until the account locks.
    await #expect(throws: SecureEnclaveControllerError.encryptedValueAuthenticationFailed) {
      _ = try await sut.getPinPrivateKey(pin: "123456")
    }

    #expect(secureEnclave.storeEncryptedCallCount == 0)
    #expect(secureEnclave.derivedWith.isEmpty)
  }
}

private final class FakeSecureEnclaveController: SecureEnclaveController {
  private var stringStorage: [SecureEnclaveKeys: String] = [:]
  var decryptionError: Error?
  private(set) var storeEncryptedCallCount = 0
  /// Salts passed to `generateECPrivateKey`, in call order.
  private(set) var derivedWith: [String] = []

  func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool { false }
  func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool { true }

  @discardableResult
  func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    stringStorage[keyTag] = value
    return true
  }

  func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String? { stringStorage[keyTag] }

  func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) throws {
    storeEncryptedCallCount += 1
    stringStorage[keyTag] = value
  }
  func retrieveDecryptedString(keyTag: SecureEnclaveKeys) throws -> String? {
    if let decryptionError { throw decryptionError }
    return stringStorage[keyTag]
  }

  func deleteKeychainItem(keyTag: SecureEnclaveKeys) { stringStorage.removeValue(forKey: keyTag) }

  func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey {
    derivedWith.append(salt)
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

  func generatePublicKey(from privateKey: SecKey) throws -> SecKey { throw NSError(domain: "unused", code: -1) }
  func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey { throw NSError(domain: "unused", code: -1) }
  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo { throw NSError(domain: "unused", code: -1) }
}
