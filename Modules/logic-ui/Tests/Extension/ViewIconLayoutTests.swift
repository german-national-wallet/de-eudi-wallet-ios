//
//  ViewIconLayoutTests.swift
//  logic-ui
//

import XCTest
import SwiftUI
@testable import logic_ui

@MainActor
final class ViewIconLayoutTests: XCTestCase {

  func testIconButtonSlot_ThenSizesTheIconToTheDesignSystemSquare() {
    let size = measure(icon(size: 24).iconButtonSlot())

    XCTAssertEqual(size.width, 48)
    XCTAssertEqual(size.height, 48)
  }

  // The slot is what keeps the control above Apple's 44pt minimum tap target.
  func testIconButtonSlot_ThenStaysAboveTheMinimumTapTarget() {
    let size = measure(icon(size: 12).iconButtonSlot())

    XCTAssertGreaterThanOrEqual(size.width, 44)
    XCTAssertGreaterThanOrEqual(size.height, 44)
  }

  func testIconButtonSlot_WhenGivenASize_ThenUsesThatSizeInstead() {
    let size = measure(icon(size: 12).iconButtonSlot(size: 32))

    XCTAssertEqual(size.width, 32)
    XCTAssertEqual(size.height, 32)
  }

  /// The hidden space is the whole point of the helper: it gives the container the text font's own
  /// line height, so an icon shorter than that line still lands on the middle of it.
  func testCenteredOnFirstLine_ThenAdoptsTheFontsLineHeightRatherThanTheIconsHeight() {
    let bare = measure(icon(size: 12))
    let centered = measure(icon(size: 12).centeredOnFirstLine(of: DSTypography.Body.large))

    XCTAssertEqual(centered.width, bare.width)
    XCTAssertGreaterThan(centered.height, bare.height)
  }

  func testCenteredOnFirstLine_WhenTheIconIsTallerThanTheLine_ThenKeepsTheIconsHeight() {
    let iconHeight: CGFloat = 80
    let centered = measure(icon(size: iconHeight).centeredOnFirstLine(of: DSTypography.Body.large))

    XCTAssertEqual(centered.height, iconHeight)
  }

  private func icon(size: CGFloat) -> some View {
    Image(systemName: "exclamationmark.circle")
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
  }

  /// Hosting the view is what makes SwiftUI resolve the layout the extensions describe.
  private func measure(_ view: some View) -> CGSize {
    UIHostingController(rootView: view)
      .sizeThatFits(in: CGSize(width: 1000, height: 1000))
  }
}
