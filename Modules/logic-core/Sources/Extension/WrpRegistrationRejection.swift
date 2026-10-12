//
//  WrpRegistrationRejection.swift
//  logic-core
//
import Foundation
import EudiWalletKit
import logic_resources

public enum WrpRegistrationRejection: Sendable, Equatable {
  case certificateMissing
  case certificateNotTrusted
}

public extension Collection<PresentationPolicyViolation> {
  var overAskedClaimViolations: [PresentationPolicyViolation] {
    filter { violation in
      if case .overAskedClaims = violation.reason { return true }
      return false
    }
  }

  var containsOverAskedClaims: Bool {
    !overAskedClaimViolations.isEmpty
  }
}

public extension PresentationSession {

  func makePresentationRequest() -> PresentationRequest {
    PresentationRequest(
      itemSets: disclosedDocumentSets.map(\.docElements),
      relyingParty: readerCertIssuer ?? LocalizableStringKey.unknownVerifier.toString,
      dataRequestInfo: readerCertValidationMessage ?? LocalizableStringKey.requestDataInfoNotice.toString,
      isTrusted: readerCertIssuerValid == true,
      policyViolations: allPolicyViolations,
      supervisoryAuthorityURI: wrpVerifierPolicy?.supervisoryAuthority?.uri
        .flatMap { URL(string: $0) },
      hasRegistrationPolicy: wrpVerifierPolicy != nil
    )
  }

  var allPolicyViolations: [PresentationPolicyViolation] {
    let requestWide = wrpVerifierWarnings?.values.flatMap { $0 } ?? []
    let perOption = disclosedDocumentSets.compactMap(\.warnings).flatMap { $0 }
    var seen = Set<PresentationPolicyViolation>()
    return (requestWide + perOption).filter { seen.insert($0).inserted }
  }
}
