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
import SwiftUI
import logic_business
import logic_core
import logic_resources

public enum FeatureStartupRouteModule: AppRouteModule {

  case startup
  case revocationOnboarding(config: any UIConfigType)
  case revocationSaveKey(config: any UIConfigType)

  public var info: (key: String, arguments: [String: String]) {
    return switch self {
    case .startup:
      (key: "Startup", arguments: [:])
    case .revocationOnboarding(let config):
      (key: "revocationOnboarding", arguments: ["config": config.log])
    case .revocationSaveKey(let config):
      (key: "revocationSaveKey", arguments: ["config": config.log])
    }
  }
}

public enum FeatureCommonRouteModule: AppRouteModule {
  case quickPin(config: any UIConfigType)
  case qrScanner(config: any UIConfigType)
  case biometry(config: any UIConfigType)
  case genericSuccess(config: any UIConfigType)
  case issuanceAddDocumentOptions(config: any UIConfigType)
  case errorView(config: any UIConfigType)
  case illustratedNoticeView(config: any UIConfigType)

  public var info: (key: String, arguments: [String: String]) {
    return switch self {
    case .genericSuccess(let config):
      (key: "GenericSuccess", arguments: ["config": config.log])
    case .biometry(let config):
      (key: "Biometry", arguments: ["config": config.log])
    case .quickPin(let config):
      (key: "QuickPin", arguments: ["config": config.log])
    case .qrScanner(config: let config):
      (key: "QRScanner", arguments: ["config": config.log])
    case .issuanceAddDocumentOptions(let config):
      (key: "issuanceAddDocumentOptions", arguments: ["config": config.log])
    case .errorView(config: let config):
      (key: "errorView", arguments: ["config": config.log])
    case .illustratedNoticeView(config: let config):
      (key: "illustratedNoticeView", arguments: ["config": config.log])
    }
  }
}

public enum FeatureDashboardRouteModule: AppRouteModule {
  case dashboard
  case signDocument
  case sideMenu
  case debugConfig
  case credentialDetail(DocClaimsDecodable)
  case personalDetail(DocClaimsDecodable)

  public var info: (key: String, arguments: [String: String]) {
    return switch self {
    case .dashboard:
      (key: "Dashboard", arguments: [:])
    case .signDocument:
      (key: "SignDocument", arguments: [:])
    case .sideMenu:
      (key: "SideMenu", arguments: [:])
    case .debugConfig:
      (key: "DebugConfig", arguments: [:])
    case .credentialDetail:
      (key: "UserProfile", arguments: [:])
    case .personalDetail:
      (key: "PersonalDetail", arguments: [:])
    }
  }
}

public indirect enum FeaturePresentationRouteModule: AppRouteModule {

  case presentationLoader(
    relyingParty: String,
    relyingPartyIsTrusted: Bool,
    presentationCoordinator: RemoteSessionCoordinator,
    originator: AppRoute,
    items: [any Routable],
    dataUiItems: [any Routable]?
  )
  case presentationRequest(
    presentationCoordinator: RemoteSessionCoordinator,
    originator: AppRoute
  )
  case presentationSuccess(
    config: any UIConfigType,
    [any Routable]
  )
  case presentationConsent(
    presentationCoordinator: RemoteSessionCoordinator,
    originator: AppRoute,
    relyingParty: String
  )
  case presentationRPInfo(
    presentationCoordinator: RemoteSessionCoordinator,
    originator: AppRoute
  )
  case showPinView(
    config: any UIConfigType
  )
  case pinRetryCounterView(config: any UIConfigType)
  case credentialNotFoundInstructionsView(config: any UIConfigType)

  public var info: (key: String, arguments: [String: String]) {
    return switch self {
    case .presentationLoader(let relyingParty, _, _, let originator, let items, _):
      (
        key: "PresentationLoader",
        arguments: [
          "relyingParty": relyingParty,
          "originator": originator.info.key,
          "items": items.map { $0.log }.joined(separator: "|")
        ]
      )
    case .presentationRequest(_, let originator):
      (key: "PresentationRequest", arguments: ["originator": originator.info.key])
    case .presentationSuccess(let config, _):
      (key: "PresentationSuccess", arguments: ["config": config.log])
    case .presentationConsent(presentationCoordinator: let presentationCoordinator, originator: let originator, let relyingParty):
      (key: "PresentationConsent", arguments: ["originator": originator.info.key, "relyingParty": relyingParty])
    case .presentationRPInfo(presentationCoordinator: let presentationCoordinator, originator: let originator):
      (key: "PresentationRPInfo", arguments: ["originator": originator.info.key])
    case .showPinView(config: let config):
      (key: "showPinView", arguments: ["config": config.log])
    case .pinRetryCounterView(config: let config):
      (key: "errorView", arguments: ["config": config.log])
    case .credentialNotFoundInstructionsView(config: let config):
      (key: "credentialNotFoundInstructionsView", arguments: ["config": config.log])
    }
  }
}

public indirect enum FeatureProximityRouteModule: AppRouteModule {

  case proximityConnection(
    presentationCoordinator: ProximitySessionCoordinator,
    originator: AppRoute
  )
  case proximityRequest(
    presentationCoordinator: ProximitySessionCoordinator,
    originator: AppRoute
  )
  case proximityLoader(
    relyingParty: String,
    relyingPartyisTrusted: Bool,
    presentationCoordinator: ProximitySessionCoordinator,
    originator: AppRoute,
    items: [any Routable]
  )
  case proximitySuccess(
    config: any UIConfigType,
    [any Routable]
  )

  public var info: (key: String, arguments: [String: String]) {
    return switch self {
    case .proximityConnection(_, let originator):
      (key: "ProximityConnection", arguments: ["originator": originator.info.key])
    case .proximityRequest(_, let originator):
      (key: "ProximityRequest", arguments: ["originator": originator.info.key])
    case .proximityLoader(let relyingParty, _, _, let originator, let items):
      (
        key: "ProximityLoader",
        arguments: [
          "relyingParty": relyingParty,
          "originator": originator.info.key,
          "items": items.map { $0.log }.joined(separator: "|")
        ]
      )
    case .proximitySuccess:
      (key: "ProximitySuccess", arguments: [:])
    }
  }
}

public enum EidFlowType: Sendable {
    case authentication, setEidPin, confirmNewPin
}

public struct PinCallbackWrapper: Sendable {
  public let onEntered: @Sendable (String) -> Void
  
  public init(onEntered: @Sendable @escaping (String) -> Void) {
    self.onEntered = onEntered
  }
}

public protocol IssuanceVerificationInteractor: Sendable {
  var delegate: IssuanceVerificationInteractorDelegate? { get set }
  func start(tokenURL: URL, pin: String?)
  func startChangePinFlow(tokenURL: URL, transportPin: String)
  func setPin(_ pin: String)
  func assignNewPin(_ pin: String)
  func stop()
  func setCAN(_ can: String)
  func setDelegate(_ delegate: IssuanceVerificationInteractorDelegate)
}

public struct CardStatusInfo {
  public let deactivated: Bool?
  public let inoperative: Bool?
  public let pinRetryCounter: Int?
  
  public init(deactivated: Bool?, inoperative: Bool?, pinRetryCounter: Int?) {
    self.deactivated = deactivated
    self.inoperative = inoperative
    self.pinRetryCounter = pinRetryCounter
  }
}

public protocol IssuanceVerificationInteractorDelegate: AnyObject, Sendable {
  func didRecognizeCard()
  func didNotRecognizeCard()
  func requestPin()
  func didSuccess(result: String)
  func stopIssuanceFlow(with error: Error?)
  func didRequestCAN()
  func invalidCANEntered(error: Error?, cardStatusInfo: CardStatusInfo?)
  func invalidPinErrorReceived(error: Error?, cardStatusInfo: CardStatusInfo?)
  func setNewPin()
  func onChangePinCompleted(success: Bool)
  func canEnteredCorrectly()
  func tcTokenExpired()
  func onBadState(error: String)
}

public protocol IssuanceCardViewModelDelegate: AnyObject, Sendable {
  func invalidPinErrorReceived(error: (any Error)?, cardStatusInfo: CardStatusInfo?)
}

public enum FeatureIssuanceRouteModule: AppRouteModule {

  case issuanceAddDocument(config: any UIConfigType)
  case issuanceDocumentDetails(config: any UIConfigType)
  case issuanceSuccess(config: any UIConfigType, requestItems: [any Routable])
  case credentialOfferRequest(config: any UIConfigType)
  case credentialOfferConsentView(config: any UIConfigType)
  case issuanceCode(config: any UIConfigType)
  case issuanceCard(config: any UIConfigType, requestURI: String, eidPin: String, eidPinFlow: EidFlowType = .authentication, delegate: IssuanceVerificationInteractorDelegate)
  case pinView(config: any UIConfigType, onPinEntered: PinCallbackWrapper? = nil, issuanceVerificationInteractor: IssuanceVerificationInteractor? = nil)
  case canView(config: any UIConfigType, onPinEntered: PinCallbackWrapper?, issuanceVerificationInteractor: IssuanceVerificationInteractor)
  case setEidTransportPinInstructionsView(config: any UIConfigType, issuanceVerificationInteractor: IssuanceVerificationInteractor)
  case setEidPinView(config: any UIConfigType, onPinEntered: PinCallbackWrapper?, issuanceVerificationInteractor: IssuanceVerificationInteractor?)
  case setNewEidInstructionsPinView(config: any UIConfigType, issuanceVerificationInteractor: IssuanceVerificationInteractor?, pinCallbackWrapper: PinCallbackWrapper?, pinScreenType: PINScreenType)
  case issuanceSuccessView(config: any UIConfigType, callback: (@Sendable () -> Void)? = nil)
  case issuanceOnboardingView
  case issuanceOnboardingCardView
  case issuanceOnboardingInstructionView(issuanceVerificationInteractor: IssuanceVerificationInteractor?)
  case issuanceProcessOverviewView(issuanceVerificationInteractor: IssuanceVerificationInteractor?)
  case issuancePidPreviewView(config: any UIConfigType)
  case walletPinSetupInstructionView(config: any UIConfigType)
  case issuanceLoadingView(config: any UIConfigType)
  case consentView(issuanceVerificationInteractor: IssuanceVerificationInteractor?)
  case issuerDetailsView(config: any UIConfigType)
  case documentLoaderView(config: any UIConfigType, onFailure: (@Sendable () -> Void)? = nil)
    
  public var info: (key: String, arguments: [String: String]) {
    return switch self {
    case .issuanceAddDocument(let config):
      (key: "IssuanceAddDocument", arguments: ["config": config.log])
    case .issuanceDocumentDetails(let config):
      (key: "IssuanceDocumentDetails", arguments: ["config": config.log])
    case .issuanceSuccess(let config, _):
      (key: "IssuanceSuccess", arguments: ["config": config.log])
    case .issuanceCode(let config):
      (key: "IssuanceCode", arguments: ["config": config.log])
    case .credentialOfferRequest(let config):
      (key: "CredentialOfferRequest", arguments: ["config": config.log])
    case .issuanceCard(let config, let requestURI, _, _, _):
        (key: "IssuanceCard", arguments: ["requestURI": requestURI, "config": config.log])
    case .pinView(let config, _, _):
        (key: "PinView", arguments: ["config": config.log])
    case .canView(let config, _, _):
        (key: "CANView", arguments: ["config": config.log])
    case .setEidTransportPinInstructionsView(let config, _):
      (key: "setEidTransportPinInstructionsView", arguments: ["config": config.log])
    case .setEidPinView(let config, _, _):
      (key: "setupEidPinView", arguments: ["config": config.log])
    case .setNewEidInstructionsPinView(let config, _, _, _):
      (key: "setNewEidPin", arguments: ["config": config.log])
    case .issuanceSuccessView(config: let config, _):
      (key: "issuanceSuccessView", arguments: ["config": config.log])
    case .issuanceOnboardingView:
      (key: "issuanceOnboardingView", arguments: [:])
    case .issuanceOnboardingCardView:
      (key: "issuanceOnboardingCardView", arguments: [:])
    case .issuanceOnboardingInstructionView:
      (key: "issuanceOnboardingInstructionView", arguments: [:])
    case .issuanceProcessOverviewView:
      (key: "issuanceProcessOverviewView", arguments: [:])
    case .issuancePidPreviewView(let config):
      (key: "issuancePidPreviewView", arguments: ["config": config.log])
    case .walletPinSetupInstructionView:
      (key: "correctPinEntered", arguments: [:])
    case .issuanceLoadingView:
      (key: "issuanceLoadingView", arguments: [:])
    case .consentView:
      (key: "IssuanceConsentView", arguments: [:])
    case .issuerDetailsView(let config):
      (key: "IssuerDetailsView", arguments: ["config": config.log])
    case .credentialOfferConsentView(config: let config):
      (key: "credentialOfferConsentView", arguments: ["config": config.log])
    case .documentLoaderView(let config, _):
      (key: "documentLoaderView", arguments: ["config": config.log])
    }
  }
}

public enum AppRoute: AppRouteModule {
  case featureStartupModule(FeatureStartupRouteModule)
  case featureDashboardModule(FeatureDashboardRouteModule)
  case featureCommonModule(FeatureCommonRouteModule)
  case featureIssuanceModule(FeatureIssuanceRouteModule)
  case featureIssuanceCardModule(FeatureIssuanceRouteModule)
  case featurePresentationModule(FeaturePresentationRouteModule)
  case featureProximityModule(FeatureProximityRouteModule)

  public var info: (key: String, arguments: [String: String]) {
    return switch self {
    case .featureStartupModule(let module):
      module.info
    case .featureDashboardModule(let module):
      module.info
    case .featureCommonModule(let module):
      module.info
    case .featureIssuanceModule(let module):
      module.info
    case .featurePresentationModule(let module):
      module.info
    case .featureProximityModule(let module):
      module.info
    case .featureIssuanceCardModule(let module):
        module.info
    }
  }
}
