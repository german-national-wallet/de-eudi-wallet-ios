/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
@_exported import SwiftUI
@_exported import Combine
@_exported import Copyable

public protocol ViewState {}

@MainActor
open class ViewModel<Router: RouterHost, UiState: ViewState>: ObservableObject {

  public lazy var cancellables = Set<AnyCancellable>()

  @Published public private(set) var viewState: UiState

  public let router: Router

  public init(
    router: Router,
    initialState: UiState
  ) {
    self.router = router
    self.viewState = initialState
  }

  public func setState(_ reducer: (UiState) -> UiState) {
    self.viewState = reducer(viewState)
  }
  
  public func backButtonTapped() {
    router.pop()
  }
  
  public func closeButtonTapped() {
    router.popTo(with: .featureIssuanceModule(.issuanceAddDocument(config: NoConfig())))
  }

  /// Abandons the current flow for the wallet overview. The overview is pushed when it is not on the
  /// stack yet, which is the case while the wallet still holds no documents.
  public func cancelToDashboard() {
    let dashboard = AppRoute.featureDashboardModule(.dashboard)

    if router.isScreenOnBackStack(with: dashboard) {
      router.popTo(with: dashboard)
    } else {
      router.push(with: dashboard)
    }
  }
}
