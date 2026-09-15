//
//  AppIntroViewModelTests.swift
//  feature-startup
//

import XCTest
import Cuckoo
import logic_ui
@testable import feature_startup
@testable import feature_test

@MainActor
final class AppIntroViewModelTests: XCTestCase {

  private let continueRoute: AppRoute = .featureDashboardModule(.dashboard)

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
      when(mock.markAppIntroSeen()).thenDoNothing()
    }
  }

  override func tearDown() {
    interactor = nil
    router = nil
    super.tearDown()
  }

  func testInit_ThenStartsOnConfiguredPageWithAnimationPlayingAndToggleHidden() {
    let sut = makeSut(page: .benefits)

    XCTAssertEqual(sut.viewState.page, .benefits)
    XCTAssertFalse(sut.viewState.isAnimationPaused)
    XCTAssertFalse(sut.viewState.isAnimationToggleVisible)
  }

  func testLoadAnimationDuration_WhenClipIsFiveSecondsOrLonger_ThenShowsToggle() async {
    let sut = makeSut(page: .benefits, animationDuration: 9.5)

    await sut.loadAnimationDuration()

    XCTAssertTrue(sut.viewState.isAnimationToggleVisible)
  }

  func testLoadAnimationDuration_WhenClipIsShorterThanFiveSeconds_ThenHidesToggle() async {
    let sut = makeSut(page: .digitalWallet, animationDuration: 4.0)

    await sut.loadAnimationDuration()

    XCTAssertFalse(sut.viewState.isAnimationToggleVisible)
  }

  func testLoadAnimationDuration_WhenDurationIsUnknown_ThenHidesToggle() async {
    let sut = makeSut(page: .trust, animationDuration: nil)

    await sut.loadAnimationDuration()

    XCTAssertFalse(sut.viewState.isAnimationToggleVisible)
  }

  func testOnPrimaryTapped_WhenNotOnLastPage_ThenPushesNextIntroPage() {
    let sut = makeSut(page: .digitalWallet)

    sut.onPrimaryTapped()

    let pushed = capturePushedRoute()
    guard case .featureStartupModule(.appIntro(let config)) = pushed,
          let introConfig = config as? AppIntroUiConfig else {
      return XCTFail("Expected the next intro page, got \(String(describing: pushed))")
    }
    XCTAssertEqual(introConfig.page, .benefits)
    XCTAssertEqual(introConfig.continueRoute.info.key, continueRoute.info.key)
    verify(interactor, never()).markAppIntroSeen()
  }

  func testOnPrimaryTapped_WhenOnLastPage_ThenMarksIntroSeenAndPushesContinueRoute() {
    let sut = makeSut(page: .trust)

    sut.onPrimaryTapped()

    verify(interactor).markAppIntroSeen()
    XCTAssertEqual(capturePushedRoute()?.info.key, continueRoute.info.key)
  }

  func testOnSkipTapped_ThenMarksIntroSeenAndPushesContinueRoute() {
    let sut = makeSut(page: .digitalWallet)

    sut.onSkipTapped()

    verify(interactor).markAppIntroSeen()
    XCTAssertEqual(capturePushedRoute()?.info.key, continueRoute.info.key)
  }

  func testOnBackTapped_ThenPopsRouter() {
    let sut = makeSut(page: .benefits)

    sut.onBackTapped()

    verify(router).pop()
    verify(router, never()).push(with: any())
  }

  func testToggleAnimation_ThenFlipsPausedState() {
    let sut = makeSut(page: .digitalWallet)

    sut.toggleAnimation()
    XCTAssertTrue(sut.viewState.isAnimationPaused)

    sut.toggleAnimation()
    XCTAssertFalse(sut.viewState.isAnimationPaused)
  }

  func testPauseAnimation_ThenPausesAndStaysPaused() {
    let sut = makeSut(page: .digitalWallet)

    sut.pauseAnimation()
    sut.pauseAnimation()

    XCTAssertTrue(sut.viewState.isAnimationPaused)
  }

  func testAppIntroPage_OrderAndNavigation() {
    XCTAssertEqual(AppIntroPage.allCases, [.digitalWallet, .benefits, .trust])
    XCTAssertEqual(AppIntroPage.count, 3)
    XCTAssertEqual(AppIntroPage.digitalWallet.next, .benefits)
    XCTAssertEqual(AppIntroPage.benefits.next, .trust)
    XCTAssertNil(AppIntroPage.trust.next)
    XCTAssertTrue(AppIntroPage.trust.isLast)
    XCTAssertEqual(AppIntroPage.benefits.number, 2)
  }

  func testAppIntroPage_ButtonsFollowTheDesign() {
    XCTAssertFalse(AppIntroPage.digitalWallet.showsBackButton)
    XCTAssertTrue(AppIntroPage.benefits.showsBackButton)
    XCTAssertTrue(AppIntroPage.trust.showsBackButton)

    XCTAssertNotNil(AppIntroPage.digitalWallet.tertiaryButtonTitle)
    XCTAssertNotNil(AppIntroPage.benefits.tertiaryButtonTitle)
    XCTAssertNil(AppIntroPage.trust.tertiaryButtonTitle)

    XCTAssertFalse(AppIntroPage.digitalWallet.primaryButtonHasArrow)
    XCTAssertTrue(AppIntroPage.trust.primaryButtonHasArrow)
  }

  private func makeSut(
    page: AppIntroPage,
    animationDuration: TimeInterval? = nil
  ) -> AppIntroViewModel<MockRouterHost> {
    AppIntroViewModel(
      router: router,
      config: AppIntroUiConfig(page: page, continueRoute: continueRoute),
      interactor: interactor,
      animationDurationLoader: { _ in animationDuration }
    )
  }

  private func capturePushedRoute() -> AppRoute? {
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    return captor.value
  }
}
