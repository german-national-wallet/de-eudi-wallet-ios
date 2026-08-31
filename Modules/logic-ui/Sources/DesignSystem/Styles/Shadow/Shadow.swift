//
//  Shadow.swift
//  logic-ui
//

import SwiftUI

/// Drop-shadow tokens for the design system.
///
/// Example usage:
/// ```swift
/// someView.dsShadow(DSShadow.card)
/// ```
public extension DesignSystem.Styles.Shadow {

  /// A single drop-shadow definition.
  ///
  /// Note: SwiftUI shadows have no "spread", and Figma's blur maps to roughly
  /// half its value as a SwiftUI radius (e.g. Figma blur 8 ≈ radius 4).
  struct Style {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
      self.color = color
      self.radius = radius
      self.x = x
      self.y = y
    }
  }

  /// Card drop shadow — Figma: X 0, Y 2, Blur 8, Spread 0, #1D1D1E @ 20%.
  static let card = Style(
    color: Color(hex: "#1D1D1E").opacity(0.2),
    radius: 4,
    x: 0,
    y: 2
  )
}

public extension View {
  /// Applies a design-system drop-shadow token.
  func dsShadow(_ style: DesignSystem.Styles.Shadow.Style) -> some View {
    shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
  }
}
