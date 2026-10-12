//
//  PushNotificationOnboardingViewModelTests.swift
//  feature-startup
//

import XCTest
import Cuckoo
import logic_ui
@testable import feature_startup
@testable import feature_test

@MainActor
final class PushNotificationOnboardingViewModelTests: XCTestCase {

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
      when(mock.markPushIntroSeen()).thenDoNothing()
      when(mock.requestPushAuthorization()).thenReturn(true)
    }
  }

  override func tearDown() {
    interactor = nil
    router = nil
    super.tearDown()
  }

  func testOnEnableNotificationsTapped_ThenRequestsAuthorizationMarksSeenAndPushes() async {
    let sut = makeSut()

    await sut.onEnableNotificationsTapped()

    verify(interactor).requestPushAuthorization()
    verify(interactor).markPushIntroSeen()
    XCTAssertFalse(sut.viewState.isRequestingAuthorization)
    XCTAssertEqual(capturePushedRoute()?.info.key, continueRoute.info.key)
  }

  func testOnEnableNotificationsTapped_WhenDenied_ThenStillContinues() async {
    stub(interactor) { mock in
      when(mock.requestPushAuthorization()).thenReturn(false)
    }
    let sut = makeSut()

    await sut.onEnableNotificationsTapped()

    verify(interactor).markPushIntroSeen()
    XCTAssertEqual(capturePushedRoute()?.info.key, continueRoute.info.key)
  }

  func testOnLaterTapped_ThenMarksSeenAndPushesWithoutRequesting() {
    let sut = makeSut()

    sut.onLaterTapped()

    verify(interactor, never()).requestPushAuthorization()
    verify(interactor).markPushIntroSeen()
    XCTAssertEqual(capturePushedRoute()?.info.key, continueRoute.info.key)
  }

  func testOnBackTapped_ThenPopsRouter() {
    let sut = makeSut()

    sut.onBackTapped()

    verify(router).pop()
    verify(router, never()).push(with: any())
  }

  private func makeSut() -> PushNotificationOnboardingViewModel<MockRouterHost> {
    PushNotificationOnboardingViewModel(
      router: router,
      config: PushNotificationOnboardingUiConfig(continueRoute: continueRoute),
      interactor: interactor
    )
  }

  private func capturePushedRoute() -> AppRoute? {
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    return captor.value
  }
}
