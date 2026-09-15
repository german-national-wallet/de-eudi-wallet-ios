//
//  SuccessViewModelTests.swift
//  SuccessViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_ui
@testable import feature_issuance

@MainActor
final class SuccessViewModelTests: XCTestCase {

  func testPrimaryButtonPressed_WhenCallbackExists_ThenRunsCallback() {
    let expectation = expectation(description: "Wait for success callback")
    let sut = SuccessViewModel(
      config: UIConfig.Success(title: .init(value: .digitalIdDeleted)),
      callback: {
        expectation.fulfill()
      },
      deepLinkController: MockDeepLinkController(),
      router: MockRouterHost()
    )

    sut.primaryButtonPressed()

    wait(for: [expectation], timeout: 1)
  }
}
