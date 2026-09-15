//
//  NetworkManagerTests.swift
//  logic-api
//
//  Created by Tamas Dancsi on 26.02.26.
//

import Foundation
import Testing

@testable import logic_api

@Suite(.serialized)
struct NetworkManagerTests {

  @Test
  func networkRequest_DefaultsAreApplied() {
    let request = DefaultRequest()
    #expect(request.method == .GET)
    #expect(request.body == nil)
    #expect(request.requiresAuthToken == true)
    #expect(request.credentials.isEmpty)
  }

  @Test
  func prepare_UsesBaseHostPathAndParameters_WhenRequestHasNoBaseURL() async throws {
    let manager = NetworkManagerImpl(baseHost: "https://example.com", logger: nil)
    let request = TestRequest(path: "v1/test", baseURL: nil, requiresAuthToken: false)

    let urlRequest = try await manager.prepare(
      request: request,
      parameters: [NetworkParameter(key: "q", value: "1")],
      baseHost: "https://example.com"
    )

    #expect(urlRequest.url?.absoluteString == "https://example.com/v1/test?q=1")
    #expect(urlRequest.httpMethod == "GET")
  }

  @Test
  func prepare_UsesRequestBaseURL_WhenProvided() async throws {
    let manager = NetworkManagerImpl(baseHost: "https://wallet.example", logger: nil)
    let request = TestRequest(path: "v1/test", baseURL: "https://feature.example", requiresAuthToken: false)

    let urlRequest = try await manager.prepare(request: request, parameters: nil, baseHost: "https://wallet.example")

    #expect(urlRequest.url?.absoluteString == "https://feature.example/v1/test")
  }

  @Test
  func prepare_AddsAuthHeader_WhenRequiresAuthTokenIsTrue() async throws {
    setenv("API_KEY", "test-api-key", 1)
    defer { unsetenv("API_KEY") }

    let manager = NetworkManagerImpl(baseHost: "https://example.com", logger: nil)
    let request = TestRequest(path: "v1/test", baseURL: nil, requiresAuthToken: true)

    let urlRequest = try await manager.prepare(request: request, parameters: nil, baseHost: "https://example.com")

    #expect(urlRequest.value(forHTTPHeaderField: Constants.Key.authToken) == "test-api-key")
  }

  @Test
  func prepare_DoesNotAddAuthHeader_WhenRequestBaseURLTargetsForeignHost() async throws {
    setenv("API_KEY", "test-api-key", 1)
    defer { unsetenv("API_KEY") }

    let manager = NetworkManagerImpl(baseHost: "https://wallet.example", logger: nil)
    let request = TestRequest(path: "nonce", baseURL: "https://pid-provider.example", requiresAuthToken: true)

    let urlRequest = try await manager.prepare(request: request, parameters: nil, baseHost: "https://wallet.example")

    #expect(urlRequest.url?.absoluteString == "https://pid-provider.example/nonce")
    #expect(urlRequest.value(forHTTPHeaderField: Constants.Key.authToken) == nil)
  }

  @Test
  func prepare_AddsAuthHeader_WhenRequestBaseURLMatchesBaseHost() async throws {
    setenv("API_KEY", "test-api-key", 1)
    defer { unsetenv("API_KEY") }

    let manager = NetworkManagerImpl(baseHost: "https://wallet.example", logger: nil)
    let request = TestRequest(path: "v1/test", baseURL: "https://wallet.example", requiresAuthToken: true)

    let urlRequest = try await manager.prepare(request: request, parameters: nil, baseHost: "https://wallet.example")

    #expect(urlRequest.value(forHTTPHeaderField: Constants.Key.authToken) == "test-api-key")
  }

  @Test
  func prepare_AddsQueryCredential_WhenConfigured() async throws {
    setenv("FEATURE_FLAG_API_KEY", "ff-key", 1)
    defer { unsetenv("FEATURE_FLAG_API_KEY") }

    let manager = NetworkManagerImpl(baseHost: "https://example.com", logger: nil)
    let request = TestRequest(
      path: "features",
      baseURL: nil,
      requiresAuthToken: false,
      credentials: [.query(name: "apiKey", envKey: "FEATURE_FLAG_API_KEY")]
    )

    let urlRequest = try await manager.prepare(request: request, parameters: nil, baseHost: "https://example.com")
    let components = URLComponents(url: urlRequest.url!, resolvingAgainstBaseURL: false)

    #expect(components?.queryItems?.contains(URLQueryItem(name: "apiKey", value: "ff-key")) == true)
    #expect(urlRequest.value(forHTTPHeaderField: Constants.Key.authToken) == nil)
  }
}

private struct DefaultRequest: NetworkRequest {
  typealias Response = String

  var path: String = "v1/default"
  var additionalHeaders: [String: String] = [:]
  var baseURL: String? = nil
}

private struct TestRequest: NetworkRequest {
  typealias Response = String

  var path: String
  var additionalHeaders: [String: String] = [:]
  var baseURL: String?
  var requiresAuthToken: Bool
  var credentials: [NetworkRequestCredential] = []
}
