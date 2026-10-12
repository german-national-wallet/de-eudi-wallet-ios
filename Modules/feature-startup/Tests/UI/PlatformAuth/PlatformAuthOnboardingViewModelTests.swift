//
//  PlatformAuthOnboardingViewModelTests.swift
//  feature-startup
//

import XCTest
import Cuckoo
import logic_ui
@testable import feature_startup
@testable import feature_test

@MainActor
final class PlatformAuthOnboardingViewModelTests: XCTestCase {

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
      when(mock.markPlatformAuthIntroSeen()).thenDoNothing()
      when(mock.isPlatformAuthenticationEnabled()).thenReturn(true)
    }
  }

  override func tearDown() {
    interactor = nil
    router = nil
    super.tearDown()
  }

  func testInit_ThenIsChecking() {
    let sut = makeSut()

    XCTAssertTrue(sut.viewState.isChecking)
    XCTAssertFalse(sut.viewState.isPlatformAuthEnabled)
  }

  func testCheckPlatformAuthentication_WhenEnabled_ThenStopsCheckingAndIsEnabled() async {
    let sut = makeSut()

    await sut.checkPlatformAuthentication()

    XCTAssertFalse(sut.viewState.isChecking)
    XCTAssertTrue(sut.viewState.isPlatformAuthEnabled)
  }

  func testCheckPlatformAuthentication_WhenDisabled_ThenIsNotEnabled() async {
    stub(interactor) { mock in
      when(mock.isPlatformAuthenticationEnabled()).thenReturn(false)
    }
    let sut = makeSut()

    await sut.checkPlatformAuthentication()

    XCTAssertFalse(sut.viewState.isChecking)
    XCTAssertFalse(sut.viewState.isPlatformAuthEnabled)
  }

  func testOnPrimaryButtonTapped_WhileChecking_ThenDoesNothing() {
    let sut = makeSut()

    sut.onPrimaryButtonTapped()

    verify(router, never()).push(with: any())
    verify(interactor, never()).markPlatformAuthIntroSeen()
  }

  func testOnPrimaryButtonTapped_AfterCheck_ThenPresentsImportantSheetWithoutNavigating() async {
    let sut = makeSut()
    await sut.checkPlatformAuthentication()

    sut.onPrimaryButtonTapped()

    XCTAssertTrue(sut.viewState.isImportantSheetPresented)
    verify(router, never()).push(with: any())
    verify(interactor, never()).markPlatformAuthIntroSeen()
  }

  func testOnImportantSheetConfirmed_ThenDismissesSheetMarksSeenAndPushesContinueRoute() async {
    let sut = makeSut()
    await sut.checkPlatformAuthentication()
    sut.onPrimaryButtonTapped()

    sut.onImportantSheetConfirmed()

    XCTAssertFalse(sut.viewState.isImportantSheetPresented)
    verify(interactor).markPlatformAuthIntroSeen()
    XCTAssertEqual(capturePushedRoute()?.info.key, continueRoute.info.key)
  }

  func testSetImportantSheetPresented_WhenDismissed_ThenStaysOnScreen() async {
    let sut = makeSut()
    await sut.checkPlatformAuthentication()
    sut.onPrimaryButtonTapped()

    sut.setImportantSheetPresented(false)

    XCTAssertFalse(sut.viewState.isImportantSheetPresented)
    verify(router, never()).push(with: any())
  }

  func testOnBackTapped_ThenPopsRouter() {
    let sut = makeSut()

    sut.onBackTapped()

    verify(router).pop()
    verify(router, never()).push(with: any())
  }

  private func makeSut() -> PlatformAuthOnboardingViewModel<MockRouterHost> {
    PlatformAuthOnboardingViewModel(
      router: router,
      config: PlatformAuthOnboardingUiConfig(continueRoute: continueRoute),
      interactor: interactor
    )
  }

  private func capturePushedRoute() -> AppRoute? {
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    return captor.value
  }
}
