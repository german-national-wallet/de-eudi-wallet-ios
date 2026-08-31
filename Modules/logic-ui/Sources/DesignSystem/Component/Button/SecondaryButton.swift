//
//  SecondaryButton.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Buttons {
  
  /// A reusable secondary button styled according to the design system.
  ///
  /// `SecondaryButton` provides a full-width, accessibility-friendly button
  /// that supports multi-line text and dynamic font scaling.
  /// It uses `DSButton.FilledPressedButtonStyle` for consistent styling.
  struct SecondaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: String
    private let action: () -> Void
    private let icon: Image?
    private let trailingIcon: Image?
    private let backgroundColor: Color
    private let showsBorder: Bool

    /// Creates a new `PrimaryButton` with a raw string (non-localized).
    ///
    /// - Parameters:
    ///   - title: The raw string to display on the button.
    ///   - icon: Takes an icon to show on left side of the tittle.
    ///   - trailingIcon: Takes an icon to show on right side of the title.
    ///   - action: A closure to execute when the button is tapped.
    public init(
      title: String,
      icon: Image? = nil,
      trailingIcon: Image? = nil,
      showsBorder: Bool = true,
      backgroundColor: Color = .clear,
      action: @escaping () -> Void
    ) {
      self.title = title
      self.action = action
      self.icon = icon
      self.trailingIcon = trailingIcon
      self.backgroundColor = backgroundColor
      self.showsBorder = showsBorder
    }

    public var body: some View {
      Button(action: action) {
        HStack(spacing: 8) {
          Spacer()
          if let icon {
            icon
              .resizable()
              .frame(width: 16, height: 16)
              .foregroundColor(isEnabled ? DSColor.onBackground : DSColor.onSurfaceVariant)
          }
          Text(title)
            .font(DSTypography.Label.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundColor(isEnabled ? DSColor.onBackground : DSColor.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .lineLimit(DSStyle.LineLimits.two)
            .minimumScaleFactor(0.8)
            .fixedSize(horizontal: false, vertical: true)
          if let trailingIcon {
            // Template rendered so the glyph follows the label, as the bundled icons carry their own
            // colour and would stay black in dark mode.
            trailingIcon
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .frame(width: 16, height: 16)
              .foregroundColor(isEnabled ? DSColor.onBackground : DSColor.onSurfaceVariant)
              .accessibilityHidden(true)
          }
          Spacer()
        }
      }
      .buttonStyle(
        DSButton.FilledPressedButtonStyle(
          outlineColor: DSColor.outline,
          pressedBackgroundColor: DSColor.onSecondaryContainer.opacity(0.12),
          defaultBackgroundColor: backgroundColor,
          borderWidth: 1
        ))
    }
  }
}
