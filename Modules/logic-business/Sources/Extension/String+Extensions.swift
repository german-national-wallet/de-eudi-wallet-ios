/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import CryptoKit
import CommonCrypto
import SwiftUI

public extension String {
  func capitalizedFirst() -> String {
    guard let firstCharacter = self.first else { return "" }
    return firstCharacter.uppercased() + self.dropFirst().lowercased()
  }

  func toJSON() -> Any? {
    guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
  }

  func urlEncode() -> String {
    return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
  }

  func loadFileFromBundle() -> String? {
    let path = self.components(separatedBy: ".")
    guard
      let fileName = path.first,
      let fileExtension = path.last
    else {
      return nil
    }
    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension),
          let data = try? Data(contentsOf: fileURL),
          let string = String(data: data, encoding: .utf8) else {
      return nil
    }
    return string
  }
}

public extension String {

  private var formatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 2
    formatter.decimalSeparator = "."
    formatter.usesGroupingSeparator = false
    formatter.roundingMode = .floor
    return formatter
  }

  func toInteger() -> Int? {
    return Int(self)
  }

  func toNumeric() -> String {
    if self.toInteger() != nil {
      return self
    } else {
      var text = NSMutableString(string: self)
      if let regex = try? NSRegularExpression(pattern: "[^0-9]") {
        regex.replaceMatches(in: text, options: .reportProgress, range: NSRange(location: 0, length: text.length), withTemplate: "")
      } else {
        text = ""
      }
      return String(text)
    }
  }

  func toAmount() -> String? {
    if let number = formatter.number(from: self) {
      return formatter.string(from: number)
    }
    return nil
  }
}

public extension String {
  func countInstances(of stringToFind: String) -> Int {
    assert(!stringToFind.isEmpty)
    var count = 0
    var searchRange: Range<String.Index>?
    while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
      count += 1
      searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
    }
    return count
  }
}

public extension String {
  func equals(_ valueToMatch: String, ignoreCase: Bool = false) -> Bool {
    if ignoreCase {
      return self.caseInsensitiveCompare(valueToMatch) == .orderedSame
    } else {
      return self == valueToMatch
    }
  }

  func match(_ regex: String) -> [[String]] {
    let nsString = self as NSString
    return (try? NSRegularExpression(pattern: regex, options: []))?.matches(in: self, options: [], range: NSRange(location: 0, length: nsString.length)).map { match in
      (0..<match.numberOfRanges).map { match.range(at: $0).location == NSNotFound ? "" : nsString.substring(with: match.range(at: $0)) }
    } ?? []
  }
}

public extension String? {
  var orEmpty: String {
    guard let self = self else {
      return ""
    }
    return self
  }
  func ifNil(_ fallback: () -> String) -> String {
    guard let self = self else {
      return fallback()
    }
    return self
  }
  func ifNilOrEmpty(_ fallback: () -> String) -> String {
    guard let self = self, !self.isEmpty else {
      return fallback()
    }
    return self
  }
}

public extension String {
  func padded(toWidth width: Int, withPad pad: String = " ", startingAt start: Int = 0) -> String {
    let padLength = width - self.count
    guard padLength > 0 else { return self }

    let padding = String(repeating: pad, count: padLength)
    return padding + self
  }

  func padded(withPad pad: String = " ", padLength: Int) -> String {
    guard padLength > 0 else { return self }

    let padding = String(repeating: pad, count: padLength)
    return self + padding
  }
}

public extension String {
  var valueFromBundle: String {
    Bundle.main.infoDictionary?[self] as? String ?? ""
  }

  var optionalValueFromBundle: String? {
    guard let value = Bundle.main.infoDictionary?[self] as? String, !value.isEmpty else {
      return nil
    }
    return value
  }
}

public extension String {

  var decodeBase64: String? {
    guard
      let data = Data(base64Encoded: self),
      let decoded = String(data: data, encoding: .utf8)
    else {
      return nil
    }
    return decoded
  }

  var toBase64: String? {
    guard
      let data = self.data(using: .utf8)
    else {
      return nil
    }
    return data.base64EncodedString()
  }
    
  var decodeBase64Data: Data? {
    var base64 = self
    .replacingOccurrences(of: "-", with: "+")
    .replacingOccurrences(of: "_", with: "/")
            
    let missingPadding = base64.count % 4
     if missingPadding > 0 {
        base64.append(String(repeating: "=", count: 4 - missingPadding))
       }
     return Data(base64Encoded: base64)
    }
}

public extension String? {

  func isNilOrEmpty() -> Bool {
    return self == nil || self?.isEmpty == true
  }

}

public extension String {
  func toCompatibleUrl() -> URL? {
    guard let decoded = self.removingPercentEncoding else { return nil }
    return if let url = URL(string: decoded) {
      url
    } else if let encodedString = decoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encodedString) {
      url
    } else {
      nil
    }
  }
}

extension String {
    public func toHashedStringWithSha256() -> String {
        let digest = SHA256.hash(data: self.data(using: .utf8)!)
        return Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        
    }
}

extension String {
    public func toFormattedDateString(from inputFormat: String = "yyyy-MM-dd", to outputFormat: String = "dd. MMM yyyy", locale: Locale = Locale(identifier: "en_US")) -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = inputFormat
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")

        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = outputFormat
        outputFormatter.locale = locale

        guard let date = inputFormatter.date(from: self) else { return nil }
        return outputFormatter.string(from: date)
    }
}

extension String {
  public func convertStringTimestampToDate() -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard let date = formatter.date(from: self) else {
      return nil
    }
    return date
  }
  
  public func isValidISODate() -> Bool {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [
          .withInternetDateTime,
          .withDashSeparatorInDate,
          .withColonSeparatorInTime
      ]
      
      return formatter.date(from: self) != nil
  }
  
  public func isInFuture() -> Bool {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard let date = formatter.date(from: self) else {
        return false
    }
    return date > Date()
  }

  public func timeDifference(to endTimestamp: String) -> String? {
    func trimToMicroseconds(_ dateStr: String) -> String {
        if let dotRange = dateStr.range(of: ".") {
            let prefix = dateStr[..<dotRange.lowerBound]
            let fractionStart = dateStr[dotRange.upperBound...]
            let trimmedFraction = String(fractionStart.prefix(6))
            return prefix + "." + trimmedFraction + "Z"
        }
        return dateStr.hasSuffix("Z") ? dateStr : dateStr + "Z"
    }

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    let startFixed = trimToMicroseconds(self)
    let endFixed = trimToMicroseconds(endTimestamp)

    guard let startDate = formatter.date(from: startFixed),
          let endDate = formatter.date(from: endFixed) else {
        return nil
    }

    let diff = Int(endDate.timeIntervalSince(startDate))
    guard diff >= 0 else { return "00:00:00" }

    let hours = diff / 3600
    let minutes = (diff % 3600) / 60
    let seconds = diff % 60

    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
}

public extension String {
  func extractBoldAndRegularText(font: Font) -> Text {
    let pattern = #"\*\*(.*?)\*\*"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: self, range: NSRange(self.startIndex..., in: self)),
          let boldRange = Range(match.range(at: 1), in: self),
          let fullRange = Range(match.range, in: self) else {
        return Text(self).font(font) // fallback: full string
    }

    let boldText = String(self[boldRange])
    let afterBold = String(self[fullRange.upperBound..<self.endIndex])

    let boldPart = Text(boldText).font(font).fontWeight(.bold)
    return boldPart + Text(afterBold).font(font)
  }
}

public extension String {
  var normalizedHTTPHeaderKey: String {
    lowercased()
      .replacingOccurrences(of: "-", with: "_")
      .filter { $0.isLetter || $0.isNumber || $0 == "_" }
  }

  func toBase64URL() -> String {
    replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}

public extension String {

  /// ISO 8601 temporal duration string support
  /// Kept minimal to avoid adding a third-party for this
  /// Docs: https://tc39.es/proposal-temporal/docs/duration.html
  func minutesFromISO8601DurationString() -> Int? {
    let value = uppercased()
    let normalized: String
    if value.hasPrefix("P") {
      normalized = value
    } else if value.hasPrefix("DT") {
      normalized = "P\(value.dropFirst())"
    } else if value.hasPrefix("T") {
      normalized = "P\(value)"
    } else {
      return nil
    }

    let pattern = #"^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      return nil
    }

    let range = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
    guard let match = regex.firstMatch(in: normalized, range: range) else {
      return nil
    }
    let hasComponent = (1...4).contains { match.range(at: $0).location != NSNotFound }
    guard hasComponent else { return nil }

    func intValue(at index: Int) -> Int {
      let nsRange = match.range(at: index)
      guard
        nsRange.location != NSNotFound,
        let range = Range(nsRange, in: normalized),
        let value = Int(normalized[range])
      else {
        return 0
      }
      return value
    }

    let days = intValue(at: 1)
    let hours = intValue(at: 2)
    let minutes = intValue(at: 3)
    let seconds = intValue(at: 4)
    let totalMinutes = (days * 24 * 60) + (hours * 60) + minutes + (seconds / 60)
    return totalMinutes
  }
}
