//
//  IssuanceConsentViewModel.swift
//  feature-issuance
//

import Foundation
import logic_ui
import logic_core
import feature_common
import logic_resources

struct ConsentItem {
  let title: String
}

@Copyable
public struct IssuanceConsentViewState: ViewState {
  let config: UIConfig.IssuanceConsentViewConfig
}

public extension UIConfig {
   struct IssuanceConsentViewConfig: UIConfigType {
    let consentItems: [ConsentItem] = [
      ConsentItem(title: LocalizableStringKey.eIDAttributeName.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeFirstNames.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeBirthDate.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeAgeInYears.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeIssuingAuthority.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeCreatedAt.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeBirthName.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeNationality.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributePlaceOfBirth.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeAgeBirthYear.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeAgeEqualOrOver.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeIssuingCountry.toString),
      ConsentItem(title: LocalizableStringKey.eIDAttributeExpireDate.toString)
    ]
    let issuanceInteractor: IssuanceVerificationInteractor?
    let primaryRoute: AppRoute
    
    public var log: String {
      return "IssuanceConsentViewConfig"
    }
    
    init (
      primaryRoute: AppRoute,
      issuanceInteractor: IssuanceVerificationInteractor?
    ) {
      self.primaryRoute = primaryRoute
      self.issuanceInteractor = issuanceInteractor
    }
  }
}

final class IssuanceConsentViewModel<Router: RouterHost>: ViewModel<Router, IssuanceConsentViewState> {
  @Published var isRejectSheetOpen = false
  
  public init(
    router: Router,
    config: any UIConfigType
  ) {
    guard let config = config as? UIConfig.IssuanceConsentViewConfig else {
      fatalError("Config error :: config must be of type UIConfig.InstructionsViewConfig")
    }
    super.init(
      router: router,
      initialState: .init(
        config: config
      )
    )
  }

  func doWork() {
    router.push(with: viewState.config.primaryRoute)
  }
  
  func goToPidIssuer() {
    router.push(with: .featureIssuanceModule(.issuerDetailsView(config: UIConfig.IssuerDetailsViewConfig(issuerDetails: .init(
      name: "Bundesdruckerei",
      address: "Kommandantenstraß 18, 10969 Berlin",
      logo: Theme.shared.image.bdrLogo,
      email: "info@bdr.de",
      dataProtectionURL: "bundesdruckerei.de/de/datenschutz",
      certificateExpirationDate: "23.05.2030",
      logoURL: nil
    )))))
  }
  
  func openBurgeramtWebpage() {
    if let url = AppEnvironment.burgeramtServiceLink {
      UIApplication.shared.open(url)
    }
  }

  func rejectButtonTapped() {
    isRejectSheetOpen = true
  }

  func reportProblem() {
    // TODO: - Provide action here
  }

  func rejectConfirmed() {
    isRejectSheetOpen = false
    closeButtonTapped()
  }
}
