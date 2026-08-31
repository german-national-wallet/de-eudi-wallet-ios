//
//  File.swift
//  DesignSystem
//

import CoreGraphics
import CoreText
import UIKit

public struct CustomFonts {
  public init() { }
  
  public func loadFonts() {
    let fontNames = [
      "EUDIDiatype-Regular",
      "EUDIDiatype-Bold",
      "EUDIDiatypeWide-Semibold",
      "EUDIDiatypeSemiMono-Medium",
      "EUDIDiatypeSemiExtended-Bold"
    ]
    fontNames.forEach {
      registerFont(withName: $0, fileExtension: "ttf")
    }
  }
  
  private func registerFont(withName name: String, fileExtension: String) {
    let frameworkBundle = Bundle.module
    guard let url = frameworkBundle.url(forResource: name, withExtension: fileExtension),
          let fontDataProvider = CGDataProvider(url: url as CFURL),
          let font = CGFont(fontDataProvider)
    else {
      return
    }

    CTFontManagerRegisterGraphicsFont(font, nil)
  }
}
