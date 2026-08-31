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
import logic_api
import logic_business
import logic_authentication
import logic_storage
import logic_ui
import feature_common

public final class FeatureIssuanceAssembly: Assembly {

  public init() {}

  public func assemble(container: Container) {
    container.register(AddDocumentInteractor.self) { r in
      AddDocumentInteractorImpl(
        walletController: r.force(WalletKitController.self),
        secureEnclaveController: r.force(SecureEnclaveController.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(CredentialsInteractor.self) { r in
      CredentialsInteractorImpl(
        walletKitController: r.force(WalletKitController.self),
        walletPoPController: r.force(WalletPoPController.self),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(DocumentDetailsInteractor.self) { r in
      DocumentDetailsInteractorImpl(
        walletController: r.force(WalletKitController.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(SecureEnclaveController.self) { r in
      SecureEnclaveControllerImpl(
        logger: r.force(Logging.self),
        walletDataEncryptionController: r.force(WalletDataEncryptionController.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(DocumentOfferInteractor.self) { r in
      DocumentOfferInteractorImpl(walletController: r.force(WalletKitController.self))
    }
    .inObjectScope(ObjectScope.transient)

    container.register(NetworkManager.self) { r in
      NetworkManagerImpl(
        baseHost: r.force(ConfigLogic.self).walletHostUrl,
        logger: r.force(Logging.self),
        debugConfigController: r.force(DebugConfigController.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(IssuanceCardRemoteRepository.self) { r in
      IssuanceCardRemoteRepositoryImpl(networkManager: r.force(NetworkManager.self))
    }
    .inObjectScope(ObjectScope.transient)

    container.register(IssuanceWorkflowInteractor.self) { r in
      IssuanceWorkflowInteractorImpl(logger: r.force(Logging.self))
    }
    .inObjectScope(ObjectScope.transient)

    container.register(IssuanceVerificationInteractor.self) { r in
      IssuanceVerificationInteractorImpl(issuenceWorkflowInteractor: r.force(IssuanceWorkflowInteractor.self))
    }
    .inObjectScope(ObjectScope.transient)

    container.register(IssuanceCardInteractor.self) { r in
      IssuanceCardInteractorImpl(
        issuanceCardRemoteRepository: r.force(IssuanceCardRemoteRepository.self),
        walletController: r.force(WalletKitController.self),
        secureEnclaveController: r.force(SecureEnclaveController.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(WalletPoPController.self) {  _ in
      WalletPoPControllerImpl()
    }
    .inObjectScope(ObjectScope.transient)

    container.register(PinStorageController.self) { r in
      PinStorageControllerImpl(provider: r.force(
        PinStorageProvider.self
      ))
    }
    .inObjectScope(ObjectScope.transient)
  }
}
