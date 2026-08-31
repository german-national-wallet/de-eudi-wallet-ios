//
//  PNSPushAction.swift
//  push-notification-service
//

public enum PNSPushAction: String, Equatable, Sendable {
  case renewMDVMToken = "RENEW_MDVM_TOKEN"

  public static let payloadKey = "action"

  public static func from(userInfo: [AnyHashable: Any]) -> PNSPushAction? {
    guard let rawValue = userInfo[payloadKey] as? String else {
      return nil
    }
    return PNSPushAction(rawValue: rawValue)
  }
}
