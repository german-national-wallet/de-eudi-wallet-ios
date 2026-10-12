//
//  LottieAsset.swift
//  logic-resources
//

import Foundation

public enum LottieAsset: String, CaseIterable, Sendable {
  case displayLockedSuccess = "display_locked_success"
  case displayLockedFailure = "display_locked_failure"
  case phoneLost = "phone_lost"
  case successInline = "success_inline"

  private static let fileExtension = "json"
  private static let subdirectory = "Animations"

  public var url: URL? {
    Bundle.assetsBundle.url(
      forResource: rawValue,
      withExtension: Self.fileExtension,
      subdirectory: Self.subdirectory
    ) ?? Bundle.assetsBundle.url(
      forResource: rawValue,
      withExtension: Self.fileExtension
    )
  }

  public var backgroundLayerNames: [String] {
    switch self {
    case .displayLockedSuccess, .displayLockedFailure:
      ["Shape Layer 1", "Shape Layer 2", "Shape Layer 4"]
    case .phoneLost, .successInline:
      []
    }
  }
}
