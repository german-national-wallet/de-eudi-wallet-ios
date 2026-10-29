//
//  WalletRegistrationInteractorImplTests.swift
//  wallet-backend
//
//  Created by Tamas Dancsi on 30.05.26.
//

import Foundation
import Security
import Testing

@testable import wallet_backend
@testable import logic_api
@testable import logic_business
@testable import logic_core
@testable import logic_test

struct WalletRegistrationInteractorImplTests {

  // MARK: - registerWalletInstance

  @Test
  func registerWalletInstance_WhenWIIDAlreadyStored_ReturnsIDWithoutCallingMDVMOrWPB() async throws {
    let mdvmInteractor = FakeMDVMInteractor(token: nil)
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn("existing-wi-id")
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    let result = try await sut.registerWalletInstance()

    #expect(result == "existing-wi-id")
    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 0)
    verify(wpbInteractor, never()).register(mdvmStoredRegistration: any())
  }

  @Test
  func registerWalletInstance_WhenWalletIsRevoked_DoesNotRegisterAgain() async {
    let mdvmInteractor = FakeMDVMInteractor(
      token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token")
    )
    let wpbInteractor = MockWPBInteractor()
    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: true),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    /// The self-lock wipes local state, so without this guard a revoked wallet would look like a
    /// fresh install and silently enrol a brand-new Wallet Instance under the lock screen.
    await #expect(throws: BackendError.notRegistered) {
      _ = try await sut.registerWalletInstance()
    }
    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 0)
    verify(wpbInteractor, never()).register(mdvmStoredRegistration: any())
  }

  @Test
  func registerWalletInstance_WhenMDVMAndWPBSucceed_ReturnsWBWIID() async throws {
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.register(mdvmStoredRegistration: any())).thenReturn("wb-wi-id-123")
      when(mock.walletInstanceID()).thenReturn(nil)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )
    let result = try await sut.registerWalletInstance()

    #expect(result == "wb-wi-id-123")
  }

  @Test
  func registerWalletInstance_WhenMDVMTokenIsNil_ThrowsErrorWithoutServerIdentifiers() async throws {
    let mdvmInteractor = FakeMDVMInteractor(token: nil)
    let wpbInteractor = MockWPBInteractor()
    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn(nil)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    await #expect(throws: BackendError.unknown) {
      _ = try await sut.registerWalletInstance()
    }
  }

  @Test
  func registerWalletInstance_WhenWPBThrowsServerError_PassesCodeAndTraceIdThrough() async throws {
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn(nil)
      when(mock.register(mdvmStoredRegistration: any()))
        .thenThrow(BackendError.serverError(code: "MDVM_TOKEN_VERIFICATION_FAILURE", description: "invalid token", traceID: "t-1"))
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    await #expect(throws: BackendError.serverError(code: "MDVM_TOKEN_VERIFICATION_FAILURE", description: "invalid token", traceID: "t-1")) {
      _ = try await sut.registerWalletInstance()
    }
  }

  /// The app keeps no catalogue of WPB codes, so a code it has never seen must reach the UI unchanged.
  @Test
  func registerWalletInstance_WhenWPBThrowsUnknownCode_PassesItThroughUnchanged() async throws {
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn(nil)
      when(mock.register(mdvmStoredRegistration: any()))
        .thenThrow(BackendError.serverError(code: "SOME_FUTURE_SERVER_CODE", description: "whatever", traceID: "t-2"))
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    await #expect(throws: BackendError.serverError(code: "SOME_FUTURE_SERVER_CODE", description: "whatever", traceID: "t-2")) {
      _ = try await sut.registerWalletInstance()
    }
  }

  @Test
  func registerWalletInstance_WhenWPBThrowsNonServerError_ThrowsErrorWithoutServerIdentifiers() async throws {
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn(nil)
      when(mock.register(mdvmStoredRegistration: any()))
        .thenThrow(BackendError.decodingFailed)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    await #expect(throws: BackendError.decodingFailed) {
      _ = try await sut.registerWalletInstance()
    }
  }

  // MARK: - MDVM account not found

  private static let accountNotFound = BackendError.serverError(
    code: "ACCOUNT_NOT_FOUND",
    description: "MdvmAccount not found",
    traceID: "t-3"
  )

  /// A setup that stopped after the MDVM step, followed by a backend reset, used to fail on every launch.
  @Test
  func registerWalletInstance_WhenMDVMAccountNotFound_DropsStoredRegistrationAndRegistersAgain() async throws {
    let mdvmInteractor = FakeMDVMInteractor(results: [
      .failure(Self.accountNotFound),
      .success(MDVMStoredRegistration(mdvmWIID: "new-mdvm-id", mdvmToken: "new-mdvm-token"))
    ])
    let secureEnclaveController = FakeSecureEnclaveController()
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn(nil)
      when(mock.register(mdvmStoredRegistration: any())).thenReturn("wb-wi-id-123")
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: secureEnclaveController
    )
    let result = try await sut.registerWalletInstance()

    #expect(result == "wb-wi-id-123")
    #expect(secureEnclaveController.deletedKeyTags == [.mdvmWIID, .mdvmToken])
    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 2)
  }

  @Test
  func registerWalletInstance_WhenMDVMAccountStillNotFound_ThrowsInsteadOfRetryingAgain() async {
    let mdvmInteractor = FakeMDVMInteractor(results: [.failure(Self.accountNotFound)])
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn(nil)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    await #expect(throws: Self.accountNotFound) {
      _ = try await sut.registerWalletInstance()
    }
    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 2)
    verify(wpbInteractor, never()).register(mdvmStoredRegistration: any())
  }

  @Test
  func registerWalletInstance_WhenMDVMFailsWithAnotherCode_KeepsStoredRegistration() async {
    let signatureFailure = BackendError.serverError(
      code: "SIGNATURE_VERIFICATION_FAILURE",
      description: "signature mismatch",
      traceID: "t-4"
    )
    let mdvmInteractor = FakeMDVMInteractor(results: [.failure(signatureFailure)])
    let secureEnclaveController = FakeSecureEnclaveController()
    let wpbInteractor = MockWPBInteractor()

    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenReturn(nil)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: secureEnclaveController
    )

    await #expect(throws: signatureFailure) {
      _ = try await sut.registerWalletInstance()
    }
    #expect(secureEnclaveController.deletedKeyTags.isEmpty)
    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 1)
  }

  // MARK: - Store Error

  @Test
  func registerWalletInstance_WhenStoredWIIDIsUnreadable_ThrowsWithoutTouchingMDVM() async {
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    let wpbInteractor = MockWPBInteractor()
    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID()).thenThrow(SecureEnclaveControllerError.encryptedValueAuthenticationFailed)
    }
    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false),
      secureEnclaveController: FakeSecureEnclaveController()
    )

    await #expect(throws: SecureEnclaveControllerError.encryptedValueAuthenticationFailed) {
      _ = try await sut.registerWalletInstance()
    }
    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 0)
    verify(wpbInteractor, never()).register(mdvmStoredRegistration: any())
  }
}

private final class FakeMDVMInteractor: MDVMInteractor {
  private var results: [Result<MDVMStoredRegistration?, Error>]
  private(set) var ensureFreshMDVMTokenCallCount = 0
  init(token: MDVMStoredRegistration?) { self.results = [.success(token)] }
  /// One result per call, the last one repeats once the others are used up.
  init(results: [Result<MDVMStoredRegistration?, Error>]) { self.results = results }
  func ensureFreshMDVMToken() async throws -> MDVMStoredRegistration? {
    ensureFreshMDVMTokenCallCount += 1
    let result = results.count > 1 ? results.removeFirst() : results[0]
    return try result.get()
  }
}

/// Only records keychain deletions, the interactor touches nothing else.
private final class FakeSecureEnclaveController: SecureEnclaveController {
  private(set) var deletedKeyTags: [SecureEnclaveKeys] = []

  func deleteKeychainItem(keyTag: SecureEnclaveKeys) { deletedKeyTags.append(keyTag) }
  func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool { false }
  func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool { false }
  func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool { false }
  func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String? { nil }
  func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) throws { }
  func retrieveDecryptedString(keyTag: SecureEnclaveKeys) throws -> String? { nil }
  func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey { throw BackendError.unknown }
  func generatePublicKey(from privateKey: SecKey) throws -> SecKey { throw BackendError.unknown }
  func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey { throw BackendError.unknown }
  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo { throw BackendError.unknown }
}

private struct FakeWalletRevocationInteractor: WalletRevocationInteractor {
  let isWalletRevoked: Bool

  func confirmRevocation() async {}
  func resetAfterRevocation() {}
}
