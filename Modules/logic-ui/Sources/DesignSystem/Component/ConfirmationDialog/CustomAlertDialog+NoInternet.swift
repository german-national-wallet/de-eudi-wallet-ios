//
//  CustomAlertDialog+NoInternet.swift
//  logic-ui
//

import SwiftUI
import logic_resources

extension CustomAlertDialogConfig {
  static func noInternetButtons(
    onRetry: @escaping () -> Void,
    onCancel: @escaping () -> Void
  ) -> [CustomAlertDialogConfig] {
    [
      CustomAlertDialogConfig(title: .globalTryAgainButton, role: .primary, action: onRetry),
      CustomAlertDialogConfig(title: .globalCloseButton, role: .secondary, isCancel: true, action: onCancel)
    ]
  }
}

public extension View {
  func noInternetDialog(
    isPresented: Binding<Bool>,
    onRetry: @escaping () -> Void,
    onCancel: @escaping () -> Void = {}
  ) -> some View {
    alertDialog(
      isPresented: isPresented,
      icon: Theme.shared.image.warning,
      iconColor: DSColor.error,
      title: .globalNoInternetErrorTitle,
      subtitle: .globalNoInternetErrorParagraph,
      buttons: CustomAlertDialogConfig.noInternetButtons(onRetry: onRetry, onCancel: onCancel),
      dismissOnBackgroundTap: false,
      presentation: .modal
    )
  }
}

#if DEBUG
#Preview("No internet") {
  CustomFonts().loadFonts()
  return CustomAlertDialog(
    icon: Theme.shared.image.warning,
    iconColor: DSColor.error,
    title: LocalizableStringKey.globalNoInternetErrorTitle.toString,
    subtitle: LocalizableStringKey.globalNoInternetErrorParagraph.toString,
    buttons: CustomAlertDialogConfig.noInternetButtons(onRetry: {}, onCancel: {})
  )
}
#endif
