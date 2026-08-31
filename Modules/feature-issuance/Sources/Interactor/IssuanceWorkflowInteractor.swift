//
//  IssuanceWorkflowInteractor.swift
//  feature-issuance
//

import Foundation
import AusweisApp2SDKWrapper
import logic_ui
import logic_core
import logic_business

protocol IssuanceWorkflowInteractorDelegate: AnyObject {
  func didRecognizeCardByWorkflowConroller()
  func didNotRecognizeCardByWorkflowConroller()
  func requestPinByWorkflowConroller()
  func didReceiveSuccessByWorkflowConroller(_ url: String)
  func stopIssuanceFlow(with error: Error?)
  func didRequestCAN()
  func enterCANErrorReceived(error: Error?, cardStatusInfo: CardStatusInfo?)
  func invalidPinErrorReceived(error: Error?, cardStatusInfo: CardStatusInfo?)
  func setNewPin()
  func onChangePinCompleted(success: Bool)
  func canEnteredCorrectly()
  func tcTokenExpired()
  func onBadState(error: String)
}

protocol IssuanceWorkflowInteractor: AnyObject {
  var delegate: IssuanceWorkflowInteractorDelegate? { get set }
  func start(tokenURL: String, pin: String?)
  func startPinChangeFlow(tokenURL: URL, transportPin: String)
  func stop()
  func setPin(_ pin: String)
  func assignNewPin(_ pin: String)
  func setCAN(_ can: String)
  func changeWorkFlowType(_ type: EidFlowType)
}

public enum IssuanceWorkflowError: Error {
  case getTcTokenNetworkError
  case userCancelled
  case authenticationStartFailed
  case internalError
  case invalidCAN
  case invalidPin
}

final class IssuanceWorkflowInteractorImpl: IssuanceWorkflowInteractor {
  private enum ResultKey {
    static let major = "ResultMajor"
    static let minor = "ResultMinor"
    static let message = "ResultMessage"
  }
  
  private enum ResultMajor {
    static let ok = "ok"
  }
  
  private enum ResultSpecialError {
    static let userCancelled = "User_Cancelled"
    static let tceFailed = "trustedChannelEstablishmentFailed"
  }
  
  private var tokenURL: URL?
  private let controller = AA2SDKWrapper.workflowController
  private let logger: Logging?
  private var canRequested = false
  private var isPinIncorrect = false
  private var enteredPin: String?
  private var workflowType: EidFlowType = .authentication
  private var areCallbacksRegistered = false
  
  var delegate: IssuanceWorkflowInteractorDelegate?
  
  init(logger: Logging?) {
    self.logger = logger
  }
  
  func startPinChangeFlow(tokenURL: URL, transportPin: String) {
    registerCallbacksIfNeeded()
    self.tokenURL = tokenURL
    self.enteredPin = transportPin
    if !controller.isStarted {
      controller.start()
    } else {
      controller.stop()
    }
  }
  
  func start(tokenURL: String, pin: String?) {
    registerCallbacksIfNeeded()
    enteredPin = pin
    self.tokenURL = URL(string: tokenURL)!
   
    if !controller.isStarted {
      controller.start()
    } else {
      if let pin {
        setPin(pin)
      }
    }
  }
  
  func stop() {
    if controller.isStarted {
      controller.stop()
    }
    unregisterCallbacksIfNeeded()
    controller.cancel()
    tokenURL = nil
  }
  
  func setPin(_ pin: String) {
    if AppEnvironment.isUITesting || AppState.shared.useSimulatedEIDCard {
      controller.setPin(nil)
    } else {
      controller.setPin(pin)
    }
  }
  
  func setCAN(_ can: String) {
    controller.setCan(can)
  }
  
  func changeWorkFlowType(_ type: EidFlowType) {
    workflowType = type
  }
  
  func assignNewPin(_ newPin: String) {
    controller.setNewPin(newPin)
  }

  private func registerCallbacksIfNeeded() {
    guard !areCallbacksRegistered else {
      return
    }
    controller.registerCallbacks(self)
    areCallbacksRegistered = true
  }

  private func unregisterCallbacksIfNeeded() {
    guard areCallbacksRegistered else {
      return
    }
    controller.unregisterCallbacks(self)
    areCallbacksRegistered = false
  }
}

extension IssuanceWorkflowInteractorImpl: WorkflowCallbacks {
  func onAccessRights(error: String?, accessRights: AusweisApp2SDKWrapper.AccessRights?) {
    controller.accept()
    if let error {
      logger?.e("IDGO -> 3. onAccessRights called, error: \(error)")
    }
    
    guard let accessRights else {
      return
    }
    
    guard accessRights.requiredRights == accessRights.effectiveRights else {
      controller.setAccessRights([])
      return
    }
    
    do {
      _ = try accessRights.requiredRights.map(EIDAttribute.init)
      
    } catch EIDInteractionError.unexpectedReadAttribute(_) {
      logger?.e("IDGO -> 3. onAccessRights unexpected attribute")
      return
    } catch {
      logger?.e("IDGO -> 3. onAccessRights Failed to map attributr")
      return
    }
  }
  
  private func getURLComponents(from url: URL?) -> URLComponents? {
    guard let refreshURLOrCommunicationErrorAddress = url,
          let refreshURLOrCommunicationErrorAddressComponents = URLComponents(
            url: refreshURLOrCommunicationErrorAddress,
            resolvingAgainstBaseURL: false
          ) else {
      return nil
    }
    return refreshURLOrCommunicationErrorAddressComponents
  }
  
  private func authenticationCompletedWithSuccess(url: URL?) {
    guard let refreshUrlComponent = getURLComponents(from: url) else {
      return
    }
    var queryItems = refreshUrlComponent.queryItems ?? []
    queryItems.append(URLQueryItem(name: ResultKey.major, value: ResultMajor.ok))
    var refreshURLComponents = refreshUrlComponent
    refreshURLComponents.queryItems = refreshURLComponents.queryItems?.filter { $0.name == "issuer_state" }
    
    if let modifiedURL = refreshURLComponents.url?.absoluteString {
      Task {
        await delegate?.didReceiveSuccessByWorkflowConroller(modifiedURL)
      }
    } else {
      logger?.e("Error: Could not generate modified URL")
    }
  }
  
  func onAuthenticationCompleted(authResult: AusweisApp2SDKWrapper.AuthResult) {
    guard let resultData = authResult.result,
          let resultMajorSuffix = resultData.major.split(separator: "#").last else {
      return
    }
    let resultMajor = String(resultMajorSuffix)
    
    if resultMajor == ResultMajor.ok {
      authenticationCompletedWithSuccess(url: authResult.url)
      
    } else if resultData.reason == ResultSpecialError.userCancelled {
      logger?.d("IDGO -> onAuthenticationCompleted: user cancelled")
      controller.stop()
      delegate?.stopIssuanceFlow(with: IssuanceWorkflowError.userCancelled)
    } else {
      var resultMinor: String?
      var urlComponent = getURLComponents(from: authResult.url)
      var queryItems = urlComponent?.queryItems ?? []
      
      if let resultMinorSuffix = resultData.minor?.split(separator: "#").last {
        resultMinor = String(resultMinorSuffix)
        queryItems.append(URLQueryItem(name: ResultKey.minor, value: resultMinor))
      }
      
      if resultMinor == ResultSpecialError.tceFailed, let resultMessage = resultData.reason {
        queryItems.append(URLQueryItem(name: ResultKey.message, value: resultMessage))
        delegate?.tcTokenExpired()
      }
      urlComponent?.queryItems = queryItems
      
      logger?.e("IDGO -> onAuthenticationCompleted error minor: \(String(describing: resultMinor))")
      if let resultMinor = resultMinor, resultMinor == "cancellationByUser" {
        stop()
        delegate?.stopIssuanceFlow(with: IssuanceWorkflowError.userCancelled)
      } else {
        //  delegate?.stopIssuanceFlow(with: nil)
      }
    }
    stop()
  }
  
  func onAuthenticationStarted() {
    
  }
  
  func onAuthenticationStartFailed(error: String) {
    logger?.e("IDGO -> onAuthenticationStartFailed: Auth Failed")
    delegate?.stopIssuanceFlow(with: IssuanceWorkflowError.authenticationStartFailed)
  }
  
  func onBadState(error: String) {
    logger?.e("IDGO -> onBadState: \(error)")
    delegate?.onBadState(error: error)
  }
  
  func onCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
    
  }
  
  func onChangePinCompleted(changePinResult: AusweisApp2SDKWrapper.ChangePinResult) {
    if controller.isStarted {
      controller.stop()
    }
    unregisterCallbacksIfNeeded()
    controller.cancel()
    
    tokenURL = nil
    canRequested = false
    isPinIncorrect = false
    enteredPin = nil
    workflowType = .authentication
    
    delegate?.onChangePinCompleted(success: changePinResult.success)
  }
  
  func onChangePinStarted() {
    logger?.d("on change pin started")

  }
  
  func onEnterCan(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
    logger?.e("IDGO -> onEnterCan: Please enter CAN (\(String(describing: error))")

    controller.interrupt()
    
    let cardStatusInfo = CardStatusInfo(deactivated: reader.card?.deactivated, inoperative: reader.card?.inoperative, pinRetryCounter: reader.card?.pinRetryCounter)
    
    if !canRequested {
      canRequested.toggle()
      delegate?.enterCANErrorReceived(error: nil, cardStatusInfo: cardStatusInfo)
    } else {
      delegate?.enterCANErrorReceived(error: IssuanceWorkflowError.invalidCAN, cardStatusInfo: cardStatusInfo)
    }
  }
  
  func onEnterNewPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
    logger?.e("IDGO -> onEnterNewPin:")
    controller.interrupt()
    delegate?.setNewPin()
  }
  
  func onEnterPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
   
    if canRequested {
      canRequested = false
      controller.interrupt()
      delegate?.canEnteredCorrectly()
      return
    }
    
    switch workflowType {
    case .setEidPin:
      controller.setPin(enteredPin)
    case .authentication:
      if !isPinIncorrect {
       isPinIncorrect = true
        delegate?.requestPinByWorkflowConroller()
      } else if isPinIncorrect {
        controller.interrupt()
        let cardStatusInfo = CardStatusInfo(deactivated: reader.card?.deactivated, inoperative: reader.card?.inoperative, pinRetryCounter: reader.card?.pinRetryCounter)
        delegate?.invalidPinErrorReceived(error: IssuanceWorkflowError.invalidPin, cardStatusInfo: cardStatusInfo)
      }
    case .confirmNewPin:
      break
    }
  }
  
  func onEnterPuk(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
    logger?.e("IDGO -> onEnterPuk: \(String(describing: error))")
    controller.setPuk("1133557799")
  }
  
  func onInfo(versionInfo: AusweisApp2SDKWrapper.VersionInfo) {
    logger?.d("IDGO -> onInfo: \(versionInfo)")
  }
  
  func onInsertCard(error: String?) {
    logger?.e("IDGO -> 4. onInsertCard")
    if AppEnvironment.isUITesting || AppState.shared.useSimulatedEIDCard {
      controller.setCard(name: AppEnvironment.ausweiseSdkSimulatorIdentifier)
    }
  }
  
  func onInternalError(error: String) {
    logger?.e("IDGO -> onInternalError: \(error)")
    delegate?.stopIssuanceFlow(with: IssuanceWorkflowError.internalError)
  }
  
  func onPause(cause: AusweisApp2SDKWrapper.Cause) {
    logger?.d("IDGO -> onPause: \(cause)")
  }
  
  func onReader(reader: AusweisApp2SDKWrapper.Reader?) {
    guard let reader,
          let card = reader.card else {
      logger?.e("IDGO -> onReader: reader is nil")
      return
    }
    
    if card.deactivated == true {
      self.delegate?.didNotRecognizeCardByWorkflowConroller()
    } else {
      self.delegate?.didRecognizeCardByWorkflowConroller()
    }
  }
  
  func onReaderList(readers: [AusweisApp2SDKWrapper.Reader]?) {
    logger?.e("IDGO -> onReaderList: \(String(describing: readers))")
  }
  
  func onStarted() {
    if workflowType == .setEidPin {
      controller.startChangePin()
    } else {
      guard let tokenURL, !tokenURL.absoluteString.isEmpty else {
        logger?.e("IssuanceWorkflowInteractor :: tokenURL is empty")
        return
      }
      controller.startAuthentication(
        withTcTokenUrl: tokenURL,
        withDeveloperMode: true,
        withUserInfoMessages: nil,
        withStatusMsgEnabled: true
      )
    }
  }
  
  func onStatus(workflowProgress: AusweisApp2SDKWrapper.WorkflowProgress) {
    
  }
  
  func onWrapperError(error: AusweisApp2SDKWrapper.WrapperError) {
    
  }
}
