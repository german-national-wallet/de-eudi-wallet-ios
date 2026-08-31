//
//  RWSCAChallengeResponse.swift
//  logic-api
//

struct RWSCAChallengeResponse: Codable {
  let rwscaAuthChallenge: String

  enum CodingKeys: String, CodingKey {
    case rwscaAuthChallenge = "rwsca_auth_challenge"
  }
}
