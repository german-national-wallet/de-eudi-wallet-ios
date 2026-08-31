//
//  NonceRequest.swift
//  logic-api
//

import Foundation

struct NonceRequest: NetworkRequest {
  var baseURL: String?
  typealias Response = NonceResponse
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String] = [:]
  var path: String = "nonce"
  var body: Data?

  var requiresAuthToken: Bool { false }
}
