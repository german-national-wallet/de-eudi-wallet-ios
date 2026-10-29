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

  public static var aboutLink: URL? {
    URL(string: "ABOUT_LINK".valueFromBundle)
  }

  public static var accessibilityStatementLink: URL? {
    URL(string: "ACCESSIBILITY_STATEMENT_LINK".valueFromBundle)
  }

  public static var termsAndConditionsLink: URL? {
    URL(string: "TERMS_AND_CONDITIONS_LINK".valueFromBundle)
  }

  public static var imprintLink: URL? {
    URL(string: "IMPRINT_LINK".valueFromBundle)
  }

  public static let ausweisSdkSimulatorIdentifier = "Simulator"

  public static var reportIssueUrl: URL? {
    URL(string: "REPORT_ISSUE_URL".valueFromBundle)
  }
}
