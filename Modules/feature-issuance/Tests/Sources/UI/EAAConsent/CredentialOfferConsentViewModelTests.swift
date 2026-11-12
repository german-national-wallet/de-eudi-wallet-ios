//
//  CredentialOfferConsentViewModelTests.swift
//  CredentialOfferConsentViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_core
import logic_api
import logic_ui
@testable import feature_issuance

@MainActor
final class CredentialOfferConsentViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockDocumentOfferInteractor!
  private var connectivityMonitor: MockNetworkConnectivityMonitor!
  private var sut: CredentialOfferConsentViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockDocumentOfferInteractor()
    connectivityMonitor = .stubbed()
    sut = CredentialOfferConsentViewModel(
      router: router,
      config: makeConfig(),
      interactor: interactor,
      connectivityMonitor: connectivityMonitor
    )
  }

  override func tearDown() {
    sut = nil
    connectivityMonitor = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testInitialize_WhenOfferProcessingSucceeds_ThenShowsOfferDetails() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer")))
        .thenReturn(.success(makeDocumentOfferUIModel()))
    }

    await sut.initialize()

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertEqual(sut.documentName, "Document")
    XCTAssertEqual(sut.viewState.documentOfferUiModel.issuerName, "Issuer")
    verify(interactor).processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer"))
  }

  func testInitialize_WhenOfferProcessingFails_ThenStopsLoading() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer")))
        .thenReturn(.failure(WalletCoreError.unableToIssueAndStore))
    }

    await sut.initialize()

    XCTAssertFalse(sut.viewState.isLoading)
    verify(interactor).processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer"))
  }

  func testPrimaryButtonAction_WhenTheOfferNeedsATransactionCode_ThenPushesTheOfferScreen() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: any()))
        .thenReturn(.success(makeDocumentOfferUIModel(txCode: .init(isRequired: true, codeLenght: 6))))
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }
    await sut.initialize()

    sut.primaryButtonAction()

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceModule(.credentialOfferRequest) = captor.value else {
      return XCTFail("Expected the offer screen to be pushed")
    }
  }

  func testPrimaryButtonAction_WhenTheOfferNeedsNoTransactionCode_ThenPushesTheLoader() async {
    let pushed = expectation(description: "Wait for the loader to be pushed")
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: any()))
        .thenReturn(.success(makeDocumentOfferUIModel()))
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { _ in
        pushed.fulfill()
      }
    }
    await sut.initialize()

    sut.primaryButtonAction()

    // Without a transaction code the loader is pushed from a task, so it does not happen inline.
    await fulfillment(of: [pushed], timeout: 2)
    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceModule(.documentLoaderView(let config, _)) = captor.value else {
      return XCTFail("Expected the loader to be pushed")
    }
    XCTAssertNil((config as? DocumentLoaderUiConfig)?.txCodeValue)
  }

  func testInitialize_WhenOffline_ThenShowsNoInternetDialogAndRetryProcessesTheOfferAgain() async {
    let processed = expectation(description: "offer processed twice")
    processed.expectedFulfillmentCount = 2
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: any())).then { _ in
        processed.fulfill()
        return .failure(NetworkError.noInternet)
      }
    }

    await sut.initialize()
    XCTAssertTrue(sut.noInternetDialog.isPresented)
    XCTAssertNil(sut.viewState.error)

    sut.noInternetDialog.retry()
    await fulfillment(of: [processed], timeout: 5)
  }

  func testInitialize_WhenOfflineAndCancelTapped_ThenGoesBack() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: any())).thenReturn(.failure(NetworkError.noInternet))
    }
    stub(router) { mock in
      when(mock.pop()).thenDoNothing()
    }

    await sut.initialize()
    sut.noInternetDialog.cancel()

    verify(router).pop()
  }

  func testPrimaryButtonAction_WhenTheLoaderReportsNoInternet_ThenShowsNoInternetDialogInsteadOfFailurePopup() async {
    let pushed = expectation(description: "Wait for the loader to be pushed")
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: any()))
        .thenReturn(.success(makeDocumentOfferUIModel()))
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { _ in
        pushed.fulfill()
      }
    }
    await sut.initialize()
    sut.primaryButtonAction()
    await fulfillment(of: [pushed], timeout: 2)

    let captor = ArgumentCaptor<AppRoute>()
    verify(router).push(with: captor.capture())
    guard case .featureIssuanceModule(.documentLoaderView(_, let onFailure)) = captor.value else {
      return XCTFail("Expected the loader to be pushed")
    }
    onFailure?(NetworkError.noInternet)
    for _ in 0..<200 where !sut.noInternetDialog.isPresented {
      try? await Task.sleep(for: .milliseconds(10))
    }

    XCTAssertTrue(sut.noInternetDialog.isPresented)
    XCTAssertFalse(sut.showIssuanceFailurePopup)
  }

  func testSecondaryButtonAction_WhenCalled_ThenShowsCancelConfirmationPopup() {
    sut.secondaryButtonAction()

    XCTAssertTrue(sut.showCancelConfirmationPopup)
  }

  private func makeConfig() -> UIConfig.Generic {
    .init(
      arguments: ["uri": "openid-credential-offer://credential-offer"],
      navigationSuccessType: .push(.featureDashboardModule(.dashboard)),
      navigationCancelType: .pop
    )
  }

  private func makeDocumentOfferUIModel(
    txCode: DocumentOfferUIModel.TxCode? = nil
  ) -> DocumentOfferUIModel {
    .init(
      issuerName: "Issuer",
      issuerLogo: nil,
      txCode: txCode,
      uiOffers: [
        .init(
          listItem: .init(mainText: .custom("Document")),
          documentName: "Document"
        )
      ],
      docOffers: []
    )
  }
}
