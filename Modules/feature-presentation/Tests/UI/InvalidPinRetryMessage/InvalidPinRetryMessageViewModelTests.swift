//
//  InvalidPinRetryMessageViewModelTests.swift
//  InvalidPinRetryMessageViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_api
import logic_resources
import logic_ui
@testable import feature_presentation

@MainActor
final class InvalidPinRetryMessageViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var pidRevokeInteractor: MockPIDRevokeInteractor!
  private var prefsController: MockPrefsController!
  private var deepLinkController: MockDeepLinkController!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    pidRevokeInteractor = MockPIDRevokeInteractor()
    prefsController = MockPrefsController()
    deepLinkController = MockDeepLinkController()
  }

  override func tearDown() {
    deepLinkController = nil
    prefsController = nil
    pidRevokeInteractor = nil
    router = nil

    super.tearDown()
  }

  func testInit_WhenPINIsBlocked_ThenShowsBlockedUserState() {
    let sut = makeSUT(
      invalidPasswordResponse: .init(
        code: RWSCAServerErrorCode.accountLocked,
        message: nil,
        timestamp: "2026-05-05T10:00:00Z",
        traceId: "trace-id",
        tryCounter: 0
      )
    )

    XCTAssertFalse(sut.showCounterView)
    XCTAssertTrue(sut.showBlockedUserButtons)
    XCTAssertNotNil(sut.warningMessage)
  }

  func testSendUserToDashboard_WhenCalled_ThenReturnsToStartup() {
    let sut = makeSUT()
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.sendUserToDashboard()

    verify(router).popTo(with: any())
  }

  func testResetWallet_WhenCalled_ThenDeletesPIDClearsDeepLinkFlagAndPopsToStartup() async {
    let sut = makeSUT()
    stub(pidRevokeInteractor) { mock in
      when(mock.deletePIDFromWallet()).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }
    stub(deepLinkController) { mock in
      when(mock.setDeeplinkFlowFlag(any())).thenDoNothing()
    }

    await sut.resetWallet()

    verify(pidRevokeInteractor).deletePIDFromWallet()
    verify(router).popTo(with: any())
  }

  func testResetWallet_WhenDeletePIDFails_ThenDoesNotClearFlagOrNavigate() async {
    struct DeleteError: Error {}
    let sut = makeSUT()
    stub(pidRevokeInteractor) { mock in
      when(mock.deletePIDFromWallet()).thenThrow(DeleteError())
    }

    await sut.resetWallet()
    verify(pidRevokeInteractor).deletePIDFromWallet()
    verify(deepLinkController, times(0)).setDeeplinkFlowFlag(any())
    verify(router, times(0)).popTo(with: any())
  }

  private func makeSUT(
    invalidPasswordResponse: InvalidPasswordResponse? = nil
  ) -> InvalidPinRetryMessageViewModel<MockRouterHost> {
    InvalidPinRetryMessageViewModel(
      router: router,
      config: UIConfig.InvalidPinRetryMessageConfig(
        mainTitle: .walletPinMultipleWrongEntry,
        retryMessage: .walletPinTryAgainIn,
        primaryButtonTitle: .walletPinForgotten,
        invalidPasswordResponse: invalidPasswordResponse
      ),
      pidRevokeInteractor: pidRevokeInteractor,
      prefsController: prefsController,
      deepLinkController: deepLinkController
    )
  }
}
