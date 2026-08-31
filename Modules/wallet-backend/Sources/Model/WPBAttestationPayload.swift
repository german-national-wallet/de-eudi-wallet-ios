//
//  WPBAttestationPayload.swift
//  wallet-backend
//

public struct WPBAttestationPayload: Encodable, Equatable {
  public let wiWIAPublicKey: String

  enum CodingKeys: String, CodingKey {
    case wiWIAPublicKey = "wi_wia_pubk"
  }

  public init(wiWIAPublicKey: String) {
    self.wiWIAPublicKey = wiWIAPublicKey
  }
}
