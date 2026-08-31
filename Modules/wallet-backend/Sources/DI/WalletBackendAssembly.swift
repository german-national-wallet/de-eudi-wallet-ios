//
//  WalletBackendAssembly.swift
//  wallet-backend
//

import Swinject
import logic_api
import logic_business
import logic_core

public final class WalletBackendAssembly: Assembly {

  public init() {}

  public func assemble(container: Container) {
    container.register(WPBRepository.self) { r in
      WPBRepositoryImpl(
        networkManager: r.force(NetworkManager.self),
        httpSignatureService: r.force(HTTPSignatureService.self),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(WPBInteractor.self) { r in
      WPBInteractorImpl(
        repository: r.force(WPBRepository.self),
        mdvmRepository: r.force(MDVMRepository.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(WIAIssuanceService.self) { r in
      WPBInteractorImpl(
        repository: r.force(WPBRepository.self),
        mdvmRepository: r.force(MDVMRepository.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    container.register(WalletRegistrationInteractor.self) { r in
      WalletRegistrationInteractorImpl(
        mdvmInteractor: r.force(MDVMInteractor.self),
        wpbInteractor: r.force(WPBInteractor.self),
        walletRevocationInteractor: r.force(WalletRevocationInteractor.self)
      )
    }
    .inObjectScope(ObjectScope.transient)
  }
}
