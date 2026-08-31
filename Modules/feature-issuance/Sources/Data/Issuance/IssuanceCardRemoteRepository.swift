//
//  IssuanceCardRemoteRepository.swift
//  feature-issuance
//

import Foundation
import logic_api
import feature_common

public protocol IssuanceCardRemoteRepository {
    func executeFinishAuthorizationRequest(with url: String) async throws -> FinishAuthorizationResponse
}

final class IssuanceCardRemoteRepositoryImpl: IssuanceCardRemoteRepository {
    private let networkManager: NetworkManager!
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func executeFinishAuthorizationRequest(with url: String) async throws -> FinishAuthorizationResponse {
        let request = PARRequest(baseURL: url)
        
        let networkResponse = try await networkManager.execute(with: request, parameters: nil)
        guard let headers = networkResponse.headers else {
            throw NetworkError.invalidResponse
        }
        let domainModel = try mapToFinishAuthorization(headers: headers)
        return domainModel
    }
    
    private func mapToFinishAuthorization(headers: [String: String]) throws -> FinishAuthorizationResponse {
        guard let dpopNonce = headers["dpop-nonce"],
              let location = headers["Location"],
              let urlComponents = URLComponents(string: location) else {
            throw NetworkError.invalidResponse
        }
        var code: String?
        var state: String?
        
        for queryItem in urlComponents.queryItems ?? [] {
            if queryItem.name == "code" {
                code = queryItem.value
            } else if queryItem.name == "state" {
                state = queryItem.value
            }
        }
        guard let code, let state else {
            throw NetworkError.invalidResponse
        }
        return FinishAuthorizationResponse(nonce: dpopNonce, code: code, state: state, location: location)
    }
}

struct PARRequest: NetworkRequest {
  var baseURL: String?
  typealias Response = FinishAuthorizationResponse

  var method: NetworkMethod { .GET }
  var additionalHeaders: [String: String] = [:]
  var path: String = ""
  var requiresAuthToken: Bool { false }

  var body: Data?
    
  let request: FinishAuthorizationResponse?
    
    init(request: FinishAuthorizationResponse? = nil, baseURL: String? = nil) {
        self.request = request
        self.baseURL = baseURL
    }
}
