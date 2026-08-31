//
//  FilledButton.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Buttons {
  struct FilledPressedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let outlineColor: Color
    let pressedBackgroundColor: Color
    let defaultBackgroundColor: Color
    let disabledBackgroundColor: Color
    let height: CGFloat
    let showsBorder: Bool
    let borderWidth: CGFloat

    public init(
      outlineColor: Color = .clear,
      pressedBackgroundColor: Color = Color.clear,
      defaultBackgroundColor: Color = DesignSystem.Styles.Colors.primary,
      disabledBackgroundColor: Color = DesignSystem.Styles.Colors.primaryContainer.opacity(0.38),
      height: CGFloat = 50,
      showsBorder: Bool = true,
      borderWidth: CGFloat = 2.0
    ) {
      self.height = height
      self.outlineColor = outlineColor
      self.pressedBackgroundColor = pressedBackgroundColor
      self.defaultBackgroundColor = defaultBackgroundColor
      self.disabledBackgroundColor = disabledBackgroundColor
      self.showsBorder = showsBorder
      self.borderWidth = borderWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
      let isPressed = configuration.isPressed
      let backgroundColor = if !isEnabled {
        disabledBackgroundColor
      } else if isPressed {
        pressedBackgroundColor
      } else {
        defaultBackgroundColor
      }

      return configuration.label
        .padding()
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, minHeight: height)
        .foregroundColor(outlineColor)
        .background(
          RoundedRectangle(cornerRadius: 100)
            .fill(backgroundColor)
        )
        .overlay(
          showsBorder ?
          RoundedRectangle(cornerRadius: 100)
            .stroke(isEnabled ? outlineColor : outlineColor.opacity(0.38), lineWidth: borderWidth)
          : nil
        )
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
  }
}

#if DEBUG
// MARK: - Previews
struct FilledButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        self.previewFilledPrimary()
        self.previewFilledSecondary()
    }
    
    static func previewFilledPrimary() -> some View {
        Button {
            
        } label: {
            Text("Filled Button Style Primary")
        }
        .buttonStyle(DSButton.FilledPressedButtonStyle(defaultBackgroundColor: DSColor.primary))
    }
    
    static func previewFilledSecondary() -> some View {
        Button {

        } label: {
            Text("Filled Button Style Secondary")
        }
        .buttonStyle(DSButton.FilledPressedButtonStyle(defaultBackgroundColor: DSColor.secondaryContainer))
    }
}
#endif
