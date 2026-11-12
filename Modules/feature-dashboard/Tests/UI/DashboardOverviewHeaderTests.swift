//
//  DashboardOverviewHeaderTests.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 04.11.26.
//

import XCTest
import SwiftUI
@testable import feature_dashboard

@MainActor
final class DashboardOverviewHeaderTests: XCTestCase {

  func testHeader_WhenRendered_ThenHasTheDesignHeightAndFitsTheScreenWidth() {
    let size = render(DashboardOverviewHeader())

    XCTAssertEqual(size.height, 48)
    XCTAssertLessThanOrEqual(size.width, 375)
  }

  func testHeader_WhenTextIsLarge_ThenKeepsTheDesignHeight() {
    let size = render(DashboardOverviewHeader().environment(\.dynamicTypeSize, .accessibility5))

    XCTAssertEqual(size.height, 48)
  }

  func testOnHelp_WhenNotProvided_ThenDoesNothing() {
    DashboardOverviewHeader().onHelp()
  }

  func testOnHelp_WhenProvided_ThenCallsIt() {
    var helpTapped = false
    let header = DashboardOverviewHeader(onHelp: { helpTapped = true })

    header.onHelp()

    XCTAssertTrue(helpTapped)
  }

  private func render(_ view: some View) -> CGSize {
    let controller = UIHostingController(rootView: view)
    controller.safeAreaRegions = []
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.view.layoutIfNeeded()
    return controller.sizeThatFits(in: CGSize(width: 375, height: 667))
  }
}
