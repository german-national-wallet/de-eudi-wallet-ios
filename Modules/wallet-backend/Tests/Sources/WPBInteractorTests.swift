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
    let mdvmRepo = FakeMDVMRepository()
    mdvmRepo.storedRegistration = MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token")
    let sut = makeSUT(repository: repository, mdvmRepository: mdvmRepo)

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
    let sut = makeSUT(mdvmRepository: FakeMDVMRepository())

    await #expect(throws: WPBRepositoryError.notRegistered) {
      _ = try await sut.issueAttestation(wiaPrivateKey: wiaPrivateKey)
    }
  }

  @Test
  func issueAttestation_WhenWIIDMissing_ThrowsNotRegistered() async {
    let repository = MockWPBRepository()
    let mdvmRepo = FakeMDVMRepository()
    mdvmRepo.storedRegistration = MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token")
    stub(repository) { when($0.getStoredWIID()).thenReturn(nil) }
    let sut = makeSUT(repository: repository, mdvmRepository: mdvmRepo)

    await #expect(throws: WPBRepositoryError.notRegistered) {
      _ = try await sut.issueAttestation(wiaPrivateKey: wiaPrivateKey)
    }
  }

  // MARK: - deleteAccount

  @Test
  func deleteAccount_WhenRegisteredAndWIIDStored_CallsRepoAndDeletesWIID() async throws {
    let repository = MockWPBRepository()
    let mdvmRepo = FakeMDVMRepository()
    mdvmRepo.storedRegistration = MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: "mdvm-token")
    let sut = makeSUT(repository: repository, mdvmRepository: mdvmRepo)

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
    let sut = makeSUT(mdvmRepository: FakeMDVMRepository())

    await #expect(throws: WPBRepositoryError.notRegistered) {
      try await sut.deleteAccount()
    }
  }

  // MARK: - Helpers

  private func makeSUT(
    repository: WPBRepository = MockWPBRepository(),
    mdvmRepository: MDVMRepository = FakeMDVMRepository()
  ) -> WPBInteractorImpl {
    WPBInteractorImpl(repository: repository, mdvmRepository: mdvmRepository)
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

private final class FakeMDVMRepository: MDVMRepository {
  var storedRegistration: MDVMStoredRegistration?

  func getStoredRegistration() -> MDVMStoredRegistration? { storedRegistration }
  func fetchChallenge() async throws -> String { "" }
  func register(payload: MDVMRegistrationPayload, authChallenge: String, skipIntegrityChecks: Bool, privateKey: SecKey) async throws {}
  func renew(payload: MDVMRenewalPayload, mdvmWIID: String, authChallenge: String, skipIntegrityChecks: Bool, privateKey: SecKey) async throws {}
}
