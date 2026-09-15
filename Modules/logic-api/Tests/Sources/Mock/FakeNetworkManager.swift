//
//  FakeNetworkManager.swift
//  logic-api
//
//  Created by Tamas Dancsi on 18.02.26.
//

import Foundation
import logic_api

class FakeNetworkManager: NetworkManager {
  var mockResponse: NetworkResponse?
  var error: Error?

  func prepare<R: NetworkRequest>(
    request: R,
    parameters: [NetworkParameter]?,
    baseHost: String
  ) async -> URLRequest {
    URLRequest(url: URL(string: "https://example.com")!)
  }

  func execute<R: NetworkRequest>(with request: R, parameters: [NetworkParameter]?) async throws -> NetworkResponse {
    if let error {
      throw error
    }
    if let response = mockResponse {
      return response
    }
    throw NetworkError.invalidResponse
  }

  func log(request: URLRequest, responseData: Data?, responseHeader: HTTPURLResponse?) {}
}
