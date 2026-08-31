//
//  IssuanceVerificationInteractor.swift
//  feature-issuance
//

import Foundation
import logic_ui

final class IssuanceVerificationInteractorImpl: IssuanceVerificationInteractor {
  public weak var delegate: IssuanceVerificationInteractorDelegate?
  private var issuanceWorkflowInteractor: IssuanceWorkflowInteractor
  private var tokenURL: URL?
  
  init(
    issuenceWorkflowInteractor: IssuanceWorkflowInteractor
  ) {
    self.issuanceWorkflowInteractor = issuenceWorkflowInteractor
    self.issuanceWorkflowInteractor.delegate = self
  }
  
  func start(tokenURL: URL, pin: String?) {
    self.tokenURL = tokenURL
    issuanceWorkflowInteractor.changeWorkFlowType(.authentication)
    issuanceWorkflowInteractor.start(tokenURL: tokenURL.absoluteString, pin: pin)
  }
  
  func startChangePinFlow(tokenURL: URL, transportPin: String) {
    issuanceWorkflowInteractor.changeWorkFlowType(.setEidPin)
    issuanceWorkflowInteractor.startPinChangeFlow(tokenURL: tokenURL, transportPin: transportPin)
  }
  
  func stop() {
    issuanceWorkflowInteractor.stop()
  }
  
  func setPin(_ pin: String) {
    issuanceWorkflowInteractor.setPin(pin)
  }
  
  func setCAN(_ can: String) {
    issuanceWorkflowInteractor.setCAN(can)
  }
  
  func setDelegate(_ delegate: any logic_ui.IssuanceVerificationInteractorDelegate) {
    self.delegate = delegate
  }
  
  func assignNewPin(_ pin: String) {
    issuanceWorkflowInteractor.assignNewPin(pin)
  }

}

extension IssuanceVerificationInteractorImpl: IssuanceWorkflowInteractorDelegate {
  func tcTokenExpired() {
    delegate?.tcTokenExpired()
  }  
  func canEnteredCorrectly() {
    delegate?.canEnteredCorrectly()
  }
  func didRecognizeCardByWorkflowConroller() {
    delegate?.didRecognizeCard()
  }
  func didNotRecognizeCardByWorkflowConroller() {
    delegate?.didNotRecognizeCard()
  }
  func requestPinByWorkflowConroller() {
    delegate?.requestPin()
  }
  func didReceiveSuccessByWorkflowConroller(_ url: String) {
    delegate?.didSuccess(result: url)
  }
  func stopIssuanceFlow(with error: Error?) {
    delegate?.stopIssuanceFlow(with: error)
  }
  func didRequestCAN() {
    delegate?.didRequestCAN()
  }
  func enterCANErrorReceived(error: Error?, cardStatusInfo: CardStatusInfo?) {
    delegate?.invalidCANEntered(error: error, cardStatusInfo: cardStatusInfo)
  }
  func invalidPinErrorReceived(error: Error?, cardStatusInfo: CardStatusInfo?) {
    delegate?.invalidPinErrorReceived(error: error, cardStatusInfo: cardStatusInfo)
  }
  func setNewPin() {
    delegate?.setNewPin()
  }
  func onChangePinCompleted(success: Bool) {
    delegate?.onChangePinCompleted(success: success)
  }
  func onBadState(error: String) {
    delegate?.onBadState(error: error)
  }
}
