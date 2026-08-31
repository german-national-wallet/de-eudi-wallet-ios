//
//  WPBErrorResponse.swift
//  wallet-backend
//

import Foundation

struct WPBErrorResponse: Decodable, Equatable {
  let code: String
  let description: String?
  let timestamp: String?
  let traceID: String?

  enum CodingKeys: String, CodingKey {
    case code
    case description
    case timestamp
    case traceID = "trace_id"
  }
}
