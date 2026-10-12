//
//  SetupSuccessUiConfig.swift
//  feature-startup
//

import logic_ui

struct SetupSuccessUiConfig: UIConfigType {
  let continueRoute: AppRoute

  var log: String {
    "SetupSuccessUiConfig continueRoute: \(continueRoute.info.key)"
  }

  init(continueRoute: AppRoute) {
    self.continueRoute = continueRoute
  }
}
