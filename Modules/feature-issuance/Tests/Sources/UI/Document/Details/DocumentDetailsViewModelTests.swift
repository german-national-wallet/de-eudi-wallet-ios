//
//  DocumentDetailsViewModelTests.swift
//  DocumentDetailsViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_core
import logic_ui
import feature_common
@testable import feature_issuance

@MainActor
final class DocumentDetailsViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockDocumentDetailsInteractor!
  private var sut: DocumentDetailsViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockDocumentDetailsInteractor()
    sut = DocumentDetailsViewModel(
      router: router,
      interactor: interactor,
      config: IssuanceDetailUiConfig(flow: .extraDocument("document-id"))
    )
  }

  override func tearDown() {
    sut = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testFetchDocumentDetails_WhenExtraDocumentExists_ThenShowsDeleteActionAndDocumentFields() async {
    let document = DocumentDetailsUIModel.mock()
    stub(interactor) { mock in
      when(mock.fetchStoredDocument(documentId: equal(to: "document-id")))
        .thenReturn(.success(document))
    }

    await sut.fetchDocumentDetails()

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertTrue(sut.viewState.hasDeleteAction)
    XCTAssertEqual(sut.viewState.document.id, document.id)
    XCTAssertEqual(sut.viewState.documentFieldsCount, document.documentFields.count)
    XCTAssertNil(sut.viewState.error)
    verify(interactor).fetchStoredDocument(documentId: equal(to: "document-id"))
  }

  func testFetchDocumentDetails_WhenInteractorFails_ThenShowsError() async {
    stub(interactor) { mock in
      when(mock.fetchStoredDocument(documentId: equal(to: "document-id")))
        .thenReturn(.failure(WalletCoreError.unableFetchDocument))
    }

    await sut.fetchDocumentDetails()

    XCTAssertNotNil(sut.viewState.error)
    verify(interactor).fetchStoredDocument(documentId: equal(to: "document-id"))
  }

  func testOnDeleteDocument_WhenDeletionDoesNotRequireReboot_ThenReturnsToDashboard() async {
    let expectation = expectation(description: "Wait for dashboard navigation")
    let document = DocumentDetailsUIModel.mock()
    stub(interactor) { mock in
      when(mock.fetchStoredDocument(documentId: equal(to: "document-id")))
        .thenReturn(.success(document))
      when(mock.deleteDocument(with: equal(to: document.id), and: equal(to: document.type)))
        .thenReturn(.success(shouldReboot: false))
    }
    stub(router) { mock in
      when(mock.popTo(with: any())).then { _ in
        expectation.fulfill()
      }
    }

    await sut.fetchDocumentDetails()
    sut.onDeleteDocument()

    await fulfillment(of: [expectation], timeout: 1)
    verify(interactor).deleteDocument(with: equal(to: document.id), and: equal(to: document.type))
    verify(router).popTo(with: any())
  }

  func testOnDeleteDocument_WhenDeletionRequiresReboot_ThenReturnsToStartup() async {
    let expectation = expectation(description: "Wait for startup navigation")
    let document = DocumentDetailsUIModel.mock()
    stub(interactor) { mock in
      when(mock.fetchStoredDocument(documentId: equal(to: "document-id")))
        .thenReturn(.success(document))
      when(mock.deleteDocument(with: equal(to: document.id), and: equal(to: document.type)))
        .thenReturn(.success(shouldReboot: true))
    }
    stub(router) { mock in
      when(mock.popTo(with: any())).then { _ in
        expectation.fulfill()
      }
    }

    await sut.fetchDocumentDetails()
    sut.onDeleteDocument()

    await fulfillment(of: [expectation], timeout: 1)
    verify(interactor).deleteDocument(with: equal(to: document.id), and: equal(to: document.type))
    verify(router).popTo(with: any())
  }
}
