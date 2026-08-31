//
//  IllustratedNoticeView.swift
//  feature-common
//
//  Implemented from Figma "PID Issuance", Blocking Error information (node 731:41777).
//

import SwiftUI
import logic_ui
import logic_resources
import logic_core

public struct IllustratedNoticeView: View {
  private let config: IllustratedNoticeUiConfig
  private let onBack: () -> Void

  public init(config: any UIConfigType, onBack: @escaping () -> Void) {
    guard let config = config as? IllustratedNoticeUiConfig else {
      fatalError("IllustratedNoticeView:: Invalid configuraton")
    }
    self.config = config
    self.onBack = onBack
  }

  public var body: some View {
    ContentScreenView(padding: .zero, background: DSColor.background) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          illustration

          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
            DSTitleLabel(config.title)
              .frame(maxWidth: .infinity, alignment: .leading)
              .accessibilityAddTraits(.isHeader)

            DSBodyLabel(config.message)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
          .padding(.top, DSStyle.Spacers.SPACING_LARGE)
        }
      }

      DSPrimaryButton(
        title: config.primaryButtonTitle.toString,
        trailingIcon: trailingIcon,
        action: performPrimaryAction
      )
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .ignoresSafeArea(edges: .top)
  }

  @ViewBuilder private var illustration: some View {
    ZStack(alignment: .topLeading) {
      if let image = config.illustration {
        image
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity)
          .aspectRatio(1, contentMode: .fit)
          .clipped()
      } else {
        DSColor.surfaceContainer
          .frame(maxWidth: .infinity)
          .aspectRatio(1, contentMode: .fit)
      }

      Button(action: onBack) {
        Theme.shared.image.chevronLeft
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
          .foregroundColor(DSColor.onBackground)
          .padding(DSStyle.Spacers.SPACING_SMALL)
          .background(DSColor.secondaryContainer)
          .clipShape(Circle())
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_EXTRA_LARGE)
      .accessibilityLabel(Text(LocalizableStringKey.back.toLocalizedStringKey))
    }
  }

  private var trailingIcon: Image? {
    switch config.primaryAction {
    case .findBurgeramt: Theme.shared.image.externalLink
    case .dismiss: nil
    }
  }

  private func performPrimaryAction() {
    switch config.primaryAction {
    case .findBurgeramt:
      if let url = AppEnvironment.burgeramtServiceLink {
        UIApplication.shared.open(url)
      }
    case .dismiss:
      onBack()
    }
  }
}
