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
      logger: nil
    )
  }

  override func tearDown() {
    sut = nil
    pinSessionInteractor = nil
    issuanceCancellationInteractor = nil
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
    issuanceVarificationInteractor: IssuanceVerificationInteractor? = nil
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
      onPinEntered: nil,
      pinSessionInteractor: pinSessionInteractor,
      issuanceCancellationInteractor: issuanceCancellationInteractor,
      logger: nil
    )
  }

  private func makeConfig(
    pinScreenType: PINScreenType,
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
      pinScreenType: pinScreenType,
      pinForConfirmationFlow: pinForConfirmationFlow,
      finishAuthorizationResponseDTO: finishAuthorizationResponseDTO
    )
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

private enum TestError: Error {
  case expected
}
