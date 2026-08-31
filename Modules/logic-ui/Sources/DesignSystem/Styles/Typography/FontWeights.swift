//
//  FontWeight.swift
//  DesignSystem
//
import SwiftUI

public extension DesignSystem.Styles.FontWeight {
  /// Predefined font weights
  static let ultraLight_100 = Font.Weight.ultraLight
  static let thin_200 = Font.Weight.thin
  static let light_300 = Font.Weight.light
  static let regular_400 = Font.Weight.regular
  static let medium_500 = Font.Weight.medium
  static let semibold_600 = Font.Weight.semibold
  static let bold_700 = Font.Weight.bold
  static let heavy_800 = Font.Weight.heavy
  static let black_900 = Font.Weight.black
  
  /// Function to get font weight from an integer value
  static func weight(from value: Int) -> Font.Weight {
    switch value {
    case 100: return .ultraLight
    case 200: return .thin
    case 300: return .light
    case 400: return .regular
    case 500: return .medium
    case 600: return .semibold
    case 700: return .bold
    case 800: return .heavy
    case 900: return .black
    default: return .regular
    }
  }
}
