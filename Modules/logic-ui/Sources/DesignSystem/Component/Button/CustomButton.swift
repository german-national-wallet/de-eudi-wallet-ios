//
//  CustomButton.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Buttons {
  
  /// A reusable custom button styled according to the design system.
  ///
  /// `CustomButton` provides a full-width, accessibility-friendly button
  /// that supports multi-line text and dynamic font scaling.
  /// It uses `DSButton.FilledPressedButtonStyle` for consistent styling.
  struct CustomButton: View {
    @Environment(\.isEnabled) private var isEnabled

    private let title: LocalizedStringKey
    private let action: () -> Void
    private let backgroundColor: Color

    /// Creates a new `CustomButton` with a localizable string key.
    ///
    /// - Parameters:
    ///   - title: The `LocalizedStringKey` to display as the button label.
    ///   - action: A closure to execute when the button is tapped.
    ///   - backgroundColor: Sets the background color.
    public init(title: LocalizedStringKey, backgroundColor: Color, action: @escaping () -> Void) {
      self.title = title
      self.action = action
      self.backgroundColor = backgroundColor
    }

    /// Creates a new `CustomButton` with a raw string (non-localized).
    ///
    /// - Parameters:
    ///   - title: The raw string to display on the button.
    ///   - action: A closure to execute when the button is tapped.
    ///   - backgroundColor: Sets the background color.
    public init(title: String, backgroundColor: Color, action: @escaping () -> Void) {
      self.title = LocalizedStringKey(title)
      self.action = action
      self.backgroundColor = backgroundColor
    }

    public var body: some View {
      Button(action: action) {
        Text(title)
          .font(DSTypography.Label.large)
          .fontWeight(DSStyle.FontWeight.medium_500)
          .foregroundColor(isEnabled ? DSColor.onColorPID : DSColor.onSurfaceVariant)
          .multilineTextAlignment(.center)
          .lineLimit(DSStyle.LineLimits.two)
          .minimumScaleFactor(0.8)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(DSButton.FilledPressedButtonStyle(
        outlineColor: .clear,
        defaultBackgroundColor: backgroundColor
      ))
    }
  }
}

#if DEBUG
// MARK: - Previews
struct CustomButton_Previews: PreviewProvider {
    static var previews: some View {
        self.previewCustomButtonPrimary()
        self.previewCustomButtonSecondary()
    }
    
    static func previewCustomButtonPrimary() -> some View {
        DSCustomButton(
          title: "Custom Button (primary)",
          backgroundColor: DSColor.primary,
          action: {}
        )
    }
    
    static func previewCustomButtonSecondary() -> some View {
        DSCustomButton(
          title: "Custom Button (secondary)",
          backgroundColor: DSColor.secondaryContainer,
          action: {}
        )
    }
}
#endif
