//
//  PresentationRequestTests.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 29.09.26.
//

import XCTest
import EudiWalletKit
@testable import logic_core

final class PresentationRequestTests: XCTestCase {

  func testHasUnreadableRegistration_WhenCertificateProducedNoPolicy_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .other, message: "WRP policy could not be created: The data couldn’t be read")],
      hasRegistrationPolicy: false
    )

    XCTAssertTrue(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenPolicyWasBuilt_ThenReturnsFalse() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .expired, message: "WRPRC is expired")],
      hasRegistrationPolicy: true
    )

    XCTAssertFalse(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenNoCertificateWasSent_ThenReturnsFalse() {
    let sut = makeSUT(policyViolations: [], hasRegistrationPolicy: false)

    XCTAssertFalse(sut.hasUnreadableRegistration)
  }

  private func makeSUT(
    policyViolations: [PresentationPolicyViolation],
    hasRegistrationPolicy: Bool
  ) -> PresentationRequest {
    PresentationRequest(
      itemSets: [],
      relyingParty: "Relying Party",
      dataRequestInfo: "Data Request Info",
      isTrusted: true,
      policyViolations: policyViolations,
      supervisoryAuthorityURI: nil,
      hasRegistrationPolicy: hasRegistrationPolicy
    )
  }
}
