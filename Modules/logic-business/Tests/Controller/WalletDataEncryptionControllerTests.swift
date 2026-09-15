//
//  WalletDataEncryptionControllerTests.swift
//  logic-business
//
//  Created by Ameen Qadri on 18.06.26
//

import Foundation
import CryptoKit
import Testing

@testable import logic_business

// Exercises the wi_data_enc_symk encryption logic against an in-memory key store, so the
// crypto behaviour is verified without depending on Keychain / device passcode state.
struct WalletDataEncryptionControllerTests {

  private func makeSUT() -> (WalletDataEncryptionControllerImpl, InMemorySymmetricKeyStorage) {
    let storage = InMemorySymmetricKeyStorage()
    let sut = WalletDataEncryptionControllerImpl(logger: nil, keyStorage: storage)
    return (sut, storage)
  }

  @Test
  func generateKeyIfNeeded_createsKeyWhenMissing() {
    let (sut, storage) = makeSUT()
    #expect(storage.loadKey() == nil)

    sut.generateKeyIfNeeded()

    #expect(storage.loadKey() != nil)
  }

  @Test
  func generateKeyIfNeeded_isIdempotent() {
    let (sut, storage) = makeSUT()
    sut.generateKeyIfNeeded()
    let firstBytes = storage.loadKey()?.bytes

    sut.generateKeyIfNeeded()
    let secondBytes = storage.loadKey()?.bytes

    // The key must not be regenerated on subsequent calls.
    #expect(firstBytes != nil)
    #expect(firstBytes == secondBytes)
  }

  @Test
  func encryptThenDecrypt_roundTripsToOriginal() throws {
    let (sut, _) = makeSUT()
    sut.generateKeyIfNeeded()
    let plaintext = Data("super-secret-mdvm-token".utf8)

    let ciphertext = try sut.encrypt(plaintext)
    let decrypted = try sut.decrypt(ciphertext)

    #expect(ciphertext != plaintext)
    #expect(decrypted == plaintext)
  }

  @Test
  func encrypt_usesFreshNoncePerCall() throws {
    let (sut, _) = makeSUT()
    sut.generateKeyIfNeeded()
    let plaintext = Data("repeated-value".utf8)

    let first = try sut.encrypt(plaintext)
    let second = try sut.encrypt(plaintext)

    // AES-GCM uses a random nonce, so identical plaintext must yield different ciphertext.
    #expect(first != second)
  }

  @Test
  func encrypt_throwsWhenKeyMissing() {
    let (sut, _) = makeSUT()

    #expect(throws: WalletDataEncryptionError.keyUnavailable) {
      _ = try sut.encrypt(Data("x".utf8))
    }
  }

  @Test
  func decrypt_throwsWhenKeyMissing() {
    let (sut, _) = makeSUT()

    #expect(throws: WalletDataEncryptionError.keyUnavailable) {
      _ = try sut.decrypt(Data("x".utf8))
    }
  }

  @Test
  func decrypt_throwsOnTamperedCiphertext() throws {
    let (sut, _) = makeSUT()
    sut.generateKeyIfNeeded()
    var ciphertext = try sut.encrypt(Data("hello".utf8))

    // Flip the last byte to break the GCM authentication tag.
    ciphertext[ciphertext.count - 1] ^= 0xFF

    #expect(throws: WalletDataEncryptionError.decryptionFailed) {
      _ = try sut.decrypt(ciphertext)
    }
  }

  @Test
  func decrypt_throwsOnGarbageInput() {
    let (sut, _) = makeSUT()
    sut.generateKeyIfNeeded()

    #expect(throws: WalletDataEncryptionError.decryptionFailed) {
      _ = try sut.decrypt(Data("not-a-sealed-box".utf8))
    }
  }

  @Test
  func deleteKey_makesPreviouslyEncryptedDataUnreadable() throws {
    let (sut, _) = makeSUT()
    sut.generateKeyIfNeeded()
    let ciphertext = try sut.encrypt(Data("secret".utf8))

    sut.deleteKey()

    #expect(throws: WalletDataEncryptionError.keyUnavailable) {
      _ = try sut.decrypt(ciphertext)
    }
  }

  @Test
  func decrypt_failsAfterKeyRotation() throws {
    let (sut, storage) = makeSUT()
    sut.generateKeyIfNeeded()
    let ciphertext = try sut.encrypt(Data("bound-to-key".utf8))

    // Simulate a new key being provisioned (e.g. after a wipe + re-register).
    storage.storeKey(CryptoKit.SymmetricKey(size: .bits256))

    // Data sealed with the old key can no longer be opened with the new key.
    #expect(throws: WalletDataEncryptionError.decryptionFailed) {
      _ = try sut.decrypt(ciphertext)
    }
  }
}

// In-memory key store keeps the crypto tests deterministic and free of Keychain side effects.
private final class InMemorySymmetricKeyStorage: SymmetricKeyStorage, @unchecked Sendable {
  private var key: CryptoKit.SymmetricKey?

  func loadKey() -> CryptoKit.SymmetricKey? { key }
  func storeKey(_ key: CryptoKit.SymmetricKey) { self.key = key }
  func deleteKey() { key = nil }
}

private extension CryptoKit.SymmetricKey {
  var bytes: Data { withUnsafeBytes { Data($0) } }
}
