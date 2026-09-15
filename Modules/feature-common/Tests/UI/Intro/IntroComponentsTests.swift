//
//  IntroComponentsTests.swift
//  feature-common
//

import XCTest
import SwiftUI
import logic_ui
@testable import feature_common

@MainActor
final class IntroComponentsTests: XCTestCase {

  private let availableWidth: CGFloat = 320

  func testIntroWarningBanner_ThenFillsTheWidthItIsGiven() {
    let size = measure(IntroWarningBanner(text: "Keep your card nearby."))

    XCTAssertEqual(size.width, availableWidth)
  }

  /// The icon is pinned to the first line of the copy, so the banner has to grow with the text
  /// rather than centring the icon against the whole block.
  func testIntroWarningBanner_WhenTheTextWraps_ThenGrowsWithTheText() {
    let single = measure(IntroWarningBanner(text: "Keep your card nearby."))
    let wrapped = measure(
      IntroWarningBanner(text: String(repeating: "Keep your card nearby. ", count: 12))
    )

    XCTAssertGreaterThan(wrapped.height, single.height)
  }

  private func measure(_ view: some View) -> CGSize {
    UIHostingController(rootView: view)
      .sizeThatFits(in: CGSize(width: availableWidth, height: 2000))
  }
}
