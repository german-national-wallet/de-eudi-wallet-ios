//
//  PresentationErrorFixtures.swift
//  feature-presentation
//

import logic_ui
import logic_resources
@testable import feature_presentation

/// Config fixtures returned by the `MockPresentationErrorHandler` stubs in the view model tests.
extension PresentationErrorDialogConfig {
  static func fixture(
    traceId: String = "trace-id",
    primaryAction: Action = .popTo(.featureDashboardModule(.dashboard))
  ) -> PresentationErrorDialogConfig {
    PresentationErrorDialogConfig(
      title: .globalGenericPresentationErrorTitle,
      message: .globalGenericPresentationErrorParagraph,
      errorCode: nil,
      traceId: traceId,
      primary: .init(title: .globalGenericPresentationErrorPrimButton, action: primaryAction),
      secondary: nil
    )
  }
}

extension PresentationErrorNoticeConfig {
  static func fixture(originator: AppRoute = .featureDashboardModule(.dashboard)) -> PresentationErrorNoticeConfig {
    PresentationErrorNoticeConfig(
      title: .pidPresentationNoIssuedPidTitle,
      message: .pidPresentationNoIssuedPidParagraph,
      illustration: nil,
      primary: .init(title: .pidPresentationNoIssuedPidPrimButton, trailingIcon: nil, action: .popTo(originator)),
      secondary: nil,
      originator: originator
    )
  }
}
