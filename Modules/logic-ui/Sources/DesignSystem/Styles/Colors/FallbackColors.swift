//
//  FallbackColors.swift
//  logic-ui
//

import Foundation
import logic_core

public extension DesignSystem.Styles.Colors {
  static func getBackgroundColorForCredential(document: DocClaimsDecodable) -> Color {
    getBackgroundColorForCredential(display: document.display, id: document.id)
  }

  static func getBackgroundColorForCredential(display: [DisplayMetadata]?, id: String) -> Color {
    if let hex = display?.first?.backgroundColor, !hex.isEmpty {
      return Color(hex: hex)
    } else {
      return tertiaryContainer
    }
  }
}
