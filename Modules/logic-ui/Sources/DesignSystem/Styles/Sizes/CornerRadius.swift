//
//  IconSizes.swift
//  DesignSystem
//

import SwiftUI

/// `CornerRadius` defines standardized icon sizes used throughout the Design System.
///
/// These constants ensure consistency in icon sizing across the app UI.
///
/// Example usage:
/// ```swift
/// RoundedCorner(radius: DSStyle.Sizes.CornerRadius.medium, corners: [.topLeft, .topRight])
/// ```
public extension DesignSystem.Styles.Sizes {
  struct CornerRadius {
          /// None (0pt)
          public static let none: CGFloat = 0

          /// Extra-small (4pt)
          public static let xSmall: CGFloat = 4

          /// Small (8pt)
          public static let small: CGFloat = 8

          /// Medium (12pt)
          public static let medium: CGFloat = 12
    
          /// Medium Large (16pt)
          public static let mediumLarge: CGFloat = 16

          /// Large (20pt)
          public static let large: CGFloat = 20

          /// Extra-large 1 (24pt)
          public static let xLarge1: CGFloat = 24

          /// Extra-large (28pt)
          public static let xLarge: CGFloat = 28

          /// XX-large (40pt)
          public static let xxLarge: CGFloat = 40

          /// Full (1000pt)
          public static let full: CGFloat = 1000
      }
}
