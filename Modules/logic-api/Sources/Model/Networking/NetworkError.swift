//
//  NetworkError.swift
//  logic-api
//

import Foundation

public enum NetworkError: LocalizedError, Equatable {
  case invalidUrl
  case apiKeyNotFound
  case internetFailure(Error)
  case invalidResponse
  case decodingError(Error)
  case invalidStatusCode(URL, Int)
  case httpError(code: Int, data: Data?, headers: [String: String]?)

  public var errorDescription: String? {
    switch self {
    case .invalidUrl:
      return ".invalidUrl"
    case .internetFailure(let error):
      return ".networkError \(error.localizedDescription)"
    case .invalidResponse:
      return ".invalidResponse"
    case .decodingError(let error):
      return ".decodingError \(error.localizedDescription)"
    case .invalidStatusCode(let code, let url):
      return ".invalidStatusCode \(code) \(url)"
    case .apiKeyNotFound:
      return ".apiKeyNotFound"
    case .httpError(code: let code, data: let data, headers: let headers):
      return ".httpError \(code) \(String(data: data ?? Data(), encoding: .utf8) ?? "no data") \(headers ?? [:])"
    }
  }

  public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidUrl, .invalidUrl),
      (.invalidResponse, .invalidResponse):
      return true
    case (.internetFailure(let lhsError), .internetFailure(let rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    case (.decodingError(let lhsError), .decodingError(let rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    case (.invalidStatusCode(let lhsUrl, let lhsCode), .invalidStatusCode(let rhsUrl, let rhsCode)):
      return lhsUrl == rhsUrl && lhsCode == rhsCode
    default:
      return false
    }
  }
}
