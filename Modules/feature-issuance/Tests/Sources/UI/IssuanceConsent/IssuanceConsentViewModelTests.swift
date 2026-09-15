//
//  IssuanceConsentViewModelTests.swift
//  IssuanceConsentViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_ui
@testable import feature_issuance

@MainActor
final class IssuanceConsentViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var issuanceCancellationInteractor: MockIssuanceCancellationInteractor!
  private var sut: IssuanceConsentViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    issuanceCancellationInteractor = MockIssuanceCancellationInteractor()

    stub(issuanceCancellationInteractor) { mock in
      when(mock.cancelIssuance(verificationInteractor: any())).thenDoNothing()
    }
    sut = IssuanceConsentViewModel(
      router: router,
      config: UIConfig.IssuanceConsentViewConfig(
        primaryRoute: .featureIssuanceModule(.issuanceAddDocument(config: NoConfig())),
        issuanceInteractor: nil
      ),
      issuanceCancellationInteractor: issuanceCancellationInteractor
    )
  }

  override func tearDown() {
    sut = nil
    issuanceCancellationInteractor = nil
    router = nil

    super.tearDown()
  }

  func testDoWork_WhenCalled_ThenPushesPrimaryRoute() {
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.doWork()

    verify(router).push(with: any())
  }

  func testGoToPIDIssuer_WhenCalled_ThenPushesIssuerDetails() {
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.goToPidIssuer()

    verify(router).push(with: any())
  }

  func testRejectButtonTapped_WhenCalled_ThenOpensRejectSheet() {
    XCTAssertFalse(sut.isRejectSheetOpen)

    sut.rejectButtonTapped()

    XCTAssertTrue(sut.isRejectSheetOpen)
  }

  func testRejectConfirmed_WhenCalled_ThenClosesSheetAndLeavesFlow() {
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.rejectButtonTapped()
    sut.rejectConfirmed()

    XCTAssertFalse(sut.isRejectSheetOpen)
    verify(router).popTo(with: any())
  }
}
