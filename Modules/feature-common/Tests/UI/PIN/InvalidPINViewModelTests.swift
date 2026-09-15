//
//  InvalidPINViewModelTests.swift
//  InvalidPINViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_ui
@testable import feature_common

@MainActor
final class InvalidPINViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var sut: InvalidPINViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    sut = InvalidPINViewModel(
      router: router,
      config: makeConfig()
    )
  }

  override func tearDown() {
    sut = nil
    router = nil

    super.tearDown()
  }

  func testOnPrimaryActionButtonClicked_WhenCalled_ThenRunsPrimaryNavigation() {
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.onPrimaryActionButtonClicked()

    verify(router).push(with: any())
  }

  func testOnSecondaryActionButtonClicked_WhenCalled_ThenShowsActionSheet() {
    sut.onSecondaryActionButtonClicked()

    XCTAssertTrue(sut.showActionSheet)
  }

  func testOnCancelButtonClicked_WhenCancelNavigationExists_ThenRunsCancelNavigation() {
    stub(router) { mock in
      when(mock.pop()).thenDoNothing()
    }

    sut.onCancelButtonClicked()

    verify(router).pop()
  }

  private func makeConfig() -> UIConfig.InvalidPin {
    .init(
      title: .invalidQuickPin,
      navigationSuccessType: .push(.featureDashboardModule(.dashboard)),
      navigationCancelType: .pop,
      primaryButtonTitle: .okButton
    )
  }
}
