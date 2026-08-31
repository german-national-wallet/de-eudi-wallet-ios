//
//  IssuanceConsentViewModel.swift
//  feature-issuance
//

import Foundation
import logic_ui
import logic_core
import feature_common
import logic_resources

struct IssuerDetails {
  let name: String
  let address: String
  let logo: Image
  let email: String
  let dataProtectionURL: String
  let certificateExpirationDate: String
  let logoURL: String?
}

@Copyable
public struct IssuerDetailsViewState: ViewState {
  let config: UIConfig.IssuerDetailsViewConfig
}

public extension UIConfig {
  struct IssuerDetailsViewConfig: UIConfigType {
    let issuerDetails: IssuerDetails
    
    public var log: String {
      return "IssuerDetailsView"
    }
    
    init (
      issuerDetails: IssuerDetails
    ) {
      self.issuerDetails = issuerDetails
    }
  }
}

final class IssuerDetailsViewModel<Router: RouterHost>: ViewModel<Router, IssuerDetailsViewState> {
  
  public init(
    router: Router,
    config: any UIConfigType
  ) {
    guard let config = config as? UIConfig.IssuerDetailsViewConfig else {
      fatalError("Config error :: config must be of type UIConfig.IssuerDetailsViewState")
    }
    super.init(
      router: router,
      initialState: .init(
        config: config
      )
    )
  }

  func doWork() {
  }
  
  func reportProblem() {
   // TODO: - Provide action here
  }
  
}
