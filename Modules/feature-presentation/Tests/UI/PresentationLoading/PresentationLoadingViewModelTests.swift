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
  private var prefsController: MockPrefsController!
  private var analyticsController: MockAnalyticsController!
  private var pinSessionInteractor: MockPinSessionInteractor!
  private var sut: PresentationLoadingViewModel<MockRouterHost, DocumentElementClaim>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockPresentationInteractor()
    prefsController = MockPrefsController()
    analyticsController = MockAnalyticsController()
    pinSessionInteractor = MockPinSessionInteractor()
    sut = PresentationLoadingViewModel(
      router: router,
      interactor: interactor,
      relyingParty: "Verifier",
      relyingPartyIsTrusted: true,
      originator: .featureDashboardModule(.dashboard),
      requestItems: [],
      prefsController: prefsController,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor,
      items: nil,
      logger: nil
    )
  }

  override func tearDown() {
    sut = nil
    analyticsController = nil
    prefsController = nil
    pinSessionInteractor = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testDoWork_WhenResponseSent_ThenClearsPinSession() async {
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.sent)
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(true)
      when(mock.getSessionStatePublisher()).thenReturn(.failure(PresentationSessionError.invalidState))
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
  }

  func testDoWork_WhenNonPIDResponseSent_ThenDoesNotClearPinSession() async {
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.sent)
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(false)
      when(mock.getSessionStatePublisher()).thenReturn(.failure(PresentationSessionError.invalidState))
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

  func testDoWork_WhenGenericErrorOccurs_ThenDefaultErrorPopupCarriesTraceId() async {
    stub(interactor) { mock in
      when(mock.onSendResponse()).thenReturn(.failure(TestNSError.generic))
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(true)
      when(mock.getSessionStatePublisher()).thenReturn(.failure(PresentationSessionError.invalidState))
    }
    stub(analyticsController) { mock in
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }

    await sut.doWork()

    verify(analyticsController).endTrace(finalAttributes: equal(to: ["status": "fails"]), errorDescription: notNil())
    XCTAssertEqual(sut.errorPopupViewModel.traceId, "trace-id")
  }
}

private enum TestNSError {
  static let generic = NSError(domain: "PresentationLoadingViewModelTests", code: 1)
}
