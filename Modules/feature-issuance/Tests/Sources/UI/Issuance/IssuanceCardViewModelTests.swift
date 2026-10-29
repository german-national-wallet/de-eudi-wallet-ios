//
//  IssuanceCardViewModelTests.swift
//  IssuanceCardViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_core
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

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockIssuanceCardInteractor()
    parInteractor = MockPARInteractor()
    issuanceVerificationInteractor = MockIssuanceVerificationInteractor()
    secureEnclaveController = MockSecureEnclaveController()
    quickPinInteractor = MockQuickPinInteractor()
    delegate = MockIssuanceVerificationInteractorDelegate()
    stub(issuanceVerificationInteractor) { mock in
      when(mock.setDelegate(any())).thenDoNothing()
    }
  }

  override func tearDown() {
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

  func testInvalidPinErrorReceived_WhenAuthenticationFlow_ThenPushesInvalidPinErrorScreen() {
    let sut = makeSUT(eidFlow: .authentication)
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.invalidPinErrorReceived(error: IssuanceWorkflowError.invalidPin, cardStatusInfo: nil)

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureCommonModule(.errorView) = captor.value else {
      return XCTFail("Expected the invalid PIN error view")
    }
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

  private func capturedPinViewConfig() -> UIConfig.Biometry? {
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceModule(.pinView(let config, _, _)) = captor.value else {
      return nil
    }
    return config as? UIConfig.Biometry
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
      config: IssuanceFlowUiConfig(flow: .noDocument),
      requestURI: "https://issuer.example/authorize",
      eidPin: "123456",
      eidFlow: eidFlow,
      delegate: delegate,
      logger: nil
    )
  }
}
