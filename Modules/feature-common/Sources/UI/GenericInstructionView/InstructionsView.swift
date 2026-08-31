//
//  InstructionsView.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct InstructionsView<Router: RouterHost>: View {
  @ObservedObject var viewModel: InstructionsViewModel<Router>

  public init(viewModel: InstructionsViewModel<Router>) {
    self.viewModel = viewModel
  }

  public var body: some View {
    content
      .sheet(isPresented: $viewModel.isSecondaryButtonSheetOpen) {
        sheetContent
      }
  }

  /// Renders the intro layout selected by the config, driven by `introConfig`.
  @ViewBuilder private var content: some View {
    switch viewModel.viewState.config.introStyle {
    case .stepped, .plain:
      SteppedIntroView(config: introConfig)
    case .illustrated:
      IllustratedIntroView(config: introConfig)
    }
  }

  /// Maps the (route-based) `InstructionsViewConfig` onto the closure-based `IntroConfig`.
  private var introConfig: IntroConfig {
    let config = viewModel.viewState.config
    return IntroConfig(
      style: config.introStyle,
      title: config.mainTitle.toString,
      titleAccessibilityId: "instructionsScreen1",
      body: config.banner == nil ? nil : config.message?.toString,
      bannerText: (config.banner ?? config.message)?.toString,
      illustration: config.image,
      illustrationWidthFactor: config.illustrationWidthFactor,
      primaryAction: IntroConfig.Action(
        title: config.primaryButtonTitle.toString,
        accessibilityId: "instructionsScreen1PrimaryButton",
        handler: viewModel.primaryButtonTapped
      ),
      secondaryAction: config.secondaryButtonTitle.map { title in
        IntroConfig.Action(title: title.toString, handler: viewModel.secondaryButtonTapped)
      },
      onBack: viewModel.backButtonTapped,
      onHelp: config.onHelp,
      onClose: viewModel.closeButtonTapped
    )
  }

  @ViewBuilder private var sheetContent: some View {
    switch viewModel.viewState.config.viewType {
    case .issuanceOnboarding:
      PINIssuanceInfoView(
        onFindNearbyBurgerAmt: viewModel.openBurgeramtWebpage,
        router: viewModel.router,
        isSheetPresented: $viewModel.isSecondaryButtonSheetOpen,
        issuanceInteractor: viewModel.viewState.config.issuanceInteractor
      )
      .background(DSColor.background)
      .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
      .ignoresSafeArea()
      .presentationDetents([.fraction(0.7)])
    default:
      BottomSheetViewWithAction(
        title: LocalizableStringKey.setupPinSheetTitle.toString,
        message: LocalizableStringKey.setupPinSheetMessage.toString,
        buttonTitle: LocalizableStringKey.setupPinSheetButtonText.toString,
        action: {}
      )
      .presentationDetents([.medium])
    }
  }
}
