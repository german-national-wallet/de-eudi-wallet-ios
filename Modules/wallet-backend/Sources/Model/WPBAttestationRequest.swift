//
//  WPBAttestationRequest.swift
//  wallet-backend
//

import Foundation
import logic_api

struct WPBAttestationRequest: NetworkRequest {
  typealias Response = WPBAttestationResponse

  var baseURL: String?
  var method: NetworkMethod { .POST }
  var additionalHeaders: [String: String]
  var path: String = WPBConstants.Path.attestation
  var body: Data?

  init(body: Data?, additionalHeaders: [String: String]) {
    self.body = body
    self.additionalHeaders = additionalHeaders
  }
}
