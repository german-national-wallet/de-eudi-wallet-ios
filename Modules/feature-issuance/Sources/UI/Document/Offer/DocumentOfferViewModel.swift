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
import logic_resources
import logic_business
import feature_common
import logic_core

@Copyable
struct DocumentOfferViewState: ViewState {
  let isLoading: Bool
  let documentOfferUiModel: DocumentOfferUIModel
  let error: ContentErrorView.Config?
  let config: UIConfig.Generic
  let offerUri: String
  let allowIssue: Bool
  let initialized: Bool
  let contentHeaderConfig: ContentHeaderConfig

  var title: LocalizableStringKey {
    return .requestCredentialOfferTitle([documentOfferUiModel.issuerName])
  }

  var successNavigation: UIConfig.TwoWayNavigationType {
    return config.navigationSuccessType
  }

  var cancelNavigation: UIConfig.ThreeWayNavigationType {
    return config.navigationCancelType
  }
}

final class DocumentOfferViewModel<Router: RouterHost>: ViewModel<Router, DocumentOfferViewState> {

  private let interactor: DocumentOfferInteractor
  private let secureEnclaveController: SecureEnclaveController
  private let credentialsInteractor: CredentialsInteractor
    
  @Published var shouldFetchCredentials: Bool = false
  @Published var apiResult: String?
  @Published var showCloseConfirmationPopup: Bool = false

  init(
    router: Router,
    interactor: DocumentOfferInteractor,
    secureEnclaveController: SecureEnclaveController,
    credentialsInteractor: CredentialsInteractor,
    config: any UIConfigType
  ) {
    guard
      let config = config as? UIConfig.Generic,
      let offerUri = config.arguments["uri"]
    else {
      fatalError("DocumentOfferViewModel:: Invalid configuraton")
    }
    self.interactor = interactor
    self.secureEnclaveController = secureEnclaveController
    self.credentialsInteractor = credentialsInteractor
      
      super.init(
      router: router,
      initialState: .init(
        isLoading: true,
        documentOfferUiModel: DocumentOfferUIModel.mock(),
        error: nil,
        config: config,
        offerUri: offerUri,
        allowIssue: false,
        initialized: false,
        contentHeaderConfig: .init(
          appIconAndTextData: AppIconAndTextData(
            appIcon: ThemeManager.shared.image.logoEuDigitalIndentityWallet,
            appText: ThemeManager.shared.image.euditext
          )
        )
      )
    )
  }

  func initialize() async {
    if viewState.initialized {
      await handleResumeIssuance()
      return
    }

    switch await self.interactor.processOfferRequest(with: viewState.offerUri) {
    case .success(let uiModel):
      setState {
        $0
          .copy(
            isLoading: false,
            documentOfferUiModel: uiModel,
            allowIssue: !uiModel.uiOffers.isEmpty,
            initialized: true
          )
          .copy(error: nil)
      }
    case .failure(let error):
      setState {
        $0
          .copy(
            isLoading: false,
            error: ContentErrorView.Config(
              description: .custom(error.localizedDescription),
              cancelAction: self.onPop()
            ),
            allowIssue: false,
            initialized: true
          )
      }
    }
  }

  var introConfig: IntroConfig {
    IntroConfig(
      style: .illustrated,
      title: LocalizableStringKey.eaaOfferViewTitle.toString,
      bannerText: LocalizableStringKey.eaaOfferViewTxCodeFlowInstruction.toString,
      primaryAction: IntroConfig.Action(
        title: LocalizableStringKey.eaaOfferViewPrimaryButtonTitle.toString,
        accessibilityId: "offerIntroPrimaryButton",
        handler: onIssueDocuments
      ),
      onBack: onPop,
      onHelp: onHelp,
      onClose: closeButtonAction
    )
  }

  func closeButtonAction() {
    showCloseConfirmationPopup = true
  }

  func onIssueDocuments() {
    guard !viewState.isLoading else { return }

    if let code = viewState.documentOfferUiModel.txCode {
      router.push(
        with: .featureIssuanceModule(
          .issuanceCode(
            config: IssuanceCodeUiConfig(
              offerUri: viewState.offerUri,
              issuerName: viewState.documentOfferUiModel.issuerName,
              txCodeLength: code.codeLength,
              docOffers: viewState.documentOfferUiModel.docOffers,
              successNavigation: viewState.successNavigation,
              navigationCancelType: .pop
            )
          )
        )
      )
      return
    }
    setState { $0.copy(isLoading: true).copy(error: nil) }
    Task {
      switch await self.interactor.issueDocuments(
        with: viewState.offerUri,
        issuerName: viewState.documentOfferUiModel.issuerName,
        docOffers: viewState.documentOfferUiModel.docOffers,
        successNavigation: viewState.successNavigation,
        txCodeValue: nil
      ) {
      case .success(let route):
        router.push(with: route)
      case .dynamicIssuance(let session):
        router.push(
          with: .featurePresentationModule(
            .presentationRPInfo(
              presentationCoordinator: session,
              originator: .featureIssuanceModule(.credentialOfferRequest(config: viewState.config))
            )
          )
        )
      case .failure(let error):
        setState {
          $0.copy(
            isLoading: false,
            error: .init(
              description: .custom(error.localizedDescription),
              cancelAction: self.setState { $0.copy(error: nil) }
            )
          )
        }
      case .partialSuccess(let route):
        router.push(with: route)
      case .deferredSuccess(let route):
        router.push(with: route)
      }
    }
  }

  func onPop() {
    switch viewState.cancelNavigation {
    case .popTo(let route):
      router.popTo(with: route)
    case .push(let route):
      router.push(with: route)
    case .pop:
      router.pop()
    }
  }

  func onHelp() {
    // TODO: Implement help action
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
          config: .init(
            arguments: ["uri": uri],
            navigationSuccessType: viewState.config.navigationSuccessType,
            navigationCancelType: viewState.config.navigationCancelType
          ),
          offerUri: uri,
          allowIssue: false,
          initialized: false
        )
        .copy(error: nil)
    }
    Task {
      await self.initialize()
    }
  }

  private func handleResumeIssuance() async {
    setState { $0.copy(isLoading: true) }
    switch await interactor.resumeDynamicIssuance(
      issuerName: viewState.documentOfferUiModel.issuerName,
      successNavigation: viewState.successNavigation
    ) {
    case .success(let route):
      router.push(with: route)
    case .noPending:
      setState { $0.copy(isLoading: false) }
    case .failure(let error):
      setState {
        $0.copy(
          isLoading: false,
          error: .init(
            description: .custom(error.localizedDescription),
            cancelAction: self.setState { $0.copy(error: nil) }
          )
        )
      }
    }
  }
}
