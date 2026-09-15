//
//  AutomationsConstants.swift
//  logic-core
//

import Foundation

enum AppConstants {
  enum LaunchArguments {
    static let uiTesting = "--ui-testing"
  }
}
public enum AppEnvironment {
  public static var isUITesting: Bool {
      CommandLine.arguments.contains(AppConstants.LaunchArguments.uiTesting)
  }
  
  public static var burgeramtServiceLink: URL? {
    URL(string: "BURGERAMT_SERVICE_LINK".valueFromBundle)
  }

  public static var privacyPolicyLink: URL? {
    URL(string: "PRIVACY_POLICY_LINK".valueFromBundle)
  }

  public static let ausweiseSdkSimulatorIdentifier = "Simulator"
}
