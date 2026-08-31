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
import logic_core
import wallet_backend
import push_notification_service

@MainActor
public final class StartupRouter {

  public static func resolve(module: FeatureStartupRouteModule, host: some RouterHost) -> AnyView {
    switch module {
    case .revocationOnboarding(let config):
      WalletRevocationView(
        with: .init(
          router: host,
          config: config
        )
      ).eraseToAnyView()
    case .revocationSaveKey(let config):
      WalletRevocationSaveKeyView(
        with: .init(
          router: host,
          config: config,
          interactor: DIGraph.resolver.force(
            StartupInteractor.self
          )
        )
      ).eraseToAnyView()
    case .startup:
      StartupView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            StartupInteractor.self
          ),
          walletRegistrationInteractor: DIGraph.resolver.force(
            WalletRegistrationInteractor.self
          ),
          pnsAccountInteractor: DIGraph.resolver.force(
            PNSAccountInteractor.self
          ),
          walletRevocationInteractor: DIGraph.resolver.force(
            WalletRevocationInteractor.self
          ),
          deepLinkController: DIGraph.resolver.force(
            DeepLinkController.self
          ),
          logger: DIGraph.resolver.force(
            Logging.self
          )
        )
      ).eraseToAnyView()
    }
  }
}
