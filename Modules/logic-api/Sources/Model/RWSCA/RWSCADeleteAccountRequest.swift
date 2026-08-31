//
//  RWSCADeleteAccountRequest.swift
//  logic-api
//

import Foundation

struct RWSCADeleteAccountRequest: NetworkRequest {
  typealias Response = Void

  var baseURL: String?
  var method: NetworkMethod { .DELETE }
  var additionalHeaders: [String: String]
  var path: String = RWSCAConstants.Path.deleteAccount

  init(additionalHeaders: [String: String]) {
    self.additionalHeaders = additionalHeaders
  }
}
