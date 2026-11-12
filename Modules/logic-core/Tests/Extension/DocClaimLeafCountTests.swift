//
//  DocClaimLeafCountTests.swift
//  logic-core-tests
//
//  Created by Ameen Qadri
//

import XCTest
import EudiWalletKit
@testable import logic_core

final class DocClaimLeafCountTests: XCTestCase {

  func testLeafCount_WhenClaimHasNoChildren_ThenReturnsOne() {
    XCTAssertEqual(makeClaim("family_name").leafCount, 1)
  }

  func testLeafCount_WhenClaimsAreNested_ThenCountsOnlyLeaves() {
    let claims = [
      makeClaim("family_name"),
      makeClaim("address", children: [
        makeClaim("street_address"),
        makeClaim("locality"),
        makeClaim("postal_code")
      ]),
      makeClaim("age_equal_or_over", children: [
        makeClaim("16"),
        makeClaim("18"),
        makeClaim("nested", children: [makeClaim("21"), makeClaim("65")])
      ])
    ]

    XCTAssertEqual(claims.count, 3)
    XCTAssertEqual(claims.leafCount, 8)
  }

  func testLeafCount_WhenChildrenAreEmpty_ThenReturnsZero() {
    XCTAssertEqual(makeClaim("nationalities", children: []).leafCount, 0)
  }

  private func makeClaim(_ name: String, children: [DocClaim]? = nil) -> DocClaim {
    DocClaim(
      name: name,
      displayName: name,
      dataValue: .string(name),
      stringValue: name,
      isOptional: false,
      order: 0,
      namespace: nil,
      children: children
    )
  }
}
