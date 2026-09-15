//
//  PageIndicatorTests.swift
//  logic-ui
//

import XCTest
import SwiftUI
@testable import logic_ui

@MainActor
final class PageIndicatorTests: XCTestCase {

  func testPageIndicator_WhenThreePages_ThenLaysOutDotsInARow() {
    let size = measure(DSPageIndicator(current: 1, total: 3))

    XCTAssertEqual(size.width, 40, accuracy: 0.5)
    XCTAssertEqual(size.height, 8, accuracy: 0.5)
  }

  func testPageIndicator_WhenTotalIsZero_ThenStillShowsOneDot() {
    let size = measure(DSPageIndicator(current: 1, total: 0))

    XCTAssertEqual(size.width, 8, accuracy: 0.5)
  }

  private func measure(_ view: some View) -> CGSize {
    UIHostingController(rootView: view)
      .sizeThatFits(in: CGSize(width: 320, height: 200))
  }
}
