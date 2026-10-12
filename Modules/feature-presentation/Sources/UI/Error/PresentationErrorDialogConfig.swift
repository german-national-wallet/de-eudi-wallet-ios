//
//  PresentationErrorDialogConfig.swift
//  feature-presentation
//

import logic_ui
import logic_resources

struct PresentationErrorDialogConfig: Equatable {

  enum Action: Equatable {
    case popTo(AppRoute)
    case addDigitalIDAgain
    case dismiss
  }

  struct Button: Equatable {
    let title: LocalizableStringKey
    let action: Action
  }

  let title: LocalizableStringKey
  let titleIcon: Image?
  let message: LocalizableStringKey
  let errorCode: String?
  let traceId: String
  let primary: Button
  let secondary: Button?

  init(
    title: LocalizableStringKey,
    titleIcon: Image? = nil,
    message: LocalizableStringKey,
    errorCode: String?,
    traceId: String,
    primary: Button,
    secondary: Button?
  ) {
    self.title = title
    self.titleIcon = titleIcon
    self.message = message
    self.errorCode = errorCode
    self.traceId = traceId
    self.primary = primary
    self.secondary = secondary
  }
}
