//
//  ConfirmationPopupViewModel.swift
//  feature-common
//

import SwiftUI
import Combine
import logic_ui
import logic_api
import logic_resources

public final class ConfirmationPopupViewModel: ObservableObject {
  @Published public var isVisible: Bool = false
  @Published public var title: String = ""
  @Published public var detail: String = ""
  public var errorCode: String = ""
  public var traceId: String = ""
  @Published public var isTraceIdCopied: Bool = false

  var confirmButtonBackgroundColor: Color = DSColor.primary
  var infoIcon: Image?
  var titleIcon: Image?
  var primaryButtontitle: String?
  var secondaryButtontitle: String?
  public var primaryAction: (() -> Void)?
  public var secondaryAction: (() -> Void)?

  public init() {}

  public func configure(
    title: String,
    detail: String,
    errorCode: String = "",
    traceId: String = "",
    infoIcon: Image? = nil,
    titleIcon: Image? = nil,
    confirmButtonBackgroundColor: Color = DSColor.primary,
    primaryButtontitle: String? = nil,
    secondaryButtontitle: String? = nil,
    primaryAction: (() -> Void)?,
    secondaryAction: (() -> Void)?
  ) {
    self.title = title
    self.detail = detail
    self.errorCode = errorCode
    self.traceId = traceId
    self.infoIcon = infoIcon
    self.titleIcon = titleIcon
    self.confirmButtonBackgroundColor = confirmButtonBackgroundColor
    self.primaryAction = primaryAction
    self.secondaryAction = secondaryAction
    self.isVisible = true
    self.isTraceIdCopied = false
    self.primaryButtontitle = primaryButtontitle
    self.secondaryButtontitle = secondaryButtontitle
  }

  public func onConfirm() {
    primaryAction?()
    isVisible = false
  }

  public func onCancel() {
    secondaryAction?()
    isVisible = false
  }
  
  public func copyTraceId() {
    UIPasteboard.general.string = traceId
    isTraceIdCopied = true
    
    // Reset the copied state after 2 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      self.isTraceIdCopied = false
    }
  }
  
  /// The single way to present a WPB / MDVM / RWSCA failure.
  public func configure(
    backendError: BackendError,
    analyticsTraceId: String = "",
    primaryAction: @escaping () -> Void
  ) {
    let content = backendError.errorContent
    configure(
      title: content.title.toString,
      detail: content.paragraph.toString,
      errorCode: backendError.errorCode,
      traceId: backendError.traceId.isEmpty ? analyticsTraceId : backendError.traceId,
      titleIcon: Theme.shared.image.errorIndicator,
      primaryButtontitle: content.primaryButtonTitle?.toString
        ?? LocalizableStringKey.globalErrorPrimaryButtonTitle.toString,
      primaryAction: primaryAction,
      secondaryAction: nil
    )
  }

  public func configureDefaultError(traceId: String = "", primaryAction: @escaping () -> Void ) {
    configure(
      title: LocalizableStringKey.globalErrorTitle.toString,
      detail: LocalizableStringKey.globalErrorParagraph.toString,
      errorCode: "",
      traceId: traceId,
      titleIcon: Theme.shared.image.errorIndicator,
      primaryButtontitle: LocalizableStringKey.globalErrorPrimaryButtonTitle.toString,
      primaryAction: primaryAction,
      secondaryAction: nil
    )
  }

}
