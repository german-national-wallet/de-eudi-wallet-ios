//
//  TintedToggleStyle.swift
//  DesignSystem
//

import SwiftUI

public extension DesignSystem.Components.Toggles {
  struct TintedToggleStyle: ToggleStyle {

    private let activeBackground: Color
    private let activeBorderColor: Color
    private let activeHandleBackground: Color
    private let inactiveBackground: Color
    private let inactiveBorderColor: Color
    private let inactiveHandleBackground: Color

    private let trackWidth = 52.0
    private let trackHeight = 32.0
    private let activeHandleSize = 24.0
    private var inactiveHandleSize: CGFloat { activeHandleSize * 0.7 }
    private var handleOffsetX: CGFloat { (trackWidth - trackHeight) / 2 }

    public init(
      activeBackground: Color = DSColor.primaryContainer,
      activeBorderColor: Color = DSColor.primaryOutline,
      activeHandleBackground: Color = DSColor.background,
      inactiveBackground: Color = DSColor.surfaceContainerHighest,
      inactiveBorderColor: Color = DSColor.outline,
      inactiveHandleBackground: Color = DSColor.outline
    ) {
      self.activeBackground = activeBackground
      self.activeBorderColor = activeBorderColor
      self.activeHandleBackground = activeHandleBackground
      self.inactiveBackground = inactiveBackground
      self.inactiveBorderColor = inactiveBorderColor
      self.inactiveHandleBackground = inactiveHandleBackground
    }

    public func makeBody(configuration: Configuration) -> some View {
      HStack {
        configuration.label
        Spacer()

        ZStack {
          Capsule()
            .fill(configuration.isOn ? activeBackground : inactiveBackground)
            .frame(width: trackWidth, height: trackHeight)
            .overlay(
              Capsule()
                .strokeBorder(configuration.isOn ? activeBorderColor : inactiveBorderColor, lineWidth: 2)
            )

          Circle()
            .fill(configuration.isOn ? activeHandleBackground : inactiveHandleBackground)
            .frame(
              width: configuration.isOn ? activeHandleSize : inactiveHandleSize,
              height: configuration.isOn ? activeHandleSize : inactiveHandleSize
            )
            .offset(x: configuration.isOn ? handleOffsetX : -handleOffsetX)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
        .onTapGesture {
          configuration.isOn.toggle()
        }
      }
    }
  }
}
