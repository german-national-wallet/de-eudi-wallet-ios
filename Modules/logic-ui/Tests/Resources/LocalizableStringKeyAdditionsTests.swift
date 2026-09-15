//
//  LocalizableStringKeyAdditionsTests.swift
//  logic-ui
//
//  Created by Ameen Qadri on 27.07.26.
//

import XCTest
import logic_resources

// Verifies the localization keys added for the EAA card designs resolve to a
// real translation from the resources bundle (i.e. the enum case + manager
// mapping + xcstrings entry are all wired correctly).
final class LocalizableStringKeyAdditionsTests: XCTestCase {

  func test_buttonViewData_resolvesToTranslatedValue() {
    let value = LocalizableStringKey.buttonViewData.toString

    XCTAssertFalse(value.isEmpty, "Expected a non-empty localized value")
    XCTAssertNotEqual(
      value,
      "button_view_data",
      "Expected a translated value, not the raw key — the key is not wired to the bundle"
    )
  }

  func test_eaaIssuanceDialogCancelSecButton_resolvesToTranslatedValue() {
    let value = LocalizableStringKey.eaaIssuanceDialogCancelSecButton.toString

    XCTAssertFalse(value.isEmpty, "Expected a non-empty localized value")
    XCTAssertNotEqual(
      value,
      "eaa_issuance.dialog_cancel.sec_button",
      "Expected a translated value, not the raw key — the key is not wired to the bundle"
    )
  }

  func test_pidOnboardingKeys_resolveToTranslatedValues() {
    let keys: [(LocalizableStringKey, String)] = [
      (.pidNoLetterForgotInfoTitle, "pid_issuance.no_letter_forgot_info.title"),
      (.pidNoLetterForgotInfoParagraph, "pid_issuance.no_letter_forgot_info.paragraph"),
      (.pidCardPinLetterInfoTitle, "pid_issuance.card_pin_letter_info.title"),
      (.pidCardPinLetterInfoHeadline1, "pid_issuance.card_pin_letter_info.headline_1"),
      (.pidCardPinLetterInfoParagraph1, "pid_issuance.card_pin_letter_info.paragraph_1"),
      (.pidCardPinLetterInfoHeadline2, "pid_issuance.card_pin_letter_info.headline_2"),
      (.pidCardPinLetterInfoParagraph2, "pid_issuance.card_pin_letter_info.paragraph_2"),
      (.pidCardPinLetterInfoSecButton, "pid_issuance.card_pin_letter_info.sec_button"),
      (.pidIssuanceDialogCancelTitle, "pid_issuance.dialog_cancel.title"),
      (.pidIssuanceDialogCancelSubTitle, "pid_issuance.dialog_cancel.paragraph"),
      (.pidIssuanceDialogCancelPrimButton, "pid_issuance.dialog_cancel.prim_button"),
      (.pidIssuanceDialogCancelSecButton, "pid_issuance.dialog_cancel.sec_button")
    ]

    for (key, rawKey) in keys {
      let value = key.toString

      XCTAssertFalse(value.isEmpty, "Expected a non-empty localized value for \(rawKey)")
      XCTAssertNotEqual(
        value,
        rawKey,
        "Expected a translated value, not the raw key — \(rawKey) is not wired to the bundle"
      )
    }
  }
}
