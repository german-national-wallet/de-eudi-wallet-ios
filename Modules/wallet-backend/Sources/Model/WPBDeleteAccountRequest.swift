//
//  WPBDeleteAccountRequest.swift
//  wallet-backend
//

import logic_api

struct WPBDeleteAccountRequest: NetworkRequest {
  typealias Response = Void

  var baseURL: String?
  var method: NetworkMethod { .DELETE }
  var additionalHeaders: [String: String]
  var path: String = WPBConstants.Path.deleteAccount

  init(additionalHeaders: [String: String]) {
    self.additionalHeaders = additionalHeaders
  }
}
