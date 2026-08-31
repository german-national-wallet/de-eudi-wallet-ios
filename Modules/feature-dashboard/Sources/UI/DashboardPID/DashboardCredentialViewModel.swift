//
//  DashboardPIDViewModel.swift
//  feature-dashboard
//
import Foundation
import logic_ui
import logic_core
import logic_business
import logic_resources
import logic_analytics

@Copyable
struct DashboardPIDState: ViewState {
  let pidTitle: String
}

final class DashboardCredentialViewModel<Router: RouterHost>: ViewModel<Router, DashboardPIDState> {
  private let interactor: DashboardInteractor
  private let deeplinkController: DeepLinkController
  private let logger: Logging?
  private let analyticsController: AnalyticsController

  @Published var fullName: String = ""
  @Published var pidName: String = ""
  @Published var additionalDocuments: [DocClaimsDecodable]?
  var pidDocument: DocClaimsDecodable?

  init(
    router: Router,
    interactor: DashboardInteractor,
    logger: Logging?,
    deepLinkController: DeepLinkController,
    analyticsController: AnalyticsController
  ) {
    self.interactor = interactor
    self.deeplinkController = deepLinkController
    self.logger = logger
    self.analyticsController = analyticsController
    super.init(
      router: router,
      initialState: .init(
        pidTitle: ""
      )
    )
    getMainPIDDocument()
  }

  func getMainPIDDocument() {
    do {
      if let doc = try interactor.getPIDDocument() {
        pidDocument = doc
        let firstName = (doc.docClaims.first(where: {
          $0.name == "given_name"
        })?.dataValue.description ?? "").capitalizedFirst()
        let familyName = (doc.docClaims.first(where: {
          $0.name == "family_name"
        })?.dataValue.description ?? "").capitalizedFirst()

        fullName = "\(firstName) \(familyName)"

        setIssuerName(doc)
      } else {
        resetPIDDetails()
      }
    } catch {
      resetPIDDetails()
      logger?.e("doc not found")
    }
  }

  var isPIDAvailable: Bool {
    pidDocument != nil
  }

  var showAdditionalDocuments: Bool {
    if let additionalDocuments = additionalDocuments, additionalDocuments.count > 0 && !isPIDAvailable {
      return true
    } else if let additionalDocuments = additionalDocuments, !additionalDocuments.isEmpty && isPIDAvailable {
      return true
    }
    return false
  }

  func getAdditionalDocuments() {
    do {
      let docs = try interactor.getAdditionalDocuments()
      additionalDocuments = docs
    } catch {
      logger?.e("additional documents not found")
    }
  }
  
  private func resetPIDDetails() {
    pidDocument = nil
    fullName = ""
    pidName = ""
  }

  func onTap(additionalDocument: DocClaimsDecodable? = nil) {
    if let additionalDocument {
      router.push(with: .featureDashboardModule(.credentialDetail(additionalDocument)))
    } else if let pidDocument {
      router.push(with: .featureDashboardModule(.credentialDetail(pidDocument)))
    }
  }

  private func setIssuerName(_ doc: DocClaimsDecodable) {
    pidName = doc.configurationIdentifier?.contains("pid") ?? false ? LocalizableStringKey.dashboardCardTitle.toString : ""
  }

  func onMenuTap() {
    router.push(
      with: .featureDashboardModule(
        .sideMenu
      )
    )
  }

  func handleDeepLink() async {
    guard let deepLink = deeplinkController.getPendingDeepLinkAction(),
          deepLink.requiresCoordinator else {
      return
    }
    deeplinkController.handleDeepLinkAction(
      routerHost: router,
      deepLinkExecutable: deepLink,
      remoteSessionCoordinator: await interactor.getWalletKitController().startSameDevicePresentation(deepLink: deepLink.link)
    )
  }

  func performIssuance() {
    analyticsController.startTrace(name: AnalyticsConstants.TraceName.issuance, initialAttributes: [:])
    router.push(
      with: .featureIssuanceModule(
        .issuanceOnboardingView
      )
    )
  }

}
