//
//  TestCredentialDetailViewModel.swift
//  feature-dashboard
//
//  Created by Ameen Qadri on 26.04.26.
//

import XCTest
import Cuckoo
import logic_core
@testable import feature_dashboard
@testable import feature_test

@MainActor
final class TestCredentialDetailViewModel: XCTestCase {

  private var mockInteractor: MockDashboardInteractor!
  private var mockDeepLinkController: MockDeepLinkController!
  private var mockRouter: MockRouterHost!
  private var mockPidRevokeInteractor: MockPIDRevokeInteractor!

  override func setUp() {
    super.setUp()
    mockInteractor = MockDashboardInteractor()
    mockRouter = MockRouterHost()
    mockDeepLinkController = MockDeepLinkController()
    mockPidRevokeInteractor = MockPIDRevokeInteractor()

    stub(mockRouter) { mock in
      when(mock.pop()).thenDoNothing()
      when(mock.popTo(with: any())).thenDoNothing()
    }
  }

  override func tearDown() {
    mockInteractor = nil
    mockRouter = nil
    mockDeepLinkController = nil
    mockPidRevokeInteractor = nil
    super.tearDown()
  }

  private func makeViewModel(document: DocClaimsDecodable) -> CredentialDetailViewModel<MockRouterHost> {
    CredentialDetailViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      document: document,
      deepLinkController: mockDeepLinkController,
      pidRevokeInteractor: mockPidRevokeInteractor
    )
  }

  func testDeleteCredential_WhenCredentialIsPIDAndWalletBecomesEmpty_ThenRevokesPIDAndResetsToStartup() async throws {
    let document = Constants.euPidModel

    stub(mockPidRevokeInteractor) { mock in
      when(mock.deletePIDFromWallet()).thenDoNothing()
    }
    stub(mockInteractor) { mock in
      when(mock.getAdditionalDocuments()).thenReturn([])
      when(mock.getPIDDocument()).thenReturn(nil)
    }
    stub(mockDeepLinkController) { mock in
      when(mock.setDeeplinkFlowFlag(any())).thenDoNothing()
    }

    let viewModel = makeViewModel(document: document)

    try await viewModel.deleteCredential()

    verify(mockPidRevokeInteractor).deletePIDFromWallet()
    verify(mockInteractor, times(0)).deleteDocument(with: any())
    verify(mockInteractor, times(0)).clearFirstRunFlag()
    verify(mockDeepLinkController).setDeeplinkFlowFlag(equal(to: false))
    verify(mockRouter).popTo(with: equal(to: .featureStartupModule(.startup)))
    verify(mockRouter, times(0)).pop()
  }

  func testDeleteCredential_WhenCredentialIsPIDAndOtherDocumentsRemain_ThenRevokesPIDKeepsFlagAndPops() async throws {
    let document = Constants.euPidModel

    stub(mockPidRevokeInteractor) { mock in
      when(mock.deletePIDFromWallet()).thenDoNothing()
    }
    stub(mockInteractor) { mock in
      when(mock.getAdditionalDocuments()).thenReturn([Constants.isoMdlModel])
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    let viewModel = makeViewModel(document: document)

    try await viewModel.deleteCredential()

    verify(mockPidRevokeInteractor).deletePIDFromWallet()
    verify(mockInteractor, times(0)).deleteDocument(with: any())
    verify(mockInteractor, times(0)).clearFirstRunFlag()
    verify(mockRouter).pop()
    verify(mockRouter, times(0)).popTo(with: any())
    verify(mockDeepLinkController, times(0)).setDeeplinkFlowFlag(any())
  }

  func testDeleteCredential_WhenCredentialIsNotPIDAndWalletStillHasDocuments_ThenPopsWithoutReset() async throws {
    let document = Constants.isoMdlModel

    stub(mockInteractor) { mock in
      when(mock.deleteDocument(with: any())).thenDoNothing()
      when(mock.getAdditionalDocuments()).thenReturn([Constants.isoMdlModel])
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    let viewModel = makeViewModel(document: document)

    try await viewModel.deleteCredential()

    verify(mockInteractor).deleteDocument(with: equal(to: document.id))
    verify(mockPidRevokeInteractor, times(0)).deletePIDFromWallet()
    verify(mockInteractor, times(0)).clearFirstRunFlag()
    verify(mockRouter).pop()
    verify(mockRouter, times(0)).popTo(with: any())
    verify(mockDeepLinkController, times(0)).setDeeplinkFlowFlag(any())
  }

  func testDeleteCredential_WhenCredentialIsNotPIDAndWalletBecomesEmpty_ThenResetsToStartup() async throws {
    let document = Constants.isoMdlModel

    stub(mockInteractor) { mock in
      when(mock.deleteDocument(with: any())).thenDoNothing()
      when(mock.getAdditionalDocuments()).thenReturn([])
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    stub(mockDeepLinkController) { mock in
      when(mock.setDeeplinkFlowFlag(any())).thenDoNothing()
    }

    let viewModel = makeViewModel(document: document)

    try await viewModel.deleteCredential()

    verify(mockInteractor).deleteDocument(with: equal(to: document.id))
    verify(mockPidRevokeInteractor, times(0)).deletePIDFromWallet()
    verify(mockInteractor, times(0)).clearFirstRunFlag()
    verify(mockDeepLinkController).setDeeplinkFlowFlag(equal(to: false))
    verify(mockRouter).popTo(with: equal(to: .featureStartupModule(.startup)))
    verify(mockRouter, times(0)).pop()
  }

  func testDeleteCredential_WhenDeleteDocumentThrows_ThenShowsErrorAndDoesNotNavigate() async throws {
    let document = Constants.isoMdlModel
    let expectedError = NSError(domain: "test", code: -1, userInfo: nil)

    stub(mockInteractor) { mock in
      when(mock.deleteDocument(with: any())).thenThrow(expectedError)
    }

    let viewModel = makeViewModel(document: document)

    try await viewModel.deleteCredential()

    XCTAssertTrue(viewModel.isErrorPopupVisible)

    verify(mockInteractor).deleteDocument(with: equal(to: document.id))
    verify(mockPidRevokeInteractor, times(0)).deletePIDFromWallet()
    verify(mockInteractor, times(0)).getAdditionalDocuments()
    verify(mockInteractor, times(0)).getPIDDocument()
    verify(mockInteractor, times(0)).clearFirstRunFlag()
    verify(mockRouter, times(0)).pop()
    verify(mockRouter, times(0)).popTo(with: any())
    verify(mockDeepLinkController, times(0)).setDeeplinkFlowFlag(any())
  }
}
