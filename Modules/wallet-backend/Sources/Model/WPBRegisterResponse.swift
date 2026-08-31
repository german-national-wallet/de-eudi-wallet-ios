//
//  WPBRegisterResponse.swift
//  wallet-backend
//

public struct WPBRegisterResponse: Decodable, Equatable {
  public let wbWIID: String
  public let wpbWiRevocationCode: String

  enum CodingKeys: String, CodingKey {
    case wbWIID = "wpb_wi_id"
    case wpbWiRevocationCode = "wpb_wi_revocation_code"
  }

  public init(wbWIID: String, wpbWiRevocationCode: String) {
    self.wbWIID = wbWIID
    self.wpbWiRevocationCode = wpbWiRevocationCode
  }
}
