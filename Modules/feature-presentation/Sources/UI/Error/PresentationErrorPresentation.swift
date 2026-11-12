//
//  PresentationErrorPresentation.swift
//  feature-presentation
//

enum PresentationErrorPresentation {
  case dialog(PresentationErrorDialogConfig)
  case notice(PresentationErrorNoticeConfig)
  case noInternet(retry: PresentationErrorDialogConfig.RetryAction?)
}
