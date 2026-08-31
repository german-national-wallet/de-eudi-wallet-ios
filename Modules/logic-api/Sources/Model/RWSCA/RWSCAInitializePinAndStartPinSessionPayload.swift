//
//  RWSCAInitializePinAndStartPinSessionPayload.swift
//  logic-api
//

import Foundation

public struct RWSCAInitializePinAndStartPinSessionPayload: Codable {

  enum CodingKeys: String, CodingKey {
    case wiRwscaPinPubk = "wi_rwsca_pin_pubk"
  }

  let wiRwscaPinPubk: String

  public init(wiRwscaPinPubk: String) {
    self.wiRwscaPinPubk = wiRwscaPinPubk
  }
}
