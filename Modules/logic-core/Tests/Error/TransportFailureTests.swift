//
//  TransportFailureTests.swift
//  logic-core
//

import Testing
import Foundation
import enum logic_api.NetworkError
import enum OpenID4VCI.FetchError
import enum OpenID4VCI.PostError
import enum OpenID4VP.PostError
import enum OpenID4VP.ValidationError
import struct OpenID4VP.NetworkFailure
@testable import logic_core

@Suite("TransportFailure")
struct TransportFailureTests {

  private let url = URL(string: "https://verifier.example/request.jwt")!

  private func nested(_ inner: Error) -> Error {
    let service = WalletError(description: "OpenID4VP request error", code: .invalidRequest, innerError: inner)
    return WalletError(description: service.description, code: .invalidRequest, innerError: service)
  }

  private func requestFetch(_ failure: NetworkFailure) -> Error {
    nested(ValidationError.networkError(failure))
  }

  // MARK: - OpenID4VP request object fetch

  @Test("A timed-out request object fetch is an OpenID4VP request timeout")
  func requestFetchTimeout() {
    let error = requestFetch(.init(stage: .GET, url: url, underlying: URLError(.timedOut)))
    #expect(TransportFailure.find(in: error) == .init(kind: .timeout, source: .openID4VPRequest))
  }

  @Test("DNS and connection failures while fetching the request object are unreachable")
  func requestFetchUnreachable() {
    for code: URLError.Code in [.cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .networkConnectionLost] {
      let error = requestFetch(.init(stage: .POST, url: url, underlying: URLError(code)))
      #expect(TransportFailure.find(in: error) == .init(kind: .unreachable, source: .openID4VPRequest), "\(code)")
    }
  }

  @Test("A 408 or 504 from the verifier is a timeout that keeps the status code")
  func requestFetchServerTimeout() {
    for status in [408, 504] {
      let error = requestFetch(.init(stage: .GET, url: url, statusCode: status))
      #expect(
        TransportFailure.find(in: error) == .init(kind: .timeout, source: .openID4VPRequest, statusCode: status)
      )
    }
  }

  @Test("A 429 from the verifier is rate limiting without a retry hint")
  func requestFetchRateLimited() {
    let error = requestFetch(.init(stage: .GET, url: url, statusCode: 429))
    let failure = TransportFailure.find(in: error)
    #expect(failure == .init(kind: .rateLimited, source: .openID4VPRequest, statusCode: 429))
    #expect(failure?.retryAfter == nil)
  }

  @Test("Other verifier status codes are left to the classifier")
  func requestFetchOtherStatusIsNotTransport() {
    for status in [400, 401, 403, 404, 410, 500, 503] {
      let error = requestFetch(.init(stage: .GET, url: url, statusCode: status))
      #expect(TransportFailure.find(in: error) == nil, "\(status)")
    }
  }

  @Test("Transport errors the mapping does not know are left to the classifier")
  func requestFetchUnknownURLErrorIsNotTransport() {
    let error = requestFetch(.init(stage: .GET, url: url, underlying: URLError(.cancelled)))
    #expect(TransportFailure.find(in: error) == nil)
  }

  // MARK: - OpenID4VP response dispatch

  @Test("A timed-out response post is an OpenID4VP response timeout")
  func responseDispatchTimeout() {
    let error = nested(OpenID4VP.PostError.networkError(URLError(.timedOut)))
    #expect(TransportFailure.find(in: error) == .init(kind: .timeout, source: .openID4VPResponse))
  }

  @Test("An unreachable response_uri is an OpenID4VP response unreachable failure")
  func responseDispatchUnreachable() {
    let error = nested(OpenID4VP.PostError.networkError(URLError(.cannotConnectToHost)))
    #expect(TransportFailure.find(in: error) == .init(kind: .unreachable, source: .openID4VPResponse))
  }

  @Test("A 504 on the response post is a response timeout with status")
  func responseDispatchGatewayTimeout() {
    let error = nested(OpenID4VP.PostError.invalidStatusCode(url, 504, nil))
    #expect(
      TransportFailure.find(in: error) == .init(kind: .timeout, source: .openID4VPResponse, statusCode: 504)
    )
  }

  @Test("Non-transport post errors are not transport failures")
  func responseDispatchOtherPostErrors() {
    #expect(TransportFailure.find(in: nested(OpenID4VP.PostError.invalidResponse)) == nil)
    #expect(TransportFailure.find(in: nested(OpenID4VP.PostError.invalidUrl)) == nil)
    #expect(TransportFailure.find(in: nested(OpenID4VP.PostError.invalidStatusCode(url, 400, nil))) == nil)
  }

  // MARK: - Wallet backend (logic-api NetworkManager)

  @Test("A backend call that never got a response is attributed to the wallet backend")
  func walletBackendTransport() {
    let cause = NetworkError.internetFailure(URLError(.timedOut))
    let timedOut = WalletError(description: "registration", code: .internalError, innerError: cause)
    #expect(TransportFailure.find(in: timedOut) == .init(kind: .timeout, source: .walletBackend))
  }

  @Test("A typed gateway or rate-limit answer keeps its status and Retry-After")
  func walletBackendStatus() {
    let rateLimited = NetworkError.httpError(code: 429, data: nil, headers: ["Retry-After": "60"])
    let expected = TransportFailure(kind: .rateLimited, source: .walletBackend, statusCode: 429, retryAfter: 60)
    #expect(TransportFailure.find(in: rateLimited) == expected)
    let gateway = NetworkError.httpError(code: 504, data: nil, headers: nil)
    #expect(TransportFailure.find(in: gateway) == .init(kind: .timeout, source: .walletBackend, statusCode: 504))
    #expect(TransportFailure.find(in: NetworkError.httpError(code: 500, data: nil, headers: nil)) == nil)
    #expect(TransportFailure.find(in: NetworkError.invalidResponse) == nil)
    #expect(TransportFailure.find(in: NetworkError.decodingError(URLError(.timedOut))) == nil)
  }

  // MARK: - OpenID4VCI issuance calls

  @Test("A timed-out issuance post is an OpenID4VCI timeout")
  func issuancePostTimeout() {
    let error = nested(OpenID4VCI.PostError.networkError(URLError(.timedOut)))
    #expect(TransportFailure.find(in: error) == .init(kind: .timeout, source: .openID4VCI))
  }

  @Test("A 504 or 429 answered to an issuance post keeps its status")
  func issuancePostStatus() {
    let gateway = nested(OpenID4VCI.PostError.requestError(504, URLError(.badServerResponse)))
    #expect(TransportFailure.find(in: gateway) == .init(kind: .timeout, source: .openID4VCI, statusCode: 504))
    let limited = nested(OpenID4VCI.PostError.requestError(429, URLError(.badServerResponse)))
    #expect(TransportFailure.find(in: limited) == .init(kind: .rateLimited, source: .openID4VCI, statusCode: 429))
  }

  @Test("Issuance metadata fetches are recognised as well")
  func issuanceFetch() {
    // Being offline is the connectivity monitor's business, not a transport failure.
    let offline = nested(OpenID4VCI.FetchError.networkError(URLError(.notConnectedToInternet)))
    #expect(TransportFailure.find(in: offline) == nil)
    let timedOut = nested(OpenID4VCI.FetchError.networkError(URLError(.timedOut)))
    #expect(TransportFailure.find(in: timedOut) == .init(kind: .timeout, source: .openID4VCI))
    let gateway = nested(OpenID4VCI.FetchError.invalidStatusCode(url, 504, nil))
    #expect(TransportFailure.find(in: gateway) == .init(kind: .timeout, source: .openID4VCI, statusCode: 504))
  }

  @Test("Issuance errors that are not transport failures are left alone")
  func issuanceOtherErrors() {
    let unauthorized = nested(OpenID4VCI.PostError.requestError(401, URLError(.userAuthenticationRequired)))
    #expect(TransportFailure.find(in: unauthorized) == nil)
    #expect(TransportFailure.find(in: nested(OpenID4VCI.PostError.serverError)) == nil)
    #expect(TransportFailure.find(in: nested(OpenID4VCI.FetchError.invalidResponse)) == nil)
  }

  // MARK: - Bare URLError

  @Test("A URLError without a library wrapper is attributed to an unknown source")
  func bareURLError() {
    #expect(TransportFailure.find(in: URLError(.timedOut)) == .init(kind: .timeout, source: .unknown))
    #expect(TransportFailure.find(in: nested(URLError(.cannotFindHost))) == .init(kind: .unreachable, source: .unknown))
    #expect(TransportFailure.find(in: URLError(.cancelled)) == nil)
  }

  @Test("Library wrappers win over the URLError they carry")
  func wrapperBeatsBareURLError() {
    let error = nested(OpenID4VP.PostError.networkError(URLError(.timedOut)))
    #expect(TransportFailure.find(in: error)?.source == .openID4VPResponse)
  }

  // MARK: - Lookup

  @Test("The NSUnderlyingErrorKey chain is walked as well")
  func underlyingErrorKeyIsWalked() {
    let wrapped = NSError(
      domain: "test",
      code: 1,
      userInfo: [NSUnderlyingErrorKey: URLError(.timedOut)]
    )
    #expect(TransportFailure.find(in: wrapped) == .init(kind: .timeout, source: .unknown))
  }

  @Test("A transport failure passed directly is returned as is")
  func passthrough() {
    let failure = TransportFailure(kind: .timeout, source: .walletBackend, retryAfter: 30)
    #expect(TransportFailure.find(in: failure) == failure)
    #expect(TransportFailure.find(in: nested(failure)) == failure)
  }

  @Test("Errors without a transport cause yield nothing")
  func noTransportCause() {
    struct Foreign: Error {}
    #expect(TransportFailure.find(in: Foreign()) == nil)
    #expect(TransportFailure.find(in: nested(ValidationError.invalidJwtPayload)) == nil)
    #expect(TransportFailure.find(in: WalletError(description: "plain", code: .internalError)) == nil)
  }
}
