//
//  IntroConfig.swift
//  feature-common
//

import SwiftUI

public struct IntroConfig {

  /// Which intro layout to render.
  public enum Style: Equatable, Sendable {
    /// Stepped-flow layout: header shows a step-progress bar, inline card illustration.
    /// Only for screens that really sit at `currentStep` of a `totalSteps` flow -
    /// the bar is drawn from these numbers, so a placeholder count misinforms.
    case stepped(currentStep: Int, totalSteps: Int)
    /// Same layout as `stepped`, without the step-progress bar. For standalone
    /// screens that are not part of a counted flow.
    case plain
    /// Illustration-led layout: prominent illustration frame, no progress bar.
    case illustrated
  }

  /// A tappable button. Rendered only when supplied in the config.
  public struct Action {
    public let title: String
    public let accessibilityId: String?
    public let handler: () -> Void

    public init(
      title: String,
      accessibilityId: String? = nil,
      handler: @escaping () -> Void
    ) {
      self.title = title
      self.accessibilityId = accessibilityId
      self.handler = handler
    }
  }

  public var style: Style
  public var title: String
  public var titleAccessibilityId: String?
  public var body: String?
  public var bannerText: String?
  /// Optional illustration override. When nil, each layout falls back to its default asset.
  public var illustration: Image?
  /// Width of the stepped layout's inline illustration as a fraction of the available
  /// content width (0...1). Height scales proportionally. Ignored by the illustrated layout.
  public var illustrationWidthFactor: CGFloat
  public var primaryAction: Action?
  public var secondaryAction: Action?
  public var onBack: (() -> Void)?
  public var onHelp: (() -> Void)?
  public var onClose: (() -> Void)?

  public init(
    style: Style = .plain,
    title: String,
    titleAccessibilityId: String? = nil,
    body: String? = nil,
    bannerText: String? = nil,
    illustration: Image? = nil,
    illustrationWidthFactor: CGFloat = 0.5,
    primaryAction: Action? = nil,
    secondaryAction: Action? = nil,
    onBack: (() -> Void)? = nil,
    onHelp: (() -> Void)? = nil,
    onClose: (() -> Void)? = nil
  ) {
    self.style = style
    self.title = title
    self.titleAccessibilityId = titleAccessibilityId
    self.body = body
    self.bannerText = bannerText
    self.illustration = illustration
    self.illustrationWidthFactor = illustrationWidthFactor
    self.primaryAction = primaryAction
    self.secondaryAction = secondaryAction
    self.onBack = onBack
    self.onHelp = onHelp
    self.onClose = onClose
  }
}
