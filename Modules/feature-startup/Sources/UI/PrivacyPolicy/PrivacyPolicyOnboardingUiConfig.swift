//
//  PrivacyPolicyOnboardingUiConfig.swift
//  feature-startup
//

import logic_ui

struct PrivacyPolicyOnboardingUiConfig: UIConfigType {
  let continueRoute: AppRoute

  var log: String {
    "PrivacyPolicyOnboardingUiConfig continueRoute: \(continueRoute.info.key)"
  }

  init(continueRoute: AppRoute) {
    self.continueRoute = continueRoute
  }
}
