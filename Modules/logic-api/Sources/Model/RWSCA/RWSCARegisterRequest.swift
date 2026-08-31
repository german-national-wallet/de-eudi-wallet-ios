//
//  RWSCARegisterRequest.swift
//  logic-api
//

import Foundation

struct RWSCARegisterRequest: NetworkRequest {
  typealias Response = MDVMRegistrationResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = RWSCAConstants.Path.register

  init(additionalHeaders: [String: String]) {
    self.additionalHeaders = additionalHeaders
  }
}
