//
//  DocumentLoaderUiConfig.swift
//  feature-common
//

import Foundation
import logic_ui
import logic_resources
import logic_core

public struct DocumentLoaderUiConfig: UIConfigType, Equatable {

  public let offerUri: String
  public let issuerName: String
  public let docOffers: [OfferedDocModel]
  public let successNavigation: UIConfig.TwoWayNavigationType
  public let navigationCancelType: UIConfig.ThreeWayNavigationType
  public let txCodeValue: String?

  public var log: String {
    return "offerUri: \(offerUri)" +
    " issuerName: \(issuerName)" +
    " docOffers \(docOffers.map { $0.displayName }.joined(separator: ",") )" +
    " onSuccessNav: \(successNavigation.key)" +
    " onBackNav: \(navigationCancelType.key)" +
    " hasTxCode: \(txCodeValue != nil)"
  }

  public init(
    offerUri: String,
    issuerName: String,
    docOffers: [OfferedDocModel],
    successNavigation: UIConfig.TwoWayNavigationType,
    navigationCancelType: UIConfig.ThreeWayNavigationType,
    txCodeValue: String? = nil
  ) {
    self.offerUri = offerUri
    self.issuerName = issuerName
    self.docOffers = docOffers
    self.successNavigation = successNavigation
    self.navigationCancelType = navigationCancelType
    self.txCodeValue = txCodeValue
  }
}
