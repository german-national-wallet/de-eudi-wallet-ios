//
//  RWSCASignDataRequest.swift
//  logic-api
//

import Foundation

struct RWSCASignDataRequest: NetworkRequest {
  typealias Response = RWSCASignDataResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = RWSCAConstants.Path.signData
  var body: Data?

  init(body: Data?, additionalHeaders: [String: String]) {
    self.body = body
    self.additionalHeaders = additionalHeaders
  }
}
