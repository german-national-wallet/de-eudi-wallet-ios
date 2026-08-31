//
//  BackgroundTaskAssertion.swift
//  logic-business
//

import UIKit

public enum BackgroundTask {
  public static func run<T>(
    name: String,
    _ operation: () async -> T
  ) async -> T {
    await Assertion.shared.begin(name: name)
    let result = await operation()
    await Assertion.shared.end()
    return result
  }
}

@MainActor
private final class Assertion {
  static let shared = Assertion()

  private var identifier: UIBackgroundTaskIdentifier = .invalid

  func begin(name: String) {
    guard identifier == .invalid else { return }
    identifier = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
      self?.end()
    }
  }

  func end() {
    guard identifier != .invalid else { return }
    UIApplication.shared.endBackgroundTask(identifier)
    identifier = .invalid
  }
}
