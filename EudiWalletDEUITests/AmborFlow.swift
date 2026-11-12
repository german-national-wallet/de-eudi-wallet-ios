//
//  AmborFlow.swift
//  EudiWalletDEUITests
//

import XCTest

extension BaseUITest {

  /// Base URL of the Ambor instance. Override with the `AMBOR_URL` environment variable of the
  /// test runner (test plan environment, or `TEST_RUNNER_AMBOR_URL=…` on xcodebuild).
  static var amborBaseURL: String {
    let configured = ProcessInfo.processInfo.environment["AMBOR_URL"] ?? "https://localhost:8443"
    return configured.hasSuffix("/") ? String(configured.dropLast()) : configured
  }

  /// Ambor page URL with the scenario preselected and the run labelled for this runner.
  func amborPageURL(scenario: String, timeoutSeconds: Int = 600) -> String {
    let query = [
      ("scenario", scenario),
      ("walletName", "iOS XCUITest"),
      ("timeoutSeconds", String(timeoutSeconds))
    ]
    .map { "\($0.0)=\($0.1.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.1)" }
    .joined(separator: "&")
    return "\(BaseUITest.amborBaseURL)/?\(query)"
  }

  /// Opens the UI-testing sheet on the Ambor page and waits for its controls to be queryable.
  func openAmbor(timeout: TimeInterval = BaseUITest.webContentTimeout) throws {
    try tap("deeplinkTriggerButton", timeout: 30)
    guard app.webViews.buttons["Start run"].firstMatch.waitForExistence(timeout: timeout) else {
      throw UITestError(message: "Ambor page did not load at \(BaseUITest.amborBaseURL); "
        + "start the stack (scripts/stack-native.sh up or docker compose up -d in e2e-wallet-test-tool) "
        + "and run scripts/trust-simulator.sh. \(amborPageSummary())")
    }
  }

  /// Starts a run for the preselected scenario and returns its run ID once the wallet step is ready.
  func startRun(timeout: TimeInterval = 60) throws -> String {
    try tapWebButtonWhenEnabled("Start run", timeout: timeout)
    let runId = try readWebText(prefix: "Run ID: ", timeout: timeout)
    try waitForOpenWallet(timeout: timeout)
    return runId
  }

  /// Waits until Ambor has prepared the current step and the page enables "Open wallet".
  func waitForOpenWallet(timeout: TimeInterval = 60) throws {
    let button = app.webViews.buttons["Open wallet"].firstMatch
    let enabled = NSPredicate(format: "exists == true AND isEnabled == true")
    let result = XCTWaiter.wait(for: [expectation(for: enabled, evaluatedWith: button)], timeout: timeout)
    guard result == .completed else {
      throw UITestError(message: "Ambor did not enable 'Open wallet' within \(Int(timeout))s. \(amborPageSummary())")
    }
  }

  /// Hands the current step's URI to the wallet and closes the sheet so the native flow is on top.
  func openWallet() throws {
    try waitForOpenWallet()
    app.webViews.buttons["Open wallet"].firstMatch.tap()
    try tap("closeWebViewButton")
  }

  /// Reads the transaction code of a pre-authorized offer. Call before `openWallet()`.
  func readTransactionCode(timeout: TimeInterval = BaseUITest.deafultTimeout) throws -> String {
    try readWebText(prefix: "Transaction code: ", timeout: timeout)
  }

  /// Waits for Ambor's terminal verdict of `runId`. Reopens the sheet when it is not showing;
  /// the page restores the active run from browser storage. Matching the run ID guards against
  /// a previous test's run being restored instead.
  func waitForVerdict(runId: String, expected: String = "passed", timeout: TimeInterval = 120) throws {
    if !app.buttons["closeWebViewButton"].exists {
      try openAmbor()
    }
    let present = NSPredicate(format: "exists == true")
    let verdict = app.webViews.staticTexts["Verdict: \(expected)"].firstMatch
    let sameRun = app.webViews.staticTexts["Run ID: \(runId)"].firstMatch
    let result = XCTWaiter.wait(
      for: [expectation(for: present, evaluatedWith: verdict), expectation(for: present, evaluatedWith: sameRun)],
      timeout: timeout
    )
    guard result == .completed else {
      throw UITestError(
        message: "Ambor did not report 'Verdict: \(expected)' for run \(runId) within \(Int(timeout))s. \(amborPageSummary())"
      )
    }
  }

  /// Closes the Ambor sheet.
  func closeAmbor() throws {
    try tap("closeWebViewButton")
  }

  // MARK: - Private

  private func tapWebButtonWhenEnabled(_ label: String, timeout: TimeInterval) throws {
    let button = app.webViews.buttons[label].firstMatch
    let enabled = NSPredicate(format: "exists == true AND isEnabled == true")
    guard XCTWaiter.wait(for: [expectation(for: enabled, evaluatedWith: button)], timeout: timeout) == .completed else {
      throw UITestError(message: "Missing or disabled web button \"\(label)\". \(amborPageSummary())")
    }
    button.tap()
  }

  private func readWebText(prefix: String, timeout: TimeInterval) throws -> String {
    let element = app.webViews.staticTexts
      .matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
      .firstMatch
    guard element.waitForExistence(timeout: timeout) else {
      throw UITestError(message: "Missing web text starting with \"\(prefix)\". \(amborPageSummary())")
    }
    return String(element.label.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
  }

  /// Visible page texts for failure messages; includes Ambor's reason and step lines.
  private func amborPageSummary() -> String {
    let texts = app.webViews.staticTexts.allElementsBoundByIndex
      .prefix(40)
      .map(\.label)
      .filter { !$0.isEmpty }
    return texts.isEmpty ? "Ambor page showed no text." : "Ambor page: " + texts.joined(separator: " | ")
  }
}
