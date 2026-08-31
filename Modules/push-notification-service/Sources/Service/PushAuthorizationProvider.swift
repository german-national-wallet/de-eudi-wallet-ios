//
//  PushAuthorizationProvider.swift
//  push-notification-service
//

import UserNotifications

/// Push notifications are strictly opt-in: they introduce a dependency on Google/Apple
/// infrastructure and expose metadata to the Mobile Platform Provider. The system notification
/// authorization is the opt-in signal, so without it the WI must not register at the PNS.
public protocol PushAuthorizationProvider: Sendable {
  func isAuthorized() async -> Bool
}

struct UserNotificationAuthorizationProvider: PushAuthorizationProvider {

  func isAuthorized() async -> Bool {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    switch settings.authorizationStatus {
    case .authorized, .provisional, .ephemeral:
      return true
    case .denied, .notDetermined:
      return false
    @unknown default:
      return false
    }
  }
}
