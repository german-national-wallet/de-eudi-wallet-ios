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
import logic_business
import logic_api
import logic_feature_flags
import MdocSecurity18013

public final class LogicCoreAssembly: Assembly {

  public init() {}

  public func assemble(container: Container) {
    container.register(AppBlockingController.self) { r in
      AppBlockingControllerImpl(
        configLogic: r.force(ConfigLogic.self),
        featureFlagRepository: r.force(FeatureFlagRepository.self),
        prefsController: r.force(PrefsController.self)
      )
    }
    .inObjectScope(ObjectScope.container)

      container.register(WalletKitConfig.self) { r in
        WalletKitConfigImpl(
          configLogic: r.force(ConfigLogic.self),
          walletKitAttestationProvider: r.force(WalletAttestationsProvider.self)
        )
      }
      .inObjectScope(ObjectScope.container)

    container.register(WalletAttestationsProvider.self) { r in
      WalletAttestationProviderImpl(
        wiaIssuanceService: r.force(WIAIssuanceService.self),
        secureEnclaveController: r.force(SecureEnclaveController.self)
      )
    }
    .inObjectScope(ObjectScope.graph)

      // swiftlint:disable unused_closure_parameter
      container.register(SecureKeyStorage.self, name: RemoteWSCAService.name) { r in
        RemoteKeyStorage(serviceName: RemoteWSCAService.name, accessGroup: nil, logger: r.force(Logging.self))
      }
      .inObjectScope(ObjectScope.container)
    
      container.register(SecureKeyStorage.self, name: SoftwareSecureArea.name) { r in
        KeyChainSecureKeyStorage(serviceName: SoftwareSecureArea.name, accessGroup: nil)
      }
      .inObjectScope(ObjectScope.container)
     
      // swiftlint:enable unused_closure_parameter

    container.register(NonceRepository.self) { r in
      NonceRepositoryImpl(networkManager: r.force(NetworkManager.self))
    }
    .inObjectScope(ObjectScope.container)

    container.register(RemoteWSCAService.self, name: RemoteWSCAService.name) { r in
      RemoteWSCAService(
        secureEnclaveController: r.force(SecureEnclaveController.self),
        rwscaInteractor: r.force(RWSCAInteractor.self),
        nonceRepository: r.force(NonceRepository.self),
        storage: r.force(SecureKeyStorage.self, name: RemoteWSCAService.name),
        config: r.force(ConfigLogic.self)
      )
    }
    .inObjectScope(ObjectScope.container)

      container.register(SecureArea.self, name: SoftwareSecureArea.name) { r in
        SoftwareSecureArea.create(storage: r.force(SecureKeyStorage.self, name: SoftwareSecureArea.name))
      }
      .inObjectScope(ObjectScope.container)

      container.register(PinnedCertificateNetworking.self) { r in
        PinnedCertificateNetworking(logger: r.force(Logging.self))
      }
      .inObjectScope(ObjectScope.container)
      
      container.register(WalletKitController.self) { r in
        WalletKitControllerImpl(
          configLogic: r.force(WalletKitConfig.self),
          keyChainController: r.force(KeyChainController.self),
          featureFlagRepository: r.force(FeatureFlagRepository.self),
          sessionCoordinatorHolder: r.force(SessionCoordinatorHolder.self),
          secureAreas: [
            r.force(RemoteWSCAService.self, name: RemoteWSCAService.name),
            r.force(SecureArea.self, name: SoftwareSecureArea.name)
          ],
          networking: r.force(PinnedCertificateNetworking.self),
          logger: r.force(Logging.self)
        )
      }
      .inObjectScope(ObjectScope.container)

    container.register(ProximitySessionCoordinator.self) { _, session in
      ProximitySessionCoordinatorImpl(session: session)
    }
    .inObjectScope(ObjectScope.transient)

    container.register(RemoteSessionCoordinator.self) { _, session in
      RemoteSessionCoordinatorImpl(session: session)
    }
    .inObjectScope(ObjectScope.transient)

    container.register(SessionCoordinatorHolder.self) { _ in
      SessionCoordinatorHolderImpl()
    }
    .inObjectScope(ObjectScope.transient)

    container.register(PlatformAttestationInteractor.self) { r in
      PlatformAttestationInteractorImpl(
        secureEnclaveController: r.force(SecureEnclaveController.self),
        isUITesting: AppEnvironment.isUITesting
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(WalletRevocationStore.self) { r in
      WalletRevocationStoreImpl(
        prefsController: r.force(PrefsController.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.container)

    container.register(MDVMInteractor.self) { r in
      MDVMInteractorImpl(
        mdvmRepository: r.force(MDVMRepository.self),
        platformAttestationInteractor: r.force(PlatformAttestationInteractor.self),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        configLogic: r.force(ConfigLogic.self),
        prefsController: r.force(PrefsController.self),
        featureFlagRepository: r.force(FeatureFlagRepository.self),
        walletRevocationStore: r.force(WalletRevocationStore.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(MDVMTokenRenewalService.self) { r in
      MDVMInteractorImpl(
        mdvmRepository: r.force(MDVMRepository.self),
        platformAttestationInteractor: r.force(PlatformAttestationInteractor.self),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        configLogic: r.force(ConfigLogic.self),
        prefsController: r.force(PrefsController.self),
        featureFlagRepository: r.force(FeatureFlagRepository.self),
        walletRevocationStore: r.force(WalletRevocationStore.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(WalletRevocationInteractor.self) { r in
      WalletRevocationInteractorImpl(
        renewalService: r.force(MDVMTokenRenewalService.self),
        store: r.force(WalletRevocationStore.self),
        prefsController: r.force(PrefsController.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.container)

    container.register(RWSCAInteractor.self) { r in
      RWSCAInteractorImpl(
        rwscaRepository: r.force(RWSCARepository.self),
        mdvmRepository: r.force(MDVMRepository.self),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        prefsController: r.force(PrefsController.self),
        walletPinRepository: r.force(WalletPinRepository.self)
      )
    }
    .inObjectScope(ObjectScope.transient)
  }
}
