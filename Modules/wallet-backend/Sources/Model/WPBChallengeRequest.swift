//
//  WPBChallengeRequest.swift
//  wallet-backend
//

import Foundation
import logic_api

struct WPBChallengeRequest: NetworkRequest {
  typealias Response = WPBChallengeResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String] = [:]
  var path: String = WPBConstants.Path.challenge
  var body: Data?
}
