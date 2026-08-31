//
//  NetworkRequest.swift
//  logic-api
//

import struct Foundation.Data

public protocol NetworkRequest {

  associatedtype Response

  var method: NetworkMethod { get }
  var path: String { get set }
  var additionalHeaders: [String: String] { get set }
  var body: Data? { get }
  var baseURL: String? { get }
  /// Set `false` for unauthenticated endpoints; otherwise NetworkManager injects `X-Auth-Token` from `API_KEY`.
  var requiresAuthToken: Bool { get }
  /// Add extra env-backed auth values (e.g. feature-flag `apiKey` query) beyond the default token behavior.
  var credentials: [NetworkRequestCredential] { get }
}

extension NetworkRequest {
  public var method: NetworkMethod { .GET }
  public var body: Data? { nil }
  public var requiresAuthToken: Bool { true }
  public var credentials: [NetworkRequestCredential] { [] }
}
