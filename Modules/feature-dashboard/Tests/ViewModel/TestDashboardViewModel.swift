//
//  TestDashboardViewModel.swift
//  feature-dashboard
//
//  Created by Sándor Gazdag on 08.09.26.
//

import XCTest
import Cuckoo
import Swinject
import logic_core
import logic_business
import logic_analytics
@testable import logic_ui
@testable import feature_dashboard
@testable import feature_issuance
@testable import feature_test

@MainActor
final class TestDashboardViewModel: XCTestCase {

  private var mockDashboardInteractor: MockDashboardInteractor!
  private var mockHomeTabInteractor: MockHomeTabInteractor!
  private var mockDocumentTabInteractor: MockDocumentTabInteractor!
  private var mockTransactionTabInteractor: MockTransactionTabInteractor!
  private var mockCredentialsInteractor: MockCredentialsInteractor!
  private var mockSettingsTabInteractor: MockSettingsTabInteractor!
  private var mockSecureEnclaveController: MockSecureEnclaveController!
  private var mockConfigLogic: MockConfigLogic!
  private var mockDeepLinkController: MockDeepLinkController!
  private var mockRouter: MockRouterHost!
  private var mockLogging: MockLogging!
  private var mockAnalyticsController: MockAnalyticsController!
  private var mockaddDocumentInteractor: MockAddDocumentInteractor!

  override func setUp() {
    super.setUp()
    mockDashboardInteractor = MockDashboardInteractor()
    mockHomeTabInteractor = MockHomeTabInteractor()
    mockDocumentTabInteractor = MockDocumentTabInteractor()
    mockTransactionTabInteractor = MockTransactionTabInteractor()
    mockCredentialsInteractor = MockCredentialsInteractor()
    mockSettingsTabInteractor = MockSettingsTabInteractor()
    mockSecureEnclaveController = MockSecureEnclaveController()
    mockConfigLogic = MockConfigLogic()
    mockDeepLinkController = MockDeepLinkController()
    mockRouter = MockRouterHost()
    mockLogging = MockLogging()
    mockAnalyticsController = MockAnalyticsController()
    mockaddDocumentInteractor = MockAddDocumentInteractor()

    registerGraphDependencies()
    stubTabDependencies()
  }

  override func tearDown() {
    mockDashboardInteractor = nil
    mockHomeTabInteractor = nil
    mockDocumentTabInteractor = nil
    mockTransactionTabInteractor = nil
    mockCredentialsInteractor = nil
    mockSettingsTabInteractor = nil
    mockSecureEnclaveController = nil
    mockConfigLogic = nil
    mockDeepLinkController = nil
    mockRouter = nil
    mockLogging = nil
    mockAnalyticsController = nil
    mockaddDocumentInteractor = nil
    super.tearDown()
  }

  // MARK: - Initialization

  func testInit_WhenCreated_ThenSelectsWalletAndCreatesTabs() {
    let viewModel = makeViewModel()

    XCTAssertEqual(viewModel.selectedTab, .overview)
    XCTAssertNotNil(viewModel.viewState.homeTab)
    XCTAssertNotNil(viewModel.viewState.documentTab)
    XCTAssertNotNil(viewModel.viewState.transactionTab)
    XCTAssertNotNil(viewModel.viewState.credentialsTab)
    XCTAssertNotNil(viewModel.viewState.addDocumentTab)
    XCTAssertNotNil(viewModel.viewState.activitiesTab)
    XCTAssertNotNil(viewModel.viewState.settingsTab)
  }

  // MARK: - Helpers

  private func makeViewModel() -> DashboardViewModel<MockRouterHost> {
    DashboardViewModel(
      router: mockRouter,
      dashboardInteractor: mockDashboardInteractor,
      homeTabInteractor: mockHomeTabInteractor,
      documentTabInteractor: mockDocumentTabInteractor,
      transactionTabInteractor: mockTransactionTabInteractor,
      credentialsInteractor: mockCredentialsInteractor,
      settingsTabInteractor: mockSettingsTabInteractor,
      secureEnclaveController: mockSecureEnclaveController,
      configLogic: mockConfigLogic,
      deepLinkController: mockDeepLinkController
    )
  }

  private func registerGraphDependencies() {
    DIGraph.lazyLoad(
      with: [
        DashboardViewModelTestAssembly(
          logging: mockLogging,
          analyticsController: mockAnalyticsController,
          addDocumentInteractor: mockaddDocumentInteractor
        )
      ]
    )
  }

  private func stubTabDependencies() {
    let finishedFilterStream = AsyncStream<FiltersPartialState> { continuation in
      continuation.finish()
    }

    stub(mockDashboardInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
      when(mock.hasDocuments.get).thenReturn(true)
    }
    stub(mockHomeTabInteractor) { mock in
      when(mock.fetchUsername()).thenReturn("")
    }
    stub(mockDocumentTabInteractor) { mock in
      when(mock.onFilterChangeState()).thenReturn(finishedFilterStream)
    }
    stub(mockSettingsTabInteractor) { mock in
      when(mock.getAppVersion()).thenReturn("")
      when(mock.retrieveLogFileUrl()).thenReturn(nil)
    }
    stub(mockConfigLogic) { mock in
      when(mock.appBuildVariant.get).thenReturn(.STAGING)
    }
  }
}

private final class DashboardViewModelTestAssembly: Assembly {

  private let logging: Logging
  private let analyticsController: AnalyticsController
  private let addDocumentInteractor: AddDocumentInteractor

  init(logging: Logging, analyticsController: AnalyticsController, addDocumentInteractor: AddDocumentInteractor) {
    self.logging = logging
    self.analyticsController = analyticsController
    self.addDocumentInteractor = addDocumentInteractor
  }

  func assemble(container: Container) {
    container.register(Logging.self) { [logging] _ in
      logging
    }
    container.register(AnalyticsController.self) { [analyticsController] _ in
      analyticsController
    }
    container.register(AddDocumentInteractor.self) { [addDocumentInteractor] _ in
      addDocumentInteractor
    }
  }
}
