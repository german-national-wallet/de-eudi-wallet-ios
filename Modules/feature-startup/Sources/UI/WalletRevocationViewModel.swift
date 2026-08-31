//
//  WalletRevocationViewModel.swift
//  feature-startup
//

import Foundation
import logic_ui

struct WalletRevocationUiConfig: UIConfigType {
  let continueRoute: AppRoute

  var log: String {
    "WalletRevocationUiConfig continueRoute: \(continueRoute.info.key)"
  }

  init(continueRoute: AppRoute) {
    self.continueRoute = continueRoute
  }
}

struct WalletRevocationState: ViewState {}

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
}
