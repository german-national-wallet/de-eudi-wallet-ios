//
//  ConfirmationPopupViewModel+TransportFailure.swift
//  feature-common
//

import SwiftUI
import logic_api
import logic_business
import logic_core
import logic_resources
import logic_ui

public extension ErrorDialogIcon {
  var image: Image? {
    switch self {
    case .error: Theme.shared.image.errorIndicator
    case .info: Theme.shared.image.infoCircleImage
    case .warning: Theme.shared.image.warning
    case .none: nil
    }
  }
}

public extension ConfirmationPopupViewModel {

  func configure(
    transportFailure: TransportFailure,
    retry: (() -> Void)? = nil,
    dismiss: @escaping () -> Void,
    close: (() -> Void)? = nil
  ) {
    let content = content(for: transportFailure)
    let isRateLimited = transportFailure.kind == .rateLimited
    let canRetry = retry != nil && !isRateLimited
    let acknowledge = isRateLimited ? (close ?? dismiss) : dismiss
    configure(
      title: content.title.toString,
      detail: content.paragraph.toString,
      titleIcon: content.icon.image,
      primaryButtontitle: canRetry
        ? content.primaryButtonTitle?.toString
        : LocalizableStringKey.globalNoInternetErrorPrimButton.toString,
      primaryAction: canRetry ? retry : acknowledge,
      secondaryAction: nil
    )
  }

  func content(for failure: TransportFailure) -> RemoteErrorResponseStruct {
    switch failure.kind {
    case .rateLimited:
      return RemoteErrorResponseStruct(
        title: .globalTimeoutTooManyRequestsTitle,
        paragraph: rateLimitParagraph(retryAfter: failure.retryAfter),
        primaryButtonTitle: .globalNoInternetErrorPrimButton,
        icon: .warning
      )
    case .timeout, .unreachable:
      return RemoteErrorResponseStruct(
        title: .globalTimeoutSlowInternetErrorTitle,
        paragraph: .globalTimeoutSlowInternetErrorParagraph,
        primaryButtonTitle: .globalTimeoutSlowInternetErrorPrimButton,
        icon: .warning
      )
    }
  }

  func rateLimitParagraph(retryAfter: TimeInterval?) -> LocalizableStringKey {
    guard let retryAfter, let duration = Self.retryDuration(retryAfter) else {
      return .globalErrorParagraph
    }
    return .globalTimeoutTooManyRequestsParagraph([duration])
  }

  static var retryDurationLocale: Locale {
    let languageCode = Locale.current.systemLanguageCode
      .flatMap { Bundle.assetsBundle.localizations.contains($0) ? $0 : nil } ?? "en"
    return Locale(identifier: languageCode)
  }

  static func retryDuration(
    _ retryAfter: TimeInterval,
    locale: Locale = ConfirmationPopupViewModel.retryDurationLocale
  ) -> String? {
    var calendar = Calendar.current
    calendar.locale = locale
    let formatter = DateComponentsFormatter()
    formatter.calendar = calendar
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.hour, .minute]
    let minutes = max(1, Int((retryAfter / 60).rounded(.up)))
    return formatter.string(from: TimeInterval(minutes * 60))
  }
}
