//
//  MDVMChallengeRequest.swift
//  logic-api
//

import Foundation

struct MDVMChallengeRequest: NetworkRequest {
  typealias Response = MDVMChallengeResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String] = [:]
  var path: String = MDVMConstants.Path.challenge
  var body: Data?
}
