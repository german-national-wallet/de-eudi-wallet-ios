//
//  PNSPushActionTests.swift
//  push-notification-service
//

import Foundation
import Testing

@testable import push_notification_service

struct PNSPushActionTests {

  @Test
  func from_WhenPayloadCarriesTheRenewAction_ResolvesIt() {
    #expect(PNSPushAction.from(userInfo: ["action": "RENEW_MDVM_TOKEN"]) == .renewMDVMToken)
  }

  @Test
  func from_WhenPayloadCarriesTheFullAlertShape_ResolvesTheAction() {
    /// The delivered push also carries the user-visible `aps` part; the action must still resolve.
    let userInfo: [AnyHashable: Any] = [
      "aps": ["alert": ["title": "Wallet revoked"], "mutable-content": 1],
      "action": "RENEW_MDVM_TOKEN",
      "gcm.message_id": "1:234"
    ]

    #expect(PNSPushAction.from(userInfo: userInfo) == .renewMDVMToken)
  }

  @Test
  func from_WhenActionIsUnknown_ReturnsNil() {
    #expect(PNSPushAction.from(userInfo: ["action": "WIPE_EVERYTHING"]) == nil)
  }

  @Test
  func from_WhenActionKeyIsMissing_ReturnsNil() {
    #expect(PNSPushAction.from(userInfo: ["aps": ["alert": "hello"]]) == nil)
  }

  @Test
  func from_WhenPayloadIsEmpty_ReturnsNil() {
    #expect(PNSPushAction.from(userInfo: [:]) == nil)
  }

  @Test
  func from_WhenActionIsNotAString_ReturnsNil() {
    #expect(PNSPushAction.from(userInfo: ["action": 42]) == nil)
  }
}
