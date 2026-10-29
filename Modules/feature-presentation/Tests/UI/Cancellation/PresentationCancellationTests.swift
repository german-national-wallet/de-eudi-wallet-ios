//
//  PresentationCancellationTests.swift
//  feature-presentation
//
//  Created by Ameen Qadri on 12.10.26.
//

import XCTest
import Cuckoo
import logic_analytics
@testable import logic_core
@testable import feature_common
@testable import feature_presentation
@testable import feature_test

@MainActor
final class PresentationCancellationTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockPresentationInteractor!
  private var analyticsController: MockAnalyticsController!
  private var openedURLs: [URL] = []
  private let declinedTrace = [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.declined]

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockPresentationInteractor()
    analyticsController = MockAnalyticsController()
    openedURLs = []
    stub(analyticsController) { mock in
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
      when(mock.push(with: any())).thenDoNothing()
    }
  }

  override func tearDown() {
    analyticsController = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testCancel_ThenSendsAccessDeniedAndEndsTraceAsDeclined() async {
    let rejectionSent = expectation(description: "access_denied sent")
    stub(interactor) { mock in
      when(mock.onRejectRequest()).then {
        rejectionSent.fulfill()
        return nil
      }
    }

    makeSUT().cancel()
    await fulfillment(of: [rejectionSent], timeout: 1)

    verify(interactor).onRejectRequest()
    verify(analyticsController).endTrace(finalAttributes: equal(to: declinedTrace), errorDescription: isNil())
  }

  func testCancel_WhenVerifierReturnsRedirectURI_ThenOpensIt() async throws {
    let redirectURL = try XCTUnwrap(URL(string: "https://verifier.example/cancelled"))
    stub(interactor) { mock in
      when(mock.onRejectRequest()).thenReturn(redirectURL)
    }

    makeSUT().cancel()
    try await waitUntil { !self.openedURLs.isEmpty }

    XCTAssertEqual(openedURLs, [redirectURL])
  }

  func testCancel_WhenVerifierReturnsNoRedirectURI_ThenOpensNothing() async {
    let rejectionSent = expectation(description: "access_denied sent")
    stub(interactor) { mock in
      when(mock.onRejectRequest()).then {
        rejectionSent.fulfill()
        return nil
      }
    }

    makeSUT().cancel()
    await fulfillment(of: [rejectionSent], timeout: 1)
    await Task.yield()

    XCTAssertTrue(openedURLs.isEmpty)
  }

  func testCancel_WhenOverviewIsOnBackStack_ThenPopsToIt() {
    stub(interactor) { mock in
      when(mock.onRejectRequest()).thenReturn(nil)
    }

    makeSUT().cancel()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).popTo(with: captor.capture())
    verify(router, never()).push(with: any())
    guard case .featureDashboardModule(.dashboard) = captor.value else {
      return XCTFail("Expected the overview to be popped to")
    }
  }

  func testCancel_WhenOverviewIsNotOnBackStack_ThenPushesIt() {
    stub(interactor) { mock in
      when(mock.onRejectRequest()).thenReturn(nil)
    }
    stub(router) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(false)
    }

    makeSUT().cancel()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    verify(router, never()).popTo(with: any())
    guard case .featureDashboardModule(.dashboard) = captor.value else {
      return XCTFail("Expected the overview to be pushed")
    }
  }

  private func makeSUT() -> PresentationCancellation<MockRouterHost> {
    PresentationCancellation(
      router: router,
      interactor: interactor,
      analyticsController: analyticsController,
      openURL: { [weak self] url in self?.openedURLs.append(url) }
    )
  }

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
}
