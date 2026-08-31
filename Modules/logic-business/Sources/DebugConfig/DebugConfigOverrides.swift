//
//  DebugConfigOverrides.swift
//  logic-business
//

import Foundation

public struct DebugConfigOverrides: Equatable, Sendable {
  public let walletHostURL: String?
  public let walletAPIKey: String?
  public let otlpHostURL: String?
  public let otlpAuthToken: String?
  public let pidProviderURL: String?

  public init(
    walletHostURL: String? = nil,
    walletAPIKey: String? = nil,
    otlpHostURL: String? = nil,
    otlpAuthToken: String? = nil,
    pidProviderURL: String? = nil
  ) {
    self.walletHostURL = walletHostURL
    self.walletAPIKey = walletAPIKey
    self.otlpHostURL = otlpHostURL
    self.otlpAuthToken = otlpAuthToken
    self.pidProviderURL = pidProviderURL
  }

  public var hasOverrides: Bool {
    [walletHostURL, walletAPIKey, otlpHostURL, otlpAuthToken, pidProviderURL]
      .contains { $0 != nil }
  }
}
