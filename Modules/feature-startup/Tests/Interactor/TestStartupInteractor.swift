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
  var rwscaInteractor: MockRWSCAInteractor!
  var secureEnclaveController: MockSecureEnclaveController!
  var appBlockingController: MockAppBlockingController!
  var pushAuthorizationProvider: MockPushAuthorizationProvider!
  var pnsAccountInteractor: MockPNSAccountInteractor!

  override func setUp() {
    self.walletKitController = MockWalletKitController()
    self.quickPinInteractor = MockQuickPinInteractor()
    self.keyChainController = MockKeyChainController()
    self.prefsController = MockPrefsController()
    self.rwscaInteractor = MockRWSCAInteractor()
    self.secureEnclaveController = MockSecureEnclaveController()
    self.appBlockingController = MockAppBlockingController()
    self.pushAuthorizationProvider = MockPushAuthorizationProvider()
    self.pnsAccountInteractor = MockPNSAccountInteractor()

    self.interactor = StartupInteractorImpl(
      walletKitController: walletKitController,
      quickPinInteractor: quickPinInteractor,
      keyChainController: keyChainController,
      prefsController: prefsController,
      rwscaInteractor: rwscaInteractor,
      secureEnclaveController: secureEnclaveController,
      appBlockingController: appBlockingController,
      pushAuthorizationProvider: pushAuthorizationProvider,
      pnsAccountInteractor: pnsAccountInteractor
    )

    stubPrefsControllerSetValue()
    stubKeyChainClear()
    stubWalletKitControllerClearAllDocuments()
    stubStoredAppDataVersion(StartupInteractorImpl.currentAppDataVersion)
  }

  override func tearDown() {
    self.interactor = nil
    self.walletKitController = nil
    self.quickPinInteractor = nil
    self.keyChainController = nil
    self.prefsController = nil
    self.secureEnclaveController = nil
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
      when(mock.remove(forKey: equal(to: .hasSeenPlatformAuthIntro))).thenDoNothing()
      when(mock.remove(forKey: equal(to: .hasAcceptedPrivacyPolicy))).thenDoNothing()
      when(mock.remove(forKey: equal(to: .hasSeenPushIntro))).thenDoNothing()
      when(mock.remove(forKey: equal(to: .isAppSetupPending))).thenDoNothing()
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

  // MARK: - App data version tests

  func testInitialize_WhenNoAppDataVersionStored_ThenClearsAllDataAndStoresCurrentVersion() async {
    stubFetchDocuments(with: [])
    stubHasPin(with: false)
    stubRunAtLeastOnce(false)
    stubStoredAppDataVersion(nil)
    stubPrefsControllerRemove()

    _ = await interactor.initialize(with: .zero)

    for key in Prefs.Key.allCases {
      verify(prefsController, atLeastOnce()).remove(forKey: key)
    }
    verify(prefsController).setValue(isCurrentAppDataVersion(), forKey: Prefs.Key.appDataVersion)
    verifyFirstBootStorageManipulation(count: 1)
  }

  func testInitialize_WhenAppDataVersionUnchanged_ThenDoesNotClearData() async {
    stubFetchDocuments(with: [])
    stubHasPin(with: false)
    stubRunAtLeastOnce()

    _ = await interactor.initialize(with: .zero)

    verify(prefsController, never()).setValue(any(), forKey: Prefs.Key.appDataVersion)
    verify(prefsController, never()).remove(forKey: any())
    verifyFirstBootStorageManipulation(count: 0)
  }

  func testInitialize_WhenAppDataVersionChanged_ThenClearsAllDataAndStoresCurrentVersion() async {
    stubFetchDocuments(with: [])
    stubHasPin(with: false)
    stubRunAtLeastOnce(false)
    stubStoredAppDataVersion(StartupInteractorImpl.currentAppDataVersion + 1)
    stubPrefsControllerRemove()

    _ = await interactor.initialize(with: .zero)

    for key in Prefs.Key.allCases {
      verify(prefsController, atLeastOnce()).remove(forKey: key)
    }
    verify(prefsController).setValue(isCurrentAppDataVersion(), forKey: Prefs.Key.appDataVersion)
    verifyFirstBootStorageManipulation(count: 1)
  }

  // MARK: - Revocation code tests

  func testStoredRevocationCode_WhenCodeStored_ThenReturnsCode() throws {
    stubStoredRevocationCode("revocation-123")

    XCTAssertEqual(try interactor.storedRevocationCode(), "revocation-123")
  }

  func testStoredRevocationCode_WhenNoCodeStored_ThenReturnsNil() throws {
    stubStoredRevocationCode(nil)

    XCTAssertNil(try interactor.storedRevocationCode())
  }

  func testStoredRevocationCode_WhenCodeIsEmpty_ThenReturnsNil() throws {
    stubStoredRevocationCode("")

    XCTAssertNil(try interactor.storedRevocationCode())
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

  func stubStoredAppDataVersion(_ version: Any?) {
    stub(prefsController) { mock in
      when(mock.getValue(forKey: Prefs.Key.appDataVersion)).thenReturn(version)
    }
  }

  func isCurrentAppDataVersion() -> ParameterMatcher<Any?> {
    ParameterMatcher { ($0 as? Int) == StartupInteractorImpl.currentAppDataVersion }
  }

  func stubStoredRevocationCode(_ code: String?) {
    stub(secureEnclaveController) { mock in
      when(mock.retrieveDecryptedString(keyTag: equal(to: .wpbWiRevocationCode))).thenReturn(code)
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

  func stubPrefsControllerRemove() {
    stub(prefsController) { mock in
      when(mock.remove(forKey: any())).thenDoNothing()
    }
  }
}
