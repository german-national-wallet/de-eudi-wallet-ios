//
//  Bundle+Extensions.swift
//  logic-business
//
//  Created by Pankaj Sachdeva on 20.07.26.
//
import Foundation

public extension Bundle {
  static func getMainAppBundleID() -> String {
    guard let bundleID = Bundle.main.bundleIdentifier else {
      return ""
    }

    let isExtension = Bundle.main.bundlePath.contains(".appex")

    if isExtension {
      let components = bundleID.split(separator: ".")
      if components.count > 1 {
        return components.dropLast().joined(separator: ".")
      }
    }

    // In the main app, return the bundle identifier as-is
    return bundleID
  }

  /// App Group identifier shared between the main app and its extensions.
  static func getAppGroupIdentifier() -> String? {
    let mainAppBundleID = getMainAppBundleID()
    guard !mainAppBundleID.isEmpty else { return nil }
    return "group.\(mainAppBundleID)"
  }

  /// Gets the document storage service name using the main app bundle ID.
  static func getDocumentStorageServiceName() -> String {
    let mainAppBundleID = getMainAppBundleID()
    guard !mainAppBundleID.isEmpty else {
      return "eudi.document.storage"
    }
    return "\(mainAppBundleID).eudi.document.storage"
  }
}
