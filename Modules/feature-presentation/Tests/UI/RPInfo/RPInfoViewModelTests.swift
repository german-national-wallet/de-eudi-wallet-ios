//
//  RPInfoViewModelTests.swift
//  RPInfoViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_core
@testable import feature_presentation
@testable import feature_test

@MainActor
final class RPInfoViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockPresentationInteractor!
  private var analyticsController: MockAnalyticsController!
  private var sut: RPInfoViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockPresentationInteractor()
    analyticsController = MockAnalyticsController()
    sut = RPInfoViewModel(
      router: router,
      interactor: interactor,
      originator: .featureDashboardModule(.dashboard),
      analyticsController: analyticsController,
      logger: nil
    )
  }

  override func tearDown() {
    sut = nil
    analyticsController = nil
    interactor = nil
    router = nil

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

  func testDoWork_WhenCredentialNotFound_ThenPushesInstructionsRouteAndKeepsPopupHidden() async {
    var didPushInstructionsRoute = false
    let credentialNotFound = WalletError(description: "no document", code: .credentialNotFound)
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.failure(credentialNotFound))
    }
    stub(analyticsController) { mock in
      when(mock.startTrace(name: any(), initialAttributes: any())).thenDoNothing()
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        if case .featurePresentationModule(.credentialNotFoundInstructionsView) = route {
          didPushInstructionsRoute = true
        }
      }
    }

    await sut.doWork()

    XCTAssertTrue(didPushInstructionsRoute)
    XCTAssertFalse(sut.isConfirmationPopupVisible)
    verify(interactor).onDeviceEngagement()
    verify(router).push(with: any())
    verify(analyticsController).endTrace(finalAttributes: any(), errorDescription: notNil())
  }

  func testDoWork_WhenNoDocumentsAvailable_ThenPushesInstructionsRouteAndKeepsPopupHidden() async {
    var didPushInstructionsRoute = false
    let noDocumentsAvailable = WalletError(description: "no documents", code: .noDocumentsAvailable)
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.failure(noDocumentsAvailable))
    }
    stub(analyticsController) { mock in
      when(mock.startTrace(name: any(), initialAttributes: any())).thenDoNothing()
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        if case .featurePresentationModule(.credentialNotFoundInstructionsView) = route {
          didPushInstructionsRoute = true
        }
      }
    }

    await sut.doWork()

    XCTAssertTrue(didPushInstructionsRoute)
    XCTAssertFalse(sut.isConfirmationPopupVisible)
    verify(interactor).onDeviceEngagement()
    verify(router).push(with: any())
  }

  func testDoWork_WhenOtherWalletError_ThenShowsConfirmationPopupAndDoesNotPush() async {
    let otherError = WalletError(description: "malformed", code: .dcqlQueryNotSatisfied)
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.failure(otherError))
    }
    stub(analyticsController) { mock in
      when(mock.startTrace(name: any(), initialAttributes: any())).thenDoNothing()
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.doWork()

    XCTAssertTrue(sut.isConfirmationPopupVisible)
    verify(router, never()).push(with: any())
    verify(interactor).onDeviceEngagement()
    verify(analyticsController).endTrace(finalAttributes: any(), errorDescription: notNil())
    XCTAssertEqual(sut.confirmationPopupViewModel.traceId, "trace-id")
  }

  func testDoWork_WhenNonWalletError_ThenShowsConfirmationPopupAndDoesNotPush() async {
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.failure(TestNSError.generic))
    }
    stub(analyticsController) { mock in
      when(mock.startTrace(name: any(), initialAttributes: any())).thenDoNothing()
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.doWork()

    XCTAssertTrue(sut.isConfirmationPopupVisible)
    verify(router, never()).push(with: any())
    verify(interactor).onDeviceEngagement()
  }
}

private enum TestNSError {
  static let generic = NSError(domain: "RPInfoViewModelTests", code: 1)
}
