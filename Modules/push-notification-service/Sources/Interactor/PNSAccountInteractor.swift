//
//  PNSAccountInteractor.swift
//  push-notification-service
//

import Foundation
import logic_api
import logic_business
import logic_feature_flags

public protocol PNSAccountInteractor: Sendable {
  /// Creates the PNS account, or refreshes the stored `mpp_registration_token` when the MPP rotated
  /// it or the periodic renewal is due. Does nothing when the account is already up to date.
  ///
  /// Never throws: push notifications are opt-in and best-effort, so a failure here must not affect
  /// the flow that triggered the sync. A Wallet Instance without a PNS account still learns of a
  /// revocation through the regular `mdvm_token` renewal.
  func syncAccountIfNeeded() async

  /// Records the `mpp_registration_token` the MPP just issued and syncs the account with it.
  func handleTokenUpdate(_ mppRegistrationToken: String) async
}

public actor PNSAccountInteractorImpl: PNSAccountInteractor {

  private enum SyncReason: String {
    case created
    case tokenRotated = "token rotated"
    case renewed
  }

  /// Fallback when the feature flag value cannot be parsed: the spec asks for a monthly renewal.
  private static let defaultRenewalIntervalMinutes = 30 * 24 * 60
  private static let minimumRenewalIntervalMinutes = 60

  private let repository: PNSRepository
  private let mdvmRepository: MDVMRepository
  private let authorizationProvider: PushAuthorizationProvider
  private let featureFlagRepository: FeatureFlagRepository
  private let logger: Logging?

  /// The most recent token the MPP handed over in this session. Falls back to the persisted one,
  /// which is what makes a start-up sync possible before the MPP has called back.
  private var latestToken: String?
  /// Chains syncs so a start-up sync and a concurrent token rotation cannot both register.
  private var syncTask: Task<Void, Never>?

  init(
    repository: PNSRepository,
    mdvmRepository: MDVMRepository,
    authorizationProvider: PushAuthorizationProvider,
    featureFlagRepository: FeatureFlagRepository,
    logger: Logging? = nil
  ) {
    self.repository = repository
    self.mdvmRepository = mdvmRepository
    self.authorizationProvider = authorizationProvider
    self.featureFlagRepository = featureFlagRepository
    self.logger = logger
  }

  public func syncAccountIfNeeded() async {
    let token = latestToken ?? repository.getStoredRegistration()?.mppRegistrationToken
    await enqueueSync(with: token)
  }

  public func handleTokenUpdate(_ mppRegistrationToken: String) async {
    latestToken = mppRegistrationToken
    await enqueueSync(with: mppRegistrationToken)
  }

  // MARK: - Sync

  private func enqueueSync(with mppRegistrationToken: String?) async {
    let previous = syncTask
    let task = Task { [weak self] in
      await previous?.value
      await self?.sync(with: mppRegistrationToken)
    }
    syncTask = task
    await task.value
  }

  private func sync(with mppRegistrationToken: String?) async {
    guard let mppRegistrationToken, !mppRegistrationToken.isEmpty else {
      logger?.d("[PNS] no mpp_registration_token yet, skipping account sync")
      return
    }
    guard await authorizationProvider.isAuthorized() else {
      logger?.d("[PNS] notifications are not authorized, skipping account sync")
      return
    }
    guard let mdvmRegistration = mdvmRepository.getStoredRegistration() else {
      logger?.d("[PNS] wallet instance is not registered at the MDVM yet, skipping account sync")
      return
    }
    guard let reason = await syncReason(for: mppRegistrationToken) else {
      return
    }

    do {
      let challenge = try await repository.fetchChallenge()
      try await repository.register(
        mppRegistrationToken: mppRegistrationToken,
        mdvmToken: mdvmRegistration.mdvmToken,
        authChallenge: challenge
      )
      repository.storeRegistration(
        PNSStoredRegistration(mppRegistrationToken: mppRegistrationToken, registeredAt: Date())
      )
      logger?.d("[PNS] account synced: \(reason.rawValue)")
    } catch let error as BackendError {
      logger?.e("[PNS] account sync failed: code=\(error.errorCode) traceId=\(error.traceId)")
    } catch {
      logger?.e("[PNS] account sync failed: \(error.logDescriptor)")
    }
  }

  /// Returns why a sync is needed, or `nil` when the stored registration is still current. Skipping
  /// the call is the point: it avoids reaching out to the MPP and the PNS on every start-up.
  private func syncReason(for mppRegistrationToken: String) async -> SyncReason? {
    guard let stored = repository.getStoredRegistration() else {
      return .created
    }
    if stored.mppRegistrationToken != mppRegistrationToken {
      return .tokenRotated
    }
    if stored.isOlderThan(await renewalInterval()) {
      return .renewed
    }
    return nil
  }

  private func renewalInterval() async -> TimeInterval {
    let duration: String = await featureFlagRepository.getFlagValue(.pnsAccountRenewalInterval)
    let minutes = duration.minutesFromISO8601DurationString() ?? Self.defaultRenewalIntervalMinutes
    return TimeInterval(max(Self.minimumRenewalIntervalMinutes, minutes) * 60)
  }
}
