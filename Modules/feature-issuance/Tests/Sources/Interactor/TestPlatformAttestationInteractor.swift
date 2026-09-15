//
//  TestPlatformAttestationInteractor.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 13.11.24.
//

@testable import logic_test
@testable import logic_api
@testable import feature_issuance
@testable import logic_business

import DeviceCheck

final class TestPlatformAttestationInteractor: XCTestCase {
  var mockAttestationService: MockDCAppAttestService!
  var mockSecureEnclaveController: MockSecureEnclaveController!
  var sut: PlatformAttestationInteractorImpl!

  override func setUp() {
    super.setUp()
    mockAttestationService = MockDCAppAttestService(generateKeyResult: "", attestationResult: "".data(using: .utf8)!)
    mockSecureEnclaveController = MockSecureEnclaveController()
    sut = PlatformAttestationInteractorImpl(
      attestationService: mockAttestationService,
      secureEnclaveController: mockSecureEnclaveController
    )
  }

  override func tearDown() {
    sut = nil
    mockSecureEnclaveController = nil
    mockAttestationService = nil
    super.tearDown()
  }

  func testFetchAttestation_WhenNoKeyStored_GeneratesAndStoresKeyThenReturnsAttestation() async {
    let mockKeyId = "mockedKeyId"
    let expectedAttestation = Data("mockedAttestationData".utf8)
    let challengeData = Data("validChallenge".utf8)

    let service = MockDCAppAttestService(generateKeyResult: mockKeyId, attestationResult: expectedAttestation)
    stub(mockSecureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .mdvmAppAttestKeyID))).thenReturn(nil)
      when(mock.storeStringInKeychain(value: equal(to: mockKeyId), keyTag: equal(to: .mdvmAppAttestKeyID))).thenReturn(true)
    }
    sut = PlatformAttestationInteractorImpl(
      attestationService: service,
      secureEnclaveController: mockSecureEnclaveController
    )

    do {
      let result = try await sut.fetchAttestation(for: challengeData)
      XCTAssertEqual(result, expectedAttestation.base64EncodedString())
      verify(mockSecureEnclaveController).storeStringInKeychain(value: equal(to: mockKeyId), keyTag: equal(to: .mdvmAppAttestKeyID))
    } catch {
      XCTFail("Expected no error, but got \(error)")
    }
  }

  func testFetchAttestation_WhenKeyAlreadyStored_ReusesKeyWithoutGenerating() async {
    let storedKeyId = "storedKeyId"
    let expectedAttestation = Data("mockedAttestationData".utf8)
    let challengeData = Data("validChallenge".utf8)

    let service = MockDCAppAttestService(generateKeyResult: "shouldNotBeUsed", attestationResult: expectedAttestation)
    stub(mockSecureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .mdvmAppAttestKeyID))).thenReturn(storedKeyId)
    }
    sut = PlatformAttestationInteractorImpl(
      attestationService: service,
      secureEnclaveController: mockSecureEnclaveController
    )

    do {
      let result = try await sut.fetchAttestation(for: challengeData)
      XCTAssertEqual(result, expectedAttestation.base64EncodedString())
      XCTAssertEqual(service.attestedKeyId, storedKeyId)
      verify(mockSecureEnclaveController, never()).storeStringInKeychain(value: any(), keyTag: any())
    } catch {
      XCTFail("Expected no error, but got \(error)")
    }
  }

  func testFetchAssertion_WhenKeyAlreadyStored_UsesStoredKeyForAssertion() async {
    let storedKeyId = "storedKeyId"
    let expectedAssertion = Data("mockedAssertionData".utf8)
    let challengeData = Data("validChallenge".utf8)

    let service = MockDCAppAttestService(
      generateKeyResult: "shouldNotBeUsed",
      attestationResult: Data(),
      assertionResult: expectedAssertion
    )
    stub(mockSecureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .mdvmAppAttestKeyID))).thenReturn(storedKeyId)
    }
    sut = PlatformAttestationInteractorImpl(
      attestationService: service,
      secureEnclaveController: mockSecureEnclaveController
    )

    do {
      let result = try await sut.fetchAssertion(for: challengeData)
      XCTAssertEqual(result, expectedAssertion.base64EncodedString())
      XCTAssertEqual(service.assertedKeyId, storedKeyId)
    } catch {
      XCTFail("Expected no error, but got \(error)")
    }
  }

  func testFetchAttestation_WhenEmptyChallenge_ThrowsInvalidChallenge() async {
    do {
      _ = try await sut.fetchAttestation(for: Data())
      XCTFail("Expected error to be thrown")
    } catch let error as AppAttestationError {
      XCTAssertEqual(error, .invalidChallenge)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testFetchAttestation_WhenKeyGenerationFails_ThrowsKeyGenerationFailed() async {
    let service = MockDCAppAttestService(generateKeyResult: "", attestationResult: Data())
    stub(mockSecureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .mdvmAppAttestKeyID))).thenReturn(nil)
    }
    sut = PlatformAttestationInteractorImpl(
      attestationService: service,
      secureEnclaveController: mockSecureEnclaveController
    )

    do {
      _ = try await sut.fetchAttestation(for: Data("challenge".utf8))
      XCTFail("Expected error to be thrown")
    } catch let error as AppAttestationError {
      if case .keyGenerationFailed = error { XCTAssert(true) }
      else { XCTFail("Expected keyGenerationFailed, got \(error)") }
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}

// MARK: - TestFakeKeyChainController (helper class tests, unrelated to attestation)

final class TestFakeKeyChainController: XCTestCase {
  private var sut: FakeKeyChainController!
  private var key: FakeKeyChainWrapper!

  override func setUp() {
    super.setUp()
    sut = FakeKeyChainController()
    key = FakeKeyChainWrapper()
    key.value = "test-key"
  }

  override func tearDown() {
    sut = nil
    key = nil
    super.tearDown()
  }

  func testStoreStringValueStoresValueForKey() {
    sut.storeValue(key: key, value: "value-1")
    XCTAssertEqual(sut.getValue(key: key), "value-1")
  }

  func testStoreDataValueStoresAndReturnsData() {
    let data = Data("data-value".utf8)
    sut.storeValue(key: key, value: data)
    XCTAssertEqual(sut.getData(key: key), data)
  }

  func testRemoveObjectAddsKeyToRemovedKeysAndClearsStoredValues() {
    sut.storeValue(key: key, value: "value-1")
    sut.storeValue(key: key, value: Data("value-1".utf8))
    sut.removeObject(key: key)
    XCTAssertEqual(sut.removedKeys, ["test-key"])
    XCTAssertNil(sut.getValue(key: key))
    XCTAssertNil(sut.getData(key: key))
  }

  func testClearRemovesAllStoredState() {
    sut.storeValue(key: key, value: "value-1")
    sut.removeObject(key: key)
    sut.clear()
    XCTAssertTrue(sut.storedValues.isEmpty)
    XCTAssertTrue(sut.storedDataValues.isEmpty)
    XCTAssertTrue(sut.removedKeys.isEmpty)
  }
}

// MARK: - Helpers

final class FakeKeyChainWrapper: KeyChainWrapper {
  var value: String = ""
}

class FakeKeyChainController: KeyChainController {
  var storedValues: [String: String] = [:]
  var storedDataValues: [String: Data] = [:]
  var removedKeys: [String] = []
  var didValidateBiometry = false

  func storeValue(key: KeyChainWrapper, value: String) { storedValues[key.value] = value }
  func storeValue(key: any KeyChainWrapper, value: Data) { storedDataValues[key.value] = value }
  func getValue(key: any KeyChainWrapper) -> String? { storedValues[key.value] }
  func getData(key: any KeyChainWrapper) -> Data? { storedDataValues[key.value] }
  func removeObject(key: KeyChainWrapper) {
    removedKeys.append(key.value)
    storedValues.removeValue(forKey: key.value)
    storedDataValues.removeValue(forKey: key.value)
  }
  func validateKeyChainBiometry() throws { didValidateBiometry = true }
  func clearKeyChainBiometry() { didValidateBiometry = false }
  func clear() { storedValues.removeAll(); storedDataValues.removeAll(); removedKeys.removeAll(); didValidateBiometry = false }
  func clearAllKeychainItems() { clear() }
}

final class MockDCAppAttestService: DCAppAttestService {
  var generateKeyResult: String
  var attestationResult: Data
  var assertionResult: Data
  var attestedKeyId: String?
  var assertedKeyId: String?

  init(generateKeyResult: String, attestationResult: Data, assertionResult: Data = Data()) {
    self.generateKeyResult = generateKeyResult
    self.attestationResult = attestationResult
    self.assertionResult = assertionResult
  }

  override func generateKey() async throws -> String { generateKeyResult }

  override func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
    attestedKeyId = keyId
    return attestationResult
  }

  override func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
    assertedKeyId = keyId
    return assertionResult
  }
}
