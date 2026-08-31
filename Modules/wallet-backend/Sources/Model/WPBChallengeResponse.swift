//
//  WPBChallengeResponse.swift
//  wallet-backend
//

public struct WPBChallengeResponse: Decodable, Equatable {
  public let wbAuthChallenge: String

  enum CodingKeys: String, CodingKey {
    case wbAuthChallenge = "wpb_auth_challenge"
  }

  public init(wbAuthChallenge: String) {
    self.wbAuthChallenge = wbAuthChallenge
  }
}
