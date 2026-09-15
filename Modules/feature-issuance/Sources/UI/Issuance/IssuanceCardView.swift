//
//  SwiftUIView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct IssuanceCardView<Router: RouterHost>: View {
  @ObservedObject var viewModel: IssuanceCardViewModel<Router>

  @State private var isCancelDialogPresented = false

  init(with viewModel: IssuanceCardViewModel<Router>) {
      self.viewModel = viewModel
  }

  private var progressSteps: (current: Int, total: Int)? {
    guard viewModel.viewState.eidFlow == .authentication,
          !viewModel.viewState.config.isExtraDocumentFlow else {
      return nil
    }
    return (current: 3, total: 4)
  }

  var body: some View {
    ContentScreenView(
      padding: .zero,
      isLoading: viewModel.viewState.isLoading
    ) {
      HeaderContentView(
        onBack: viewModel.backButtonTapped,
        onClose: { isCancelDialogPresented = true },
        onHelp: viewModel.viewHelpAndTips,
        progress: progressSteps
      )

      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
        DSTitleLabel(viewModel.viewState.navigationTitle)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)

        VideoAnimationView(
          asset: .nfcTappingTop,
          size: Constants.scanAnimationSize,
          playCount: Constants.scanAnimationPlayCount
        )
        .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)

        scanningHintBanner

        Spacer()

        DSPrimaryButton(title: LocalizableStringKey.restartScanning.toString, action: viewModel.startAusweisReadFlow)
          .shimmer(isLoading: viewModel.viewState.isLoading)
          .accessibilityIdentifier("issuanceCardStartScanningButton")

        DSSecondaryButton(title: LocalizableStringKey.scanningTips.toString, action: viewModel.viewHelpAndTips)
          .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
      .shimmer(isLoading: viewModel.viewState.isLoading)
      .sheet(isPresented: $viewModel.showHelpAndTipsActionSheet, content: {
        CardScanningTipsPopupView(
          contactCustomerCareAction: viewModel.contactCustomerCareTapped,
          onClose: { viewModel.showHelpAndTipsActionSheet = false }
        )
        .presentationDetents([.medium])
      })
    }
    .ignoresSafeArea(edges: .bottom)
    .overlay {
      if viewModel.isErrorPopupVisible {
        ConfirmationPopupView(viewModel: viewModel.errorPopupViewModel)
      }
    }
    .cancelConfirmationDialog(isPresented: $isCancelDialogPresented) {
      viewModel.abandonIssuance()
      viewModel.closeButtonTapped()
    }

    .background(EnableSwipeBackGesture())
  }

  private var scanningHintBanner: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Theme.shared.image.infoCircleImage
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(
          width: Constants.inlineIconSize,
          height: Constants.inlineIconSize
        )
        .foregroundColor(DSColor.onSurfaceVariant)
        .centeredOnFirstLine(of: DSTypography.Body.large)
        .accessibilityHidden(true)

      Text(.scanningBannerIOS)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM_SMALL)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DSColor.surfaceContainer)
    .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.mediumLarge))
  }
}

struct CardScanningTipsPopupView: View {
  let contactCustomerCareAction: () -> Void
  let onClose: () -> Void

  init(
    contactCustomerCareAction: @escaping () -> Void,
    onClose: @escaping () -> Void
  ) {
    self.contactCustomerCareAction = contactCustomerCareAction
    self.onClose = onClose
  }

  var body: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        Theme.shared.image.help
          .resizable()
          .scaledToFit()
          .frame(
            width: DSStyle.Sizes.Icons.large,
            height: DSStyle.Sizes.Icons.large
          )
          .foregroundColor(DSColor.onSurface)
          .accessibilityHidden(true)

        DSTitleLabel(.scanningHelpPopupTitle, alignment: .center)
      }
      .frame(maxWidth: .infinity)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
          BulletPointText(text: LocalizableStringKey.scanningHelpPopupDetailPara1.toString)
          BulletPointText(text: LocalizableStringKey.scanningHelpPopupDetailPara2.toString)
          BulletPointText(text: LocalizableStringKey.scanningHelpPopupDetailPara3.toString)
        }
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .frame(maxWidth: .infinity, alignment: .leading)
      }

      VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        DSPrimaryButton(
          title: LocalizableStringKey.scanningHelpCustomerServiceCalling.toString,
          leadingIcon: Theme.shared.image.phone,
          action: contactCustomerCareAction
        )

        DSSecondaryButton(
          title: LocalizableStringKey.globalCloseHintButton.toString,
          action: onClose
        )
      }
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
    .padding(.top, DSStyle.Spacers.SPACING_LARGE)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
    .background(DSColor.background)
  }
}

private enum Constants {
  static let scanAnimationSize: CGFloat = 300
  static let scanAnimationPlayCount = 2
  static let inlineIconSize: CGFloat = 18
}
