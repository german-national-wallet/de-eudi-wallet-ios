//
//  TestPersonalDetailViewModel.swift
//  feature-dashboard
//
//  Created by Ameen Qadri on 30.03.26.
//

import XCTest
import Cuckoo
import logic_core
import logic_ui
@testable import feature_dashboard
@testable import feature_test

@MainActor
final class TestPersonalDetailViewModel: XCTestCase {

  private var mockInteractor: MockDashboardInteractor!
  private var mockRouter: MockRouterHost!

  override func setUp() {
    super.setUp()
    mockInteractor = MockDashboardInteractor()
    mockRouter = MockRouterHost()
  }

  override func tearDown() {
    mockInteractor = nil
    mockRouter = nil
    super.tearDown()
  }

  func testInit_WhenDocumentHasClaims_ThenCreatesCredentialDetailItems() {
    let document = Constants.euPidModel

    let viewModel = PersonalDetailViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      document: document
    )

    XCTAssertEqual(viewModel.credentialDetailItems.count, document.docClaims.count)
  }

  func testInit_WhenClaimsDoNotProvideDisplayName_ThenUsesClaimNameAsTitle() {
    let document = Constants.euPidModel

    let viewModel = PersonalDetailViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      document: document
    )

    let expectedTitles = Set(document.docClaims.map(\.name))
    let actualTitles = Set(viewModel.credentialDetailItems.map(\.title))

    XCTAssertEqual(actualTitles, expectedTitles)
  }

  func testInit_WhenClaimsHaveStringValues_ThenUsesClaimStringValueAsDetail() {
    let document = Constants.euPidModel

    let viewModel = PersonalDetailViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      document: document
    )

    let expectedDetails = Set(document.docClaims.map(\.stringValue))
    let actualDetails = Set(viewModel.credentialDetailItems.map(\.detail))

    XCTAssertEqual(actualDetails, expectedDetails)
  }

  func testConfigureClaimDisplay_WhenCredentialItemsAreCleared_ThenRepopulatesItems() {
    let document = Constants.euPidModel

    let viewModel = PersonalDetailViewModel(
      router: mockRouter,
      interactor: mockInteractor,
      document: document
    )
    viewModel.credentialDetailItems = []

    viewModel.configureClaimDisplay()

    XCTAssertEqual(viewModel.credentialDetailItems.count, document.docClaims.count)
  }
}
