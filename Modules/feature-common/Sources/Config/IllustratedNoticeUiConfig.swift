//
//  IllustratedNoticeUiConfig.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct IllustratedNoticeUiConfig: UIConfigType {

  public enum PrimaryAction: Equatable {
    case findBurgeramt
    case dismiss
  }

  public let title: LocalizableStringKey
  public let message: LocalizableStringKey
  public let illustration: Image?
  public let primaryButtonTitle: LocalizableStringKey
  public let primaryAction: PrimaryAction

  public var log: String {
    "title: \(title.toString), primaryAction: \(primaryAction)"
  }

  public init(
    title: LocalizableStringKey,
    message: LocalizableStringKey,
    illustration: Image? = nil,
    primaryButtonTitle: LocalizableStringKey,
    primaryAction: PrimaryAction
  ) {
    self.title = title
    self.message = message
    self.illustration = illustration
    self.primaryButtonTitle = primaryButtonTitle
    self.primaryAction = primaryAction
  }
}
