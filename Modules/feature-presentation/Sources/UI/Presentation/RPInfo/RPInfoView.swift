//
//  RPInfoView.swift
//  feature-presentation
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct RPInfoView<Router: RouterHost>: View {
  @ObservedObject var viewModel: RPInfoViewModel<Router>
  
  public init(
    viewModel: RPInfoViewModel<Router>
  ) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    ContentScreenView {
      ZStack {
        RPInfoViewContent(
          viewState: viewModel.viewState,
          getScreenRect: getScreenRect(),
          continueAction: viewModel.onContinue,
          declineAction: viewModel.onDecline,
          viewDetailsAction: viewModel.onViewDetails,
          showDetailsSheet: $viewModel.isRequestInfoModalShowing
        )
        .shimmer(isLoading: viewModel.viewState.isLoading)
        
        if viewModel.isConfirmationPopupVisible {
          ConfirmationPopupView(viewModel: viewModel.confirmationPopupViewModel)
        }
      }
      .ignoresSafeArea(edges: .bottom)
      .animation(.spring, value: viewModel.isConfirmationPopupVisible)
      .task {
        if !viewModel.viewState.initialized {
          await viewModel.doWork()
        }
      }
    }
    .navigationBarBackButtonHidden()
    .background(EnableSwipeBackGesture())
  }
  
  @MainActor
  @ViewBuilder
  private func RPInfoViewContent(
    viewState: RequestViewState,
    getScreenRect: CGRect,
    continueAction: @escaping () -> Void,
    declineAction: @escaping () -> Void,
    viewDetailsAction: @escaping () -> Void,
    showDetailsSheet: Binding<Bool>
  ) -> some View {
    
    VStack {
      HeaderContentView(onClose: {
        self.viewModel.router.pop()
      })
      
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
          DSTitleLabel(.presentationConfirmationTitle([viewState.relyingParty.toString]))
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
          
          Text(viewState.relyingParty.toString)
            .font(DSTypography.Headline.small)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundColor(DSColor.onBackground)

          Text(.presentationConfirmationDescription1([""]))
            .font(DSTypography.Body.large)
            .fontWeight(DSStyle.FontWeight.regular_400)
            .foregroundColor(DSColor.onSurfaceVariant)
          
          Text(.presentationConfirmationDescription2([""]))
            .font(DSTypography.Body.large)
            .fontWeight(DSStyle.FontWeight.regular_400)
            .foregroundColor(DSColor.onSurfaceVariant)
        }
        Spacer()
        
        HStack {
          DSSecondaryButton(title: LocalizableStringKey.reject.toString, action: declineAction)
          DSPrimaryButton(title: LocalizableStringKey.next.toString, action: continueAction)
            .accessibilityIdentifier("rpInfoNextButton")
        }
        
        DSStyle.Spacers.VSpacer.medium()
        
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.vertical)
    }
  }
}
