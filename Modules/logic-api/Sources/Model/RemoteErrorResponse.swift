//
//  RemoteErrorResponse.swift
//  logic-api
//

import Foundation
import logic_resources

public struct RemoteErrorResponseStruct {
  public var title: LocalizableStringKey
  public var paragraph: LocalizableStringKey
  public var primaryButtonTitle: LocalizableStringKey?
  public var secondaryButtonTitle: LocalizableStringKey?

  public init(
    title: LocalizableStringKey,
    paragraph: LocalizableStringKey,
    primaryButtonTitle: LocalizableStringKey? = nil,
    secondaryButtonTitle: LocalizableStringKey? = nil
  ) {
    self.title = title
    self.paragraph = paragraph
    self.primaryButtonTitle = primaryButtonTitle
    self.secondaryButtonTitle = secondaryButtonTitle
  }
}
