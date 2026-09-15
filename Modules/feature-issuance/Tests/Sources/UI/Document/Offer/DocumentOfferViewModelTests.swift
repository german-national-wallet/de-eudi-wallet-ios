//
//  DocumentOfferViewModelTests.swift
//  DocumentOfferViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_core
import logic_ui
@testable import feature_test
@testable import feature_issuance

@MainActor
final class DocumentOfferViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockDocumentOfferInteractor!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var credentialsInteractor: MockCredentialsInteractor!
  private var sut: DocumentOfferViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockDocumentOfferInteractor()
    secureEnclaveController = MockSecureEnclaveController()
    credentialsInteractor = MockCredentialsInteractor()
    sut = DocumentOfferViewModel(
      router: router,
      interactor: interactor,
      secureEnclaveController: secureEnclaveController,
      credentialsInteractor: credentialsInteractor,
      config: makeConfig()
    )
  }

  override func tearDown() {
    sut = nil
    credentialsInteractor = nil
    secureEnclaveController = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testInitialize_WhenOfferProcessingSucceeds_ThenAllowsIssue() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer")))
        .thenReturn(.success(makeDocumentOfferUIModel()))
    }

    await sut.initialize()

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertTrue(sut.viewState.allowIssue)
    XCTAssertTrue(sut.viewState.initialized)
    XCTAssertEqual(sut.viewState.documentOfferUiModel.issuerName, "Issuer")
    XCTAssertNil(sut.viewState.error)
    verify(interactor).processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer"))
  }

  func testInitialize_WhenOfferProcessingFails_ThenShowsError() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer")))
        .thenReturn(.failure(WalletCoreError.missingPid))
    }

    await sut.initialize()

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertFalse(sut.viewState.allowIssue)
    XCTAssertTrue(sut.viewState.initialized)
    XCTAssertNotNil(sut.viewState.error)
    verify(interactor).processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer"))
  }

  func testOnIssueDocuments_WhenTxCodeRequired_ThenPushesIssuanceCode() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer")))
        .thenReturn(.success(makeDocumentOfferUIModel(txCode: .init(isRequired: true, codeLenght: 6))))
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.initialize()
    sut.onIssueDocuments()

    verify(router).push(with: any())
  }

  func testOnIssueDocuments_WhenDynamicIssuanceReturned_ThenPushesPresentationRequest() async {
    let expectation = expectation(description: "Wait for presentation request push")
    let coordinator = MockRemoteSessionCoordinator(session: Constants.mockPresentationSession)
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer")))
        .thenReturn(.success(makeDocumentOfferUIModel()))
      when(mock.issueDocuments(
        with: any(),
        issuerName: any(),
        docOffers: any(),
        successNavigation: any(),
        txCodeValue: any()
      ))
      .thenReturn(.dynamicIssuance(coordinator))
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { _ in
        expectation.fulfill()
      }
    }

    await sut.initialize()
    sut.onIssueDocuments()

    await fulfillment(of: [expectation], timeout: 1)
    XCTAssertTrue(sut.viewState.isLoading, "Loading must stay true while the user is in the webview so the screen is blocked on return")
    verify(router).push(with: any())
    verify(interactor).issueDocuments(
      with: equal(to: "openid-credential-offer://credential-offer"),
      issuerName: equal(to: "Issuer"),
      docOffers: any(),
      successNavigation: any(),
      txCodeValue: any()
    )
  }

  func testOnIssueDocuments_WhenAlreadyLoading_ThenIssueDocumentsNotCalledAgain() async {
    stub(interactor) { mock in
      when(mock.processOfferRequest(with: equal(to: "openid-credential-offer://credential-offer")))
        .thenReturn(.success(makeDocumentOfferUIModel()))
    }

    await sut.initialize()

    // Simulate the ViewModel being mid-issuance (isLoading: true)
    sut.setState { $0.copy(isLoading: true) }

    sut.onIssueDocuments()

    verify(interactor, never()).issueDocuments(
      with: any(),
      issuerName: any(),
      docOffers: any(),
      successNavigation: any(),
      txCodeValue: any()
    )
  }

  private func makeConfig() -> UIConfig.Generic {
    .init(
      arguments: ["uri": "openid-credential-offer://credential-offer"],
      navigationSuccessType: .push(.featureDashboardModule(.dashboard)),
      navigationCancelType: .pop
    )
  }

  private func makeDocumentOfferUIModel(txCode: DocumentOfferUIModel.TxCode? = nil) -> DocumentOfferUIModel {
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
