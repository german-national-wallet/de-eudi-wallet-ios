//
//  DebugLogger.swift
//  logic-core
//

import Foundation
import Logging

let logger = Logger(label: "WalletApp")

public final class DebugLogger: Logging, Sendable {

  private static let emitsDebugLogs = AppBuildVariant.current.emitsDebugLogs

  public func d(_ message: String, file: String, function: String, line: Int) {
    guard DebugLogger.emitsDebugLogs else { return }
    log(message, level: .debug, file: file, function: function, line: line)
  }

  public func e(_ message: String, file: String, function: String, line: Int) {
    // Error-level logs are emitted in every build configuration (including release builds such as
    // SandboxRelease produced by Xcode Cloud) so issues can be diagnosed from the exported wallet log.
    // Because these ship in release, callers MUST pass only non-sensitive text — never interpolate a
    // raw error or PII. Use Error.logDescriptor (type + domain/code) for error details.
    log(message, level: .error, file: file, function: function, line: line)
  }

  private func log(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
    let filename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
    let formatted = "[\(level.rawValue)] [\(filename):\(line) \(function)] \(message)"
    let wrappedMessage = Logger.Message(stringLiteral: formatted)
    // OSLogBridge added to support debugging during automation testing
    switch level {
    case .debug:
      logger.info(wrappedMessage)
      OSLogBridge.debug(formatted)
    case .error:
      logger.error(wrappedMessage)
      OSLogBridge.error(formatted)
    }
  }
}
