//
//  RWSCARegistrationResponse.swift
//  logic-api
//

import Foundation

public struct RWSCAPinSessionResponse: Codable {
  public let rwscaPinSessionToken: String

  public init(rwscaPinSessionToken: String) {
    self.rwscaPinSessionToken = rwscaPinSessionToken
  }

  enum CodingKeys: String, CodingKey {
    case rwscaPinSessionToken = "rwsca_pin_session_token"
  }
}
