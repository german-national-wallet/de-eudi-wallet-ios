//
//  Buttons.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Buttons {
  struct OutlinePressedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let outlineColor: Color
    let pressedBackgroundColor: Color
    let defaultBackgroundColor: Color
    let disabledBackgroundColor: Color
    let height: CGFloat
    let showsBorder: Bool

    public init(
      outlineColor: Color = .clear,
      pressedBackgroundColor: Color = DesignSystem.Styles.Colors.primary.opacity(0.8),
      defaultBackgroundColor: Color = Color.clear,
      disabledBackgroundColor: Color = DesignSystem.Styles.Colors.onPrimaryContainer,
      height: CGFloat = 50,
      showsBorder: Bool = true
    ) {
      self.height = height
      self.outlineColor = outlineColor
      self.pressedBackgroundColor = pressedBackgroundColor
      self.defaultBackgroundColor = defaultBackgroundColor
      self.disabledBackgroundColor = disabledBackgroundColor
      self.showsBorder = showsBorder
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
        .frame(maxWidth: .infinity, minHeight: height)
        .contentShape(Rectangle())
        .foregroundColor(outlineColor)
        .background(
          RoundedRectangle(cornerRadius: 100)
            .fill(backgroundColor)
        )
        .overlay(
          showsBorder && isEnabled ?
          RoundedRectangle(cornerRadius: 100)
            .stroke(outlineColor, lineWidth: 1.0)
          : nil
        )
        .animation(.easeInOut(duration: 0.2), value: isPressed)
    }
  }
}

#if DEBUG
// MARK: - Previews
struct OutlinedButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        self.previewOutlined()
    }

    static func previewOutlined() -> some View {
        Button {
            
        } label: {
            Text("Outlined Button Style")
        }
        .buttonStyle(DSButton.OutlinePressedButtonStyle())
    }
}
#endif
