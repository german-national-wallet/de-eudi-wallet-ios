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
  var walletInstanceID: String? { get }
  /// Register a new WPB account
  func register(mdvmStoredRegistration: MDVMStoredRegistration) async throws -> String
  /// Issue wallet instance attestation bound to the provided WIA private key
  func issueAttestation(wiaPrivateKey: SecKey) async throws -> String
  /// Delete WBP account
  func deleteAccount() async throws
}

public final class WPBInteractorImpl: WPBInteractor {

  private let repository: WPBRepository
  private let mdvmRepository: MDVMRepository

  init(
    repository: WPBRepository,
    mdvmRepository: MDVMRepository
  ) {
    self.repository = repository
    self.mdvmRepository = mdvmRepository
  }

  public var walletInstanceID: String? {
    repository.getStoredWIID()
  }

  public func register(mdvmStoredRegistration: MDVMStoredRegistration) async throws -> String {
    if let wbWIID = walletInstanceID {
      return wbWIID
    }

    let challenge = try await repository.fetchChallenge()
    let response = try await repository.register(
      mdvmToken: mdvmStoredRegistration.mdvmToken,
      authChallenge: challenge
    )
    repository.storeWIID(response.wbWIID)
    repository.storeRevocationCode(response.wpbWiRevocationCode)
    return response.wbWIID
  }

  public func issueAttestation(wiaPrivateKey: SecKey) async throws -> String {
    guard let mdvmStoredRegistration = mdvmRepository.getStoredRegistration() else {
      throw WPBRepositoryError.notRegistered
    }
    guard let wbWIID = walletInstanceID else {
      throw WPBRepositoryError.notRegistered
    }

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
    guard let mdvmStoredRegistration = mdvmRepository.getStoredRegistration() else {
      throw WPBRepositoryError.notRegistered
    }
    guard let wbWIID = walletInstanceID else {
      throw WPBRepositoryError.notRegistered
    }

    let challenge = try await repository.fetchChallenge()
    try await repository.deleteAccount(
      mdvmToken: mdvmStoredRegistration.mdvmToken,
      authChallenge: challenge,
      wbWIID: wbWIID
    )
    repository.deleteWIID()
    repository.deleteRevocationCode()
  }
}

extension WPBInteractorImpl: WIAIssuanceService {
  public func issueWIA(wiaPrivateKey: SecKey) async throws -> String {
    try await issueAttestation(wiaPrivateKey: wiaPrivateKey)
  }
}
