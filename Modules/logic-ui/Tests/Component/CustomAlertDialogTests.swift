//
//  CustomAlertDialogTests.swift
//  logic-ui
//

import XCTest
@testable import logic_ui

final class CustomAlertDialogTests: XCTestCase {

  private let destructive = CustomAlertDialogConfig(title: .cancelButton, role: .destructive, action: {})
  private let link = CustomAlertDialogConfig(title: .cancelButton, role: .secondary, action: {})
  private let dismiss = CustomAlertDialogConfig(title: .cancelButton, role: .secondary, action: {})
  private let primary = CustomAlertDialogConfig(title: .cancelButton, role: .primary, action: {})
  private let cancel = CustomAlertDialogConfig(title: .cancelButton, role: .secondary, isCancel: true, action: {})

  func testEscape_WhenBackgroundTapDismisses_ThenCloses() {
    XCTAssertEqual(CustomAlertDialogEscape.outcome(buttons: [primary, cancel], dismissOnBackgroundTap: true), .close)
  }

  func testEscape_WhenNotDismissable_ThenRunsTheExplicitCancel() {
    XCTAssertEqual(
      CustomAlertDialogEscape.outcome(buttons: [primary, cancel], dismissOnBackgroundTap: false),
      .runCancel(cancel.id)
    )
  }

  func testEscape_WhenNotDismissableAndNoCancel_ThenNeverRunsASecondaryButton() {
    XCTAssertEqual(
      CustomAlertDialogEscape.outcome(buttons: [destructive, link, dismiss], dismissOnBackgroundTap: false),
      .ignore
    )
  }

  func testInitialFocus_PrefersTheExplicitCancel() {
    XCTAssertEqual([primary, cancel].initialFocusButton?.id, cancel.id)
  }

  func testInitialFocus_WithoutCancel_SkipsDestructiveAndExternalLink() {
    XCTAssertEqual([destructive, link, dismiss].initialFocusButton?.id, dismiss.id)
    XCTAssertEqual([destructive, dismiss].initialFocusButton?.id, dismiss.id)
  }

  func testInitialFocus_WhenOnlyDestructive_ThenFallsBackToFirst() {
    XCTAssertEqual([destructive].initialFocusButton?.id, destructive.id)
  }

  func testDeferredAction_RunsOnlyWhenTriggeredAndOnlyOnce() {
    var runs = 0
    let deferred = DeferredDialogAction()

    deferred.store { runs += 1 }
    XCTAssertEqual(runs, 0)

    deferred.runOnce()
    deferred.runOnce()
    XCTAssertEqual(runs, 1)
  }
}
