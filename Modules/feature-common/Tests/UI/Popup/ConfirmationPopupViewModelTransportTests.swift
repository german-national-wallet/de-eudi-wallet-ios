//
//  ConfirmationPopupViewModelTransportTests.swift
//  feature-common
//

import XCTest
import logic_api
import logic_core
import logic_resources
@testable import feature_common

@MainActor
final class ConfirmationPopupViewModelTransportTests: XCTestCase {

  private var sut: ConfirmationPopupViewModel!
  private var retries = 0
  private var dismissals = 0

  override func setUp() {
    super.setUp()
    sut = ConfirmationPopupViewModel()
    retries = 0
    dismissals = 0
  }

  override func tearDown() {
    sut = nil
    super.tearDown()
  }

  func testConfigure_WhenTimedOut_ThenSlowInternetCopyWithRetry() {
    configure(.init(kind: .timeout, source: .walletBackend))

    XCTAssertTrue(sut.isVisible)
    XCTAssertEqual(sut.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
    XCTAssertEqual(sut.detail, LocalizableStringKey.globalTimeoutSlowInternetErrorParagraph.toString)
    XCTAssertEqual(sut.primaryButtontitle, LocalizableStringKey.globalTimeoutSlowInternetErrorPrimButton.toString)
    XCTAssertNil(sut.secondaryButtontitle)
    XCTAssertNotNil(sut.titleIcon)

    sut.onConfirm()

    XCTAssertEqual(retries, 1)
    XCTAssertEqual(dismissals, 0)
    XCTAssertFalse(sut.isVisible)
  }

  func testConfigure_WhenUnreachable_ThenSameCopyAsTimeout() {
    configure(.init(kind: .unreachable, source: .walletBackend, statusCode: 504))

    XCTAssertEqual(sut.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
    XCTAssertEqual(sut.primaryButtontitle, LocalizableStringKey.globalTimeoutSlowInternetErrorPrimButton.toString)
  }

  func testConfigure_WhenRateLimited_ThenGotItOnlyDismisses() {
    configure(.init(kind: .rateLimited, source: .walletBackend, statusCode: 429, retryAfter: 600))

    XCTAssertEqual(sut.title, LocalizableStringKey.globalTimeoutTooManyRequestsTitle.toString)
    XCTAssertEqual(sut.primaryButtontitle, LocalizableStringKey.globalNoInternetErrorPrimButton.toString)
    XCTAssertNil(sut.secondaryButtontitle)

    sut.onConfirm()

    XCTAssertEqual(dismissals, 1)
    XCTAssertEqual(retries, 0)
  }

  func testRateLimitParagraph_WhenRetryAfterKnown_ThenFillsInTheDuration() {
    let duration = ConfirmationPopupViewModel.retryDuration(600)

    XCTAssertNotNil(duration)
    XCTAssertEqual(sut.rateLimitParagraph(retryAfter: 600), .globalTimeoutTooManyRequestsParagraph([duration ?? ""]))
  }

  func testRetryDuration_ThenFormatsWholeMinutesInTheGivenLanguage() {
    let english = Locale(identifier: "en")
    let german = Locale(identifier: "de")

    XCTAssertEqual(ConfirmationPopupViewModel.retryDuration(600, locale: english), "10 minutes")
    XCTAssertEqual(ConfirmationPopupViewModel.retryDuration(600, locale: german), "10 Minuten")
    XCTAssertEqual(ConfirmationPopupViewModel.retryDuration(3700, locale: english), "1 hour, 2 minutes")
    XCTAssertEqual(ConfirmationPopupViewModel.retryDuration(3700, locale: german), "1 Stunde und 2 Minuten")
  }

  func testRetryDuration_WhenBelowAMinute_ThenRoundsUpToOneMinute() {
    XCTAssertEqual(ConfirmationPopupViewModel.retryDuration(30, locale: Locale(identifier: "en")), "1 minute")
  }

  func testRateLimitParagraph_WhenRetryAfterUnknown_ThenGenericText() {
    XCTAssertEqual(sut.rateLimitParagraph(retryAfter: nil), .globalErrorParagraph)
  }

  func testConfigureBackendError_ThenTitleIconComesFromTheContentModel() {
    sut.configure(backendError: .unknown) {}

    XCTAssertEqual(BackendError.unknown.errorContent.icon, .error)
    XCTAssertNotNil(sut.titleIcon)
    XCTAssertEqual(sut.title, LocalizableStringKey.globalErrorTitle.toString)
  }

  func testConfigure_WhenTimedOutWithoutRetry_ThenGotItOnlyDismisses() {
    sut.configure(transportFailure: .init(kind: .timeout, source: .openID4VCI)) { [weak self] in self?.dismissals += 1 }

    XCTAssertEqual(sut.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
    XCTAssertEqual(sut.primaryButtontitle, LocalizableStringKey.globalNoInternetErrorPrimButton.toString)
    XCTAssertNil(sut.secondaryButtontitle)

    sut.onConfirm()

    XCTAssertEqual(dismissals, 1)
    XCTAssertEqual(retries, 0)
  }

  func testConfigure_WhenRateLimitedWithoutRetry_ThenGotItStillDismisses() {
    let failure = TransportFailure(kind: .rateLimited, source: .openID4VCI, statusCode: 429)
    sut.configure(transportFailure: failure) { [weak self] in self?.dismissals += 1 }

    XCTAssertEqual(sut.primaryButtontitle, LocalizableStringKey.globalNoInternetErrorPrimButton.toString)

    sut.onConfirm()

    XCTAssertEqual(dismissals, 1)
  }

  func testConfigure_WhenRateLimitedWithClose_ThenGotItOnlyCloses() {
    var closes = 0
    sut.configure(
      transportFailure: .init(kind: .rateLimited, source: .openID4VCI, statusCode: 429),
      retry: { [weak self] in self?.retries += 1 },
      dismiss: { [weak self] in self?.dismissals += 1 },
      close: { closes += 1 }
    )

    sut.onConfirm()

    XCTAssertEqual(closes, 1)
    XCTAssertEqual(dismissals, 0)
    XCTAssertEqual(retries, 0)
  }

  func testConfigure_WhenTimedOutWithClose_ThenGotItStillDismisses() {
    var closes = 0
    sut.configure(
      transportFailure: .init(kind: .timeout, source: .openID4VCI),
      dismiss: { [weak self] in self?.dismissals += 1 },
      close: { closes += 1 }
    )

    sut.onConfirm()

    XCTAssertEqual(dismissals, 1)
    XCTAssertEqual(closes, 0)
  }

  private func configure(_ failure: TransportFailure) {
    sut.configure(
      transportFailure: failure,
      retry: { [weak self] in self?.retries += 1 },
      dismiss: { [weak self] in self?.dismissals += 1 }
    )
  }
}
