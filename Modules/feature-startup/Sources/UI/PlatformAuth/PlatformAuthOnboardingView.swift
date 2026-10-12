//
//  PlatformAuthOnboardingView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct PlatformAuthOnboardingView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: PlatformAuthOnboardingViewModel<Router>

  @Environment(\.scenePhase) private var scenePhase

  init(with viewModel: PlatformAuthOnboardingViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    Group {
      if viewModel.viewState.isChecking || viewModel.viewState.isPlatformAuthEnabled {
        successContent
      } else {
        PlatformAuthenticationBlockingView(action: openSettings)
      }
    }
    .background(DSColor.background)
    .task {
      await viewModel.checkPlatformAuthentication()
    }
    .onChange(of: scenePhase) { phase in
      guard phase == .active else { return }
      Task { await viewModel.checkPlatformAuthentication() }
    }
    .sheet(
      isPresented: Binding(
        get: { viewModel.viewState.isImportantSheetPresented },
        set: { viewModel.setImportantSheetPresented($0) }
      )
    ) {
      OnboardingInfoSheet(
        title: .appOnboardingPaSetSuccessSheetTitle,
        message: .appOnboardingPaSetSuccessSheetParagraph,
        buttonTitle: .appOnboardingPaSetSuccessSheetPrimButton,
        buttonAccessibilityIdentifier: "paImportantSheetButton",
        action: viewModel.onImportantSheetConfirmed
      )
    }
  }

  private var successContent: some View {
    VStack(spacing: 0) {
      HeaderContentView(onBack: viewModel.onBackTapped)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          OnboardingIllustrationView(asset: .displayLockedSuccess, stretchesBackground: true)

          Text(
            viewModel.viewState.isChecking
            ? LocalizableStringKey.appOnboardingPaSetIntroTitleLoading.toLocalizedStringKey
            : LocalizableStringKey.appOnboardingPaSetSuccessTitle.toLocalizedStringKey
          )
          .font(DSTypography.Title.large)
          .foregroundStyle(DSColor.onBackground)
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("paTitle")

          if !viewModel.viewState.isChecking {
            OnboardingInfoBanner(text: .appOnboardingPaSetSuccessParagraph)
          }
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
      }

      bottomBar
    }
  }

  private var bottomBar: some View {
    DSPrimaryButton(
      title: LocalizableStringKey.appOnboardingPaSetSuccessPrimButton.toString,
      trailingIcon: Theme.shared.image.arrowForward
    ) {
      viewModel.onPrimaryButtonTapped()
    }
    .disabled(viewModel.viewState.isChecking)
    .keyboardShortcut(.defaultAction)
    .accessibilityIdentifier("paSuccessPrimaryButton")
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_SMALL)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .background(DSColor.background.ignoresSafeArea(edges: .bottom))
  }

  private func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
  }
}
