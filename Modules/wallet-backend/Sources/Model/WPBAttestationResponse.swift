//
//  WPBAttestationResponse.swift
//  wallet-backend
//

public struct WPBAttestationResponse: Decodable, Equatable {
  public let wbWIA: String

  enum CodingKeys: String, CodingKey {
    case wbWIA = "wpb_wia"
  }

  public init(wbWIA: String) {
    self.wbWIA = wbWIA
  }
}
