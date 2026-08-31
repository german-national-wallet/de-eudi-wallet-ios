//
//  InvalidPINView.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

struct InvalidPINView<Router: RouterHost>: View {
  @ObservedObject var viewModel: InvalidPINViewModel<Router>
  
  init(with viewModel: InvalidPINViewModel<Router>) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    ContentScreenView(padding: 0) {
      VStack(alignment: .leading) {
        HeaderContentView(onClose: viewModel.onCancelButtonClicked)
        
        DSTitleLabel(viewModel.viewState.config.title)
        
        Spacer()
        
        HStack {
          Spacer()
          Theme.shared.image.wrongPinIcon
            .resizable()
            .frame(width: 179, height: 179)
          Spacer()
        }
        
        Spacer()
        
        if let caption = viewModel.viewState.config.caption?.toString.extractBoldAndRegularText(font: DSTypography.Body.large) {
          caption
            .font(DSTypography.Body.large)
            .fontWeight(DSStyle.FontWeight.regular_400)
            .foregroundColor(DSColor.primary)
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
            )
        }
        DSPrimaryButton(title: viewModel.viewState.config.primaryButtonTitle.toString) {
          viewModel.onPrimaryActionButtonClicked()
        }

        if let secondaryButtonTitle = viewModel.viewState.config.secondaryButtonTitle {
          DSSecondaryButton(title: secondaryButtonTitle.toString) {
            viewModel.onSecondaryActionButtonClicked()
          }
        }
      }
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .background(DSColor.background)
    .sheet(isPresented: $viewModel.showActionSheet) {
      if viewModel.viewState.config.pinScreenType == .eidCanFlow {
        CanInfoView()
          .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
          .presentationDetents([.height(600)])
          .background(DSColor.background)
          .ignoresSafeArea()
      } else if viewModel.viewState.config.pinScreenType == .issueEidPinFlow {
        PINIssuanceInfoView(
          onFindNearbyBurgerAmt: viewModel.openBurgeramtWebpage,
          router: viewModel.router,
          isSheetPresented: $viewModel.showActionSheet,
          issuanceInteractor: nil
        )
        .background(DSColor.background)
          .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
          .ignoresSafeArea()
          .presentationDetents([.fraction(0.7)])
      } else {
        BottomSheetView(
          title: LocalizableStringKey.whatIsSecurityPassword.toString,
          message: LocalizableStringKey.whatIsSecurityPasswordMessage.toString
        )
        .presentationDetents([.medium])
      }
    }
  }
}
