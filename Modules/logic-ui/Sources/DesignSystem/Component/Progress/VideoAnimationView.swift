//
//  VideoAnimationView.swift
//  logic-ui
//

import SwiftUI
import AVFoundation
import logic_resources

public struct VideoAnimationView: View {

  public enum ContentMode {
    case fit
    case fill

    var videoGravity: AVLayerVideoGravity {
      switch self {
      case .fit: .resizeAspect
      case .fill: .resizeAspectFill
      }
    }
  }

  private let asset: VideoAsset
  private let size: CGFloat?
  private let contentMode: ContentMode
  private let playCount: Int?
  private let isPaused: Bool
  private let onFinished: (() -> Void)?

  public init(
    asset: VideoAsset,
    size: CGFloat? = nil,
    contentMode: ContentMode = .fit,
    playCount: Int? = 1,
    isPaused: Bool = false,
    onFinished: (() -> Void)? = nil
  ) {
    self.asset = asset
    self.size = size
    self.contentMode = contentMode
    self.playCount = playCount.map { max(1, $0) }
    self.isPaused = isPaused
    self.onFinished = onFinished
  }

  public var body: some View {
    Group {
      if let url = asset.url {
        PlayerLayerView(
          url: url,
          videoGravity: contentMode.videoGravity,
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

private struct PlayerLayerView: UIViewRepresentable {
  let url: URL
  let videoGravity: AVLayerVideoGravity
  let playCount: Int?
  let isPaused: Bool
  let onFinished: (() -> Void)?

  func makeUIView(context: Context) -> PlayerContainerView {
    let view = PlayerContainerView()
    view.backgroundColor = .clear
    view.videoGravity = videoGravity
    view.play(url: url, playCount: playCount, onFinished: onFinished)
    view.setPaused(isPaused)
    return view
  }

  func updateUIView(_ uiView: PlayerContainerView, context: Context) {
    uiView.videoGravity = videoGravity
    uiView.setPaused(isPaused)
  }

  static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: ()) {
    uiView.stop()
  }
}

final class PlayerContainerView: UIView {
  private let playerLayer = AVPlayerLayer()
  private var player: AVPlayer?
  private var endObserver: NSObjectProtocol?
  private var foregroundObserver: NSObjectProtocol?
  private var completedPlays = 0
  private var isUserPaused = false

  var videoGravity: AVLayerVideoGravity {
    get { playerLayer.videoGravity }
    set { playerLayer.videoGravity = newValue }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    playerLayer.videoGravity = .resizeAspect
    playerLayer.backgroundColor = UIColor.clear.cgColor
    layer.addSublayer(playerLayer)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    playerLayer.frame = bounds
  }

  func play(url: URL, playCount: Int?, onFinished: (() -> Void)?) {
    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.isMuted = true
    player.actionAtItemEnd = .pause
    self.player = player
    playerLayer.player = player
    completedPlays = 0

    endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      guard let self else { return }
      self.completedPlays += 1
      // A nil `playCount` never reaches its limit, so the video keeps repeating.
      if let playCount, self.completedPlays >= playCount {
        onFinished?()
      } else {
        self.player?.seek(to: .zero)
        if !self.isUserPaused {
          self.player?.play()
        }
      }
    }

    foregroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self, !self.isUserPaused else { return }
      self.player?.play()
    }

    player.play()
  }

  func setPaused(_ paused: Bool) {
    guard paused != isUserPaused else { return }
    isUserPaused = paused
    if paused {
      player?.pause()
    } else {
      player?.play()
    }
  }

  func stop() {
    player?.pause()
    if let endObserver {
      NotificationCenter.default.removeObserver(endObserver)
    }
    if let foregroundObserver {
      NotificationCenter.default.removeObserver(foregroundObserver)
    }
    endObserver = nil
    foregroundObserver = nil
    playerLayer.player = nil
    player = nil
  }
}
