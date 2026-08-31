//
//  WalletRevocationStore.swift
//  logic-core
//

import Foundation
import logic_business

public extension Notification.Name {
  static let walletRevocationConfirmed = Notification.Name("walletRevocationConfirmed")
}

public protocol WalletRevocationStore: Sendable {
  var isWalletRevoked: Bool { get }

  func markRevoked()

  func clearRevoked()
}

public struct WalletRevocationStoreImpl: WalletRevocationStore {

  private let prefsController: PrefsController
  private let logger: Logging?

  public init(prefsController: PrefsController, logger: Logging?) {
    self.prefsController = prefsController
    self.logger = logger
  }

  public var isWalletRevoked: Bool {
    prefsController.getBool(forKey: .walletRevoked)
  }

  public func markRevoked() {
    let wasAlreadyRevoked = isWalletRevoked
    prefsController.setValue(true, forKey: .walletRevoked)
    if !wasAlreadyRevoked {
      logger?.e("[Revocation] confirmed by the MDVM, self-locking")
    }
    NotificationCenter.default.post(name: .walletRevocationConfirmed, object: nil)
  }

  public func clearRevoked() {
    prefsController.remove(forKey: .walletRevoked)
  }
}
