//
//  DocumentLoaderViewModel.swift
//  feature-issuance
//

import logic_ui
import logic_resources
import logic_business
import feature_common

@Copyable
struct DocumentLoaderViewState: ViewState {
  let progress: ProgressState
  let config: DocumentLoaderUiConfig
}

final class DocumentLoaderViewModel<Router: RouterHost>: ViewModel<Router, DocumentLoaderViewState> {

  private let successPause: Duration = .milliseconds(3150)

  private let interactor: DocumentOfferInteractor
  private let onFailure: (@Sendable () -> Void)?
  private let logger: Logging?
  private var issuanceStarted = false

  init(
    router: Router,
    config: any UIConfigType,
    interactor: DocumentOfferInteractor,
    onFailure: (@Sendable () -> Void)?,
    logger: Logging? = nil
  ) {
    guard let config = config as? DocumentLoaderUiConfig else {
      fatalError("DocumentLoaderViewModel:: Invalid configuraton")
    }
    self.interactor = interactor
    self.onFailure = onFailure
    self.logger = logger
    super.init(
      router: router,
      initialState: .init(
        progress: .loading,
        config: config
      )
    )
  }

  func issueDocuments() async {
    if await resumePendingIssuance() {
      return
    }
    guard !issuanceStarted else {
      router.pop()
      return
    }
    issuanceStarted = true

    let config = viewState.config

    let state = await Task.detached { () -> OfferResultPartialState in
      return await self.interactor.issueDocuments(
        with: config.offerUri,
        issuerName: config.issuerName,
        docOffers: config.docOffers,
        successNavigation: config.successNavigation,
        txCodeValue: config.txCodeValue
      )
    }.value

    switch state {
    case .success:
      await confirmSuccess()
    case .partialSuccess(let route), .deferredSuccess(let route):
      router.push(with: route)
    case .dynamicIssuance(let session):
      router.push(
        with: .featurePresentationModule(
          .presentationRPInfo(
            presentationCoordinator: session,
            originator: .featureIssuanceModule(.documentLoaderView(config: viewState.config))
          )
        )
      )
    case .failure:
      reportFailure()
    }
  }

  private func resumePendingIssuance() async -> Bool {
    let config = viewState.config

    let state = await Task.detached { () -> OfferDynamicIssuancePartialState in
      return await self.interactor.resumeDynamicIssuance(
        issuerName: config.issuerName,
        successNavigation: config.successNavigation
      )
    }.value

    switch state {
    case .noPending:
      return false
    case .success:
      logger?.d("loader: pending issuance resumed successfully")
      await confirmSuccess()
      return true
    case .failure:
      logger?.d("loader: pending issuance resume failed")
      reportFailure()
      return true
    }
  }

  private func confirmSuccess() async {
    setState { $0.copy(progress: .success) }
    try? await Task.sleep(for: successPause)

    switch viewState.config.successNavigation {
    case .popTo(let route):
      router.popTo(with: route)
    case .push(let route):
      router.push(with: route)
    }
  }

  private func reportFailure() {
    router.pop()
    onFailure?()
  }
}
