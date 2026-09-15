//
//  MDVMInteractorTests.swift
//  logic-core
//
//  Created by Tamas Dancsi on 18.02.26.
//

import Testing
import Foundation
import Security

@testable import logic_core
@testable import logic_business
@testable import logic_api
@testable import logic_feature_flags
@testable import logic_test

struct MDVMInteractorTests {

  private var sut: MDVMInteractorImpl!
  private var mdvmPrivateKey: SecKey!

  private let mockMDVMRepository = MockMDVMRepository()
  private let mockPlatformAttestationInteractor = MockPlatformAttestationInteractor()
  private let mockSecureEnclaveController = MockSecureEnclaveController()
  private let mockConfigLogic = MockConfigLogic()
  private let mockPrefsController = MockPrefsController()
  private let mockLogger = MockLogging()
  private let featureFlagRepositoryStub = FeatureFlagRepositoryStub()
  private let revocationStoreSpy = WalletRevocationStoreSpy()

  init() {
    mdvmPrivateKey = makePrivateKey()
    stub(mockPrefsController) { mock in
      when(mock.getString(forKey: equal(to: .mdvmInstallationIdentifier))).thenReturn("test-installation-id")
      when(mock.remove(forKey: equal(to: .mdvmInstallationIdentifier))).thenDoNothing()
    }
    stub(mockSecureEnclaveController) { mock in
      when(mock.deleteKeychainItem(keyTag: equal(to: .mdvmAppAttestKeyID))).thenDoNothing()
      when(mock.deletePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(true)
    }
    sut = MDVMInteractorImpl(
      mdvmRepository: mockMDVMRepository,
      platformAttestationInteractor: mockPlatformAttestationInteractor,
      secureEnclaveController: mockSecureEnclaveController,
      configLogic: mockConfigLogic,
      prefsController: mockPrefsController,
      featureFlagRepository: featureFlagRepositoryStub,
      walletRevocationStore: revocationStoreSpy,
      logger: mockLogger
    )
  }

  @Test
  func ensureFreshMDVMToken_WhenRegistrationMissingInDev_RegistersWithSkipIntegrityChecks() async throws {
    stub(mockConfigLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.DEV)
    }
    stub(mockSecureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(mdvmPrivateKey)
      when(mock.getPublicKeyInfo(from: equal(to: mdvmPrivateKey))).thenReturn(
        PublicKeyInfo(x963: Data([0x01, 0x02]), derBase64: "AQI=")
      )
    }
    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(nil)
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.register(
        payload: any(),
        authChallenge: equal(to: "challenge-value"),
        skipIntegrityChecks: equal(to: true),
        privateKey: any()
      )).thenDoNothing()
    }

    try await sut.ensureFreshMDVMToken()

    verify(mockPlatformAttestationInteractor, never()).fetchAttestation(for: any())
    verify(mockPlatformAttestationInteractor, never()).fetchAssertion(for: any())
    verify(mockPrefsController).remove(forKey: equal(to: .mdvmInstallationIdentifier))
    verify(mockSecureEnclaveController).deleteKeychainItem(keyTag: equal(to: .mdvmAppAttestKeyID))
    verify(mockSecureEnclaveController).deletePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))
    verify(mockMDVMRepository).register(
      payload: any(),
      authChallenge: equal(to: "challenge-value"),
      skipIntegrityChecks: equal(to: true),
      privateKey: any()
    )
  }

  @Test
  func ensureFreshMDVMToken_WhenRegistrationMissingInSandbox_SendsAttestationWithoutSkipIntegrityChecks() async throws {
    stub(mockConfigLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.SANDBOX)
    }
    stub(mockSecureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(mdvmPrivateKey)
      when(mock.getPublicKeyInfo(from: equal(to: mdvmPrivateKey))).thenReturn(
        PublicKeyInfo(x963: Data([0x01, 0x02]), derBase64: "AQI=")
      )
    }
    stub(mockPlatformAttestationInteractor) { mock in
      when(mock.fetchAttestation(for: any())).thenReturn("attestation")
      when(mock.fetchAssertion(for: any())).thenReturn("assertion")
    }
    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(nil)
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.register(
        payload: any(),
        authChallenge: equal(to: "challenge-value"),
        skipIntegrityChecks: equal(to: false),
        privateKey: any()
      )).thenDoNothing()
    }

    try await sut.ensureFreshMDVMToken()

    verify(mockPlatformAttestationInteractor).fetchAttestation(for: any())
    verify(mockPlatformAttestationInteractor).fetchAssertion(for: any())
  }

  @Test
  func ensureFreshMDVMToken_WhenStoredTokenStillFresh_DoesNothing() async throws {
    let validToken = makeJWT(expiration: Date().addingTimeInterval(60 * 60))

    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(
        MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: validToken)
      )
    }

    try await sut.ensureFreshMDVMToken()

    verify(mockMDVMRepository, never()).fetchChallenge()
    verify(mockMDVMRepository, never()).register(payload: any(), authChallenge: anyString(), skipIntegrityChecks: any(), privateKey: any())
    verify(mockMDVMRepository, never()).renew(payload: any(), mdvmWIID: anyString(), authChallenge: anyString(), skipIntegrityChecks: any(), privateKey: any())
  }

  @Test
  func ensureFreshMDVMToken_WhenStoredTokenIsNearExpiryInSandbox_RenewsWithoutSkipIntegrityChecks() async throws {
    featureFlagRepositoryStub.setMDVMTokenFreshnessBuffer("PT10M")
    let expiringToken = makeJWT(expiration: Date().addingTimeInterval(60))

    stub(mockConfigLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.SANDBOX)
    }
    stub(mockSecureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(mdvmPrivateKey)
      when(mock.getPublicKeyInfo(from: equal(to: mdvmPrivateKey))).thenReturn(
        PublicKeyInfo(x963: Data([0x01, 0x02]), derBase64: "AQI=")
      )
    }
    stub(mockPlatformAttestationInteractor) { mock in
      when(mock.fetchAssertion(for: any())).thenReturn("assertion")
    }
    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(
        MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: expiringToken)
      )
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.renew(
        payload: any(),
        mdvmWIID: equal(to: "mdvm-id"),
        authChallenge: equal(to: "challenge-value"),
        skipIntegrityChecks: equal(to: false),
        privateKey: any()
      )).thenDoNothing()
    }

    try await sut.ensureFreshMDVMToken()

    verify(mockMDVMRepository).renew(
      payload: any(),
      mdvmWIID: equal(to: "mdvm-id"),
      authChallenge: equal(to: "challenge-value"),
      skipIntegrityChecks: equal(to: false),
      privateKey: any()
    )
  }

  @Test
  func ensureFreshMDVMToken_WhenStoredTokenIsNearExpiryInDev_RenewsWithSkipIntegrityChecks() async throws {
    featureFlagRepositoryStub.setMDVMTokenFreshnessBuffer("PT10M")
    let expiringToken = makeJWT(expiration: Date().addingTimeInterval(60))

    stub(mockConfigLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.DEV)
    }
    stub(mockSecureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(mdvmPrivateKey)
      when(mock.getPublicKeyInfo(from: equal(to: mdvmPrivateKey))).thenReturn(
        PublicKeyInfo(x963: Data([0x01, 0x02]), derBase64: "AQI=")
      )
    }
    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(
        MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: expiringToken)
      )
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.renew(
        payload: any(),
        mdvmWIID: equal(to: "mdvm-id"),
        authChallenge: equal(to: "challenge-value"),
        skipIntegrityChecks: equal(to: true),
        privateKey: any()
      )).thenDoNothing()
    }

    try await sut.ensureFreshMDVMToken()

    verify(mockPlatformAttestationInteractor, never()).fetchAssertion(for: any())
    verify(mockMDVMRepository).renew(
      payload: any(),
      mdvmWIID: equal(to: "mdvm-id"),
      authChallenge: equal(to: "challenge-value"),
      skipIntegrityChecks: equal(to: true),
      privateKey: any()
    )
  }

  @Test
  func ensureFreshMDVMToken_WhenRenewalFailsWithIOSAttestationFailure_KeepsMDVMPersistedState() async throws {
    featureFlagRepositoryStub.setMDVMTokenFreshnessBuffer("PT10M")
    let expiringToken = makeJWT(expiration: Date().addingTimeInterval(60))

    stub(mockConfigLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.SANDBOX)
    }
    stub(mockSecureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(mdvmPrivateKey)
      when(mock.getPublicKeyInfo(from: equal(to: mdvmPrivateKey))).thenReturn(
        PublicKeyInfo(x963: Data([0x01, 0x02]), derBase64: "AQI=")
      )
    }
    stub(mockPlatformAttestationInteractor) { mock in
      when(mock.fetchAssertion(for: any())).thenReturn("assertion")
    }
    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(
        MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: expiringToken)
      )
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.renew(
        payload: any(),
        mdvmWIID: equal(to: "mdvm-id"),
        authChallenge: equal(to: "challenge-value"),
        skipIntegrityChecks: equal(to: false),
        privateKey: any()
      )).thenThrow(MDVMRepositoryError.serverError(
        code: "IOS_ATTESTATION_FAILURE",
        description: "The assertion's signature is invalid",
        traceID: "trace-id"
      ))
    }

    await #expect(throws: MDVMRepositoryError.serverError(
      code: "IOS_ATTESTATION_FAILURE",
      description: "The assertion's signature is invalid",
      traceID: "trace-id"
    )) {
      try await sut.ensureFreshMDVMToken()
    }

    // clearMDVMPersistedStateIfNeeded is intentionally a no-op: clearing MDVM state here without
    // also clearing the persistent auth key would strand the device (renew needs the attested key,
    // register is rejected as already-registered), so persisted state is kept and the error surfaces.
    verify(mockSecureEnclaveController, times(0)).deleteKeychainItem(keyTag: equal(to: .mdvmToken))
    verify(mockSecureEnclaveController, times(0)).deleteKeychainItem(keyTag: equal(to: .mdvmWIID))
    verify(mockSecureEnclaveController, times(0)).deleteKeychainItem(keyTag: equal(to: .mdvmAppAttestKeyID))
    verify(mockSecureEnclaveController, times(0)).deletePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))
    // Only an explicit REVOKED rejection may confirm a revocation, never another server error.
    #expect(revocationStoreSpy.markRevokedCallCount == 0)
  }

  @Test
  func ensureFreshMDVMToken_WhenRenewalIsRejectedAsRevoked_ConfirmsTheRevocation() async throws {
    // The path users who declined push notifications rely on: the regular renewal must confirm the
    // revocation too, otherwise only opted-in devices would ever self-lock.
    featureFlagRepositoryStub.setMDVMTokenFreshnessBuffer("PT10M")
    let expiringToken = makeJWT(expiration: Date().addingTimeInterval(60))

    stub(mockConfigLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.SANDBOX)
    }
    stub(mockSecureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(mdvmPrivateKey)
      when(mock.getPublicKeyInfo(from: equal(to: mdvmPrivateKey))).thenReturn(
        PublicKeyInfo(x963: Data([0x01, 0x02]), derBase64: "AQI=")
      )
    }
    stub(mockPlatformAttestationInteractor) { mock in
      when(mock.fetchAssertion(for: any())).thenReturn("assertion")
    }
    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(
        MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: expiringToken)
      )
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.renew(
        payload: any(),
        mdvmWIID: equal(to: "mdvm-id"),
        authChallenge: equal(to: "challenge-value"),
        skipIntegrityChecks: equal(to: false),
        privateKey: any()
      )).thenThrow(MDVMRepositoryError.serverError(
        code: MDVMServerErrorCode.revoked,
        description: "wallet instance is revoked",
        traceID: "trace-id"
      ))
    }

    // The error still surfaces to the caller; the self-lock is applied separately via the store.
    await #expect(throws: MDVMRepositoryError.serverError(
      code: MDVMServerErrorCode.revoked,
      description: "wallet instance is revoked",
      traceID: "trace-id"
    )) {
      try await sut.ensureFreshMDVMToken()
    }

    #expect(revocationStoreSpy.markRevokedCallCount == 1)
    #expect(revocationStoreSpy.isWalletRevoked)
  }

  @Test
  func ensureFreshMDVMToken_WhenBufferIsZeroAndTokenNotExpired_DoesNotRenew() async throws {
    featureFlagRepositoryStub.setMDVMTokenFreshnessBuffer("PT0M")
    let tokenWithOneMinuteLeft = makeJWT(expiration: Date().addingTimeInterval(60))

    stub(mockMDVMRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(
        MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: tokenWithOneMinuteLeft)
      )
    }

    try await sut.ensureFreshMDVMToken()

    verify(mockMDVMRepository, never()).renew(payload: any(), mdvmWIID: anyString(), authChallenge: anyString(), skipIntegrityChecks: any(), privateKey: any())
  }

  private func makePrivateKey() -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeEC,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      fatalError("Failed to create fake key: \(String(describing: error))")
    }
    return key
  }

  private func makeJWT(expiration: Date) -> String {
    let headerData = try? JSONSerialization.data(withJSONObject: ["alg": "HS256", "typ": "JWT"])
    let payloadData = try? JSONSerialization.data(withJSONObject: ["exp": Int(expiration.timeIntervalSince1970)])
    let header = (headerData ?? Data()).base64EncodedString().toBase64URL()
    let payload = (payloadData ?? Data()).base64EncodedString().toBase64URL()
    return "\(header).\(payload).signature"
  }
}

private final class WalletRevocationStoreSpy: WalletRevocationStore, @unchecked Sendable {
  private(set) var markRevokedCallCount = 0
  var isWalletRevoked = false

  func markRevoked() {
    markRevokedCallCount += 1
    isWalletRevoked = true
  }

  func clearRevoked() {
    isWalletRevoked = false
  }
}

private final class FeatureFlagRepositoryStub: FeatureFlagRepository, @unchecked Sendable {
  private var mdvmTokenFreshnessBuffer = "PT10M"

  func getFlagValue<T>(_ flag: FeatureFlag<T>) async -> T {
    if flag.key == FeatureFlag<String>.mdvmTokenFreshnessBuffer.key,
       let value = mdvmTokenFreshnessBuffer as? T {
      return value
    }
    return flag.defaultValue
  }

  func refreshFlagsIfNeeded() async {}

  func setMDVMTokenFreshnessBuffer(_ value: String) {
    mdvmTokenFreshnessBuffer = value
  }
}
