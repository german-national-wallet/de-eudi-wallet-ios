//
//  PresentationCancellation.swift
//  feature-presentation
//
//  Created by Ameen Qadri on 12.10.26.
//

import UIKit
import logic_ui
import logic_analytics

@MainActor
struct PresentationCancellation<Router: RouterHost> {

  let router: Router
  let interactor: PresentationInteractor
  let analyticsController: AnalyticsController
  var openURL: @MainActor (URL) -> Void = { UIApplication.shared.open($0) }

  func cancel() {
    analyticsController.endTrace(
      finalAttributes: [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.declined],
      errorDescription: nil
    )
    Task { [interactor, openURL] in
      if let redirectURL = await interactor.onRejectRequest() {
        openURL(redirectURL)
      }
    }
    let dashboard = AppRoute.featureDashboardModule(.dashboard)
    if router.isScreenOnBackStack(with: dashboard) {
      router.popTo(with: dashboard)
    } else {
      router.push(with: dashboard)
    }
  }
}
