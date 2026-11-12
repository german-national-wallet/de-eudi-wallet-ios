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

  func testHasUnreadableRegistration_WhenPolicyWasBuiltWithOnlyBenignViolation_ThenReturnsFalse() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .wrprcNotRepeated, message: "WRPRC not repeated in every ItemsRequest.requestInfo")],
      hasRegistrationPolicy: true
    )

    XCTAssertFalse(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenCertificateIsExpired_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .expired, message: "WRPRC is expired")],
      hasRegistrationPolicy: true
    )

    XCTAssertTrue(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenCertificateIsRevoked_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .statusRevoked, message: "WRPRC status: revoked")],
      hasRegistrationPolicy: true
    )

    XCTAssertTrue(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenNoCertificateWasSent_ThenReturnsFalse() {
    let sut = makeSUT(policyViolations: [], hasRegistrationPolicy: false)

    XCTAssertFalse(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenStatusListCouldNotBeRetrieved_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .statusRetrievalFailed, message: "WRPRC status list could not be retrieved")],
      hasRegistrationPolicy: true
    )

    XCTAssertTrue(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenNotBoundToAccessCertificate_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .notBoundToAccessCertificate, message: "WRPRC not bound to requester access certificate")],
      hasRegistrationPolicy: true
    )

    XCTAssertTrue(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenAccessCertificateIsUnavailable_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .accessCertificateUnavailable, message: "Requester access certificate not available to check WRPRC binding")],
      hasRegistrationPolicy: true
    )

    XCTAssertTrue(sut.hasUnreadableRegistration)
  }

  func testHasUnreadableRegistration_WhenOnlyOverAsking_ThenReturnsFalse() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .overAskedClaims(docType: "urn:eudi:pid:de:1", claims: nil), message: "not registered")],
      hasRegistrationPolicy: true
    )

    XCTAssertFalse(sut.hasUnreadableRegistration)
  }

  func testIsOverAsking_WhenClaimsAreOverAsked_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .overAskedClaims(docType: "urn:eudi:pid:de:1", claims: nil), message: "not registered")],
      hasRegistrationPolicy: true
    )

    XCTAssertTrue(sut.isOverAsking)
  }

  func testIsOverAsking_WhenServiceProviderEntitlementIsMissing_ThenReturnsTrue() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .entitlementMissing(expected: "https://uri.etsi.org/19475/Entitlement/Service_Provider"), message: "missing")],
      hasRegistrationPolicy: true
    )

    XCTAssertTrue(sut.isOverAsking)
  }

  func testIsOverAsking_WhenOnlyOtherViolations_ThenReturnsFalse() {
    let sut = makeSUT(
      policyViolations: [.init(reason: .wrprcNotRepeated, message: "WRPRC not repeated in every ItemsRequest.requestInfo")],
      hasRegistrationPolicy: true
    )

    XCTAssertFalse(sut.isOverAsking)
    XCTAssertFalse(sut.hasUnreadableRegistration)
  }

  func testLocalizedPurpose_WhenLanguageMatches_ThenReturnsThatLanguage() {
    let policy = makePolicy(purpose: [.init(lang: "en", value: "Age check"), .init(lang: "de", value: "Altersprüfung")])

    XCTAssertEqual(policy.localizedPurpose(languageCode: "de"), "Altersprüfung")
  }

  func testLocalizedPurpose_WhenLanguageDoesNotMatch_ThenFallsBackToFirst() {
    let policy = makePolicy(purpose: [.init(lang: "en", value: "Age check")])

    XCTAssertEqual(policy.localizedPurpose(languageCode: "fr"), "Age check")
  }

  func testLocalizedPurpose_WhenOnlyServiceDescription_ThenReturnsIt() {
    let policy = makePolicy(purpose: nil, srvDescriptions: [[.init(lang: "en", value: "Online shop")]])

    XCTAssertEqual(policy.localizedPurpose(languageCode: "en"), "Online shop")
  }

  func testLocalizedPurpose_WhenPurposeIsInAnotherLanguage_ThenStillPrefersItOverServiceDescription() {
    let policy = makePolicy(
      purpose: [.init(lang: "en", value: "Age check")],
      srvDescriptions: [[.init(lang: "de", value: "Onlineshop")]]
    )

    XCTAssertEqual(policy.localizedPurpose(languageCode: "de"), "Age check")
  }

  func testLocalizedPurpose_WhenNoneOrEmpty_ThenReturnsNil() {
    XCTAssertNil(makePolicy(purpose: nil).localizedPurpose(languageCode: "en"))
    XCTAssertNil(makePolicy(purpose: [.init(lang: "en", value: "")]).localizedPurpose(languageCode: "en"))
  }

  private func makePolicy(purpose: [PolicyPurpose]?, srvDescriptions: [[PolicyPurpose]]? = nil) -> WrpRegistrationPolicy {
    WrpRegistrationPolicy(sub: "verifier", credentials: [], purpose: purpose, srvDescriptions: srvDescriptions)
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
