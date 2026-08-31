//
//  BodyLabel.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public extension DesignSystem.Components.Labels {

  /// A reusable body label styled according to the design system.
  ///
  /// `BodyLabel` renders body / paragraph copy with the design-system body
  /// typography and color so every screen body text looks the same.
  struct BodyLabel: View {

    private let text: LocalizedStringKey
    private let font: Font
    private let color: Color

    /// Creates a new `BodyLabel` with an app localizable string key.
    ///
    /// - Parameters:
    ///   - text: The `LocalizableStringKey` to display as the body text.
    ///   - font: The body font. Defaults to `DSTypography.Body.large`.
    ///   - color: The body color. Defaults to `DSColor.onBackground`.
    public init(
      _ text: LocalizableStringKey,
      font: Font = DSTypography.Body.large,
      color: Color = DSColor.onBackground
    ) {
      self.text = LocalizedStringKey(text.toString)
      self.font = font
      self.color = color
    }

    /// Creates a new `BodyLabel` with a raw string (non-localized).
    ///
    /// - Parameters:
    ///   - text: The raw string to display as the body text.
    ///   - font: The body font. Defaults to `DSTypography.Body.large`.
    ///   - color: The body color. Defaults to `DSColor.onBackground`.
    public init(
      _ text: String,
      font: Font = DSTypography.Body.large,
      color: Color = DSColor.onBackground
    ) {
      self.text = LocalizedStringKey(text)
      self.font = font
      self.color = color
    }

    public var body: some View {
      Text(text)
        .font(font)
        .foregroundStyle(color)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
