//
//  PNSStoredRegistration.swift
//  push-notification-service
//

import Foundation

/// Local persistence model kept separate from request DTOs to decouple storage shape from backend
/// contract changes. Token and timestamp are stored as one record on purpose: a partial wipe must
/// never leave a registration timestamp behind that points at a token the WI no longer holds.
public struct PNSStoredRegistration: Codable, Equatable {
  public let mppRegistrationToken: String
  public let registeredAt: Date

  enum CodingKeys: String, CodingKey {
    case mppRegistrationToken = "mpp_registration_token"
    case registeredAt = "registered_at"
  }

  public init(mppRegistrationToken: String, registeredAt: Date) {
    self.mppRegistrationToken = mppRegistrationToken
    self.registeredAt = registeredAt
  }

  /// Whether the registration is due for the periodic renewal, so the stored
  /// `mpp_registration_token` does not become stale at the PNS.
  public func isOlderThan(_ interval: TimeInterval, now: Date = Date()) -> Bool {
    now.timeIntervalSince(registeredAt) >= interval
  }
}
