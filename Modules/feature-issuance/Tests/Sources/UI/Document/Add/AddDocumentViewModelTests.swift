//
//  AddDocumentViewModelTests.swift
//  AddDocumentViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_analytics
import logic_core
import logic_ui
@testable import feature_issuance

@MainActor
final class AddDocumentViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockAddDocumentInteractor!
  private var deepLinkController: MockDeepLinkController!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var analyticsController: MockAnalyticsController!
  private var sut: AddDocumentViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockAddDocumentInteractor()
    deepLinkController = MockDeepLinkController()
    secureEnclaveController = MockSecureEnclaveController()
    analyticsController = MockAnalyticsController()
    sut = AddDocumentViewModel(
      router: router,
      interactor: interactor,
      deepLinkController: deepLinkController,
      secureEnclaveController: secureEnclaveController,
      analyticsController: analyticsController,
      config: IssuanceFlowUiConfig(flow: .extraDocument)
    )
  }

  override func tearDown() {
    sut = nil
    analyticsController = nil
    secureEnclaveController = nil
    deepLinkController = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testInitialize_WhenDocumentsLoadAndNoPendingIssuanceExists_ThenShowsDocuments() async {
    let documents = AddDocumentUIModel.mocks
    stub(interactor) { mock in
      when(mock.fetchScopedDocuments(with: any())).thenReturn(.success(documents))
      when(mock.resumeDynamicIssuance()).thenReturn(.noPending)
    }
    stub(deepLinkController) { mock in
      when(mock.getPendingDeepLinkAction()).thenReturn(nil)
    }

    await sut.initialize()

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertEqual(sut.viewState.addDocumentCellModels.count, documents.count)
    XCTAssertTrue(sut.viewState.addDocumentCellModels.allSatisfy { !$0.isLoading })
    XCTAssertNil(sut.viewState.error)
    verify(interactor).fetchScopedDocuments(with: any())
    verify(interactor).resumeDynamicIssuance()
  }

  func testInitialize_WhenDocumentLoadingFails_ThenShowsError() async {
    stub(interactor) { mock in
      when(mock.fetchScopedDocuments(with: any())).thenReturn(.failure(WalletCoreError.unableFetchDocuments))
    }

    await sut.initialize()

    XCTAssertNotNil(sut.viewState.error)
    verify(interactor).fetchScopedDocuments(with: any())
  }

  func testOnClick_WhenCalled_ThenStartsIssuanceTraceAndPushesOnboarding() async {
    let expectation = expectation(description: "Wait for onboarding route push")
    var pushedRoute: AppRoute?
    stub(analyticsController) { mock in
      when(mock.startTrace(name: any(), initialAttributes: any())).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        pushedRoute = route
        expectation.fulfill()
      }
    }

    sut.onClick()

    await fulfillment(of: [expectation], timeout: 1)
    verify(analyticsController).startTrace(name: equal(to: AnalyticsConstants.TraceName.issuance), initialAttributes: any())
    XCTAssertEqual(pushedRoute?.info.key, "issuanceOnboardingCardView")
  }
}
