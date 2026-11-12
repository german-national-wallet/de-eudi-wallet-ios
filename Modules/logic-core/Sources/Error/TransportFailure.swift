//
//  TransportFailure.swift
//  logic-core
//

import Foundation
import enum logic_api.NetworkError
import enum OpenID4VCI.FetchError
import enum OpenID4VCI.PostError
import enum OpenID4VP.PostError
import enum OpenID4VP.ValidationError

public struct TransportFailure: Error, Equatable, Sendable {

  public enum Kind: String, Equatable, Sendable {
    /// The peer did not answer in time.
    case timeout
    /// The peer could not be reached at all (DNS, connection refused, connection lost).
    case unreachable
    /// The peer answered 429.
    case rateLimited
  }

  public enum Source: String, Equatable, Sendable {
    case openID4VPRequest
    case openID4VPResponse
    case openID4VCI
    case walletBackend
    case unknown
  }

  public let kind: Kind
  public let source: Source
  public let statusCode: Int?
  public let retryAfter: TimeInterval?

  public init(kind: Kind, source: Source, statusCode: Int? = nil, retryAfter: TimeInterval? = nil) {
    self.kind = kind
    self.source = source
    self.statusCode = statusCode
    self.retryAfter = retryAfter
  }

  // MARK: - Lookup

  private static let maxDepth = 8

  public static func find(in error: Error) -> TransportFailure? {
    var current: Error? = error
    var depth = 0
    while let candidate = current, depth < maxDepth {
      for matcher in matchers {
        if let failure = matcher(candidate) {
          return failure
        }
      }
      current = next(after: candidate)
      depth += 1
    }
    return nil
  }

  private static func next(after error: Error) -> Error? {
    if let walletError = error as? WalletError {
      return walletError.innerError
    }
    return (error as NSError).userInfo[NSUnderlyingErrorKey] as? Error
  }

  private static let matchers: [(Error) -> TransportFailure?] = [
    passthrough,
    openID4VP,
    openID4VCI,
    walletBackend,
    bareURLError
  ]

  // MARK: - Matchers

  private static func passthrough(_ error: Error) -> TransportFailure? {
    error as? TransportFailure
  }

  private static func openID4VP(_ error: Error) -> TransportFailure? {
    if case ValidationError.networkError(let failure) = error {
      return make(source: .openID4VPRequest, statusCode: failure.statusCode, urlError: failure.urlError)
    }
    if case OpenID4VP.PostError.networkError(let underlying) = error {
      return make(source: .openID4VPResponse, statusCode: nil, urlError: underlying as? URLError)
    }
    if case OpenID4VP.PostError.invalidStatusCode(_, let code, _) = error {
      return make(source: .openID4VPResponse, statusCode: code, urlError: nil)
    }
    return nil
  }

  private static func openID4VCI(_ error: Error) -> TransportFailure? {
    if case OpenID4VCI.PostError.networkError(let underlying) = error {
      return make(source: .openID4VCI, statusCode: nil, urlError: underlying as? URLError)
    }
    if case OpenID4VCI.PostError.requestError(let code, _) = error {
      return make(source: .openID4VCI, statusCode: code, urlError: nil)
    }
    if case OpenID4VCI.FetchError.networkError(let underlying) = error {
      return make(source: .openID4VCI, statusCode: nil, urlError: underlying as? URLError)
    }
    if case OpenID4VCI.FetchError.invalidStatusCode(_, let code, _) = error {
      return make(source: .openID4VCI, statusCode: code, urlError: nil)
    }
    return nil
  }

  private static func walletBackend(_ error: Error) -> TransportFailure? {
    guard let networkError = error as? NetworkError else {
      return nil
    }
    switch networkError {
    case .internetFailure:
      return make(source: .walletBackend, statusCode: nil, urlError: networkError.transportCause)
    case .httpError(let code, _, _):
      return make(source: .walletBackend, statusCode: code, urlError: nil, retryAfter: networkError.retryAfter)
    default:
      return nil
    }
  }

  private static func bareURLError(_ error: Error) -> TransportFailure? {
    guard let urlError = error as? URLError else {
      return nil
    }
    return make(source: .unknown, statusCode: nil, urlError: urlError)
  }

  // MARK: - Shared classification

  static func make(
    source: Source,
    statusCode: Int?,
    urlError: URLError?,
    retryAfter: TimeInterval? = nil
  ) -> TransportFailure? {
    if let statusCode {
      switch statusCode {
      case 408, 504:
        return .init(kind: .timeout, source: source, statusCode: statusCode, retryAfter: retryAfter)
      case 429:
        return .init(kind: .rateLimited, source: source, statusCode: statusCode, retryAfter: retryAfter)
      default:
        return nil
      }
    }
    switch urlError?.code {
    case .timedOut:
      return .init(kind: .timeout, source: source)
    case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .networkConnectionLost:
      return .init(kind: .unreachable, source: source)
    default:
      return nil
    }
  }
}

extension TransportFailure: CustomStringConvertible {
  /// Don't include the  request URL.
  public var description: String {
    let status = statusCode.map { " status \($0)" } ?? ""
    return "TransportFailure \(kind.rawValue) via \(source.rawValue)\(status)"
  }
}
