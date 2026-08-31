/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation

public enum AppBuildType: String, @unchecked Sendable {
  case RELEASE, DEBUG
}

public enum AppBuildVariant: String, @unchecked Sendable {
  case DEV, SANDBOX, STAGING

  public static var current: AppBuildVariant {
    guard let variant = AppBuildVariant(rawValue: "Build Variant".valueFromBundle) else {
      /// Unknown variants should never expose debug features (debug config, log file, menu items) or disable log redaction
      return .STAGING
    }
    return variant
  }

  public var emitsDebugLogs: Bool {
    [.DEV, .SANDBOX].contains(self)
  }
}

public protocol ConfigLogic: Sendable {

  /**
   * Wallet base url for direct network operation.
   */
  var walletHostUrl: String { get }

  /**
   * Build type.
   */
  var appBuildType: AppBuildType { get }

  /**
   * Build Variant.
   */
  var appBuildVariant: AppBuildVariant { get }

  /**
   * App version.
   */
  var appVersion: String { get }

  /**
   * Changelog URL
   */
  var changelogUrl: URL? { get }

  var vciIssuerName: String? { get }

  var vciIssuerURL: String? { get }

  var walletOTLPURL: String { get }

  /**
   * Issuer credential-configuration identifier for the mso_mdoc PID credential.
   */
  var pidMsoMdocConfigId: String { get }

  /**
   * Issuer credential-configuration identifier for the SD-JWT PID credential.
   */
  var pidSdJwtConfigId: String { get }
}

public struct ConfigLogicImpl: ConfigLogic {

  private let debugOverrides: DebugConfigOverrides

  public var walletHostUrl: String {
    debugOverrides.walletHostURL ?? getBundleValue(key: "WALLET_HOST_URL")
  }

  public var walletOTLPURL: String {
    debugOverrides.otlpHostURL ?? getBundleValue(key: "WALLET_OTLP_HOST_URL")
  }

  public var vciIssuerName: String? {
    /// wallet-kit resolves its VCI service by the issuer URL's host, so the name must follow the override
    if let pidProviderURL = debugOverrides.pidProviderURL {
      return URL(string: pidProviderURL)?.host
    }
    return getBundleValue(key: "PID_ISSUER_NAME")
  }

  public var vciIssuerURL: String? {
    debugOverrides.pidProviderURL ?? getBundleValue(key: "VCI_ISSUER_URL")
  }

  public var pidMsoMdocConfigId: String {
    getBundleNullableValue(key: "PID_MSO_MDOC_CONFIG_ID") ?? "pid-mso-mdoc"
  }

  public var pidSdJwtConfigId: String {
    getBundleNullableValue(key: "PID_SD_JWT_CONFIG_ID") ?? "pid-sd-jwt"
  }

  public var appBuildType: AppBuildType {
    getBuildType()
  }

  public var appVersion: String {
    getBundleValue(key: "CFBundleShortVersionString")
  }

  public var appBuildVariant: AppBuildVariant {
    getBuildVariant()
  }

  public var changelogUrl: URL? {
    guard
      let value = getBundleNullableValue(key: "Changelog Url"),
      let url = URL(string: value)
    else {
      return nil
    }
    return url
  }

  public init(debugConfigController: DebugConfigController) {
    self.debugOverrides = debugConfigController.overrides
  }
}
