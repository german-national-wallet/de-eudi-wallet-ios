//
//  ActivityDetailViewModel.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import UIKit
import logic_ui
import logic_business

@Copyable
struct ActivityDetailViewState: ViewState {
  let activityId: String
  let detail: ActivityDetailUIModel?
  let isLoading: Bool
  let isDeleteConfirmationPresented: Bool
}

final class ActivityDetailViewModel<Router: RouterHost>: ViewModel<Router, ActivityDetailViewState> {

  private let interactor: ActivitiesInteractor
  private let logger: Logging?

  init(
    router: Router,
    interactor: ActivitiesInteractor,
    activityId: String,
    logger: Logging? = nil
  ) {
    self.interactor = interactor
    self.logger = logger
    super.init(
      router: router,
      initialState: .init(activityId: activityId, detail: nil, isLoading: true, isDeleteConfirmationPresented: false)
    )
  }

  func onAppear() async {
    switch await interactor.fetchActivity(with: viewState.activityId) {
    case .success(let detail):
      setState { $0.copy(detail: detail, isLoading: false) }
    case .failure(let error):
      logger?.e("Activities: failed to load an activity: \(error.localizedDescription)")
      setState { $0.copy(isLoading: false) }
    }
  }

  func onHelpTapped() {
    // Intentionally empty: the app has no help destination yet
  }

  func onDeleteRequested() {
    setState { $0.copy(isDeleteConfirmationPresented: true) }
  }

  func onDeleteDismissed() {
    setState { $0.copy(isDeleteConfirmationPresented: false) }
  }

  func onDeleteConfirmed() async {
    setState { $0.copy(isDeleteConfirmationPresented: false) }
    do {
      try await interactor.deleteActivity(with: viewState.activityId)
      backButtonTapped()
    } catch {
      logger?.e("Activities: failed to delete an activity: \(error.localizedDescription)")
    }
  }

  func onLinkSelected(_ link: ActivityServiceLinkUIModel) {
    guard let url = link.url else {
      logger?.d("Activities: ignored a \(link.kind) link that can't be opened")
      return
    }
    UIApplication.shared.open(url)
  }
}
