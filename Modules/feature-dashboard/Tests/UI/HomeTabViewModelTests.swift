//
//  HomeTabViewModelTests.swift
//  HomeTabViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import SwiftUI
import logic_resources
import logic_ui
@testable import feature_dashboard

@MainActor
final class HomeTabViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockHomeTabInteractor!
  private var sut: HomeTabViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockHomeTabInteractor()
    stub(interactor) { mock in
      when(mock.fetchUsername()).thenReturn("Tamas")
    }
    sut = HomeTabViewModel(
      router: router,
      interactor: interactor,
      onUpdateToolbar: { _, _ in }
    )
  }

  override func tearDown() {
    sut = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testInit_WhenCreated_ThenShowsFetchedUsername() {
    XCTAssertEqual(sut.viewState.username, "Tamas")
    verify(interactor).fetchUsername()
  }

  func testOpenSignDocument_WhenCalled_ThenPushesSignDocumentRoute() {
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.openSignDocument()

    verify(router).push(with: any())
  }

  func testToggleBleModal_WhenSceneIsInactive_ThenMarksPendingBleModalAction() {
    sut.setPhase(with: .background)

    sut.toggleBleModal()

    XCTAssertTrue(sut.viewState.pendingBleModalAction)
    XCTAssertFalse(sut.isBleModalShowing)
  }

  func testOnBleSettings_WhenCalled_ThenDelegatesToInteractor() {
    stub(interactor) { mock in
      when(mock.openBleSettings()).thenDoNothing()
    }

    sut.onBleSettings()

    verify(interactor).openBleSettings()
  }
}
