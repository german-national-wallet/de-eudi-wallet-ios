//
//  MDVMRenewalRequest.swift
//  logic-api
//

import Foundation

struct MDVMRenewalRequest: NetworkRequest {
  typealias Response = MDVMRenewalResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = MDVMConstants.Path.renewal
  var body: Data?

  init(body: Data, additionalHeaders: [String: String]) {
    self.body = body
    self.additionalHeaders = additionalHeaders
  }
}
