//
//  TransactionEntry+ActivityList.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 10.10.26.
//

import Foundation
import logic_core
import logic_resources

extension TransactionEntry {

  var isShownInActivityLog: Bool {
    switch self {
    case .presentation, .credentialIssuance, .credentialDeletion: true
    default: false
    }
  }

  var isUntypedIssuance: Bool {
    guard case .credentialIssuance(let issuance) = self else { return false }
    return issuance.details.credentialIdentifier.allSatisfy(\.isEmpty)
  }

  var isPidIssuance: Bool {
    guard case .credentialIssuance(let issuance) = self else { return false }
    let identifiers = issuance.details.credentialIdentifier
    return !identifiers.isEmpty && identifiers.allSatisfy(Self.isPid)
  }

  func toListItem(
    now: Date = Date(),
    calendar: Calendar = .current,
    logo: ActivityListLogo? = nil,
    credentialNames: [String: String] = [:]
  ) -> ActivityListItemUIModel {
    let isCompleted = transactionResult == .completed
    let subtitleParts = [listSubtitleSource(credentialNames), Self.listTime(time, now: now, calendar: calendar)]
      + (isCompleted ? [] : [LocalizableStringKey.activitiesLogStatusNotCompleted.toString])
    return ActivityListItemUIModel(
      id: transactionIdentifier,
      leading: listLeading(logo: logo, credentialNames: credentialNames),
      title: listTitle(credentialNames),
      subtitle: subtitleParts.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "),
      time: time,
      isCompleted: isCompleted
    )
  }

  private func listSubtitleSource(_ names: [String: String]) -> String? {
    switch self {
    case .presentation(let presentation):
      let shared = presentation.listOfClaimsPresented.isEmpty
      ? presentation.listOfClaimsRequested
      : presentation.listOfClaimsPresented
      let credentials = Set(shared.map(\.credentialIdentifier).map { Self.credentialName($0, names: names) })
      if credentials.count > 1 { return LocalizableStringKey.activitiesLogMultipleCredentials.toString }
      return credentials.first
    case .credentialIssuance(let issuance):
      return issuance.details.interactingPartyName?.content
    case .credentialDeletion(let deletion):
      return deletion.credentialIssuerName?.content
    default:
      return nil
    }
  }

  private func listLeading(logo: ActivityListLogo?, credentialNames names: [String: String]) -> ActivityLeadingUIModel {
    switch self {
    case .credentialIssuance(let issuance) where issuance.details.credentialIdentifier.contains(where: Self.isPid):
      return .pidLogo
    case .credentialDeletion(let deletion) where Self.isPid(deletion.credentialIdentifier):
      return .pidLogo
    case .credentialIssuance(let issuance):
      let initials = Self.initials(of: issuance.details.interactingPartyName?.content ?? displayTitle(names))
      return logo.map { .logo($0, initials: initials) } ?? .initials(initials)
    default:
      return .initials(Self.initials(of: displayTitle(names)))
    }
  }

  var issuedDocumentId: String? {
    guard case .credentialIssuance = self else { return nil }
    return IssuanceSnapshot.documentId(fromTransactionIdentifier: transactionIdentifier)
  }

  private static func listTime(_ date: Date, now: Date, calendar: Calendar) -> String {
    guard calendar.isDate(date, inSameDayAs: now) else {
      return ActivityDateFormatter.date(date)
    }
    return ActivityDateFormatter.time(date)
  }

  private static func initials(of name: String) -> String {
    String(name.filter(\.isLetter).prefix(2)).uppercased()
  }
}

extension Array where Element == TransactionEntry {

  func preparedForActivityLog(pidMergeWindow: TimeInterval = 60) -> [TransactionEntry] {
    activityLogGroups(pidMergeWindow: pidMergeWindow).map { group in
      group.dropFirst().reduce(group[0]) { merged, next in
        guard case .credentialIssuance(let first) = merged, case .credentialIssuance(let other) = next else { return merged }
        return .credentialIssuance(first.merged(with: other))
      }
    }
  }

  func activityLogGroups(pidMergeWindow: TimeInterval = 60) -> [[TransactionEntry]] {
    let visible = filter { $0.isShownInActivityLog && !$0.isUntypedIssuance }.sorted { $0.time < $1.time }
    var groups: [[TransactionEntry]] = []
    for entry in visible {
      if case .credentialIssuance(let current) = entry, entry.isPidIssuance,
         let first = groups.last?.first, first.isPidIssuance, case .credentialIssuance(let previous) = first,
         previous.details.interactingPartyName == current.details.interactingPartyName,
         current.time.timeIntervalSince(previous.time) <= pidMergeWindow {
        groups[groups.count - 1].append(entry)
      } else {
        groups.append([entry])
      }
    }
    return groups
  }
}

private extension TransactionEntry.CredentialIssuance {
  func merged(with other: Self) -> Self {
    let completed = transactionResult == .completed && other.transactionResult == .completed
    return .init(
      transactionIdentifier: transactionIdentifier,
      time: time,
      transactionResult: completed ? .completed : .notCompleted,
      reasonOfNoncompletion: reasonOfNoncompletion ?? other.reasonOfNoncompletion,
      details: .init(
        credentialNumberRequested: details.credentialNumberRequested + other.details.credentialNumberRequested,
        credentialNumberIssued: details.credentialNumberIssued + other.details.credentialNumberIssued,
        credentialIdentifier: details.credentialIdentifier + other.details.credentialIdentifier,
        isUserTriggered: details.isUserTriggered,
        interactingPartyName: details.interactingPartyName,
        interactingPartyIdentifier: details.interactingPartyIdentifier,
        interactingPartyType: details.interactingPartyType,
        interactingPartyContact: details.interactingPartyContact
      )
    )
  }
}
