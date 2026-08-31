//
//  NetworkRequestCredential.swift
//  logic-api
//

/// Defines an env-backed value that NetworkManager injects into a header or query item.
public enum NetworkRequestCredential: Sendable {
  case header(name: String, envKey: String)
  case query(name: String, envKey: String)
}
