//
//  TitleLabel.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public extension DesignSystem.Components.Labels {

  /// A reusable title label styled according to the design system.
  ///
  /// `TitleLabel` renders screen titles with the design-system title
  /// typography and color so every screen title looks the same.
  struct TitleLabel: View {

    private let title: LocalizedStringKey
    private let font: Font
    private let color: Color

    /// Creates a new `TitleLabel` with an app localizable string key.
    ///
    /// - Parameters:
    ///   - title: The `LocalizableStringKey` to display as the title.
    ///   - font: The title font. Defaults to `DSTypography.Title.large`.
    ///   - color: The title color. Defaults to `DSColor.onBackground`.
    public init(
      _ title: LocalizableStringKey,
      font: Font = DSTypography.Title.large,
      color: Color = DSColor.onBackground
    ) {
      self.title = LocalizedStringKey(title.toString)
      self.font = font
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
      font: Font = DSTypography.Title.large,
      color: Color = DSColor.onBackground
    ) {
      self.title = LocalizedStringKey(title)
      self.font = font
      self.color = color
    }

    public var body: some View {
      Text(title)
        .font(font)
        .foregroundStyle(color)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)
    }
  }
}
