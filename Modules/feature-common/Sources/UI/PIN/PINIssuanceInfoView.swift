//
//  SwiftUIView.swift
//  feature-common
//

import SwiftUI
import logic_ui

public struct PINIssuanceInfoView<Router: RouterHost>: View {
  
  let onFindNearbyBurgerAmt: () -> Void
  let router: Router
  let isSheetPresented: Binding<Bool>
  let issuanceInteractor: IssuanceVerificationInteractor?
  
  public init(
    onFindNearbyBurgerAmt: @escaping () -> Void,
    router: Router,
    isSheetPresented: Binding<Bool>,
    issuanceInteractor: IssuanceVerificationInteractor?
  ) {
    self.onFindNearbyBurgerAmt = onFindNearbyBurgerAmt
    self.router = router
    self.isSheetPresented = isSheetPresented
    self.issuanceInteractor = issuanceInteractor
  }
  
  public var body: some View {
    ScrollView {
      VStack {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          HStack {
            Theme.shared.image.infoCircle
              .resizable()
              .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
              .foregroundColor(DSColor.onBackground)

            DSTitleLabel(.issuanceEidUnkownTitle)
              .multilineTextAlignment(.leading)
              .lineLimit(nil)
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.top, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
          
          Text(.issuanceEidUnkownParagraph1)
            .font(DSTypography.Body.large)
            .foregroundColor(DSColor.onSurface)
          
          BulletPointText(text: LocalizableStringKey .issuanceEidUnkownParagraph2.toString)
            .font(DSTypography.Body.large)
            .foregroundColor(DSColor.onSurface)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, DSStyle.Spacers.SPACING_SMALL)
          
          DSPrimaryButton(title: LocalizableStringKey.issuanceButtonKartenPin.toString) {
            isSheetPresented.wrappedValue = false
            self.hideKeyboard()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              guard let issuanceInteractor else { return }
              router.push(with: .featureIssuanceModule(.setEidTransportPinInstructionsView(
                config: NoConfig(),
                issuanceVerificationInteractor: issuanceInteractor
              )))
            }
          }
          
          BulletPointText(text: LocalizableStringKey.issuanceEidUnkownParagraph31.toString)
            .font(DSTypography.Body.large)
            .foregroundColor(DSColor.onSurface)
            .padding(.leading, DSStyle.Spacers.SPACING_SMALL)
          
          BulletPointText(text: LocalizableStringKey.issuanceEidUnkownParagraph32.toString)
            .font(DSTypography.Body.large)
            .foregroundColor(DSColor.onSurface)
            .padding(.leading, DSStyle.Spacers.SPACING_SMALL)
          
          BulletPointText(text: LocalizableStringKey.issuanceEidUnkownParagraph33.toString)
            .font(DSTypography.Body.large)
            .foregroundColor(DSColor.onSurface)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, DSStyle.Spacers.SPACING_SMALL)

          DSSecondaryButton(title: LocalizableStringKey.issuanceButtonFindBurgeramt.toString) {
            onFindNearbyBurgerAmt()
          }
          .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
        }
        Spacer()
      }
      .padding(DSStyle.Spacers.SPACING_MEDIUM)
    }
  }
}
