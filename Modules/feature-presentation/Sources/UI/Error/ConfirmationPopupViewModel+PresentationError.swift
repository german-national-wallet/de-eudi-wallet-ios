//
//  ConfirmationPopupViewModel+PresentationError.swift
//  feature-presentation
//

import feature_common
import logic_resources

extension ConfirmationPopupViewModel {

  convenience init(
    presentationError dialog: PresentationErrorDialogConfig,
    onAction: @escaping (PresentationErrorDialogConfig.Action) -> Void
  ) {
    self.init()
    configure(with: dialog, onAction: onAction)
  }

  func configure(
    with dialog: PresentationErrorDialogConfig,
    onAction: @escaping (PresentationErrorDialogConfig.Action) -> Void
  ) {
    configure(
      title: dialog.title.toString,
      detail: dialog.message.toString,
      errorCode: dialog.errorCode ?? "",
      traceId: dialog.traceId,
      titleIcon: dialog.titleIcon ?? Theme.shared.image.errorIndicator,
      primaryButtontitle: dialog.primary.title.toString,
      secondaryButtontitle: dialog.secondary?.title.toString,
      primaryAction: { onAction(dialog.primary.action) },
      secondaryAction: dialog.secondary.map { secondary in { onAction(secondary.action) } }
    )
  }
}
