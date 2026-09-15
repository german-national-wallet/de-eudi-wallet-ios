/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import XCTest
import logic_business
import logic_core
@testable import feature_startup
@testable import logic_test
@testable import feature_test
@testable import feature_common

final class TestStartupInteractor: EudiTest {

  var interactor: StartupInteractor!
  var walletKitController: MockWalletKitController!
  var quickPinInteractor: MockQuickPinInteractor!
  var keyChainController: MockKeyChainController!
  var prefsController: MockPrefsController!
  var mdvmInteractor: MockMDVMInteractor!
  var rwscaInteractor: MockRWSCAInteractor!
  var secureEnclaveController: MockSecureEnclaveController!
  var pidRevokeInteractor: MockPIDRevokeInteractor!

  override func setUp() {
    self.walletKitController = MockWalletKitController()
    self.quickPinInteractor = MockQuickPinInteractor()
    self.keyChainController = MockKeyChainController()
    self.prefsController = MockPrefsController()
    self.mdvmInteractor = MockMDVMInteractor()
    self.rwscaInteractor = MockRWSCAInteractor()
    self.secureEnclaveController = MockSecureEnclaveController()
    self.pidRevokeInteractor = MockPIDRevokeInteractor()

    self.interactor = StartupInteractorImpl(
      walletKitController: walletKitController,
      quickPinInteractor: quickPinInteractor,
      keyChainController: keyChainController,
      prefsController: prefsController,
      mdvmInteractor: mdvmInteractor,
      rwscaInteractor: rwscaInteractor,
      secureEnclaveController: secureEnclaveController,
      pidRevokeInteractor: pidRevokeInteractor
    )

    stubPrefsControllerSetValue()
    stubKeyChainClear()
    stubWalletKitControllerClearAllDocuments()
    stubNoOldWallet()
  }

  override func tearDown() {
    self.interactor = nil
    self.walletKitController = nil
    self.quickPinInteractor = nil
    self.keyChainController = nil
    self.prefsController = nil
    self.secureEnclaveController = nil
    self.pidRevokeInteractor = nil
    super.tearDown()
  }

  // MARK: - Routing tests

  func testInitialize_WhenIsNotFirstBootAndPinIsNotSet_ThenReturnQuickPinAppRoute() async throws {
    let expectedConfig = QuickPinUiConfig(flow: .set)
    stubFetchDocuments(with: [Constants.euPidModel, Constants.isoMdlModel])
    stubHasPin(with: false)
    stubRunAtLeastOnce()

    let route = await interactor.initialize(with: .zero)

    switch route {
    case .featureCommonModule(let module):
      if case .quickPin(let config) = module {
        let receivedConfig = try XCTUnwrap(config as? QuickPinUiConfig)
        XCTAssertEqual(receivedConfig, expectedConfig)
      } else { XCTFail("Wrong route \(route)") }
    default: XCTFail("Wrong route \(route)")
    }
    verifyFirstBootStorageManipulation(count: 0)
  }

  func testInitialize_WhenIsNotFirstBootAndPinIsSetAndHasIssuedDocuments_ThenReturnBiometricsAppRouteWithNavigationSuccessDashboard() async throws {
    let expectedConfig = biometryConfig(with: true)
    stubFetchDocuments(with: [Constants.euPidModel, Constants.isoMdlModel])
    stubHasPin(with: true)
    stubRunAtLeastOnce()

    let route = await interactor.initialize(with: .zero)

    switch route {
    case .featureCommonModule(let module):
      if case .biometry(let config) = module {
        let receivedConfig = try XCTUnwrap(config as? UIConfig.Biometry)
        XCTAssertEqual(receivedConfig, expectedConfig)
      } else { XCTFail("Wrong route \(route)") }
    default: XCTFail("Wrong route \(route)")
    }
    verifyFirstBootStorageManipulation(count: 0)
  }

  func testInitialize_WhenIsNotFirstBootAndPinIsSetAndHasNoIssuedDocuments_ThenReturnBiometricsAppRouteWithNavigationSuccessAddDocument() async throws {
    let expectedConfig = biometryConfig(with: false)
    stubFetchDocuments(with: [])
    stubHasPin(with: true)
    stubRunAtLeastOnce()

    let route = await interactor.initialize(with: .zero)

    switch route {
    case .featureCommonModule(let module):
      if case .biometry(let config) = module {
        let receivedConfig = try XCTUnwrap(config as? UIConfig.Biometry)
        XCTAssertEqual(receivedConfig, expectedConfig)
      } else { XCTFail("Wrong route \(route)") }
    default: XCTFail("Wrong route \(route)")
    }
    verifyFirstBootStorageManipulation(count: 0)
  }

  func testInitialize_WhenIsFirstBootAndPinIsNotSet_ThenClearDocumentStorageAndReturnQuickPinAppRoute() async throws {
    let expectedConfig = QuickPinUiConfig(flow: .set)
    stubFetchDocuments(with: [Constants.euPidModel, Constants.isoMdlModel])
    stubHasPin(with: false)
    stubRunAtLeastOnce(false)
    stub(prefsController) { mock in
      when(mock.remove(forKey: equal(to: .isPinInitialized))).thenDoNothing()
      when(mock.remove(forKey: equal(to: .hasSeenRevocationCode))).thenDoNothing()
      when(mock.remove(forKey: equal(to: .hasSeenAppIntro))).thenDoNothing()
    }
    let route = await interactor.initialize(with: .zero)

    switch route {
    case .featureCommonModule(let module):
      if case .quickPin(let config) = module {
        let receivedConfig = try XCTUnwrap(config as? QuickPinUiConfig)
        XCTAssertEqual(receivedConfig, expectedConfig)
      } else { XCTFail("Wrong route \(route)") }
    default: XCTFail("Wrong route \(route)")
    }
    verifyFirstBootStorageManipulation(count: 1)
  }

  // MARK: - Migration tests

  func testInitialize_WhenOldWalletIDPresent_RunsMigrationBeforeRouting() async throws {
    stubFetchDocuments(with: [])
    stubHasPin(with: false)
    stubRunAtLeastOnce()
    stubOldWalletPresent()

    _ = await interactor.initialize(with: .zero)

    // Sentinel deleted
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .wiID))
    // SE private keys deleted
    verify(secureEnclaveController).deletePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))
    verify(secureEnclaveController).deletePrivateKey(with: equal(to: .wiaPrivateKey))
    // Stale WPB ID cleared
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .wbWIID))
    // Full wallet reset called
    verify(pidRevokeInteractor).deletePIDFromWallet()
  }

  func testInitialize_WhenNoOldWalletID_SkipsMigration() async throws {
    stubFetchDocuments(with: [])
    stubHasPin(with: false)
    stubRunAtLeastOnce()

    _ = await interactor.initialize(with: .zero)

    verify(secureEnclaveController, never()).deleteKeychainItem(keyTag: equal(to: .wiID))
    verify(pidRevokeInteractor, never()).deletePIDFromWallet()
  }

  // MARK: - Revocation code tests

  func testStoredRevocationCode_WhenCodeStored_ThenReturnsCode() {
    stubStoredRevocationCode("revocation-123")

    XCTAssertEqual(interactor.storedRevocationCode(), "revocation-123")
  }

  func testStoredRevocationCode_WhenNoCodeStored_ThenReturnsNil() {
    stubStoredRevocationCode(nil)

    XCTAssertNil(interactor.storedRevocationCode())
  }

  func testStoredRevocationCode_WhenCodeIsEmpty_ThenReturnsNil() {
    stubStoredRevocationCode("")

    XCTAssertNil(interactor.storedRevocationCode())
  }

  func testHasSeenRevocationCode_ReflectsStoredFlag() {
    stub(prefsController) { mock in
      when(mock.getBool(forKey: Prefs.Key.hasSeenRevocationCode)).thenReturn(true)
    }
    XCTAssertTrue(interactor.hasSeenRevocationCode())
  }

  func testHasSeenRevocationCode_WhenNotSet_ThenFalse() {
    stub(prefsController) { mock in
      when(mock.getBool(forKey: Prefs.Key.hasSeenRevocationCode)).thenReturn(false)
    }
    XCTAssertFalse(interactor.hasSeenRevocationCode())
  }

  func testMarkRevocationCodeSeen_ThenSetsFlag() {
    stub(prefsController) { mock in
      when(mock.setValue(any(), forKey: any())).thenDoNothing()
    }

    interactor.markRevocationCodeSeen()

    verify(prefsController).setValue(any(), forKey: Prefs.Key.hasSeenRevocationCode)
  }

  func testHasSeenAppIntro_ReflectsStoredFlag() {
    stub(prefsController) { mock in
      when(mock.getBool(forKey: Prefs.Key.hasSeenAppIntro)).thenReturn(true)
    }
    XCTAssertTrue(interactor.hasSeenAppIntro())
  }

  func testHasSeenAppIntro_WhenNotSet_ThenFalse() {
    stub(prefsController) { mock in
      when(mock.getBool(forKey: Prefs.Key.hasSeenAppIntro)).thenReturn(false)
    }
    XCTAssertFalse(interactor.hasSeenAppIntro())
  }

  func testMarkAppIntroSeen_ThenSetsFlag() {
    stub(prefsController) { mock in
      when(mock.setValue(any(), forKey: any())).thenDoNothing()
    }

    interactor.markAppIntroSeen()

    verify(prefsController).setValue(any(), forKey: Prefs.Key.hasSeenAppIntro)
  }

}

// MARK: - Stubs & helpers

private extension TestStartupInteractor {

  func stubFetchDocuments(with documents: [DocClaimsDecodable]) {
    stub(walletKitController) { mock in
      when(mock.loadDocuments()).thenDoNothing()
      when(mock.fetchAllDocuments()).thenReturn(documents)
      when(mock.fetchIssuedDocuments(with: any())).thenReturn(documents)
    }
  }

  func stubHasPin(with hasPin: Bool) {
    stub(quickPinInteractor) { mock in
      when(mock.hasPin()).thenReturn(hasPin)
    }
  }

  func stubRunAtLeastOnce(_ atLeastOnce: Bool = true) {
    stub(prefsController) { mock in
      when(mock.getBool(forKey: Prefs.Key.runAtLeastOnce)).thenReturn(atLeastOnce)
    }
  }

  func stubNoOldWallet() {
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .wiID))).thenReturn(nil)
    }
  }

  func stubStoredRevocationCode(_ code: String?) {
    stub(secureEnclaveController) { mock in
      when(mock.retrieveDecryptedString(keyTag: equal(to: .wpbWiRevocationCode))).thenReturn(code)
    }
  }

  func stubOldWalletPresent() {
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .wiID))).thenReturn("old-wallet-id")
      when(mock.deleteKeychainItem(keyTag: equal(to: .wiID))).thenDoNothing()
      when(mock.deletePrivateKey(with: equal(to: .wiMdvmAuthPrivateKey))).thenReturn(true)
      when(mock.deletePrivateKey(with: equal(to: .wiaPrivateKey))).thenReturn(true)
      when(mock.deletePrivateKey(with: equal(to: .custom("com.dewallet.registration.privateKey")))).thenReturn(true)
      when(mock.deleteKeychainItem(keyTag: equal(to: .wbWIID))).thenDoNothing()
      when(mock.deleteKeychainItem(keyTag: equal(to: .wpbWiRevocationCode))).thenDoNothing()
    }
    stub(pidRevokeInteractor) { mock in
      when(mock.deletePIDFromWallet()).thenDoNothing()
    }
  }

  func biometryConfig(with hasDocuments: Bool) -> UIConfig.Biometry {
    UIConfig.Biometry(
      navigationTitle: .custom(""),
      title: .loginTitle,
      caption: .loginCaption,
      quickPinOnlyCaption: .loginCaptionQuickPinOnly,
      navigationSuccessType: .push(.featureDashboardModule(.dashboard)),
      navigationErrorScreen: nil,
      navigationBackType: nil,
      isPreAuthorization: true,
      shouldInitializeBiometricOnCreate: true,
      invalidPinTitle: .issuanceErrorWrongCan,
      pinScreenType: .issueEidPinFlow
    )
  }

  func stubPrefsControllerSetValue() {
    stub(prefsController) { mock in
      when(mock.setValue(any(), forKey: any())).thenDoNothing()
    }
  }

  func stubKeyChainClear() {
    stub(keyChainController) { mock in
      when(mock.clear()).thenDoNothing()
      when(mock.clearAllKeychainItems()).thenDoNothing()
    }
  }

  func stubWalletKitControllerClearAllDocuments() {
    stub(walletKitController) { mock in
      when(mock.clearAllDocuments()).thenDoNothing()
    }
  }

  func verifyFirstBootStorageManipulation(count: Int) {
    verify(prefsController, times(count)).setValue(any(), forKey: Prefs.Key.runAtLeastOnce)
    verify(keyChainController, times(count)).clear()
    verify(keyChainController, times(count)).clearAllKeychainItems()
    verify(walletKitController, times(count)).clearAllDocuments()
  }
}
