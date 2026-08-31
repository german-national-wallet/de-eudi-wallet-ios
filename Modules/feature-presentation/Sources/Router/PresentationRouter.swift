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
import logic_ui
import logic_business
import feature_common
import logic_core
import logic_analytics

@MainActor
public final class PresentationRouter {

  public static func resolve(module: FeaturePresentationRouteModule, host: some RouterHost) -> AnyView {
    switch module {
    case .presentationLoader(
      let relyingParty,
      let relyingPartyIsTrusted,
      presentationCoordinator: let presentationCoordinator,
      originator: let originator,
      let uiModels,
      let dataUiModels
    ):
      PresentationLoadingView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            PresentationInteractor.self,
            argument: presentationCoordinator as RemoteSessionCoordinator
          ),
          relyingParty: relyingParty,
          relyingPartyIsTrusted: relyingPartyIsTrusted,
          originator: originator,
          requestItems: uiModels.compactMap { $0 as? PresentationListItemSection },
          prefsController: DIGraph.resolver.force(PrefsController.self),
          analyticsController: DIGraph.resolver.force(AnalyticsController.self),
          pinSessionInteractor: DIGraph.resolver.force(PinSessionInteractor.self),
          items: dataUiModels?.compactMap({
            $0 as? RequestDataUiModel
          }),
          logger: DIGraph.resolver.force(Logging.self)
        )
      ).eraseToAnyView()
    case .presentationRequest(
      presentationCoordinator: let presentationCoordinator,
      originator: let originator
    ):
      PresentationRequestView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            PresentationInteractor.self,
            argument: presentationCoordinator as RemoteSessionCoordinator
          ),
          pinSessionInteractor: DIGraph.resolver.force(
            PinSessionInteractor.self
          ),
          originator: originator
        )
      ).eraseToAnyView()
    case .presentationSuccess(
      let config,
      let uiModels
    ):
      PresentationSuccessView(
        with: .init(
          router: host,
          config: config,
          deepLinkController: DIGraph.resolver.force(
            DeepLinkController.self
          ),
          requestItems: uiModels.compactMap { $0 as? PresentationListItemSection }
        )
      ).eraseToAnyView()
    case .presentationConsent(presentationCoordinator: let presentationCoordinator, originator: let originator, let relyingParty):
      ConsentView(
            with: .init(
              router: host,
              interactor: DIGraph.resolver.force(
                PresentationInteractor.self,
                argument: presentationCoordinator as RemoteSessionCoordinator
              ),
              pinSessionInteractor: DIGraph.resolver.force(
                PinSessionInteractor.self
              ),
              analyticsController: DIGraph.resolver.force(AnalyticsController.self),
              originator: originator,
              relyingParty: relyingParty
            )
          ).eraseToAnyView()

    case .presentationRPInfo(presentationCoordinator: let presentationCoordinator, originator: let originator):
      RPInfoView(
        viewModel: .init(
          router: host,
          interactor: DIGraph.resolver.force(
          PresentationInteractor.self,
          argument: presentationCoordinator as RemoteSessionCoordinator
          ),
          originator: originator,
          analyticsController: DIGraph.resolver.force(AnalyticsController.self),
          logger: DIGraph.resolver.force(Logging.self)
        )
      ).eraseToAnyView()
    case .showPinView(config: let config):
      PINView(
        viewModel: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            BiometryInteractor.self
          ),
          issuanceVarificationInteractor: nil,
          prefsController: DIGraph.resolver.force(
            PrefsController.self
          ),
          secureEnclaveController: DIGraph.resolver.force(SecureEnclaveController.self),
          parInteractor: DIGraph.resolver.force(PARInteractor.self),
          config: config,
          onPinEntered: nil,
          pinSessionInteractor: DIGraph.resolver.force(PinSessionInteractor.self),
          logger: DIGraph.resolver.force(Logging.self)
        )
      ).eraseToAnyView()
    case .pinRetryCounterView(config: let config):
      InvalidPinRetryMessageView(viewModel: .init(router: host, config: config, pidRevokeInteractor: DIGraph.resolver.force(
        PIDRevokeInteractor.self
      ), prefsController: DIGraph.resolver.force(PrefsController.self),
         deepLinkController: DIGraph.resolver.force(
          DeepLinkController.self
        ))).eraseToAnyView()
    case .credentialNotFoundInstructionsView(config: let config):
      InstructionsView(
        viewModel: .init(
          router: host,
          config: config
        )
      ).eraseToAnyView()
    }
  }
}
