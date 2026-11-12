//
//  IssuanceLoadingViewModelTests.swift
//  IssuanceLoadingViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_api
import logic_core
import feature_test
import logic_analytics
import logic_resources
import logic_ui
@testable import feature_issuance

@MainActor
final class IssuanceLoadingViewModelTests: XCTestCase {

  func testPerformWalletRegistration_WhenPrivateKeyCannotBeCreated_ThenDoesNotRequestCredentials() async {
    let secureEnclaveController = MockSecureEnclaveController()
    let addDocumentInteractor = MockAddDocumentInteractor()
    let analyticsController = MockAnalyticsController()
    let pinSessionInteractor = MockPinSessionInteractor()
    let sut = makeSUT(
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor
    )
    stub(secureEnclaveController) { mock in
      when(mock.createPrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(nil)
    }
    stub(analyticsController) { mock in
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }

    await sut.issueCredentials()

    verify(secureEnclaveController).createPrivateKey(with: equal(to: .credentialPrivKey))
    verify(addDocumentInteractor, never()).getCredentials(docTypeIdentifier: any(), any(), privateKey: any())
    verify(pinSessionInteractor).clear()
    verify(analyticsController).endTrace(finalAttributes: any(), errorDescription: notNil())
  }

  func testConfigureErrorPopupViewModel_WhenCalled_ThenShowsPopup() {
    let sut = makeSUT()

    sut.configureErrorPopupViewModel(error: .invalidResponse)

    XCTAssertTrue(sut.errorPopupViewModel.isVisible)
  }

  func testPerformWalletRegistration_WhenCredentialsAreIssued_ThenClearsPinSession() async throws {
    let secureEnclaveController = MockSecureEnclaveController()
    let addDocumentInteractor = MockAddDocumentInteractor()
    let analyticsController = MockAnalyticsController()
    let pinSessionInteractor = MockPinSessionInteractor()
    let router = MockRouterHost()
    let privateKey = SecKeyMock.generateFakePrivateKey()
    let sut = makeSUT(
      router: router,
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor
    )
    stub(secureEnclaveController) { mock in
      when(mock.createPrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(privateKey)
      when(mock.storePrivateKey(any(), with: equal(to: .credentialPrivKey))).thenReturn(true)
    }
    stub(addDocumentInteractor) { mock in
      when(mock.getCredentials(docTypeIdentifier: any(), any(), privateKey: any())).thenReturn(true)
    }
    stub(analyticsController) { mock in
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.issueCredentials()

    verify(pinSessionInteractor).clear()
    verify(analyticsController).endTrace(finalAttributes: equal(to: [:]), errorDescription: isNil())
    XCTAssertTrue(sut.isIssued)
    verifyNoMoreInteractions(router)
  }

  func testSuccessAnimationFinished_WhenCalledTwice_ThenLeavesTheFlowOnce() {
    let router = MockRouterHost()
    let sut = makeSUT(router: router)
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.successAnimationFinished()
    sut.successAnimationFinished()

    verify(router, times(1)).popTo(with: any())
  }

  func testPerformWalletRegistration_WhenIssuanceFails_ThenEndsTraceWithErrorAndShowsTraceIdInPopup() async {
    let secureEnclaveController = MockSecureEnclaveController()
    let addDocumentInteractor = MockAddDocumentInteractor()
    let analyticsController = MockAnalyticsController()
    let pinSessionInteractor = MockPinSessionInteractor()
    let privateKey = SecKeyMock.generateFakePrivateKey()
    let sut = makeSUT(
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor
    )
    stub(secureEnclaveController) { mock in
      when(mock.createPrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(privateKey)
      when(mock.storePrivateKey(any(), with: equal(to: .credentialPrivKey))).thenReturn(true)
    }
    stub(addDocumentInteractor) { mock in
      when(mock.getCredentials(docTypeIdentifier: any(), any(), privateKey: any()))
        .thenThrow(RWSCARepositoryError.invalidResponse)
    }
    stub(analyticsController) { mock in
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }

    await sut.issueCredentials()

    verify(pinSessionInteractor).clear()
    verify(analyticsController).endTrace(finalAttributes: any(), errorDescription: notNil())
    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.traceId, "trace-id")
  }

  func testPerformWalletRegistration_WhenGatewayTimesOut_ThenSlowInternetPopupOnlyAcknowledges() async {
    let (sut, mocks) = makeFailingSUT(throwing: NetworkError.httpError(code: 504, data: nil, headers: nil))

    await sut.issueCredentials()

    verify(mocks.pinSessionInteractor).clear()
    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalNoInternetErrorPrimButton.toString
    )
    XCTAssertNil(sut.errorPopupViewModel.secondaryButtontitle)
    XCTAssertTrue(sut.errorPopupViewModel.traceId.isEmpty, "transport failures show no trace ID")
    verify(mocks.analyticsController).endTrace(
      finalAttributes: equal(to: [AnalyticsConstants.TraceAttribute.errorCode: "504"]),
      errorDescription: equal(to: "TransportFailure timeout via walletBackend status 504")
    )

    sut.errorPopupViewModel.onConfirm()

    XCTAssertFalse(sut.isErrorPopupVisible)
    verify(mocks.router).popTo(with: any())
  }

  func testPerformWalletRegistration_WhenRateLimited_ThenGotItStillLeavesTheLoadingScreen() async {
    let (sut, mocks) = makeFailingSUT(
      throwing: NetworkError.httpError(code: 429, data: nil, headers: ["Retry-After": "60"])
    )

    await sut.issueCredentials()

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutTooManyRequestsTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalNoInternetErrorPrimButton.toString
    )
    XCTAssertNil(sut.errorPopupViewModel.secondaryButtontitle)

    sut.errorPopupViewModel.onConfirm()

    // The loading screen has nothing to stay on, so "Got it" keeps leaving the flow.
    XCTAssertFalse(sut.isErrorPopupVisible)
    verify(mocks.router).popTo(with: any())
  }

  func testPerformWalletRegistration_WhenIssuanceCallTimesOut_ThenSlowInternetPopup() async {
    let walletError = WalletError(
      description: "issuance",
      code: .issuanceRequestFailed,
      innerError: URLError(.timedOut)
    )
    let (sut, _) = makeFailingSUT(throwing: walletError)

    await sut.issueCredentials()

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
  }

  func testPerformWalletRegistration_WhenOffline_ThenKeepsPinSessionAndTraceAndShowsNoInternetPopup() async {
    let (sut, mocks) = makeFailingSUT(throwing: NetworkError.internetFailure(URLError(.notConnectedToInternet)))

    await sut.issueCredentials()

    XCTAssertTrue(sut.noInternetDialog.isPresented)
    XCTAssertFalse(sut.isErrorPopupVisible)
    // Offline keeps both alive so retry can reuse them; the transport-failure branch below tears both down.
    verify(mocks.pinSessionInteractor, never()).clear()
    verify(mocks.analyticsController, never()).endTrace(finalAttributes: any(), errorDescription: any())
  }

  func testPerformWalletRegistration_WhenOfflineAndRetryTapped_ThenRequestsCredentialsAgain() async {
    let offline = NetworkError.internetFailure(URLError(.notConnectedToInternet))
    let (sut, mocks) = makeFailingSUT(throwing: offline)
    let requested = expectation(description: "credentials requested twice")
    requested.expectedFulfillmentCount = 2
    stub(mocks.addDocumentInteractor) { mock in
      when(mock.getCredentials(docTypeIdentifier: any(), any(), privateKey: any())).then { _ in
        requested.fulfill()
        throw offline
      }
    }

    await sut.issueCredentials()
    sut.noInternetDialog.retry()
    await fulfillment(of: [requested], timeout: 5)

    verify(mocks.addDocumentInteractor, times(2)).getCredentials(docTypeIdentifier: any(), any(), privateKey: any())
    verify(mocks.pinSessionInteractor, never()).clear()
  }

  func testPerformWalletRegistration_WhenOfflineAndCancelTapped_ThenClearsPinSessionAndGoesBack() async {
    let (sut, mocks) = makeFailingSUT(throwing: NetworkError.internetFailure(URLError(.notConnectedToInternet)))

    await sut.issueCredentials()
    sut.noInternetDialog.cancel()

    verify(mocks.pinSessionInteractor).clear()
    verify(mocks.router).pop()
  }

  func testConfigureIssuanceRestartPopupViewModel_ThenStartAgainLeadsBackToTheOnboardingCard() {
    let router = MockRouterHost()
    let sut = makeSUT(router: router)
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.configureIssuanceRestartPopupViewModel()

    XCTAssertEqual(
      sut.errorPopupViewModel.title,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredTitle.toString
    )
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredPrimButton.toString
    )
    XCTAssertEqual(
      sut.errorPopupViewModel.secondaryButtontitle,
      LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredSecButton.toString
    )

    sut.errorPopupViewModel.onConfirm()

    verify(router).popTo(with: equal(to: .featureIssuanceModule(.issuanceOnboardingCardView)))
  }

  private typealias FailingMocks = (
    router: MockRouterHost,
    addDocumentInteractor: MockAddDocumentInteractor,
    analyticsController: MockAnalyticsController,
    pinSessionInteractor: MockPinSessionInteractor
  )

  private func makeFailingSUT(throwing error: Error) -> (IssuanceLoadingViewModel<MockRouterHost>, FailingMocks) {
    let router = MockRouterHost()
    let secureEnclaveController = MockSecureEnclaveController()
    let addDocumentInteractor = MockAddDocumentInteractor()
    let analyticsController = MockAnalyticsController()
    let pinSessionInteractor = MockPinSessionInteractor()
    let sut = makeSUT(
      router: router,
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor
    )
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
      when(mock.push(with: any())).thenDoNothing()
      when(mock.pop()).thenDoNothing()
    }
    stub(secureEnclaveController) { mock in
      when(mock.createPrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(SecKeyMock.generateFakePrivateKey())
      when(mock.storePrivateKey(any(), with: equal(to: .credentialPrivKey))).thenReturn(true)
    }
    stub(addDocumentInteractor) { mock in
      when(mock.getCredentials(docTypeIdentifier: any(), any(), privateKey: any())).thenThrow(error)
    }
    stub(analyticsController) { mock in
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }
    return (sut, (router, addDocumentInteractor, analyticsController, pinSessionInteractor))
  }

  private func makeSUT(
    router: MockRouterHost = MockRouterHost(),
    secureEnclaveController: MockSecureEnclaveController = MockSecureEnclaveController(),
    addDocumentInteractor: MockAddDocumentInteractor = MockAddDocumentInteractor(),
    analyticsController: MockAnalyticsController = MockAnalyticsController(),
    pinSessionInteractor: MockPinSessionInteractor = MockPinSessionInteractor(),
    connectivityMonitor: MockNetworkConnectivityMonitor = .stubbed()
  ) -> IssuanceLoadingViewModel<MockRouterHost> {
    IssuanceLoadingViewModel(
      router: router,
      config: UIConfig.IssuanceLoadingUiConfig(
        finishAuthorizationResponse: .init(
          nonce: "nonce",
          code: "code",
          state: nil,
          location: "https://issuer.example/callback"
        )
      ),
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      mdvmInteractor: MockMDVMInteractor(),
      rwscaInteractor: MockRWSCAInteractor(),
      pinSessionInteractor: pinSessionInteractor,
      connectivityMonitor: connectivityMonitor,
      logger: nil
    )
  }
}
