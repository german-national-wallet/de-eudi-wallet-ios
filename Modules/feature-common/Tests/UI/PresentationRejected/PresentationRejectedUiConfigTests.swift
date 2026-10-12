//
//  PresentationRejectedUiConfigTests.swift
//  feature-common
//
//  Created by Pankaj Sachdeva on 30.09.26.
//

import XCTest
import logic_resources
@testable import feature_common

final class PresentationRejectedUiConfigTests: XCTestCase {

  func testCanReport_WhenReportURIIsSet_ThenReturnsTrue() {
    let sut = PresentationRejectedUiConfig(
      reason: .overAsking,
      reportURI: URL(string: "https://www.bfdi.bund.de/EN/Home/home_node.html")
    )

    XCTAssertTrue(sut.canReport)
  }

  func testCanReport_WhenReportURIIsMissing_ThenReturnsFalse() {
    let sut = PresentationRejectedUiConfig(reason: .unregisteredRelyingParty)

    XCTAssertFalse(sut.canReport)
  }

  func testTexts_WhenOverAsking_ThenUsesOverAskingCopy() {
    let sut = PresentationRejectedUiConfig(reason: .overAsking)

    XCTAssertEqual(sut.title, .pidPresentationOverAskingTitle)
    XCTAssertEqual(sut.message, .pidPresentationOverAskingParagraph)
    XCTAssertEqual(sut.secondaryButtonTitle, .pidPresentationOverAskingSecButton)
  }

  func testTexts_WhenUnregisteredRelyingParty_ThenUsesUnregisteredCopy() {
    let sut = PresentationRejectedUiConfig(reason: .unregisteredRelyingParty)

    XCTAssertEqual(sut.title, .pidPresentationRpUnregisteredTitle)
    XCTAssertEqual(sut.message, .pidPresentationRpUnregisteredParagraph)
    XCTAssertEqual(sut.secondaryButtonTitle, .pidPresentationRpUnregisteredSecButton)
  }
}
