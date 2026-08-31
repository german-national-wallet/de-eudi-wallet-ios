//
//  FlagStore.swift
//  logic-feature-flag
//

import Foundation
import logic_business

protocol FlagStore: Sendable {

  /// Returns the resolved flag value from memory, or the default when unavailable.
  func getFlagValue<T>(_ flag: FeatureFlag<T>) async -> T

  func isStale(maxAgeHours: Int) async -> Bool

  /// Replaces the in-memory flags and the cached payload with the values parsed from a payload.
  func replaceFlags(from payload: String) async throws
}

actor FlagStoreImpl: FlagStore {

  private lazy var isoDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private var rawFlags: [String: FlagValue] = [:]
  private let prefsController: PrefsController
  private let logger: Logging?

  init(prefsController: PrefsController, logger: Logging?) {
    self.prefsController = prefsController
    self.logger = logger

    do {
      rawFlags = try FlagValue.decodeAll(from: prefsController.getOptionalString(forKey: .featureFlagsPayload))
    } catch {
      logger?.e("Feature flags payload decoding failed: \(error.logDescriptor)")
      rawFlags = [:]
    }
  }

  func getFlagValue<T>(_ flag: FeatureFlag<T>) async -> T {
    guard let converted = rawFlags[flag.key]?.converted(to: T.self) else {
      return flag.defaultValue
    }
    return converted
  }

  func isStale(maxAgeHours: Int) async -> Bool {
    let lastUpdateValue = prefsController.getOptionalString(forKey: .featureFlagsLastUpdate)
    guard !lastUpdateValue.isEmpty, let lastUpdate = isoDateFormatter.date(from: lastUpdateValue) else {
      return true
    }
    return Date().timeIntervalSince(lastUpdate) > TimeInterval(maxAgeHours * 3600)
  }

  func replaceFlags(from payload: String) async throws {
    rawFlags = try FlagValue.decodeAll(from: payload)
    prefsController.setValue(isoDateFormatter.string(from: Date()), forKey: .featureFlagsLastUpdate)

    guard !rawFlags.isEmpty else {
      prefsController.remove(forKey: .featureFlagsPayload)
      return
    }
    prefsController.setValue(payload, forKey: .featureFlagsPayload)
  }
}
