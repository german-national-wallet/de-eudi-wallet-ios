//
//  PushNotificationOnboardingUiConfig.swift
//  feature-startup
//

import logic_ui

struct PushNotificationOnboardingUiConfig: UIConfigType {
  let continueRoute: AppRoute

  var log: String {
    "PushNotificationOnboardingUiConfig continueRoute: \(continueRoute.info.key)"
  }

  init(continueRoute: AppRoute) {
    self.continueRoute = continueRoute
  }
}
