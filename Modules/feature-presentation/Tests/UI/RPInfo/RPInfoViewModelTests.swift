//
//  RPInfoViewModelTests.swift
//  RPInfoViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_analytics
@testable import logic_core
@testable import feature_common
@testable import feature_presentation
@testable import feature_test

@MainActor
final class RPInfoViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockPresentationInteractor!
  private var analyticsController: MockAnalyticsController!
  private var errorHandler: MockPresentationErrorHandler!
  private var sut: RPInfoViewModel<MockRouterHost>!
  private var openedURLs: [URL] = []
  private let declinedTrace = [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.declined]
    
  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockPresentationInteractor()
    analyticsController = MockAnalyticsController()
    errorHandler = MockPresentationErrorHandler()
    openedURLs = []
    sut = RPInfoViewModel(
      router: router,
      interactor: interactor,
      originator: .featureDashboardModule(.dashboard),
      analyticsController: analyticsController,
      errorHandler: errorHandler,
      logger: nil,
      openURL: { [weak self] url in self?.openedURLs.append(url) }
    )
    stub(analyticsController) { mock in
      when(mock.startTrace(name: any(), initialAttributes: any())).thenDoNothing()
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(errorHandler) { mock in
      when(mock.handle(any(), originator: any(), retryAction: any())).thenReturn(.dialog(.fixture()))
    }
  }

  override func tearDown() {
    sut = nil
    analyticsController = nil
    interactor = nil
    router = nil
    errorHandler = nil

    super.tearDown()
  }

  func testOnContinue_WhenCoordinatorExists_ThenPushesConsentRoute() {
    let coordinator = MockRemoteSessionCoordinator(session: Constants.mockPresentationSession)
    stub(interactor) { mock in
      when(mock.getCoordinator()).thenReturn(.success(coordinator))
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.onContinue()

    verify(interactor).getCoordinator()
    verify(router).push(with: any())
  }

  func testOnContinue_WhenCoordinatorFails_ThenDoesNotPush() {
    stub(interactor) { mock in
      when(mock.getCoordinator()).thenReturn(.failure(TestNSError.generic))
    }

    sut.onContinue()

    verify(interactor).getCoordinator()
    verify(router, never()).push(with: any())
  }

  func testDoWork_WhenHandlerReturnsNotice_ThenPushesNoticeRouteAndKeepsDialogHidden() async {
    var didPushNoticeRoute = false
    let credentialNotFound = WalletError(description: "no document", code: .credentialNotFound)
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.failure(credentialNotFound))
    }
    stub(errorHandler) { mock in
      when(mock.handle(any(), originator: any(), retryAction: any())).thenReturn(.notice(.fixture()))
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        if case .featurePresentationModule(.presentationErrorNotice) = route {
          didPushNoticeRoute = true
        }
      }
    }

    await sut.doWork()

    XCTAssertTrue(didPushNoticeRoute)
    XCTAssertNil(sut.errorDialog)
    XCTAssertTrue(sut.viewState.initialized, "Must be initialized before presenting the error")
    verify(errorHandler).handle(
      any(),
      originator: equal(to: AppRoute.featureDashboardModule(.dashboard)),
      retryAction: any()
    )
    verify(interactor).onDeviceEngagement()
    verify(analyticsController).startTrace(name: any(), initialAttributes: any())
  }

  func testDoWork_WhenHandlerReturnsDialog_ThenShowsDialogAndDoesNotPush() async {
    let otherError = WalletError(description: "malformed", code: .notSecuredRequest)
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.failure(otherError))
    }
    stub(errorHandler) { mock in
      when(mock.handle(any(), originator: any())).thenReturn(.dialog(.fixture(traceId: "trace-id")))
    }

    await sut.doWork()

    XCTAssertEqual(sut.errorDialog?.traceId, "trace-id")
    XCTAssertTrue(sut.viewState.initialized, "Must be initialized before presenting the error")
    verify(errorHandler).handle(any(), originator: any(), retryAction: any())
    verify(router, never()).push(with: any())
    verify(interactor).onDeviceEngagement()
  }

  func testOnErrorDialogAction_WhenPopTo_ThenClearsDialogAndPopsToRoute() {
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.onErrorDialogAction(.popTo(.featureDashboardModule(.dashboard)))

    XCTAssertNil(sut.errorDialog)
    verify(router).popTo(with: equal(to: AppRoute.featureDashboardModule(.dashboard)))
  }

  func testOnErrorDialogAction_WhenAddDigitalIDAgain_ThenPopsToOriginator() {
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.onErrorDialogAction(.addDigitalIDAgain)

    XCTAssertNil(sut.errorDialog)
    verify(router).popTo(with: equal(to: AppRoute.featureDashboardModule(.dashboard)))
  }

  // MARK: - Refusals by registration certificate

  func testDoWork_WhenOverAsking_ThenRefusesWithReportURIAndDeclinesWithoutShowingItems() async {
    let reportURI = URL(string: "https://www.bfdi.bund.de/EN/Home/home_node.html")
    let request = makeRequest(isOverAsking: true, supervisoryAuthorityURI: reportURI)
    stubPresentation(returning: .success(request))
    var pushedConfig: PresentationRejectedUiConfig?
    stubRejectedRoute { pushedConfig = $0 }

    await sut.doWork()

    XCTAssertEqual(pushedConfig?.reason, .overAsking)
    XCTAssertEqual(pushedConfig?.reportURI, reportURI)
    XCTAssertFalse(sut.viewState.initialized, "Requested items must never be received")
    XCTAssertFalse(sut.viewState.allowShare)
    verify(interactor).declinePresentation()
    verify(interactor).stopPresentation()
  }

  func testDoWork_WhenRegistrationCertificateIsUnreadable_ThenRefusesAsUnregisteredAndDeclines() async {
    let request = makeRequest(hasUnreadableRegistration: true)
    stubPresentation(returning: .success(request))
    var pushedConfig: PresentationRejectedUiConfig?
    stubRejectedRoute { pushedConfig = $0 }

    await sut.doWork()

    XCTAssertEqual(pushedConfig?.reason, .unregisteredRelyingParty)
    XCTAssertNil(pushedConfig?.reportURI)
    XCTAssertFalse(sut.viewState.initialized, "Requested items must never be received")
    verify(interactor).declinePresentation()
    verify(interactor).stopPresentation()
  }

  func testDoWork_WhenUnreadableAndOverAsking_ThenRefusesAsUnregistered() async {
    let request = makeRequest(isOverAsking: true, hasUnreadableRegistration: true)
    stubPresentation(returning: .success(request))
    var pushedConfig: PresentationRejectedUiConfig?
    stubRejectedRoute { pushedConfig = $0 }

    await sut.doWork()

    XCTAssertEqual(pushedConfig?.reason, .unregisteredRelyingParty)
  }

  func testDoWork_WhenAccessCertificateIsNotTrusted_ThenShowsNoticeWithoutDecliningOrStopping() async {
    let notTrusted = WalletError(description: "Trust evaluation failed", code: .trustError)
    stubPresentation(returning: .failure(notTrusted))
    stub(errorHandler) { mock in
      when(mock.handle(any(), originator: any(), retryAction: any())).thenReturn(.notice(.fixture()))
    }
    var pushedNotice = false
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        if case .featurePresentationModule(.presentationErrorNotice) = route { pushedNotice = true }
      }
    }

    await sut.doWork()

    XCTAssertTrue(pushedNotice)
    XCTAssertNil(sut.errorDialog)
    verify(interactor, never()).declinePresentation()
  }

  func testDoWork_WhenRequestIsCoveredByRegistration_ThenDoesNotRefuse() async {
    stubPresentation(returning: .success(makeRequest()))
    var pushedConfig: PresentationRejectedUiConfig?
    stubRejectedRoute { pushedConfig = $0 }

    await sut.doWork()

    XCTAssertNil(pushedConfig)
    verify(interactor, never()).declinePresentation()
    verify(interactor, never()).stopPresentation()
  }

  // MARK: - Decline

  func testOnDecline_ThenShowsPopupAndSendsNothing() async {
    sut.onDecline()
    await Task.yield()

    XCTAssertTrue(sut.isConfirmationPopupVisible)
    verify(interactor, never()).onRejectRequest()
    verify(router, never()).pop()
  }

  func testConfirmDecline_ThenSendsAccessDeniedEndsTraceAsDeclinedAndPops() async {
    let rejectionSent = expectation(description: "access_denied sent")
    stub(interactor) { mock in
      when(mock.onRejectRequest()).then {
        rejectionSent.fulfill()
        return nil
      }
    }
    stub(router) { mock in
      when(mock.pop()).thenDoNothing()
    }

    sut.onDecline()
    sut.confirmDecline()
    await fulfillment(of: [rejectionSent], timeout: 1)

    verify(interactor).onRejectRequest()
    verify(router).pop()
    verify(analyticsController).endTrace(finalAttributes: equal(to: declinedTrace), errorDescription: isNil())
  }

  func testConfirmDecline_WhenVerifierReturnsRedirectURI_ThenOpensIt() async throws {
    let redirectURL = try XCTUnwrap(URL(string: "https://verifier.example/cancelled"))
    stub(interactor) { mock in
      when(mock.onRejectRequest()).thenReturn(redirectURL)
    }
    stub(router) { mock in
      when(mock.pop()).thenDoNothing()
    }

    sut.confirmDecline()
    try await waitUntil { !self.openedURLs.isEmpty }

    XCTAssertEqual(openedURLs, [redirectURL])
    verify(router).pop()
  }

  func testConfirmDecline_WhenVerifierReturnsNoRedirectURI_ThenOpensNothing() async throws {
    let rejectionSent = expectation(description: "access_denied sent")
    stub(interactor) { mock in
      when(mock.onRejectRequest()).then {
        rejectionSent.fulfill()
        return nil
      }
    }
    stub(router) { mock in
      when(mock.pop()).thenDoNothing()
    }

    sut.confirmDecline()
    await fulfillment(of: [rejectionSent], timeout: 1)
    await Task.yield()

    XCTAssertTrue(openedURLs.isEmpty)
    verify(router).pop()
  }

  func testOnErrorDialogAction_WhenDismiss_ThenClearsDialogAndHidesConfirmationPopup() {
    sut.onDecline()

    sut.onErrorDialogAction(.dismiss)

    XCTAssertNil(sut.errorDialog)
    XCTAssertFalse(sut.isConfirmationPopupVisible)
    verify(router, never()).popTo(with: any())
  }

  // MARK: - Helpers

  private func waitUntil(timeout: TimeInterval = 1, _ condition: @escaping () -> Bool) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
      guard Date() < deadline else {
        XCTFail("Condition not met within \(timeout)s")
        return
      }
      try await Task.sleep(nanoseconds: 10_000_000)
    }
  }

  private func makeRequest(
    isOverAsking: Bool = false,
    supervisoryAuthorityURI: URL? = nil,
    hasUnreadableRegistration: Bool = false
  ) -> OnlineAuthenticationRequestSuccessModel {
    OnlineAuthenticationRequestSuccessModel(
      requestDataCells: [],
      relyingParty: "EUDI Wallet Playground",
      dataRequestInfo: "Data Request Info",
      isTrusted: true,
      isOverAsking: isOverAsking,
      supervisoryAuthorityURI: supervisoryAuthorityURI,
      hasUnreadableRegistration: hasUnreadableRegistration
    )
  }

  private func stubPresentation(returning result: Result<OnlineAuthenticationRequestSuccessModel, Error>) {
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(result)
      when(mock.declinePresentation()).thenDoNothing()
      when(mock.stopPresentation()).thenDoNothing()
    }
  }

  private func stubRejectedRoute(_ onRejected: @escaping (PresentationRejectedUiConfig) -> Void) {
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        if case .featurePresentationModule(.presentationRejectedView(let config)) = route,
           let config = config as? PresentationRejectedUiConfig {
          onRejected(config)
        }
      }
    }
  }
}

private enum TestNSError {
  static let generic = NSError(domain: "RPInfoViewModelTests", code: 1)
}
