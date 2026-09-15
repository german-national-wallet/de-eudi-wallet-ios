//
//  CardPinLetterInfoSheetView.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct CardPinLetterInfoSheetView: View {
  private let onSetCardPin: () -> Void
  private let onClose: () -> Void

  public init(
    onSetCardPin: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    self.onSetCardPin = onSetCardPin
    self.onClose = onClose
  }

  private let pinLetterWidth: CGFloat = 108

  public var body: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
      ScrollView {
        VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          Theme.shared.image.help
            .resizable()
            .scaledToFit()
            .frame(
              width: DSStyle.Sizes.Icons.large,
              height: DSStyle.Sizes.Icons.large
            )
            .foregroundColor(DSColor.onBackground)

          Text(.pidCardPinLetterInfoTitle)
            .font(DSTypography.Title.large)
            .foregroundColor(DSColor.onBackground)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)

          DSInfoCardView(
            title: .pidCardPinLetterInfoHeadline1,
            message: .pidCardPinLetterInfoParagraph1
          ) {
            PIDCredentialCardView(
              credentialTitle: LocalizableStringKey.dashboardCardTitle.toString,
              issuer: LocalizableStringKey.dashboardCardIssuer.toString
            )
          }

          DSInfoCardView(
            title: .pidCardPinLetterInfoHeadline2,
            message: .pidCardPinLetterInfoParagraph2,
            image: Theme.shared.image.tranportPinLetter,
            imagePlacement: .aboveMessage,
            imageWidth: pinLetterWidth,
            buttonTitle: .pidCardPinLetterInfoSecButton,
            buttonAction: onSetCardPin
          )
        }
        .padding(.top, DSStyle.Spacers.SPACING_LARGE)
      }

      DSSecondaryButton(
        title: LocalizableStringKey.globalCloseHintButton.toString,
        action: onClose
      )
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .background(DSColor.background)
  }
}
