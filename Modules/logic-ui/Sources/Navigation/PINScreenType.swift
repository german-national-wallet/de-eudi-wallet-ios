//
//  PINScreenType.swift
//  logic-ui
//

import Foundation

public enum PINScreenType: Sendable {
  
  // MARK: - Typical Issuance Flow
  
  /// `issueEidPinFlow` represents the flow triggered
  ///  when the user wants to issue their PID from a typical issuance flow
  ///
  ///   - **Flow: **
  ///    User wants to issue a PID ->`issueEidPinFlow`
  case issueEidPinFlow
  
  /// `setupWalletPin` represents the flow triggered
  ///  when the user wants to issue their PID from a typical issuance flow
  ///  and then has to set the wallet pin.
  ///
  ///   - **Flow: **
  ///    User wants to issue a PID ->`issueEidPinFlow` ->  `setupWalletPin`.
  case setupWalletPinflow
  
  /// `confirmNewWalletPin` represents the flow triggered
  ///  when the user wants to issue their PID from a typical issuance flow
  ///  and then has to set the wallet pin, next the user needs to **confirm** the pin that he added.
  ///
  ///   - **Flow: **
  ///    User wants to issue a PID ->`issueEidPinFlow` ->  `setupWalletPin` ->  `confirmNewWalletPin`
  case confirmNewWalletPinFlow
    
  // MARK: - Setup a new EID Card Flow
  
  /// `transportPinFlow` represents the flow triggered
  ///  when the user wants to set up a NEW card and wants to setup a new eid pin
  ///  for that the user is required to enter the transport PIN from the PIN letter.
  ///
  ///  - **Flow: **
  ///  User wants to setup a new EID CARD ->`transportPinFlow`
  case transportPinFlow
  
  /// `setupNewEidPinFlow` represents the flow triggered
  ///  after entering the Transport pin when the user wants
  ///  to set up a NEW card and wants to setup a **new eid pin**
  ///  for that the user is required to enter the new PIN from after entering the correct
  ///  transport pin.
  ///
  ///  - **Flow:
  ///   ** User wants to setup a new EID CARD -> `transportPinFlow` ->`setupNewEidPinFlow`
  case setupNewEidPinFlow
  
  /// `confirmNewEIDPinFlow` represents the flow triggered
  ///  after entering the **NEW EID PIN**, this is asked to confirm
  ///  and verify the new **NEW EID PIN**.
  ///
  ///  - **Flow:
  ///  ** User wants to setup a new EID CARD -> `transportPinFlow` ->`setupNewEidPinFlow` ->  `confirmNewEIDPinFlow`
  case confirmNewEIDPinFlow
  
  // MARK: - Verify wallet pin in Presentation flow
  
  /// `verifyWalletPinFlow` represents the flow triggered when the
  ///  user has to enter wallet print to validate the
  ///  presentation request in the presentation flow
  ///
  ///  - **Flow: **
  ///  Presentation request -> `verifyWalletPinFlow`
  case verifyWalletPinFlow
  
  // MARK: - Error flows
  
  /// `eidCanFlow` represents the flow triggered when the user has entered
  ///  their eID PIN incorrectly at least two times.
  ///
  ///   - **Flow: **
  ///    Enter eid pin incorrect twice ->`eidCanFlow`
  case eidCanFlow

  case eidPinAfterCanFlow
  
}
