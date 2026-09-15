//
//  DocumentTabViewModelTests.swift
//  DocumentTabViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_business
import logic_core
import logic_resources
import logic_ui
import feature_issuance
@testable import feature_dashboard

@MainActor
final class DocumentTabViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockDocumentTabInteractor!
  private var credentialsInteractor: MockCredentialsInteractor!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var configLogic: MockConfigLogic!
  private var toolbarUpdates: [(ToolBarContent, LocalizableStringKey)]!
  private var sut: DocumentTabViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockDocumentTabInteractor()
    credentialsInteractor = MockCredentialsInteractor()
    secureEnclaveController = MockSecureEnclaveController()
    configLogic = MockConfigLogic()
    toolbarUpdates = []

    stub(interactor) { mock in
      when(mock.onFilterChangeState()).thenReturn(emptyDocumentFilterStream())
      when(mock.hasDeferredDocuments()).thenReturn(false)
      when(mock.retrieveLogFileUrl()).thenReturn(nil)
    }

    stub(configLogic) { mock in
      when(mock.pidMsoMdocConfigId.get).thenReturn("pid-mso-mdoc")
    }

    sut = makeSUT()
  }

  override func tearDown() {
    sut = nil
    toolbarUpdates = nil
    configLogic = nil
    secureEnclaveController = nil
    credentialsInteractor = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testOnCreate_WhenFetchSucceeds_ThenInitializesFiltersAndAppliesFilters() async {
    let expectation = expectation(description: "Wait for filter application")
    let filterableList = FilterableList(items: [])
    stub(interactor) { mock in
      when(mock.fetchDocuments(failedDocuments: equal(to: []))).thenReturn(.success(filterableList))
      when(mock.initializeFilters(filterableList: any())).thenDoNothing()
      when(mock.applyFilters()).then {
        expectation.fulfill()
      }
    }

    sut.onCreate()

    await fulfillment(of: [expectation], timeout: 1)
    await waitUntil { !self.sut.viewState.isFromOnPause }
    verify(interactor).fetchDocuments(failedDocuments: equal(to: []))
    verify(interactor).initializeFilters(filterableList: any())
    verify(interactor).applyFilters()
    XCTAssertFalse(sut.viewState.isFromOnPause)
    XCTAssertEqual(toolbarUpdates.count, 1)
  }

  func testOnCreate_WhenFetchFails_ThenStopsLoadingAndClearsDocuments() async {
    let expectation = expectation(description: "Wait for fetch failure")
    stub(interactor) { mock in
      when(mock.fetchDocuments(failedDocuments: equal(to: []))).then { _ in
        expectation.fulfill()
        return .failure(TestError.expected)
      }
    }

    sut.onCreate()

    await fulfillment(of: [expectation], timeout: 1)
    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertTrue(sut.viewState.documents.isEmpty)
    verify(interactor, never()).initializeFilters(filterableList: any())
    verify(interactor, never()).applyFilters()
  }

  func testOnAdd_WhenCalled_ThenPushesAddDocumentOptionsRoute() {
    var pushedRoute: AppRoute?
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        pushedRoute = route
      }
    }

    sut.onAdd()

    verify(router).push(with: any())
    XCTAssertEqual(pushedRoute?.info.key, "issuanceAddDocumentOptions")
  }

  func testLoadMoreCredentials_WhenPrivateKeyIsMissing_ThenDoesNotRequestCredentials() async {
    stub(secureEnclaveController) { mock in
      when(mock.retrievePrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(nil)
    }

    await sut.loadMoreCredentials()

    verify(secureEnclaveController).retrievePrivateKey(with: equal(to: .credentialPrivKey))
    verify(credentialsInteractor, never()).getCredentialsWithRefreshToken(any(), privateKey: any())
  }

  private func makeSUT() -> DocumentTabViewModel<MockRouterHost> {
    DocumentTabViewModel(
      router: router,
      interactor: interactor,
      credentialsInteractor: credentialsInteractor,
      secureEnclaveController: secureEnclaveController,
      configLogic: configLogic,
      onUpdateToolbar: { [weak self] toolbarContent, title in
        self?.toolbarUpdates.append((toolbarContent, title))
      }
    )
  }

  private func waitUntil(
    timeout: TimeInterval = 1,
    condition: @escaping () -> Bool
  ) async {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition(), Date() < deadline {
      await Task.yield()
    }
  }
}

private enum TestError: Error {
  case expected
}

private func emptyDocumentFilterStream() -> AsyncStream<FiltersPartialState> {
  AsyncStream { continuation in
    continuation.finish()
  }
}
