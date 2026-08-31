//
//  RWSCAChallengeRequest.swift
//  logic-api
//

import Foundation

struct RWSCAChallengeRequest: NetworkRequest {
  typealias Response = RWSCAChallengeResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String] = [:]
  var path: String = RWSCAConstants.Path.challenge
  var body: Data?
}
