//
//  PushNotificationController.swift
//  Wallet
//

import Foundation
import UIKit
import UserNotifications
import FirebaseMessaging
import logic_business
import logic_core
import push_notification_service

final class PushNotificationController: NSObject {

  static let shared = PushNotificationController()

  private(set) var fcmRegistrationToken: String?

  private let logger: Logging

  private let pnsAccountInteractor: PNSAccountInteractor
  private let walletRevocationInteractor: WalletRevocationInteractor

  private var handlingTask: Task<Void, Never>?

  private override init() {
    self.logger = DIGraph.resolver.force(Logging.self)
    self.pnsAccountInteractor = DIGraph.resolver.force(PNSAccountInteractor.self)
    self.walletRevocationInteractor = DIGraph.resolver.force(WalletRevocationInteractor.self)
    super.init()
  }

  func configure() {
    UNUserNotificationCenter.current().delegate = self
    Messaging.messaging().delegate = self
  }

  func requestAuthorizationAndRegister() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      if let error {
        self.logger.e("[Push] Authorization request failed: \(error.logDescriptor)")
      }
      self.logger.d("[Push] Notification permission granted: \(granted)")
      guard granted else { return }
      DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
      }
    }
  }

  func setAPNSToken(_ deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }

  @discardableResult
  func handle(userInfo: [AnyHashable: Any]) -> Task<Void, Never>? {
    guard let action = PNSPushAction.from(userInfo: userInfo) else {
      logger.e("[Push] unknown or missing notification action, ignoring the message")
      return nil
    }

    logger.d("[Push] handling notification action \(action.rawValue)")
    switch action {
    case .renewMDVMToken:
      return enqueue { [walletRevocationInteractor] in
        await walletRevocationInteractor.confirmRevocation()
      }
    }
  }

  private func enqueue(_ work: @escaping @Sendable () async -> Void) -> Task<Void, Never> {
    let previous = handlingTask
    let task = Task {
      await previous?.value
      await work()
    }
    handlingTask = task
    return task
  }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationController: UNUserNotificationCenterDelegate {

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    handle(userInfo: notification.request.content.userInfo)
    completionHandler([.banner, .list, .sound, .badge])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    handle(userInfo: response.notification.request.content.userInfo)
    completionHandler()
  }
}

// MARK: - MessagingDelegate

extension PushNotificationController: MessagingDelegate {

  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    fcmRegistrationToken = fcmToken
    guard let fcmToken, !fcmToken.isEmpty else { return }
    Task { [pnsAccountInteractor] in
      await pnsAccountInteractor.handleTokenUpdate(fcmToken)
    }
  }
}
