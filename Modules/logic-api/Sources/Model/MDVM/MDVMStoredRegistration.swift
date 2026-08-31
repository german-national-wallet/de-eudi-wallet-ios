//
//  MDVMStoredRegistration.swift
//  logic-api
//

import Foundation
import logic_business

/// Local persistence model kept separate from response DTOs to decouple storage shape from backend contract changes.
public struct MDVMStoredRegistration: Equatable {
  public let mdvmWIID: String
  public let mdvmToken: String

  /// Helper to parse expiration date from the mdvm token
  public var expirationDate: Date? {
    let parts = mdvmToken.split(separator: ".")
    guard parts.count == 3 else { return nil }

    guard
      let payloadData = String(parts[1]).decodeBase64Data,
      let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
      let expiration = (payloadJSON["exp"] as? NSNumber).map({ TimeInterval($0.doubleValue) })
    else {
      return nil
    }

    return Date(timeIntervalSince1970: expiration)
  }

  public init(mdvmWIID: String, mdvmToken: String) {
    self.mdvmWIID = mdvmWIID
    self.mdvmToken = mdvmToken
  }
}
