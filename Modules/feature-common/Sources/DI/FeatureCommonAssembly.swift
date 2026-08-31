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
import logic_authentication
import logic_business
import logic_core
import logic_api
import wallet_backend

public final class FeatureCommonAssembly: Assembly {

  public init() {}

  public func assemble(container: Container) {
    container.register(QuickPinInteractor.self) { r in
      QuickPinInteractorImpl(pinStorageController: r.force(PinStorageController.self))
    }
    .inObjectScope(ObjectScope.transient)

    container.register(BiometryInteractor.self) { r in
      BiometryInteractorImpl(
        prefsController: r.force(PrefsController.self),
        quickPinInteractor: r.force(QuickPinInteractor.self),
        biometryController: r.force(SystemBiometryController.self),
        secureEnclaveController: r.force(SecureEnclaveController.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(ScannerInteractor.self) { r in
      ScannerInteractorImpl(
        formValidator: r.force(FormValidator.self),
        walletKitController: r.force(WalletKitController.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(PIDRevokeInteractor.self) { r in
      PIDRevokeInteractorImpl(
        walletKitController: r.force(WalletKitController.self),
        prefsController: r.force(PrefsController.self),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        rwscaInteractor: r.force(RWSCAInteractor.self),
        logger: r.force(Logging.self)
      )
    }.inObjectScope(ObjectScope.transient)

    container.register(PARInteractor.self) { r in
      PARInteractorImpl(
        walletPoPInteractor: r.force(WalletPoPController.self),
        walletKitController: r.force(WalletKitController.self),
        walletRegistrationInteractor: r.force(WalletRegistrationInteractor.self),
        secureEnclaveController: r.force(SecureEnclaveController.self)
      )
    }.inObjectScope(ObjectScope.transient)

    container.register(PinSessionInteractor.self) { r in
      PinSessionInteractorImpl(
        mdvmInteractor: r.force(MDVMInteractor.self),
        rwscaInteractor: r.force(RWSCAInteractor.self),
        secureEnclaveController: r.force(SecureEnclaveController.self)
      )
    }.inObjectScope(ObjectScope.transient)
  }
}
