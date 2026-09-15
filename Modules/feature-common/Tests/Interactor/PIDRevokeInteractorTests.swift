//
//  PIDRevokeInteractorTests.swift
//  PIDRevokeInteractorTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_business
import logic_core
import logic_api
@testable import feature_common
@testable import feature_test

final class PIDRevokeInteractorTests: XCTestCase {

  private var walletKitController: MockWalletKitController!
  private var prefsController: MockPrefsController!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var logger: MockLogging!
  private var rwscaInteractor: MockRWSCAInteractor!
  private var sut: PIDRevokeInteractorImpl!

  override func setUp() {
    super.setUp()

    walletKitController = MockWalletKitController()
    prefsController = MockPrefsController()
    secureEnclaveController = MockSecureEnclaveController()
    logger = MockLogging()
    rwscaInteractor = MockRWSCAInteractor()
    
    sut = PIDRevokeInteractorImpl(
      walletKitController: walletKitController,
      prefsController: prefsController,
      secureEnclaveController: secureEnclaveController,
      rwscaInteractor: rwscaInteractor,
      logger: logger
    )
  }

  override func tearDown() {
    sut = nil
    prefsController = nil
    walletKitController = nil

    super.tearDown()
  }

  func testDeletePIDFromWallet_WhenCalled_ThenDeletesPIDDocAndTearsDownWalletInstance() async throws {
    let pidDocument = Constants.euPidModel

    stub(walletKitController) { mock in
      when(mock.fetchIssuedDocuments(with: any())).thenReturn([pidDocument])
      when(mock.deleteDocument(with: any(), status: any())).thenDoNothing()
    }
    stub(secureEnclaveController) { mock in
      when(mock.deleteKeychainItem(keyTag: any())).thenDoNothing()
    }
    stub(prefsController) { mock in
      when(mock.remove(forKey: any())).thenDoNothing()
    }
    stub(rwscaInteractor) { mock in
      when(mock.deleteAccount()).thenDoNothing()
    }

    try await sut.deletePIDFromWallet()

    // Only the PID document is deleted; the wallet is never wiped wholesale.
    verify(walletKitController).fetchIssuedDocuments(with: any())
    verify(walletKitController).deleteDocument(with: equal(to: pidDocument.id), status: any())
    verify(walletKitController, times(0)).clearAllDocuments()

    // PIN state and the installation identifier are reset for a fresh registration.
    verify(prefsController).remove(forKey: equal(to: .isPinInitialized))
    verify(prefsController).remove(forKey: equal(to: .mdvmInstallationIdentifier))

    // The server-side RWSCA account is deleted before local state.
    verify(rwscaInteractor).deleteAccount()

    // PID/PIN and RWSCA account keys are torn down.
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .rwscaAccountID))
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .rwscaAuthPrivateKeySalt))
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .pinSessionToken))

    verify(secureEnclaveController, times(0)).deleteKeychainItem(keyTag: equal(to: .wiMdvmAuthPrivateKey))
    verify(secureEnclaveController, times(0)).deleteKeychainItem(keyTag: equal(to: .mdvmWIID))
    verify(secureEnclaveController, times(0)).deleteKeychainItem(keyTag: equal(to: .mdvmToken))
    verify(secureEnclaveController, times(0)).deleteKeychainItem(keyTag: equal(to: .mdvmAppAttestKeyID))
  }

  func testDeletePIDFromWallet_WhenDeleteAccountFails_ThenLogsAndSkipsLocalCleanup() async {
    struct DeleteAccountError: Error {}

    stub(rwscaInteractor) { mock in
      when(mock.deleteAccount()).thenThrow(DeleteAccountError())
    }
    stub(logger) { mock in
      when(mock.e(any(), file: any(), function: any(), line: any())).thenDoNothing()
    }

    do {
      try await sut.deletePIDFromWallet()
      XCTFail("Expected deletePIDFromWallet to rethrow the deleteAccount error")
    } catch {
      // expected: the error is logged and rethrown to the caller
    }

    // deleteAccount() runs first and its failure aborts the whole flow via the do/catch...
    verify(rwscaInteractor).deleteAccount()
    verify(logger).e(any(), file: any(), function: any(), line: any())

    // ...so no local state is touched: documents stay, prefs and keychain are untouched.
    verify(walletKitController, times(0)).fetchIssuedDocuments(with: any())
    verify(walletKitController, times(0)).deleteDocument(with: any(), status: any())
    verify(prefsController, times(0)).remove(forKey: any())
    verify(secureEnclaveController, times(0)).deleteKeychainItem(keyTag: any())
  }

  func testDeletePIDFromWallet_WhenNoRWSCAAccount_ThenStillDeletesLocalState() async throws {
    let pidDocument = Constants.euPidModel

    stub(walletKitController) { mock in
      when(mock.fetchIssuedDocuments(with: any())).thenReturn([pidDocument])
      when(mock.deleteDocument(with: any(), status: any())).thenDoNothing()
    }
    stub(secureEnclaveController) { mock in
      when(mock.deleteKeychainItem(keyTag: any())).thenDoNothing()
    }
    stub(prefsController) { mock in
      when(mock.remove(forKey: any())).thenDoNothing()
    }
    // Pre-WPB / already-removed wallet: no RWSCA account exists to delete.
    stub(rwscaInteractor) { mock in
      when(mock.deleteAccount()).thenThrow(RWSCARepositoryError.notRegistered)
    }
    stub(logger) { mock in
      when(mock.d(any(), file: any(), function: any(), line: any())).thenDoNothing()
    }

    // Must not throw — "no account" is tolerated so migration/local cleanup proceeds.
    try await sut.deletePIDFromWallet()

    verify(rwscaInteractor).deleteAccount()
    verify(walletKitController).deleteDocument(with: equal(to: pidDocument.id), status: any())
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .rwscaAccountID))
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .pinSessionToken))
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .rwscaAuthPrivateKeySalt))
  }
}
