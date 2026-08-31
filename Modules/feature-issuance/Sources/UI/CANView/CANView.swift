//
//  CANView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import feature_common

struct CANView<Router: RouterHost>: View {
    @ObservedObject var viewModel: PINViewModel<Router>

    public init(
        viewModel: PINViewModel<Router>,
        onPinEntered: PinCallbackWrapper?
    ) {
        self.viewModel = viewModel
        self.viewModel.onPinEntered = onPinEntered
    }
    
    var body: some View {
        VStack {
          HeaderContentView(onBack: viewModel.backButtonTapped)
            VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
                DSStyle.Spacers.VSpacer.large()
                PresentationProgressView(progress: 0.5)
                    .frame(height: 10)
                
                DSTitleLabel(.cardPinEnteredWrongTwice)
                    .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)

                Spacer()
                HStack {
                    Spacer()
                    Theme.shared.image.wrongPinIcon
                        .resizable()
                        .frame(width: 179, height: 179)
                    Spacer()
                }
                
                Spacer()
                infoBubbleView

              DSPrimaryButton(title: LocalizableStringKey.canEingeben.toString) {
                viewModel.toTheCan()
              }
            }
            .padding(.horizontal)
        }
        .background(DSColor.background)
    }
  
    var infoBubbleView: some View {
      Text(LocalizableStringKey.cardPinEnteredWrongDescription.toString)
        .font(DSStyle.Typography.Body.large)
        .foregroundColor(DSColor.onBackground)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(DSColor.inverseOnSurface)
            )
    }
}
