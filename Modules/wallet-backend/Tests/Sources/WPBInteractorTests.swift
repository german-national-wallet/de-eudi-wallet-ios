//
//  WPBInteractorTests.swift
//  wallet-backend
//

import Foundation
import Security
import Testing

@testable import wallet_backend
@testable import logic_api
@testable import logic_business
@testable import logic_core
@testable import logic_test

struct WPBInteractorTests {

  private let wiaPrivateKey = makePrivateKey()

  // MARK: - walletInstanceID

  @Test
  func walletInstanceID_WhenRepositoryHasValue_ReturnsIt() {
    let repository = MockWPBRepository()
    stub(repository) { when($0.getStoredWIID()).thenReturn("stored-wi-id") }

    #expect(makeSUT(repository: repository).walletInstanceID == "stored-wi-id")
  }

  @Test
  func walletInstanceID_WhenRepositoryReturnsNil_ReturnsNil() {
    let repository = MockWPBRepository()
    stub(repository) { when($0.getStoredWIID()).thenReturn(nil) }

    #expect(makeSUT(repository: repository).walletInstanceID == nil)
  }

  // MARK: - register

  @Test
  func register_WhenNoWIIDStored_FetchesChallengeRegistersAndStoresWIID() async throws {
    let repository = MockWPBRepository()
    let sut = makeSUT(repository: repository)

    stub(repository) { mock in
      when(mock.getStoredWIID()).thenReturn(nil)
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.register(
        mdvmToken: equal(to: "mdvm-token"),
        authChallenge: equal(to: "challenge-value")
      )).thenReturn(WPBRegisterResponse(wbWIID: "new-wi-id", wpbWiRevocationCode: ""))
      when(mock.storeWIID(equal(to: "new-wi-id"))).thenDoNothing()
      when(mock.storeRevocationCode(any())).thenDoNothing()
    }

    let result = try await sut.register(
      mdvmStoredRegistration: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token")
    )

    #expect(result == "new-wi-id")
    verify(repository).storeWIID(equal(to: "new-wi-id"))
    verify(repository).storeRevocationCode(any())
  }

  @Test
  func register_WhenWIIDAlreadyStored_ReturnsEarlyWithoutCallingNetwork() async throws {
    let repository = MockWPBRepository()
    stub(repository) { when($0.getStoredWIID()).thenReturn("existing-wi-id") }
    let sut = makeSUT(repository: repository)

    let result = try await sut.register(
      mdvmStoredRegistration: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token")
    )

    #expect(result == "existing-wi-id")
    verify(repository, never()).fetchChallenge()
    verify(repository, never()).register(mdvmToken: any(), authChallenge: any())
  }

  // MARK: - issueAttestation

  @Test
  func issueAttestation_WhenAllDependenciesReady_ReturnsToken() async throws {
    let repository = MockWPBRepository()
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    let sut = makeSUT(repository: repository, mdvmInteractor: mdvmInteractor)

    stub(repository) { mock in
      when(mock.getStoredWIID()).thenReturn("wi-id-123")
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.issueAttestation(
        mdvmToken: equal(to: "mdvm-token"),
        authChallenge: equal(to: "challenge-value"),
        wbWIID: equal(to: "wi-id-123"),
        wiaPrivateKey: any()
      )).thenReturn(WPBAttestationResponse(wbWIA: "attestation-token"))
    }

    let result = try await sut.issueAttestation(wiaPrivateKey: wiaPrivateKey)

    #expect(result == "attestation-token")
  }

  @Test
  func issueAttestation_WhenMDVMRegistrationMissing_ThrowsNotRegistered() async {
    let sut = makeSUT(mdvmInteractor: FakeMDVMInteractor())

    await #expect(throws: WPBRepositoryError.notRegistered) {
      _ = try await sut.issueAttestation(wiaPrivateKey: wiaPrivateKey)
    }
  }

  @Test
  func issueAttestation_WhenWIIDMissing_ThrowsNotRegistered() async {
    let repository = MockWPBRepository()
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    stub(repository) { when($0.getStoredWIID()).thenReturn(nil) }
    let sut = makeSUT(repository: repository, mdvmInteractor: mdvmInteractor)

    await #expect(throws: WPBRepositoryError.notRegistered) {
      _ = try await sut.issueAttestation(wiaPrivateKey: wiaPrivateKey)
    }
  }

  // MARK: - deleteAccount

  @Test
  func deleteAccount_WhenRegisteredAndWIIDStored_CallsRepoAndDeletesWIID() async throws {
    let repository = MockWPBRepository()
    let mdvmInteractor = FakeMDVMInteractor(token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token"))
    let sut = makeSUT(repository: repository, mdvmInteractor: mdvmInteractor)

    stub(repository) { mock in
      when(mock.getStoredWIID()).thenReturn("wi-id-123")
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.deleteAccount(
        mdvmToken: equal(to: "mdvm-token"),
        authChallenge: equal(to: "challenge-value"),
        wbWIID: equal(to: "wi-id-123")
      )).thenDoNothing()
      when(mock.deleteWIID()).thenDoNothing()
      when(mock.deleteRevocationCode()).thenDoNothing()
    }

    try await sut.deleteAccount()

    verify(repository).deleteWIID()
    verify(repository).deleteRevocationCode()
  }

  @Test
  func deleteAccount_WhenMDVMRegistrationMissing_ThrowsNotRegistered() async {
    let sut = makeSUT(mdvmInteractor: FakeMDVMInteractor())

    await #expect(throws: WPBRepositoryError.notRegistered) {
      try await sut.deleteAccount()
    }
  }
  
  @Test
  func issueAttestation_UsesTokenFromEnsureFreshMDVMToken() async throws {
    let repository = MockWPBRepository()
    let mdvmInteractor = FakeMDVMInteractor(
      token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "renewed-token")
    )
    stub(repository) { mock in
      when(mock.getStoredWIID()).thenReturn("wi-id-123")
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.issueAttestation(
        mdvmToken: equal(to: "renewed-token"),
        authChallenge: equal(to: "challenge-value"),
        wbWIID: equal(to: "wi-id-123"),
        wiaPrivateKey: any()
      )).thenReturn(WPBAttestationResponse(wbWIA: "attestation-token"))
    }

    let result = try await makeSUT(repository: repository, mdvmInteractor: mdvmInteractor)
      .issueAttestation(wiaPrivateKey: wiaPrivateKey)

    #expect(result == "attestation-token")
    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 1)
  }

  @Test
  func issueAttestation_WhenTokenRenewalThrows_PropagatesErrorWithoutCallingRepository() async {
    let repository = MockWPBRepository()
    let sut = makeSUT(repository: repository, mdvmInteractor: FakeMDVMInteractor(error: StubError()))

    await #expect(throws: StubError()) {
      _ = try await sut.issueAttestation(wiaPrivateKey: wiaPrivateKey)
    }

    verify(repository, never()).fetchChallenge()
    verify(repository, never()).issueAttestation(
      mdvmToken: any(), authChallenge: any(), wbWIID: any(), wiaPrivateKey: any()
    )
  }

  @Test
  func deleteAccount_UsesTokenFromEnsureFreshMDVMToken() async throws {
    let repository = MockWPBRepository()
    let mdvmInteractor = FakeMDVMInteractor(
      token: MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "renewed-token")
    )
    stub(repository) { mock in
      when(mock.getStoredWIID()).thenReturn("wi-id-123")
      when(mock.fetchChallenge()).thenReturn("challenge-value")
      when(mock.deleteAccount(
        mdvmToken: equal(to: "renewed-token"),
        authChallenge: equal(to: "challenge-value"),
        wbWIID: equal(to: "wi-id-123")
      )).thenDoNothing()
      when(mock.deleteWIID()).thenDoNothing()
      when(mock.deleteRevocationCode()).thenDoNothing()
    }

    try await makeSUT(repository: repository, mdvmInteractor: mdvmInteractor).deleteAccount()

    #expect(mdvmInteractor.ensureFreshMDVMTokenCallCount == 1)
    verify(repository).deleteAccount(
      mdvmToken: equal(to: "renewed-token"), authChallenge: any(), wbWIID: any()
    )
  }

  @Test
  func deleteAccount_WhenTokenRenewalThrows_PropagatesErrorAndKeepsLocalData() async {
    let repository = MockWPBRepository()
    let sut = makeSUT(repository: repository, mdvmInteractor: FakeMDVMInteractor(error: StubError()))

    await #expect(throws: StubError()) {
      try await sut.deleteAccount()
    }

    verify(repository, never()).deleteWIID()
    verify(repository, never()).deleteRevocationCode()
  }
  // MARK: - Helpers

  private func makeSUT(
    repository: WPBRepository = MockWPBRepository(),
    mdvmInteractor: MDVMInteractor = FakeMDVMInteractor()
  ) -> WPBInteractorImpl {
    WPBInteractorImpl(repository: repository, mdvmInteractor: mdvmInteractor)
  }

  private static func makePrivateKey() -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      fatalError("Failed to create key: \(String(describing: error))")
    }
    return key
  }
}

private final class FakeMDVMInteractor: MDVMInteractor {
  private let result: Result<MDVMStoredRegistration?, Error>
  private(set) var ensureFreshMDVMTokenCallCount = 0

  init(token: MDVMStoredRegistration? = nil, error: Error? = nil) {
    result = error.map { .failure($0) } ?? .success(token)
  }

  func ensureFreshMDVMToken() async throws -> MDVMStoredRegistration? {
    ensureFreshMDVMTokenCallCount += 1
    return try result.get()
  }
}

private struct StubError: Error, Equatable {}
