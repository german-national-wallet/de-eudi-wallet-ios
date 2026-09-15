//
//  IssuanceCancellationInteractor.swift
//  feature-common
//

import logic_core

public protocol IssuanceCancellationInteractor: AnyObject {
  func cancelIssuance(verificationInteractor: IssuanceVerificationInteractor?) async
}

final class IssuanceCancellationInteractorImpl: IssuanceCancellationInteractor {
  private let parInteractor: PARInteractor
  private let pinSessionInteractor: PinSessionInteractor

  init(
    parInteractor: PARInteractor,
    pinSessionInteractor: PinSessionInteractor
  ) {
    self.parInteractor = parInteractor
    self.pinSessionInteractor = pinSessionInteractor
  }

  func cancelIssuance(verificationInteractor: IssuanceVerificationInteractor?) async {
    verificationInteractor?.stop()
    pinSessionInteractor.clear()
    await parInteractor.removeAllPendingDocs()
  }
}
