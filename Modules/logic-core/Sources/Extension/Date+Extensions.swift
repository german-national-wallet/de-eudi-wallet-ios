//
//  Date+Extensions.swift
//  logic-core
//
import Foundation

extension Date {
  
  public func isWithinNextDays(_ days: Int) -> Bool {
    let calendar = Calendar.current
    
    guard let futureDate = calendar.date(byAdding: .day, value: days, to: Date()) else {
      return false
    }
    
    return self >= Date() && self <= futureDate
  }
  
  public func isBeyondNextDays(_ days: Int) -> Bool {
    let calendar = Calendar.current
    
    guard let futureDate = calendar.date(byAdding: .day, value: days, to: Date()) else {
      return false
    }
    
    return self > futureDate
  }
  
  public func isBeforeToday() -> Bool {
    let calendar = Calendar.current
    return calendar.compare(self, to: Date(), toGranularity: .day) == .orderedAscending
  }
  
  public func isValid() -> Bool {
    return self > Date()
  }
  
  public func isExpired() -> Bool {
    return self < Date()
  }
  
  public static func convertISO8601String(
    _ input: String,
    to outputFormat: String = "dd.MM.yyyy",
    locale: Locale = Locale(identifier: "de_DE")
  ) -> String? {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    guard let date = isoFormatter.date(from: input) ?? ISO8601DateFormatter().date(from: input) else {
        return nil
    }

    let outputFormatter = DateFormatter()
    outputFormatter.locale = locale
    outputFormatter.dateFormat = outputFormat
    return outputFormatter.string(from: date)
  }
  
  public func formatDate(format: String = "yyyy-dd-MM HH:mm:ss") -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: self)
  }
}

public enum DateFormatType: String {
  case ddMMYYYY = "dd.MM.YYYY"
  case yyyyMMdd = "yyyy-MM-dd"
  case iso8601DateTime = "yyyy-MM-dd'T'HH:mm:ssZ"
}
