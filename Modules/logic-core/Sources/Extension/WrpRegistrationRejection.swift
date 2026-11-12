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

  var containsUnverifiedRegistration: Bool {
    contains { $0.reason.leavesRegistrationUnverified }
  }

  var containsMissingEntitlement: Bool {
    contains { violation in
      if case .entitlementMissing = violation.reason { return true }
      return false
    }
  }
}

extension PresentationFailureReason {
  // Exhaustive on purpose: a reason added by wallet-kit must be classified here before the app builds.
  var leavesRegistrationUnverified: Bool {
    switch self {
    case .expired, .statusRevoked, .statusSuspended, .statusApplicationSpecific, .statusMissing,
         .statusRetrievalFailed, .statusTrustError, .trustError, .invalidType, .payloadDecodingFailed,
         .invalidCertificate, .wrpacDecodingFailed, .notBoundToAccessCertificate, .accessCertificateUnavailable,
         .wrprcMismatch, .wrprcMissing, .other:
      true
    case .overAskedClaims, .entitlementMissing, .wrprcNotRepeated:
      false
    }
  }
}

public extension PresentationSession {

  func makePresentationRequest() -> PresentationRequest {
    PresentationRequest(
      itemSets: disclosedDocumentSets.map(\.docElements),
      relyingParty: readerCertIssuer ?? LocalizableStringKey.unknownVerifier.toString,
      dataRequestInfo: readerCertValidationMessage ?? LocalizableStringKey.requestDataInfoNotice.toString,
      isTrusted: readerAuthenticationStatus == .authenticated,
      policyViolations: allPolicyViolations,
      supervisoryAuthorityURI: wrpVerifierPolicy?.supervisoryAuthority?.uri
        .flatMap { URL(string: $0) },
      hasRegistrationPolicy: wrpVerifierPolicy != nil,
      serviceProviderURL: wrpVerifierPolicy?.serviceProviderURL,
      purpose: wrpVerifierPolicy?.localizedPurpose(languageCode: Locale.preferredLanguages.first?.components(separatedBy: "-").first)
    )
  }

  var allPolicyViolations: [PresentationPolicyViolation] {
    let requestWide = wrpVerifierWarnings?.values.flatMap { $0 } ?? []
    let perOption = disclosedDocumentSets.compactMap(\.warnings).flatMap { $0 }
    var seen = Set<PresentationPolicyViolation>()
    return (requestWide + perOption).filter { seen.insert($0).inserted }
  }
}

public extension WrpRegistrationPolicy {
  var serviceProviderURL: URL? {
    [infoURI, supportURI]
      .compactMap { $0.flatMap(URL.init(string:)) }
      .first { $0.scheme?.lowercased() == "https" && !($0.host ?? "").isEmpty }
  }

  func localizedPurpose(languageCode: String?) -> String? {
    Self.localized(purpose, languageCode: languageCode) ?? Self.localized(srvDescription, languageCode: languageCode)
  }

  private static func localized(_ values: [PolicyPurpose]?, languageCode: String?) -> String? {
    let values = (values ?? []).filter { !$0.value.isEmpty }
    let match = languageCode.flatMap { code in
      values.first { $0.lang.lowercased().hasPrefix(code.lowercased()) }
    }
    return (match ?? values.first)?.value
  }
}
