//
//  OutlinePressedButtonStyle.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Buttons {
  struct TextButtonStyle: ButtonStyle {
    
    let outlineColor: Color
    let pressedBackgroundColor: Color
    let defaultBackgroundColor: Color
    let height: CGFloat
    
    public init(
      outlineColor: Color = Color.clear,
      pressedBackgroundColor: Color = DesignSystem.Styles.Colors.primary.opacity(0.12),
      defaultBackgroundColor: Color = Color.clear,
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
struct TextButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        self.previewTextOnRed()
        self.previewTextOnGreen()
    }

    static func previewTextOnRed() -> some View {
        VStack {
            Button {
                
            } label: {
                Text("Text Button Style")
            }
            .buttonStyle(DSButton.TextButtonStyle())
        }
        .background(Color.red)
    }
    
    static func previewTextOnGreen() -> some View {
        VStack {
            Button {
                
            } label: {
                Text("Text Button Style")
            }
            .buttonStyle(DSButton.TextButtonStyle())
        }
        .background(Color.green)
    }
}
#endif
