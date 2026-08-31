//
//  GenericInstructionViewModel.swift
//  feature-common
//

@_exported import logic_ui
@_exported import logic_resources
import logic_core

public enum IntstructionViewType: Sendable {
  case defaultType
  case issuanceOnboarding
}

public extension UIConfig {
  struct InstructionsViewConfig: UIConfigType {
    let mainTitle: LocalizableStringKey
    let message: LocalizableStringKey?
    let banner: LocalizableStringKey?
    let image: Image?
    let illustrationWidthFactor: CGFloat
    let primaryButtonTitle: LocalizableStringKey
    let secondaryButtonTitle: LocalizableStringKey?
    let viewType: IntstructionViewType
    let introStyle: IntroConfig.Style
    let issuanceInteractor: IssuanceVerificationInteractor?
    public let onBack: (() -> Void)?
    public let onClose: (() -> Void)?
    public let onHelp: (() -> Void)?
    public let finishAuthorizationResponse: FinishAuthorizationResponse?
    
    public let primaryRoute: AppRoute
    public var log: String {
      return "mainTitle: \(mainTitle.toString)"
    }
    
    public init(
      mainTitle: LocalizableStringKey,
      message: LocalizableStringKey?,
      banner: LocalizableStringKey? = nil,
      image: Image? = nil,
      illustrationWidthFactor: CGFloat,
      primaryButtonTitle: LocalizableStringKey,
      secondaryButtonTitle: LocalizableStringKey? = nil,
      viewType: IntstructionViewType = .defaultType,
      introStyle: IntroConfig.Style = .plain,
      primaryRoute: AppRoute,
      issuanceInteractor: IssuanceVerificationInteractor? = nil,
      onBack: (() -> Void)? = nil,
      onClose: (() -> Void)? = nil,
      onHelp: (() -> Void)? = nil,
      finishAuthorizationResponse: FinishAuthorizationResponse? = nil
    ) {
      self.mainTitle = mainTitle
      self.message = message
      self.banner = banner
      self.image = image
      self.illustrationWidthFactor = illustrationWidthFactor
      self.primaryButtonTitle = primaryButtonTitle
      self.secondaryButtonTitle = secondaryButtonTitle
      self.primaryRoute = primaryRoute
      self.viewType = viewType
      self.introStyle = introStyle
      self.issuanceInteractor = issuanceInteractor
      self.onBack = onBack
      self.onClose = onClose
      self.onHelp = onHelp
      self.finishAuthorizationResponse = finishAuthorizationResponse
    }
  }
}

@Copyable
public struct InstructionsViewState: ViewState {
  let config: UIConfig.InstructionsViewConfig
}

public final class InstructionsViewModel<Router: RouterHost>: ViewModel<Router, InstructionsViewState> {
  @Published var isSecondaryButtonSheetOpen = false
  
  public init(
    router: Router,
    config: any UIConfigType
  ) {
    guard let config = config as? UIConfig.InstructionsViewConfig else {
      fatalError("Config error :: config must be of type UIConfig.InstructionsViewConfig")
    }
    super.init(
      router: router,
      initialState: .init(
        config: config
      )
    )
  }
  
  func openBurgeramtWebpage() {
    if let url = AppEnvironment.burgeramtServiceLink {
      UIApplication.shared.open(url)
    }
  }
  
  func primaryButtonTapped() {
    router.push(with: viewState.config.primaryRoute)
  }
  
  func secondaryButtonTapped() {
    isSecondaryButtonSheetOpen.toggle()
  }
}
