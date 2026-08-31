//
//  Logging.swift
//  logic-core
//

import Foundation

public enum LogLevel: String {
  case debug = "DEBUG"
  case error = "ERROR"
}

public protocol Logging: Sendable {
  func d(_ message: String, file: String, function: String, line: Int)
  func e(_ message: String, file: String, function: String, line: Int)
}

// Swift protocols can't have default parameter values. This extension with default parameters keeps the call site clean - logger.d("message")
public extension Logging {
  func d(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    d(message, file: file, function: function, line: line)
  }

  func e(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    e(message, file: file, function: function, line: line)
  }
}

public extension Error {
  /// A descriptor safe to write to logs that ship in release builds (e.g. SandboxRelease).
  ///
  /// Emits only the error type and the bridged NSError domain/code. It deliberately excludes
  /// `localizedDescription` and any associated values, which for network/issuer errors can carry
  /// response bodies or tokens. Use this instead of interpolating the raw error (`\(error)`) in
  /// any `logger.e(...)` call.
  var logDescriptor: String {
    let nsError = self as NSError
    return "\(type(of: self)) [\(nsError.domain)#\(nsError.code)]"
  }
}
