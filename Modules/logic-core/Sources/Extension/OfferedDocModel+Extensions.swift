//
//  OfferedDocModel+Extensions.swift
//  logic-core
//

import Foundation
import OpenID4VCI
import EudiWalletKit
import MdocDataModel18013

public extension OfferedDocModel {
  /// Display metadata (name, background/text colors, logo) advertised for this offered
  /// credential, mapped to the same `DisplayMetadata` type used by issued documents.
  var displayMetadata: [DisplayMetadata]? {
    credentialMetadata?.display.map(\.displayMetadata)
  }

  var credentialLogoUrl: String? {
    displayMetadata?.first?.logo?.urlString
  }
}
