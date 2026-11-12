//
//  DeviceOwnerAuthenticationController.swift
//  logic-authentication
//

import Foundation
import LocalAuthentication
import logic_core

public enum DeviceOwnerAuthenticationResult: Equatable, Sendable {
  case authenticated
  case denied
  case interrupted
}

public protocol DeviceOwnerAuthenticationController: Sendable {
  func authenticate(localizedReason: String) async -> DeviceOwnerAuthenticationResult
}

final class DeviceOwnerAuthenticationControllerImpl: DeviceOwnerAuthenticationController {

  private static let interruptionCodes: Set<LAError.Code> = [.systemCancel, .appCancel, .notInteractive]

  func authenticate(localizedReason: String) async -> DeviceOwnerAuthenticationResult {
    if AppEnvironment.isUITesting { return .authenticated }
    let context = LAContext()
    defer { context.invalidate() }
    do {
      let isAuthenticated = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: localizedReason)
      return isAuthenticated ? .authenticated : .denied
    } catch let error as LAError where Self.interruptionCodes.contains(error.code) {
      return .interrupted
    } catch {
      return .denied
    }
  }
}
