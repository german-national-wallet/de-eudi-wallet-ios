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

import feature_common
import logic_analytics
import logic_core
import logic_resources

final class PresentationRequestViewModel<Router: RouterHost>: BaseRequestViewModel<Router> {

  @Published var errorDialog: PresentationErrorDialogConfig?

  private let interactor: PresentationInteractor
  private let pinSessionInteractor: PinSessionInteractor
  private let analyticsController: AnalyticsController
  private let errorHandler: PresentationErrorHandler

  init(
    router: Router,
    interactor: PresentationInteractor,
    pinSessionInteractor: PinSessionInteractor,
    analyticsController: AnalyticsController,
    errorHandler: PresentationErrorHandler,
    originator: AppRoute
  ) {
    self.interactor = interactor
    self.pinSessionInteractor = pinSessionInteractor
    self.analyticsController = analyticsController
    self.errorHandler = errorHandler
    super.init(router: router, originator: originator)
  }

  override func doWork() async {
    self.onStartLoading()
    // Force starting presentation trace because no RPInfo in previous flow
    analyticsController.startTrace(name: AnalyticsConstants.TraceName.presentation, initialAttributes: [:])

    let result = await Task.detached { () -> Result<OnlineAuthenticationRequestSuccessModel, Error> in
      return await self.interactor.onDeviceEngagement()
    }.value

    switch result {
    case .success(let authenticationRequest):
      if await refuseIfBlockedByRegistration(authenticationRequest, interactor: interactor) { return }

      self.onReceivedItems(
        with: authenticationRequest.requestDataCells,
        title: .requestDataTitle(
          [authenticationRequest.relyingParty]
        ),
        relyingParty: .custom(authenticationRequest.relyingParty),
        isTrusted: authenticationRequest.isTrusted
      )
      self.onPresentationDoWorkSuccess()
    case .failure(let error):
      presentError(errorHandler.handle(error, originator: getOriginator(), retryAction: retryAction))
    }
  }

  override func onShare() {
    Task {

      let items = self.viewState.items
      let documentIDs = items.map(\.section.id)
      let isPIDRequest = interactor.isPIDPresentation(documentIDs: documentIDs)

      let result = await Task.detached { () -> Result<RequestItemConvertible, Error> in
        return await self.interactor.onResponsePrepare(requestItems: items)
      }.value

      switch result {
      case .success:
        if let route = isPIDRequest ? self.getPinRoute() : self.getSuccessRoute() {
          self.router.push(with: route)
        } else {
          self.router.popTo(
            with: self.getPopRoute() ?? .featureDashboardModule(.dashboard)
          )
        }
      case .failure(let error):
        if isPIDRequest {
          pinSessionInteractor.clear()
        }
        self.presentError(self.errorHandler.handle(error, originator: self.getOriginator()))
      }
    }
  }

  override func getSuccessRoute() -> AppRoute? {
    return switch interactor.getCoordinator() {
    case .success(let remoteSessionCoordinator):
        .featureCommonModule(
          .biometry(
            config: UIConfig.Biometry(
              navigationTitle: .enterPassword,
              caption: .requestDataShareBiometryCaption,
              quickPinOnlyCaption: .requestDataShareQuickPinCaption,
              navigationSuccessType: .push(
                .featurePresentationModule(
                  .presentationLoader(
                    relyingParty: getRelyingParty().toString,
                    relyingPartyIsTrusted: getRelyingPartyIsTrusted(),
                    presentationCoordinator: remoteSessionCoordinator,
                    originator: getOriginator(),
                    items: viewState.items.filterSelectedRows(),
                    dataUiItems: viewState.items
                  )
                )
              ),
              navigationErrorScreen: nil,
              navigationBackType: .pop,
              isPreAuthorization: false,
              shouldInitializeBiometricOnCreate: true,
              invalidPinTitle: .invalidQuickPin,
              pinScreenType: .verifyWalletPinFlow
            )
          )
        )
    case .failure: nil
    }
  }

  func getPinRoute() -> AppRoute? {
    return switch interactor.getCoordinator() {
    case .success(let remoteSessionCoordinator):
      .featurePresentationModule(
        .showPinView(
          config: UIConfig.Biometry(
            navigationTitle: .enterPassword,
            caption: .requestDataShareBiometryCaption,
            primaryButtonTitle: .pidPresentationWalletPinEntryPrimButton,
            quickPinOnlyCaption: .space,
            navigationSuccessType: .push(
              .featurePresentationModule(
                .presentationLoader(
                  relyingParty: getRelyingParty().toString,
                  relyingPartyIsTrusted: getRelyingPartyIsTrusted(),
                  presentationCoordinator: remoteSessionCoordinator,
                  originator: getOriginator(),
                  items: viewState.items.filterSelectedRows(),
                  dataUiItems: viewState.items
                )
              )
            ),
            navigationErrorScreen: nil,
            navigationBackType: .pop,
            isPreAuthorization: false,
            shouldInitializeBiometricOnCreate: true,
            invalidPinTitle: .invalidQuickPin,
            pinScreenType: .verifyWalletPinFlow,
            imageIcon: Theme.shared.image.setupWalletPin,
            items: viewState.items
          ),
          presentationCoordinator: remoteSessionCoordinator
        )
      )
    case .failure: nil
    }
  }

  override func getPopRoute() -> AppRoute? {
    return getOriginator()
  }

  override func getTitle() -> LocalizableStringKey {
    .dataSharingRequest
  }

  override func getCaption() -> LocalizableStringKey {
    .requestsTheFollowing
  }

  override func getDataRequestInfo() -> LocalizableStringKey {
    .requestDataInfoNotice
  }

  override func getRelyingParty() -> LocalizableStringKey {
    viewState.relyingParty
  }

  override func getRelyingPartyIsTrusted() -> Bool {
    viewState.isTrusted
  }

  override func getTitleCaption() -> LocalizableStringKey {
    .requestDataTitle([""])
  }

  override func getTrustedRelyingParty() -> LocalizableStringKey {
    .requestDataVerifiedEntity
  }

  override func getTrustedRelyingPartyInfo() -> LocalizableStringKey {
    .requestDataVerifiedEntityMessage
  }

  func handleDeepLinkNotification(with info: [AnyHashable: Any]) {
    guard let session = info["session"] as? RemoteSessionCoordinator else {
      return
    }
    resetState()
    interactor.updatePresentationCoordinator(with: session)
    Task { await doWork() }
  }

  func onErrorDialogAction(_ action: PresentationErrorDialogConfig.Action) {
    errorDialog = nil
    switch action {
    case .popTo(let route):
      router.popTo(with: route)
    case .addDigitalIDAgain:
      router.popTo(with: getOriginator())
    case .dismiss:
      break
    case .retry(let retryAction):
      retryAction.action()
    }
  }

  private func presentError(_ presentation: PresentationErrorPresentation) {
    switch presentation {
    case .notice(let config):
      router.push(with: .featurePresentationModule(.presentationErrorNotice(config: config)))
    case .dialog(let config):
      errorDialog = config
    }
  }
}
