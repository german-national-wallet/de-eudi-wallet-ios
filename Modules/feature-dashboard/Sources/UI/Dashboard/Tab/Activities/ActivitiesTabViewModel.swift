//
//  ActivitiesTabViewModel.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import logic_ui
import logic_business

@Copyable
struct ActivitiesTabViewState: ViewState {
  let sections: [ActivitySectionUIModel]
  let isLoading: Bool
  let isDeleteAllConfirmationPresented: Bool
}

final class ActivitiesTabViewModel<Router: RouterHost>: ViewModel<Router, ActivitiesTabViewState> {

  private let interactor: ActivitiesInteractor
  private let logger: Logging?

  init(
    router: Router,
    interactor: ActivitiesInteractor,
    logger: Logging? = nil
  ) {
    self.interactor = interactor
    self.logger = logger
    super.init(router: router, initialState: .init(sections: [], isLoading: true, isDeleteAllConfirmationPresented: false))
  }

  func onAppear() async {
    switch await interactor.fetchActivities() {
    case .success(let sections):
      setState { $0.copy(sections: sections, isLoading: false) }
    case .failure(let error):
      logger?.e("Activities: failed to load the activity log: \(error.localizedDescription)")
      setState { $0.copy(sections: [], isLoading: false) }
    }
  }

  func onDeleteAllRequested() {
    setState { $0.copy(isDeleteAllConfirmationPresented: true) }
  }

  func onDeleteAllDismissed() {
    setState { $0.copy(isDeleteAllConfirmationPresented: false) }
  }

  func onDeleteAllConfirmed() async {
    setState { $0.copy(isDeleteAllConfirmationPresented: false) }
    do {
      try await interactor.deleteAllActivities()
    } catch {
      logger?.e("Activities: failed to delete the activity log: \(error.localizedDescription)")
    }
    await onAppear()
  }

  func onHelpTapped() {
    // Intentionally empty: the app has no help destination yet
  }

  func onHowToUseTapped() {
    // Intentionally empty: the how-to page doesn't exist yet
  }

  func onActivitySelected(_ item: ActivityListItemUIModel) {
    router.push(with: .featureDashboardModule(.activityDetail(id: item.id)))
  }
}
