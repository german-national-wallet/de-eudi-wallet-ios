//
//  ActivitiesInteractor.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import logic_core
import logic_business

enum ActivitiesPartialState: Sendable {
  case success([ActivitySectionUIModel])
  case failure(Error)
}

enum ActivityDetailPartialState: Sendable {
  case success(ActivityDetailUIModel)
  case failure(Error)
}

protocol ActivitiesInteractor: Sendable {
  func fetchActivities() async -> ActivitiesPartialState
  func fetchActivity(with id: String) async -> ActivityDetailPartialState
  func deleteActivity(with id: String) async throws
  func deleteAllActivities() async throws
}

final class ActivitiesInteractorImpl: ActivitiesInteractor {

  private let transactionLogController: TransactionLogController
  private let walletKitController: WalletKitController
  private let logger: Logging?

  init(transactionLogController: TransactionLogController, walletKitController: WalletKitController, logger: Logging? = nil) {
    self.transactionLogController = transactionLogController
    self.walletKitController = walletKitController
    self.logger = logger
  }

  func fetchActivities() async -> ActivitiesPartialState {
    do {
      let now = Date()
      let snapshots = await loadSnapshots()
      let names = credentialNames(snapshots)
      let items = try await transactionLogController.fetchTransactionLogs()
        .preparedForActivityLog()
        .map { $0.toListItem(now: now, logo: listLogo(for: $0, snapshots: snapshots), credentialNames: names) }
      let grouped = Dictionary(grouping: items) { ActivityCategory(date: $0.time, now: now) }
      let sections = grouped.keys.sorted().compactMap { category -> ActivitySectionUIModel? in
        guard let items = grouped[category], !items.isEmpty else { return nil }
        return ActivitySectionUIModel(category: category, items: items.sorted { $0.time > $1.time })
      }
      return .success(sections)
    } catch {
      return .failure(error)
    }
  }

  func deleteActivity(with id: String) async throws {
    let groups = try await transactionLogController.fetchTransactionLogs().activityLogGroups()
    let identifiers = groups.first { $0.first?.transactionIdentifier == id }?.map(\.transactionIdentifier) ?? [id]
    try await transactionLogController.deleteTransactionLogs(with: identifiers)
  }

  func deleteAllActivities() async throws {
    try await transactionLogController.deleteAllTransactionLogs()
  }

  func fetchActivity(with id: String) async -> ActivityDetailPartialState {
    do {
      let entry = try await transactionLogController.fetchTransactionLog(with: id)
      let snapshots = await loadSnapshots()
      return .success(
        entry.toDetail(
          totalClaimCounts: totalClaimCounts(for: entry, snapshots: snapshots),
          credentialNames: credentialNames(snapshots),
          claimNames: claimNames(for: entry, snapshots: snapshots),
          credentialDisplays: credentialDisplays(for: entry, snapshots: snapshots),
          storedCredential: storedCredential(for: entry, snapshots: snapshots)
        )
      )
    } catch {
      return .failure(error)
    }
  }

  private func listLogo(for entry: TransactionEntry, snapshots: ActivitySnapshots) -> ActivityListLogo? {
    let snapshot = snapshots.byTransaction[entry.transactionIdentifier]
    let document = snapshot == nil ? issuedDocument(for: entry) : nil
    let display = snapshot?.display ?? document?.display
    if let url = display?.first?.logo?.uri {
      return ActivityListLogo(url: url, backgroundHex: display?.first?.backgroundColor)
    }
    let issuerLogo = snapshot?.issuerDisplay?.first?.logo?.uri ?? document?.issuerLogo
    return issuerLogo.map { ActivityListLogo(url: $0, backgroundHex: nil) }
  }

  // Background refreshes replace the document an issuance entry points to, so fall back to the same type.
  private func issuedDocument(for entry: TransactionEntry) -> (any DocClaimsDecodable)? {
    guard case .credentialIssuance(let issuance) = entry else { return nil }
    if let id = entry.issuedDocumentId, let document = walletKitController.fetchDocument(with: id) {
      return document
    }
    let types = Set(issuance.details.credentialIdentifier)
    return walletKitController.fetchIssuedDocuments().first { types.contains($0.docType) }
  }

  private func storedCredential(for entry: TransactionEntry, snapshots: ActivitySnapshots) -> ActivityStoredCredential? {
    if case .credentialDeletion(let deletion) = entry {
      return snapshots.latestByCredential[deletion.credentialIdentifier].map(ActivityStoredCredential.init(snapshot:))
    }
    if let snapshot = snapshots.byTransaction[entry.transactionIdentifier] {
      return ActivityStoredCredential(snapshot: snapshot)
    }
    // Entries logged before snapshots were saved
    return issuedDocument(for: entry).map { document in
      ActivityStoredCredential(
        documentId: document.id,
        issuerName: document.issuerName,
        issuerLogoURL: document.issuerLogo?.absoluteString,
        display: document.display,
        claimNames: document.docClaims.map { claim in claim.displayName.ifNilOrEmpty { claim.name } },
        privacyPolicy: nil,
        supportURI: nil,
        infoURI: nil
      )
    }
  }

  // The activity log still works from the stored credentials without snapshots.
  private func loadSnapshots() async -> ActivitySnapshots {
    do {
      return ActivitySnapshots(try await transactionLogController.fetchIssuanceSnapshots())
    } catch {
      logger?.e("Activities: reading the issuance snapshots failed: \(error.localizedDescription)")
      return ActivitySnapshots([])
    }
  }

  private func credentialDisplays(for entry: TransactionEntry, snapshots: ActivitySnapshots) -> [String: [DisplayMetadata]] {
    guard case .presentation(let presentation) = entry else { return [:] }
    let identifiers = involvedCredentials(presentation)
    var displays: [String: [DisplayMetadata]] = [:]
    for identifier in identifiers {
      displays[identifier] = snapshots.latestByCredential[identifier]?.display
    }
    for document in walletKitController.fetchIssuedDocuments() where identifiers.contains(document.docType) {
      if let display = document.display { displays[document.docType] = display }
    }
    return displays
  }

  private func involvedCredentials(_ presentation: TransactionEntry.Presentation) -> Set<String> {
    Set((presentation.listOfClaimsPresented + presentation.listOfClaimsRequested).map(\.credentialIdentifier))
  }

  private func totalClaimCounts(for entry: TransactionEntry, snapshots: ActivitySnapshots) -> [String: Int] {
    guard case .presentation(let presentation) = entry else { return [:] }
    let identifiers = involvedCredentials(presentation)
    guard !identifiers.isEmpty else { return [:] }
    var counts: [String: Int] = [:]
    for identifier in identifiers {
      if let snapshot = snapshots.latestByCredential[identifier] {
        counts[identifier] = snapshot.claims.filter { $0.path.count == 1 }.count
      }
    }
    for document in walletKitController.fetchIssuedDocuments() where identifiers.contains(document.docType) {
      counts[document.docType] = document.docClaims.count
    }
    return counts
  }

  private func credentialNames(_ snapshots: ActivitySnapshots) -> [String: String] {
    var names = snapshots.latestByCredential.compactMapValues { $0.display?.localizedName }
    for document in walletKitController.fetchIssuedDocuments() {
      if let name = document.displayName, !name.isEmpty { names[document.docType] = name }
    }
    return names
  }

  private func claimNames(for entry: TransactionEntry, snapshots: ActivitySnapshots) -> [String: [String: String]] {
    guard case .presentation(let presentation) = entry else { return [:] }
    let identifiers = involvedCredentials(presentation)
    var result: [String: [String: String]] = [:]
    for identifier in identifiers {
      if let snapshot = snapshots.latestByCredential[identifier] {
        result[identifier] = snapshot.claimTitlesByPath
      }
    }
    for document in walletKitController.fetchIssuedDocuments() where identifiers.contains(document.docType) {
      var names: [String: String] = [:]
      collectClaimNames(document.docClaims, parentNames: [], parentTitles: [], into: &names)
      result[document.docType] = names
    }
    return result
  }

  private func collectClaimNames(
    _ claims: [DocClaim],
    parentNames: [String],
    parentTitles: [String],
    into names: inout [String: String]
  ) {
    for claim in claims {
      let path = parentNames + [claim.name]
      let titles = parentTitles + [claim.displayName.ifNilOrEmpty { claim.name }]
      let title = titles.joined(separator: " · ")
      names[path.joined(separator: ".")] = title
      if let namespace = claim.namespace, !namespace.isEmpty, parentNames.isEmpty {
        names["\(namespace).\(claim.name)"] = title
      }
      if let children = claim.children {
        collectClaimNames(children, parentNames: path, parentTitles: titles, into: &names)
      }
    }
  }
}

struct ActivitySnapshots {
  let byTransaction: [String: IssuanceSnapshot]
  let latestByCredential: [String: IssuanceSnapshot]

  // Expects the snapshots newest first, as the controller returns them.
  init(_ snapshots: [IssuanceSnapshot]) {
    byTransaction = Dictionary(snapshots.map { ($0.transactionIdentifier, $0) }) { first, _ in first }
    latestByCredential = Dictionary(snapshots.map { ($0.credentialIdentifier, $0) }) { first, _ in first }
  }
}

extension ActivityStoredCredential {
  init(snapshot: IssuanceSnapshot) {
    self.init(
      documentId: snapshot.documentId,
      issuerName: snapshot.issuerDisplay?.localizedName ?? "",
      issuerLogoURL: snapshot.issuerDisplay?.first?.logo?.urlString,
      display: snapshot.display,
      claimNames: snapshot.claims.filter { $0.path.count == 1 }.map { claim in
        claim.displayName.ifNilOrEmpty { claim.path.last ?? "" }
      },
      privacyPolicy: snapshot.registration?.privacyPolicy,
      supportURI: snapshot.registration?.supportURI,
      infoURI: snapshot.registration?.infoURI
    )
  }
}

extension IssuanceSnapshot {
  var claimTitlesByPath: [String: String] {
    let ownTitles = Dictionary(claims.map { ($0.path.joined(separator: "."), $0) }) { first, _ in first }
    var titles: [String: String] = [:]
    for claim in claims {
      let parts = claim.path.indices.map { index -> String in
        let prefix = claim.path[...index]
        return ownTitles[prefix.joined(separator: ".")]?.displayName.ifNilOrEmpty { prefix.last ?? "" }
          ?? (prefix.last ?? "")
      }
      titles[claim.path.joined(separator: ".")] = parts.joined(separator: " · ")
    }
    return titles
  }
}
