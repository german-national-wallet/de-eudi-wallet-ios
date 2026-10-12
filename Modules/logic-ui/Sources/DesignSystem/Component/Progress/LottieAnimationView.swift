//
//  LottieAnimationView.swift
//  logic-ui
//

import SwiftUI
import Lottie
import logic_resources

public struct LottieAnimationView: View {

  public enum ContentMode {
    case fit
    case fill

    var uiContentMode: UIView.ContentMode {
      switch self {
      case .fit: .scaleAspectFit
      case .fill: .scaleAspectFill
      }
    }
  }

  public enum LayerFilter: Equatable {
    case all
    case only([String])
    case excluding([String])
  }

  private let asset: LottieAsset
  private let size: CGFloat?
  private let contentMode: ContentMode
  private let layerFilter: LayerFilter
  private let playCount: Int?
  private let isPaused: Bool
  private let onFinished: (() -> Void)?

  public init(
    asset: LottieAsset,
    size: CGFloat? = nil,
    contentMode: ContentMode = .fit,
    layerFilter: LayerFilter = .all,
    playCount: Int? = 1,
    isPaused: Bool = false,
    onFinished: (() -> Void)? = nil
  ) {
    self.asset = asset
    self.size = size
    self.contentMode = contentMode
    self.layerFilter = layerFilter
    self.playCount = playCount.map { max(1, $0) }
    self.isPaused = isPaused
    self.onFinished = onFinished
  }

  public var body: some View {
    Group {
      if let url = asset.url {
        LottiePlayerView(
          url: url,
          contentMode: contentMode.uiContentMode,
          layerFilter: layerFilter,
          playCount: playCount,
          isPaused: isPaused,
          onFinished: onFinished
        )
      } else {
        Color.clear.onAppear { onFinished?() }
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

private struct LottiePlayerView: UIViewRepresentable {
  let url: URL
  let contentMode: UIView.ContentMode
  let layerFilter: LottieAnimationView.LayerFilter
  let playCount: Int?
  let isPaused: Bool
  let onFinished: (() -> Void)?

  func makeUIView(context: Context) -> LottieContainerView {
    let view = LottieContainerView()
    view.contentMode = contentMode
    view.load(url: url, layerFilter: layerFilter, playCount: playCount, onFinished: onFinished)
    view.setPaused(isPaused)
    return view
  }

  func updateUIView(_ uiView: LottieContainerView, context: Context) {
    uiView.contentMode = contentMode
    uiView.setPaused(isPaused)
  }

  static func dismantleUIView(_ uiView: LottieContainerView, coordinator: ()) {
    uiView.stop()
  }
}

final class LottieContainerView: UIView {
  private let animationView = Lottie.LottieAnimationView()
  private var isUserPaused = false
  private var hasLoaded = false

  override var contentMode: UIView.ContentMode {
    didSet { animationView.contentMode = contentMode }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    animationView.backgroundColor = .clear
    animationView.backgroundBehavior = .pauseAndRestore
    animationView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(animationView)
    NSLayoutConstraint.activate([
      animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
      animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
      animationView.topAnchor.constraint(equalTo: topAnchor),
      animationView.bottomAnchor.constraint(equalTo: bottomAnchor)
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func load(
    url: URL,
    layerFilter: LottieAnimationView.LayerFilter,
    playCount: Int?,
    onFinished: (() -> Void)?
  ) {
    guard let animation = LottieAnimation.filepath(url.path) else {
      onFinished?()
      return
    }
    animationView.animation = animation
    animationView.loopMode = playCount.map { .repeat(Float($0)) } ?? .loop
    hideLayers(excludedBy: layerFilter)
    hasLoaded = true
    guard !isUserPaused else { return }
    animationView.play { finished in
      guard finished, playCount != nil else { return }
      onFinished?()
    }
  }

  func setPaused(_ paused: Bool) {
    isUserPaused = paused
    guard hasLoaded else { return }
    if paused {
      animationView.pause()
    } else if !animationView.isAnimationPlaying {
      animationView.play()
    }
  }

  func stop() {
    animationView.stop()
  }

  private func hideLayers(excludedBy filter: LottieAnimationView.LayerFilter) {
    let hiddenLayers: Set<String>
    switch filter {
    case .all:
      return
    case .excluding(let names):
      hiddenLayers = Set(names)
    case .only(let names):
      hiddenLayers = topLevelLayerNames.subtracting(names)
    }
    for name in hiddenLayers {
      animationView.setValueProvider(
        FloatValueProvider(0),
        keypath: AnimationKeypath(keypath: "\(name).Transform.Opacity")
      )
    }
  }

  private var topLevelLayerNames: Set<String> {
    Set(
      animationView.allHierarchyKeypaths().compactMap {
        $0.components(separatedBy: ".").first
      }
    )
  }
}
