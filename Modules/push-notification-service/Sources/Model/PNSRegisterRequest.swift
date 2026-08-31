//
//  PNSRegisterRequest.swift
//  push-notification-service
//

import Foundation
import logic_api

struct PNSRegisterRequest: NetworkRequest {
  typealias Response = Void

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = PNSConstants.Path.register
  var body: Data?

  init(body: Data?, additionalHeaders: [String: String]) {
    self.body = body
    self.additionalHeaders = additionalHeaders
  }
}
