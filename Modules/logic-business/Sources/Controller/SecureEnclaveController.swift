//
//  SecureEnclaveController.swift
//  logic-business
//

import Foundation
import Security
import CommonCrypto
import CryptoKit

public enum SecureEnclaveKeys: Equatable {
  case wia
  case wiID
  case wbWIID
  case wpbWiRevocationCode
  case mdvmToken
  case mdvmWIID
  case mdvmAppAttestKeyID
  case credentialPrivKey
  case rwscdAccountID
  case rwscdPinPrivKey
  case wiaPrivateKey
  case clientAttestationPrivateKey
  case rwscaAuthPrivateKeySalt
  case rwscaAccountID
  case pinSessionToken
  case mppRegistrationToken
  case custom(String)
  case wiMdvmAuthPrivateKey

  var value: String {
    switch self {
    case .wia: return "com.dewallet.wia"
    case .wiID: return "com.dewallet.wiID"
    case .wbWIID: return "com.dewallet.wb.wi_id"
    case .wpbWiRevocationCode: return "com.dewallet.wb.wi_revocation_code"
    case .mdvmToken: return "com.dewallet.mdvm.token"
    case .mdvmWIID: return "com.dewallet.mdvm.wi_id"
    case .mdvmAppAttestKeyID: return "com.dewallet.mdvm.app_attest_key_id"
    case .credentialPrivKey: return "com.dewallet.credentials.privateKey"
    case .rwscdAccountID: return "com.dewallet.rwscd.account_id"
    case .rwscdPinPrivKey: return "com.rwscd.pin.priv.key"
    case .wiaPrivateKey: return "com.dewallet.wia.private.key"
    case .clientAttestationPrivateKey: return "com.dewallet.bdr.client.attestation"
    case .rwscaAuthPrivateKeySalt: return "com.rwsca.auth.priv_key.salt"
    case .rwscaAccountID: return "com.dewallet.rwsca.account_id"
    case .pinSessionToken: return "com.rwsca.auth.pin_session_token"
    case .mppRegistrationToken: return "com.dewallet.pns.mpp_registration_token"
    case .custom(let string): return string
    // Rename the value for the key to keep it consistent with Architecture
    case .wiMdvmAuthPrivateKey: return "com.dewallet.registration.privateKey"
    }
  }
}
extension SecureEnclaveKeys: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
  }
}

public protocol SecureEnclaveController {
  func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey?
  func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool
  func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey?
  func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool
  func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool
  func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String?
  /// Encrypts the value with `wi_data_enc_symk` before storing it in the Keychain.
  func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) -> Bool
  /// Retrieves and decrypts a value stored via `storeEncryptedString`. Transparently migrates
  /// legacy plaintext values that were written before encryption was introduced.
  func retrieveDecryptedString(keyTag: SecureEnclaveKeys) -> String?
  func deleteKeychainItem(keyTag: SecureEnclaveKeys)
  func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey
  func generatePublicKey(from privateKey: SecKey) throws -> SecKey
  /// Returns an existing private key for the tag or creates and stores a new one if missing.
  func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey
  /// Derives exportable public key representations used by backend registration and signing headers.
  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo
}

public final class SecureEnclaveControllerImpl: SecureEnclaveController {

  private let logger: Logging?
  private let walletDataEncryptionController: WalletDataEncryptionController

  public init(logger: Logging?, walletDataEncryptionController: WalletDataEncryptionController) {
    self.logger = logger
    self.walletDataEncryptionController = walletDataEncryptionController
  }

  public func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? {
    guard let keyTag = keyTag.value.data(using: .utf8) else { return nil }
    guard let accessControl = makePrivateKeyAccessControl() else { return nil }

    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecPrivateKeyAttrs as String: [
        kSecAttrIsPermanent as String: true,
        kSecAttrApplicationTag as String: keyTag,
        kSecAttrAccessControl as String: accessControl
      ]
    ]
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      logger?.e("Error creating private key: \(error!.takeRetainedValue())")
      return nil
    }
    return privateKey
  }

  public func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool {

    if !deletePrivateKey(with: keyTag) {
      return false
    }
    logger?.d("[STORAGE] store key=\(keyTag.value) dest=secureEnclave")
    guard let keyTag = keyTag.value.data(using: .utf8) else { return false }
    guard let accessControl = makePrivateKeyAccessControl() else { return false }

    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: keyTag,
      kSecValueRef as String: privateKey,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecAttrAccessControl as String: accessControl
    ]

    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess {
      logger?.e("Error saving private key to keychain: \(status)")
      return false
    }

    return true
  }

  // MARK: - Fetch Private Key from Keychain
  public func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? {
    guard let keyTag = keyTag.value.data(using: .utf8) else { return nil }
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: keyTag,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
      kSecReturnRef as String: true
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess else { return nil }

    // We are only doing force downcast because we are sure of the item as SecKey
    // swiftlint:disable force_cast
    return (item as! SecKey)
    // swiftlint:enable force_cast
  }

  public func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool {
    logger?.d("[STORAGE] clear key=\(keyTag.value) dest=secureEnclave")
    guard let keyTag = keyTag.value.data(using: .utf8) else { return false }
    let query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrApplicationTag as String: keyTag,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom
    ]

    // Delete the existing key
    let status = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound { return false }

    return true
  }

  public func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    guard let valueData = value.data(using: .utf8) else { return false }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      // Requiring device passcode and keep this keychain item bound to the current device only
      kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
      kSecAttrAccount as String: keyTag.value,
      kSecValueData as String: valueData
    ]

    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)
    if status != errSecSuccess {
      logger?.e("Error storing string in Keychain: \(status)")
    } else {
      logger?.d("[STORAGE] store key=\(keyTag.value) dest=keychain")
    }
    return status == errSecSuccess
  }

  public func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: keyTag.value,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    guard status == errSecSuccess, let valueData = item as? Data else {
      logger?.e("Failed to retrieve value from Keychain: \(status)")
      return nil
    }

    return String(data: valueData, encoding: .utf8)
  }

  public func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    guard let plaintext = value.data(using: .utf8) else { return false }
    walletDataEncryptionController.generateKeyIfNeeded()
    guard let ciphertext = try? walletDataEncryptionController.encrypt(plaintext) else {
      logger?.e("Failed to encrypt value for keyTag: \(keyTag.value)")
      return false
    }
    return storeStringInKeychain(value: ciphertext.base64EncodedString(), keyTag: keyTag)
  }

  public func retrieveDecryptedString(keyTag: SecureEnclaveKeys) -> String? {
    guard let stored = retrieveStringFromKeychain(keyTag: keyTag) else { return nil }
    if let ciphertext = Data(base64Encoded: stored),
       let plaintext = try? walletDataEncryptionController.decrypt(ciphertext),
       let value = String(data: plaintext, encoding: .utf8) {
      return value
    }
    _ = storeEncryptedString(value: stored, keyTag: keyTag)
    return stored
  }

  public func deleteKeychainItem(keyTag: SecureEnclaveKeys) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: keyTag.value
    ]
    let status = SecItemDelete(query as CFDictionary)
    if status == errSecSuccess {
      logger?.d("[STORAGE] clear key=\(keyTag.value) dest=keychain")
    }
  }

  public func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey {
    let combined = "\(pin)\(salt)"
    let combinedData = Data(combined.utf8)
    let saltData = Data(salt.utf8)
    let iterations = 120_000
    let keyLength = 32 // 256 bits

    var derivedKey = [UInt8](repeating: 0, count: keyLength)
    let result = derivedKey.withUnsafeMutableBytes { derivedKeyPointer in
      saltData.withUnsafeBytes { saltPointer in
        CCKeyDerivationPBKDF(
          CCPBKDFAlgorithm(kCCPBKDF2),
          combined, combinedData.count,
          saltPointer.baseAddress!.assumingMemoryBound(to: UInt8.self), saltData.count,
          CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
          UInt32(iterations),
          derivedKeyPointer.baseAddress!.assumingMemoryBound(to: UInt8.self),
          keyLength
        )
      }
    }

    guard result == kCCSuccess else {
      throw NSError(domain: "PBKDF2Error", code: Int(result), userInfo: nil)
    }
    return try P256.Signing.PrivateKey(rawRepresentation: Data(derivedKey)).toSecKey()
  }

  public func generatePublicKey(from privateKey: SecKey) throws -> SecKey {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw NSError(domain: "YourDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate public key"])
    }
    return publicKey
  }

  public func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey {
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

  public func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw SecureEnclaveControllerError.publicKeyUnavailable
    }

    var error: Unmanaged<CFError>?
    guard let x963 = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
      _ = error?.takeRetainedValue()
      throw SecureEnclaveControllerError.publicKeyEncodingFailed
    }

    let p256PublicKey = try P256.Signing.PublicKey(x963Representation: x963)
    return PublicKeyInfo(
      x963: x963,
      derBase64: p256PublicKey.derRepresentation.base64EncodedString()
    )
  }

  private func makePrivateKeyAccessControl() -> SecAccessControl? {
    var error: Unmanaged<CFError>?
    let accessControl = SecAccessControlCreateWithFlags(
      nil,
      // Protecting this secure enclave key with passcode-backed access control for private-key use
      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
      [.privateKeyUsage],
      &error
    )
    if let error {
      logger?.e("Error creating private key access control: \(error.takeRetainedValue())")
    }
    return accessControl
  }
}
extension P256.Signing.PrivateKey {
  func toSecKey() throws -> SecKey {
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateWithData(x963Representation as NSData, [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeyClass: kSecAttrKeyClassPrivate] as NSDictionary, &error) else {
      throw error!.takeRetainedValue() as Error
    }
    return privateKey
  }
}
