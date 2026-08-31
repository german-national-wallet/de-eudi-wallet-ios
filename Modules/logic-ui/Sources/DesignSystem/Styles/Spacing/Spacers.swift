//
//  VSpacer.swift
//  DesignSystem
//

import SwiftUI
import Foundation

@MainActor
public extension DesignSystem.Styles.Spacers {
  
  static let SPACING_NONE: CGFloat = 0
  static let SPACING_EXTRA_SMALL: CGFloat = 4
  static let SPACING_SMALL: CGFloat = 8
  static let SPACING_MEDIUM_SMALL: CGFloat = 12
  static let SPACING_MEDIUM: CGFloat = 16
  static let SPACING_MEDIUM_LARGE: CGFloat = 20
  static let SPACING_LARGE_MEDIUM: CGFloat = 24
  static let SPACING_LARGE: CGFloat = 32
  static let SPACING_EXTRA_LARGE: CGFloat = 48
  static let SPACING_JUMBO: CGFloat = 96
  static let SPACING_XXL: CGFloat = 120
    
  @MainActor
  struct VSpacer {
    public static func custom(size: CGFloat) -> some View {
      return Spacer().frame(height: size)
    }
    
    public static func extraSmall() -> some View {
      return Spacer().frame(height: SPACING_EXTRA_SMALL)
    }
    
    public static func small() -> some View {
      return Spacer().frame(height: SPACING_SMALL)
    }
    
    public static func mediumSmall() -> some View {
      return Spacer().frame(height: SPACING_MEDIUM_SMALL)
    }
    
    public static func medium() -> some View {
      return Spacer().frame(height: SPACING_MEDIUM)
    }
    
    public static func mediumLarge() -> some View {
      return Spacer().frame(height: SPACING_MEDIUM_LARGE)
    }
    
    public static func largeMedium() -> some View {
      return Spacer().frame(height: SPACING_LARGE_MEDIUM)
    }
    
    public static func large() -> some View {
      return Spacer().frame(height: SPACING_LARGE)
    }
    
    public static func extraLarge() -> some View {
      return Spacer().frame(height: SPACING_EXTRA_LARGE)
    }
    
    public static func jumbo() -> some View {
      return Spacer().frame(height: SPACING_JUMBO)
    }
  }
  
  @MainActor
  struct HSpacer {
    
    public static func custom(size: CGFloat) -> some View {
      return Spacer().frame(width: size)
    }
    
    public static func extraSmall() -> some View {
      return Spacer().frame(width: SPACING_EXTRA_SMALL)
    }
    
    public static func small() -> some View {
      return Spacer().frame(width: SPACING_SMALL)
    }
    
    public static func mediumSmall() -> some View {
      return Spacer().frame(width: SPACING_MEDIUM_SMALL)
    }
    
    public static func medium() -> some View {
      return Spacer().frame(width: SPACING_MEDIUM)
    }
    
    public static func mediumLarge() -> some View {
      return Spacer().frame(width: SPACING_MEDIUM_LARGE)
    }
    
    public static func largeMedium() -> some View {
      return Spacer().frame(width: SPACING_LARGE_MEDIUM)
    }
    
    public static func large() -> some View {
      return Spacer().frame(width: SPACING_LARGE)
    }
    
    public static func extraLarge() -> some View {
      return Spacer().frame(width: SPACING_EXTRA_LARGE)
    }
  }
}
