//
//  PresentationErrorHandler.swift
//  feature-presentation
//

import Foundation
import logic_analytics
import logic_api
import logic_business
import logic_core
import logic_resources
import logic_ui

protocol PresentationErrorHandler {
  func handle(
    _ error: Error,
    originator: AppRoute
  ) -> PresentationErrorPresentation

  func handle(
    _ error: Error,
    originator: AppRoute,
    retryAction: PresentationErrorDialogConfig.RetryAction?
  ) -> PresentationErrorPresentation
}

final class PresentationErrorHandlerImpl: PresentationErrorHandler {

  private let classifier: PresentationErrorClassifier
  private let analyticsController: AnalyticsController
  private let walletKitController: WalletKitController
  private let maxInnerErrorDepth = 8

  init(
    classifier: PresentationErrorClassifier,
    analyticsController: AnalyticsController,
    walletKitController: WalletKitController,
  ) {
    self.classifier = classifier
    self.analyticsController = analyticsController
    self.walletKitController = walletKitController
  }

  func handle(_ error: any Error, originator: AppRoute) -> PresentationErrorPresentation {
    handle(error, originator: originator, retryAction: nil)
  }

  func handle(
    _ error: Error,
    originator: AppRoute,
    retryAction: PresentationErrorDialogConfig.RetryAction?
  ) -> PresentationErrorPresentation {
    if let backendError = error as? BackendError, !backendError.errorCode.isEmpty {
      let traceId = endTrace(serverCode: backendError.errorCode, serverTraceId: backendError.traceId, error: error)
      return .dialog(
        PresentationErrorHandlerImpl.rwscaDialog(for: backendError, traceId: traceId, originator: originator)
      )
    }
    let classified = classifier.classify(error)
    let traceId = endTrace(classified: classified)
    return presentation(for: classified, traceId: traceId, originator: originator, retryAction: retryAction)
  }

  // MARK: - Designed states

  private func presentation(
    for classified: ClassifiedPresentationError,
    traceId: String,
    originator: AppRoute,
    retryAction: PresentationErrorDialogConfig.RetryAction?
  ) -> PresentationErrorPresentation {
    switch classified.errorClass {
    case .unclassified:
      return .dialog(PresentationErrorHandlerImpl.genericDialog(traceId: traceId, originator: originator))
    case .relyingPartyRequestInvalid:
      return .dialog(PresentationErrorHandlerImpl.codedDialog(classified: classified, traceId: traceId, originator: originator))
    case .walletInternal:
      return .dialog(PresentationErrorHandlerImpl.genericDialog(
        traceId: traceId,
        originator: originator,
        errorCode: PresentationErrorHandlerImpl.diagnosticLabel(classified)
      ))
    case .networkUnavailable:
      let dismissButton = PresentationErrorDialogConfig.Button(
        title: .globalNoInternetErrorPrimButton,
        action: .popTo(originator)
      )
      let retryButton = retryAction.map { action in
        PresentationErrorDialogConfig.Button(
          title: .globalTryAgainButton,
          action: .retry(action)
        )
      }
      return .dialog(
        .init(
          title: .globalNoInternetErrorTitle,
          titleIcon: Theme.shared.image.warning,
          message: .globalNoInternetErrorParagraph,
          errorCode: nil,
          traceId: traceId,
          primary: retryButton ?? dismissButton,
          secondary: retryButton != nil ? dismissButton : nil
        )
      )
    case .relyingPartyNotTrusted:
      return .notice(PresentationErrorHandlerImpl.notTrustedNotice(originator: originator))
    case .credentialNotAvailable:
      let pidIsMissing = isMissingCredentialPID(classified) ?? !hasIssuedPID()
      if pidIsMissing {
        return .notice(PresentationErrorHandlerImpl.pidMissingNotice(originator))
      }
      return .notice(PresentationErrorHandlerImpl.credentialMissingNotice(originator))
    case .userDeclined, .walletPinBlocked:
      return .dialog(PresentationErrorHandlerImpl.userRejectionDialog(traceId: traceId, originator: originator))
    }
  }

  private func hasIssuedPID() -> Bool {
    !walletKitController.fetchIssuedDocuments(with: [.mDocPid, .sdJwtPid]).isEmpty
  }

  private func missingDocType(_ classified: ClassifiedPresentationError) -> String? {
    var current: Error? = classified.underlying
    var depth = 0
    while let candidate = current as? WalletError, depth < maxInnerErrorDepth {
      if let docType = candidate.context["docType"] { return docType }
      current = candidate.innerError
      depth += 1
    }
    return nil
  }

  private func isMissingCredentialPID(_ classified: ClassifiedPresentationError) -> Bool? {
    guard let docType = missingDocType(classified) else { return nil }
    let pidDocTypes = [DocumentTypeIdentifier.mDocPid.rawValue, DocumentTypeIdentifier.sdJwtPid.rawValue]
    return pidDocTypes.contains(docType)
  }

  private func endTrace(classified: ClassifiedPresentationError) -> String {
    var attributes = [
      AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.failure,
      AnalyticsConstants.TraceAttribute.errorClass: classified.errorClass.rawValue,
      AnalyticsConstants.TraceAttribute.errorOrigin: classified.errorClass.origin.rawValue
    ]
    if let code = classified.diagnosticCode {
      attributes[AnalyticsConstants.TraceAttribute.errorCode] = code
    }
    if let diagnosticCase = classified.diagnosticCase {
      attributes[AnalyticsConstants.TraceAttribute.errorDiagnosticCase] = diagnosticCase
    }
    let activeTraceId = analyticsController.currentTraceID
    let endedTraceId = analyticsController.endTrace(
      finalAttributes: attributes,
      errorDescription: String(describing: classified.underlying)
    )
    return endedTraceId ?? activeTraceId ?? ""
  }

  private func endTrace(serverCode: String, serverTraceId: String, error: Error) -> String {
    var attributes = [
      AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.failure,
      AnalyticsConstants.TraceAttribute.errorCode: serverCode
    ]
    if !serverTraceId.isEmpty {
      attributes[AnalyticsConstants.TraceAttribute.serverTraceID] = serverTraceId
    }
    let activeTraceId = analyticsController.currentTraceID
    let endedTraceId = analyticsController.endTrace(
      finalAttributes: attributes,
      errorDescription: String(describing: error)
    )
    return endedTraceId ?? activeTraceId ?? serverTraceId
  }
}

// MARK: - Helpers

extension PresentationErrorHandlerImpl {

  static func genericDialog(
    traceId: String,
    originator: AppRoute,
    errorCode: String? = nil
  ) -> PresentationErrorDialogConfig {
    .init(
      title: .globalGenericPresentationErrorTitle,
      titleIcon: Theme.shared.image.warning,
      message: .globalGenericPresentationErrorParagraph,
      errorCode: errorCode,
      traceId: traceId,
      primary: .init(title: .globalGenericPresentationErrorPrimButton, action: .popTo(originator)),
      secondary: nil
    )
  }

  static func userRejectionDialog(
    traceId: String,
    originator: AppRoute,
    errorCode: String? = nil
  ) -> PresentationErrorDialogConfig {
    .init(
      title: .globalGenericPresentationErrorTitle,
      titleIcon: Theme.shared.image.infoCircleImage,
      message: .globalGenericPresentationErrorParagraph,
      errorCode: errorCode,
      traceId: traceId,
      primary: .init(title: .globalGenericPresentationErrorPrimButton, action: .popTo(originator)),
      secondary: nil
    )
  }

  static func codedDialog(
    classified: ClassifiedPresentationError,
    traceId: String,
    originator: AppRoute
  ) -> PresentationErrorDialogConfig {
    .init(
      title: .pidPresentationMalformedPresentationTitle,
      titleIcon: Theme.shared.image.warning,
      message: .pidPresentationMalformedPresentationParagraph,
      errorCode: diagnosticLabel(classified),
      traceId: traceId,
      primary: .init(title: .pidPresentationMalformedPresentationPrimButton, action: .popTo(originator)),
      secondary: nil
    )
  }

  static func rwscaDialog(
    for error: BackendError,
    traceId: String,
    originator: AppRoute
  ) -> PresentationErrorDialogConfig {
    switch error.errorCode {
    case RWSCAServerErrorCode.accountUnknown, RWSCAServerErrorCode.accountLocked:
      return .init(
        title: .pidPresentationRwscdAccountUnknownTitle,
        titleIcon: Theme.shared.image.warning,
        message: .pidPresentationRwscdAccountUnknownParagraph,
        errorCode: error.errorCode,
        traceId: traceId,
        primary: .init(title: .pidPresentationRwscdAccountUnknownPrimButton, action: .addDigitalIDAgain),
        secondary: .init(title: .pidPresentationRwscdAccountUnknownSecButton, action: .popTo(originator))
      )
    case RWSCAServerErrorCode.authVerificationFailed:
      return .init(
        title: .pidPresentationRwscdAuthVerificationFailedTitle,
        titleIcon: Theme.shared.image.warning,
        message: .pidPresentationRwscdAuthVerificationFailedParagraph,
        errorCode: error.errorCode,
        traceId: traceId,
        primary: .init(title: .pidPresentationRwscdAuthVerificationFailedPrimButton, action: .popTo(originator)),
        secondary: nil
      )
    default:
      return genericDialog(traceId: traceId, originator: originator, errorCode: error.errorCode)
    }
  }

  static func notTrustedNotice(
    originator: AppRoute,
    supervisoryAuthorityURL: URL? = AppEnvironment.reportIssueUrl
  ) -> PresentationErrorNoticeConfig {
    .init(
      title: .pidPresentationDialogRpUnkownTitle,
      message: .pidPresentationDialogRpUnkownParagraphCertFailed,
      illustration: Theme.shared.image.presentationTrustErrorInfo,
      primary: .init(
        title: .pidPresentationDialogRpUnkownPrimButton,
        trailingIcon: Theme.shared.image.externalLink,
        action: .reportSuspicion(supervisoryAuthorityURL: supervisoryAuthorityURL)
      ),
      secondary: .init(
        title: .pidPresentationDialogRpUnkownSecButton,
        trailingIcon: nil,
        action: .popTo(originator)
      ),
      originator: originator
    )
  }

  static func pidMissingNotice(_ originator: AppRoute) -> PresentationErrorNoticeConfig {
    .init(
      title: .pidPresentationNoIssuedPidTitle,
      message: .pidPresentationNoIssuedPidParagraph,
      illustration: Theme.shared.image.presentationPIDMissingErrorInfo,
      primary: .init(
        title: .pidPresentationNoIssuedPidPrimButton,
        trailingIcon: nil,
        action: .popTo(.featureDashboardModule(.dashboard))
      ),
      secondary: nil,
      originator: originator
    )
  }

  static func credentialMissingNotice(_ originator: AppRoute) -> PresentationErrorNoticeConfig {
    .init(
      title: .eaaPresentationCredentialNotFoundTitle,
      message: .eaaPresentationCredentialNotFoundParagraphCredentalNotAvailable,
      illustration: Theme.shared.image.presentationCredentialMissingErrorInfo,
      primary: .init(
        title: .globalToOverviewButton,
        trailingIcon: nil,
        action: .popTo(.featureDashboardModule(.dashboard))
      ),
      secondary: nil,
      originator: originator
    )
  }

  static func diagnosticLabel(_ classified: ClassifiedPresentationError) -> String? {
    let parts = [classified.diagnosticCode, classified.diagnosticCase].compactMap { $0 }
    return parts.isEmpty ? nil : parts.joined(separator: ".")
  }
}
