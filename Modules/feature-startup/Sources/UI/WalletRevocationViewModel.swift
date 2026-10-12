//
//  WalletRevocationViewModel.swift
//  feature-startup
//

import Foundation
import logic_ui

final class WalletRevocationViewModel<Router: RouterHost>: ViewModel<Router, WalletRevocationState> {

  private let continueRoute: AppRoute

  init(router: Router, config: any UIConfigType) {
    guard let config = config as? WalletRevocationUiConfig else {
      fatalError("Config error :: config must be of type WalletRevocationUiConfig")
    }
    self.continueRoute = config.continueRoute
    super.init(router: router, initialState: WalletRevocationState())
  }

  func onPrimaryButtonTapped() {
    router.push(with: continueRoute)
  }

  func onBackTapped() {
    router.pop()
  }
}
