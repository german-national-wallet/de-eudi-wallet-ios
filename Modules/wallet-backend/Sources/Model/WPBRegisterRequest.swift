//
//  WPBRegisterRequest.swift
//  wallet-backend
//

import logic_api

struct WPBRegisterRequest: NetworkRequest {
  typealias Response = WPBRegisterResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = WPBConstants.Path.register

  init(additionalHeaders: [String: String]) {
    self.additionalHeaders = additionalHeaders
  }
}
