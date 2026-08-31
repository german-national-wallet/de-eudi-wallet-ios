//
//  FeatureFlag.swift
//  logic-feature-flag
//

import Foundation

public struct FeatureFlag<T: Sendable>: Sendable {
  public let key: String
  public let defaultValue: T

  public init(key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }
}

public extension FeatureFlag where T == String {

  /// Uses an ISO 8601 temporal duration string
  /// https://tc39.es/proposal-temporal/docs/duration.html
  static let mdvmTokenFreshnessBuffer: FeatureFlag<String> = .init(
    key: "mdvm_token_freshness_buffer",
    defaultValue: "PT10M"
  )

  /// How long a `mpp_registration_token` stored at the PNS may go without a refresh. Keeps the
  /// token from becoming stale while avoiding calls to the MPP and the PNS on every start-up.
  /// Uses an ISO 8601 temporal duration string
  /// https://tc39.es/proposal-temporal/docs/duration.html
  static let pnsAccountRenewalInterval: FeatureFlag<String> = .init(
    key: "pns_account_renewal_interval",
    defaultValue: "P30D"
  )

  /// Controls minimum app version using a semantic version string
  /// https://semver.org/
  static let minimumAppVersion: FeatureFlag<String> = .init(
    key: "minimum_app_version",
    defaultValue: "0.0.0"
  )

  /// Issuer credential-configuration identifier for the mso_mdoc PID credential.
  /// The server value is preferred; `fallback` (the hardcoded/xcconfig value) is used when absent.
  static func pidMsoMdocConfigId(fallback: String) -> FeatureFlag<String> {
    .init(
      key: "credential_configuration_id_mdoc",
      defaultValue: fallback
    )
  }

  /// Issuer credential-configuration identifier for the SD-JWT PID credential.
  /// The server value is preferred; `fallback` (the hardcoded/xcconfig value) is used when absent.
  static func pidSdJwtConfigId(fallback: String) -> FeatureFlag<String> {
    .init(
      key: "credential_configuration_id_sdjwt",
      defaultValue: fallback
    )
  }
}
