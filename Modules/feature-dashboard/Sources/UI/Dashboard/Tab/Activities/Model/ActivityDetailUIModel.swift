//
//  ActivityDetailUIModel.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 10.10.26.
//

import Foundation
import logic_core
import logic_resources

struct ActivityDetailUIModel: Equatable {
  let title: String
  let rows: [ActivityDetailRowUIModel]
  var presentation: ActivityPresentationDetailUIModel?
  var issuance: ActivityIssuanceDetailUIModel?
}

struct ActivityIssuanceDetailUIModel: Equatable {
  enum Kind: Equatable {
    case added
    case deleted
  }

  let kind: Kind
  let title: String
  let date: String
  let card: ActivityCredentialCardUIModel
  let issuerLinks: [ActivityServiceLinkUIModel]

  var dateLabel: LocalizableStringKey {
    kind == .added ? .activitiesDetailIssuedOn : .activitiesDetailDeletedOn
  }

  var cardLabel: LocalizableStringKey {
    switch (kind, card.isPid) {
    case (.added, true): .activitiesDetailIdCreated
    case (.added, false): .activitiesDetailCredentialCreated
    case (.deleted, true): .activitiesDetailIdDeleted
    case (.deleted, false): .activitiesDetailCredentialDeleted
    }
  }
}

struct ActivityCredentialCardUIModel: Equatable {
  let documentId: String?
  let title: String
  let issuer: String
  let isPid: Bool
  let display: [DisplayMetadata]?
  let issuerLogoURL: String?
  // Names only, never claim values
  let claimNames: [String]
}

struct ActivityStoredCredential: Equatable {
  let documentId: String?
  let issuerName: String
  let issuerLogoURL: String?
  let display: [DisplayMetadata]?
  let claimNames: [String]
  let privacyPolicy: String?
  let supportURI: String?
  let infoURI: String?
}

struct ActivityDetailRowUIModel: Identifiable, Equatable {
  let title: LocalizableStringKey
  let value: String

  var id: String { title.toString }
}

struct ActivityPresentationDetailUIModel: Equatable {
  let serviceName: String
  let dateLabel: LocalizableStringKey
  let date: String
  let failureMessage: LocalizableStringKey?
  let purpose: String?
  let isShared: Bool
  let credentials: [ActivitySharedCredentialUIModel]
  let services: [ActivityServiceLinkUIModel]
  let reportLink: ActivityServiceLinkUIModel?

  var credentialsLabel: LocalizableStringKey {
    isShared ? .activitiesDetailCredentialAndDataShared : .activitiesDetailNoDataShared
  }
}

struct ActivitySharedCredentialUIModel: Identifiable, Equatable {
  let id: String
  let name: String
  /// Only known for the PID.
  let issuerName: String?
  let isPid: Bool
  let display: [DisplayMetadata]?
  let isShared: Bool
  let sharedClaims: [String]
  let totalClaimCount: Int?

  var valuesSummary: LocalizableStringKey {
    let shared = "\(sharedClaims.count)"
    guard let totalClaimCount else { return .activitiesDetailValues([shared]) }
    return .activitiesDetailValuesOf([shared, "\(totalClaimCount)"])
  }
}

struct ActivityServiceLinkUIModel: Identifiable, Equatable {
  enum Kind: Equatable {
    case support
    case dataPolicy
    case website
  }

  let kind: Kind
  let value: String

  var id: Kind { kind }

  var url: URL? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.lowercased().hasPrefix("https://") {
      return URL(string: trimmed).flatMap { $0.host?.isEmpty == false ? $0 : nil }
    }
    if trimmed.contains("@"), !trimmed.contains(where: { $0.isWhitespace || $0 == "/" || $0 == ":" }) {
      return URL(string: "mailto:\(trimmed)")
    }
    if Self.isPhoneNumber(trimmed) {
      return URL(string: "tel:\(trimmed.filter { $0.isNumber || $0 == "+" })")
    }
    return nil
  }

  static func isPhoneNumber(_ value: String) -> Bool {
    value.filter(\.isNumber).count >= 6 && value.allSatisfy { $0.isNumber || "+ -()".contains($0) }
  }

  var title: LocalizableStringKey {
    switch kind {
    case .support: .activitiesDetailSupport
    case .dataPolicy: .activitiesDetailDataPolicy
    case .website: .activitiesDetailWebsite
    }
  }
}

extension Array where Element == DisplayMetadata {
  var localizedName: String? {
    let language = ActivityDateFormatter.appLocale.language.languageCode?.identifier ?? ""
    let match = first { ($0.localeIdentifier ?? "").lowercased().hasPrefix(language) && $0.name?.isEmpty == false }
    return (match ?? first { $0.name?.isEmpty == false })?.name
  }
}
