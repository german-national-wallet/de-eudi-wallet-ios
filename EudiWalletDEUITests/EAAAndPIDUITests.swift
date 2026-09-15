//
//  EAAFlowUITests.swift
//  EudiWalletDEUITests
//
//  Created by Tamas Dancsi  on 06.03.26.
//
import XCTest

final class EAAAndPIDUITests: BaseUITest {

  // MARK: - PID tests
  
  func testPIDPresentationFailureWithWrongPIN() throws {
    openApp()
    try passAppIntro()
    try passRevocationOnboarding()
    try exists("dashboardPrimaryButton", timeout: 30)
    try issuePID()

    // Verification
    relaunchApp()
    try openPlaygroundLink("Vineyard Select")
    try tap("Proceed to Checkout", elementType: .button)
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try tap("rpInfoNextButton")
    try tap("rpConsentNextButton")

    // Testing wrong PIN entry and deleting account
    var retryCount = 0
    while retryCount < 3 {
      try fill("pinTextView", value: "222222", timeout: 30)
      try tap("pinSubmitPrimaryButton", timeout: 30)
      retryCount += 1
      if retryCount < 3 {
        try exists("incorrect", contains: true, timeout: 30)
      }
    }
    try tap("To Overview")
    try tap("Delete Digital ID now")
    try tap("Yes, delete")

    // Re-issue PID
    try exists("dashboardPrimaryButton")
    try issuePID()
  }

  // MARK: - Multiple credential presentation tests

  func testMultipleCredentialPresentation() throws {
    openApp()
    try passAppIntro()
    try passRevocationOnboarding()
    try issuePID()

    // Issuance of Diploma
    try openPlaygroundLink("European Technical University")
    try tap("Get Digital Diploma", contains: true)
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try exists("Add")
    try tap("Add")
    // TODO: Temporarily commented; re-enable once the underlying issuance fix lands
//    try tap("Continue with entry")
    try tapSystemButton("Continue")
    if elementExists("Sign In", timeout: 30, elementType: .button) {
      try fill("Username or email", value: "Erika")
      try fill("Password", value: "Erika\n", elementType: .secureTextField)
      if elementExists("Sign In", timeout: 5, elementType: .button) {
        try tap("Sign In", elementType: .button)
      }
    }
    try exists("University Diploma", timeout: 60)

    try openPlaygroundLink("TechCorp Careers")
    try tap("Verify Diploma + Identity", elementType: .button)
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try exists("rpInfoNextButton")
    try tap("rpInfoNextButton")
    try tap("rpConsentNextButton")
    try enterWalletPin(timeout: 60)
    try exists("Diploma verified", contains: true)
    try tap("closeWebViewButton")

    // Deleting EAA
    try deleteEAA("University Diploma")
  }

  // MARK: - Pre-auth code flow without transaction code

  func testEAAPreAuthNoTransactionCodeFlow() throws {
    // Issuance
    openApp()
    try passAppIntro()
    try passRevocationOnboarding()
    try openPlaygroundLink("FitLife Health Club")
    try tap("Complete Registration", contains: true)
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try exists("rpConsentNextButton")
    try tap("rpConsentNextButton")
    try exists("FitLife Membership")

    // Verification
//    app.launch()
    try openPlaygroundLink("SportZone")
    try tap("Apply Member Discount", contains: true)
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try exists("rpInfoNextButton")
    try tap("rpInfoNextButton")
    try tap("rpConsentNextButton")
    try exists("membership verified", contains: true)
    try tap("closeWebViewButton")

    // Deleting EAA
    try deleteEAA("FitLife Membership")
  }

   // MARK: - Pre-auth code flow with transaction code

  func testEAAPreAuthTransactionCodeFlow() throws {
    // Issuance
    openApp()
    try passAppIntro()
    try passRevocationOnboarding()
    try openPlaygroundLink("FitLife Health Club")
    try tap("Secure Registration (with PIN)", contains: true)
    let code = try readSixDigitCode()
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try exists("Next")
    try tap("Next")
    try tap("offerIntroPrimaryButton")
    app.typeText(code)
    try tap("pinSubmitPrimaryButton")
    try exists("FitLife Membership", timeout: 60)

    // Verification
//    relaunchApp()
    try openPlaygroundLink("SportZone")
    try tap("Apply Member Discount", contains: true)
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try exists("rpInfoNextButton")
    try tap("rpInfoNextButton")
    try tap("rpConsentNextButton")
    try exists("membership verified", contains: true)
    try tap("closeWebViewButton")

    // Deleting EAA
    try deleteEAA("FitLife Membership")
  }

  // MARK: - Revocation onboarding

  func testRevocationOnboardingShownOnceThenSkipped() throws {
    openApp()
    try passAppIntro()
    try exists("revocationIntroPrimaryButton", timeout: 60)
    try tap("revocationIntroPrimaryButton")
    try exists("revocationCodeText")
    try exists("revocationCodeShareButton")
    try tap("revocationCodeCopyButton")
    try tap("revocationSavedElsewhereCheckbox")
    try tap("revocationSaveKeyPrimaryButton")
    try exists("dashboardPrimaryButton", timeout: 30)
    relaunchApp()
    try exists("dashboardPrimaryButton", timeout: 30)
  }

  func readSixDigitCode(timeout: TimeInterval = BaseUITest.deafultTimeout) throws -> String {
    let code = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]{6}$")).firstMatch
    guard code.waitForExistence(timeout: timeout) else {
      throw UITestError(message: "Missing 6-digit transaction code")
    }
    return code.label
  }

  // MARK: - MDL Issuer ui test
  
  func testMDLIssuanceFlow() throws {
    openApp()
    try passAppIntro()
    try passRevocationOnboarding()
    try issuePID()
    try openPlaygroundLink("Driving Licence Authority")
    try tap("Create mDL Offer")
    try tap("Open in Wallet")
    try tap("closeWebViewButton")
    try exists("Add")
    try tap("Add")
    // TODO: Temporarily commented; re-enable once the underlying issuance fix lands
//    try tap("Continue with entry")
    try tapSystemButton("Continue")
    try tap("rpInfoNextButton")
    try tap("rpConsentNextButton")
    try enterWalletPin(timeout: 60)
    try tapSystemButton("Continue")
    
    // Deleting EAA
    try deleteEAA("Driving Licence")
    
  }
  
  // MARK: - helpers

  private func issuePID() throws {
    try tap("dashboardPrimaryButton", timeout: 30)
    try tap("onboardingCardsPrimaryOption")
    try tap("onboardingPinKnownOption")
    try tap("processOverviewContinueButton")
    try exists("issuanceConsentViewTitle")
    try tap("issuanceConsentViewPrimaryButton")
    try enterWalletPin()
    try tap("issuanceCardStartScanningButton", timeout: 30)
    try tap("issuancePidPreviewContinueButton", timeout: 60)
    try tap("instructionsScreen1PrimaryButton", timeout: 30)
    try enterWalletPin()
    try enterWalletPin()
    try exists("deeplinkTriggerButton", timeout: 60)
  }

  private func deleteEAA(_ label: String) throws {
    try tap("eaaCredentialTitleView", timeout: 10)
    try tap("deleteButton")

    guard elementExists("credentialTitleView", timeout: 5)
            || elementExists("dashboardPrimaryButton", timeout: 15) else {
      throw UITestError(message: "Dashboard not shown after deleting \"\(label)\"")
    }
  }
}
