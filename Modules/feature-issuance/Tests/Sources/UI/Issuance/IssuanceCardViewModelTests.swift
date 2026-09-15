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
