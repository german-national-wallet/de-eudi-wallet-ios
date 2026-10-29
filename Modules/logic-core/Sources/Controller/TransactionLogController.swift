//
//  TransactionLogController.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import MdocDataModel18013
import logic_business
import logic_storage

public protocol TransactionLogController: Sendable {
  func fetchTransactionLogs() async throws -> [TransactionEntry]
  func fetchTransactionLog(with identifier: String) async throws -> TransactionEntry
  func deleteTransactionLogs(with identifiers: [String]) async throws
  func deleteAllTransactionLogs() async throws
  func saveIssuanceSnapshot(_ snapshot: IssuanceSnapshot) async throws
  func fetchIssuanceSnapshots() async throws -> [IssuanceSnapshot]
}

final actor TransactionLogControllerImpl: TransactionLogController, TransactionLogger {

  private let storageController: TransactionLogStorageController
  private let logger: Logging?
  private var pending: [String: TransactionLog] = [:]

  init(storageController: TransactionLogStorageController, logger: Logging? = nil) {
    self.storageController = storageController
    self.logger = logger
  }

  func log(transaction: TransactionEntry) async throws {
    guard let value = String(data: try Self.encoder.encode(transaction), encoding: .utf8) else {
      throw EncodingError.invalidValue(
        transaction,
        .init(codingPath: [], debugDescription: "The encoded transaction isn't valid UTF-8")
      )
    }
    let log = TransactionLog(identifier: transaction.transactionIdentifier, time: transaction.time, value: value)
    pending[log.identifier] = log
    await storePending()
  }

  private func storePending() async {
    for log in pending.values.sorted(by: { $0.time < $1.time }) {
      do {
        try await storageController.store(log)
        if pending[log.identifier] == log { pending[log.identifier] = nil }
      } catch {
        logger?.e("TransactionLog: keeping \(pending.count) entries to store later: \(error.localizedDescription)")
        return
      }
    }
  }

  func fetchTransactionLogs() async throws -> [TransactionEntry] {
    await storePending()
    return try await storageController.retrieveAll().compactMap { log in
      do {
        return try decode(log)
      } catch {
        logger?.e("TransactionLog: skipping undecodable entry: \(error.localizedDescription)")
        return nil
      }
    }
  }

  func fetchTransactionLog(with identifier: String) async throws -> TransactionEntry {
    await storePending()
    return try decode(try await storageController.retrieve(identifier))
  }

  func deleteTransactionLogs(with identifiers: [String]) async throws {
    identifiers.forEach { pending[$0] = nil }
    try await storageController.delete(identifiers)
  }

  func deleteAllTransactionLogs() async throws {
    pending.removeAll()
    try await storageController.deleteAll()
  }

  func saveIssuanceSnapshot(_ snapshot: IssuanceSnapshot) async throws {
    guard let value = String(data: try Self.encoder.encode(snapshot), encoding: .utf8) else {
      throw EncodingError.invalidValue(
        snapshot,
        .init(codingPath: [], debugDescription: "The encoded issuance snapshot isn't valid UTF-8")
      )
    }
    try await storageController.storeSnapshot(
      IssuanceSnapshotRecord(identifier: snapshot.transactionIdentifier, time: snapshot.time, value: value)
    )
  }

  func fetchIssuanceSnapshots() async throws -> [IssuanceSnapshot] {
    try await storageController.retrieveAllSnapshots().compactMap { record in
      do {
        return try Self.decoder.decode(IssuanceSnapshot.self, from: Data(record.value.utf8))
      } catch {
        logger?.e("TransactionLog: skipping undecodable issuance snapshot: \(error.localizedDescription)")
        return nil
      }
    }
  }

  private func decode(_ log: TransactionLog) throws -> TransactionEntry {
    try Self.decoder.decode(TransactionEntry.self, from: Data(log.value.utf8))
  }

  private static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }()

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()
}
