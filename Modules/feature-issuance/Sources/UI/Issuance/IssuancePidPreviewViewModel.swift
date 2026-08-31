//
//  IssuancePidPreviewViewModel.swift
//  feature-issuance
//

import Foundation
import logic_ui
import logic_core
import feature_common
import logic_resources

@Copyable
public struct IssuancePidPreviewViewState: ViewState {
  let config: UIConfig.IssuancePidPreviewViewConfig
}

public extension UIConfig {
  struct IssuancePidPreviewViewConfig: UIConfigType {

    let primaryRoute: AppRoute

    public var log: String {
      return "IssuancePidPreviewViewConfig"
    }

    public init(primaryRoute: AppRoute) {
      self.primaryRoute = primaryRoute
    }
  }
}

final class IssuancePidPreviewViewModel<Router: RouterHost>: ViewModel<Router, IssuancePidPreviewViewState> {
  @Published var isRejectDialogOpen = false

  public init(
    router: Router,
    config: any UIConfigType
  ) {
    guard let config = config as? UIConfig.IssuancePidPreviewViewConfig else {
      fatalError("Config error :: config must be of type UIConfig.IssuancePidPreviewViewConfig")
    }
    super.init(
      router: router,
      initialState: .init(config: config)
    )
  }

  func continueTapped() {
    router.push(with: viewState.config.primaryRoute)
  }

  func rejectButtonTapped() {
    isRejectDialogOpen = true
  }

  func rejectConfirmed() {
    isRejectDialogOpen = false
    closeButtonTapped()
  }

  func reportProblem() {
    // TODO: - Provide action here
  }

  func helpTapped() {
    // TODO: - Provide action here
  }

  func showIssuerDetails() {
    router.push(
      with: .featureIssuanceModule(
        .issuerDetailsView(
          config: UIConfig.IssuerDetailsViewConfig(
            issuerDetails: .init(
              name: LocalizableStringKey.pidIDPreviewIssuerName.toString,
              address: "Alt-Moabit 140, 10557 Berlin",
              logo: Theme.shared.image.buildingBlocks,
              email: "info@bdr.de",
              dataProtectionURL: "www.bmi.bund.de/DE/service/datenschutz/datenschutz_node.html",
              certificateExpirationDate: "23.05.2030",
              logoURL: nil
            )
          )
        )
      )
    )
  }
}
