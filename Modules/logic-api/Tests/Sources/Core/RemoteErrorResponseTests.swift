//
//  RemoteErrorResponseTests.swift
//  logic-api
//

import Testing
import logic_resources

@testable import logic_api

@Suite
struct RemoteErrorResponseTests {

  @Test("The error icon is the default for shared error content")
  func defaultIcon() {
    let content = RemoteErrorResponseStruct(title: .globalErrorTitle, paragraph: .globalErrorParagraph)
    #expect(content.icon == .error)
  }

  @Test("An explicit icon is kept")
  func explicitIcon() {
    let content = RemoteErrorResponseStruct(title: .globalErrorTitle, paragraph: .globalErrorParagraph, icon: .info)
    #expect(content.icon == .info)
  }

  @Test("Backend errors always present with the error icon")
  func backendErrorContent() {
    let errors: [BackendError] = [
      .unknown,
      .notRegistered,
      .decodingFailed,
      .serverError(code: "X", description: "", traceID: "")
    ]
    for error in errors {
      #expect(error.errorContent.icon == .error, "\(error)")
      #expect(error.errorContent.title == .globalErrorTitle, "\(error)")
    }
  }
}
