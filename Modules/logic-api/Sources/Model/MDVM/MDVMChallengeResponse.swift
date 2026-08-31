//
//  MDVMChallengeResponse.swift
//  logic-api
//

import Foundation

struct MDVMChallengeResponse: Decodable {
  let mdvmAuthChallenge: String

  enum CodingKeys: String, CodingKey {
    case mdvmAuthChallenge = "mdvm_auth_challenge"
  }
}
