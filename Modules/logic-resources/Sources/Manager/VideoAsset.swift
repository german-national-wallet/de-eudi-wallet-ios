//
//  VideoAsset.swift
//  logic-resources
//

import Foundation
import AVFoundation

public enum VideoAsset: String, CaseIterable, Sendable {
  case successInline = "03_Success_Inline"
  case errorInline = "04_Error_Inline"
  case nfcTappingTop = "06_NFC_Tapping_Top"
  case displayLockedSuccess = "01_Display_Locked_Success_iOS"
  case displayLockedFailure = "01_Display_Locked_Failure_iOS"
  case onboardingDigitalWallet = "onboarding_digital_wallet"
  case onboardingBenefits = "onboarding_benefits"
  case onboardingTrust = "onboarding_trust"

  private static let fileExtension = "mp4"
  private static let subdirectory = "Videos"

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

  public func duration() async -> TimeInterval? {
    guard let url else { return nil }
    guard let duration = try? await AVURLAsset(url: url).load(.duration) else { return nil }
    return duration.seconds
  }
}
