//
//  AppIntroView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources

struct AppIntroView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: AppIntroViewModel<Router>
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let videoAspectRatio: CGFloat = 902 / 1920
  private let sheetMinHeight: CGFloat = 384
  private let overlayInset: CGFloat = 10
  private let iconButtonDiameter: CGFloat = 40
  private let buttonHeight: CGFloat = 48

  init(with viewModel: AppIntroViewModel<Router>) {
    self.viewModel = viewModel
  }

  private var page: AppIntroPage { viewModel.viewState.page }

  var body: some View {
    ContentScreenView(
      padding: 0,
      allowBackGesture: page.showsBackButton,
      backgroundIgnoresSafeArea: true
    ) {
      ZStack(alignment: .top) {
        illustration

        VStack(spacing: 0) {
          Spacer(minLength: 0)

          if viewModel.viewState.isAnimationToggleVisible {
            HStack {
              Spacer()
              animationToggle
            }
            .padding(.trailing, overlayInset)
            .padding(.bottom, DSStyle.Spacers.SPACING_SMALL)
          }

          sheet
        }

        if page.showsBackButton {
          backButton
            .padding(.leading, overlayInset)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      if reduceMotion {
        viewModel.pauseAnimation()
      }
    }
    .task {
      await viewModel.loadAnimationDuration()
    }
  }

  private var illustration: some View {
    GeometryReader { proxy in
      VideoAnimationView(
        asset: page.videoAsset,
        contentMode: .fill,
        playCount: nil,
        isPaused: viewModel.viewState.isAnimationPaused
      )
      .frame(width: proxy.size.width, height: proxy.size.width / videoAspectRatio)
    }
    .clipped()
    .ignoresSafeArea(edges: .top)
    .accessibilityHidden(true)
  }

  private var backButton: some View {
    Button(action: viewModel.onBackTapped) {
      Theme.shared.image.arrowBackIcon
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: DSIconSize.large, height: DSIconSize.large)
        .foregroundColor(DSColor.onSurface)
        .frame(width: iconButtonDiameter, height: iconButtonDiameter)
        .background(Circle().fill(DSColor.background))
        .overlay(Circle().stroke(DSColor.outline, lineWidth: 1))
        .iconButtonSlot()
    }
    .accessibilityLabel(Text(LocalizableStringKey.globalBackButtonA11y.toLocalizedStringKey))
    .accessibilityIdentifier("appIntroBackButton")
  }

  private var animationToggle: some View {
    let isPaused = viewModel.viewState.isAnimationPaused
    return Button(action: viewModel.toggleAnimation) {
      Image(systemName: isPaused ? "play.fill" : "pause.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(DSColor.onSurface)
        .frame(width: iconButtonDiameter, height: iconButtonDiameter)
        .background(Circle().fill(DSColor.surfaceContainer.opacity(0.7)))
        .overlay(Circle().stroke(DSColor.tertiaryOutline, lineWidth: 1))
        .iconButtonSlot()
    }
    .accessibilityLabel(
      Text(
        (isPaused
         ? LocalizableStringKey.appOnboardingAnimationPlayA11y
         : LocalizableStringKey.appOnboardingAnimationPauseA11y).toLocalizedStringKey
      )
    )
    .accessibilityIdentifier("appIntroAnimationToggle")
  }

  private var sheet: some View {
    VStack(spacing: 0) {
      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        Text(page.title)
          .font(DSTypography.Title.large)
          .fontWeight(DSStyle.FontWeight.medium_500)
          .foregroundColor(DSColor.onSurface)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("appIntroTitle")

        Text(page.body)
          .font(DSTypography.Body.large)
          .foregroundColor(DSColor.onSurfaceVariant)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
      .padding(.top, DSStyle.Spacers.SPACING_LARGE)

      Spacer(minLength: DSStyle.Spacers.SPACING_MEDIUM)

      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        DSPageIndicator(current: page.number, total: AppIntroPage.count)

        VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          DSPrimaryButton(
            title: page.primaryButtonTitle.toString,
            trailingIcon: page.primaryButtonHasArrow ? Theme.shared.image.arrowForward : nil
          ) {
            viewModel.onPrimaryTapped()
          }
          .accessibilityIdentifier("appIntroPrimaryButton")

          if let tertiaryTitle = page.tertiaryButtonTitle {
            Button(action: viewModel.onSkipTapped) {
              Text(tertiaryTitle)
                .font(DSTypography.Label.large)
                .fontWeight(DSStyle.FontWeight.medium_500)
                .foregroundColor(DSColor.onSecondaryContainer)
                .lineLimit(DSStyle.LineLimits.two)
                .minimumScaleFactor(0.8)
            }
            .buttonStyle(DSButton.TextButtonStyle(height: buttonHeight))
            .accessibilityIdentifier("appIntroSkipButton")
          } else {
            Color.clear
              .frame(height: buttonHeight)
              .accessibilityHidden(true)
          }
        }
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .frame(maxWidth: .infinity)
    .frame(minHeight: sheetMinHeight, alignment: .top)
    .fixedSize(horizontal: false, vertical: true)
    .background(
      RoundedCorner(
        radius: DSStyle.Sizes.CornerRadius.xxLarge,
        corners: [.topLeft, .topRight]
      )
      .fill(DSColor.background)
      .dsShadow(DSShadow.high)
      .ignoresSafeArea(edges: .bottom)
    )
  }
}
