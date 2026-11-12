//
//  PINViewModelTests.swift
//  PINViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_api
import logic_core
import logic_resources
import logic_ui
@testable import feature_common

@MainActor
final class PINViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockBiometryInteractor!
  private var prefsController: MockPrefsController!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var parInteractor: MockPARInteractor!
  private var pinSessionInteractor: MockPinSessionInteractor!
  private var issuanceCancellationInteractor: MockIssuanceCancellationInteractor!
  private var connectivityMonitor: MockNetworkConnectivityMonitor!
  private var presentationOriginStore: MockPresentationOriginStore!
  private var sut: PINViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockBiometryInteractor()
    prefsController = MockPrefsController()
    secureEnclaveController = MockSecureEnclaveController()
    parInteractor = MockPARInteractor()
    pinSessionInteractor = MockPinSessionInteractor()
    issuanceCancellationInteractor = MockIssuanceCancellationInteractor()
    connectivityMonitor = .stubbed()
    presentationOriginStore = MockPresentationOriginStore()
    stub(presentationOriginStore) { mock in
      when(mock.getServiceProviderURL()).thenReturn(nil)
    }
    stub(issuanceCancellationInteractor) { mock in
      when(mock.cancelIssuance(verificationInteractor: any())).thenDoNothing()
    }
    sut = PINViewModel(
      router: router,
      interactor: interactor,
      issuanceVarificationInteractor: nil,
      prefsController: prefsController,
      secureEnclaveController: secureEnclaveController,
      parInteractor: parInteractor,
      config: makeConfig(pinScreenType: .verifyWalletPinFlow),
      throttlePinInput: false,
      onPinEntered: nil,
      pinSessionInteractor: pinSessionInteractor,
      issuanceCancellationInteractor: issuanceCancellationInteractor,
      connectivityMonitor: connectivityMonitor,
      presentationOriginStore: presentationOriginStore,
      logger: nil
    )
  }

  override func tearDown() {
    sut = nil
    pinSessionInteractor = nil
    issuanceCancellationInteractor = nil
    connectivityMonitor = nil
    parInteractor = nil
    secureEnclaveController = nil
    prefsController = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testHandleInput_WhenDigitIsEntered_ThenAppendsDigitToPIN() {
    sut.handleInput("1")
    sut.handleInput("2")

    XCTAssertEqual(sut.pinString, "12")
  }

  func testHandleInput_WhenValueIsNotDigit_ThenIgnoresInput() {
    sut.handleInput("A")

    XCTAssertTrue(sut.pinString.isEmpty)
  }

  func testHandleBackspace_WhenPINHasDigits_ThenRemovesLastDigit() {
    sut.handleInput("1")
    sut.handleInput("2")

    sut.handleBackspace()

    XCTAssertEqual(sut.pinString, "1")
  }

  func testOnViewAppeared_WhenReturningAfterSubmit_ThenRestoresFocusAndResetsEntry() {
    enterPIN("111111")
    sut.isInvalidPin = true
    sut.canFocus = false

    sut.onViewAppeared()

    XCTAssertTrue(sut.canFocus)
    XCTAssertTrue(sut.pinString.isEmpty)
    XCTAssertFalse(sut.isInvalidPin)
  }

  func testOnViewAppeared_WhenConfigHasInitialError_ThenShowsIt() {
    sut = makeSUT(config: makeConfig(pinScreenType: .transportPinRetryFlow, initialErrorMessage: .transportPinWrongEntry))

    sut.onViewAppeared()

    XCTAssertTrue(sut.isInvalidPin)
    XCTAssertEqual(sut.errorMessage, LocalizableStringKey.transportPinWrongEntry.toString)
  }

  func testOnSendData_WhenTransportPinRetryFlow_ThenForwardsEnteredPin() async {
    let received = LockedValue<String?>(nil)
    sut = makeSUT(
      config: makeConfig(pinScreenType: .transportPinRetryFlow),
      onPinEntered: PinCallbackWrapper(onEntered: { received.set($0) })
    )
    enterPIN("54321")

    await sut.onSendData()

    XCTAssertEqual(received.get(), "54321")
  }

  func testOnSendData_WhenEidPinRetryFlow_ThenForwardsEnteredPin() async {
    let received = LockedValue<String?>(nil)
    sut = makeSUT(
      config: makeConfig(pinScreenType: .eidPinRetryFlow),
      onPinEntered: PinCallbackWrapper(onEntered: { received.set($0) })
    )
    enterPIN("654321")

    await sut.onSendData()

    XCTAssertEqual(received.get(), "654321")
  }

  func testDoNavigation_WhenNavigationTypePushes_ThenPushesRoute() {
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.doNavigation(navigationType: .push(.featureDashboardModule(.dashboard)))

    verify(router).push(with: any())
  }

  func testVerifyWalletPinFlow_WhenPinSessionFailsWithAttestationError_ThenShowsGenericError() async {
    var pushedRoute: AppRoute?
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        pushedRoute = route
      }
    }
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111")))
        .thenThrow(MDVMRepositoryError.serverError(
          code: "IOS_ATTESTATION_FAILURE",
          description: "Attestation failed",
          traceID: "trace-id"
        ))
    }

    enterPIN("111111")
    await sut.onSendData()
    await waitUntil { self.sut.isInvalidPin }

    XCTAssertNil(pushedRoute)
    XCTAssertTrue(sut.isInvalidPin)
    XCTAssertEqual(sut.errorMessage, LocalizableStringKey.genericErrorDesc.toString)
  }

  func testVerifyWalletPinFlow_WhenPinSessionFailsWithoutAttestationError_ThenMarksPinInvalid() async {
    var pushedRoute: AppRoute?
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        pushedRoute = route
      }
    }
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111")))
        .thenThrow(TestError.expected)
    }

    enterPIN("111111")
    await sut.onSendData()
    await waitUntil { self.sut.isInvalidPin }

    XCTAssertNil(pushedRoute)
    XCTAssertTrue(sut.isInvalidPin)
    XCTAssertEqual(sut.errorMessage, LocalizableStringKey.walletPinWrongEntry.toString)
  }

  func testConfirmNewWalletPinFlow_WhenPinSessionFailsWithoutAttestationError_ThenMarksPinInvalid() async {
    var pushedRoute: AppRoute?
    sut = makeSUT(
      config: makeConfig(
        pinScreenType: .confirmNewWalletPinFlow,
        pinForConfirmationFlow: "111111",
        finishAuthorizationResponseDTO: makeFinishAuthorizationResponse()
      )
    )
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        pushedRoute = route
      }
    }
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111")))
        .thenThrow(TestError.expected)
    }
    stub(prefsController) { mock in
      when(mock.setValue(any(), forKey: any())).thenDoNothing()
    }

    enterPIN("111111")
    await sut.onSendData()

    XCTAssertNil(pushedRoute)
    XCTAssertTrue(sut.isInvalidPin)
    XCTAssertEqual(sut.errorMessage, LocalizableStringKey.walletPinWrongEntry.toString)
  }

  func testConfirmNewWalletPinFlow_WhenOffline_ThenShowsNoInternetDialogInsteadOfWrongPin() async {
    sut = makeConfirmNewWalletPinSUT()
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.noInternet)
    }

    enterPIN("111111")
    await sut.onSendData()

    XCTAssertTrue(sut.noInternetDialog.isPresented)
    XCTAssertFalse(sut.isInvalidPin)
  }

  func testConfirmNewWalletPinFlow_WhenOfflineAndRetryTapped_ThenSetsTheSamePinAgain() async {
    let attempted = expectation(description: "pin set twice")
    attempted.expectedFulfillmentCount = 2
    sut = makeConfirmNewWalletPinSUT()
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).then { _ in
        attempted.fulfill()
        throw NetworkError.noInternet
      }
    }

    enterPIN("111111")
    await sut.onSendData()
    sut.pin.removeAll()
    sut.noInternetDialog.retry()
    await fulfillment(of: [attempted], timeout: 5)

    verify(pinSessionInteractor, times(2)).set(pin: equal(to: "111111"))
  }

  func testConfirmNewWalletPinFlow_WhenOfflineAndCancelTapped_ThenGoesBack() async {
    sut = makeConfirmNewWalletPinSUT()
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.noInternet)
    }
    stub(router) { mock in
      when(mock.pop()).thenDoNothing()
    }

    enterPIN("111111")
    await sut.onSendData()
    sut.noInternetDialog.cancel()

    verify(router).pop()
  }

  func testIssueEidPinFlow_WhenOffline_ThenShowsNoInternetDialogAndRetriesTheRequest() async {
    let requested = expectation(description: "PAR requested twice")
    requested.expectedFulfillmentCount = 2
    sut = makeSUT(config: makeConfig(pinScreenType: .issueEidPinFlow))
    stub(parInteractor) { mock in
      when(mock.fetchPushAuthorisationRequest()).then { _ in
        requested.fulfill()
        throw NetworkError.noInternet
      }
    }

    enterPIN("123456")
    await sut.onSendData()
    await waitUntil { self.sut.noInternetDialog.isPresented }
    XCTAssertFalse(sut.isInvalidPin)

    sut.noInternetDialog.retry()
    await fulfillment(of: [requested], timeout: 5)
  }

  func testTransportPinFlow_WhenOffline_ThenShowsNoInternetDialog() async {
    sut = makeSUT(config: makeConfig(pinScreenType: .transportPinFlow))
    stub(parInteractor) { mock in
      when(mock.fetchPushAuthorisationRequest()).thenThrow(NetworkError.noInternet)
    }

    enterPIN("12345")
    await sut.onSendData()
    await waitUntil { self.sut.noInternetDialog.isPresented }

    XCTAssertTrue(sut.noInternetDialog.isPresented)
  }

  // MARK: - Transport failures (timeout, rate limit)

  func testVerifyWalletPinFlow_WhenPinSessionTimesOut_ThenShowsTimeoutDialogInsteadOfWrongPin() async {
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }

    enterPIN("111111")
    await sut.onSendData()
    await waitUntil { self.sut.isErrorPopupVisible }

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertFalse(sut.isInvalidPin)
    XCTAssertFalse(sut.noInternetDialog.isPresented)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.pidPresentationTimeoutRpTitle.toString)
    XCTAssertEqual(sut.errorPopupViewModel.detail, LocalizableStringKey.pidPresentationTimeoutRpParagraph.toString)
    // No service provider URL is known, so "Cancel verification" is the only button.
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.pidPresentationTimeoutRpSecButton.toString
    )
    XCTAssertNil(sut.errorPopupViewModel.primaryButtonTrailingIcon)
    XCTAssertNil(sut.errorPopupViewModel.secondaryButtontitle)
  }

  func testVerifyWalletPinFlow_WhenPinSessionTimesOutWithServiceProviderURL_ThenOffersBackToServiceProvider() async {
    stub(presentationOriginStore) { mock in
      when(mock.getServiceProviderURL()).thenReturn(URL(string: "https://service-provider.example"))
    }
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }

    enterPIN("111111")
    await sut.onSendData()
    await waitUntil { self.sut.isErrorPopupVisible }

    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.pidPresentationTimeoutRpTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.pidPresentationTimeoutRpPrimButton.toString
    )
    XCTAssertNotNil(sut.errorPopupViewModel.primaryButtonTrailingIcon, "the external link icon marks leaving the app")
    XCTAssertEqual(
      sut.errorPopupViewModel.secondaryButtontitle,
      LocalizableStringKey.pidPresentationTimeoutRpSecButton.toString
    )
  }

  func testVerifyWalletPinFlow_WhenPinSessionTimesOut_ThenCancelVerificationClosesThePresentation() async {
    var closes = 0
    sut = makeSUT(config: makeConfig(pinScreenType: .verifyWalletPinFlow), onClose: { closes += 1 })
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }

    enterPIN("111111")
    await sut.onSendData()
    await waitUntil { self.sut.isErrorPopupVisible }

    sut.errorPopupViewModel.primaryAction?()

    XCTAssertFalse(sut.isErrorPopupVisible)
    XCTAssertEqual(closes, 1, "Cancel verification runs the presentation's own cancellation")
    verify(router, never()).pop()
    verify(pinSessionInteractor, times(1)).set(pin: any())
  }

  func testTransportPinFlow_WhenParRequestTimesOut_ThenOffersToStartAddingTheIdAgain() async {
    sut = makeSUT(config: makeConfig(pinScreenType: .transportPinFlow))
    stub(parInteractor) { mock in
      when(mock.fetchPushAuthorisationRequest()).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    enterPIN("12345")
    await sut.onSendData()
    await waitUntil { self.sut.isErrorPopupVisible }

    XCTAssertFalse(sut.isInvalidPin)
    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertEqual(
      sut.errorPopupViewModel.title,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredTitle.toString
    )

    sut.errorPopupViewModel.primaryAction?()

    XCTAssertFalse(sut.isErrorPopupVisible)
    verify(router).popTo(with: equal(to: .featureIssuanceModule(.issuanceOnboardingCardView)))
  }

  func testTransportPinFlow_WhenParRequestFails_ThenShowsInlineError() async {
    sut = makeSUT(config: makeConfig(pinScreenType: .transportPinFlow))
    stub(parInteractor) { mock in
      when(mock.fetchPushAuthorisationRequest()).thenThrow(PARGenerationError.wiaParCreationFailed)
    }

    enterPIN("12345")
    await sut.onSendData()
    await waitUntil { self.sut.isInvalidPin }

    XCTAssertTrue(sut.isInvalidPin)
    XCTAssertFalse(sut.isErrorPopupVisible)
    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertEqual(sut.errorMessage, LocalizableStringKey.genericErrorDesc.toString)
  }

  func testConfirmNewWalletPinFlow_WhenTimedOut_ThenOffersToStartAddingTheIdAgain() async {
    sut = makeConfirmNewWalletPinSUT()
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    enterPIN("111111")
    await sut.onSendData()

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertFalse(sut.isInvalidPin)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredPrimButton.toString
    )
    XCTAssertEqual(
      sut.errorPopupViewModel.secondaryButtontitle,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredSecButton.toString
    )

    sut.errorPopupViewModel.primaryAction?()

    XCTAssertFalse(sut.isErrorPopupVisible)
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    guard case .featureIssuanceModule(.issuanceOnboardingCardView) = captor.value else {
      return XCTFail("Expected to start over from the onboarding card")
    }
    verify(pinSessionInteractor, times(1)).set(pin: equal(to: "111111"))
  }

  func testConfirmNewWalletPinFlow_WhenTimedOutWithoutOnboardingCardOnStack_ThenStartsFromAddDocument() async {
    sut = makeConfirmNewWalletPinSUT()
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).then { route in
        if case .featureIssuanceModule(.issuanceAddDocument) = route { return true }
        return false
      }
      when(mock.popTo(with: any())).thenDoNothing()
    }

    enterPIN("111111")
    await sut.onSendData()
    sut.errorPopupViewModel.primaryAction?()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    guard case .featureIssuanceModule(.issuanceAddDocument) = captor.value else {
      return XCTFail("Expected to start over from the add document screen")
    }
  }

  func testConfirmNewWalletPinFlow_WhenTimedOutAndCancelTapped_ThenAbandonsTheIssuance() async {
    sut = makeConfirmNewWalletPinSUT()
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111"))).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    enterPIN("111111")
    await sut.onSendData()
    sut.errorPopupViewModel.secondaryAction?()

    XCTAssertFalse(sut.isErrorPopupVisible)
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    guard case .featureDashboardModule(.dashboard) = captor.value else {
      return XCTFail("Expected the overview to be popped to")
    }
  }

  func testConfirmNewWalletPinFlow_WhenRateLimited_ThenGotItOnlyClosesTheDialog() async {
    sut = makeConfirmNewWalletPinSUT()
    stub(pinSessionInteractor) { mock in
      when(mock.set(pin: equal(to: "111111")))
        .thenThrow(NetworkError.httpError(code: 429, data: nil, headers: ["Retry-After": "60"]))
    }

    enterPIN("111111")
    // The submit button disables the field before sending.
    sut.canFocus = false
    await sut.onSendData()

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutTooManyRequestsTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalNoInternetErrorPrimButton.toString
    )
    XCTAssertNil(sut.errorPopupViewModel.secondaryButtontitle)
    sut.errorPopupViewModel.primaryAction?()

    // A 429 keeps the user on the PIN screen: no navigation, no abandoned issuance, no retry.
    XCTAssertFalse(sut.isErrorPopupVisible)
    XCTAssertTrue(sut.canFocus, "the PIN field is usable again after Got it")
    verify(router, never()).pop()
    verify(router, never()).popTo(with: any())
    verify(issuanceCancellationInteractor, never()).cancelIssuance(verificationInteractor: any())
    verify(pinSessionInteractor, times(1)).set(pin: equal(to: "111111"))
  }

  func testIssueEidPinFlow_WhenParRequestTimesOut_ThenOffersToStartAddingTheIdAgain() async {
    sut = makeSUT(config: makeConfig(pinScreenType: .issueEidPinFlow))
    stub(parInteractor) { mock in
      when(mock.fetchPushAuthorisationRequest()).thenThrow(NetworkError.internetFailure(URLError(.timedOut)))
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    enterPIN("123456")
    await sut.onSendData()
    await waitUntil { self.sut.isErrorPopupVisible }
    XCTAssertFalse(sut.isInvalidPin)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredTitle.toString)

    sut.errorPopupViewModel.primaryAction?()

    XCTAssertFalse(sut.isErrorPopupVisible)
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    guard case .featureIssuanceModule(.issuanceOnboardingCardView) = captor.value else {
      return XCTFail("Expected to start over from the onboarding card")
    }
    verify(parInteractor, times(1)).fetchPushAuthorisationRequest()
  }

  func testConfirmNewWalletPinFlow_WhenPinsDoNotMatch_ThenShowsConfiguredInvalidPinMessage() async {
    sut = makeSUT(
      config: makeConfig(
        pinScreenType: .confirmNewWalletPinFlow,
        pinForConfirmationFlow: "111111",
        finishAuthorizationResponseDTO: makeFinishAuthorizationResponse()
      )
    )

    enterPIN("222222")
    await sut.onSendData()

    XCTAssertTrue(sut.isInvalidPin)
    XCTAssertEqual(sut.errorMessage, LocalizableStringKey.invalidQuickPin.toString)
  }

  func testHandleCloseButton_WhenIssuingTheEidPin_ThenUnwindsToTheStartScreen() {
    sut = makeSUT(config: makeConfig(pinScreenType: .issueEidPinFlow))
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.handleCloseButton()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    guard case .featureDashboardModule(.dashboard) = captor.value else {
      return XCTFail("Expected the overview to be popped to")
    }
  }

  func testHandleCloseButton_WhenRetryingTheEidPin_ThenAbandonsIssuanceAndUnwindsToTheStartScreen() async {
    sut = makeSUT(config: makeConfig(pinScreenType: .eidPinRetryFlow))
    let cancelled = expectation(description: "Wait for the issuance to be abandoned")
    stub(issuanceCancellationInteractor) { mock in
      when(mock.cancelIssuance(verificationInteractor: any())).then { _ in cancelled.fulfill() }
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.handleCloseButton()

    await fulfillment(of: [cancelled], timeout: 1)
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    guard case .featureDashboardModule(.dashboard) = captor.value else {
      return XCTFail("Expected the overview to be popped to")
    }
  }

  func testHandleCloseButton_WhenVerifyingWalletPinWithCloseAction_ThenRunsItInsteadOfNavigating() {
    var closeActionCallCount = 0
    sut = makeSUT(
      config: makeConfig(pinScreenType: .verifyWalletPinFlow),
      onClose: { closeActionCallCount += 1 }
    )

    sut.handleCloseButton()

    XCTAssertEqual(closeActionCallCount, 1)
    verify(router, never()).popTo(with: any())
    verify(router, never()).push(with: any())
  }

  func testHandleCloseButton_WhenVerifyingWalletPinWithoutCloseAction_ThenFallsBackToCloseNavigation() {
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.handleCloseButton()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    guard case .featureIssuanceModule(.issuanceAddDocument) = captor.value else {
      return XCTFail("Expected the default close navigation")
    }
  }

  func testCancelConfirmationConfig_WhenCloseActionIsSet_ThenUsesPresentationCopy() {
    sut = makeSUT(config: makeConfig(pinScreenType: .verifyWalletPinFlow), onClose: {})

    XCTAssertEqual(sut.cancelConfirmationConfig.title, .pidPresentationDialogCancelTitle)
    XCTAssertEqual(sut.cancelConfirmationConfig.confirmTitle, .pidPresentationDialogCancelPrimButton)
  }

  func testCancelConfirmationConfig_WhenNoCloseActionIsSet_ThenUsesIssuanceCopy() {
    XCTAssertEqual(sut.cancelConfirmationConfig.title, .pidIssuanceDialogCancelTitle)
    XCTAssertEqual(sut.cancelConfirmationConfig.confirmTitle, .pidIssuanceDialogCancelPrimButton)
  }

  // Without an interactor there is nothing to hand the instructions screen, so closing the sheet
  // is all this can do.
  func testSetCardPinTapped_WhenThereIsNoVerificationInteractor_ThenOnlyClosesTheSheet() {
    sut.isSheetPresented = true

    sut.setCardPinTapped()

    XCTAssertFalse(sut.isSheetPresented)
    verify(router, never()).push(with: any())
  }

  func testSetCardPinTapped_WhenThereIsAVerificationInteractor_ThenPushesTheInstructions() async {
    let verificationInteractor = MockIssuanceVerificationInteractor()
    stub(verificationInteractor) { mock in
      when(mock.delegate.set(any())).thenDoNothing()
    }
    sut = makeSUT(
      config: makeConfig(pinScreenType: .issueEidPinFlow),
      issuanceVarificationInteractor: verificationInteractor
    )
    let pushed = expectation(description: "Wait for the instructions to be pushed")
    stub(router) { mock in
      when(mock.push(with: any())).then { _ in
        pushed.fulfill()
      }
    }
    sut.isSheetPresented = true

    sut.setCardPinTapped()

    // The sheet has to be dismissed before the push, so the push is deferred rather than inline.
    XCTAssertFalse(sut.isSheetPresented)
    await fulfillment(of: [pushed], timeout: 2)
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceModule(.setEidTransportPinInstructionsView) = captor.value else {
      return XCTFail("Expected the transport-PIN instructions to be pushed")
    }
  }

  private func makeSUT(
    config: UIConfig.Biometry,
    issuanceVarificationInteractor: IssuanceVerificationInteractor? = nil,
    onPinEntered: PinCallbackWrapper? = nil,
    onClose: (@MainActor () -> Void)? = nil
  ) -> PINViewModel<MockRouterHost> {
    PINViewModel(
      router: router,
      interactor: interactor,
      issuanceVarificationInteractor: issuanceVarificationInteractor,
      prefsController: prefsController,
      secureEnclaveController: secureEnclaveController,
      parInteractor: parInteractor,
      config: config,
      throttlePinInput: false,
      onPinEntered: onPinEntered,
      pinSessionInteractor: pinSessionInteractor,
      issuanceCancellationInteractor: issuanceCancellationInteractor,
      connectivityMonitor: connectivityMonitor,
      presentationOriginStore: presentationOriginStore,
      logger: nil,
      onClose: onClose
    )
  }

  private func makeConfig(
    pinScreenType: PINScreenType,
    initialErrorMessage: LocalizableStringKey? = nil,
    pinForConfirmationFlow: String? = nil,
    finishAuthorizationResponseDTO: FinishAuthorizationResponse? = nil
  ) -> UIConfig.Biometry {
    UIConfig.Biometry(
      navigationTitle: .enterPassword,
      caption: .loginCaption,
      quickPinOnlyCaption: .loginCaptionQuickPinOnly,
      navigationSuccessType: .push(.featureDashboardModule(.dashboard)),
      navigationErrorScreen: nil,
      navigationBackType: .pop,
      isPreAuthorization: false,
      shouldInitializeBiometricOnCreate: false,
      invalidPinTitle: .invalidQuickPin,
      initialErrorMessage: initialErrorMessage,
      pinScreenType: pinScreenType,
      pinForConfirmationFlow: pinForConfirmationFlow,
      finishAuthorizationResponseDTO: finishAuthorizationResponseDTO
    )
  }

  private func makeConfirmNewWalletPinSUT() -> PINViewModel<MockRouterHost> {
    makeSUT(
      config: makeConfig(
        pinScreenType: .confirmNewWalletPinFlow,
        pinForConfirmationFlow: "111111",
        finishAuthorizationResponseDTO: makeFinishAuthorizationResponse()
      )
    )
  }

  private func waitUntil(_ condition: () -> Bool) async {
    for _ in 0..<200 where !condition() {
      try? await Task.sleep(for: .milliseconds(10))
    }
  }

  private func enterPIN(_ pin: String) {
    pin.forEach { sut.handleInput(String($0)) }
  }

  private func makeFinishAuthorizationResponse() -> FinishAuthorizationResponse {
    FinishAuthorizationResponse(
      nonce: "nonce",
      code: "code",
      state: "state",
      location: "location"
    )
  }

  private func waitUntil(
    timeout: TimeInterval = 1,
    condition: @escaping () -> Bool
  ) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition(), Date() < deadline {
      await Task.yield()
    }
  }
}

private final class LockedValue<Value>: @unchecked Sendable {
  private let lock = NSLock()
  private var value: Value

  init(_ value: Value) {
    self.value = value
  }

  func get() -> Value {
    lock.withLock { value }
  }

  func set(_ newValue: Value) {
    lock.withLock { value = newValue }
  }
}

private enum TestError: Error {
  case expected
}
