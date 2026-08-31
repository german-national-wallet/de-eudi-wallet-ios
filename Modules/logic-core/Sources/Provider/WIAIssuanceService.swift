//
//  WIAIssuanceService.swift
//  logic-core
//

import Foundation
import Security

/// Small protocol so WalletAttestationProviderImpl can call WPB without logic-core depending on the wallet-backend module directly
public protocol WIAIssuanceService: Sendable {
  func issueWIA(wiaPrivateKey: SecKey) async throws -> String
}
