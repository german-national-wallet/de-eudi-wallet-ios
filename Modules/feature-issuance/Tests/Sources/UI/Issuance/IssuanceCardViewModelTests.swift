//
//  IssuanceCardViewModelTests.swift
//  IssuanceCardViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_api
import logic_core
import logic_resources
import logic_ui
@testable import feature_issuance

@MainActor
final class IssuanceCardViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockIssuanceCardInteractor!
  private var parInteractor: MockPARInteractor!
  private var issuanceVerificationInteractor: MockIssuanceVerificationInteractor!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var quickPinInteractor: MockQuickPinInteractor!
  private var delegate: MockIssuanceVerificationInteractorDelegate!
  private var connectivityMonitor: MockNetworkConnectivityMonitor!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockIssuanceCardInteractor()
    parInteractor = MockPARInteractor()
    issuanceVerificationInteractor = MockIssuanceVerificationInteractor()
    secureEnclaveController = MockSecureEnclaveController()
    quickPinInteractor = MockQuickPinInteractor()
    delegate = MockIssuanceVerificationInteractorDelegate()
    connectivityMonitor = .stubbed()
    stub(issuanceVerificationInteractor) { mock in
      when(mock.setDelegate(any())).thenDoNothing()
    }
  }

  override func tearDown() {
    connectivityMonitor = nil
    delegate = nil
    quickPinInteractor = nil
    secureEnclaveController = nil
    issuanceVerificationInteractor = nil
    parInteractor = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testStartAusweisReadFlow_WhenAuthenticationFlow_ThenStartsEIDScanning() throws {
    let sut = makeSUT(eidFlow: .authentication)
    let url = try XCTUnwrap(URL(string: "https://issuer.example/authorize"))
    stub(issuanceVerificationInteractor) { mock in
      when(mock.start(tokenURL: equal(to: url), pin: equal(to: "123456"))).thenDoNothing()
    }

    sut.startAusweisReadFlow()

    verify(issuanceVerificationInteractor).start(tokenURL: equal(to: url), pin: equal(to: "123456"))
  }

  func testStartAusweisReadFlow_WhenSetEIDPINFlow_ThenStartsPINChangeFlow() throws {
    let sut = makeSUT(eidFlow: .setEidPin)
    let url = try XCTUnwrap(URL(string: "https://issuer.example/authorize"))
    stub(issuanceVerificationInteractor) { mock in
      when(mock.startChangePinFlow(tokenURL: equal(to: url), transportPin: equal(to: "123456"))).thenDoNothing()
    }

    sut.startAusweisReadFlow()

    verify(issuanceVerificationInteractor).startChangePinFlow(tokenURL: equal(to: url), transportPin: equal(to: "123456"))
  }

  func testOnCANSubmission_WhenCANIsEntered_ThenDelegatesToVerificationInteractor() {
    let sut = makeSUT(eidFlow: .authentication)
    stub(issuanceVerificationInteractor) { mock in
      when(mock.setCAN(equal(to: "123456"))).thenDoNothing()
    }

    sut.enteredCan = "123456"
    sut.onCANSubmission()

    verify(issuanceVerificationInteractor).setCAN(equal(to: "123456"))
  }

  func testViewHelpAndTips_WhenCalled_ThenShowsHelpSheet() {
    let sut = makeSUT(eidFlow: .authentication)

    sut.viewHelpAndTips()

    XCTAssertTrue(sut.showHelpAndTipsActionSheet)
  }

  func testInvalidPinErrorReceived_WhenSetEIDPINFlow_ThenPushesTransportPinRetryScreen() {
    let sut = makeSUT(eidFlow: .setEidPin)
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.invalidPinErrorReceived(error: IssuanceWorkflowError.invalidPin, cardStatusInfo: nil)

    let config = capturedPinViewConfig()
    XCTAssertEqual(config?.pinScreenType, .transportPinRetryFlow)
    XCTAssertEqual(config?.quickPinSize, 5)
    XCTAssertEqual(config?.initialErrorMessage, .transportPinWrongEntry)
  }

  func testInvalidPinErrorReceived_WhenAuthenticationFlow_ThenPushesInvalidPinErrorScreenThatRetriesOnEidPinRetryScreen() {
    let sut = makeSUT(eidFlow: .authentication)
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.invalidPinErrorReceived(error: IssuanceWorkflowError.invalidPin, cardStatusInfo: nil)

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureCommonModule(.errorView(let config)) = captor.value,
          case .push(.featureIssuanceModule(.pinView(let pinConfig, _, _))) = (config as? UIConfig.InvalidPin)?.primaryActionNavigation else {
      return XCTFail("Expected the invalid PIN error view to push the eID PIN retry screen")
    }
    XCTAssertEqual((pinConfig as? UIConfig.Biometry)?.pinScreenType, .eidPinRetryFlow)
  }

  func testEidPinRetryRoute_WhenPinEntered_ThenResumesScanWithoutNewPARAndReturnsToScan() async throws {
    let sut = makeSUT(eidFlow: .authentication)
    let url = try XCTUnwrap(URL(string: "https://issuer.example/authorize"))
    let returned = expectation(description: "Wait for the scan screen to be shown again")
    stub(issuanceVerificationInteractor) { mock in
      when(mock.start(tokenURL: any(), pin: any())).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.popTo(with: any())).then { _ in returned.fulfill() }
    }

    guard case .featureIssuanceModule(.pinView(_, let onPinEntered, let verificationInteractor)) = sut.getEidPinRetryRoute() else {
      return XCTFail("Expected a PIN view route")
    }
    XCTAssertNotNil(verificationInteractor)
    onPinEntered?.onEntered("654321")

    await fulfillment(of: [returned], timeout: 1)
    verify(issuanceVerificationInteractor).start(tokenURL: equal(to: url), pin: equal(to: "654321"))
    verifyNoMoreInteractions(parInteractor)
    XCTAssertEqual(sut.enteredPin, "654321")
    XCTAssertTrue(sut.viewState.isLoading)
  }

  func testTransportPinRetryRoute_WhenPinEntered_ThenSendsPinToCardAndReturnsToScan() async {
    let sut = makeSUT(eidFlow: .setEidPin)
    let returned = expectation(description: "Wait for the scan screen to be shown again")
    stub(issuanceVerificationInteractor) { mock in
      when(mock.setPin(any())).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.pop()).then { returned.fulfill() }
    }

    guard case .featureIssuanceModule(.pinView(_, let onPinEntered, let verificationInteractor)) = sut.getTransportPinRetryRoute() else {
      return XCTFail("Expected a PIN view route")
    }
    XCTAssertNil(verificationInteractor)
    onPinEntered?.onEntered("54321")

    await fulfillment(of: [returned], timeout: 1)
    verify(issuanceVerificationInteractor, times(2)).setDelegate(any())
    verify(issuanceVerificationInteractor).setPin(equal(to: "54321"))
    XCTAssertTrue(sut.viewState.isLoading)
  }

  func testDidSuccess_WhenOffline_ThenShowsNoInternetDialogAndRetriesTheFinishAuthorization() async {
    let requested = expectation(description: "finish authorization requested twice")
    requested.expectedFulfillmentCount = 2
    let sut = makeSUT(eidFlow: .authentication)
    stub(interactor) { mock in
      when(mock.executeFinishAuthorizationRequest(equal(to: "https://issuer.example/redirect"))).then { _ in
        requested.fulfill()
        throw NetworkError.noInternet
      }
    }

    sut.didSuccess(result: "https://issuer.example/redirect")
    await waitUntil { sut.noInternetDialog.isPresented }
    XCTAssertTrue(sut.noInternetDialog.isPresented)

    sut.noInternetDialog.retry()
    await fulfillment(of: [requested], timeout: 5)
  }

  func testDidSuccess_WhenOfflineAndCancelTapped_ThenAbandonsIssuance() async {
    let sut = makeSUT(eidFlow: .authentication)
    stub(interactor) { mock in
      when(mock.executeFinishAuthorizationRequest(any())).thenThrow(NetworkError.noInternet)
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(false)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.didSuccess(result: "https://issuer.example/redirect")
    await waitUntil { sut.noInternetDialog.isPresented }
    sut.noInternetDialog.cancel()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    XCTAssertEqual(captor.value?.info.key, AppRoute.featureIssuanceModule(.issuanceAddDocument(config: NoConfig())).info.key)
  }

  func testDidSuccess_WhenWalletPinSetupInstructionsClosed_ThenReturnsToOverview() async {
    let sut = makeSUT(eidFlow: .authentication)
    let pushed = expectation(description: "PID preview pushed")
    stub(interactor) { mock in
      when(mock.executeFinishAuthorizationRequest(any())).thenReturn(
        FinishAuthorizationResponse(nonce: "nonce", code: "code", state: nil, location: "https://issuer.example/redirect")
      )
    }
    stub(issuanceVerificationInteractor) { mock in
      when(mock.stop()).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { _ in pushed.fulfill() }
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.didSuccess(result: "https://issuer.example/redirect")
    await fulfillment(of: [pushed], timeout: 1)

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceCardModule(.issuancePidPreviewView(let previewConfig)) = captor.value,
          case .featureIssuanceModule(.walletPinSetupInstructionView(let config)) = (previewConfig as? UIConfig.IssuancePidPreviewViewConfig)?.primaryRoute,
          let instructionsConfig = config as? UIConfig.InstructionsViewConfig else {
      return XCTFail("Expected the PID preview to lead to the wallet PIN setup instructions")
    }

    instructionsConfig.onClose?()

    let popCaptor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: popCaptor.capture())
    XCTAssertEqual(popCaptor.value?.info.key, AppRoute.featureDashboardModule(.dashboard).info.key)
  }

  func testTcTokenExpired_WhenOffline_ThenShowsNoInternetDialogInsteadOfErrorPopup() async {
    let sut = makeSUT(eidFlow: .authentication)
    stub(parInteractor) { mock in
      when(mock.removePendingDocs(of: any())).thenDoNothing()
      when(mock.issuePAR()).thenThrow(NetworkError.noInternet)
    }

    sut.tcTokenExpired()
    await waitUntil { sut.isErrorPopupVisible }
    XCTAssertTrue(sut.isErrorPopupVisible)
    sut.errorPopupViewModel.primaryAction?()
    await waitUntil { sut.noInternetDialog.isPresented }
    
    XCTAssertTrue(sut.noInternetDialog.isPresented)
    XCTAssertFalse(sut.isErrorPopupVisible)
  }

  private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<200 where !condition() {
      try? await Task.sleep(for: .milliseconds(10))
    }
  }

  private func capturedPinViewConfig() -> UIConfig.Biometry? {
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceModule(.pinView(let config, _, _)) = captor.value else {
      return nil
    }
    return config as? UIConfig.Biometry
  }

  // MARK: - Expired PAR

  func testTcTokenExpired_ThenAsksWhetherToStartAgain() async {
    let sut = makeSUT(eidFlow: .authentication)

    sut.tcTokenExpired()
    await waitUntil { sut.isErrorPopupVisible }

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(
      sut.errorPopupViewModel.title,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredTitle.toString
    )
    XCTAssertEqual(
      sut.errorPopupViewModel.detail,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredParagraph.toString
    )
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredPrimButton.toString
    )
    XCTAssertEqual(
      sut.errorPopupViewModel.secondaryButtontitle,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredSecButton.toString
    )
    verifyNoMoreInteractions(parInteractor)
  }

  func testTcTokenExpired_WhenCancelled_ThenUnwindsToTheStartScreen() async {
    let sut = makeSUT(eidFlow: .authentication)
    // The PID is re-added from the overview: add-document is not on the stack, the overview is.
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).then { route in
        if case .featureDashboardModule(.dashboard) = route { return true }
        return false
      }
      when(mock.popTo(with: any())).thenDoNothing()
    }
    sut.tcTokenExpired()
    await waitUntil { sut.isErrorPopupVisible }

    sut.errorPopupViewModel.onCancel()

    XCTAssertFalse(sut.isErrorPopupVisible)
    verify(router).popTo(with: equal(to: .featureDashboardModule(.dashboard)))
    verifyNoMoreInteractions(parInteractor)
  }

  func testTcTokenExpired_WhenStartAgain_ThenRequestsFreshPAR() async {
    let sut = makeSUT(eidFlow: .authentication)
    stub(parInteractor) { mock in
      when(mock.removePendingDocs(of: any())).thenDoNothing()
      when(mock.issuePAR()).thenThrow(NetworkError.httpError(code: 504, data: nil, headers: nil))
    }
    sut.tcTokenExpired()
    await waitUntil { sut.isErrorPopupVisible }

    // "Start again" hides the popup and kicks off the restart; the fresh PAR request's failure shows it again.
    // The title can't be the signal: the expired-PAR and timeout dialogs share the same title text.
    sut.errorPopupViewModel.onConfirm()
    XCTAssertFalse(sut.isErrorPopupVisible)
    await waitUntil { sut.isErrorPopupVisible }

    verify(parInteractor).removePendingDocs(of: equal(to: "https://issuer.example/authorize"))
    verify(parInteractor).issuePAR()
    XCTAssertTrue(sut.isErrorPopupVisible, "the fresh PAR's transport failure is shown as a timeout")
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalNoInternetErrorPrimButton.toString
    )
  }

  func testRestartAfterExpiredPAR_WhenNoAuthorizeURL_ThenStopsLoadingAndShowsError() async {
    let sut = makeSUT(eidFlow: .authentication)
    let pendingDoc = WalletStorage.Document(
      id: "par-document",
      docType: "testType",
      docDataFormat: .cbor,
      data: Data(),
      docKeyInfo: nil,
      createdAt: nil,
      metadata: nil,
      displayName: "Test Document",
      status: .pending
    )
    stub(parInteractor) { mock in
      when(mock.removePendingDocs(of: any())).thenDoNothing()
      when(mock.issuePAR()).thenReturn(pendingDoc)
    }

    await sut.restartIssuanceAfterExpiredPAR().value

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertTrue(sut.isErrorPopupVisible)
  }

  func testRestartAfterExpiredPAR_WhenRateLimited_ThenGotItOnlyClosesTheDialog() async {
    let sut = makeSUT(eidFlow: .authentication)
    stub(parInteractor) { mock in
      when(mock.removePendingDocs(of: any())).thenDoNothing()
      when(mock.issuePAR()).thenThrow(NetworkError.httpError(code: 429, data: nil, headers: ["Retry-After": "60"]))
    }

    await sut.restartIssuanceAfterExpiredPAR().value

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutTooManyRequestsTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalNoInternetErrorPrimButton.toString
    )
    XCTAssertNil(sut.errorPopupViewModel.secondaryButtontitle)

    sut.errorPopupViewModel.onConfirm()

    XCTAssertFalse(sut.isErrorPopupVisible)
    verify(router, never()).pop()
    verify(parInteractor, times(1)).issuePAR()
  }

  private func makeSUT(eidFlow: EidFlowType) -> IssuanceCardViewModel<MockRouterHost> {
    // Abandoning cancels the issuance in a detached task, so the stub has to exist even for
    // the tests that do not assert on it.
    let issuanceCancellationInteractor = MockIssuanceCancellationInteractor()
    stub(issuanceCancellationInteractor) { mock in
      when(mock.cancelIssuance(verificationInteractor: any())).thenDoNothing()
    }
    return IssuanceCardViewModel(
      router: router,
      interactor: interactor,
      parInteractor: parInteractor,
      issuanceVarificationInteractor: issuanceVerificationInteractor,
      secureEnclaveController: secureEnclaveController,
      quickPinInteractor: quickPinInteractor,
      analyticsController: AnalyticsControllerStub(),
      issuanceCancellationInteractor: issuanceCancellationInteractor,
      connectivityMonitor: connectivityMonitor,
      config: IssuanceFlowUiConfig(flow: .noDocument),
      requestURI: "https://issuer.example/authorize",
      eidPin: "123456",
      eidFlow: eidFlow,
      delegate: delegate,
      logger: nil
    )
  }
}
