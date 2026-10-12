//
//  PlatformAuthOnboardingState.swift
//  feature-startup
//

import logic_ui

@Copyable
struct PlatformAuthOnboardingState: ViewState {
  let isChecking: Bool
  let isPlatformAuthEnabled: Bool
  let isImportantSheetPresented: Bool
}
