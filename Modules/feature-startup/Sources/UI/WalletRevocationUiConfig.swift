//
//  WalletRevocationUiConfig.swift
//  feature-startup
//

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
