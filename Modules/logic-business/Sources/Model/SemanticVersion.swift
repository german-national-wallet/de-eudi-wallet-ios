//
//  SemanticVersion.swift
//  SemanticVersion
//

import Foundation

public struct SemanticVersion: Comparable, Sendable {

  public let major: Int
  public let minor: Int
  public let patch: Int
  public let prereleaseIdentifiers: [String]

  public init?(_ value: String) {
    let pattern = #"^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9A-Za-z-][0-9A-Za-z-]*))*))?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$"#
    guard
      let regex = try? NSRegularExpression(pattern: pattern),
      let match = regex.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
      let majorRange = Range(match.range(at: 1), in: value),
      let minorRange = Range(match.range(at: 2), in: value),
      let patchRange = Range(match.range(at: 3), in: value),
      let major = Int(value[majorRange]),
      let minor = Int(value[minorRange]),
      let patch = Int(value[patchRange])
    else {
      return nil
    }

    self.major = major
    self.minor = minor
    self.patch = patch
    if
      match.range(at: 4).location != NSNotFound,
      let prereleaseRange = Range(match.range(at: 4), in: value) {
      self.prereleaseIdentifiers = value[prereleaseRange].split(separator: ".").map(String.init)
    } else {
      self.prereleaseIdentifiers = []
    }
  }

  public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
    if lhs.major != rhs.major { return lhs.major < rhs.major }
    if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
    if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }
    return lhs.hasLowerPrecedenceThanVersionWithSameCore(rhs)
  }

  private func hasLowerPrecedenceThanVersionWithSameCore(_ other: SemanticVersion) -> Bool {
    if prereleaseIdentifiers.isEmpty {
      return false
    }
    if other.prereleaseIdentifiers.isEmpty {
      return true
    }

    for (left, right) in zip(prereleaseIdentifiers, other.prereleaseIdentifiers) {
      if left == right { continue }

      let leftNumber = Int(left)
      let rightNumber = Int(right)
      switch (leftNumber, rightNumber) {
      case let (leftNumber?, rightNumber?):
        return leftNumber < rightNumber
      case (_?, nil):
        return true
      case (nil, _?):
        return false
      case (nil, nil):
        return left < right
      }
    }

    return prereleaseIdentifiers.count < other.prereleaseIdentifiers.count
  }
}
