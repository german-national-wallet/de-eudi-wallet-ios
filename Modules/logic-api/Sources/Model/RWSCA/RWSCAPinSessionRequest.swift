//
//  RWSCARegisterRequest.swift
//  logic-api
//

import Foundation

struct RWSCAPinSessionRequest: NetworkRequest {
  typealias Response = RWSCAPinSessionResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String
  var body: Data?

  init(body: Data?, additionalHeaders: [String: String], path: String) {
    self.body = body
    self.additionalHeaders = additionalHeaders
    self.path = path
  }
}
