//
//  WalletPinRepository.swift
//  logic-api
//
import Foundation
import logic_business

public protocol WalletPinRepository {
  func getPinPrivateKey(pin: String) async throws -> SecKey
}
final class WalletPinRepositoryImpl: WalletPinRepository {
  private let secureEnclaveController: SecureEnclaveController

  init(secureEnclaveController: SecureEnclaveController) {
    self.secureEnclaveController = secureEnclaveController
  }

  public func getPinPrivateKey(pin: String) async throws -> SecKey {
    let salt = try getPinSalt()
    let secKey = try secureEnclaveController.generateECPrivateKey(from: pin, and: salt)
    return secKey
  }

  private func getPinSalt() throws -> String {
    let saltTag: SecureEnclaveKeys = .rwscaAuthPrivateKeySalt

    if let salt = try secureEnclaveController.retrieveDecryptedString(keyTag: saltTag) {
      return salt
    }

    var saltBytes = [UInt8](repeating: 0, count: 16)
    let status = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)
    guard status == errSecSuccess else {
      throw PoPGenerationError.saltGenerationFailed
    }
    // Stored as base64 so the PIN key derivation can decode it back to the raw 16 salt bytes
    let newSalt = Data(saltBytes).base64EncodedString()

    _ = try secureEnclaveController.storeEncryptedString(value: newSalt, keyTag: saltTag)

    return newSalt
  }
}
