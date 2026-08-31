//
//  IssuanceLoadingUiConfig.swift
//  feature-common
//
import Foundation
import logic_ui
import MdocDataModel18013

public struct FinishAuthorizationResponse: Equatable, Sendable {
  public let nonce: String
  public let code: String
  public let state: String?
  public let location: String
  
  public init(
    nonce: String,
    code: String,
    state: String?,
    location: String
  ) {
    self.nonce = nonce
    self.code = code
    self.state = state
    self.location = location
  }
}

public extension UIConfig {
  struct IssuanceLoadingUiConfig: UIConfigType {
    public let finishAuthorizationResponse: FinishAuthorizationResponse

    public var log: String {
      return "IssuanceLoading"
    }
    
    public init(
      finishAuthorizationResponse: FinishAuthorizationResponse
    ) {
      self.finishAuthorizationResponse = finishAuthorizationResponse
    }
  }
}
