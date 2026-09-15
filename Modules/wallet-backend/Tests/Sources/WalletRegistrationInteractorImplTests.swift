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
  func registerWalletInstance_WhenWalletIsRevoked_DoesNotRegisterAgain() async {
    let mdvmInteractor = FakeMDVMInteractor(
      token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token")
    )
    let wpbInteractor = MockWPBInteractor()
    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: true)
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
      when(mock.walletInstanceID.get).thenReturn(nil)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false)
    )
    let result = try await sut.registerWalletInstance()

    #expect(result == "wb-wi-id-123")
  }

  @Test
  func registerWalletInstance_WhenMDVMTokenIsNil_ThrowsErrorWithoutServerIdentifiers() async throws {
    let mdvmInteractor = FakeMDVMInteractor(token: nil)
    let wpbInteractor = MockWPBInteractor()
    stub(wpbInteractor) { mock in
      when(mock.walletInstanceID.get).thenReturn(nil)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false)
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
      when(mock.walletInstanceID.get).thenReturn(nil)
      when(mock.register(mdvmStoredRegistration: any()))
        .thenThrow(BackendError.serverError(code: "MDVM_TOKEN_VERIFICATION_FAILURE", description: "invalid token", traceID: "t-1"))
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false)
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
      when(mock.walletInstanceID.get).thenReturn(nil)
      when(mock.register(mdvmStoredRegistration: any()))
        .thenThrow(BackendError.serverError(code: "SOME_FUTURE_SERVER_CODE", description: "whatever", traceID: "t-2"))
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false)
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
      when(mock.walletInstanceID.get).thenReturn(nil)
      when(mock.register(mdvmStoredRegistration: any()))
        .thenThrow(BackendError.decodingFailed)
    }

    let sut = WalletRegistrationInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      wpbInteractor: wpbInteractor,
      walletRevocationInteractor: FakeWalletRevocationInteractor(isWalletRevoked: false)
    )

    await #expect(throws: BackendError.decodingFailed) {
      _ = try await sut.registerWalletInstance()
    }
  }
}

private final class FakeMDVMInteractor: MDVMInteractor {
  private let token: MDVMStoredRegistration?
  private(set) var ensureFreshMDVMTokenCallCount = 0
  init(token: MDVMStoredRegistration?) { self.token = token }
  func ensureFreshMDVMToken() async throws -> MDVMStoredRegistration? {
    ensureFreshMDVMTokenCallCount += 1
    return token
  }
}

private struct FakeWalletRevocationInteractor: WalletRevocationInteractor {
  let isWalletRevoked: Bool

  func confirmRevocation() async {}
  func resetAfterRevocation() {}
}
