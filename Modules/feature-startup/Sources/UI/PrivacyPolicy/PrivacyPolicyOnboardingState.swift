//
//  PrivacyPolicyOnboardingState.swift
//  feature-startup
//

import Foundation
import logic_ui

@Copyable
struct PrivacyPolicyOnboardingState: ViewState {
  let hasAgreed: Bool
  let isPolicyPresented: Bool
  let presentedURL: URL?
}
