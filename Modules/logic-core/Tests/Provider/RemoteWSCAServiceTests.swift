//
//  RemoteWSCAServiceTests.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 24.03.26.
//

import Testing
import Foundation
import Security
import MdocDataModel18013

@testable import logic_core
@testable import logic_business
@testable import logic_api
@testable import logic_test

@Suite("RemoteWSCAService")
struct RemoteWSCAServiceTests {
  private var sut: RemoteWSCAService
  private var rwscaInteractor: MockRWSCAInteractor
  private let nonceRepository: MockNonceRepository
  private let secureEnclaveController: MockSecureEnclaveController
  private let config: MockConfigLogic
  private var storage: StubSecureKeyStorage

  init() {
    rwscaInteractor = MockRWSCAInteractor()
    nonceRepository = MockNonceRepository()
    secureEnclaveController = MockSecureEnclaveController()

    storage = StubSecureKeyStorage()
    config = MockConfigLogic()

    stub(config) { mock in
      when(mock.vciIssuerURL.get).thenReturn("https://issuer.example.com")
    }
    stub(nonceRepository) { mock in
      when(mock.fetchNonce(baseURL: anyString())).thenReturn("mock-nonce")
    }
    stub(secureEnclaveController) { mock in
      when(mock.storeStringInKeychain(value: anyString(), keyTag: any())).thenReturn(true)
      when(mock.deleteKeychainItem(keyTag: any())).thenDoNothing()
    }

    sut = RemoteWSCAService(
      secureEnclaveController: secureEnclaveController,
      rwscaInteractor: rwscaInteractor,
      nonceRepository: nonceRepository,
      storage: storage,
      config: config
    )
  }

  // MARK: - createKeyBatch

  @Test func createKeyBatch_Success_ReturnsCoseKey() async throws {
    let validKey = makeValidBase64URLDERPublicKey()
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any())).thenReturn(
        RWSCACreateKeysResponse(
          rwscaWIKeys: [RWSCACreateKeysResponse.KeyInfo(rwscdWIPubk: validKey, rwscaWIWrappedPrvk: "wrapped-key")],
          rwscaWTE: "wte"
        )
      )
    }

    let coseKeys = try await sut.createKeyBatch(
      id: "test-id",
      credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
      keyOptions: nil
    )

    #expect(coseKeys.count == 1)
    let writeDataBatchCount = await storage.writeKeyDataBatchCallCount
    #expect(writeDataBatchCount == 1)
    let writeInfoCount = await storage.writeKeyInfoCallCount
    #expect(writeInfoCount == 1)
  }

  @Test func createKeyBatch_Success_WritesKeyBatchInfo_WhenMultipleKeys() async throws {
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any())).thenReturn(
        RWSCACreateKeysResponse(
          rwscaWIKeys: [
            RWSCACreateKeysResponse.KeyInfo(rwscdWIPubk: makeValidBase64URLDERPublicKey(), rwscaWIWrappedPrvk: "wrapped-key-1"),
            RWSCACreateKeysResponse.KeyInfo(rwscdWIPubk: makeValidBase64URLDERPublicKey(), rwscaWIWrappedPrvk: "wrapped-key-2")
          ],
          rwscaWTE: "wte"
        )
      )
    }

    let coseKeys = try await sut.createKeyBatch(
      id: "test-id",
      credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 2),
      keyOptions: nil
    )

    #expect(coseKeys.count == 2)
    let writeInfoCount = await storage.writeKeyInfoCallCount
    #expect(writeInfoCount == 1)
    let writeDataBatchCount = await storage.writeKeyDataBatchCallCount
    #expect(writeDataBatchCount == 1)
  }

  @Test func createKeyBatch_Fails_InteractorThrows() async throws {
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any()))
        .thenThrow(RWSCARepositoryError.invalidResponse)
    }

    await #expect(throws: RWSCARepositoryError.invalidResponse) {
      try await sut.createKeyBatch(
        id: "test-id",
        credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
        keyOptions: nil
      )
    }

    let writeCount = await storage.writeKeyDataBatchCallCount
    #expect(writeCount == 0)
  }

  @Test func createKeyBatch_Fails_NilInteractor() async throws {
    let storage = StubSecureKeyStorage()
    let sut = RemoteWSCAService(storage: storage)

    await #expect(throws: (any Error).self) {
      try await sut.createKeyBatch(
        id: "test-id",
        credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
        keyOptions: nil
      )
    }

    let writeCount = await storage.writeKeyDataBatchCallCount
    #expect(writeCount == 0)
  }

  @Test func createKeyBatch_SkipsInvalidPublicKeys() async throws {
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any())).thenReturn(
        RWSCACreateKeysResponse(
          rwscaWIKeys: [RWSCACreateKeysResponse.KeyInfo(rwscdWIPubk: "not-a-valid-key", rwscaWIWrappedPrvk: "wrapped-key")],
          rwscaWTE: "wte"
        )
      )
    }

    let coseKeys = try await sut.createKeyBatch(
      id: "test-id",
      credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
      keyOptions: nil
    )

    #expect(coseKeys.isEmpty)
  }

  // MARK: - signature

  @Test func signature_Success_ReturnsRawSignature() async throws {
    await storage.setKeyData(makeStoredKeyData())
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: any())).thenReturn("mock_pin_session_token")
    }
    
    stub(rwscaInteractor) { mock in
      when(mock.signData(wrappedPrivateKey: any(), keyBindingData: any(), pinSessionToken: any()))
        .thenReturn(RWSCASignDataResponse(rwscdKeyBindingSignature: makeValidDERSignatureBase64()))
    }

    let result = try await sut.signature(
      id: "test-id",
      index: 0,
      algorithm: .ES256,
      dataToSign: Data("test".utf8),
      unlockData: "pin-session-token".data(using: .utf8)
    )

    #expect(result.count == 64)
  }

  @Test func signature_Fails_WhenKeyNotFound() async throws {
    await storage.setShouldThrowOnRead(true)
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: any())).thenReturn("mock_pin_session_token")
    }

    await #expect(throws: (any Error).self) {
      try await sut.signature(
        id: "test-id",
        index: 0,
        algorithm: .ES256,
        dataToSign: Data("test".utf8),
        unlockData: "pin-session-token".data(using: .utf8)
      )
    }
  }

  @Test func signature_Fails_WhenInteractorThrows() async throws {
    await storage.setKeyData(makeStoredKeyData())
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: any())).thenReturn("mock_pin_session_token")
    }
    stub(rwscaInteractor) { mock in
      when(mock.signData(wrappedPrivateKey: any(), keyBindingData: any(), pinSessionToken: any()))
        .thenThrow(RWSCARepositoryError.invalidResponse)
    }

    await #expect(throws: RWSCARepositoryError.invalidResponse) {
      try await sut.signature(
        id: "test-id",
        index: 0,
        algorithm: .ES256,
        dataToSign: Data("test".utf8),
        unlockData: "pin-session-token".data(using: .utf8)
      )
    }
  }

  @Test func signature_Fails_WhenSignatureIsInvalidBase64() async throws {
    await storage.setKeyData(makeStoredKeyData())
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: any())).thenReturn("mock_pin_session_token")
    }
    stub(rwscaInteractor) { mock in
      when(mock.signData(wrappedPrivateKey: any(), keyBindingData: any(), pinSessionToken: any()))
        .thenReturn(RWSCASignDataResponse(rwscdKeyBindingSignature: "not-valid-base64!!!"))
    }

    await #expect(throws: (any Error).self) {
      try await sut.signature(
        id: "test-id",
        index: 0,
        algorithm: .ES256,
        dataToSign: Data("test".utf8),
        unlockData: "pin-session-token".data(using: .utf8)
      )
    }
  }

  @Test func signature_Fails_WhenNilInteractor() async throws {
    let isolatedStorage = StubSecureKeyStorage()
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: any())).thenReturn("mock_pin_session_token")
    }
    await isolatedStorage.setKeyData(makeStoredKeyData())
    let isolatedSut = RemoteWSCAService(storage: isolatedStorage)

    await #expect(throws: (any Error).self) {
      try await isolatedSut.signature(
        id: "test-id",
        index: 0,
        algorithm: .ES256,
        dataToSign: Data("test".utf8),
        unlockData: "pin-session-token".data(using: .utf8)
      )
    }
  }

  // MARK: - createKeyBatch (edge cases)

  @Test func createKeyBatch_ReturnsEmptyArray_WhenResponseHasNoKeys() async throws {
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any())).thenReturn(
        RWSCACreateKeysResponse(rwscaWIKeys: [], rwscaWTE: "wte")
      )
    }

    let coseKeys = try await sut.createKeyBatch(
      id: "test-id",
      credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
      keyOptions: nil
    )

    #expect(coseKeys.isEmpty)
    let writeCount = await storage.writeKeyDataBatchCallCount
    #expect(writeCount == 1)
  }

  // MARK: - signature (edge cases)

  @Test func signature_Fails_WhenKeyMetaDataIsCorrupt() async throws {
    await storage.setKeyData([kSecValueData as String: Data("not-valid-json".utf8)])
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: any())).thenReturn("mock_pin_session_token")
    }

    await #expect(throws: (any Error).self) {
      try await sut.signature(
        id: "test-id",
        index: 0,
        algorithm: .ES256,
        dataToSign: Data("test".utf8),
        unlockData: "pin-session-token".data(using: .utf8)
      )
    }
  }

  @Test func signature_PassesPinSessionTokenToSignData() async throws {
    await storage.setKeyData(makeStoredKeyData())
    let expectedToken = "expected-pin-session-token"
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: any())).thenReturn(expectedToken)
    }

    var capturedToken: String?
    stub(rwscaInteractor) { mock in
      when(mock.signData(wrappedPrivateKey: any(), keyBindingData: any(), pinSessionToken: any()))
        .then { _, _, token in
          capturedToken = token
          return RWSCASignDataResponse(rwscdKeyBindingSignature: self.makeValidDERSignatureBase64())
        }
    }

    _ = try await sut.signature(
      id: "test-id",
      index: 0,
      algorithm: .ES256,
      dataToSign: Data("test".utf8),
      unlockData: expectedToken.data(using: .utf8)
    )

    #expect(capturedToken == expectedToken)
  }

  // MARK: - WTE storage

  @Test func createKeyBatch_StoresWTEUnderKeyTag_WhenNoDocType() async throws {
    let validKey = makeValidBase64URLDERPublicKey()
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any())).thenReturn(
        RWSCACreateKeysResponse(
          rwscaWIKeys: [RWSCACreateKeysResponse.KeyInfo(rwscdWIPubk: validKey, rwscaWIWrappedPrvk: "wrapped-key")],
          rwscaWTE: "wte"
        )
      )
    }

    let coseKeys = try await sut.createKeyBatch(
      id: "test-id",
      credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
      keyOptions: nil
    )

    let expectedTag = RemoteWSCAService.wteKeychainTag(
      forKeyX: Data(try #require(coseKeys.first).x).base64URLEncodedString()
    )
    verify(secureEnclaveController).storeStringInKeychain(
      value: equal(to: "wte"),
      keyTag: equal(to: SecureEnclaveKeys.custom(expectedTag))
    )
  }

  @Test func createKeyBatch_StoresWTEUnderDocTypeOnly_WhenDocTypeGiven() async throws {
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any())).thenReturn(
        RWSCACreateKeysResponse(
          rwscaWIKeys: [
            RWSCACreateKeysResponse.KeyInfo(rwscdWIPubk: makeValidBase64URLDERPublicKey(), rwscaWIWrappedPrvk: "wrapped-key")
          ],
          rwscaWTE: "wte"
        )
      )
    }

    _ = try await sut.createKeyBatch(
      id: "test-id",
      credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
      keyOptions: KeyOptions(additionalOptions: Data("eu.europa.ec.eudi.pid.1".utf8))
    )

    // The credential path consumes the attestation by docType, so the key-derived tag must not be written too.
    verify(secureEnclaveController).storeStringInKeychain(
      value: equal(to: "wte"),
      keyTag: equal(to: SecureEnclaveKeys.custom("eu.europa.ec.eudi.pid.1"))
    )
    verify(secureEnclaveController, times(1)).storeStringInKeychain(value: anyString(), keyTag: any())
  }

  @Test func createKeyBatch_DoesNotStoreWTE_WhenEmpty() async throws {
    stub(rwscaInteractor) { mock in
      when(mock.createKeys(numberOfKeys: any(), ppCNonce: any())).thenReturn(
        RWSCACreateKeysResponse(
          rwscaWIKeys: [
            RWSCACreateKeysResponse.KeyInfo(rwscdWIPubk: makeValidBase64URLDERPublicKey(), rwscaWIWrappedPrvk: "wrapped-key")
          ],
          rwscaWTE: ""
        )
      )
    }

    _ = try await sut.createKeyBatch(
      id: "test-id",
      credentialOptions: CredentialOptions(credentialPolicy: .oneTimeUse, batchSize: 1),
      keyOptions: nil
    )

    verify(secureEnclaveController, never()).storeStringInKeychain(value: anyString(), keyTag: any())
  }

  // MARK: - deleteKeyBatch

  @Test func deleteKeyBatch_DelegatesToStorage() async throws {
    try await sut.deleteKeyBatch(id: "test-id", startIndex: 0, batchSize: 2)

    let count = await storage.deleteKeyBatchCallCount
    #expect(count == 1)
  }

  @Test func deleteKeyBatch_ClearsStoredWTEOfEachKey() async throws {
    // The stored mapping is what the tag is recovered from, so the batch has to be readable.
    await storage.setKeyData(makeStoredKeyData())
    let storedKeyX = Data([UInt8](repeating: 0x01, count: 32)).base64URLEncodedString()

    try await sut.deleteKeyBatch(id: "test-id", startIndex: 0, batchSize: 2)

    verify(secureEnclaveController, times(2)).deleteKeychainItem(
      keyTag: equal(to: SecureEnclaveKeys.custom(RemoteWSCAService.wteKeychainTag(forKeyX: storedKeyX)))
    )
  }

  @Test func deleteKeyBatch_SkipsWTEDeletion_WhenKeyMetaDataUnreadable() async throws {
    await storage.setShouldThrowOnRead(true)

    try await sut.deleteKeyBatch(id: "test-id", startIndex: 0, batchSize: 1)

    // Best effort: an unrecoverable tag must not fail the deletion of the keys themselves.
    verify(secureEnclaveController, never()).deleteKeychainItem(keyTag: any())
    let count = await storage.deleteKeyBatchCallCount
    #expect(count == 1)
  }

  // MARK: - deleteKeyInfo

  @Test func deleteKeyInfo_DoesNotThrow() async throws {
    try await sut.deleteKeyInfo(id: "test-id")
  }

  // MARK: - getPublicKey

  @Test func getPublicKey_ReturnsPublicKey_WhenKeyExists() async throws {
    await storage.setKeyData(makeStoredKeyData())

    let key = try await sut.getPublicKey(id: "test-id", index: 0, curve: .P256)

    #expect(key.crv == .P256)
  }

  @Test func getPublicKey_Throws_WhenKeyNotFound() async throws {
    await #expect(throws: (any Error).self) {
      try await sut.getPublicKey(id: "test-id", index: 0, curve: .P256)
    }
  }

  // MARK: - keyAgreement

  @Test func keyAgreement_AlwaysThrows() async throws {
    let dummyKey = CoseKey(crv: .P256, x963Representation: Data([0x04] + [UInt8](repeating: 0, count: 64)))
    await #expect(throws: (any Error).self) {
      try await sut.keyAgreement(id: "test-id", index: 0, publicKey: dummyKey, unlockData: nil)
    }
  }

  // MARK: - unlockKey

  @Test func unlockKey_ReturnsNil() async throws {
    let result = try await sut.unlockKey(id: "test-id")
    #expect(result == nil)
  }

  // MARK: - getStorage

  @Test func getStorage_ReturnsInjectedStorage() async {
    let returnedStorage = await sut.getStorage()
    #expect(returnedStorage as? StubSecureKeyStorage === storage)
  }

  // MARK: - Helpers

  private func makeStoredKeyData() -> [String: Data] {
    let x963Data = Data([0x04] + [UInt8](repeating: 0x01, count: 32) + [UInt8](repeating: 0x02, count: 32))
    let mappingData: [String: Any] = [
      "wrappedPrivateKey": "wrapped-key",
      "keyPurpose": [String](),
      "publicKey": ["x963Representation": x963Data.base64EncodedString()]
    ]
    // swiftlint:disable:next force_try
    let jsonData = try! JSONSerialization.data(withJSONObject: mappingData)
    return [kSecValueData as String: jsonData]
  }

  private func makeValidDERSignatureBase64() -> String {
    // DER ECDSA: 0x30 [totalLen] 0x02 [rLen] r... 0x02 [sLen] s...
    var der = Data()
    der.append(0x30)
    der.append(0x44) // total length = 68 (2+32 + 2+32)
    der.append(0x02)
    der.append(0x20) // r length = 32
    der.append(contentsOf: [UInt8](repeating: 0xAA, count: 32))
    der.append(0x02)
    der.append(0x20) // s length = 32
    der.append(contentsOf: [UInt8](repeating: 0xBB, count: 32))
    return der.base64EncodedString()
  }

  private func makeValidBase64URLDERPublicKey() -> String {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
          let publicKey = SecKeyCopyPublicKey(privateKey),
          let x963Data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
      fatalError("Failed to create test key: \(String(describing: error))")
    }
    // Standard DER SubjectPublicKeyInfo header for P-256 (26 bytes).
    // getX963Representation expects: [0]=0x30, [23]=0x03, [25]=0x00, [26]=0x04
    let derHeader = Data([
      0x30, 0x59, 0x30, 0x13, 0x06, 0x07,
      0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
      0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07,
      0x03, 0x42, 0x00
    ])
    // x963Data is 65 bytes: 0x04 + 32 bytes X + 32 bytes Y
    return (derHeader + x963Data).base64URLEncodedString()
  }
}

// MARK: - StubSecureKeyStorage

actor StubSecureKeyStorage: SecureKeyStorage {
  var writeKeyDataBatchCallCount = 0
  var writeKeyInfoCallCount = 0
  var writeRWSCACreateKeysResponseCallCount = 0
  var deleteKeyBatchCallCount = 0
  var deleteKeyInfoCallCount = 0
  var keyDataToReturn: [String: Data] = [:]
  var shouldThrowOnRead = false

  func setKeyData(_ dict: [String: Data]) {
    keyDataToReturn = dict
  }

  func setShouldThrowOnRead(_ value: Bool) {
    shouldThrowOnRead = value
  }

  func readRWSCACreateKeysResponse(id: String) async throws -> [String: Data] { [:] }

  func readKeyData(id: String, index: Int) async throws -> [String: Data] {
    if shouldThrowOnRead { throw SecureAreaError("Stub read error") }
    return keyDataToReturn
  }

  func writeRWSCACreateKeysResponse(id: String, dict: [String: Data]) async throws {
    writeRWSCACreateKeysResponseCallCount += 1
  }

  func writeKeyDataBatch(id: String, startIndex: Int, dicts: [[String: Data]], keyOptions: KeyOptions?) async throws {
    writeKeyDataBatchCallCount += 1
  }

  func deleteKeyBatch(id: String, startIndex: Int, batchSize: Int) async throws {
    deleteKeyBatchCallCount += 1
  }

  func deleteRWSCACreateKeysResponse(id: String) async throws {}

  func readKeyInfo(id: String) async throws -> [String: Data] {
    [:]
  }

  func writeKeyInfo(id: String, dict: [String: Data]) async throws {
    writeKeyInfoCallCount += 1
  }

  func deleteKeyInfo(id: String) async throws {
    deleteKeyInfoCallCount += 1
  }
}
