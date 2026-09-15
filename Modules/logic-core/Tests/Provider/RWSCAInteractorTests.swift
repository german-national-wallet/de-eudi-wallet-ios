//
//  RWSCAInteractorTests.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 11.03.26.
//

import Testing
import Foundation
import Security
import CryptoKit

@testable import logic_core
@testable import logic_business
@testable import logic_api
@testable import logic_test

@Suite("RWSCAInteractorImpl")
struct RWSCAInteractorTests {
  private var sut: RWSCAInteractorImpl!
  private var rwscaRepository: MockRWSCARepository!
  private var mdvmRepository: MockMDVMRepository!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var prefsController: MockPrefsController
  private var walletPinRepository: MockWalletPinRepository

  init() {
    rwscaRepository = MockRWSCARepository()
    mdvmRepository = MockMDVMRepository()
    secureEnclaveController = MockSecureEnclaveController()
    prefsController = MockPrefsController()
    walletPinRepository = MockWalletPinRepository()

    sut = RWSCAInteractorImpl(
      rwscaRepository: rwscaRepository,
      mdvmRepository: mdvmRepository,
      secureEnclaveController: secureEnclaveController,
      prefsController: prefsController,
      walletPinRepository: walletPinRepository
    )
  }

  @Test
  func register_Success() async throws {
    stub(rwscaRepository) { mock in
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.getRWSCAID()).thenReturn(nil)
    }
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    let privKey = makePrivateKey()
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(privKey)
    }
    stub(rwscaRepository) { mock in
      when(mock.register(mdvmToken: "mock_token", authChallenge: "mock_challenge", privateKey: any())).thenDoNothing()
    }

    try await sut.register(mdvmStoredRegistration: MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    verify(rwscaRepository).register(mdvmToken: "mock_token", authChallenge: "mock_challenge", privateKey: any())
  }

  @Test func register_Fails_ChallangeNotReceived() async throws {
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn(nil)
      when(mock.fetchChallenge()).thenThrow(RWSCARepositoryError.invalidResponse)
    }

    await #expect(throws: RWSCARepositoryError.invalidResponse) {
      try await sut.register(
        mdvmStoredRegistration: MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token")
      )
    }

    verify(rwscaRepository, never()).register(mdvmToken: any(), authChallenge: any(), privateKey: any())
  }

  @Test func register_Fails_RepositoryRegisterThrows() async throws {
    stub(rwscaRepository) { mock in
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.getRWSCAID()).thenReturn(nil)
    }
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    let privKey = makePrivateKey()
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(privKey)
    }
    stub(rwscaRepository) { mock in
      when(mock.register(mdvmToken: any(), authChallenge: any(), privateKey: any()))
        .thenThrow(RWSCARepositoryError.signingFailed)
    }

    await #expect(throws: RWSCARepositoryError.signingFailed) {
      try await sut.register(
        mdvmStoredRegistration: MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token")
      )
    }
  }

  @Test func register_SkipWhenRWSCAIDPresent() async throws {
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
    }
    try await sut.register(
      mdvmStoredRegistration: MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token")
    )
    
    verify(rwscaRepository, never()).fetchChallenge()
    verify(rwscaRepository, never()).register(mdvmToken: any(), authChallenge: any(), privateKey: any())
    verify(secureEnclaveController, never()).getOrCreatePrivateKey(with: any())
  }

  @Test func startPinSession_Success_Initialize() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.initializePinAndStartPinSession(
        mdvmToken: any(), challenge: any(), rwscaID: any(),
        pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
      )).thenReturn(RWSCAPinSessionResponse(rwscaPinSessionToken: "mock_pin_session_token"))
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
      when(mock.getPublicKeyInfo(from: any()))
        .thenReturn(PublicKeyInfo(x963: Data(), derBase64: "mock_public_key"))
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(false)
      when(mock.setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))).thenDoNothing()
    }
    let pinPrivKey = makePrivateKey()
    stub(walletPinRepository) { mock in
      when(mock.getPinPrivateKey(pin: any())).thenReturn(pinPrivKey)
    }
    let response = try await sut.startPinSession(pin: "123456")

    #expect(response.rwscaPinSessionToken == "mock_pin_session_token")
    verify(prefsController).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func startPINSession_WhenPINIsAlreadyInitialized_ThenStartsPINSessionWithoutSavingPrefs() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.startPinSession(
        mdvmToken: any(),
        challenge: any(),
        privateKey: any(),
        pinPrivateKey: any(),
        rwscaID: any()
      )).thenReturn(RWSCAPinSessionResponse(rwscaPinSessionToken: "mock_pin_session_token"))
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
      when(mock.getPublicKeyInfo(from: any()))
        .thenReturn(PublicKeyInfo(x963: Data(), derBase64: "mock_public_key"))
    }
    stub(walletPinRepository) { mock in
      when(mock.getPinPrivateKey(pin: any())).thenReturn(makePrivateKey())
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(true)
    }

    let response = try await sut.startPinSession(pin: "123456")

    #expect(response.rwscaPinSessionToken == "mock_pin_session_token")
    verify(rwscaRepository).startPinSession(
      mdvmToken: "mock_token",
      challenge: "mock_challenge",
      privateKey: any(),
      pinPrivateKey: any(),
      rwscaID: "mock_rwscaID"
    )
    verify(rwscaRepository, never()).initializePinAndStartPinSession(
      mdvmToken: any(),
      challenge: any(),
      rwscaID: any(),
      pinPrivateKey: any(),
      mdvmPrivateKey: any(),
      payload: any()
    )
    verify(prefsController, never()).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func startPinSession_Fails_MDVMNotRegistered() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(nil)
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(false)
    }

    await #expect(throws: RWSCARepositoryError.notRegistered) {
      try await sut.startPinSession(pin: "123456")
    }

    verify(rwscaRepository, never()).fetchChallenge()
    verify(rwscaRepository, never()).initializePinAndStartPinSession(
      mdvmToken: any(), challenge: any(), rwscaID: any(),
      pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
    )
  }

  @Test func startPinSession_Fails_RWSCANotRegistered() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn(nil)
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(false)
    }

    await #expect(throws: RWSCARepositoryError.notRegistered) {
      try await sut.startPinSession(pin: "123456")
    }

    verify(rwscaRepository, never()).fetchChallenge()
  }

  @Test func startPinSession_Fails_ChallengeNotReceived() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenThrow(RWSCARepositoryError.invalidResponse)
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(false)
    }

    await #expect(throws: RWSCARepositoryError.invalidResponse) {
      try await sut.startPinSession(pin: "123456")
    }

    verify(rwscaRepository, never()).initializePinAndStartPinSession(
      mdvmToken: any(), challenge: any(), rwscaID: any(),
      pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
    )
    verify(prefsController, never()).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func startPinSession_Fails_PinKeyDerivationFailed() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
    }
    stub(walletPinRepository) { mock in
      when(mock.getPinPrivateKey(pin: any())).thenThrow(PoPGenerationError.saltGenerationFailed)
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(false)
    }

    await #expect(throws: PoPGenerationError.saltGenerationFailed) {
      try await sut.startPinSession(pin: "123456")
    }

    verify(rwscaRepository, never()).initializePinAndStartPinSession(
      mdvmToken: any(), challenge: any(), rwscaID: any(),
      pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
    )
    verify(prefsController, never()).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func startPinSession_Fails_InitializeRepositoryThrows_DoesNotSavePrefs() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.initializePinAndStartPinSession(
        mdvmToken: any(), challenge: any(), rwscaID: any(),
        pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
      )).thenThrow(RWSCARepositoryError.signingFailed)
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
      when(mock.getPublicKeyInfo(from: any()))
        .thenReturn(PublicKeyInfo(x963: Data(), derBase64: "mock_public_key"))
    }
    stub(walletPinRepository) { mock in
      when(mock.getPinPrivateKey(pin: any())).thenReturn(makePrivateKey())
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(false)
    }

    await #expect(throws: RWSCARepositoryError.signingFailed) {
      try await sut.startPinSession(pin: "123456")
    }

    // Critical: isPinInitialized must NOT be saved if the repository call fails
    verify(prefsController, never()).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func startPinSession_Fails_ResumeRepositoryThrows() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.startPinSession(
        mdvmToken: any(), challenge: any(),
        privateKey: any(), pinPrivateKey: any(), rwscaID: any()
      )).thenThrow(RWSCARepositoryError.signingFailed)
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
      when(mock.getPublicKeyInfo(from: any()))
        .thenReturn(PublicKeyInfo(x963: Data(), derBase64: "mock_public_key"))
    }
    stub(walletPinRepository) { mock in
      when(mock.getPinPrivateKey(pin: any())).thenReturn(makePrivateKey())
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(true) // ← resume path
    }

    await #expect(throws: RWSCARepositoryError.signingFailed) {
      try await sut.startPinSession(pin: "123456")
    }

    verify(rwscaRepository, never()).initializePinAndStartPinSession(
      mdvmToken: any(), challenge: any(), rwscaID: any(),
      pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
    )
    verify(prefsController, never()).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func startPinSession_WhenInitReturnsPinAlreadyInitialized_ThenResumesAndSavesPrefs() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.initializePinAndStartPinSession(
        mdvmToken: any(), challenge: any(), rwscaID: any(),
        pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
      )).thenThrow(RWSCARepositoryError.serverError(
        code: RWSCAServerErrorCode.pinAlreadyInitialized, description: "", traceID: ""
      ))
      when(mock.startPinSession(
        mdvmToken: any(), challenge: any(),
        privateKey: any(), pinPrivateKey: any(), rwscaID: any()
      )).thenReturn(RWSCAPinSessionResponse(rwscaPinSessionToken: "mock_pin_session_token"))
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
      when(mock.getPublicKeyInfo(from: any()))
        .thenReturn(PublicKeyInfo(x963: Data(), derBase64: "mock_public_key"))
    }
    stub(walletPinRepository) { mock in
      when(mock.getPinPrivateKey(pin: any())).thenReturn(makePrivateKey())
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(false)
      when(mock.setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))).thenDoNothing()
    }

    let response = try await sut.startPinSession(pin: "123456")

    #expect(response.rwscaPinSessionToken == "mock_pin_session_token")
    verify(rwscaRepository).startPinSession(
      mdvmToken: any(), challenge: any(),
      privateKey: any(), pinPrivateKey: any(), rwscaID: any()
    )
    verify(prefsController).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func startPinSession_WhenResumeReturnsPinNotInitialized_ThenInitializesAndSavesPrefs() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.startPinSession(
        mdvmToken: any(), challenge: any(),
        privateKey: any(), pinPrivateKey: any(), rwscaID: any()
      )).thenThrow(RWSCARepositoryError.serverError(
        code: RWSCAServerErrorCode.pinNotInitialized, description: "", traceID: ""
      ))
      when(mock.initializePinAndStartPinSession(
        mdvmToken: any(), challenge: any(), rwscaID: any(),
        pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
      )).thenReturn(RWSCAPinSessionResponse(rwscaPinSessionToken: "mock_pin_session_token"))
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
      when(mock.getPublicKeyInfo(from: any()))
        .thenReturn(PublicKeyInfo(x963: Data(), derBase64: "mock_public_key"))
    }
    stub(walletPinRepository) { mock in
      when(mock.getPinPrivateKey(pin: any())).thenReturn(makePrivateKey())
    }
    stub(prefsController) { mock in
      when(mock.getBool(forKey: equal(to: Prefs.Key.isPinInitialized))).thenReturn(true)
      when(mock.setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))).thenDoNothing()
    }

    let response = try await sut.startPinSession(pin: "123456")

    #expect(response.rwscaPinSessionToken == "mock_pin_session_token")
    verify(rwscaRepository).initializePinAndStartPinSession(
      mdvmToken: any(), challenge: any(), rwscaID: any(),
      pinPrivateKey: any(), mdvmPrivateKey: any(), payload: any()
    )
    verify(prefsController).setValue(any(), forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func createKeys_Success() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.createKeys(
        mdvmToken: any(), challenge: any(), rwscaID: any(),
        mdvmPrivateKey: any(), payload: any()
      )).thenReturn(
        RWSCACreateKeysResponse(
          rwscaWIKeys: [.init(rwscdWIPubk: "pubk", rwscaWIWrappedPrvk: "wrapped-prvk")],
          rwscaWTE: "wte"
        )
      )
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
    }

    let response = try await sut.createKeys(numberOfKeys: 2, ppCNonce: "issuer-nonce")

    #expect(response.rwscaWIKeys.first?.rwscaWIWrappedPrvk == "wrapped-prvk")
    verify(rwscaRepository).createKeys(
      mdvmToken: "mock_token",
      challenge: "mock_challenge",
      rwscaID: "mock_rwscaID",
      mdvmPrivateKey: any(),
      payload: equal(to: RWSCACreateKeysPayload(numberOfKeys: 2, ppCNonce: "issuer-nonce"))
    )
  }

  @Test func createKeys_Fails_NotRegistered() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(nil)
    }

    await #expect(throws: RWSCARepositoryError.notRegistered) {
      try await sut.createKeys(numberOfKeys: 2, ppCNonce: "issuer-nonce")
    }

    verify(rwscaRepository, never()).createKeys(
      mdvmToken: any(), challenge: any(), rwscaID: any(), mdvmPrivateKey: any(), payload: any()
    )
  }

  @Test func createKeys_Fails_RepositoryThrows() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.createKeys(
        mdvmToken: any(), challenge: any(), rwscaID: any(),
        mdvmPrivateKey: any(), payload: any()
      )).thenThrow(RWSCARepositoryError.signingFailed)
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
    }

    await #expect(throws: RWSCARepositoryError.signingFailed) {
      try await sut.createKeys(numberOfKeys: 2, ppCNonce: "issuer-nonce")
    }
  }

  @Test func deleteAccount_Success() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.deleteAccount(
        mdvmToken: any(),
        challenge: any(),
        rwscaID: any(),
        mdvmPrivateKey: any()
      )).thenDoNothing()
    }
    stub(secureEnclaveController) { mock in
      when(mock.retrievePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(makePrivateKey())
    }
    stub(prefsController) { mock in
      when(mock.remove(forKey: equal(to: Prefs.Key.isPinInitialized))).thenDoNothing()
    }

    try await sut.deleteAccount()

    verify(rwscaRepository).deleteAccount(
      mdvmToken: "mock_token",
      challenge: "mock_challenge",
      rwscaID: "mock_rwscaID",
      mdvmPrivateKey: any()
    )
    verify(prefsController).remove(forKey: equal(to: Prefs.Key.isPinInitialized))
  }

  @Test func deleteAccount_Fails_NotRegistered() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration()).thenReturn(nil)
    }

    await #expect(throws: RWSCARepositoryError.notRegistered) {
      try await sut.deleteAccount()
    }

    verify(rwscaRepository, never()).fetchChallenge()
    verify(rwscaRepository, never()).deleteAccount(
      mdvmToken: any(),
      challenge: any(),
      rwscaID: any(),
      mdvmPrivateKey: any()
    )
  }

  @Test func deleteAccount_Fails_RepositoryThrows() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.deleteAccount(
        mdvmToken: any(),
        challenge: any(),
        rwscaID: any(),
        mdvmPrivateKey: any()
      )).thenThrow(RWSCARepositoryError.signingFailed)
    }
    stub(secureEnclaveController) { mock in
      when(mock.retrievePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(makePrivateKey())
    }

    await #expect(throws: RWSCARepositoryError.signingFailed) {
      try await sut.deleteAccount()
    }
  }

  @Test func deleteAccount_Fails_MissingRegistrationPrivateKey() async throws {
    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
    }
    stub(secureEnclaveController) { mock in
      when(mock.retrievePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(nil)
    }

    await #expect(throws: RWSCARepositoryError.notRegistered) {
      try await sut.deleteAccount()
    }

    verify(rwscaRepository, never()).fetchChallenge()
    verify(rwscaRepository, never()).deleteAccount(
      mdvmToken: any(),
      challenge: any(),
      rwscaID: any(),
      mdvmPrivateKey: any()
    )
  }

  @Test func signData_Success() async throws {
    let keyBindingData = Data("binding-data".utf8)
    let keyBindingDataHash = Data(SHA256.hash(data: keyBindingData)).base64EncodedString()

    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenReturn("mock_challenge")
      when(mock.signData(
        mdvmToken: any(), challenge: any(), rwscaID: any(),
        pinSessionToken: any(), mdvmPrivateKey: any(), payload: any()
      )).thenReturn(
        RWSCASignDataResponse(rwscdKeyBindingSignature: "binding-signature")
      )
    }
    stub(secureEnclaveController) { mock in
      when(mock.getOrCreatePrivateKey(with: any())).thenReturn(makePrivateKey())
    }

    let response = try await sut.signData(
      wrappedPrivateKey: "wrapped-prvk",
      keyBindingData: keyBindingData,
      pinSessionToken: "pin-session-token"
    )

    #expect(response.rwscdKeyBindingSignature == "binding-signature")
    verify(rwscaRepository).signData(
      mdvmToken: "mock_token",
      challenge: "mock_challenge",
      rwscaID: "mock_rwscaID",
      pinSessionToken: "pin-session-token",
      mdvmPrivateKey: any(),
      payload: equal(to: RWSCASignDataPayload(
        rwscaWIWrappedPrvk: "wrapped-prvk",
        wiKeyBindingDataHash: keyBindingDataHash
      ))
    )
  }

  @Test func signData_Fails_ChallengeNotReceived() async throws {
    let keyBindingData = Data("binding-data".utf8)

    stub(mdvmRepository) { mock in
      when(mock.getStoredRegistration())
        .thenReturn(MDVMStoredRegistration(mdvmWIID: "mock_wiid", mdvmToken: "mock_token"))
    }
    stub(rwscaRepository) { mock in
      when(mock.getRWSCAID()).thenReturn("mock_rwscaID")
      when(mock.fetchChallenge()).thenThrow(RWSCARepositoryError.invalidResponse)
    }

    await #expect(throws: RWSCARepositoryError.invalidResponse) {
      try await sut.signData(
        wrappedPrivateKey: "wrapped-prvk",
        keyBindingData: keyBindingData,
        pinSessionToken: "pin-session-token"
      )
    }

    verify(rwscaRepository, never()).signData(
      mdvmToken: any(), challenge: any(), rwscaID: any(),
      pinSessionToken: any(), mdvmPrivateKey: any(), payload: any()
    )
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
}
