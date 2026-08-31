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
struct OfferCodeViewState: ViewState {
  let isLoading: Bool
  let error: ContentErrorView.Config?
  let config: IssuanceCodeUiConfig
  let title: LocalizableStringKey
  let caption: LocalizableStringKey
  let contentHeaderConfig: ContentHeaderConfig
}

final class OfferCodeViewModel<Router: RouterHost>: ViewModel<Router, OfferCodeViewState> {

  @Published var codeInput: String = ""
  @Published var codeIsFocused: Bool = true
  @Published var errorMessage = String()
  @Published var showCloseConfirmationPopup: Bool = false

  private let interactor: DocumentOfferInteractor

  init(
    router: Router,
    interactor: DocumentOfferInteractor,
    config: any UIConfigType
  ) {
    guard
      let config = config as? IssuanceCodeUiConfig
    else {
      fatalError("OfferCodeViewModel:: Invalid configuraton")
    }
    self.interactor = interactor
    super.init(
      router: router,
      initialState: .init(
        isLoading: false,
        error: nil,
        config: config,
        title: .transactionCodeViewTitle,
        caption: .transactionCodeViewDescription,
        contentHeaderConfig: .init(
          appIconAndTextData: AppIconAndTextData(
            appIcon: ThemeManager.shared.image.logoEuDigitalIndentityWallet,
            appText: ThemeManager.shared.image.euditext
          )
        )
      )
    )
  }

  var isPrimaryButtonEnabled: Bool {
    codeInput.count == viewState.config.txCodeLength
  }

  func checkPendingIssuance() async {
    let config: IssuanceCodeUiConfig = viewState.config

    let state = await Task.detached { () -> OfferDynamicIssuancePartialState in
      return await self.interactor.resumeDynamicIssuance(
        issuerName: config.issuerName,
        successNavigation: config.successNavigation
      )
    }.value

    switch state {
    case .success(let route):
      router.push(with: route)
    case .noPending: break
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

  func onPop() {
    switch viewState.config.navigationCancelType {
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

  func closeButtonAction() {
    codeIsFocused = false
    showCloseConfirmationPopup = true
  }

  func toolbarContent() -> ToolBarContent {
    .init(
      trailingActions: [],
      leadingActions: [
        Action(image: Theme.shared.image.chevronLeft) {
          self.onPop()
        }
      ]
    )
  }

  private func onIssueDocuments() {
    setState { $0.copy(error: nil) }
    errorMessage = String()
    pushLoader()
  }

  private func pushLoader() {
    let config = viewState.config

    router.push(
      with: .featureIssuanceModule(
        .documentLoaderView(
          config: DocumentLoaderUiConfig(
            offerUri: config.offerUri,
            issuerName: config.issuerName,
            docOffers: config.docOffers,
            successNavigation: config.successNavigation,
            navigationCancelType: config.navigationCancelType,
            txCodeValue: codeInput
          ),
          onFailure: { [weak self] in
            Task { @MainActor in
              self?.onIssuanceFailed()
            }
          }
        )
      )
    )
  }

  private func onIssuanceFailed() {
    errorMessage = LocalizableStringKey.eaaOfferTxCodeInvalidEntry.toString
  }

  func primaryButtonAction() {
    onIssueDocuments()
  }

  private func resetError() {
    self.setState { $0.copy(error: nil) }
    self.codeInput = ""
    self.codeIsFocused = true
  }
}
