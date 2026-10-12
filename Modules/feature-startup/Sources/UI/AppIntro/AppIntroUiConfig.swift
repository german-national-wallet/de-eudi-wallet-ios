//
//  AppIntroUiConfig.swift
//  feature-startup
//

import logic_ui

struct AppIntroUiConfig: UIConfigType {
  let page: AppIntroPage
  let continueRoute: AppRoute

  var log: String {
    "AppIntroUiConfig page: \(page.number) continueRoute: \(continueRoute.info.key)"
  }

  init(page: AppIntroPage = .digitalWallet, continueRoute: AppRoute) {
    self.page = page
    self.continueRoute = continueRoute
  }
}
