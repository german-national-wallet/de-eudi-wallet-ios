//
//  AppEnvironmentTests.swift
//  logic-core
//
//  Created by Ameen Qadri on 02.11.26.
//

import XCTest
@testable import logic_core

final class AppEnvironmentTests: XCTestCase {

  func testCredentialCatalogueLink_ThenPointsToEudiHubWithoutNavigation() throws {
    let url = try XCTUnwrap(AppEnvironment.credentialCatalogueLink)
    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

    XCTAssertEqual(components.scheme, "https")
    XCTAssertEqual(components.host, "eudi-hub.gov.de")
    XCTAssertEqual(components.queryItems, [URLQueryItem(name: "showNavigation", value: "false")])
  }

  func testCredentialCatalogueLink_ThenMatchesDeviceLanguage() throws {
    let url = try XCTUnwrap(AppEnvironment.credentialCatalogueLink)
    let expectedPath = Locale.current.language.languageCode?.identifier == "de"
      ? "/de/credentials/nachweisuebersicht"
      : "/en/credentials/credential-overview"

    XCTAssertEqual(url.path, expectedPath)
  }
}
