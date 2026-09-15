//
//  AppIntroPage.swift
//  feature-startup
//

import logic_resources

enum AppIntroPage: Int, CaseIterable, Equatable, Sendable {
  case digitalWallet
  case benefits
  case trust

  var number: Int { rawValue + 1 }

  static var count: Int { allCases.count }

  var next: AppIntroPage? {
    AppIntroPage(rawValue: rawValue + 1)
  }

  var isLast: Bool { next == nil }

  var videoAsset: VideoAsset {
    switch self {
    case .digitalWallet: .onboardingDigitalWallet
    case .benefits: .onboardingBenefits
    case .trust: .onboardingTrust
    }
  }

  var title: LocalizableStringKey {
    switch self {
    case .digitalWallet: .appOnboardingOnboarding1Title
    case .benefits: .appOnboardingOnboarding2Title
    case .trust: .appOnboardingOnboarding4Title
    }
  }

  var body: LocalizableStringKey {
    switch self {
    case .digitalWallet: .appOnboardingOnboarding1Paragraph
    case .benefits: .appOnboardingOnboarding2Paragraph
    case .trust: .appOnboardingOnboarding4Paragraph
    }
  }

  var primaryButtonTitle: LocalizableStringKey {
    switch self {
    case .digitalWallet: .appOnboardingOnboarding1PrimButton
    case .benefits: .appOnboardingOnboarding2PrimButton
    case .trust: .appOnboardingOnboarding4PrimButton
    }
  }

  var tertiaryButtonTitle: LocalizableStringKey? {
    switch self {
    case .digitalWallet: .appOnboardingOnboarding1TertiaryButton
    case .benefits: .appOnboardingOnboarding2TertiaryButton
    case .trust: nil
    }
  }

  var showsBackButton: Bool { self != .digitalWallet }

  var primaryButtonHasArrow: Bool { isLast }
}
