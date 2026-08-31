//
//  IconSizes.swift
//  DesignSystem
//

import SwiftUI

/// `IconSizes` defines standardized icon sizes used throughout the Design System.
///
/// These constants ensure consistency in icon sizing across the app UI.
///
/// Example usage:
/// ```swift
/// Image(systemName: "star.fill")
///     .frame(width: DSIconSizes.medium, height: DSIconSizes.medium)
/// ```
public extension DesignSystem.Styles.Sizes {
  struct Icons {
    
    /// Extra small icon size (12pt)
    public static let xSmall: CGFloat = 12

    /// Small icon size (16pt)
    public static let small: CGFloat = 16

    /// Medium icon size (20pt) — commonly used as the default icon size
    public static let medium: CGFloat = 20

    /// Large icon size (24pt)
    public static let large: CGFloat = 24

    /// Extra large icon size (32pt)
    public static let xLarge: CGFloat = 32

    /// Double extra large icon size (40pt)
    public static let xxLarge: CGFloat = 40
    
    /// Double extra large icon size (120pt)
    public static let xxxLarge: CGFloat = 120
  }
}
