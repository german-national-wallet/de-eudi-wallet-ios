//
//  InvalidPinRetryMessageConfig.swift
//  feature-common
//
import Foundation
import logic_resources
import logic_core
import logic_api

public extension UIConfig {
  struct InvalidPinRetryMessageConfig: UIConfigType {
    
    public let mainTitle: LocalizableStringKey
    public let retryMessage: LocalizableStringKey
    public let image: Image? = Theme.shared.image.orangeRetryError
    public let primaryButtonTitle: LocalizableStringKey
    public var remoteSessionCoordinator: RemoteSessionCoordinator?
    public var invalidPasswordResponse: InvalidPasswordResponse?

    public var log: String {
      return "mainTitle: \(mainTitle.toString)"
    }

    public init(
      mainTitle: LocalizableStringKey,
      retryMessage: LocalizableStringKey,
      primaryButtonTitle: LocalizableStringKey,
      remoteSessionCoordinator: RemoteSessionCoordinator? = nil,
      invalidPasswordResponse: InvalidPasswordResponse? = nil
    ) {
      self.mainTitle = mainTitle
      self.retryMessage = retryMessage
      self.primaryButtonTitle = primaryButtonTitle
      self.remoteSessionCoordinator = remoteSessionCoordinator
      self.invalidPasswordResponse = invalidPasswordResponse
    }
  }
}
