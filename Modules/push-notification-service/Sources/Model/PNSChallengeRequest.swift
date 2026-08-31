//
//  PNSChallengeRequest.swift
//  push-notification-service
//

import Foundation
import logic_api

struct PNSChallengeRequest: NetworkRequest {
  typealias Response = PNSChallengeResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String] = [:]
  var path: String = PNSConstants.Path.challenge
  var body: Data?
}
