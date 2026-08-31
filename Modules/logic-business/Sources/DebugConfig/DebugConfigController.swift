//
//  DebugConfigController.swift
//  logic-business
//

import Foundation

/// Developer-only config overrides for the DEV/SANDBOX apps, applied on the next app launch.
/// Everything lives in the keychain: writes are synchronous, so they survive the exit(0)
/// that applies a new configuration (UserDefaults flushes asynchronously and can lose them)
public protocol DebugConfigController: Sendable {
  var overrides: DebugConfigOverrides { get }
  func store(_ overrides: DebugConfigOverrides)
  func clearAll()
}

public final class DebugConfigControllerImpl: DebugConfigController {

  private let keyChainController: KeyChainController
  private let buildVariant: AppBuildVariant

  public convenience init(keyChainController: KeyChainController) {
    self.init(keyChainController: keyChainController, buildVariant: .current)
  }

  init(keyChainController: KeyChainController, buildVariant: AppBuildVariant) {
    self.keyChainController = keyChainController
    self.buildVariant = buildVariant
  }

  public var overrides: DebugConfigOverrides {
    guard isAvailable else {
      return .init()
    }
    return .init(
      walletHostURL: value(for: .debugConfigWalletHostURL),
      walletAPIKey: value(for: .debugConfigWalletAPIKey),
      otlpHostURL: value(for: .debugConfigOTLPHostURL),
      otlpAuthToken: value(for: .debugConfigOTLPAuthToken),
      pidProviderURL: value(for: .debugConfigPIDProviderURL)
    )
  }

  public func store(_ overrides: DebugConfigOverrides) {
    guard isAvailable else {
      return
    }
    set(.debugConfigWalletHostURL, to: overrides.walletHostURL)
    set(.debugConfigWalletAPIKey, to: overrides.walletAPIKey)
    set(.debugConfigOTLPHostURL, to: overrides.otlpHostURL)
    set(.debugConfigOTLPAuthToken, to: overrides.otlpAuthToken)
    set(.debugConfigPIDProviderURL, to: overrides.pidProviderURL)
  }

  public func clearAll() {
    store(.init())
  }

  private var isAvailable: Bool {
    [.DEV, .SANDBOX].contains(buildVariant)
  }

  private func value(for key: KeyChainIdentifier) -> String? {
    keyChainController.getValue(key: key)
  }

  private func set(_ key: KeyChainIdentifier, to value: String?) {
    if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
      keyChainController.storeValue(key: key, value: value)
    } else {
      keyChainController.removeObject(key: key)
    }
  }
}
