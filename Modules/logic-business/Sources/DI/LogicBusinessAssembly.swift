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

public final class LogicBusinessAssembly: Assembly {

  public init() {}

  public func assemble(container: Container) {

    container.register(KeyChainController.self) { r in
      KeyChainControllerImpl(logger: r.force(Logging.self))
    }
    .inObjectScope(ObjectScope.container)

    container.register(PrefsController.self) { r in
      PrefsControllerImpl(logger: r.force(Logging.self))
    }
    .inObjectScope(ObjectScope.container)

    container.register(WalletDataEncryptionController.self) { r in
      WalletDataEncryptionControllerImpl(logger: r.force(Logging.self))
    }
    .inObjectScope(ObjectScope.container)

    container.register(DebugConfigController.self) { r in
      DebugConfigControllerImpl(
        keyChainController: r.force(KeyChainController.self)
      )
    }
    .inObjectScope(ObjectScope.container)

    container.register(ConfigLogic.self) { r in
      ConfigLogicImpl(debugConfigController: r.force(DebugConfigController.self))
    }
    .inObjectScope(ObjectScope.container)

    container.register(FormValidator.self) { _ in
      FormValidatorImpl()
    }
    .inObjectScope(ObjectScope.transient)

    container.register(ReachabilityController.self) { r in
      ReachabilityControllerImpl(logger: r.force(Logging.self))
    }
    .inObjectScope(ObjectScope.transient)
      
      container.register(FilterValidator.self) { _ in
          FilterValidatorImpl()
      }
      .inObjectScope(ObjectScope.transient)

    container.register(Logging.self) { _ in DebugLogger() }
      .inObjectScope(.container)
  }
}
