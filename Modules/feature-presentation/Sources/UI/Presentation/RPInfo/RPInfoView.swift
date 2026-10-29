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
  @State private var isCancelDialogPresented = false

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

        if let dialog = viewModel.errorDialog {
          PresentationErrorDialogView(config: dialog, onAction: viewModel.onErrorDialogAction)
            .transition(.opacity)
            .zIndex(1)
        }
      }
      .ignoresSafeArea(edges: .bottom)
      .animation(.spring, value: viewModel.errorDialog)
      .task {
        if !viewModel.viewState.initialized {
          await viewModel.doWork()
        }
      }
    }
    .cancelConfirmationDialog(
      isPresented: $isCancelDialogPresented,
      config: .pidPresentation,
      onConfirm: viewModel.confirmDecline
    )
    .centerDialog(
      isPresented: $viewModel.isConfirmationPopupVisible,
      icon: Theme.shared.image.infoCircleImage,
      title: .confirmItendificationRefusal,
      subtitle: .confirmItendificationRefusalMessage,
      buttons: declineButtons
    )
    .navigationBarBackButtonHidden()
    .background(EnableSwipeBackGesture())
  }

  private var declineButtons: [CustomAlertDialogConfig] {
    [
      .init(title: .pidPresentationDialogRpRejectionPrimButton, role: .destructive) { viewModel.confirmDecline() },
      .init(
        title: .pidPresentationDialogRpRejectionSecButton,
        role: .secondary,
        trailingIcon: Theme.shared.image.externalLink
      ) {
        viewModel.reportSuspicion()
      },
      .init(title: .pidPresentationDialogRpRejectionSecButton2, role: .secondary) {}
    ]
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
        isCancelDialogPresented = true
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
