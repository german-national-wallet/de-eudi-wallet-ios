//
//  OnboardingIllustrationView.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct OnboardingIllustrationView: View {

  public enum Content {
    case animation(LottieAsset, stretchesBackground: Bool, playCount: Int? = 1)
    case video(VideoAsset)
    case image(Image)
  }

  private let content: Content

  private let aspectRatio: CGFloat = 16 / 9

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init(asset: LottieAsset, stretchesBackground: Bool = false, playCount: Int? = 1) {
    self.content = .animation(asset, stretchesBackground: stretchesBackground, playCount: playCount)
  }

  public init(video: VideoAsset) {
    self.content = .video(video)
  }

  public init(image: Image) {
    self.content = .image(image)
  }

  public var body: some View {
    RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xLarge1)
      .fill(DSColor.surfaceContainer)
      .frame(maxWidth: .infinity)
      .aspectRatio(aspectRatio, contentMode: .fit)
      .overlay {
        illustration
      }
      .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xLarge1))
      .accessibilityHidden(true)
  }

  @ViewBuilder
  private var illustration: some View {
    switch content {
    case .animation(let asset, let stretchesBackground, let playCount):
      if stretchesBackground, !asset.backgroundLayerNames.isEmpty {
        ZStack {
          GeometryReader { proxy in
            animation(asset, layerFilter: .only(asset.backgroundLayerNames), playCount: playCount)
              .frame(width: proxy.size.width, height: proxy.size.width)
              .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
          }
          animation(asset, layerFilter: .excluding(asset.backgroundLayerNames), playCount: playCount)
        }
      } else {
        animation(asset, layerFilter: .all, playCount: playCount)
      }
    case .video(let asset):
      VideoAnimationView(
        asset: asset,
        contentMode: .fill,
        playCount: 1,
        isPaused: reduceMotion
      )
    case .image(let image):
      image
        .resizable()
        .aspectRatio(contentMode: .fill)
    }
  }

  private func animation(
    _ asset: LottieAsset,
    layerFilter: LottieAnimationView.LayerFilter,
    playCount: Int?
  ) -> some View {
    LottieAnimationView(
      asset: asset,
      contentMode: .fit,
      layerFilter: layerFilter,
      playCount: playCount,
      isPaused: reduceMotion
    )
  }
}
