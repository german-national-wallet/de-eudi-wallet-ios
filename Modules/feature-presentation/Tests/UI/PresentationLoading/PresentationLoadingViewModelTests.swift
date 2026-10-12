//
//  PresentationLoadingViewModelTests.swift
//  PresentationLoadingViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_core
import logic_api
import logic_ui
@testable import feature_presentation

@MainActor
final class PresentationLoadingViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockPresentationInteractor!
  private var pidRevokeInteractor: MockPIDRevokeInteractor!
  private var deeplinkController: MockDeepLinkController!
  private var prefsController: MockPrefsController!
  private var analyticsController: MockAnalyticsController!
  private var pinSessionInteractor: MockPinSessionInteractor!
  private var errorHandler: MockPresentationErrorHandler!
  private var sut: PresentationLoadingViewModel<MockRouterHost, DocumentElementClaim>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockPresentationInteractor()
    pidRevokeInteractor = MockPIDRevokeInteractor()
    deeplinkController = MockDeepLinkController()
    prefsController = MockPrefsController()
    analyticsController = MockAnalyticsController()
    pinSessionInteractor = MockPinSessionInteractor()
    errorHandler = MockPresentationErrorHandler()
    sut = PresentationLoadingViewModel(
      router: router,
      interactor: interactor,
      pidRevokeInteractor: pidRevokeInteractor,
      deepLinkController: deeplinkController,
      relyingParty: "Verifier",
      relyingPartyIsTrusted: true,
      originator: .featureDashboardModule(.dashboard),
      requestItems: [],
      prefsController: prefsController,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor,
      errorHandler: errorHandler,
      items: nil,
      logger: nil
    )
    stub(errorHandler) { mock in
      when(mock.handle(any(), originator: any())).thenReturn(.dialog(.fixture()))
    }
  }

  override func tearDown() {
    sut = nil
    errorHandler = nil
    analyticsController = nil
    pinSessionInteractor = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testDoWork_WhenResponseSent_ThenClearsPinSession() async {
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.sent)
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(true)
      when(mock.getSessionStatePublisher()).thenReturn(.success(Self.finishedStream()))
    }
    stub(analyticsController) { mock in
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.doWork()

    verify(pinSessionInteractor).clear()
    verify(analyticsController).endTrace(finalAttributes: equal(to: ["status": "success"]), errorDescription: isNil())
    XCTAssertNil(sut.errorDialog)
  }

  func testDoWork_WhenNonPIDResponseSent_ThenDoesNotClearPinSession() async {
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.sent)
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(false)
      when(mock.getSessionStatePublisher()).thenReturn(.success(Self.finishedStream()))
    }
    stub(analyticsController) { mock in
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.doWork()

    verify(pinSessionInteractor, never()).clear()
    verify(analyticsController).endTrace(finalAttributes: equal(to: ["status": "success"]), errorDescription: isNil())
  }

  func testDoWork_WhenSendFails_ThenClearsPinSessionAndShowsDialogFromHandler() async {
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.failure(TestNSError.generic))
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(true)
      when(mock.getSessionStatePublisher()).thenReturn(.success(Self.finishedStream()))
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }

    await sut.doWork()

    verify(pinSessionInteractor).clear()
    XCTAssertEqual(sut.errorDialog?.traceId, "trace-id")
    verify(errorHandler).handle(any(), originator: equal(to: AppRoute.featureDashboardModule(.dashboard)))
    // The handler owns the failure trace; the loader must not end it a second time.
    verify(analyticsController, never()).endTrace(finalAttributes: any(), errorDescription: any())
  }

  func testDoWork_WhenSessionPublishesErrorAndSendFails_ThenHandlesTheFailureOnce() async {
    let stream = AsyncStream<PresentationState> { continuation in
      continuation.yield(.error(TestNSError.generic))
      continuation.finish()
    }
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.failure(TestNSError.generic))
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(false)
      when(mock.getSessionStatePublisher()).thenReturn(.success(stream))
    }

    await sut.doWork()
    await Task.yield()

    verify(errorHandler, times(1)).handle(any(), originator: any())
    XCTAssertNotNil(sut.errorDialog)
  }

  func testDoWork_WhenHandlerReturnsNotice_ThenPushesNoticeRoute() async {
    var didPushNoticeRoute = false
    stub(errorHandler) { mock in
      when(mock.handle(any(), originator: any())).thenReturn(.notice(.fixture()))
    }
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.failure(TestNSError.generic))
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(false)
      when(mock.getSessionStatePublisher()).thenReturn(.success(Self.finishedStream()))
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
  }

  func testOnErrorDialogAction_WhenPopTo_ThenHidesDialogAndPopsToRoute() {
    sut.errorDialog = .fixture()
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.onErrorDialogAction(.popTo(.featureDashboardModule(.dashboard)))

    XCTAssertNil(sut.errorDialog)
    verify(router).popTo(with: equal(to: AppRoute.featureDashboardModule(.dashboard)))
  }

  func testOnErrorDialogAction_WhenAddDigitalIDAgain_ThenOnlyHidesDialog() {
    sut.errorDialog = .fixture(primaryAction: .addDigitalIDAgain)
    sut.onErrorDialogAction(.addDigitalIDAgain)
    XCTAssertNil(sut.errorDialog)
    verify(router, never()).popTo(with: any())
    verify(router, never()).push(with: any())
  }

  private static func finishedStream() -> AsyncStream<PresentationState> {
    AsyncStream { continuation in
      continuation.finish()
    }
  }
}

private enum TestNSError {
  static let generic = NSError(domain: "PresentationLoadingViewModelTests", code: 1)
}
