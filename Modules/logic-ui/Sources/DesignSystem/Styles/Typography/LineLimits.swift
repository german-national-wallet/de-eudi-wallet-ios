//
//  LineLimits.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Styles.LineLimits {
  /// No line limit.
  /// Text will expand vertically to fit its content.
  static let unlimited: Int? = nil
  
  /// Single-line text.
  /// Commonly used for titles, buttons, and labels that must stay compact.
  static let one: Int = 1
  
  /// Two-line text.
  /// Suitable for subtitles, secondary labels, or compact descriptions.
  static let two: Int = 2
  
  /// Three-line text.
  /// Ideal for short descriptions or preview text.
  static let three: Int = 3
  
  /// Four-line text.
  /// Used when slightly more content is allowed without breaking layouts.
  static let four: Int = 4
}
