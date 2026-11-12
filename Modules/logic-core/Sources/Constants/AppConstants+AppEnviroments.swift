//
//  AutomationsConstants.swift
//  logic-core
//

import Foundation

enum AppConstants {
  enum LaunchArguments {
    static let uiTesting = "--ui-testing"
  }
  enum LaunchEnvironment {
    static let uiTestWebURL = "UI_TEST_WEB_URL"
    static let skipRegistrationCertificateValidation = "UI_TEST_SKIP_WRPRC"
  }
}
public enum AppEnvironment {
  public static var isUITesting: Bool {
      CommandLine.arguments.contains(AppConstants.LaunchArguments.uiTesting)
  }

  /// Page loaded by the UI-testing deep-link sheet (`deeplinkTriggerButton`).
  /// XCUITests can point it at a local Ambor instance through the `UI_TEST_WEB_URL`
  /// launch environment variable; otherwise it is the public playground, so the
  /// existing playground tests keep working. Only honoured in UI-testing mode.
  public static var uiTestWebURL: URL? {
    let playground = URL(string: "https://playground.eudi-wallet.org/")
    guard isUITesting,
          let raw = ProcessInfo.processInfo.environment[AppConstants.LaunchEnvironment.uiTestWebURL],
          let url = URL(string: raw),
          let scheme = url.scheme?.lowercased(),
          ["http", "https"].contains(scheme) else {
      return playground
    }
    return url
  }

  private static var environmentLanguageSuffix: String {
    guard let languageCode = Bundle.assetsBundle.preferredLocalizations.first?.components(separatedBy: "-").first else {
      return "EN"
    }
    return languageCode.uppercased()
  }

  private static func localizedLink(_ key: String) -> URL? {
    let localized = "\(key)_\(environmentLanguageSuffix)".optionalValueFromBundle
    return URL(string: localized ?? "\(key)_EN".valueFromBundle)
  }

  public static var burgeramtServiceLink: URL? {
    URL(string: "BURGERAMT_SERVICE_LINK".valueFromBundle)
  }

  public static var privacyPolicyLink: URL? {
    localizedLink("PRIVACY_POLICY_LINK")
  }

  public static var pidPrivacyPolicyLink: URL? {
    localizedLink("PID_PRIVACY_POLICY_LINK")
  }

  public static var faqLink: URL? {
    localizedLink("FAQ_LINK")
  }

  public static var aboutLink: URL? {
    localizedLink("ABOUT_LINK")
  }

  public static var accessibilityStatementLink: URL? {
    URL(string: "ACCESSIBILITY_STATEMENT_LINK".valueFromBundle)
  }

  public static var termsAndConditionsLink: URL? {
    return localizedLink("TERMS_AND_CONDITIONS_LINK")
  }

  public static var imprintLink: URL? {
    localizedLink("IMPRINT_LINK")
  }

  public static var credentialCatalogueLink: URL? {
    if Locale.current.language.languageCode?.identifier == "de" {
      return URL(string: "https://eudi-hub.gov.de/de/credentials/nachweisuebersicht?showNavigation=false")
    }
    return URL(string: "https://eudi-hub.gov.de/en/credentials/credential-overview?showNavigation=false")
  }

  /// UI tests against a local test verifier (Ambor/EUDIPLO) that has no registrar can set
  /// `UI_TEST_SKIP_WRPRC=1` to skip relying-party registration certificate validation.
  /// Only honoured in UI-testing mode; playground tests and all real builds keep validating.
  public static var skipsRegistrationCertificateValidation: Bool {
    isUITesting
      && ProcessInfo.processInfo.environment[AppConstants.LaunchEnvironment.skipRegistrationCertificateValidation] == "1"
  }

  public static let ausweisSdkSimulatorIdentifier = "Simulator"

  public static var reportIssueUrl: URL? {
    URL(string: "REPORT_ISSUE_URL".valueFromBundle)
  }
}
