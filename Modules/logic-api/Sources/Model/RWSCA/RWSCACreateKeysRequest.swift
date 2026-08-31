//
//  RWSCACreateKeysRequest.swift
//  logic-api
//

import Foundation

struct RWSCACreateKeysRequest: NetworkRequest {
  typealias Response = RWSCACreateKeysResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = RWSCAConstants.Path.createKeys
  var body: Data?

  init(body: Data?, additionalHeaders: [String: String]) {
    self.body = body
    self.additionalHeaders = additionalHeaders
  }
}
