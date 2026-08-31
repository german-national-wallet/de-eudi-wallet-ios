/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import Alamofire
import logic_business
import SwiftDotenv

public protocol NetworkManager {
  func execute<R: NetworkRequest>(with request: R, parameters: [NetworkParameter]?) async throws -> NetworkResponse
  func prepare<R: NetworkRequest>(
    request: R,
    parameters: [NetworkParameter]?,
    baseHost: String
  ) async throws -> URLRequest

  func log(
    request: URLRequest,
    responseData: Data?,
    responseHeader: HTTPURLResponse?
  )
}

public actor NetworkManagerImpl: NetworkManager {

  private typealias ResolvedCredential = (name: String, envKey: String)

  private let baseHost: String
  private let debugConfigController: DebugConfigController?
  nonisolated private let networkLogger: NetworkLogger

  let session: Session = {
    let configuration = URLSessionConfiguration.default
    return Session(
      configuration: configuration,
      redirectHandler: Redirector(behavior: .doNotFollow)
    )
  }()

  public init(
    baseHost: String,
    logger: Logging?,
    debugConfigController: DebugConfigController? = nil
  ) {
    self.baseHost = baseHost
    self.debugConfigController = debugConfigController
    self.networkLogger = NetworkLogger(logger: logger)
  }

  public func execute<R: NetworkRequest>(
    with request: R,
    parameters: [NetworkParameter]?
  ) async throws -> NetworkResponse {
    let request = try await self.prepare(
      request: request,
      parameters: parameters,
      baseHost: baseHost
    )

    return try await withCheckedThrowingContinuation { continuation in
      session.request(request)
        .responseData { response in

          self.log(
            request: request,
            responseData: response.data,
            responseHeader: response.response
          )
          guard let statusCode = response.response?.statusCode else {
            if let error = response.error {
              continuation.resume(throwing: NetworkError.internetFailure(error))
            } else {
              continuation.resume(throwing: NetworkError.invalidResponse)
            }
            return
          }
          let headers = response.response?.allHeaderFields as? [String: String]
          if (300..<399).contains(statusCode) && (headers?.keys.count ?? 0) > 0 {
            continuation.resume(returning: NetworkResponse(data: nil, headers: headers, statusCode: statusCode))
            return
          }
          let data = response.data
          if !(200..<300).contains(statusCode) {
            continuation.resume(returning: NetworkResponse(data: data, headers: headers, statusCode: statusCode))
            return
          }

          switch response.result {
          case .success(let data):
            continuation.resume(returning: NetworkResponse(data: data, headers: headers, statusCode: statusCode))
          case .failure(let error):
            if (headers?.keys.count ?? 0) > 0 {
              continuation.resume(returning: NetworkResponse(data: nil, headers: headers, statusCode: statusCode))
            } else if let data = response.data {
              continuation.resume(returning: NetworkResponse(data: data, headers: headers, statusCode: statusCode))
            } else {
              continuation.resume(throwing: error)
            }
          }
        }
    }
  }

  public func prepare<R: NetworkRequest>(
    request: R,
    parameters: [NetworkParameter]?,
    baseHost: String
  ) async throws -> URLRequest {
    let endpoint = try resolveEndpoint(request: request, baseHost: baseHost)
    var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
    var queryItems = parameters?.map { URLQueryItem(name: $0.key, value: $0.value) } ?? []

    let injectAuthToken = requestTargetsBaseHost(request: request, baseHost: baseHost)
    let (queryCredentials, headerCredentials) = resolveCredentials(request: request, injectAuthToken: injectAuthToken)
    let envValues = try resolveEnvironmentValues(for: queryCredentials + headerCredentials)
    apply(queryCredentials: queryCredentials, envValues: envValues, queryItems: &queryItems)

    if !queryItems.isEmpty {
      components?.queryItems = queryItems
    }
    guard let url = components?.url else {
      fatalError("No base url components provided")
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.allHTTPHeaderFields = request.additionalHeaders
    urlRequest.httpMethod = request.method.rawValue
    apply(headerCredentials: headerCredentials, envValues: envValues, to: &urlRequest)

    if let body = request.body {
      urlRequest.httpBody = body
    }
    return urlRequest
  }

  private func resolveEndpoint<R: NetworkRequest>(request: R, baseHost: String) throws -> URL {
    let baseURLString = request.baseURL ?? baseHost
    guard let baseURL = URL(string: baseURLString) else {
      throw NetworkError.invalidUrl
    }
    guard !request.path.isEmpty else {
      return baseURL
    }
    return baseURL.appendingPathComponent(request.path)
  }

  /// The `X-Auth-Token` (API key) authenticates the wallet instance to its own backend (`baseHost`).
  /// It must never be attached to a request whose caller redirected it to a foreign host via
  /// `baseURL` (e.g. the PID Provider), otherwise the backend credential leaks to a third party.
  private func requestTargetsBaseHost<R: NetworkRequest>(request: R, baseHost: String) -> Bool {
    guard let overrideURLString = request.baseURL, !overrideURLString.isEmpty else {
      return true
    }
    return URL(string: overrideURLString)?.host == URL(string: baseHost)?.host
  }

  private func resolveCredentials<R: NetworkRequest>(
    request: R,
    injectAuthToken: Bool
  ) -> (query: [ResolvedCredential], header: [ResolvedCredential]) {
    var requestCredentials = request.credentials
    if request.requiresAuthToken && injectAuthToken {
      requestCredentials.append(.header(name: Constants.Key.authToken, envKey: NetworkEnvName.apiKey))
    }

    let queryCredentials = requestCredentials.compactMap { credential -> ResolvedCredential? in
      if case let .query(name, envKey) = credential {
        return (name: name, envKey: envKey)
      }
      return nil
    }
    let headerCredentials = requestCredentials.compactMap { credential -> ResolvedCredential? in
      if case let .header(name, envKey) = credential {
        return (name: name, envKey: envKey)
      }
      return nil
    }
    return (queryCredentials, headerCredentials)
  }

  private func resolveEnvironmentValues(for credentials: [ResolvedCredential]) throws -> [String: String] {
    guard !credentials.isEmpty else {
      return [:]
    }
    var values: [String: String] = [:]
    var missingKeys = Set<String>()
    for credential in credentials {
      if values[credential.envKey] != nil {
        continue
      }
      if let value = overrideValue(for: credential.envKey) {
        values[credential.envKey] = value
      } else if let value = ProcessInfo.processInfo.environment[credential.envKey], !value.isEmpty {
        values[credential.envKey] = value
      } else {
        missingKeys.insert(credential.envKey)
      }
    }

    if !missingKeys.isEmpty {
      if let path = Bundle.main.path(forResource: ".env", ofType: nil) {
        try Dotenv.configure(atPath: path)
        for key in missingKeys where values[key] == nil {
          if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            values[key] = value
          }
        }
      }
      for key in missingKeys where values[key] == nil {
        throw NetworkError.apiKeyNotFound
      }
    }
    return values
  }

  /// Debug config (DEV/SANDBOX) can override the backend api key. The override wins over the environment and `.env`
  private func overrideValue(for envKey: String) -> String? {
    guard envKey == NetworkEnvName.apiKey else {
      return nil
    }
    return debugConfigController?.overrides.walletAPIKey
  }

  private func apply(
    queryCredentials: [ResolvedCredential],
    envValues: [String: String],
    queryItems: inout [URLQueryItem]
  ) {
    for credential in queryCredentials {
      if let value = envValues[credential.envKey] {
        queryItems.append(URLQueryItem(name: credential.name, value: value))
      }
    }
  }

  private func apply(
    headerCredentials: [ResolvedCredential],
    envValues: [String: String],
    to request: inout URLRequest
  ) {
    for credential in headerCredentials {
      if let value = envValues[credential.envKey] {
        request.setValue(value, forHTTPHeaderField: credential.name)
      }
    }
  }

  nonisolated public func log(
    request: URLRequest,
    responseData: Data? = nil,
    responseHeader: HTTPURLResponse?
  ) {
    networkLogger.log(
      request: request,
      responseData: responseData,
      responseHeader: responseHeader
    )
  }
}
