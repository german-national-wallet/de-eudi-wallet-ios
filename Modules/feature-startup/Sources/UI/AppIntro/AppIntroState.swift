//
//  AppIntroState.swift
//  feature-startup
//

import logic_ui

@Copyable
struct AppIntroState: ViewState {
  let page: AppIntroPage
  let isAnimationPaused: Bool
  let isAnimationToggleVisible: Bool
}
