//
//  RWSCAServerErrorCode.swift
//  logic-api
//

public enum RWSCAServerErrorCode {
  public static let pinAlreadyInitialized = "PIN_ALREADY_INITIALIZED"
  public static let pinNotInitialized = "PIN_NOT_INITIALIZED"
  public static let accountLocked = "ACCOUNT_LOCKED"
  public static let accountUnknown = "ACCOUNT_UNKNOWN"
  public static let authVerificationFailed = "AUTH_VERIFICATION_FAILED"
}
