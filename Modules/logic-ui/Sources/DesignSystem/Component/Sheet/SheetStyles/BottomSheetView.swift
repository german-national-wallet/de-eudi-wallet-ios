//
//  BottomSheetView.swift
//  DesignSystem
//
import SwiftUI

@available(iOS 16.0, *)
public struct BottomSheetView: View {
  let title: String
  let message: String
  
  public init(title: String, message: String) {
    self.title = title
    self.message = message
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      
      HStack(spacing: 16) {
        Image(systemName: "info.circle")
          .resizable()
          .foregroundColor(DesignSystem.Styles.Colors.onBackground)
          .frame(width: 42, height: 42)
        
        DSTitleLabel(title)
      }
      .padding(.top, 32)
      Text(message)
        .font(DesignSystem.Styles.Typography.Body.large)
        .foregroundStyle(DesignSystem.Styles.Colors.onBackground)
        .fontWeight(DesignSystem.Styles.FontWeight.regular_400)
      
      Spacer()
    }
    .padding()
    .frame(height: UIScreen.main.bounds.height * 0.5)
    .background(DesignSystem.Styles.Colors.background)
    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
    .presentationDetents([.medium])
  }
}
