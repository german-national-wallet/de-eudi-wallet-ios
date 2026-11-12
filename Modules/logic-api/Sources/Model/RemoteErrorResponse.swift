//
//  RemoteErrorResponse.swift
//  logic-api
//

import Foundation
import logic_resources

public enum ErrorDialogIcon: Equatable, Sendable {
  case error
  case info
  case warning
  case none
}

public struct RemoteErrorResponseStruct {
  public var title: LocalizableStringKey
  public var paragraph: LocalizableStringKey
  public var primaryButtonTitle: LocalizableStringKey?
  public var secondaryButtonTitle: LocalizableStringKey?
  public var icon: ErrorDialogIcon

  public init(
    title: LocalizableStringKey,
    paragraph: LocalizableStringKey,
    primaryButtonTitle: LocalizableStringKey? = nil,
    secondaryButtonTitle: LocalizableStringKey? = nil,
    icon: ErrorDialogIcon = .error
  ) {
    self.title = title
    self.paragraph = paragraph
    self.primaryButtonTitle = primaryButtonTitle
    self.secondaryButtonTitle = secondaryButtonTitle
    self.icon = icon
  }
}
