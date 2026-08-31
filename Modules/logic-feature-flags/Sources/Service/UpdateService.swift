//
//  UpdateService.swift
//  logic-feature-flag
//

import Foundation
import logic_business
import logic_api

protocol UpdateService: Sendable {
  func refreshFlagsIfNeeded() async
}

struct UpdateServiceImpl: UpdateService {

  private let logger: Logging?
  private let networkManager: any NetworkManager
  private let store: FlagStore

  init(logger: Logging?, networkManager: any NetworkManager, store: FlagStore) {
    self.logger = logger
    self.networkManager = networkManager
    self.store = store
  }

  func refreshFlagsIfNeeded() async {
    guard await store.isStale(maxAgeHours: Constants.Cache.maxAgeHours) else {
      return
    }
    do {
      try await store.replaceFlags(from: fetchFeatureFlags())
    } catch {
      logger?.e("Feature flag refresh failed: \(error.logDescriptor)")
    }
  }

  private func fetchFeatureFlags() async throws -> String {
    let result = try await networkManager.execute(with: FeatureFlagFetchRequest(), parameters: nil)
    guard let data = result.data else {
      throw FlagError.invalidResponse
    }
    guard let payload = String(data: data, encoding: .utf8) else {
      throw FlagError.invalidPayload
    }
    return payload
  }
}
