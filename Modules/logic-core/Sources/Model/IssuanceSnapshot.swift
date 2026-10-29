//
//  IssuanceSnapshot.swift
//  logic-core
//

import Foundation
import MdocDataModel18013
import EudiWalletKit

public struct IssuanceSnapshot: Codable, Equatable, Sendable {

  public struct Claim: Codable, Equatable, Sendable {
    public let path: [String]
    public let displayName: String?

    public init(path: [String], displayName: String?) {
      self.path = path
      self.displayName = displayName
    }
  }

  public struct Registration: Codable, Equatable, Sendable {
    public let privacyPolicy: String?
    public let supportURI: String?
    public let infoURI: String?

    public init(privacyPolicy: String?, supportURI: String?, infoURI: String?) {
      self.privacyPolicy = privacyPolicy
      self.supportURI = supportURI
      self.infoURI = infoURI
    }
  }

  public let transactionIdentifier: String
  public let time: Date
  public let credentialIdentifier: String
  public let display: [DisplayMetadata]?
  public let issuerDisplay: [DisplayMetadata]?
  public let claims: [Claim]
  public let registration: Registration?

  public init(
    transactionIdentifier: String,
    time: Date,
    credentialIdentifier: String,
    display: [DisplayMetadata]?,
    issuerDisplay: [DisplayMetadata]?,
    claims: [Claim],
    registration: Registration?
  ) {
    self.transactionIdentifier = transactionIdentifier
    self.time = time
    self.credentialIdentifier = credentialIdentifier
    self.display = display
    self.issuerDisplay = issuerDisplay
    self.claims = claims
    self.registration = registration
  }
}

public extension IssuanceSnapshot {

  static func transactionIdentifier(forDocumentId id: String) -> String {
    "\(issuancePrefix)\(id)"
  }

  static func documentId(fromTransactionIdentifier identifier: String) -> String? {
    guard identifier.hasPrefix(issuancePrefix) else { return nil }
    return String(identifier.dropFirst(issuancePrefix.count))
  }

  var documentId: String? {
    Self.documentId(fromTransactionIdentifier: transactionIdentifier)
  }

  private static let issuancePrefix = "issuance:"

  init(document: any DocClaimsDecodable, registration: WrpRegistrationPolicy?, time: Date = Date()) {
    self.init(
      transactionIdentifier: Self.transactionIdentifier(forDocumentId: document.id),
      time: time,
      credentialIdentifier: document.docType,
      display: document.display,
      issuerDisplay: document.issuerDisplay,
      claims: Self.flatten(document.docClaims, parent: []),
      registration: registration.map {
        Registration(privacyPolicy: $0.privacyPolicy, supportURI: $0.supportURI, infoURI: $0.infoURI)
      }
    )
  }

  private static func flatten(_ claims: [DocClaim], parent: [String]) -> [Claim] {
    claims.flatMap { claim -> [Claim] in
      let path = parent + [claim.name]
      let own = Claim(path: path, displayName: claim.displayName)
      return [own] + flatten(claim.children ?? [], parent: path)
    }
  }
}
