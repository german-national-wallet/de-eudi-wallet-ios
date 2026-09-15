//
//  Typography.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Styles.Typography {
  struct Display {
    public static let large = Font.custom("EUDIDiatypeWide-Semibold", size: 57)
    public static let medium = Font.custom("EUDIDiatypeWide-Semibold", size: 45)
    public static let small = Font.custom("EUDIDiatypeWide-Semibold", size: 36)
  }

  struct Headline {
    public static let large = Font.custom("EUDIDiatypeWide-Semibold", size: 32)
    public static let medium = Font.custom("EUDIDiatypeWide-Semibold", size: 28)
    public static let small = Font.custom("EUDIDiatypeWide-Semibold", size: 24)
  }

  struct Title {
    public static let large = Font.custom("EUDIDiatypeSemiExtended-Bold", size: 28)
    public static let medium = Font.custom("EUDIDiatypeSemiExtended-Bold", size: 18)
    public static let small = Font.custom("EUDIDiatypeSemiExtended-Bold", size: 16)
  }

  struct Label {
    public static let large = Font.custom("EUDIDiatype-Medium", size: 16)
    public static let medium = Font.custom("EUDIDiatype-Regular", size: 14)
    public static let small = Font.custom("EUDIDiatype-Regular", size: 11)
  }

  struct Body {
    public static let large = Font.custom("EUDIDiatype-Regular", size: 16)
    public static let medium = Font.custom("EUDIDiatype-Regular", size: 14)
    public static let small = Font.custom("EUDIDiatype-Regular", size: 12)
    public static let largeBold = Font.custom("EUDIDiatype-Bold", size: 16)
  }
}
