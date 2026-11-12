//
//  NoInternetDialogState.swift
//  logic-ui
//

import SwiftUI

public struct NoInternetDialogState {
  public var isPresented = false
  private var actions = Actions()

  public init() {}

  public mutating func present(
    retry: @escaping () -> Void,
    cancel: @escaping () -> Void
  ) {
    actions = Actions(retry: retry, cancel: cancel)
    isPresented = true
  }

  public func retry() {
    actions.run(\.retry)
  }

  public func cancel() {
    actions.run(\.cancel)
  }
}

// The actions capture the step's inputs (for example an entered PIN), so they are dropped after one runs.
private final class Actions {
  var retry: (() -> Void)?
  var cancel: (() -> Void)?

  init(retry: (() -> Void)? = nil, cancel: (() -> Void)? = nil) {
    self.retry = retry
    self.cancel = cancel
  }

  func run(_ action: KeyPath<Actions, (() -> Void)?>) {
    let pending = self[keyPath: action]
    retry = nil
    cancel = nil
    pending?()
  }
}

public extension View {
  func noInternetDialog(_ state: Binding<NoInternetDialogState>) -> some View {
    noInternetDialog(
      isPresented: state.isPresented,
      onRetry: { state.wrappedValue.retry() },
      onCancel: { state.wrappedValue.cancel() }
    )
  }
}
