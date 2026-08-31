//
//  PNSRegisterPayload.swift
//  push-notification-service
//

public struct PNSRegisterPayload: Encodable, Equatable {
  public let mppRegistrationToken: String

  enum CodingKeys: String, CodingKey {
    case mppRegistrationToken = "mpp_registration_token"
  }

  public init(mppRegistrationToken: String) {
    self.mppRegistrationToken = mppRegistrationToken
  }
}
