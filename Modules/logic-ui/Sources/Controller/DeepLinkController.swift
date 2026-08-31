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

import Foundation
import logic_business
import logic_core
//import EudiRQESUi
import logic_api

public struct DeepLink {}

public protocol DeepLinkController: Sendable {
  func hasDeepLink(url: URL) -> DeepLink.Executable?
  @MainActor func handleDeepLinkAction(
    routerHost: RouterHost,
    deepLinkExecutable: DeepLink.Executable,
    remoteSessionCoordinator: RemoteSessionCoordinator?
  )
  func getPendingDeepLinkAction() -> DeepLink.Executable?
  func cacheDeepLinkURL(url: URL)
  func removeCachedDeepLinkURL()
  func isDeeplinkFlowActive() async -> Bool
  func setDeeplinkFlowFlag(_ active: Bool) async
  func clearFirstRunFlag() async
}

final class DeepLinkControllerImpl: DeepLinkController {

  private let prefsController: PrefsController
  private let urlSchemaController: UrlSchemaController
  private let walletKitController: WalletKitController
  
  @MainActor private static var isDeeplinkFlowActive: Bool = false
  
  init(
    prefsController: PrefsController,
    urlSchemaController: UrlSchemaController,
    walletKitController: WalletKitController
  ) {
    self.prefsController = prefsController
    self.urlSchemaController = urlSchemaController
    self.walletKitController = walletKitController
  }

  private var hasDocuments: Bool {
    return !walletKitController.fetchAllDocuments().isEmpty
  }

  public func getPendingDeepLinkAction() -> DeepLink.Executable? {
    if let cachedLink = prefsController.getString(forKey: .cachedDeepLink),
       let url = cachedLink.toCompatibleUrl() {
      return hasDeepLink(url: url)
    }
    return nil
  }
  
  @MainActor public func isDeeplinkFlowActive() -> Bool {
    return DeepLinkControllerImpl.isDeeplinkFlowActive
  }
  
  @MainActor public func setDeeplinkFlowFlag(_ active: Bool) {
    DeepLinkControllerImpl.isDeeplinkFlowActive = active
  }
  
  public func hasDeepLink(url: URL) -> DeepLink.Executable? {
    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
       let scheme = components.scheme,
       let action = DeepLink.Action.parseType(with: scheme, and: urlSchemaController) {
      return DeepLink.Executable(link: components, plainUrl: url, action: action)
    }
    return nil
  }

  public func handleDeepLinkAction(
    routerHost: RouterHost,
    deepLinkExecutable: DeepLink.Executable,
    remoteSessionCoordinator: RemoteSessionCoordinator?
  ) {
    
    let isPresentation = deepLinkExecutable.action == .openid4vp
      || deepLinkExecutable.action == .haip_vp
    if isPresentation, routerHost.isScreenForeground(with: .featureStartupModule(.startup)) {
      if let url = deepLinkExecutable.link.url {
        cacheDeepLinkURL(url: url)
      }
      return
    }

    setDeeplinkFlowFlag(true)

    removeCachedDeepLinkURL()

    switch deepLinkExecutable.action {
    case .openid4vp, .haip_vp:
      guard let remoteSessionCoordinator else {
        fatalError("DeepLink Action OpenId4VP Requires Remote Session Coordinator")
      }
      if !routerHost.isScreenForeground(
        with: .featurePresentationModule(
          .presentationRequest(
            presentationCoordinator: remoteSessionCoordinator,
            originator: .featureDashboardModule(.dashboard)
          )
        )
      ) {
        if let invalidPINResponse = try? prefsController.getObject(forKey: .invalidPinResponse, as: InvalidPasswordResponse.self),
            invalidPINResponse.isBlocked || invalidPINResponse.tryAllowedAfter?.isInFuture() == true {
          routerHost.push(
            with: .featurePresentationModule(
              .pinRetryCounterView(config: getInvalidPinRetryMessageConfig(response: invalidPINResponse, remoteSessionCoordinator: remoteSessionCoordinator))
            )
          )
        } else {
          routerHost.push(
            with: .featurePresentationModule(
              .presentationRPInfo(
                presentationCoordinator: remoteSessionCoordinator,
                originator: .featureDashboardModule(.dashboard)
              )
            )
          )
        }
      } else {
        postNotification(
          with: NSNotification.PresentationVC,
          and: ["session": remoteSessionCoordinator]
        )
      }
    case .external:
      deepLinkExecutable.plainUrl.open()
    case .credential_offer, .haip_vci:
      let config = UIConfig.Generic(
        arguments: ["uri": deepLinkExecutable.plainUrl.absoluteString],
        navigationSuccessType: hasDocuments
        ? .popTo(.featureDashboardModule(.dashboard))
        : .push(.featureDashboardModule(.dashboard)),
        navigationCancelType: .pop
      )
      if !routerHost.isScreenForeground(with: .featureIssuanceModule(.credentialOfferRequest(config: config))) {
        routerHost.push(with: .featureIssuanceModule(.credentialOfferConsentView(config: config)))
      } else {
        postNotification(
          with: NSNotification.CredentialOffer,
          and: ["uri": deepLinkExecutable.plainUrl.absoluteString]
        )
      }
    }
  }

  private func getInvalidPinRetryMessageConfig(response: InvalidPasswordResponse, remoteSessionCoordinator: RemoteSessionCoordinator) -> UIConfig.InvalidPinRetryMessageConfig {
    UIConfig.InvalidPinRetryMessageConfig(
      mainTitle: .walletPinMultipleWrongEntry,
      retryMessage: .walletPinTryAgainIn,
      primaryButtonTitle: .walletPinForgotten,
      remoteSessionCoordinator: remoteSessionCoordinator,
      invalidPasswordResponse: response
    )
  }

  public func clearFirstRunFlag() {
    prefsController.setValue(false, forKey: .runAtLeastOnce)
    prefsController.remove(forKey: .isPinInitialized)
  }
  
  public func cacheDeepLinkURL(url: URL) {
    prefsController.setValue(url.absoluteString, forKey: .cachedDeepLink)
  }

  public func removeCachedDeepLinkURL() {
    prefsController.remove(forKey: .cachedDeepLink)
  }

  private func postNotification(
    with name: NSNotification.Name,
    and info: [AnyHashable: Any]? = nil
  ) {
    NotificationCenter.default.post(
      name: name,
      object: nil,
      userInfo: info
    )
  }
}

public extension DeepLink {
  struct Executable: Equatable, Sendable {

    public let link: URLComponents
    public let plainUrl: URL
    public let action: DeepLink.Action

    public var requiresCoordinator: Bool {
      action == .openid4vp
    }
  }
}

public extension DeepLink {
  enum Action: String, Equatable, Sendable {

    case openid4vp
    case haip_vp
    case credential_offer
    case haip_vci
    case external
    
    private var name: String {
      return rawValue.replacingOccurrences(of: "_", with: "-")
    }

    private func getSchemas(
      with urlSchemaController: UrlSchemaController
    ) -> [String] {
      return urlSchemaController.retrieveSchemas(with: name)
    }

    static func parseType(
      with scheme: String,
      and urlSchemaController: UrlSchemaController
    ) -> Action? {
      switch scheme {
      case _ where openid4vp.getSchemas(with: urlSchemaController).contains(scheme),
        _ where haip_vp.getSchemas(with: urlSchemaController).contains(scheme):
        return .openid4vp
      case _ where credential_offer.getSchemas(with: urlSchemaController).contains(scheme),
        _ where haip_vci.getSchemas(with: urlSchemaController).contains(scheme):
        return .credential_offer
      default:
        return .external
      }
    }
  }
}

public extension NSNotification {
  static let PresentationVC = Notification.Name.init("PresentationVC")
  static let CredentialOffer = Notification.Name.init("CredentialOffer")
}
