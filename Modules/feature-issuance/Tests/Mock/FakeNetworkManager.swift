//
//  FakeNetworkManager.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 21.10.24.
//

import Foundation
import logic_api

class FakeNetworkManager: NetworkManager {
  var mockResponse: NetworkResponse?
  var error: Error?

  func log(request: URLRequest, responseData: Data?, responseHeader: HTTPURLResponse?) {}

  func prepare<R: NetworkRequest>(
    request: R,
    parameters: [NetworkParameter]?,
    baseHost: String
  ) async -> URLRequest {
    URLRequest(url: URL(string: "https://example.com")!)
  }

  func execute<R: NetworkRequest>(
    with request: R,
    parameters: [NetworkParameter]?
  ) async throws -> NetworkResponse {
    if let error {
      throw error
    }
    if let response = mockResponse {
      return response
    }
    throw NetworkError.invalidResponse
  }
}
