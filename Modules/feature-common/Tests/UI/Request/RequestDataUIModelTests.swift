//
//  RequestDataUIModelTests.swift
//  feature-common
//
//  Locks in the SD-JWT/mdoc request-claim parsing behavior flagged in PR review:
//  - requestedElementPath returns the full non-empty path for nested SD-JWT claims.
//  - requestedDocClaim populates children recursively for nested elements.
//

import XCTest
import logic_core
@testable import feature_common

final class RequestDataUIModelTests: XCTestCase {

  // MARK: - requestedElementPath (path mapping)

  func testRequestedElementPath_WhenSdJwtNestedClaim_ThenReturnsFullNonEmptyPath() {
    // A nested SD-JWT claim like address.locality must keep the whole path,
    // not collapse to just the leaf ["locality"].
    let path = requestedElementPath(type: .sdjwt, fullPath: ["address", "locality"])

    XCTAssertEqual(path, ["address", "locality"])
  }

  func testRequestedElementPath_WhenSdJwtPathHasEmptySegments_ThenDropsOnlyEmptySegments() {
    // Empty segments (array wildcards) are dropped; the remaining nested path is preserved.
    let path = requestedElementPath(type: .sdjwt, fullPath: ["", "address", "", "locality"])

    XCTAssertEqual(path, ["address", "locality"])
  }

  func testRequestedElementPath_WhenMdoc_ThenReturnsElementIdentifierOnly() {
    // For mdoc, path[0] is the namespace, so only the element identifier (path[1]) is sent.
    let path = requestedElementPath(type: .mdoc, fullPath: ["eu.europa.ec.eudi.pid.1", "family_name"])

    XCTAssertEqual(path, ["family_name"])
  }

  func testRequestedElementPath_WhenMdocPathHasSingleComponent_ThenReturnsEmpty() {
    XCTAssertEqual(requestedElementPath(type: .mdoc, fullPath: ["family_name"]), [])
  }

  func testRequestedElementPath_WhenTypeIsNil_ThenReturnsEmpty() {
    XCTAssertEqual(requestedElementPath(type: nil, fullPath: ["address", "locality"]), [])
  }

  // MARK: - requestedDocClaim (children recursion)

  func testRequestedDocClaim_WhenNestedElements_ThenPopulatesChildrenRecursively() {
    let localityClaim = DocClaim(
      name: "locality",
      path: ["address", "locality"],
      dataValue: .string("Berlin"),
      stringValue: "Berlin"
    )
    let localityElement = SdJwtElement(
      elementPath: ["address", "locality"],
      isOptional: false,
      stringValue: "Berlin",
      docClaim: localityClaim,
      isValid: true
    )

    let addressClaim = DocClaim(
      name: "address",
      path: ["address"],
      dataValue: .string(""),
      stringValue: ""
    )
    let addressElement = SdJwtElement(
      elementPath: ["address"],
      isOptional: false,
      stringValue: nil,
      docClaim: addressClaim,
      isValid: true,
      nestedElements: [localityElement]
    )

    let claim = addressElement.requestedDocClaim

    XCTAssertNotNil(claim)
    XCTAssertEqual(claim?.name, "address")
    XCTAssertEqual(claim?.children?.count, 1)
    XCTAssertEqual(claim?.children?.first?.name, "locality")
    XCTAssertEqual(claim?.children?.first?.path, ["address", "locality"])
  }

  func testRequestedDocClaim_WhenNoNestedElements_ThenHasNoChildren() {
    let claim = DocClaim(
      name: "given_name",
      path: ["given_name"],
      dataValue: .string("Erika"),
      stringValue: "Erika"
    )
    let element = SdJwtElement(
      elementPath: ["given_name"],
      isOptional: false,
      stringValue: "Erika",
      docClaim: claim,
      isValid: true
    )

    let result = element.requestedDocClaim

    XCTAssertNotNil(result)
    XCTAssertNil(result?.children)
  }

  func testRequestedDocClaim_WhenNoDocClaim_ThenReturnsNil() {
    let element = SdJwtElement(
      elementPath: ["address"],
      isOptional: false,
      stringValue: nil,
      docClaim: nil,
      isValid: true,
      nestedElements: []
    )

    XCTAssertNil(element.requestedDocClaim)
  }
}
