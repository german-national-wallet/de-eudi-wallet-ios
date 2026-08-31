//
//  BottomSheetViewWithAction.swift
//  DesignSystem
//

import SwiftUI

@available(iOS 16.0, *)
public struct BottomSheetViewWithAction: View {
  let title: String
  let message: String
  let buttonTitle: String
  let action: () -> Void
  
  public init(
    title: String,
    message: String,
    buttonTitle: String,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.message = message
    self.buttonTitle = buttonTitle
    self.action = action
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      
      HStack(spacing: 16) {
        Image(systemName: "info.circle")
          .resizable()
          .foregroundColor(DesignSystem.Styles.Colors.onBackground)
          .frame(width: 42, height: 42)
        
        DSTitleLabel(title)
          .font(DesignSystem.Styles.Typography.Title.large)
          .foregroundStyle(DesignSystem.Styles.Colors.primary)
          .fontWeight(DesignSystem.Styles.FontWeight.medium_500)
      }
      .padding(.top, 32)
      
      ScrollView {
        Text(message)
          .font(DesignSystem.Styles.Typography.Body.large)
          .foregroundStyle(DesignSystem.Styles.Colors.onSurface)
          .fontWeight(DesignSystem.Styles.FontWeight.regular_400)
          .lineSpacing(8)
          .kerning(DesignSystem.Styles.FontKerning.regular)
        
      }
      Spacer()
      
      Button(
        action: action,
        label: {
          HStack(spacing: 8) {
            Spacer()
            Text(buttonTitle)
              .font(DSTypography.Label.large)
              .foregroundStyle(DSColor.onBackground)
            Spacer()
          }
        })
      .buttonStyle(DSButton.OutlinePressedButtonStyle())

    }
    .padding()
    .frame(height: UIScreen.main.bounds.height * 0.5)
    .background(DesignSystem.Styles.Colors.background)
    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
    .presentationDetents([.medium])
  }
}
