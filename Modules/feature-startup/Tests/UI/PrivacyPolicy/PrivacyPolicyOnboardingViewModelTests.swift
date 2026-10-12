//
//  PrivacyPolicyOnboardingViewModelTests.swift
//  feature-startup
//

import XCTest
import Cuckoo
import logic_ui
@testable import feature_startup
@testable import feature_test

@MainActor
final class PrivacyPolicyOnboardingViewModelTests: XCTestCase {

  private let continueRoute: AppRoute = .featureDashboardModule(.dashboard)
  private let policyURL = URL(string: "https://example.org/privacy")

  private var router: MockRouterHost!
  private var interactor: MockStartupInteractor!

  override func setUp() {
    super.setUp()
    router = MockRouterHost()
    interactor = MockStartupInteractor()
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
      when(mock.pop()).thenDoNothing()
    }
    stub(interactor) { mock in
      when(mock.markPrivacyPolicyAccepted()).thenDoNothing()
    }
  }

  override func tearDown() {
    interactor = nil
    router = nil
    super.tearDown()
  }

  func testInit_ThenNotAgreedAndPolicyHidden() {
    let sut = makeSut()

    XCTAssertFalse(sut.viewState.hasAgreed)
    XCTAssertFalse(sut.viewState.isPolicyPresented)
  }

  func testToggleAgreement_ThenFlipsAgreement() {
    let sut = makeSut()

    sut.toggleAgreement()
    XCTAssertTrue(sut.viewState.hasAgreed)

    sut.toggleAgreement()
    XCTAssertFalse(sut.viewState.hasAgreed)
  }

  func testOnPrimaryButtonTapped_WhenNotAgreed_ThenDoesNothing() {
    let sut = makeSut()

    sut.onPrimaryButtonTapped()

    verify(router, never()).push(with: any())
    verify(interactor, never()).markPrivacyPolicyAccepted()
  }

  func testOnPrimaryButtonTapped_WhenAgreed_ThenMarksAcceptedAndPushesContinueRoute() {
    let sut = makeSut()
    sut.toggleAgreement()

    sut.onPrimaryButtonTapped()

    verify(interactor).markPrivacyPolicyAccepted()
    XCTAssertEqual(capturePushedRoute()?.info.key, continueRoute.info.key)
  }

  func testOnReadPolicyTapped_WhenURLAvailable_ThenPresentsPolicy() {
    let sut = makeSut()

    sut.onReadPolicyTapped()

    XCTAssertTrue(sut.viewState.isPolicyPresented)
  }

  func testOnReadPolicyTapped_WhenURLMissing_ThenDoesNotPresentPolicy() {
    let sut = makeSut(policyURL: .some(nil))

    sut.onReadPolicyTapped()

    XCTAssertFalse(sut.viewState.isPolicyPresented)
  }

  func testOnLinkTapped_WhenURLHasNoScheme_ThenPresentsHTTPSURL() {
    let sut = makeSut()

    sut.onLinkTapped(URL(string: "www.d-you.de/nutzungsbedingungen")!)

    XCTAssertTrue(sut.viewState.isPolicyPresented)
    XCTAssertEqual(sut.viewState.presentedURL?.absoluteString, "https://www.d-you.de/nutzungsbedingungen")
  }

  func testOnLinkTapped_WhenURLHasScheme_ThenPresentsItUnchanged() {
    let sut = makeSut()

    sut.onLinkTapped(URL(string: "https://example.org/terms")!)

    XCTAssertEqual(sut.viewState.presentedURL?.absoluteString, "https://example.org/terms")
  }

  func testOnReadPolicyTapped_ThenPresentsPrivacyPolicyURL() {
    let sut = makeSut()

    sut.onReadPolicyTapped()

    XCTAssertEqual(sut.viewState.presentedURL, policyURL)
  }

  func testOnBackTapped_ThenPopsRouter() {
    let sut = makeSut()

    sut.onBackTapped()

    verify(router).pop()
    verify(router, never()).push(with: any())
  }

  private func makeSut(policyURL: URL?? = nil) -> PrivacyPolicyOnboardingViewModel<MockRouterHost> {
    PrivacyPolicyOnboardingViewModel(
      router: router,
      config: PrivacyPolicyOnboardingUiConfig(continueRoute: continueRoute),
      interactor: interactor,
      privacyPolicyURL: policyURL ?? self.policyURL
    )
  }

  private func capturePushedRoute() -> AppRoute? {
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    return captor.value
  }
}
