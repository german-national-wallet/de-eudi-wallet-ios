//
//  PlatformAuthOnboardingUiConfig.swift
//  feature-startup
//

import logic_ui

struct PlatformAuthOnboardingUiConfig: UIConfigType {
  let continueRoute: AppRoute

  var log: String {
    "PlatformAuthOnboardingUiConfig continueRoute: \(continueRoute.info.key)"
  }

  init(continueRoute: AppRoute) {
    self.continueRoute = continueRoute
  }
}
