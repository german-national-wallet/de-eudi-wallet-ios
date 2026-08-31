//
//  AppBlockingController.swift
//  AppBlockingController
//

import Foundation
import LocalAuthentication
import logic_business
import logic_feature_flags

public protocol AppBlockingController: Sendable {
  var appUpdateURL: URL? { get }

  func blockingState(for rules: Set<AppBlockingRule>) async -> AppBlockingState?
  func refreshFeatureFlagsIfNeeded() async
}

public enum AppBlockingState: Equatable, Sendable {
  case walletRevoked
  case platformAuthentication
  case minimumAppVersion
}

public enum AppBlockingRule: Hashable, Sendable {
  case walletRevoked
  case platformAuthentication
  case minimumAppVersion
}

public struct AppBlockingControllerImpl: AppBlockingController {

  private let configLogic: ConfigLogic
  private let featureFlagRepository: FeatureFlagRepository
  private let prefsController: PrefsController

  public var appUpdateURL: URL? {
    guard
      let value = "APP_UPDATE_URL".optionalValueFromBundle,
      let url = URL(string: value)
    else {
      return nil
    }
    return url
  }

  public init(
    configLogic: ConfigLogic,
    featureFlagRepository: FeatureFlagRepository,
    prefsController: PrefsController
  ) {
    self.configLogic = configLogic
    self.featureFlagRepository = featureFlagRepository
    self.prefsController = prefsController
  }

  public func blockingState(for rules: Set<AppBlockingRule>) async -> AppBlockingState? {
    if rules.contains(.walletRevoked), isWalletRevoked() {
      return .walletRevoked
    }
    if rules.contains(.platformAuthentication), isPlatformAuthenticationNotEnabled() {
      return .platformAuthentication
    }
    if rules.contains(.minimumAppVersion), await isMinimumAppVersionBlocked() {
      return .minimumAppVersion
    }
    return nil
  }

  public func refreshFeatureFlagsIfNeeded() async {
    await featureFlagRepository.refreshFlagsIfNeeded()
  }

  private func isWalletRevoked() -> Bool {
    prefsController.getBool(forKey: .walletRevoked)
  }

  private func isPlatformAuthenticationNotEnabled() -> Bool {
    let context = LAContext()
    var error: NSError?

    return !context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
  }

  private func isMinimumAppVersionBlocked() async -> Bool {
    let minimumAppVersion = await featureFlagRepository.getFlagValue(.minimumAppVersion)
    guard
      let currentVersion = SemanticVersion(configLogic.appVersion),
      let requiredVersion = SemanticVersion(minimumAppVersion)
    else {
      return false
    }
    return currentVersion < requiredVersion
  }
}
