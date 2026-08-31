//
//  SwiftUIView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common
import AVKit

struct IssuanceCardView<Router: RouterHost>: View {
  @ObservedObject var viewModel: IssuanceCardViewModel<Router>

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
      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
        HeaderContentView(
          onBack: viewModel.backButtonTapped,
          onClose: viewModel.closeButtonTapped,
          onHelp: viewModel.viewHelpAndTips,
          progress: progressSteps
        )

        DSTitleLabel(viewModel.viewState.navigationTitle)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)

        LoopingVideoView()

        Spacer()

        scanningHintBanner

        DSPrimaryButton(title: LocalizableStringKey.restartScanning.toString, action: viewModel.startAusweisReadFlow)
          .shimmer(isLoading: viewModel.viewState.isLoading)
          .accessibilityIdentifier("issuanceCardStartScanningButton")

        DSSecondaryButton(title: LocalizableStringKey.scanningTips.toString, action: viewModel.viewHelpAndTips)
          .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
      }
      .padding()
      .shimmer(isLoading: viewModel.viewState.isLoading)
      .sheet(isPresented: $viewModel.showHelpAndTipsActionSheet, content: {
        CardScanningTipsPopupView(contactCustomerCareAction: viewModel.contactCustomerCareTapped)
          .presentationDetents([.medium])
      })
    }
    .ignoresSafeArea(edges: .bottom)
    .overlay {
      if viewModel.isErrorPopupVisible {
        ConfirmationPopupView(viewModel: viewModel.errorPopupViewModel)
      }
    }
  }

  private var scanningHintBanner: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Theme.shared.image.infoCircle
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(
          width: DSStyle.Sizes.Icons.medium,
          height: DSStyle.Sizes.Icons.medium
        )
        .foregroundColor(DSColor.onSurface)
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
  
  init(contactCustomerCareAction: @escaping () -> Void) {
    self.contactCustomerCareAction = contactCustomerCareAction
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      HStack {
        Theme.shared.image.infoCircle
          .resizable()
          .frame(width: DSStyle.Sizes.Icons.xLarge, height: DSStyle.Sizes.Icons.xLarge)
          .foregroundColor(DSColor.primary)
        
        Text(LocalizableStringKey.scanningHelpPopupTitle.toString)
          .font(DSTypography.Title.large)
          .foregroundColor(DSColor.primary)
          .padding(DSStyle.Spacers.SPACING_MEDIUM)
      }
      
      BulletPointText(text: LocalizableStringKey.scanningHelpPopupDetailPara1.toString)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .fontWeight(DSStyle.FontWeight.regular_400)
      
      BulletPointText(text: LocalizableStringKey.scanningHelpPopupDetailPara2.toString)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .fontWeight(DSStyle.FontWeight.regular_400)
      
      BulletPointText(text: LocalizableStringKey.scanningHelpPopupDetailPara3.toString)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .fontWeight(DSStyle.FontWeight.regular_400)
        .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
      
      Button(
        action: contactCustomerCareAction
      ) {
        HStack {
          ThemeManager.shared.image.phoneIPhone
          
          Text(.scanningHelpCustomerServiceCalling)
            .font(DSTypography.Label.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundColor(DSColor.primary)
        }
      }
      .buttonStyle(DSButton.OutlinePressedButtonStyle())
      .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
      
      Spacer()
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM_LARGE)
    .background(DSColor.background)
  }
}

struct LoopingVideoView: View {
    @State private var player: AVPlayer = {
        let url = Bundle.main.url(forResource: "NFC_Scan_iOS", withExtension: "mp4")!
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        player.play()
        return player
    }()

    var body: some View {
        VideoPlayer(player: player)
            .frame(width: 300, height: 300)
            .cornerRadius(12)
            .background(Color.white)
    }
}
