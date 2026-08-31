//
//  SubTitleLabel.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public extension DesignSystem.Components.Labels {

  /// A reusable title label styled according to the design system.
  ///
  /// `TitleLabel` renders screen titles with the design-system title
  /// typography and color so every screen title looks the same.
  struct SubTitleLabel: View {

    private let title: LocalizedStringKey
    private let font: Font
    private let fontWeight: Font.Weight
    private let color: Color

    /// Creates a new `TitleLabel` with an app localizable string key.
    ///
    /// - Parameters:
    ///   - title: The `LocalizableStringKey` to display as the title.
    ///   - font: The title font. Defaults to `DSTypography.Title.large`.
    ///   - color: The title color. Defaults to `DSColor.onBackground`.
    public init(
      _ title: LocalizableStringKey,
      font: Font = DSTypography.Label.large,
      fontWeight: Font.Weight = DSStyle.FontWeight.medium_500,
      color: Color = DSColor.onBackground
    ) {
      self.title = LocalizedStringKey(title.toString)
      self.font = font
      self.fontWeight = fontWeight
      self.color = color
    }

    /// Creates a new `TitleLabel` with a raw string (non-localized).
    ///
    /// - Parameters:
    ///   - title: The raw string to display as the title.
    ///   - font: The title font. Defaults to `DSTypography.Title.large`.
    ///   - color: The title color. Defaults to `DSColor.onBackground`.
    public init(
      _ title: String,
      font: Font = DSTypography.Label.large,
      fontWeight: Font.Weight = DSStyle.FontWeight.medium_500,
      color: Color = DSColor.onBackground
    ) {
      self.title = LocalizedStringKey(title)
      self.font = font
      self.fontWeight = fontWeight
      self.color = color
    }

    public var body: some View {
      Text(title)
        .font(font)
        .fontWeight(fontWeight)
        .foregroundStyle(color)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
    }
  }
}
