//
//  WalletRevocationInteractorTests.swift
//  logic-core
//

import Foundation
import Testing

@testable import logic_core
@testable import logic_api
@testable import logic_business

struct WalletRevocationInteractorTests {

  // MARK: - Confirmation

  @Test
  func confirmRevocation_WhenMDVMAnswersRevoked_MarksTheWalletRevoked() async {
    let prefs = FakePrefsController()
    let renewal = FakeRenewalService(
      error: BackendError.serverError(code: MDVMServerErrorCode.revoked, description: "revoked", traceID: "t-1")
    )
    let sut = makeSUT(renewal: renewal, prefs: prefs)

    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked)
    #expect(renewal.callCount == 1)
  }

  @Test
  func confirmRevocation_WhenRenewalFailsWithANetworkError_DoesNotLock() async {
    /// The document is explicit: only the REVOKED answer confirms a revocation, never a transient
    /// failure. Locking here would brick a perfectly valid wallet whenever the network is down.
    let sut = makeSUT(renewal: FakeRenewalService(error: BackendError.unknown))

    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked == false)
  }

  @Test
  func confirmRevocation_WhenRenewalFailsWithAnotherServerError_DoesNotLock() async {
    let sut = makeSUT(
      renewal: FakeRenewalService(
        error: BackendError.serverError(code: "IOS_ATTESTATION_FAILURE", description: "nope", traceID: "t-2")
      )
    )

    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked == false)
  }

  @Test
  func confirmRevocation_WhenThereIsNoRegistration_DoesNotLock() async {
    let sut = makeSUT(renewal: FakeRenewalService(error: BackendError.notRegistered))

    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked == false)
  }

  // MARK: - Propagation race

  @Test
  func confirmRevocation_WhenRenewalKeepsSucceeding_DoesNotLockAndRetriesOnce() async {
    let renewal = FakeRenewalService(error: nil)
    let sut = makeSUT(renewal: renewal)

    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked == false)
    /// A user-initiated revocation may not have reached the MDVM yet, so one retry is expected.
    #expect(renewal.callCount == 2)
  }

  @Test
  func confirmRevocation_WhenRevocationPropagatesOnTheRetry_Locks() async {
    let renewal = FakeRenewalService(
      errorsInOrder: [
        nil,
        BackendError.serverError(code: MDVMServerErrorCode.revoked, description: "revoked", traceID: "t-3")
      ]
    )
    let sut = makeSUT(renewal: renewal)

    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked)
    #expect(renewal.callCount == 2)
  }

  // MARK: - Already revoked

  @Test
  func confirmRevocation_WhenAlreadyRevoked_DoesNotCallTheBackendAgain() async {
    let prefs = FakePrefsController()
    prefs.setValue(true, forKey: .walletRevoked)
    let renewal = FakeRenewalService(error: nil)
    let sut = makeSUT(renewal: renewal, prefs: prefs)

    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked)
    /// Re-announced so the lock is applied even if the app was killed before it could be shown,
    /// but the MDVM must not be contacted again while the wallet is already known to be revoked.
    #expect(renewal.callCount == 0)
  }

  @Test
  func isWalletRevoked_WhenFlagWasPersistedEarlier_SurvivesANewInstance() async {
    let prefs = FakePrefsController()
    let renewal = FakeRenewalService(
      error: BackendError.serverError(code: MDVMServerErrorCode.revoked, description: "revoked", traceID: "t-4")
    )
    await makeSUT(renewal: renewal, prefs: prefs).confirmRevocation()

    /// A fresh interactor over the same storage still reports the wallet as revoked, which is what
    /// keeps the lock in place across relaunches.
    #expect(makeSUT(renewal: FakeRenewalService(error: nil), prefs: prefs).isWalletRevoked)
  }

  // MARK: - Reset

  @Test
  func resetAfterRevocation_ClearsTheLockSoTheWalletCanBeSetUpAgain() async {
    let prefs = FakePrefsController()
    let renewal = FakeRenewalService(
      error: BackendError.serverError(code: MDVMServerErrorCode.revoked, description: "revoked", traceID: "t-5")
    )
    let sut = makeSUT(renewal: renewal, prefs: prefs)
    await sut.confirmRevocation()
    #expect(sut.isWalletRevoked)

    sut.resetAfterRevocation()

    #expect(sut.isWalletRevoked == false)
    /// A fresh instance over the same storage must agree, otherwise the lock would come back on the
    /// next launch and the user could never get out of it.
    #expect(makeSUT(renewal: FakeRenewalService(error: nil), prefs: prefs).isWalletRevoked == false)
  }

  @Test
  func resetAfterRevocation_ClearsTheLocalTracesAFreshInstallWouldNotHave() async {
    let prefs = FakePrefsController()
    prefs.setValue("installation-id", forKey: .mdvmInstallationIdentifier)
    prefs.setValue(true, forKey: .biometryEnabled)
    prefs.setValue(true, forKey: .hasSeenRevocationCode)
    let sut = makeSUT(renewal: FakeRenewalService(error: nil), prefs: prefs)

    sut.resetAfterRevocation()

    #expect(prefs.getString(forKey: .mdvmInstallationIdentifier) == nil)
    #expect(prefs.getBool(forKey: .biometryEnabled) == false)
    /// Re-shown for the new Wallet Instance, which gets its own revocation code.
    #expect(prefs.getBool(forKey: .hasSeenRevocationCode) == false)
  }

  @Test
  func confirmRevocation_AfterAReset_CanLockAgain() async {
    let prefs = FakePrefsController()
    let renewal = FakeRenewalService(
      error: BackendError.serverError(code: MDVMServerErrorCode.revoked, description: "revoked", traceID: "t-6")
    )
    let sut = makeSUT(renewal: renewal, prefs: prefs)
    await sut.confirmRevocation()
    sut.resetAfterRevocation()

    /// The reset must not make the app immune to a later revocation of the new Wallet Instance.
    await sut.confirmRevocation()

    #expect(sut.isWalletRevoked)
  }

  // MARK: - Helpers

  private func makeSUT(
    renewal: FakeRenewalService,
    prefs: FakePrefsController = FakePrefsController()
  ) -> WalletRevocationInteractorImpl {
    WalletRevocationInteractorImpl(
      renewalService: renewal,
      store: WalletRevocationStoreImpl(prefsController: prefs, logger: nil),
      prefsController: prefs,
      logger: nil
    )
  }
}

private final class FakeRenewalService: MDVMTokenRenewalService, @unchecked Sendable {
  private var errorsInOrder: [Error?]
  private(set) var callCount = 0

  init(error: Error?) {
    self.errorsInOrder = [error]
  }

  init(errorsInOrder: [Error?]) {
    self.errorsInOrder = errorsInOrder
  }

  func renewMDVMTokenIgnoringFreshness() async throws {
    let error = callCount < errorsInOrder.count ? errorsInOrder[callCount] : errorsInOrder.last ?? nil
    callCount += 1
    if let error {
      throw error
    }
  }
}

private final class FakePrefsController: PrefsController, @unchecked Sendable {
  private var storage: [String: Any] = [:]

  func setValue(_ value: Any?, forKey key: Prefs.Key) { storage[key.rawValue] = value }
  func getString(forKey key: Prefs.Key) -> String? { storage[key.rawValue] as? String }
  func getOptionalString(forKey key: Prefs.Key) -> String { getString(forKey: key) ?? "" }
  func getBool(forKey key: Prefs.Key) -> Bool { storage[key.rawValue] as? Bool ?? false }
  func getFloat(forKey key: Prefs.Key) -> Float { storage[key.rawValue] as? Float ?? 0 }
  func getInt(forKey key: Prefs.Key) -> Int { storage[key.rawValue] as? Int ?? 0 }
  func remove(forKey key: Prefs.Key) { storage.removeValue(forKey: key.rawValue) }
  func getValue(forKey key: Prefs.Key) -> Any? { storage[key.rawValue] }
  func getUserLocale() -> String { "en_GB" }
  func fetchAndDeleteValue(forKey key: Prefs.Key) -> Any? {
    let value = storage[key.rawValue]
    remove(forKey: key)
    return value
  }
  func saveObject<T: Encodable>(_ object: T, forKey key: Prefs.Key) {
    storage[key.rawValue] = try? JSONEncoder().encode(object)
  }
  func getObject<T: Decodable>(forKey key: Prefs.Key, as type: T.Type) -> T? {
    guard let data = storage[key.rawValue] as? Data else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
  }
}
