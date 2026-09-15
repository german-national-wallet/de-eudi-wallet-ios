//
//  RedirectConfirmationDialog.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public extension View {
  func redirectConfirmationDialog(
    isPresented: Binding<Bool>,
    url: URL?,
    onRedirect: @escaping (URL) -> Void
  ) -> some View {
    centerDialog(
      isPresented: isPresented,
      icon: Theme.shared.image.infoCircleImage,
      title: .redirectInfoTitle,
      subtitle: .custom(
        LocalizableStringKey.redirectInfoTarget([url?.host ?? ""]).toString
        + "\n\n"
        + LocalizableStringKey.redirectInfoDisclaimer.toString
      ),
      buttons: [
        CustomAlertDialogConfig(
          title: .redirectInfoPrimaryButton,
          role: .primary
        ) {
          guard let url else { return }
          onRedirect(url)
        },
        CustomAlertDialogConfig(
          title: .redirectInfoSecondaryButton,
          role: .secondary
        ) {}
      ]
    )
  }
}
