//
//  FeatureFlagFetchRequest.swift
//  logic-feature-flag
//

import Foundation
import logic_api

struct FeatureFlagFetchRequest: NetworkRequest {
  typealias Response = String

  var baseURL: String?
  var method: NetworkMethod { .GET }
  var path: String = Constants.API.featuresPath
  var additionalHeaders: [String: String] = [:]
  var body: Data? { nil }
  var requiresAuthToken: Bool { false }
  var credentials: [NetworkRequestCredential] {
    [.query(name: Constants.API.apiKeyQueryParam, envKey: Constants.Env.apiKey)]
  }
}
