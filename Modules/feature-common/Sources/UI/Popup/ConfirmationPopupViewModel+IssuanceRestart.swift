//
//  ConfirmationPopupViewModel+IssuanceRestart.swift
//  feature-common
//

import logic_api
import logic_resources
import logic_ui

public extension ConfirmationPopupViewModel {

  /// The issuance cannot be continued (expired PAR, lost PIN session, transport failure): the user starts
  /// adding the ID again or cancels the process.
  func configureIssuanceRestart(startAgain: @escaping () -> Void, cancel: @escaping () -> Void) {
    configure(
      title: LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredTitle.toString,
      detail: LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredParagraph.toString,
      titleIcon: ErrorDialogIcon.warning.image,
      primaryButtontitle: LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredPrimButton.toString,
      secondaryButtontitle: LocalizableStringKey.pidIssuanceTimeoutParRequestExpiredSecButton.toString,
      primaryAction: startAgain,
      secondaryAction: cancel
    )
  }
}
