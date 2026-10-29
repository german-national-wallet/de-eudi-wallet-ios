//
//  TransactionLog.swift
//  logic-storage
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import SwiftData

public struct TransactionLog: StoredObject, Equatable {

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
final class SDTransactionLog {

  @Attribute(.unique) var identifier: String
  var time: Date
  var value: String

  init(identifier: String, time: Date, value: String) {
    self.identifier = identifier
    self.time = time
    self.value = value
  }
}

extension SDTransactionLog {
  func toTransactionLog() -> TransactionLog {
    TransactionLog(identifier: identifier, time: time, value: value)
  }
}
