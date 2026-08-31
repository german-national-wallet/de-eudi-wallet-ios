//
//  PrimaryButton.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Buttons {
  
  /// A reusable primary button styled according to the design system.
  ///
  /// `PrimaryButton` provides a full-width, accessibility-friendly button
  /// that supports multi-line text and dynamic font scaling.
  /// It uses `DSButton.FilledPressedButtonStyle` for consistent styling.
  struct PrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: LocalizedStringKey
    private let action: () -> Void
    private let trailingIcon: Image?

    /// Creates a new `PrimaryButton` with a localizable string key.
    ///
    /// - Parameters:
    ///   - title: The `LocalizedStringKey` to display as the button label.
    ///   - trailingIcon: Takes an icon to show on the right side of the title.
    ///   - action: A closure to execute when the button is tapped.
    public init(
      title: LocalizedStringKey,
      trailingIcon: Image? = nil,
      action: @escaping () -> Void
    ) {
      self.title = title
      self.trailingIcon = trailingIcon
      self.action = action
    }

    /// Creates a new `PrimaryButton` with a raw string (non-localized).
    ///
    /// - Parameters:
    ///   - title: The raw string to display on the button.
    ///   - trailingIcon: Takes an icon to show on the right side of the title.
    ///   - action: A closure to execute when the button is tapped.
    public init(
      title: String,
      trailingIcon: Image? = nil,
      action: @escaping () -> Void
    ) {
      self.title = LocalizedStringKey(title)
      self.trailingIcon = trailingIcon
      self.action = action
    }

    public var body: some View {
      Button(action: action) {
        HStack(spacing: 8) {
          Text(title)
            .font(DSTypography.Label.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundColor(isEnabled ? DSColor.onBackground : DSColor.onBackground.opacity(0.38))
            .multilineTextAlignment(.center)
            .lineLimit(DSStyle.LineLimits.two)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
          if let trailingIcon {
            trailingIcon
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 16, height: 16)
              .foregroundColor(isEnabled ? DSColor.onBackground : DSColor.onBackground.opacity(0.38))
              .accessibilityHidden(true)
          }
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(
        DSButton.FilledPressedButtonStyle(
          outlineColor: DSColor.primaryOutline,
          pressedBackgroundColor: DSColor.primaryContainer.opacity(0.36),
          defaultBackgroundColor: DSColor.primaryContainer,
          borderWidth: 1
        ))
    }
  }
}
