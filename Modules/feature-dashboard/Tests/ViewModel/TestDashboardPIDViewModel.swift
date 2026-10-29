//
//  TestDashboardPIDViewModel.swift
//  feature-dashboard
//
//  Created by Muhammad Qadri on 02.02.26.
//

import XCTest
import Cuckoo
import logic_core
import logic_analytics
@testable import logic_ui
@testable import feature_dashboard
@testable import feature_test

@MainActor
final class TestDashboardPIDViewModel: XCTestCase {

  private var mockInteractor: MockDashboardInteractor!
  private var mockRouter: MockRouterHost!
  private var mockAnalyticsController: MockAnalyticsController!

  override func setUp() {
    super.setUp()
    mockInteractor = MockDashboardInteractor()
    mockRouter = MockRouterHost()
    mockAnalyticsController = MockAnalyticsController()
  }

  override func tearDown() {
    mockInteractor = nil
    mockRouter = nil
    mockAnalyticsController = nil
    super.tearDown()
  }

  // MARK: - getMainPIDDocument / init

  func testInit_WhenInteractorReturnsPIDDocument_ThenSetsFullNameAndPidDocument() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(Constants.euPidModel)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    XCTAssertEqual(viewModel.fullName, "John Doe")
    XCTAssertEqual(viewModel.pidDocument?.id, Constants.euPidModelId)
  }

  func testInit_WhenInteractorThrows_ThenFullNameRemainsEmpty() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenThrow(NSError(domain: "test", code: -1, userInfo: nil))
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    XCTAssertEqual(viewModel.fullName, "")
    XCTAssertNil(viewModel.pidDocument)
  }

  func testInit_WhenInteractorReturnsNil_ThenFullNameRemainsEmpty() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    XCTAssertEqual(viewModel.fullName, "")
    XCTAssertNil(viewModel.pidDocument)
  }

  // MARK: - getAdditionalDocuments

  func testGetAdditionalDocuments_WhenInteractorReturnsDocuments_ThenSetsAdditionalDocuments() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
      when(mock.getAdditionalDocuments()).thenReturn([Constants.euPidModel])
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.getAdditionalDocuments()

    XCTAssertEqual(viewModel.additionalDocuments?.count, 1)
    XCTAssertEqual(viewModel.additionalDocuments?.first?.id, Constants.euPidModelId)
  }

  func testGetAdditionalDocuments_WhenInteractorThrows_ThenAdditionalDocumentsRemainNil() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
      when(mock.getAdditionalDocuments()).thenThrow(NSError(domain: "test", code: -1, userInfo: nil))
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.getAdditionalDocuments()

    XCTAssertNil(viewModel.additionalDocuments)
  }

  // MARK: - showAdditionalDocuments

  func testShowAdditionalDocuments_WhenAdditionalDocumentsIsNil_ThenReturnsFalse() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.additionalDocuments = nil

    XCTAssertFalse(viewModel.showAdditionalDocuments)
  }

  func testShowAdditionalDocuments_WhenAdditionalDocumentsIsEmpty_ThenReturnsFalse() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.additionalDocuments = []

    XCTAssertFalse(viewModel.showAdditionalDocuments)
  }

  func testShowAdditionalDocuments_WhenAdditionalDocumentsExistAndPidMissing_ThenReturnsTrue() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.additionalDocuments = [Constants.euPidModel]

    XCTAssertTrue(viewModel.showAdditionalDocuments)
  }

  func testShowAdditionalDocuments_WhenAdditionalDocumentsExistAndPidAvailable_ThenReturnsTrue() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(Constants.euPidModel)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.additionalDocuments = [Constants.euPidModel]

    XCTAssertTrue(viewModel.showAdditionalDocuments)
  }

  // MARK: - onAdditionalDocumentTap

  
  func testOnCardTap_WhenPidDocumentIsNil_ThenDoesNotPushRoute() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.onTap()

    verify(mockRouter, times(0)).push(with: any())
  }

  func testGetMainPIDDocument_WhenPidWasPreviouslySetAndNowNil_ThenResetsPidDetails() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(Constants.euPidModel)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    XCTAssertNotNil(viewModel.pidDocument)
    XCTAssertFalse(viewModel.fullName.isEmpty)

    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
    }

    viewModel.getMainPIDDocument()

    XCTAssertNil(viewModel.pidDocument)
    XCTAssertEqual(viewModel.fullName, "")
    XCTAssertEqual(viewModel.pidName, "")
  }

  func testGetMainPIDDocument_WhenPidWasPreviouslySetAndInteractorThrows_ThenResetsPidDetails() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(Constants.euPidModel)
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    XCTAssertNotNil(viewModel.pidDocument)
    XCTAssertFalse(viewModel.fullName.isEmpty)

    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenThrow(NSError(domain: "test", code: -1, userInfo: nil))
    }

    viewModel.getMainPIDDocument()

    XCTAssertNil(viewModel.pidDocument)
    XCTAssertEqual(viewModel.fullName, "")
    XCTAssertEqual(viewModel.pidName, "")
  }

  func testPerformIssuance_WhenCalled_ThenStartsIssuanceTraceAndPushesOnboarding() {
    stub(mockInteractor) { mock in
      when(mock.getPIDDocument()).thenReturn(nil)
    }
    stub(mockAnalyticsController) { mock in
      when(mock.startTrace(name: any(), initialAttributes: any())).thenDoNothing()
    }
    stub(mockRouter) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    let viewModel = DashboardCredentialViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      logger: nil,
      analyticsController: mockAnalyticsController
    )

    viewModel.performIssuance()

    verify(mockAnalyticsController).startTrace(
      name: equal(to: AnalyticsConstants.TraceName.issuance),
      initialAttributes: any()
    )
    verify(mockRouter).push(with: equal(to: .featureIssuanceModule(.issuanceOnboardingCardView)))
  }
}
