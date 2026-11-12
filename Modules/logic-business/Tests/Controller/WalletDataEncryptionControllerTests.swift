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
  func loadOrCreateKey_createsKeyWhenMissing() throws {
    let (sut, storage) = makeSUT()
    #expect(storage.loadKey() == nil)

    let key = try sut.loadOrCreateKey()

    #expect(storage.loadKey()?.bytes == key.bytes)
  }

  @Test
  func loadOrCreateKey_isIdempotent() throws {
    let (sut, _) = makeSUT()
    let firstKey = try sut.loadOrCreateKey()

    let secondKey = try sut.loadOrCreateKey()

    // The key must not be regenerated on subsequent calls.
    #expect(firstKey.bytes == secondKey.bytes)
  }

  @Test
  func loadOrCreateKey_throwsWhenKeyCannotBeStored() {
    let (sut, storage) = makeSUT()
    storage.storeError = WalletDataEncryptionError.keyUnavailable

    #expect(throws: WalletDataEncryptionError.keyUnavailable) {
      _ = try sut.loadOrCreateKey()
    }
    #expect(storage.loadKey() == nil)
  }

  @Test
  func loadOrCreateKey_concurrentCallersConvergeOnOneKey() throws {
    let (sut, storage) = makeSUT()
    let bothLoaded = DispatchGroup()
    bothLoaded.enter()
    bothLoaded.enter()
    storage.afterLoad = {
      bothLoaded.leave()
      _ = bothLoaded.wait(timeout: .now() + 5)
    }
    let keys = KeyCollector()
    let finished = DispatchGroup()

    for _ in 0..<2 {
      finished.enter()
      Thread {
        keys.append(try? sut.loadOrCreateKey())
        finished.leave()
      }.start()
    }

    #expect(finished.wait(timeout: .now() + 5) == .success)
    storage.afterLoad = nil
    let storedKey = try #require(storage.loadKey())
    #expect(keys.all.count == 2)
    #expect(keys.all.allSatisfy { $0?.bytes == storedKey.bytes })
  }

  @Test
  func encryptThenDecrypt_roundTripsToOriginal() throws {
    let (sut, _) = makeSUT()
    _ = try sut.loadOrCreateKey()
    let plaintext = Data("super-secret-mdvm-token".utf8)

    let ciphertext = try sut.encrypt(plaintext)
    let decrypted = try sut.decrypt(ciphertext)

    #expect(ciphertext != plaintext)
    #expect(decrypted == plaintext)
  }

  @Test
  func encrypt_usesFreshNoncePerCall() throws {
    let (sut, _) = makeSUT()
    _ = try sut.loadOrCreateKey()
    let plaintext = Data("repeated-value".utf8)

    let first = try sut.encrypt(plaintext)
    let second = try sut.encrypt(plaintext)

    // AES-GCM uses a random nonce, so identical plaintext must yield different ciphertext.
    #expect(first != second)
  }

  @Test
  func encrypt_createsKeyWhenMissing() throws {
    let (sut, storage) = makeSUT()

    _ = try sut.encrypt(Data("x".utf8))

    #expect(storage.loadKey() != nil)
  }

  @Test
  func encrypt_throwsWhenKeyCannotBeStored() {
    let (sut, storage) = makeSUT()
    storage.storeError = WalletDataEncryptionError.keyUnavailable

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
    _ = try sut.loadOrCreateKey()
    var ciphertext = try sut.encrypt(Data("hello".utf8))

    // Flip the last byte to break the GCM authentication tag.
    ciphertext[ciphertext.count - 1] ^= 0xFF

    #expect(throws: WalletDataEncryptionError.authenticationFailed) {
      _ = try sut.decrypt(ciphertext)
    }
  }

  @Test
  func decrypt_throwsOnGarbageInput() throws {
    let (sut, _) = makeSUT()
    _ = try sut.loadOrCreateKey()

    #expect(throws: WalletDataEncryptionError.invalidCiphertextFormat) {
      _ = try sut.decrypt(Data("not-a-sealed-box".utf8))
    }
  }

  @Test
  func deleteKey_makesPreviouslyEncryptedDataUnreadable() throws {
    let (sut, _) = makeSUT()
    _ = try sut.loadOrCreateKey()
    let ciphertext = try sut.encrypt(Data("secret".utf8))

    sut.deleteKey()

    #expect(throws: WalletDataEncryptionError.keyUnavailable) {
      _ = try sut.decrypt(ciphertext)
    }
  }

  @Test
  func decrypt_failsAfterKeyRotation() throws {
    let (sut, storage) = makeSUT()
    _ = try sut.loadOrCreateKey()
    let ciphertext = try sut.encrypt(Data("bound-to-key".utf8))

    // Simulate a new key being provisioned (e.g. after a wipe + re-register).
    storage.deleteKey()
    _ = try storage.storeKey(CryptoKit.SymmetricKey(size: .bits256))

    // Data sealed with the old key can no longer be opened with the new key.
    #expect(throws: WalletDataEncryptionError.authenticationFailed) {
      _ = try sut.decrypt(ciphertext)
    }
  }
}

// In-memory key store keeps the crypto tests deterministic and free of Keychain side effects.
private final class InMemorySymmetricKeyStorage: SymmetricKeyStorage, @unchecked Sendable {
  private let lock = NSLock()
  private var key: CryptoKit.SymmetricKey?
  var storeError: Error?
  var afterLoad: (@Sendable () -> Void)?

  func loadKey() -> CryptoKit.SymmetricKey? {
    let loadedKey = lock.withLock { key }
    afterLoad?()
    return loadedKey
  }
  func storeKey(_ key: CryptoKit.SymmetricKey) throws -> CryptoKit.SymmetricKey {
    if let storeError { throw storeError }
    return lock.withLock {
      if let existingKey = self.key { return existingKey }
      self.key = key
      return key
    }
  }
  func deleteKey() { lock.withLock { key = nil } }
}

private final class KeyCollector: @unchecked Sendable {
  private let lock = NSLock()
  private var keys: [CryptoKit.SymmetricKey?] = []

  var all: [CryptoKit.SymmetricKey?] { lock.withLock { keys } }

  func append(_ key: CryptoKit.SymmetricKey?) { lock.withLock { keys.append(key) } }
}

private extension CryptoKit.SymmetricKey {
  var bytes: Data { withUnsafeBytes { Data($0) } }
}
