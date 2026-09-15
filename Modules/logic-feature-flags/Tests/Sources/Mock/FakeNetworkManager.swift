//
//  FakeNetworkManager.swift
//  logic-feature-flag
//

import Foundation
@testable import logic_api

final class FakeNetworkManager: NetworkManager {
  var mockResponse: NetworkResponse?
  var error: Error?
  private(set) var executeCallCount = 0

  func execute<R: NetworkRequest>(with request: R, parameters: [NetworkParameter]?) async throws -> NetworkResponse {
    executeCallCount += 1
    if let error {
      throw error
    }
    if let response = mockResponse {
      return response
    }
    throw NetworkError.invalidResponse
  }

  func prepare<R: NetworkRequest>(request: R, parameters: [NetworkParameter]?, baseHost: String) async throws -> URLRequest {
    URLRequest(url: URL(string: "https://example.com")!)
  }

  func log(request: URLRequest, responseData: Data?, responseHeader: HTTPURLResponse?) {}
}
