//
//  SetupSuccessViewModelTests.swift
//  feature-startup
//

import XCTest
import Cuckoo
import logic_ui
@testable import feature_startup
@testable import feature_test

@MainActor
final class SetupSuccessViewModelTests: XCTestCase {

  private let continueRoute: AppRoute = .featureDashboardModule(.dashboard)

  private var router: MockRouterHost!
  private var interactor: MockStartupInteractor!

  override func setUp() {
    super.setUp()
    router = MockRouterHost()
    interactor = MockStartupInteractor()
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }
    stub(interactor) { mock in
      when(mock.markAppSetupCompleted()).thenDoNothing()
    }
  }

  override func tearDown() {
    interactor = nil
    router = nil
    super.tearDown()
  }

  func testOnAnimationFinished_ThenMarksSetupCompletedAndPushesContinueRoute() {
    let sut = makeSut()

    sut.onAnimationFinished()

    verify(interactor).markAppSetupCompleted()
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    XCTAssertEqual(captor.value?.info.key, continueRoute.info.key)
  }

  func testOnAnimationFinished_WhenCalledTwice_ThenCompletesOnce() {
    let sut = makeSut()

    sut.onAnimationFinished()
    sut.onAnimationFinished()

    verify(interactor, times(1)).markAppSetupCompleted()
    verify(router, times(1)).push(with: any())
  }

  private func makeSut() -> SetupSuccessViewModel<MockRouterHost> {
    SetupSuccessViewModel(
      router: router,
      config: SetupSuccessUiConfig(continueRoute: continueRoute),
      interactor: interactor
    )
  }
}
