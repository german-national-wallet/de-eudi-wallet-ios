//
//  BaseUITest.swift
//  EudiWalletDEUITests
//
//  Created by Tamas Dancsi  on 06.03.26.
//

import XCTest

class BaseUITest: XCTestCase {

  let app = XCUIApplication()
  static let deafultTimeout: TimeInterval = 12

  /// Timeout for the first query against freshly loaded web content.
  ///
  /// `WKWebView` publishes its accessibility tree from a separate web-content process, and none of
  /// the page's elements are queryable until that process is up and has published — the page is
  /// visibly loaded, and already reports its scroll extent, well before that happens. The first
  /// webview of a run also pays for launching that process, so `deafultTimeout` is not enough for
  /// whichever test happens to open the sheet first.
  static let webContentTimeout: TimeInterval = 90

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  /// Launches the app in UI-testing mode.
  /// - Parameter resetWallet: when `true` (the default, used when a test starts) the wallet
  ///   keychain is wiped so the test begins from a clean state. Pass `false` for mid-test
  ///   relaunches so issued credentials survive the relaunch.
  func openApp(resetWallet: Bool = true) {
    var arguments = ["--ui-testing"]
    if resetWallet {
      arguments.append("--reset-wallet")
    }
    app.launchArguments = arguments
    app.launch()
  }

  func relaunchApp() {
    app.terminate()
    openApp(resetWallet: false)
  }

  func passAppIntro(timeout: TimeInterval = 60) throws {
    try tap("appIntroSkipButton", timeout: timeout)
  }

  func enterWalletPin(timeout: TimeInterval = BaseUITest.deafultTimeout) throws {
    try fill("pinTextView", value: "111111", timeout: timeout)
    try tap("pinSubmitPrimaryButton", timeout: timeout)
  }

  /// Navigates past the wallet-revocation onboarding shown once after a fresh
  /// registration: the intro screen, then the save-key screen (which requires
  /// ticking the "saved elsewhere" checkbox before continuing).
  /// A `--reset-wallet` launch re-shows these, so this runs after every `openApp()`.
  func passRevocationOnboarding(timeout: TimeInterval = 60) throws {
    try tap("revocationIntroPrimaryButton", timeout: timeout)
    try tap("revocationSavedElsewhereCheckbox")
    try tap("revocationSaveKeyPrimaryButton")
  }

  /// Opens the UI-testing deep-link sheet and taps `link` on the playground page it loads.
  ///
  /// The link tap gets `webContentTimeout` rather than the default, because it is the first query
  /// against a page the webview has only just loaded.
  func openPlaygroundLink(
    _ link: String,
    timeout: TimeInterval = BaseUITest.webContentTimeout
  ) throws {
    try tap("deeplinkTriggerButton", timeout: 30)
    try tap(link, timeout: timeout)
  }

  // MARK: - UITest helpers

  func tap(
    _ label: String,
    contains: Bool = false,
    timeout: TimeInterval = BaseUITest.deafultTimeout,
    elementType: XCUIElement.ElementType? = nil
  ) throws {
    let element = try waitForElement(
      label,
      contains: contains,
      timeout: timeout,
      fillable: false,
      elementType: elementType
    )
    element.tap()
  }

  func fill(
    _ label: String,
    value: String,
    contains: Bool = false,
    timeout: TimeInterval = BaseUITest.deafultTimeout,
    elementType: XCUIElement.ElementType? = nil
  ) throws {
    let element = try waitForElement(
      label,
      contains: contains,
      timeout: timeout,
      fillable: true,
      elementType: elementType
    )
    if element.elementType == .secureTextField {
      element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
      element.typeText(value)
    } else if element.isHittable {
      element.tap()
      element.typeText(value)
    } else {
      app.typeText(value)
    }
  }

  func exists(
    _ label: String,
    contains: Bool = false,
    timeout: TimeInterval = BaseUITest.deafultTimeout,
    elementType: XCUIElement.ElementType? = nil
  ) throws {
    _ = try waitForElement(
      label,
      contains: contains,
      timeout: timeout,
      fillable: false,
      elementType: elementType
    )
  }

  /// Non-throwing existence check, for optional UI such as the issuer's web login page,
  /// which is only shown when there is no cached web-auth session from a previous run.
  func elementExists(
    _ label: String,
    contains: Bool = false,
    timeout: TimeInterval = BaseUITest.deafultTimeout,
    elementType: XCUIElement.ElementType? = nil
  ) -> Bool {
    (try? waitForElement(
      label,
      contains: contains,
      timeout: timeout,
      fillable: false,
      elementType: elementType
    )) != nil
  }

  func tapSystemButton(_ label: String, timeout: TimeInterval = BaseUITest.deafultTimeout) throws {
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    let alert = springboard.alerts.firstMatch
    guard alert.waitForExistence(timeout: timeout) else {
      throw UITestError(message: "Missing system alert with button \"\(label)\"")
    }
    let labelledButton = alert.buttons[label]
    let defaultAlertButton = alert.buttons.allElementsBoundByIndex.last
    guard let button = labelledButton.exists ? labelledButton : defaultAlertButton else {
      throw UITestError(message: "Missing system button \"\(label)\"")
    }
    sleep(1)
    button.tap()
  }

  private func waitForElement(
    _ label: String,
    contains: Bool,
    timeout: TimeInterval = BaseUITest.deafultTimeout,
    fillable: Bool,
    elementType: XCUIElement.ElementType? = nil
  ) throws -> XCUIElement {
    let descriptor = contains ? "containing \"\(label)\"" : "\"\(label)\""
    if fillable {
      let inputTypes: [XCUIElement.ElementType]
      switch elementType {
      case .textField:
        inputTypes = [.textField]
      case .secureTextField:
        inputTypes = [.secureTextField]
      case .none:
        inputTypes = [.textField, .secureTextField]
      default:
        throw UITestError(message: "Unsupported input field type for \(descriptor)")
      }

      for inputType in inputTypes {
        let input = app.descendants(matching: inputType)
          .matching(labelPredicate(label, contains: contains, elementType: inputType))
          .firstMatch
        if input.waitForExistence(timeout: timeout) {
          return input
        }
      }
      throw UITestError(message: "Missing input field \(descriptor)")
    }

    let element = app.descendants(matching: .any)
      .matching(labelPredicate(label, contains: contains, elementType: elementType))
      .firstMatch
    if element.waitForExistence(timeout: timeout) {
      return element
    }
    throw UITestError(message: "Missing element \(descriptor)")
  }

  private func labelPredicate(
    _ label: String,
    contains: Bool,
    elementType: XCUIElement.ElementType? = nil
  ) -> NSPredicate {
    let labelFormat = contains
      ? "(identifier CONTAINS[c] %@ OR label CONTAINS[c] %@)"
      : "(identifier == %@ OR label == %@)"

    guard let elementType else {
      return NSPredicate(format: labelFormat, label, label)
    }

    return NSPredicate(
      format: "\(labelFormat) AND elementType == %d",
      label,
      label,
      elementType.rawValue
    )
  }
}
