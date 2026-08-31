//
//  FlagError.swift
//  logic-feature-flag
//

import Foundation

enum FlagError: Error, Equatable {
  case invalidURL
  case invalidResponse
  case invalidPayload
  case duplicateKey
}
