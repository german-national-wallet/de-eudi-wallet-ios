//
//  TransactionEntry+ActivityDetail.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 10.10.26.
//

import Foundation
import logic_core
import logic_resources

extension TransactionEntry {

  func toDetail(
    totalClaimCounts: [String: Int] = [:],
    credentialNames names: [String: String] = [:],
    claimNames: [String: [String: String]] = [:],
    credentialDisplays: [String: [DisplayMetadata]] = [:],
    storedCredential: ActivityStoredCredential? = nil
  ) -> ActivityDetailUIModel {
    var rows: [ActivityDetailRowUIModel] = []
    switch self {
    case .presentation(let presentation):
      return ActivityDetailUIModel(
        title: listTitle(names),
        rows: [],
        presentation: presentationDetail(
          presentation,
          totalClaimCounts: totalClaimCounts,
          names: names,
          claimNames: claimNames,
          credentialDisplays: credentialDisplays
        )
      )
    case .credentialIssuance(let issuance) where transactionResult == .completed:
      return ActivityDetailUIModel(
        title: listTitle(names),
        rows: [],
        issuance: issuanceDetail(issuance, names: names, storedCredential: storedCredential)
      )
    case .credentialDeletion(let deletion) where transactionResult == .completed:
      return ActivityDetailUIModel(
        title: listTitle(names),
        rows: [],
        issuance: deletionDetail(deletion, names: names, storedCredential: storedCredential)
      )
    // Not completed: no credential was added or deleted, so no card, only the status
    case .credentialIssuance(let issuance):
      rows.append(.init(title: .activitiesLogDetailDate, value: Self.formatted(time)))
      rows.append(contentsOf: statusRows)
      rows.append(.init(title: .activitiesLogDetailCredential, value: displayTitle(names)))
      if let issuer = issuance.details.interactingPartyName?.content, !issuer.isEmpty {
        rows.append(.init(title: .activitiesLogDetailIssuer, value: issuer))
      }
    case .credentialDeletion(let deletion):
      rows.append(.init(title: .activitiesLogDetailDate, value: Self.formatted(time)))
      rows.append(contentsOf: statusRows)
      rows.append(.init(title: .activitiesLogDetailCredential, value: displayTitle(names)))
      if let issuer = deletion.credentialIssuerName?.content, !issuer.isEmpty {
        rows.append(.init(title: .activitiesLogDetailIssuer, value: issuer))
      }
    default:
      rows.append(.init(title: .activitiesLogDetailDate, value: Self.formatted(time)))
      rows.append(contentsOf: statusRows)
    }
    return ActivityDetailUIModel(title: listTitle(names), rows: rows)
  }

  private func presentationDetail(
    _ presentation: TransactionEntry.Presentation,
    totalClaimCounts: [String: Int],
    names: [String: String],
    claimNames: [String: [String: String]],
    credentialDisplays: [String: [DisplayMetadata]]
  ) -> ActivityPresentationDetailUIModel {
    let isShared = !presentation.listOfClaimsPresented.isEmpty
    let claims = isShared ? presentation.listOfClaimsPresented : presentation.listOfClaimsRequested
    let credentials = claims.map { info in
      let isPid = Self.isPid(info.credentialIdentifier)
      return ActivitySharedCredentialUIModel(
        id: info.credentialIdentifier,
        name: Self.credentialName(info.credentialIdentifier, names: names),
        issuerName: isPid ? LocalizableStringKey.dashboardCardIssuer.toString : nil,
        isPid: isPid,
        display: credentialDisplays[info.credentialIdentifier],
        isShared: isShared,
        sharedClaims: Self.readableClaims(info.claims, names: claimNames[info.credentialIdentifier] ?? [:]),
        totalClaimCount: totalClaimCounts[info.credentialIdentifier]
      )
    }
    let isCompleted = presentation.transactionResult == .completed

    return ActivityPresentationDetailUIModel(
      serviceName: displayTitle(names),
      dateLabel: isCompleted ? .activitiesDetailVerifiedOn : .activitiesDetailRejectedOn,
      date: Self.formatted(time),
      failureMessage: isCompleted ? nil : Self.failureMessage(presentation),
      purpose: presentation.purpose?.localized.flatMap { $0.isEmpty ? nil : $0 },
      isShared: isShared,
      credentials: credentials,
      services: Self.serviceLinks(
        contacts: presentation.interactingPartyContact ?? [],
        privacyPolicy: presentation.privacyPolicy?.first?.policyURI
      ),
      // Wallet-kit logs the supervisory authority's e-mail, phone and URI; only its page is opened
      reportLink: presentation.dpaContact?
        .first { $0.lowercased().hasPrefix("https://") }
        .map { ActivityServiceLinkUIModel(kind: .website, value: $0) }
    )
  }

  private static func failureMessage(_ presentation: TransactionEntry.Presentation) -> LocalizableStringKey {
    if presentation.reasonOfNoncompletion == "access_denied" {
      return .activitiesDetailFailureDeclined
    }
    return presentation.listOfClaimsPresented.isEmpty ? .activitiesDetailFailureGeneric : .activitiesDetailFailureServiceRejected
  }

  private func issuanceDetail(
    _ issuance: TransactionEntry.CredentialIssuance,
    names: [String: String],
    storedCredential: ActivityStoredCredential?
  ) -> ActivityIssuanceDetailUIModel {
    let isPid = isPidIssuance
    let issuer = isPid
    ? LocalizableStringKey.dashboardCardIssuer.toString
    : issuance.details.interactingPartyName?.content ?? storedCredential?.issuerName ?? ""
    return ActivityIssuanceDetailUIModel(
      kind: .added,
      title: listTitle(names),
      date: Self.formatted(time),
      card: credentialCard(isPid: isPid, issuer: issuer, names: names, storedCredential: storedCredential),
      issuerLinks: Self.issuerLinks(contacts: issuance.details.interactingPartyContact ?? [], storedCredential: storedCredential)
    )
  }

  private func deletionDetail(
    _ deletion: TransactionEntry.CredentialDeletion,
    names: [String: String],
    storedCredential: ActivityStoredCredential?
  ) -> ActivityIssuanceDetailUIModel {
    let isPid = Self.isPid(deletion.credentialIdentifier)
    let issuer = isPid
    ? LocalizableStringKey.dashboardCardIssuer.toString
    : deletion.credentialIssuerName?.content ?? storedCredential?.issuerName ?? ""
    return ActivityIssuanceDetailUIModel(
      kind: .deleted,
      title: listTitle(names),
      date: Self.formatted(time),
      card: credentialCard(isPid: isPid, issuer: issuer, names: names, storedCredential: storedCredential),
      issuerLinks: Self.issuerLinks(contacts: [], storedCredential: storedCredential)
    )
  }

  private func credentialCard(
    isPid: Bool,
    issuer: String,
    names: [String: String],
    storedCredential: ActivityStoredCredential?
  ) -> ActivityCredentialCardUIModel {
    ActivityCredentialCardUIModel(
      documentId: storedCredential?.documentId,
      title: displayTitle(names),
      issuer: issuer,
      isPid: isPid,
      display: storedCredential?.display,
      issuerLogoURL: storedCredential?.issuerLogoURL,
      claimNames: storedCredential?.claimNames ?? []
    )
  }

  private static func issuerLinks(
    contacts: [String],
    storedCredential: ActivityStoredCredential?
  ) -> [ActivityServiceLinkUIModel] {
    var links: [ActivityServiceLinkUIModel] = []
    if let policy = storedCredential?.privacyPolicy, !policy.isEmpty {
      links.append(.init(kind: .dataPolicy, value: policy))
    }
    let loggedWebsite = serviceLinks(contacts: contacts, privacyPolicy: nil).first { $0.kind == .website }?.value
    if let website = storedCredential?.infoURI.flatMap({ $0.isEmpty ? nil : $0 }) ?? loggedWebsite {
      links.append(.init(kind: .website, value: website))
    }
    return links
  }

  private static func serviceLinks(contacts: [String], privacyPolicy: String?) -> [ActivityServiceLinkUIModel] {
    let links = contacts.filter { $0.lowercased().hasPrefix("http") }
    let supportLink = links.count > 1 ? links.first : nil
    let websiteLink = links.count > 1 ? links[1] : links.first
    var services: [ActivityServiceLinkUIModel] = []
    if let support = supportLink
        ?? contacts.first(where: { $0.contains("@") })
        ?? contacts.first(where: ActivityServiceLinkUIModel.isPhoneNumber) {
      services.append(.init(kind: .support, value: support))
    }
    if let privacyPolicy, !privacyPolicy.isEmpty {
      services.append(.init(kind: .dataPolicy, value: privacyPolicy))
    }
    if let websiteLink {
      services.append(.init(kind: .website, value: websiteLink))
    }
    return services
  }

  private static func readableClaims(_ paths: [ClaimPath], names: [String: String]) -> [String] {
    var seen = Set<String>()
    return paths.compactMap { path -> String? in
      let keys = path.lookupKeys
      guard let primary = keys.first, seen.insert(primary).inserted else { return nil }
      return keys.lazy.compactMap { names[$0] }.first ?? path.lastClaimName
    }
  }

  private var statusRows: [ActivityDetailRowUIModel] {
    let completed = transactionResult == .completed
    return [
      .init(
        title: .activitiesLogDetailStatus,
        value: completed
        ? LocalizableStringKey.activitiesLogDetailCompleted.toString
        : LocalizableStringKey.activitiesLogStatusNotCompleted.toString
      )
    ]
  }

  private static func formatted(_ date: Date) -> String {
    ActivityDateFormatter.dateTime(date)
  }
}

private extension ClaimPath {
  var lookupKeys: [String] {
    let names = value.compactMap { element -> String? in
      if case .claim(let name) = element { return name }
      return nil
    }
    guard !names.isEmpty else { return [] }
    var keys = [names.joined(separator: ".")]
    if names.count > 1 { keys.append(names.dropFirst().joined(separator: ".")) }
    keys.append(names[names.count - 1])
    return keys.reduce(into: []) { if !$0.contains($1) { $0.append($1) } }
  }

  var lastClaimName: String? {
    value.reversed().compactMap { element -> String? in
      if case .claim(let name) = element { return name }
      return nil
    }.first
  }
}

private extension Array where Element == MultiLangString {
  var localized: String? {
    let language = ActivityDateFormatter.appLocale.language.languageCode?.identifier ?? ""
    let match = first { $0.lang.lowercased().hasPrefix(language) } ?? first
    return match?.content
  }
}
