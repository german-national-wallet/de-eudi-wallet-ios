//
//  CancelConfirmationDialog.swift
//  logic-ui
//

import SwiftUI
import logic_resources

/// Copy for the "really cancel?" dialog that guards a header close button.
///
/// The wording differs per flow — PID issuance warns that entered data is lost,
/// EAA issuance that the credential will not be added — so the copy is passed in
/// rather than baked into the modifier.
public struct CancelConfirmationConfig {
  public let title: LocalizableStringKey
  public let message: LocalizableStringKey
  public let confirmTitle: LocalizableStringKey
  public let dismissTitle: LocalizableStringKey

  public init(
    title: LocalizableStringKey,
    message: LocalizableStringKey,
    confirmTitle: LocalizableStringKey,
    dismissTitle: LocalizableStringKey
  ) {
    self.title = title
    self.message = message
    self.confirmTitle = confirmTitle
    self.dismissTitle = dismissTitle
  }

  public static let pidIssuance = CancelConfirmationConfig(
    title: .pidIssuanceDialogCancelTitle,
    message: .pidIssuanceDialogCancelSubTitle,
    confirmTitle: .pidIssuanceDialogCancelPrimButton,
    dismissTitle: .pidIssuanceDialogCancelSecButton
  )

  public static let eaaIssuance = CancelConfirmationConfig(
    title: .eaaIssuanceDialogCancelTitle,
    message: .eaaIssuanceDialogCancelSubTitle,
    confirmTitle: .eaaIssuanceDialogCancelPrimButton,
    dismissTitle: .eaaIssuanceDialogCancelSecButton
  )
}

public extension View {

  /// Guards a destructive close button behind a confirmation dialog.
  ///
  /// Apply this at screen level, never inside `HeaderContentView`: the dialog
  /// dims and centres itself over whatever it is attached to, so attaching it to
  /// the header would clip both to that 32pt row. The header only sets the flag,
  /// which is why the close action moves here from `onClose`.
  func cancelConfirmationDialog(
    isPresented: Binding<Bool>,
    config: CancelConfirmationConfig = .pidIssuance,
    onConfirm: @escaping () -> Void
  ) -> some View {
    centerDialog(
      isPresented: isPresented,
      icon: Theme.shared.image.infoCircleImage,
      title: config.title,
      subtitle: config.message,
      buttons: [
        .init(title: config.confirmTitle, role: .destructive, action: onConfirm),
        .init(title: config.dismissTitle, role: .secondary, action: {})
      ]
    )
  }
}
