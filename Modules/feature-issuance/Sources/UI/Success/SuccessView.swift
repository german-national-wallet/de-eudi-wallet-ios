//
//  SuccessView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources

struct SuccessView<Router: RouterHost>: View {
  @ObservedObject var viewModel: SuccessViewModel<Router>
  
  init(viewModel: SuccessViewModel<Router>) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    VStack {
      ContentScreenView(padding: DSStyle.Spacers.SPACING_MEDIUM) {
        ScrollView {
          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {

            DSTitleLabel(viewModel.viewState.config.title.value)
              .padding(.top, DSStyle.Spacers.SPACING_LARGE)
              .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM)
            
            Spacer(minLength: DSStyle.Spacers.SPACING_JUMBO)
            
            HStack {
              Spacer()
              Theme.shared.image.checkCircle
                .resizable()
                .frame(width: DSIconSize.xxxLarge, height: DSIconSize.xxxLarge)
              Spacer()
            }
            
            Spacer(minLength: DSStyle.Spacers.SPACING_JUMBO)
            
            if let rawMessage = viewModel.viewState.config.description?.toString.extractBoldAndRegularText(font: DSTypography.Body.large) {
              rawMessage
                .padding()
                .background {
                  RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
                .kerning(DSStyle.FontKerning.regular)
                .lineSpacing(0.5)
              
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        
        if viewModel.viewState.config.viewType == .canCorrect {
          VStack {
            DSPrimaryButton(
              title: LocalizableStringKey.canCorrectPrimButton.toString,
              action: viewModel.primaryButtonPressed
            )
            DSSecondaryButton(
              title: LocalizableStringKey.canCorrectSecButton.toString,
              action: viewModel.secondaryButtonPressed
            )
          }
          .padding()
        }
      }
    }
    .onAppear {
      if viewModel.viewState.config.viewType != .canCorrect {
        viewModel.navigateTo()
      }
    }
  }
}
