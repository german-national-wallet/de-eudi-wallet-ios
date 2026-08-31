//
//  AppBlockingView.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct AppBlockingView: View {

  private let title: String
  private let description: String
  private let buttonTitle: String
  private let action: () -> Void

  public init(
    title: String,
    description: String,
    buttonTitle: String,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.description = description
    self.buttonTitle = buttonTitle
    self.action = action
  }

  private let infoBubbleCornerRadius = 20.0

  public var body: some View {
    VStack {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        DSStyle.Spacers.VSpacer.large()
        Text(title)
          .foregroundStyle(DSColor.primary)
          .font(DSTypography.Title.large)
          .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
        Spacer()
        HStack {
          Spacer()
          Theme.shared.image.securityCheckIcon
            .resizable()
            .frame(width: 328, height: 294)
          Spacer()
        }
        
        Spacer()
        infoBubbleView
        DSPrimaryButton(title: buttonTitle, action: action)
      }
      .padding(.horizontal)
    }
    .background(DSColor.background)
  }

  private var infoBubbleView: some View {
    Text(description)
      .font(DSStyle.Typography.Body.large)
      .foregroundColor(DSColor.onSurface)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: infoBubbleCornerRadius)
          .fill(DSColor.inverseOnSurface)
      )
  }
}
