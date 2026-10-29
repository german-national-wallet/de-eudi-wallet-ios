//
//  IssuanceSnapshotRecord.swift
//  logic-storage
//

import Foundation
import SwiftData

public struct IssuanceSnapshotRecord: StoredObject, Equatable {

  public let identifier: String
  public let time: Date
  public let value: String

  public init(identifier: String, time: Date, value: String) {
    self.identifier = identifier
    self.time = time
    self.value = value
  }
}

@Model
final class SDIssuanceSnapshot {

  @Attribute(.unique) var identifier: String
  var time: Date
  var value: String

  init(identifier: String, time: Date, value: String) {
    self.identifier = identifier
    self.time = time
    self.value = value
  }
}

extension SDIssuanceSnapshot {
  func toRecord() -> IssuanceSnapshotRecord {
    IssuanceSnapshotRecord(identifier: identifier, time: time, value: value)
  }
}
