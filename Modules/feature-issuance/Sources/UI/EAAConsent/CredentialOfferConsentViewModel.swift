//
//  CredentialOfferConsentViewModel.swift
//  feature-issuance
//

import logic_ui
import logic_resources
import feature_common

@Copyable
struct CredentialOfferConsentViewState: ViewState {
  let isLoading: Bool
  let documentOfferUiModel: DocumentOfferUIModel
  let offerUri: String
  let claimNames: [String]
  let config: UIConfig.Generic
  let initialized: Bool
}

final class CredentialOfferConsentViewModel<Router: RouterHost>: ViewModel<Router, CredentialOfferConsentViewState> {
  private let interactor: DocumentOfferInteractor

  @Published var documentName: String = ""
  @Published var issuerImageUrl: URL?
  @Published var showCredentialDetails: Bool = false
  @Published var showCancelConfirmationPopup: Bool = false
  @Published var showCloseConfirmationPopup: Bool = false
  @Published var showIssuanceFailurePopup: Bool = false
  var txCode: DocumentOfferUIModel.TxCode?

  init(
    router: Router,
    config: any UIConfigType,
    interactor: DocumentOfferInteractor
  ) {
    guard
      let config = config as? UIConfig.Generic,
      let offerUri = config.arguments["uri"]
    else {
      fatalError("DocumentOfferViewModel:: Invalid configuraton")
    }
    self.interactor = interactor
    super.init(
      router: router,
      initialState: .init(
        isLoading: true,
        documentOfferUiModel: DocumentOfferUIModel.mock(),
        offerUri: offerUri,
        claimNames: [],
        config: config,
        initialized: false
      )
    )
  }

  var primaryButtonTitle: String {
    if txCode?.isRequired == true {
      return LocalizableStringKey.next.toString
    }
    return LocalizableStringKey.eaaConsentPrimaryButtonTitle.toString
  }

  func initialize() async {
    guard !viewState.initialized else { return }

    switch await self.interactor.processOfferRequest(with: viewState.offerUri) {
    case .success(let uiModel):
      documentName = uiModel.uiOffers.first?.documentName ?? ""
      issuerImageUrl = uiModel.issuerLogo
      txCode = uiModel.txCode
      let claims = uiModel.docOffers.first?.claims.compactMap { $0.display?.first?.name } as? [String]
      setState {
        $0
          .copy(
            isLoading: false,
            documentOfferUiModel: uiModel,
            claimNames: claims,
            initialized: true
          )
      }
    case .failure(let error):
      setState {
        $0
          .copy(
            isLoading: false,
            initialized: true
          )
      }
    }
  }

  func handleNotification(with info: [AnyHashable: Any]) {
    guard let uri = info["uri"] as? String else {
      return
    }
    setState {
      $0
        .copy(
          isLoading: true,
          documentOfferUiModel: DocumentOfferUIModel.mock(),
          offerUri: uri,
          config: .init(
            arguments: ["uri": uri],
            navigationSuccessType: viewState.config.navigationSuccessType,
            navigationCancelType: viewState.config.navigationCancelType
          ),
          initialized: false
        )
    }
    Task {
      await self.initialize()
    }
  }

  func primaryButtonAction() {
    if txCode != nil {
      router.push(with: .featureIssuanceModule(.credentialOfferRequest(config: viewState.config)))
    } else {
      Task {
        await issueDocuments()
      }
    }
  }

  private func issueDocuments() async {
    router.push(
      with: .featureIssuanceModule(
        .documentLoaderView(
          config: DocumentLoaderUiConfig(
            offerUri: viewState.offerUri,
            issuerName: viewState.documentOfferUiModel.issuerName,
            docOffers: viewState.documentOfferUiModel.docOffers,
            successNavigation: viewState.config.navigationSuccessType,
            navigationCancelType: viewState.config.navigationCancelType
          ),
          onFailure: { [weak self] in
            Task { @MainActor in
              self?.showIssuanceFailurePopup = true
            }
          }
        )
      )
    )
  }

  func secondaryButtonAction() {
    showCancelConfirmationPopup = true
  }

  func closeButtonAction() {
    showCloseConfirmationPopup = true
  }

  func showIssuerDetails() {
    router.push(with: .featureIssuanceModule(.issuerDetailsView(config: UIConfig.IssuerDetailsViewConfig(issuerDetails: .init(
      name: viewState.documentOfferUiModel.issuerName,
      address: "",
      logo: Theme.shared.image.bdrLogo,
      email: "",
      dataProtectionURL: "",
      certificateExpirationDate: "",
      logoURL: viewState.documentOfferUiModel.issuerLogo?.absoluteString
    )))))
  }

  func cancelIssuance() {
    router.pop()
  }

  func onHelp() {
    // will be added later when the functionality is finalized
  }
}
