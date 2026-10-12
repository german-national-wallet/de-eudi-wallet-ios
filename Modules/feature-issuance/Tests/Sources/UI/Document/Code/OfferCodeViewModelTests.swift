//
//  OfferCodeViewModelTests.swift
//  OfferCodeViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import OpenID4VCI
import logic_core
import logic_resources
import logic_ui
import feature_common
@testable import feature_test
@testable import feature_issuance

@MainActor
final class OfferCodeViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockDocumentOfferInteractor!
  private var sut: OfferCodeViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockDocumentOfferInteractor()
    sut = OfferCodeViewModel(
      router: router,
      interactor: interactor,
      config: makeConfig()
    )
  }

  override func tearDown() {
    sut = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testIsPrimaryButtonEnabled_WhenCodeLengthMatchesConfig_ThenReturnsTrue() {
    sut.codeInput = "123456"

    XCTAssertTrue(sut.isPrimaryButtonEnabled)
  }

  func testIsPrimaryButtonEnabled_WhenCodeLengthDoesNotMatchConfig_ThenReturnsFalse() {
    sut.codeInput = "12345"

    XCTAssertFalse(sut.isPrimaryButtonEnabled)
  }

  func testPrimaryButtonAction_ThenPushesTheLoaderWithTheEnteredCode() {
    sut.codeInput = "123456"
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.primaryButtonAction()

    guard let config = capturedLoaderConfig() else {
      return XCTFail("Expected the loader to be pushed")
    }
    XCTAssertEqual(config.offerUri, "openid-credential-offer://credential-offer")
    XCTAssertEqual(config.issuerName, "Issuer")
    XCTAssertEqual(config.txCodeValue, "123456")
    // Issuing belongs to the loader, so nothing is asked of the interactor here.
    verify(interactor, never()).issueDocuments(
      with: any(),
      issuerName: any(),
      docOffers: any(),
      successNavigation: any(),
      txCodeValue: any()
    )
  }

  func testPrimaryButtonAction_WhenTheLoaderReportsAGrantRejection_ThenShowsInvalidTransactionCodeError() async {
    let reported = expectation(description: "Wait for the failure to be reported back")
    sut.codeInput = "123456"
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.primaryButtonAction()
    capturedLoaderFailureHandler()?(
      CredentialIssuanceError.pushedAuthorizationRequestFailed(
        error: "invalid_grant",
        errorDescription: nil
      )
    )

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      reported.fulfill()
    }
    await fulfillment(of: [reported], timeout: 1)
    XCTAssertEqual(sut.errorMessage, LocalizableStringKey.eaaOfferTxCodeInvalidEntry.toString)
    XCTAssertNil(sut.viewState.error)
    // The field keeps wanting focus, so the entry view takes the keyboard back when this screen
    // reappears; nothing here raises it while the loader is still on screen.
    XCTAssertTrue(sut.codeIsFocused)
  }

  func testPrimaryButtonAction_WhenTheLoaderReportsAnotherFailure_ThenShowsGenericError() async {
    let reported = expectation(description: "Wait for the failure to be reported back")
    sut.codeInput = "123456"
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.primaryButtonAction()
    capturedLoaderFailureHandler()?(WalletCoreError.unableToIssueAndStore)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      reported.fulfill()
    }
    await fulfillment(of: [reported], timeout: 1)
    // Not the user's code being wrong, so the real error is surfaced instead.
    XCTAssertTrue(sut.errorMessage.isEmpty)
    XCTAssertNotNil(sut.viewState.error)
  }

  private func capturedLoaderRoute() -> FeatureIssuanceRouteModule? {
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceModule(let module) = captor.value else {
      return nil
    }
    return module
  }

  private func capturedLoaderConfig() -> DocumentLoaderUiConfig? {
    guard case .documentLoaderView(let config, _) = capturedLoaderRoute() else {
      return nil
    }
    return config as? DocumentLoaderUiConfig
  }

  private func capturedLoaderFailureHandler() -> (@Sendable (Error) -> Void)? {
    guard case .documentLoaderView(_, let onFailure) = capturedLoaderRoute() else {
      return nil
    }
    return onFailure
  }

  private func makeConfig() -> IssuanceCodeUiConfig {
    .init(
      offerUri: "openid-credential-offer://credential-offer",
      issuerName: "Issuer",
      txCodeLength: 6,
      docOffers: [],
      successNavigation: .push(.featureDashboardModule(.dashboard)),
      navigationCancelType: .pop
    )
  }
}
