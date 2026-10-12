//
//  PresentationErrorNoticeConfig.swift
//  feature-presentation
//

import Foundation
import SwiftUI
import logic_ui
import logic_core
import logic_resources

struct PresentationErrorNoticeConfig: UIConfigType {
  enum Action {
    case popTo(AppRoute)
    case reportSuspicion(supervisoryAuthorityURL: URL? = nil)
    case dismiss
  }

  struct Button {
    let title: LocalizableStringKey
    let trailingIcon: Image?
    let action: Action
  }

  let title: LocalizableStringKey
  let message: LocalizableStringKey
  let illustration: Image?
  let primary: Button
  let secondary: Button?
  let originator: AppRoute

  var log: String { "title: \(title.toString)" }
}
