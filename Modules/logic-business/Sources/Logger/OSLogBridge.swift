//
//  Logging.swift
//  logic-core
//
//  Mirrors app logs to Apple's unified logging.
//  swift-log's default handler writes to the app process's stdout, which is invisible during
//  UI tests because the app runs as a separate process from the test runner. Emitting to the
//  unified log makes those logs streamable while a UI test runs:
//
//    xcrun simctl spawn booted log stream --level debug --predicate 'subsystem == "WalletApp"'
//
//  or by filtering subsystem "WalletApp" in Console.app.
//

import os

enum OSLogBridge {
  private static let logger = Logger(subsystem: "WalletApp", category: "app")

  // `.public` so the message isn't redacted as <private> when streamed.
  static func debug(_ message: String) {
    logger.debug("\(message, privacy: .public)")
  }

  static func error(_ message: String) {
    logger.error("\(message, privacy: .public)")
  }
}
