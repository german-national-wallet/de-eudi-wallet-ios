//
//  NetworkErrorTests.swift
//  logic-api
//

import Foundation
import Testing
import Alamofire

@testable import logic_api

@Suite
struct NetworkErrorTests {

  @Test("Only gateway timeouts and the rate limiter are transport status codes")
  func transportStatusCodes() {
    #expect(NetworkError.transportStatusCodes == [408, 429, 504])
    #expect(!NetworkError.transportStatusCodes.contains(503), "503 carries a service error envelope")
  }

  @Test("transportCause unwraps the URLError behind Alamofire's session error")
  func transportCauseFromAlamofire() {
    let sessionError = AFError.sessionTaskFailed(error: URLError(.timedOut))
    #expect(NetworkError.internetFailure(sessionError).transportCause?.code == .timedOut)
  }

  @Test("transportCause accepts a bare URLError and ignores anything else")
  func transportCauseFallbacks() {
    #expect(NetworkError.internetFailure(URLError(.cannotFindHost)).transportCause?.code == .cannotFindHost)
    struct Other: Error {}
    #expect(NetworkError.internetFailure(Other()).transportCause == nil)
    #expect(NetworkError.invalidResponse.transportCause == nil)
    #expect(NetworkError.httpError(code: 429, data: nil, headers: nil).transportCause == nil)
  }

  @Test("retryAfter reads the delta-seconds Retry-After header case-insensitively")
  func retryAfter() {
    #expect(NetworkError.httpError(code: 429, data: nil, headers: ["Retry-After": "120"]).retryAfter == 120)
    let lowercase = NetworkError.httpError(code: 429, data: nil, headers: ["retry-after": " 30 "])
    #expect(lowercase.retryAfter == 30)
    let httpDate = NetworkError.httpError(code: 429, data: nil, headers: ["Retry-After": "Wed, 21 Oct 2026 07:28:00 GMT"])
    #expect(httpDate.retryAfter == nil, "HTTP-date form is not supported")
    #expect(NetworkError.httpError(code: 429, data: nil, headers: nil).retryAfter == nil)
    #expect(NetworkError.internetFailure(URLError(.timedOut)).retryAfter == nil)
  }
}
