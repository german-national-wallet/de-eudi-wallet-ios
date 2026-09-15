//
//  NonceRepositoryTests.swift
//  logic-api
//
//  Created by Pankaj Sachdeva on 07.04.26.
//

import Foundation
import Testing
import Cuckoo

@testable import logic_api

@Suite("NonceRepositoryImpl")
struct NonceRepositoryTests {

  @Test
  func fetchNonce_success() async throws {
    let expectedNonce = "test-nonce-value"
    let responseData = try JSONEncoder().encode(["c_nonce": expectedNonce])

    let networkManager = FakeNetworkManager()
    networkManager.mockResponse = NetworkResponse(data: responseData, headers: [:])

    let sut = NonceRepositoryImpl(networkManager: networkManager)
    let nonce = try await sut.fetchNonce(baseURL: "https://example.com")

    #expect(nonce == expectedNonce)
  }

  @Test
  func fetchNonce_networkError_throws() async throws {
    let networkManager = FakeNetworkManager()
    networkManager.error = NetworkError.invalidResponse

    let sut = NonceRepositoryImpl(networkManager: networkManager)

    await #expect(throws: NetworkError.invalidResponse) {
      try await sut.fetchNonce(baseURL: "https://example.com")
    }
  }

  @Test
  func fetchNonce_nilResponseData_throwsInvalidResponse() async throws {
    let networkManager = FakeNetworkManager()
    networkManager.mockResponse = NetworkResponse(data: nil, headers: [:])

    let sut = NonceRepositoryImpl(networkManager: networkManager)

    await #expect(throws: NetworkError.invalidResponse) {
      try await sut.fetchNonce(baseURL: "https://example.com")
    }
  }

  @Test
  func fetchNonce_malformedJSON_throwsDecodingError() async throws {
    let networkManager = FakeNetworkManager()
    networkManager.mockResponse = NetworkResponse(data: Data("not valid json".utf8), headers: [:])

    let sut = NonceRepositoryImpl(networkManager: networkManager)

    await #expect(throws: NetworkError.self) {
      try await sut.fetchNonce(baseURL: "https://example.com")
    }
  }

  @Test
  func fetchNonce_missingCNonceKey_throwsDecodingError() async throws {
    let networkManager = FakeNetworkManager()
    let wrongKey = try JSONEncoder().encode(["nonce": "some-value"])
    networkManager.mockResponse = NetworkResponse(data: wrongKey, headers: [:])

    let sut = NonceRepositoryImpl(networkManager: networkManager)

    await #expect(throws: NetworkError.self) {
      try await sut.fetchNonce(baseURL: "https://example.com")
    }
  }
}
