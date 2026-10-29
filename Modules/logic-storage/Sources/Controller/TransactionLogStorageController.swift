//
//  TransactionLogStorageController.swift
//  logic-storage
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import SwiftData

public protocol TransactionLogStorageController: Sendable {
  func store(_ value: TransactionLog) async throws
  func retrieve(_ identifier: String) async throws -> TransactionLog
  func retrieveAll() async throws -> [TransactionLog]
  /// Inserts the snapshot, or replaces the stored one with the same identifier.
  func storeSnapshot(_ value: IssuanceSnapshotRecord) async throws
  /// All stored issuance snapshots, newest first.
  func retrieveAllSnapshots() async throws -> [IssuanceSnapshotRecord]
  /// Deletes the entries and issuance snapshots with these identifiers.
  func delete(_ identifiers: [String]) async throws
  /// Deletes the entries and the issuance snapshots kept with them.
  func deleteAll() async throws
}

final actor TransactionLogStorageControllerImpl: TransactionLogStorageController {

  private let storeURL: URL
  private var context: ModelContext?

  init(storeURL: URL = TransactionLogStorageControllerImpl.defaultStoreURL) {
    self.storeURL = storeURL
  }

  func store(_ value: TransactionLog) throws {
    let context = try openContext()
    let identifier = value.identifier
    let existing = try context.fetch(
      FetchDescriptor<SDTransactionLog>(predicate: #Predicate { $0.identifier == identifier })
    )
    if let stored = existing.first {
      stored.time = value.time
      stored.value = value.value
    } else {
      context.insert(SDTransactionLog(identifier: value.identifier, time: value.time, value: value.value))
    }
    try context.save()
  }

  func retrieve(_ identifier: String) throws -> TransactionLog {
    var descriptor = FetchDescriptor<SDTransactionLog>(predicate: #Predicate { $0.identifier == identifier })
    descriptor.fetchLimit = 1
    guard let log = try openContext().fetch(descriptor).first else {
      throw StorageError.itemNotFound
    }
    return log.toTransactionLog()
  }

  func retrieveAll() throws -> [TransactionLog] {
    let descriptor = FetchDescriptor<SDTransactionLog>(sortBy: [SortDescriptor(\.time, order: .reverse)])
    return try openContext().fetch(descriptor).map { $0.toTransactionLog() }
  }

  func storeSnapshot(_ value: IssuanceSnapshotRecord) throws {
    let context = try openContext()
    let identifier = value.identifier
    let existing = try context.fetch(
      FetchDescriptor<SDIssuanceSnapshot>(predicate: #Predicate { $0.identifier == identifier })
    )
    if let stored = existing.first {
      stored.time = value.time
      stored.value = value.value
    } else {
      context.insert(SDIssuanceSnapshot(identifier: value.identifier, time: value.time, value: value.value))
    }
    try context.save()
  }

  func retrieveAllSnapshots() throws -> [IssuanceSnapshotRecord] {
    let descriptor = FetchDescriptor<SDIssuanceSnapshot>(sortBy: [SortDescriptor(\.time, order: .reverse)])
    return try openContext().fetch(descriptor).map { $0.toRecord() }
  }

  func delete(_ identifiers: [String]) throws {
    let context = try openContext()
    try context.delete(model: SDTransactionLog.self, where: #Predicate { identifiers.contains($0.identifier) })
    try context.delete(model: SDIssuanceSnapshot.self, where: #Predicate { identifiers.contains($0.identifier) })
    try context.save()
  }

  func deleteAll() throws {
    let context = try openContext()
    try context.delete(model: SDTransactionLog.self)
    try context.delete(model: SDIssuanceSnapshot.self)
    try context.save()
  }

  private func openContext() throws -> ModelContext {
    if let context { return context }
    let directory = storeURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true,
      attributes: [.protectionKey: Self.fileProtection]
    )
    try excludeFromBackup(directory)
    let container = try ModelContainer(
      for: SDTransactionLog.self, SDIssuanceSnapshot.self,
      configurations: ModelConfiguration(url: storeURL)
    )
    try applyFileProtection()
    let context = ModelContext(container)
    self.context = context
    return context
  }

  private func excludeFromBackup(_ directory: URL) throws {
    var directory = directory
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try directory.setResourceValues(values)
  }

  private func applyFileProtection() throws {
    let fileManager = FileManager.default
    for suffix in ["", "-wal", "-shm"] {
      let path = storeURL.path + suffix
      guard fileManager.fileExists(atPath: path) else { continue }
      try fileManager.setAttributes([.protectionKey: Self.fileProtection], ofItemAtPath: path)
    }
  }

  private static let fileProtection = FileProtectionType.complete

  static var defaultStoreURL: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return base
      .appendingPathComponent("TransactionLog", isDirectory: true)
      .appendingPathComponent("transaction_log.store")
  }
}
