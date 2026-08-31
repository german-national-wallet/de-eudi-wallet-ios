//
//  FeatureFlagRepository.swift
//  logic-feature-flag
//

import Foundation
import logic_business
import logic_api

public protocol FeatureFlagRepository: Sendable {

  /// Returns a server-provided flag value when present; otherwise returns the flag's default value.
  func getFlagValue<T>(_ flag: FeatureFlag<T>) async -> T

  /// Fetches flags when the cached payload is missing or stale, otherwise does nothing.
  func refreshFlagsIfNeeded() async
}

public struct FeatureFlagRepositoryImpl: FeatureFlagRepository {

  private let store: FlagStore
  private let updateService: UpdateService

  public init(prefsController: PrefsController, logger: Logging?) {
    self.init(
      prefsController: prefsController,
      logger: logger,
      networkManager: NetworkManagerImpl(
        baseHost: Constants.API.baseURLKey.valueFromBundle,
        logger: logger
      )
    )
  }

  init(
    prefsController: PrefsController,
    logger: Logging?,
    networkManager: any NetworkManager
  ) {
    let store = FlagStoreImpl(prefsController: prefsController, logger: logger)
    self.store = store
    self.updateService = UpdateServiceImpl(
      logger: logger,
      networkManager: networkManager,
      store: store
    )
  }

  public func getFlagValue<T>(_ flag: FeatureFlag<T>) async -> T {
    await store.getFlagValue(flag)
  }

  public func refreshFlagsIfNeeded() async {
    await updateService.refreshFlagsIfNeeded()
  }
}

public extension FeatureFlagRepository {

  /// Returns the resolved string flag value, but treats a blank (empty or whitespace-only)
  /// server value as absent and returns the flag's default (i.e. the caller's fallback) instead.
  ///
  /// `getFlagValue` alone only falls back when the key is missing or conversion fails; a flag
  /// that exists with a blank string would otherwise resolve to `""`. Callers that need a
  /// meaningful non-blank value (e.g. a credential-configuration id) should use this.
  func getNonBlankStringValue(_ flag: FeatureFlag<String>) async -> String {
    let resolved = await getFlagValue(flag)
    return resolved.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? flag.defaultValue : resolved
  }
}
