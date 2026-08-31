//
//  InvalidPasswordResponse.swift
//  logic-api
//

import Foundation

public enum PresentationError: Error {
  case invalidPassword(InvalidPasswordResponse)
}

public struct InvalidPasswordResponse: Codable, Error, Equatable {
  public let code: String
  public let message: String?
  public let timestamp: String
  public let traceId: String
  public let tryAllowedAfter: String?
  public let tryCounter: Int?

  public init(
      code: String,
      message: String?,
      timestamp: String,
      traceId: String,
      tryAllowedAfter: String? = nil,
      tryCounter: Int? = nil
  ) {
      self.code = code
      self.message = message
      self.timestamp = timestamp
      self.traceId = traceId
      self.tryAllowedAfter = tryAllowedAfter
      self.tryCounter = tryCounter
  }
}

public extension InvalidPasswordResponse {
  var isBlocked: Bool {
    code == RWSCAServerErrorCode.accountLocked
  }
}
