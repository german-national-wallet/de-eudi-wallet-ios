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
import Swinject
import logic_core
import logic_business
import logic_api
import feature_common
import feature_issuance

public final class FeatureStartupAssembly: Assembly {

  public init() {}

  public func assemble(container: Container) {
    container.register(StartupInteractor.self) { r in
      StartupInteractorImpl(
        walletKitController: r.force(WalletKitController.self),
        quickPinInteractor: r.force(QuickPinInteractor.self),
        keyChainController: r.force(KeyChainController.self),
        prefsController: r.force(PrefsController.self),
        mdvmInteractor: r.force(MDVMInteractor.self),
        rwscaInteractor: r.force(RWSCAInteractor.self),
        remoteWSCA: r.force(RemoteWSCAService.self, name: RemoteWSCAService.name),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        pidRevokeInteractor: r.force(PIDRevokeInteractor.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

  }
}
