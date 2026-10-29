//
//  BaseRequestViewModel+Retry.swift.swift
//  feature-presentation
//
import feature_common
import logic_ui

extension BaseRequestViewModel {
  var retryAction: PresentationErrorDialogConfig.RetryAction {
    .init { [weak self] in self?.retryDoWork() }
  }

  func retryDoWork() {
    Task { [weak self] in
      await self?.doWork()
    }
  }
}
