//
//  TextButtonStyle.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Buttons {
  struct TonalButtonStyle: ButtonStyle {
    
    let outlineColor: Color
    let pressedBackgroundColor: Color
    let defaultBackgroundColor: Color
    let height: CGFloat
    
    public init(
      outlineColor: Color = Color.clear,
      pressedBackgroundColor: Color = DesignSystem.Styles.Colors.primary.opacity(0.12),
      defaultBackgroundColor: Color = DesignSystem.Styles.Colors.secondary,
      height: CGFloat = 50
    ) {
      self.height = height
      self.outlineColor = outlineColor
      self.pressedBackgroundColor = pressedBackgroundColor
      self.defaultBackgroundColor = defaultBackgroundColor
    }
    
    public func makeBody(configuration: Configuration) -> some View {
      let isPressed = configuration.isPressed
      
      return configuration.label
        .padding()
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
        .overlay(
          RoundedRectangle(cornerRadius: 100)
            .stroke(outlineColor, lineWidth: 2.0)
        )
        .foregroundColor(outlineColor)
        .background(
          RoundedRectangle(cornerRadius: 100)
            .fill(isPressed ? pressedBackgroundColor : defaultBackgroundColor)
        )
        .animation(.easeInOut, value: 0.33)
    }
  }
}

#if DEBUG
// MARK: - Previews
struct TonalButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        self.previewTonal()
    }

    static func previewTonal() -> some View {
        Button {
            
        } label: {
            Text("Tonal Button Style")
        }
        .buttonStyle(DSButton.TonalButtonStyle())
    }
}
#endif
