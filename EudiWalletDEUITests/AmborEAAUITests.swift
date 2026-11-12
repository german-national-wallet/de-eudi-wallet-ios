//
//  AmborEAAUITests.swift
//  EudiWalletDEUITests
//

import XCTest

final class AmborEAAUITests: BaseUITest {

  // MARK: - Issuance

  func testLoyaltyIssuanceWithoutTransactionCode() throws {
    try launchOnboarded(scenario: "issue-loyalty-preauth")
    try openAmbor()
    let runId = try startRun()
    try openWallet()
    try tap("rpConsentNextButton", timeout: 60)
    try exists("FitLife Membership", timeout: 60)
    try waitForVerdict(runId: runId)
    try closeAmbor()
    try deleteEAA("FitLife Membership")
  }

  func testEventAccessIssuanceWithTransactionCode() throws {
    try launchOnboarded(scenario: "issue-eaa-preauth")
    try openAmbor()
    let runId = try startRun()
    let code = try readTransactionCode()
    try openWallet()
    try exists("Next", timeout: 60)
    try tap("Next")
    try tap("offerIntroPrimaryButton")
    app.typeText(code)
    try tap("pinSubmitPrimaryButton")
    if elementExists("pinTextView", timeout: 15) {
      try enterWalletPin()
    }
    try exists("Event Access Pass", timeout: 60)
    try waitForVerdict(runId: runId)
    try closeAmbor()
    try deleteEAA("Event Access Pass")
  }

  func testMDLIssuanceAfterPIDCheck() throws {
    try launchOnboarded(scenario: "issue-mdl-pid-auth")
    try issuePID()
    try openAmbor()
    let runId = try startRun()
    try openWallet()
    try tap("rpConsentNextButton", timeout: 60)
    try tapSystemButton("Continue")
    if elementExists("Open wallet", timeout: 20) {
      try tap("Open wallet")
    }
    try tap("rpInfoNextButton", timeout: 60)
    try tap("rpConsentNextButton")
    try enterWalletPin(timeout: 60)
    if (try? tapSystemButton("Continue", timeout: 20)) == nil {
      // No second prompt on this build; continue.
    }
    try exists("Driving Licence", timeout: 90)
    try waitForVerdict(runId: runId)
    try closeAmbor()
    try deleteEAA("Driving Licence")
  }

  // MARK: - Presentation

  func testLoyaltyIssueThenPresentSelectively() throws {
    try launchOnboarded(scenario: "loyalty-issue-present-selective")
    try openAmbor()
    let runId = try startRun()
    try openWallet()
    try tap("rpConsentNextButton", timeout: 60)
    try exists("FitLife Membership", timeout: 60)

    try openAmbor()
    try waitForOpenWallet(timeout: 90)
    try openWallet()
    try exists("rpInfoNextButton", timeout: 60)
    try tap("rpInfoNextButton")
    try tap("rpConsentNextButton")
    try waitForVerdict(runId: runId)
    try closeAmbor()
    try deleteEAA("FitLife Membership")
  }

  func testPIDAgeOverPresentation() throws {
    try launchOnboarded(scenario: "pid-age-over-sd-jwt-vc")
    try issuePID()
    try openAmbor()
    let runId = try startRun()
    try openWallet()
    try exists("rpInfoNextButton", timeout: 60)
    try tap("rpInfoNextButton")
    try tap("rpConsentNextButton")
    try enterWalletPin(timeout: 60)
    try waitForVerdict(runId: runId)
    try closeAmbor()
  }

  // MARK: - Helpers

  private func launchOnboarded(scenario: String) throws {
    // Ambor's local EUDIPLO verifier has no registrar, so its requests carry no registration certificate.
    openApp(webURL: amborPageURL(scenario: scenario), skipRegistrationCertificateValidation: true)
    try passAppIntro()
    try passRevocationOnboarding()
    try exists("dashboardPrimaryButton", timeout: 30)
  }
}
