//
//  WalletDataEncryptionController.swift
//  logic-business
//

import Foundation
import Security
import CryptoKit

public enum WalletDataEncryptionError: Error {
  case keyUnavailable
  case encryptionFailed
  case decryptionFailed
  case invalidCiphertextFormat
  case authenticationFailed
}

/// Owns the lifecycle of `wi_data_enc_symk`, the symmetric key used to encrypt sensitive
/// local data at rest. The key is stored in the Keychain with
/// `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`, so iOS makes it inaccessible the moment
/// the device passcode (Platform Authentication) is removed. Any data encrypted with it then
/// becomes unreadable without relying on an app-driven wipe.
public protocol WalletDataEncryptionController: Sendable {
  /// Encrypts plaintext using AES-GCM with `wi_data_enc_symk`, generating and storing the key
  /// first if it is not already present. The returned data is the combined representation
  /// (nonce + ciphertext + tag). Throws `keyUnavailable` when the key cannot be stored, for
  /// example when no device passcode is set.
  func encrypt(_ data: Data) throws -> Data
  /// Decrypts data previously produced by `encrypt(_:)`.
  func decrypt(_ data: Data) throws -> Data
  /// Removes `wi_data_enc_symk` from the Keychain.
  func deleteKey()
}

/// Persists the raw `wi_data_enc_symk` material. Abstracted from the controller so the
/// encryption logic can be unit tested without touching the Keychain.
protocol SymmetricKeyStorage: Sendable {
  func loadKey() -> CryptoKit.SymmetricKey?
  /// Never replaces an existing key, so a key that is only temporarily unreadable (for example on a locked device) is not lost.
  func storeKey(_ key: CryptoKit.SymmetricKey) throws -> CryptoKit.SymmetricKey
  func deleteKey()
}

public final class WalletDataEncryptionControllerImpl: WalletDataEncryptionController {

  private let logger: Logging?
  private let keyStorage: SymmetricKeyStorage

  public convenience init(logger: Logging?) {
    self.init(logger: logger, keyStorage: KeychainSymmetricKeyStorage(logger: logger))
  }

  init(logger: Logging?, keyStorage: SymmetricKeyStorage) {
    self.logger = logger
    self.keyStorage = keyStorage
  }

  func loadOrCreateKey() throws -> CryptoKit.SymmetricKey {
    if let key = keyStorage.loadKey() {
      return key
    }
    return try keyStorage.storeKey(CryptoKit.SymmetricKey(size: .bits256))
  }

  public func encrypt(_ data: Data) throws -> Data {
    let key = try loadOrCreateKey()
    do {
      let sealedBox = try AES.GCM.seal(data, using: key)
      guard let combined = sealedBox.combined else {
        throw WalletDataEncryptionError.encryptionFailed
      }
      return combined
    } catch {
      logger?.e("wi_data_enc_symk encryption failed: \(error)")
      throw WalletDataEncryptionError.encryptionFailed
    }
  }

  public func decrypt(_ data: Data) throws -> Data {
    guard let key = keyStorage.loadKey() else {
      throw WalletDataEncryptionError.keyUnavailable
    }
    let sealedBox: AES.GCM.SealedBox
    do {
      sealedBox = try AES.GCM.SealedBox(combined: data)
    } catch {
      logger?.e("Invalid wi_data_enc_symk ciphertext format: \(error)")
      throw WalletDataEncryptionError.invalidCiphertextFormat
    }

    do {
      return try AES.GCM.open(sealedBox, using: key)
    } catch {
      logger?.e("wi_data_enc_symk authentication failed: \(error)")
      throw WalletDataEncryptionError.authenticationFailed
    }
  }

  public func deleteKey() {
    keyStorage.deleteKey()
  }
}

/// Keychain-backed `wi_data_enc_symk` storage, bound to the device passcode.
final class KeychainSymmetricKeyStorage: SymmetricKeyStorage {

  private static let keyAccount = "com.dewallet.wi_data_enc_symk"

  private let logger: Logging?

  init(logger: Logging?) {
    self.logger = logger
  }

  func loadKey() -> CryptoKit.SymmetricKey? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: Self.keyAccount,
      kSecUseDataProtectionKeychain as String: true,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess, let keyData = item as? Data else {
      return nil
    }
    return CryptoKit.SymmetricKey(data: keyData)
  }

  func storeKey(_ key: CryptoKit.SymmetricKey) throws -> CryptoKit.SymmetricKey {
    let keyData = key.withUnsafeBytes { Data($0) }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: Self.keyAccount,
      // Bind the key to this device and require a passcode, so it is dropped by iOS when
      // Platform Authentication is turned off. Never sync it to iCloud.
      kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
      kSecAttrSynchronizable as String: false,
      kSecUseDataProtectionKeychain as String: true,
      kSecValueData as String: keyData
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecSuccess {
      logger?.d("[STORAGE] store key=\(Self.keyAccount) dest=keychain")
      return key
    }
    if status == errSecDuplicateItem, let existingKey = loadKey() {
      return existingKey
    }
    logger?.e("Failed to store wi_data_enc_symk: \(status)")
    throw WalletDataEncryptionError.keyUnavailable
  }

  func deleteKey() {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: Self.keyAccount
    ]
    let status = SecItemDelete(query as CFDictionary)
    if status == errSecSuccess {
      logger?.d("[STORAGE] clear key=\(Self.keyAccount) dest=keychain")
    }
  }
}
