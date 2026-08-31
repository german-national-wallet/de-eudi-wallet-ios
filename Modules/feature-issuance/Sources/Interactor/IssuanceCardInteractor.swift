//
//  IssuanceCardInteractor.swift
//  feature-issuance
//

import Foundation
import logic_ui
import logic_resources
import feature_common
import logic_business
import logic_core
import JOSESwift

public protocol IssuanceCardInteractor {
  func executeFinishAuthorizationRequest(_ url: String) async throws -> FinishAuthorizationResponse
}

final class IssuanceCardInteractorImpl: IssuanceCardInteractor {
  private let issuanceCardRemoteRepository: IssuanceCardRemoteRepository
  private let walletController: WalletKitController
  private let expirationTime = TimeInterval(5*60)
  private let secureEnclaveController: SecureEnclaveController

  init(
    issuanceCardRemoteRepository: IssuanceCardRemoteRepository,
    walletController: WalletKitController,
    secureEnclaveController: SecureEnclaveController
  ) {
    self.issuanceCardRemoteRepository = issuanceCardRemoteRepository
    self.walletController = walletController
    self.secureEnclaveController = secureEnclaveController
  }

  func executeFinishAuthorizationRequest(_ url: String) async throws -> FinishAuthorizationResponse {
      try await issuanceCardRemoteRepository.executeFinishAuthorizationRequest(with: url)
  }
}
