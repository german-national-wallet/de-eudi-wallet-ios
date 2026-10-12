/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import logic_ui
import logic_business
import logic_core
import logic_analytics
import feature_common
import feature_issuance

@Copyable
struct DashboardState<Router: RouterHost>: ViewState {
  let credentialsTab: DashboardCredentialView<Router>?
  let addDocumentTab: AddDocumentView<Router>?
  let activitiesTab: ActivitiesTabView<Router>?
  let settingsTab: SettingsTabView<Router>?
  
  let hasIssuedDocuments: Bool
  let toolBarContent: ToolBarContent
  let navigationTitle: LocalizableStringKey
}

enum DashboardTab: String {
  case overview
  case activity
  case settings
  case qrReader
  
  var tabTitle: String {
    return switch self {
    case .overview: LocalizableStringKey.dashboardTabBarTitleLabelOverview.toString
    case .activity: LocalizableStringKey.dashboardTabBarTitleLabelActivity.toString
    case .settings: LocalizableStringKey.dashboardTabBarTitleLabelSettings.toString
    case .qrReader: ""
    }
  }
  
  var tabIcon: Image {
    return switch self {
    case .overview: Theme.shared.image.tabbarOverview
    case .activity: Theme.shared.image.tabbarActivity
    case .settings: Theme.shared.image.tabbarSettings
    case .qrReader: Theme.shared.image.tabbarQRReader
    }
  }
  
  var a11Text: String {
    return switch self {
    case .overview: LocalizableStringKey.dashboardTabBarTitleLabelOverview.toString
    case .activity: LocalizableStringKey.dashboardTabBarTitleLabelActivity.toString
    case .settings: LocalizableStringKey.dashboardTabBarTitleLabelSettings.toString
    case .qrReader: LocalizableStringKey.scanQrCode.toString
    }
  }
}

final class DashboardViewModel<Router: RouterHost>: ViewModel<Router, DashboardState<Router>> {

  private let dashboardInteractor: DashboardInteractor
  private let deepLinkController: DeepLinkController
  private let secureEnclaveController: SecureEnclaveController
  private let configLogic: ConfigLogic

  @Published var selectedTab: DashboardTab = .overview
  @Published var shouldPresentQRReader: Bool = false
  
  init(
    router: Router,
    dashboardInteractor: DashboardInteractor,
    settingsTabInteractor: SettingsTabInteractor,
    secureEnclaveController: SecureEnclaveController,
    configLogic: ConfigLogic,
    deepLinkController: DeepLinkController
  ) {
    self.dashboardInteractor = dashboardInteractor
    self.deepLinkController = deepLinkController
    self.secureEnclaveController = secureEnclaveController
    self.configLogic = configLogic
    
      super.init(
        router: router,
        initialState: .init(
          credentialsTab: nil,
          addDocumentTab: nil,
          activitiesTab: nil,
          settingsTab: nil,
          hasIssuedDocuments: dashboardInteractor.hasDocuments,
          toolBarContent: .init(
            trailingActions: nil,
            leadingActions: nil
          ),
          navigationTitle: .custom("")
        )
      )
      createTabs(
        settingsTabInteractor: settingsTabInteractor,
        secureEnclaveController: secureEnclaveController,
        configLogic: configLogic
      )

  }

    private func createTabs(
      settingsTabInteractor: SettingsTabInteractor,
      secureEnclaveController: SecureEnclaveController,
      configLogic: ConfigLogic
    ) {

      func updateState(toolbar: ToolBarContent, title: LocalizableStringKey) {
        self.setState {
          $0.copy(
            hasIssuedDocuments: dashboardInteractor.hasDocuments,
            toolBarContent: toolbar,
            navigationTitle: title
          )
        }
      }

      setState {
        $0.copy(
          credentialsTab: DashboardCredentialView(
            with: .init(
              router: router,
              interactor: dashboardInteractor,
              logger: DIGraph.resolver.force(Logging.self),
              deepLinkController: deepLinkController,
              analyticsController: DIGraph.resolver.force(AnalyticsController.self)
            )
          ),
          addDocumentTab: AddDocumentView(
            with: .init(
              router: router,
              interactor: DIGraph.resolver.force(AddDocumentInteractor.self),
              deepLinkController: deepLinkController,
              secureEnclaveController: secureEnclaveController,
              analyticsController: DIGraph.resolver.force(AnalyticsController.self),
              config: IssuanceFlowUiConfig(flow: .noDocument)
            )
          ),
          activitiesTab: ActivitiesTabView(),
          settingsTab: SettingsTabView(
            with: .init(
              router: router,
              interactor: settingsTabInteractor,
              configLogic: configLogic
            )
          )
        )
      }
    }
    
    func onAppear() {
        self.setState {
          $0.copy(
            hasIssuedDocuments: dashboardInteractor.hasDocuments
          )
        }
    }
}
