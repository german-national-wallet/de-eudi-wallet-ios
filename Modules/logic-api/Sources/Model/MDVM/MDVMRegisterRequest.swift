//
//  MDVMRegisterRequest.swift
//  logic-api
//

import Foundation

struct MDVMRegisterRequest: NetworkRequest {
  typealias Response = MDVMRegistrationResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = MDVMConstants.Path.register
  var body: Data?

  init(body: Data, additionalHeaders: [String: String]) {
    self.body = body
    self.additionalHeaders = additionalHeaders
  }
}
