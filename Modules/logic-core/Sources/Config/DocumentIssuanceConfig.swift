//
//  DocumentIssuanceConfig.swift
//  logic-core
//

import EudiWalletKit

public struct DocumentIssuanceConfig {
  let defaultRule: DocumentIssuanceRule
  let documentSpecificRules: [DocumentTypeIdentifier: DocumentIssuanceRule]

  func rule(for documentIdentifier: DocumentTypeIdentifier?) -> DocumentIssuanceRule {
    guard let documentIdentifier, let rule = documentSpecificRules[documentIdentifier] else {
      return defaultRule
    }
    return rule
  }
}

struct DocumentIssuanceRule {
  let policy: CredentialPolicy
  let numberOfCredentials: Int
}
