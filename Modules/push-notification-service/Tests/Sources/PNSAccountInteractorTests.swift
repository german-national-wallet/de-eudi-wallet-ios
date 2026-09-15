//
//  PNSAccountInteractorTests.swift
//  push-notification-service
//

import Foundation
import Security
import Testing

@testable import push_notification_service
@testable import logic_api
@testable import logic_business
@testable import logic_feature_flags

struct PNSAccountInteractorTests {

  // MARK: - handleTokenUpdate

  @Test
  func handleTokenUpdate_WhenNoAccountExists_FetchesChallengeRegistersAndStores() async {
    let repository = FakePNSRepository()
    let sut = makeSUT(repository: repository)

    await sut.handleTokenUpdate("mpp-token")

    #expect(repository.challengeCallCount == 1)
    #expect(repository.registerCalls.count == 1)
    #expect(repository.registerCalls.first?.mppRegistrationToken == "mpp-token")
    #expect(repository.registerCalls.first?.mdvmToken == "mdvm-token")
    #expect(repository.registerCalls.first?.authChallenge == "pns-challenge")
    #expect(repository.stored?.mppRegistrationToken == "mpp-token")
  }

  @Test
  func handleTokenUpdate_WhenTokenIsUnchangedAndFresh_DoesNotCallTheBackend() async {
    let repository = FakePNSRepository()
    repository.stored = PNSStoredRegistration(mppRegistrationToken: "mpp-token", registeredAt: Date())
    let sut = makeSUT(repository: repository)

    await sut.handleTokenUpdate("mpp-token")

    #expect(repository.challengeCallCount == 0)
    #expect(repository.registerCalls.isEmpty)
  }

  @Test
  func handleTokenUpdate_WhenPlatformRotatedTheToken_RegistersTheNewToken() async {
    let repository = FakePNSRepository()
    repository.stored = PNSStoredRegistration(mppRegistrationToken: "old-token", registeredAt: Date())
    let sut = makeSUT(repository: repository)

    await sut.handleTokenUpdate("rotated-token")

    #expect(repository.registerCalls.count == 1)
    #expect(repository.registerCalls.first?.mppRegistrationToken == "rotated-token")
    #expect(repository.stored?.mppRegistrationToken == "rotated-token")
  }

  @Test
  func handleTokenUpdate_WhenTokenIsEmpty_DoesNothing() async {
    let repository = FakePNSRepository()
    let sut = makeSUT(repository: repository)

    await sut.handleTokenUpdate("")

    #expect(repository.registerCalls.isEmpty)
  }

  @Test
  func handleTokenUpdate_WhenNotificationsAreNotAuthorized_DoesNothing() async {
    let repository = FakePNSRepository()
    let sut = makeSUT(repository: repository, isAuthorized: false)

    await sut.handleTokenUpdate("mpp-token")

    #expect(repository.registerCalls.isEmpty)
    #expect(repository.stored == nil)
  }

  @Test
  func handleTokenUpdate_WhenWalletIsNotRegisteredAtTheMDVM_DoesNothing() async {
    let repository = FakePNSRepository()
    let mdvm = FakeMDVMRepository(storedRegistration: nil)
    let sut = makeSUT(repository: repository, mdvmRepository: mdvm)

    await sut.handleTokenUpdate("mpp-token")

    #expect(repository.registerCalls.isEmpty)
    #expect(repository.stored == nil)
  }

  @Test
  func handleTokenUpdate_WhenRegisterFails_DoesNotStoreAndDoesNotThrow() async {
    let repository = FakePNSRepository()
    repository.registerError = PNSRepositoryError.serverError(code: "PNS_ERR", description: "no", traceID: "t-1")
    let sut = makeSUT(repository: repository)

    await sut.handleTokenUpdate("mpp-token")

    #expect(repository.stored == nil)
  }

  @Test
  func handleTokenUpdate_WhenChallengeFails_DoesNotRegisterAndDoesNotThrow() async {
    let repository = FakePNSRepository()
    repository.challengeError = PNSRepositoryError.invalidResponse
    let sut = makeSUT(repository: repository)

    await sut.handleTokenUpdate("mpp-token")

    #expect(repository.registerCalls.isEmpty)
    #expect(repository.stored == nil)
  }

  // MARK: - syncAccountIfNeeded

  @Test
  func syncAccountIfNeeded_WhenNoTokenIsKnown_DoesNothing() async {
    let repository = FakePNSRepository()
    let sut = makeSUT(repository: repository)

    await sut.syncAccountIfNeeded()

    #expect(repository.challengeCallCount == 0)
    #expect(repository.registerCalls.isEmpty)
  }

  @Test
  func syncAccountIfNeeded_WhenRenewalIsDue_RefreshesTheStoredToken() async {
    let repository = FakePNSRepository()
    /// 40 days old against the default P30D renewal interval.
    repository.stored = PNSStoredRegistration(
      mppRegistrationToken: "mpp-token",
      registeredAt: Date(timeIntervalSinceNow: -40 * 24 * 60 * 60)
    )
    let sut = makeSUT(repository: repository)

    await sut.syncAccountIfNeeded()

    #expect(repository.registerCalls.count == 1)
    #expect(repository.registerCalls.first?.mppRegistrationToken == "mpp-token")
    #expect(repository.stored?.isOlderThan(24 * 60 * 60) == false)
  }

  @Test
  func syncAccountIfNeeded_WhenRenewalIsNotDueYet_DoesNotCallTheBackend() async {
    let repository = FakePNSRepository()
    repository.stored = PNSStoredRegistration(
      mppRegistrationToken: "mpp-token",
      registeredAt: Date(timeIntervalSinceNow: -20 * 24 * 60 * 60)
    )
    let sut = makeSUT(repository: repository)

    await sut.syncAccountIfNeeded()

    #expect(repository.registerCalls.isEmpty)
  }

  @Test
  func syncAccountIfNeeded_UsesTheRenewalIntervalFromTheFeatureFlag() async {
    let repository = FakePNSRepository()
    repository.stored = PNSStoredRegistration(
      mppRegistrationToken: "mpp-token",
      registeredAt: Date(timeIntervalSinceNow: -2 * 24 * 60 * 60)
    )
    /// Two days old is fresh under P30D, but stale under P1D.
    let sut = makeSUT(repository: repository, renewalInterval: "P1D")

    await sut.syncAccountIfNeeded()

    #expect(repository.registerCalls.count == 1)
  }

  @Test
  func syncAccountIfNeeded_AfterATokenUpdate_UsesTheTokenFromThisSession() async {
    let repository = FakePNSRepository()
    let sut = makeSUT(repository: repository)

    await sut.handleTokenUpdate("session-token")
    await sut.syncAccountIfNeeded()

    /// The second call finds the account already current, so it must not register again.
    #expect(repository.registerCalls.count == 1)
    #expect(repository.registerCalls.first?.mppRegistrationToken == "session-token")
  }

  @Test
  func concurrentSyncs_RegisterOnlyOnce() async {
    let repository = FakePNSRepository()
    let sut = makeSUT(repository: repository)

    /// A start-up sync and a token rotation can land at the same time; syncs are chained so the
    /// second one sees the account the first one created.
    async let first: Void = sut.handleTokenUpdate("mpp-token")
    async let second: Void = sut.handleTokenUpdate("mpp-token")
    _ = await (first, second)

    #expect(repository.registerCalls.count == 1)
  }

  // MARK: - Helpers

  private func makeSUT(
    repository: FakePNSRepository = FakePNSRepository(),
    mdvmRepository: FakeMDVMRepository = FakeMDVMRepository(
      storedRegistration: MDVMStoredRegistration(mdvmWIID: "mdvm-wi-id", mdvmToken: "mdvm-token")
    ),
    isAuthorized: Bool = true,
    renewalInterval: String = "P30D"
  ) -> PNSAccountInteractorImpl {
    PNSAccountInteractorImpl(
      repository: repository,
      mdvmRepository: mdvmRepository,
      authorizationProvider: FakePushAuthorizationProvider(isAuthorizedValue: isAuthorized),
      featureFlagRepository: FakeFeatureFlagRepository(stringValue: renewalInterval)
    )
  }
}

private final class FakePNSRepository: PNSRepository, @unchecked Sendable {
  struct RegisterCall: Equatable {
    let mppRegistrationToken: String
    let mdvmToken: String
    let authChallenge: String
  }

  var stored: PNSStoredRegistration?
  var challenge = "pns-challenge"
  var challengeError: Error?
  var registerError: Error?
  private(set) var challengeCallCount = 0
  private(set) var registerCalls: [RegisterCall] = []

  func fetchChallenge() async throws -> String {
    challengeCallCount += 1
    if let challengeError { throw challengeError }
    return challenge
  }

  func register(mppRegistrationToken: String, mdvmToken: String, authChallenge: String) async throws {
    registerCalls.append(
      RegisterCall(
        mppRegistrationToken: mppRegistrationToken,
        mdvmToken: mdvmToken,
        authChallenge: authChallenge
      )
    )
    if let registerError { throw registerError }
  }

  func getStoredRegistration() -> PNSStoredRegistration? { stored }
  func storeRegistration(_ registration: PNSStoredRegistration) { stored = registration }
  func deleteStoredRegistration() { stored = nil }
}

private final class FakeMDVMRepository: MDVMRepository, @unchecked Sendable {
  private let storedRegistration: MDVMStoredRegistration?

  init(storedRegistration: MDVMStoredRegistration?) {
    self.storedRegistration = storedRegistration
  }

  func getStoredRegistration() -> MDVMStoredRegistration? { storedRegistration }
  func fetchChallenge() async throws -> String { "mdvm-challenge" }
  func register(
    payload: MDVMRegistrationPayload,
    authChallenge: String,
    skipIntegrityChecks: Bool,
    privateKey: SecKey
  ) async throws {}
  func renew(
    payload: MDVMRenewalPayload,
    mdvmWIID: String,
    authChallenge: String,
    skipIntegrityChecks: Bool,
    privateKey: SecKey
  ) async throws {}
}

private struct FakePushAuthorizationProvider: PushAuthorizationProvider {
  let isAuthorizedValue: Bool

  func isAuthorized() async -> Bool { isAuthorizedValue }
}

private struct FakeFeatureFlagRepository: FeatureFlagRepository {
  let stringValue: String

  func getFlagValue<T>(_ flag: FeatureFlag<T>) async -> T {
    (stringValue as? T) ?? flag.defaultValue
  }

  func refreshFlagsIfNeeded() async {}
}
