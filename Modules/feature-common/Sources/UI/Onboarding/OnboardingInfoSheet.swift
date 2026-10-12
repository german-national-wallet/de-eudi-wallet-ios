//
//  OnboardingInfoSheet.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct OnboardingInfoSheet: View {

  private let title: LocalizableStringKey
  private let message: LocalizableStringKey
  private let buttonTitle: LocalizableStringKey
  private let buttonAccessibilityIdentifier: String?
  private let action: () -> Void

  private let iconSize: CGFloat = 24
  private let sheetHeight: CGFloat = 317

  public init(
    title: LocalizableStringKey,
    message: LocalizableStringKey,
    buttonTitle: LocalizableStringKey,
    buttonAccessibilityIdentifier: String? = nil,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.message = message
    self.buttonTitle = buttonTitle
    self.buttonAccessibilityIdentifier = buttonAccessibilityIdentifier
    self.action = action
  }

  public var body: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      Image(systemName: "info.circle")
        .resizable()
        .scaledToFit()
        .frame(width: iconSize, height: iconSize)
        .foregroundStyle(DSColor.onSurface)
        .accessibilityHidden(true)

      Text(title)
        .font(DSTypography.Title.large)
        .foregroundStyle(DSColor.onSurface)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityAddTraits(.isHeader)

      Text(message)
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onSurface)
        .frame(maxWidth: .infinity, alignment: .leading)

      Spacer(minLength: DSStyle.Spacers.SPACING_MEDIUM)

      DSPrimaryButton(title: buttonTitle.toString, action: action)
        .if(buttonAccessibilityIdentifier != nil) { view in
          view.accessibilityIdentifier(buttonAccessibilityIdentifier!)
        }
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_LARGE)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DSColor.background)
    .presentationDetents([.height(sheetHeight)])
    .presentationDragIndicator(.hidden)
    .sheetCornerRadius(DSStyle.Sizes.CornerRadius.xxLarge)
  }
}

private extension View {
  @ViewBuilder
  func sheetCornerRadius(_ radius: CGFloat) -> some View {
    if #available(iOS 16.4, *) {
      presentationCornerRadius(radius)
    } else {
      self
    }
  }
}
