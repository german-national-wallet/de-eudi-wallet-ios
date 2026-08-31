//
//  ProgressRingSupport.swift
//  logic-ui
//

import SwiftUI

/// Checkmark shown inside the ring once the work succeeded. Stroked like the ring itself, so the two
/// read as one drawing at any ring size.
struct SuccessCheck: View {
  var color: Color = Color(hex: 0x96F5AF)

  var body: some View {
    CheckPath()
      .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
  }
}

/// Cross shown inside the ring when the work failed.
struct ErrorX: View {
  let color: Color

  var body: some View {
    CrossPath()
      .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
  }
}

private struct CheckPath: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.width * 0.30, y: rect.height * 0.52))
    path.addLine(to: CGPoint(x: rect.width * 0.44, y: rect.height * 0.67))
    path.addLine(to: CGPoint(x: rect.width * 0.71, y: rect.height * 0.36))
    return path
  }
}

private struct CrossPath: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.34))
    path.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.66))
    path.move(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.34))
    path.addLine(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.66))
    return path
  }
}

/// Solves a CSS-style cubic-bezier easing curve, whose control points are `(p1x, p1y)` and
/// `(p2x, p2y)` between a fixed start of `(0, 0)` and end of `(1, 1)`.
/// - Returns: The eased value for the given progress `t`.
func cubicBezier(_ p1x: Double, _ p1y: Double, _ p2x: Double, _ p2y: Double, t: Double) -> Double {
  let progress = min(max(t, 0), 1)

  func axis(_ first: Double, _ second: Double, at parameter: Double) -> Double {
    let inverse = 1 - parameter
    return 3 * inverse * inverse * parameter * first
      + 3 * inverse * parameter * parameter * second
      + parameter * parameter * parameter
  }

  // The curve is monotonic in x, so a handful of bisection steps land close enough for animation and
  // cost less thought than Newton's method with its flat-slope edge cases.
  var lower = 0.0
  var upper = 1.0
  var parameter = progress

  for _ in 0..<16 {
    let x = axis(p1x, p2x, at: parameter)
    if abs(x - progress) < 0.0005 {
      break
    }
    if x < progress {
      lower = parameter
    } else {
      upper = parameter
    }
    parameter = (lower + upper) / 2
  }

  return axis(p1y, p2y, at: parameter)
}
