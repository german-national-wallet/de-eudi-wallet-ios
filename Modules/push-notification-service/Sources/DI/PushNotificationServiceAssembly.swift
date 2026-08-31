//
//  PushNotificationServiceAssembly.swift
//  push-notification-service
//

import Swinject
import logic_api
import logic_business
import logic_feature_flags

public final class PushNotificationServiceAssembly: Assembly {

  public init() {}

  public func assemble(container: Container) {
    container.register(PushAuthorizationProvider.self) { _ in
      UserNotificationAuthorizationProvider()
    }
    .inObjectScope(ObjectScope.transient)

    container.register(PNSRepository.self) { r in
      PNSRepositoryImpl(
        networkManager: r.force(NetworkManager.self),
        httpSignatureService: r.force(HTTPSignatureService.self),
        secureEnclaveController: r.force(SecureEnclaveController.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.transient)

    /// Container scope on purpose: the interactor holds the in-session `mpp_registration_token` and
    /// serialises syncs, both of which only work with a single shared instance.
    container.register(PNSAccountInteractor.self) { r in
      PNSAccountInteractorImpl(
        repository: r.force(PNSRepository.self),
        mdvmRepository: r.force(MDVMRepository.self),
        authorizationProvider: r.force(PushAuthorizationProvider.self),
        featureFlagRepository: r.force(FeatureFlagRepository.self),
        logger: r.force(Logging.self)
      )
    }
    .inObjectScope(ObjectScope.container)
  }
}
