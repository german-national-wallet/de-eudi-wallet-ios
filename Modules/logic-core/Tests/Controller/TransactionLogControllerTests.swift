//
//  TransactionLogControllerTests.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import Testing
import logic_storage

@testable import logic_core

struct TransactionLogControllerTests {

  @Test
  func log_WhenEntryIsLogged_ThenItIsReadBackUnchanged() async throws {
    let storage = InMemoryTransactionLogStorage()
    let sut = TransactionLogControllerImpl(storageController: storage)
    let entry = makePresentation(id: "presentation-1", result: .completed)

    try await sut.log(transaction: entry)

    let logs = try await sut.fetchTransactionLogs()
    #expect(logs == [entry])
    #expect(try await sut.fetchTransactionLog(with: "presentation-1") == entry)
  }

  @Test
  func log_WhenSameTransactionIsLoggedAgain_ThenTheLaterSnapshotReplacesTheEarlierOne() async throws {
    let storage = InMemoryTransactionLogStorage()
    let sut = TransactionLogControllerImpl(storageController: storage)

    try await sut.log(transaction: makePresentation(id: "presentation-1", result: .notCompleted))
    try await sut.log(transaction: makePresentation(id: "presentation-1", result: .completed))

    let logs = try await sut.fetchTransactionLogs()
    #expect(logs.count == 1)
    #expect(logs.first?.transactionResult == .completed)
  }

  @Test
  func fetchTransactionLogs_WhenAnEntryCannotBeDecoded_ThenItIsSkipped() async throws {
    let storage = InMemoryTransactionLogStorage()
    let sut = TransactionLogControllerImpl(storageController: storage)
    let entry = makePresentation(id: "presentation-1", result: .completed)
    try await sut.log(transaction: entry)
    try await storage.store(TransactionLog(identifier: "broken", time: Date(), value: "{\"not\":\"ts10\"}"))

    let logs = try await sut.fetchTransactionLogs()

    #expect(logs == [entry])
  }

  @Test
  func log_WhenTheStoreIsLocked_ThenKeepsTheEntryAndStoresItOnTheNextAccess() async throws {
    let storage = InMemoryTransactionLogStorage()
    let sut = TransactionLogControllerImpl(storageController: storage)
    let entry = makePresentation(id: "presentation-1", result: .completed)
    await storage.setLocked(true)

    try await sut.log(transaction: entry)
    #expect(await storage.retrieveAll().isEmpty)

    await storage.setLocked(false)

    #expect(try await sut.fetchTransactionLogs() == [entry])
  }

  @Test
  func deleteAllTransactionLogs_WhenEntriesArePending_ThenDropsThemToo() async throws {
    let storage = InMemoryTransactionLogStorage()
    let sut = TransactionLogControllerImpl(storageController: storage)
    await storage.setLocked(true)
    try await sut.log(transaction: makePresentation(id: "presentation-1", result: .completed))
    await storage.setLocked(false)

    try await sut.deleteAllTransactionLogs()

    #expect(try await sut.fetchTransactionLogs().isEmpty)
  }

  @Test
  func deleteTransactionLogs_WhenGivenIdentifiers_ThenDeletesThoseStoredAndPendingEntriesOnly() async throws {
    let storage = InMemoryTransactionLogStorage()
    let sut = TransactionLogControllerImpl(storageController: storage)
    let kept = makePresentation(id: "presentation-2", result: .completed)
    try await sut.log(transaction: makePresentation(id: "presentation-1", result: .completed))
    try await sut.log(transaction: kept)
    await storage.setLocked(true)
    try await sut.log(transaction: makePresentation(id: "presentation-3", result: .completed))
    await storage.setLocked(false)

    try await sut.deleteTransactionLogs(with: ["presentation-1", "presentation-3"])

    #expect(try await sut.fetchTransactionLogs() == [kept])
  }

  @Test
  func saveIssuanceSnapshot_WhenSaved_ThenItIsReadBackAndDeletedWithTheLog() async throws {
    let sut = TransactionLogControllerImpl(storageController: InMemoryTransactionLogStorage())
    let snapshot = IssuanceSnapshot(
      transactionIdentifier: IssuanceSnapshot.transactionIdentifier(forDocumentId: "doc-1"),
      time: Date(timeIntervalSince1970: 1_790_000_000),
      credentialIdentifier: "urn:eudi:eaa:loyalty-card:1",
      display: [DisplayMetadata(name: "FitLife Membership", localeIdentifier: "en-US")],
      issuerDisplay: nil,
      claims: [IssuanceSnapshot.Claim(path: ["member_id"], displayName: "Member ID")],
      registration: .init(privacyPolicy: "https://issuer.example/privacy", supportURI: nil, infoURI: "https://issuer.example/info")
    )

    try await sut.saveIssuanceSnapshot(snapshot)
    #expect(try await sut.fetchIssuanceSnapshots() == [snapshot])

    try await sut.deleteAllTransactionLogs()
    #expect(try await sut.fetchIssuanceSnapshots().isEmpty)
  }

  @Test
  func documentId_WhenBuiltFromATransactionIdentifier_ThenRoundTrips() {
    let identifier = IssuanceSnapshot.transactionIdentifier(forDocumentId: "doc-1")

    #expect(IssuanceSnapshot.documentId(fromTransactionIdentifier: identifier) == "doc-1")
    #expect(IssuanceSnapshot.documentId(fromTransactionIdentifier: "presentation-1") == nil)
  }

  private func makePresentation(id: String, result: TransactionResult) -> TransactionEntry {
    .presentation(
      .init(
        transactionIdentifier: id,
        // Whole seconds, since the log stores ISO 8601 timestamps without fractions
        time: Date(timeIntervalSince1970: 1_790_000_000),
        transactionResult: result,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [
          ClaimInfo(credentialIdentifier: "urn:eudi:pid:de:1", claims: [ClaimPath([.claim(name: "family_name")])])
        ],
        interactingPartyName: MultiLangString(lang: "en", content: "Example Verifier")
      )
    )
  }
}

private actor InMemoryTransactionLogStorage: TransactionLogStorageController {

  private var logs: [String: TransactionLog] = [:]
  /// Simulates the `.complete` protected store while the device is locked.
  private var isLocked = false
  private var snapshots: [String: IssuanceSnapshotRecord] = [:]

  func setLocked(_ locked: Bool) {
    isLocked = locked
  }

  func store(_ value: TransactionLog) throws {
    if isLocked { throw CocoaError(.fileWriteNoPermission) }
    logs[value.identifier] = value
  }

  func retrieve(_ identifier: String) throws -> TransactionLog {
    guard let log = logs[identifier] else { throw StorageError.itemNotFound }
    return log
  }

  func retrieveAll() -> [TransactionLog] {
    logs.values.sorted { $0.time > $1.time }
  }

  func storeSnapshot(_ value: IssuanceSnapshotRecord) {
    snapshots[value.identifier] = value
  }

  func retrieveAllSnapshots() -> [IssuanceSnapshotRecord] {
    snapshots.values.sorted { $0.time > $1.time }
  }

  func delete(_ identifiers: [String]) {
    identifiers.forEach {
      logs[$0] = nil
      snapshots[$0] = nil
    }
  }

  func deleteAll() {
    logs.removeAll()
    snapshots.removeAll()
  }
}
