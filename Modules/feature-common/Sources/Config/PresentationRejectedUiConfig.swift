//
//  PresentationRejectedUiConfig.swift
//  feature-common
//

import logic_resources
import logic_ui
import SwiftUI

public struct PresentationRejectedUiConfig: UIConfigType {

  public enum Reason: Equatable, Sendable {
    case overAsking
    case unregisteredRelyingParty
  }

  public let reason: Reason
  public let reportURI: URL?

  public var title: LocalizableStringKey {
    switch reason {
    case .overAsking: .pidPresentationOverAskingTitle
    case .unregisteredRelyingParty: .pidPresentationRpUnregisteredTitle
    }
  }

  public var message: LocalizableStringKey {
    switch reason {
    case .overAsking: .pidPresentationOverAskingParagraph
    case .unregisteredRelyingParty: .pidPresentationRpUnregisteredParagraph
    }
  }

  public var primaryButtonTitle: LocalizableStringKey {
    switch reason {
    case .overAsking: .pidPresentationOverAskingPrimButton
    case .unregisteredRelyingParty: .pidPresentationRpUnregisteredPrimButton
    }
  }

  public var secondaryButtonTitle: LocalizableStringKey {
    switch reason {
    case .overAsking: .pidPresentationOverAskingSecButton
    case .unregisteredRelyingParty: .pidPresentationRpUnregisteredSecButton
    }
  }

  /// Reporting needs somewhere to send the user; without a report URI the report button is not offered.
  public var canReport: Bool {
    reportURI != nil
  }

  public var log: String {
    "reason: \(reason), hasReportURI: \(reportURI != nil)"
  }

  public init(reason: Reason, reportURI: URL? = nil) {
    self.reason = reason
    self.reportURI = reportURI
  }
}
