//
//  TestSettingsTabViewModel.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 05.11.26.
//

import XCTest
import Cuckoo
import logic_business
@testable import logic_ui
@testable import feature_dashboard

@MainActor
final class TestSettingsTabViewModel: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockSettingsTabInteractor!
  private var configLogic: MockConfigLogic!

  override func setUp() {
    super.setUp()
    router = MockRouterHost()
    interactor = MockSettingsTabInteractor()
    configLogic = MockConfigLogic()
    stub(interactor) { mock in
      when(mock.getAppVersion()).thenReturn("1.0")
      when(mock.getAppBuildNumber()).thenReturn("1")
      when(mock.retrieveLogFileUrl()).thenReturn(nil)
    }
    stub(configLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.DEV)
    }
  }

  override func tearDown() {
    configLogic = nil
    interactor = nil
    router = nil
    super.tearDown()
  }

  func testDeinit_WhenNoLongerReferenced_ThenRowActionsDoNotKeepTheViewModelAlive() {
    var sut: SettingsTabViewModel<MockRouterHost>? = makeSUT()
    weak var weakSUT = sut
    XCTAssertFalse(sut?.viewState.sections.isEmpty ?? true)

    sut = nil

    XCTAssertNil(weakSUT)
  }

  func testWalletLossProtectionItem_WhenTapped_ThenPushesWalletLossProtection() throws {
    let sut = makeSUT()
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    try item("settingsWalletLossProtectionItem", in: sut).action()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    XCTAssertEqual(captor.value?.info.key, AppRoute.featureDashboardModule(.walletLossProtection).info.key)
  }

  func testDebugConfigItem_WhenTapped_ThenPushesDebugConfig() throws {
    let sut = makeSUT()
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    try item("settingsDebugConfigItem", in: sut).action()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    XCTAssertEqual(captor.value?.info.key, AppRoute.featureDashboardModule(.debugConfig).info.key)
  }

  private func makeSUT() -> SettingsTabViewModel<MockRouterHost> {
    SettingsTabViewModel(router: router, interactor: interactor, configLogic: configLogic)
  }

  private func item(_ id: String, in sut: SettingsTabViewModel<MockRouterHost>) throws -> SettingsTabItemUIModel {
    try XCTUnwrap(sut.viewState.sections.flatMap(\.items).first { $0.id == id })
  }
}
