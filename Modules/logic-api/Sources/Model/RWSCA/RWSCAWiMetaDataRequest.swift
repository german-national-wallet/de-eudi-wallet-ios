//
//  RWSCAWiMetaDataRequest.swift
//  logic-api
//

import Foundation

struct RWSCAWiMetaDataRequest: NetworkRequest {
  typealias Response = RWSCAWiMetaDataResponse

  var baseURL: String?
  var additionalHeaders: [String: String] = [:]
  var path: String = RWSCAConstants.Path.wiMetaData
}
