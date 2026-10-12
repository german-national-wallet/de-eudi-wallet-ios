//
//  NetworkLoggerTests.swift
//  logic-api
//

import Foundation
import Testing
import logic_business

@testable import logic_api

struct NetworkLoggerTests {

  private let url = URL(string: "https://example.com/logo.png")!

  @Test
  func log_DoesNotCrash_WhenResponseBodyIsNonFormTextContainingEquals() {
    let logger = LoggingSpy()
    let body = Data(#"<?xml version="1.0" encoding="UTF-8"?><Error><Code>NoSuchBucket</Code></Error>"#.utf8)

    NetworkLogger(logger: logger).log(
      request: URLRequest(url: url),
      responseData: body,
      responseHeader: HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)
    )

    #expect(logger.messages.count == 1)
    #expect(logger.messages.first?.contains("Response Body: [body not logged, \(body.count) bytes]") == true)
  }

  @Test
  func log_ParsesFormBody() {
    let logger = LoggingSpy()
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = Data("grant_type=urn:ietf:params:oauth:grant-type:pre-authorized_code&client_id=wallet+client".utf8)

    NetworkLogger(logger: logger).log(request: request, responseHeader: nil)

    #expect(logger.messages.first?.contains("Body: grant_type=urn:ietf:params:oauth:grant-type:pre-authorized_code&client_id=wallet client") == true)
  }
}

private final class LoggingSpy: Logging, @unchecked Sendable {
  private(set) var messages: [String] = []

  func d(_ message: String, file: String, function: String, line: Int) {
    messages.append(message)
  }

  func e(_ message: String, file: String, function: String, line: Int) {
    messages.append(message)
  }
}
