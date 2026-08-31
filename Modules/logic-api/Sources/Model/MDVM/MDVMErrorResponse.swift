//
//  MDVMErrorResponse.swift
//  logic-api
//

import Foundation

struct MDVMErrorResponse: Codable {
  let code: String
  let description: String
  let traceID: String?

  enum CodingKeys: String, CodingKey {
    case code
    case description
    case traceID = "trace_id"
  }
}
