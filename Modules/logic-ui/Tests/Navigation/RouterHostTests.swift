//
//  RouterHostTests.swift
//  logic-ui
//

import XCTest
import Cuckoo
@testable import logic_ui

@MainActor
final class RouterHostTests: XCTestCase {

  private var sut: MockRouterHost!

  override func setUp() {
    super.setUp()

    sut = MockRouterHost()
  }

  override func tearDown() {
    sut = nil

    super.tearDown()
  }

  func testCancelToStart_WhenTheOverviewIsOnTheBackStack_ThenPopsToTheOverview() {
    stub(sut) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(true)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.cancelToStart()

    let captor = ArgumentCaptor<AppRoute>()
    verify(sut).popTo(with: captor.capture())
    guard case .featureDashboardModule(.dashboard) = captor.value else {
      return XCTFail("Expected the overview to be popped to")
    }
  }

  // A wallet holding no documents starts on the add-document screen, so the overview is not on the
  // back stack and popping to it would do nothing.
  func testCancelToStart_WhenTheOverviewIsNotOnTheBackStack_ThenPopsToAddDocument() {
    stub(sut) { mock in
      when(mock.isScreenOnBackStack(with: any())).thenReturn(false)
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.cancelToStart()

    let captor = ArgumentCaptor<AppRoute>()
    verify(sut).popTo(with: captor.capture())
    guard case .featureIssuanceModule(.issuanceAddDocument) = captor.value else {
      return XCTFail("Expected the add-document screen to be popped to")
    }
  }
}
