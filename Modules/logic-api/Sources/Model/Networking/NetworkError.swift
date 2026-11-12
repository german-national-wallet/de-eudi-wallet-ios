//
//  NetworkError.swift
//  logic-api
//

import Foundation
import Alamofire

public enum NetworkError: LocalizedError, Equatable {
  case invalidUrl
  case apiKeyNotFound
  case noInternet
  case internetFailure(Error)
  case invalidResponse
  case decodingError(Error)
  case invalidStatusCode(URL, Int)
  case httpError(code: Int, data: Data?, headers: [String: String]?)

  public var errorDescription: String? {
    switch self {
    case .invalidUrl:
      return ".invalidUrl"
    case .noInternet:
      return ".noInternet"
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
      (.noInternet, .noInternet),
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

public extension Error {
  var isNoInternet: Bool {
    var current: Error? = self
    var depth = 0
    while let error = current, depth < 8 {
      if let urlError = error as? URLError {
        return offlineURLErrorCodes.contains(urlError.code)
      }
      switch error {
      case NetworkError.noInternet:
        return true
      case NetworkError.internetFailure(let underlying):
        current = underlying
      default:
        current = (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error
      }
      depth += 1
    }
    return false
  }
}

private let offlineURLErrorCodes: Set<URLError.Code> = [
  .notConnectedToInternet,
  .dataNotAllowed,
  .internationalRoamingOff
]

public extension NetworkError {
  static let transportStatusCodes: Set<Int> = [408, 429, 504]

  var transportCause: URLError? {
    guard case .internetFailure(let error) = self else {
      return nil
    }
    return (error.asAFError?.underlyingError ?? error) as? URLError
  }

  var retryAfter: TimeInterval? {
    guard case .httpError(_, _, let headers) = self else {
      return nil
    }
    return headers?
      .first { $0.key.caseInsensitiveCompare("Retry-After") == .orderedSame }
      .flatMap { TimeInterval($0.value.trimmingCharacters(in: .whitespaces)) }
  }
}
