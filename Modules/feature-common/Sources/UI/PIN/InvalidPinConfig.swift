//
//  InvalidPinConfig.swift
//  feature-common
//
import Foundation
import MdocDataModel18013
import SwiftUI

public extension UIConfig {
  struct InvalidPin: UIConfigType, Equatable {
    public static func == (lhs: logic_ui.UIConfig.InvalidPin, rhs: logic_ui.UIConfig.InvalidPin) -> Bool {
      (lhs.title == rhs.title && lhs.caption == rhs.caption)
    }
    
    public let title: LocalizableStringKey
    public let caption: LocalizableStringKey?
    public let iconImage: Image?
    public let primaryActionNavigation: ThreeWayNavigationType
    public let navigationBackType: ThreeWayNavigationType?
    public let navigationCancelType: ThreeWayNavigationType?
    public let primaryButtonTitle: LocalizableStringKey
    public let secondaryButtonTitle: LocalizableStringKey?
    public let pinScreenType: PINScreenType?

    public var log: String {
      return "title: \(title.toString)" +
      " onSuccessNav: \(primaryActionNavigation.key)" +
      " onBackNav: \(navigationBackType?.key ?? "none")"
    }

    public init(
      title: LocalizableStringKey,
      caption: LocalizableStringKey? = nil,
      iconImage: Image? = nil,
      navigationSuccessType: ThreeWayNavigationType,
      navigationBackType: ThreeWayNavigationType? = nil,
      navigationCancelType: ThreeWayNavigationType? = nil,
      primaryButtonTitle: LocalizableStringKey,
      secondaryButtonTitle: LocalizableStringKey? = nil,
      pinScreenType: PINScreenType? = nil,
    ) {
      self.title = title
      self.caption = caption
      self.iconImage = iconImage
      self.primaryActionNavigation = navigationSuccessType
      self.navigationBackType = navigationBackType
      self.navigationCancelType = navigationCancelType
      self.primaryButtonTitle = primaryButtonTitle
      self.secondaryButtonTitle = secondaryButtonTitle
      self.pinScreenType = pinScreenType
    }
  }
}
