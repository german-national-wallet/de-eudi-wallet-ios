//
//  NetworkResponse.swift
//  logic-api
//

import Foundation

public struct NetworkResponse: Sendable {
  public let data: Data?
  public let headers: [String: String]?
  public let statusCode: Int?

  public init(data: Data?, headers: [String: String]?, statusCode: Int? = nil) {
    self.data = data
    self.headers = headers
    self.statusCode = statusCode
  }

  public var isSuccessStatusCode: Bool {
    guard let statusCode else {
      return false
    }
    return (200..<300).contains(statusCode)
  }
}
