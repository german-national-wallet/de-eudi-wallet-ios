//
//  TransactionLogStorageControllerTests.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 05.10.26.
//

import Foundation
import Testing

@testable import logic_storage

struct TransactionLogStorageControllerTests {

  @Test
  func deleteAll_WhenEntriesWereReadBefore_ThenNoEntriesRemain() async throws {
    let sut = makeSUT()
    try await sut.store(TransactionLog(identifier: "a", time: Date(), value: "{}"))
    try await sut.store(TransactionLog(identifier: "b", time: Date(), value: "{}"))
    #expect(try await sut.retrieveAll().count == 2)

    try await sut.deleteAll()

    #expect(try await sut.retrieveAll().isEmpty)
  }

  @Test
  func store_WhenIdentifierExists_ThenReplacesTheEntry() async throws {
    let sut = makeSUT()
    try await sut.store(TransactionLog(identifier: "a", time: Date(), value: "{\"v\":1}"))
    try await sut.store(TransactionLog(identifier: "a", time: Date(), value: "{\"v\":2}"))

    let logs = try await sut.retrieveAll()

    #expect(logs.map(\.value) == ["{\"v\":2}"])
  }

  @Test
  func store_WhenTheStoreIsCreated_ThenItsFolderIsExcludedFromBackup() async throws {
    let storeURL = makeStoreURL()
    let sut = TransactionLogStorageControllerImpl(storeURL: storeURL)

    try await sut.store(TransactionLog(identifier: "a", time: Date(), value: "{}"))

    let values = try storeURL.deletingLastPathComponent().resourceValues(forKeys: [.isExcludedFromBackupKey])
    #expect(values.isExcludedFromBackup == true)
  }

  @Test
  func delete_WhenGivenIdentifiers_ThenDeletesThoseEntriesAndSnapshotsOnly() async throws {
    let sut = makeSUT()
    try await sut.store(TransactionLog(identifier: "a", time: Date(), value: "{}"))
    try await sut.store(TransactionLog(identifier: "b", time: Date(), value: "{}"))
    try await sut.storeSnapshot(IssuanceSnapshotRecord(identifier: "a", time: Date(), value: "{}"))
    try await sut.storeSnapshot(IssuanceSnapshotRecord(identifier: "b", time: Date(), value: "{}"))

    try await sut.delete(["a"])

    #expect(try await sut.retrieveAll().map(\.identifier) == ["b"])
    #expect(try await sut.retrieveAllSnapshots().map(\.identifier) == ["b"])
  }

  @Test
  func deleteAll_WhenSnapshotsWereStored_ThenTheyAreDeletedToo() async throws {
    let sut = makeSUT()
    try await sut.store(TransactionLog(identifier: "issuance:a", time: Date(), value: "{}"))
    try await sut.storeSnapshot(IssuanceSnapshotRecord(identifier: "issuance:a", time: Date(), value: "{}"))
    try await sut.storeSnapshot(IssuanceSnapshotRecord(identifier: "issuance:a", time: Date(), value: "{\"v\":2}"))
    #expect(try await sut.retrieveAllSnapshots().map(\.value) == ["{\"v\":2}"])

    try await sut.deleteAll()

    #expect(try await sut.retrieveAllSnapshots().isEmpty)
  }

  private func makeSUT() -> TransactionLogStorageControllerImpl {
    TransactionLogStorageControllerImpl(storeURL: makeStoreURL())
  }

  private func makeStoreURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
      .appendingPathComponent("transaction_log.store")
  }
}
