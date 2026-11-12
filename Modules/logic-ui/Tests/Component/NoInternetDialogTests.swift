//
//  NoInternetDialogTests.swift
//  logic-ui
//

import XCTest
import SwiftUI
import logic_resources
@testable import logic_ui

@MainActor
final class NoInternetDialogTests: XCTestCase {

  func testNoInternetButtons_AreRetryThenClose() {
    let buttons = CustomAlertDialogConfig.noInternetButtons(onRetry: {}, onCancel: {})

    XCTAssertEqual(buttons.map(\.title), [.globalTryAgainButton, .globalCloseButton])
    XCTAssertEqual(buttons.map(\.role), [.primary, .secondary])
    XCTAssertEqual(buttons.map(\.isCancel), [false, true])
  }

  func testNoInternetButtons_WireRetryAndCancelActions() {
    var retried = false
    var cancelled = false
    let buttons = CustomAlertDialogConfig.noInternetButtons(
      onRetry: { retried = true },
      onCancel: { cancelled = true }
    )

    buttons[0].action()
    XCTAssertTrue(retried)
    XCTAssertFalse(cancelled)

    buttons[1].action()
    XCTAssertTrue(cancelled)
  }

  func testDialog_WhenTextIsLarge_ThenStillFitsTheScreen() {
    let view = ScrollIfNeeded {
      CustomAlertDialog(
        icon: Theme.shared.image.warning,
        iconColor: DSColor.error,
        title: LocalizableStringKey.globalNoInternetErrorTitle.toString,
        subtitle: LocalizableStringKey.globalNoInternetErrorParagraph.toString,
        buttons: CustomAlertDialogConfig.noInternetButtons(onRetry: {}, onCancel: {})
      )
    }
    .environment(\.dynamicTypeSize, .accessibility5)

    let size = UIHostingController(rootView: view)
      .sizeThatFits(in: CGSize(width: 375, height: 667))

    XCTAssertLessThanOrEqual(size.width, 375)
    XCTAssertLessThanOrEqual(size.height, 667)
  }
}

@MainActor
final class NoInternetDialogStateTests: XCTestCase {

  func testPresent_ThenShowsTheDialogAndRunsTheGivenActions() {
    var retried = 0
    var cancelled = 0
    var state = NoInternetDialogState()

    state.present(retry: { retried += 1 }, cancel: { cancelled += 1 })

    XCTAssertTrue(state.isPresented)
    state.cancel()
    XCTAssertEqual(cancelled, 1)
    XCTAssertEqual(retried, 0)
  }

  func testPresent_WhenPresentedAgain_ThenUsesTheLatestActions() {
    var latest = ""
    var state = NoInternetDialogState()

    state.present(retry: { latest = "first" }, cancel: {})
    state.present(retry: { latest = "second" }, cancel: {})
    state.retry()

    XCTAssertEqual(latest, "second")
  }

  func testRetry_WhenRun_ThenDropsBothActions() {
    var retried = 0
    var cancelled = 0
    var state = NoInternetDialogState()
    state.present(retry: { retried += 1 }, cancel: { cancelled += 1 })

    state.retry()
    state.retry()
    state.cancel()

    XCTAssertEqual(retried, 1)
    XCTAssertEqual(cancelled, 0)
  }
}
