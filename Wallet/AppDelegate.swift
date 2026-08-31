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
import Foundation
import UIKit
import logic_assembly
import logic_business
import logic_core
import feature_common
import SwiftUI
import FirebaseCore

class AppDelegate: UIResponder, UIApplicationDelegate {

  private lazy var analyticsController: AnalyticsController = DIGraph.resolver.force(AnalyticsController.self)
  private lazy var logger: Logging = DIGraph.resolver.force(Logging.self)

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    clearPinSession()
    initializeReporting()
    setupPushNotifications()
    return true
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    PushNotificationController.shared.setAPNSToken(deviceToken)
  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    logger.e("[Push] Failed to register for remote notifications: \(error.logDescriptor)")
  }

  /// The only path that runs without the user tapping the notification. It requires the payload to
  /// carry `content-available: 1` alongside the alert, otherwise iOS does not wake the app in the
  /// background and the instruction is only acted on once the app is opened.
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    guard let task = PushNotificationController.shared.handle(userInfo: userInfo) else {
      completionHandler(.noData)
      return
    }
    Task {
      await task.value
      completionHandler(.newData)
    }
  }

  func application(
    _ application: UIApplication,
    shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier
  ) -> Bool {
    switch extensionPointIdentifier {
    case UIApplication.ExtensionPointIdentifier.keyboard: return false
    default: return true
    }
  }

  func applicationWillTerminate(_ application: UIApplication) {
    clearPinSession()
  }

  private func initializeReporting() {
    analyticsController.initialize()
  }

  private func setupPushNotifications() {
    PushNotificationController.shared.configure()
    PushNotificationController.shared.requestAuthorizationAndRegister()
  }

  private func clearPinSession() {
    DIGraph.resolver.force(PinSessionInteractor.self).clear()
  }
}
