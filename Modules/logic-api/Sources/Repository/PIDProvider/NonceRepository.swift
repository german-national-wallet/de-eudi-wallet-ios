//
//  NonceRepository.swift
//  logic-api
//

import Foundation

public protocol NonceRepository {
  func fetchNonce(baseURL: String) async throws -> String
}

public final class NonceRepositoryImpl: NonceRepository {
  private let networkManager: NetworkManager

  public init(networkManager: NetworkManager) {
    self.networkManager = networkManager
  }

  public func fetchNonce(baseURL: String) async throws -> String {

    let result = try await networkManager.execute(with: NonceRequest(baseURL: baseURL), parameters: nil)
    return try (decodeResponse(from: result.data) as NonceResponse).cNonce
  }

  private func decodeResponse<T: Decodable>(from data: Data?) throws -> T {
    guard let data else {
      throw NetworkError.invalidResponse
    }
    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw NetworkError.decodingError(error)
    }
  }
}
