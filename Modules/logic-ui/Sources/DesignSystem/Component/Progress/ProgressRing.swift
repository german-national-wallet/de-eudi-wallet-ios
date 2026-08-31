//
//  ProgressRing.swift
//  logic-ui
//
//  Imported from a code snippet provided by M&M (https://eudi-motion.vercel.app/styleguide-06-loading.html)

import SwiftUI

public enum ProgressState { case loading, success, error }

struct ProgressRing: View {
  let state: ProgressState
  var size: CGFloat = 48
  var onDarkSurface: Bool = false

  private let cycleSec: TimeInterval = 7.0
  private let rotSec: TimeInterval = 1.15
  private let breathSec: TimeInterval = 3.15
  private let pathLen: CGFloat      = 138
  private let dashMin: CGFloat      = 20
  private let dashMax: CGFloat      = 60

  /// End of the spinning window, which the loading phase is held at for as long as it lasts.
  private let spinEnd: Double = 0.47
  /// Start of the head's exit, where an outcome picks the cycle up.
  private let outcomeStart: Double = 0.48

  private let trackColor = Color(hex: 0x96F5AF)
  private let headColor  = Color(hex: 0x329D77)
  private var errorColor: Color {
    Color(hex: onDarkSurface ? 0xCB8179 : 0x950F00)
  }

  /// When the current state began, so the phases follow the state rather than the wall clock.
  @State private var phaseStart: TimeInterval?

  var body: some View {
    TimelineView(.animation) { ctx in
      let now = ctx.date.timeIntervalSinceReferenceDate
      let t   = phase(at: now)
      let rot = (now.truncatingRemainder(dividingBy: rotSec))   / rotSec * 360
      let br  = breath(at: now)

      ZStack {
        Circle()
          .stroke(trackStroke(t: t), style: StrokeStyle(lineWidth: 4, lineCap: .round))
          .padding(2)
          .opacity(trackOpacity(t: t))
        Circle()
          .trim(from: 0, to: br / pathLen)
          .stroke(headColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
          .padding(2)
          .rotationEffect(.degrees(rot - 90))
          .opacity(headOpacity(t: t))
        Group {
          if state == .success {
            SuccessCheck()
          } else if state == .error {
            ErrorX(color: errorColor)
          }
        }
        .scaleEffect(glyphScale(t: t))
        .opacity(glyphOpacity(t: t))
      }
      .frame(width: size, height: size)
    }
    .onAppear { phaseStart = Date.timeIntervalSinceReferenceDate }
    .onChange(of: state) { _ in phaseStart = Date.timeIntervalSinceReferenceDate }
  }

  /// Position in the cycle, measured from the moment the state began.
  ///
  /// Loading holds at the end of the spinning window, as a load lasts as long as it lasts, and an
  /// outcome runs from the head's exit to the fade-out once, rather than wherever the clock stands.
  private func phase(at now: TimeInterval) -> Double {
    let elapsed = max(now - (phaseStart ?? now), 0) / cycleSec

    return switch state {
    case .loading: min(elapsed, spinEnd)
    case .success, .error: min(outcomeStart + elapsed, 1.0)
    }
  }

  // Phase math (t in 0...1 over a 7 s cycle)
  private func trackOpacity(t: Double) -> Double {
    switch t {
    case   ..<0.04: return t / 0.04
    case 0.04..<0.93: return 1
    case 0.93..<0.97: return 1 - (t - 0.93) / 0.04
    default:        return 0
    }
  }
  private func headOpacity(t: Double) -> Double {
    if state == .loading { return trackOpacity(t: t) }
    switch t {
    case   ..<0.04: return t / 0.04
    case 0.04..<0.48: return 1
    default:        return 0
    }
  }
  private func glyphOpacity(t: Double) -> Double {
    if state == .loading { return 0 }
    switch t {
    case 0.50..<0.53: return (t - 0.50) / 0.03
    case 0.53..<0.93: return 1
    case 0.93..<0.97: return 1 - (t - 0.93) / 0.04
    default:        return 0
    }
  }
  private func glyphScale(t: Double) -> Double {
    switch t {
    case 0.50..<0.53: return 0.7 + (1.04 - 0.7) * (t - 0.50) / 0.03
    case 0.53..<0.57: return 1.04 - 0.04 * (t - 0.53) / 0.04
    case 0.57..<0.93: return 1.0
    case 0.93..<0.97: return 1.0 - 0.3 * (t - 0.93) / 0.04
    default:        return 0.7
    }
  }
  private func trackStroke(t: Double) -> Color {
    if state == .error && t >= 0.50 && t < 1.00 { return errorColor }
    return trackColor
  }
  private func breath(at refTime: TimeInterval) -> CGFloat {
    let u   = refTime.truncatingRemainder(dividingBy: breathSec) / breathSec
    let tri = u < 0.5 ? (u * 2) : (2 - u * 2)
    let e   = cubicBezier(0.42, 0, 0.58, 1, t: tri)
    return dashMin + (dashMax - dashMin) * CGFloat(e)
  }
}
