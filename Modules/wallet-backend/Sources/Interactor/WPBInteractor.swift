//
//  WPBInteractor.swift
//  wallet-backend
//

import Foundation
import logic_api
import logic_business
import logic_core

public protocol WPBInteractor {
  /// Retrieve wallet instance id
  func walletInstanceID() throws -> String?
  /// Register a new WPB account
  func register(mdvmStoredRegistration: MDVMStoredRegistration) async throws -> String
  /// Issue wallet instance attestation bound to the provided WIA private key
  func issueAttestation(wiaPrivateKey: SecKey) async throws -> String
  /// Delete WBP account
  func deleteAccount() async throws
}

public final class WPBInteractorImpl: WPBInteractor {

  private let repository: WPBRepository
  private let mdvmInteractor: MDVMInteractor

  init(
    repository: WPBRepository,
    mdvmInteractor: MDVMInteractor
  ) {
    self.repository = repository
    self.mdvmInteractor = mdvmInteractor
  }

  public func walletInstanceID() throws -> String? {
    try repository.getStoredWIID()
  }

  public func register(mdvmStoredRegistration: MDVMStoredRegistration) async throws -> String {
    // Missing walletInstanceID continues registration, but malformed throws
    if let wbWIID = try walletInstanceID() {
      return wbWIID
    }

    let challenge = try await repository.fetchChallenge()
    let response = try await repository.register(
      mdvmToken: mdvmStoredRegistration.mdvmToken,
      authChallenge: challenge
    )
    try repository.storeWIID(response.wbWIID)
    try repository.storeRevocationCode(response.wpbWiRevocationCode)
    return response.wbWIID
  }

  public func issueAttestation(wiaPrivateKey: SecKey) async throws -> String {
    guard let mdvmStoredRegistration = try await mdvmInteractor.ensureFreshMDVMToken() else {
      throw WPBRepositoryError.notRegistered
    }

    let wbWIID = try requireWalletInstanceID()
    let challenge = try await repository.fetchChallenge()
    let response = try await repository.issueAttestation(
      mdvmToken: mdvmStoredRegistration.mdvmToken,
      authChallenge: challenge,
      wbWIID: wbWIID,
      wiaPrivateKey: wiaPrivateKey
    )
    return response.wbWIA
  }

  public func deleteAccount() async throws {
    guard let mdvmStoredRegistration = try await mdvmInteractor.ensureFreshMDVMToken() else {
      throw WPBRepositoryError.notRegistered
    }

    let wbWIID = try requireWalletInstanceID()
    let challenge = try await repository.fetchChallenge()
    try await repository.deleteAccount(
      mdvmToken: mdvmStoredRegistration.mdvmToken,
      authChallenge: challenge,
      wbWIID: wbWIID
    )
    repository.deleteWIID()
    repository.deleteRevocationCode()
  }

  private func requireWalletInstanceID() throws -> String {
    guard let wbWIID = try walletInstanceID() else {
      throw WPBRepositoryError.notRegistered
    }
    return wbWIID
  }
}

extension WPBInteractorImpl: WIAIssuanceService {
  public func issueWIA(wiaPrivateKey: SecKey) async throws -> String {
    try await issueAttestation(wiaPrivateKey: wiaPrivateKey)
  }
}
