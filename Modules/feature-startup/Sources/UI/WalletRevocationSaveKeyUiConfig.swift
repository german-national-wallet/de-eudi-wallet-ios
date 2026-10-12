//
//  WalletRevocationSaveKeyUiConfig.swift
//  feature-startup
//

import logic_ui

struct WalletRevocationSaveKeyUiConfig: UIConfigType {
  let revocationCode: String
  let continueRoute: AppRoute

  var log: String {
    "WalletRevocationSaveKeyUiConfig continueRoute: \(continueRoute.info.key)"
  }

  init(revocationCode: String, continueRoute: AppRoute) {
    self.revocationCode = revocationCode
    self.continueRoute = continueRoute
  }
}
