//
//  PNSChallengeResponse.swift
//  push-notification-service
//

public struct PNSChallengeResponse: Decodable, Equatable {
  public let pnsAuthChallenge: String

  enum CodingKeys: String, CodingKey {
    case pnsAuthChallenge = "pns_auth_challenge"
  }

  public init(pnsAuthChallenge: String) {
    self.pnsAuthChallenge = pnsAuthChallenge
  }
}
