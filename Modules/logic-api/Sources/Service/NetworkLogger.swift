//
//  NetworkLogger.swift
//  logic-api
//

import Alamofire
import Foundation
import logic_business

public struct NetworkLogger: Sendable {

  private let logger: Logging?
  private let redactedValue = "REDACTED"
  private let redactedKeys: Set<String> = Set(
    [
      Constants.Key.authToken,
      Constants.Key.authChallenge,
      Constants.Key.signatureInput,
      Constants.Key.signature,
      Constants.Key.mdvmToken,
      Constants.Key.pinSessionToken,
      Constants.Key.apiKeyQueryParam,
      Constants.Key.authorization,
      Constants.Key.dpop,
      Constants.Key.mdvmWIID,
      Constants.Key.wpbWIID,
      Constants.Key.rwscaAccountId,
      Constants.Key.clientAttestation,
      Constants.Key.clientAttestationPoP,
      Constants.Key.location,
      Constants.Key.cookie,
      Constants.Key.setCookie,
      Constants.BodyKey.accessToken,
      Constants.BodyKey.refreshToken,
      Constants.BodyKey.cNonce,
      Constants.BodyKey.pidProviderCNonce,
      Constants.BodyKey.credential,
      Constants.BodyKey.credentials,
      Constants.BodyKey.pinSessionToken,
      Constants.BodyKey.rwscaAuthChallenge,
      Constants.BodyKey.wpbAuthChallenge,
      Constants.BodyKey.keyBindingSignature,
      Constants.BodyKey.rwscaWiWrappedPrivateKey,
      Constants.BodyKey.rwscaWte,
      Constants.BodyKey.papDeviceCheckAttestation,
      Constants.BodyKey.papDeviceCheckAssertion,
      Constants.BodyKey.preAuthorizedCode,
      Constants.BodyKey.txCode,
      Constants.BodyKey.authorizationCode,
      Constants.BodyKey.codeVerifier,
      Constants.BodyKey.mdvmToken,
      Constants.BodyKey.mdvmWIID,
      Constants.BodyKey.mdvmAuthChallenge,
      Constants.BodyKey.pnsAuthChallenge,
      Constants.BodyKey.rwscaAccountId,
      Constants.BodyKey.wpbWia,
      Constants.BodyKey.proof,
      Constants.BodyKey.proofs
    ].map { $0.lowercased() }
  )

  public init(logger: Logging?) {
    self.logger = logger
  }

  public func log(
    request: URLRequest,
    responseData: Data? = nil,
    responseHeader: HTTPURLResponse?,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    var log = "\n\n==================== Network Request Begin ====================\n"
    log += "🔵 Request: \(redactedURL(request.url))\n"
    log += "🔵 Method: \(request.httpMethod ?? "")\n"
    log += "🔵 Body: \(redactedBody(request.httpBody))\n"
    log += "🔵 Headers: \(redactedHeaders(request.allHTTPHeaderFields ?? [:]))\n"
    if let responseHeader {
      log += "\((200..<300).contains(responseHeader.statusCode) ? "✅" : "⛔️") Status: \(responseHeader.statusCode.string)\n"
      log += "🟡 Response Headers: \(redactedHeaders(responseHeader.headers.dictionary))\n"
    }
    if let responseData {
      log += "🟡 Response Body: \(redactedBody(responseData))\n"
    }
    log += "==================== Network Request End ====================\n"
    logger?.d(log, file: file, function: function, line: line)
  }

  private func isRedacted(_ key: String) -> Bool {
    redactedKeys.contains(key.lowercased())
  }

  private func redactedHeaders(_ headers: [String: String]) -> String {
    headers
      .map { key, value in
        "\(key): \(isRedacted(key) ? redactedValue : redactedURL(in: value))"
      }
      .joined(separator: ", ")
  }

  private func redactedURL(in value: String) -> String {
    guard let url = URL(string: value), url.query != nil else {
      return value
    }
    return redactedURL(url)
  }

  private func redactedURL(_ url: URL?) -> String {
    guard let url else { return "" }
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
      return url.absoluteString
    }
    components.queryItems = queryItems.map { item in
      isRedacted(item.name)
        ? URLQueryItem(name: item.name, value: redactedValue)
        : item
    }
    return components.string ?? url.absoluteString
  }

  private func redactedBody(_ body: Data?) -> String {
    guard let body, !body.isEmpty else { return "" }

    if let json = try? JSONSerialization.jsonObject(with: body),
       let redacted = try? JSONSerialization.data(
        withJSONObject: redactedJSON(json),
        options: [.prettyPrinted, .sortedKeys]
       ),
       let rendered = String(data: redacted, encoding: .utf8) {
      return rendered
    }
    if let rendered = redactedFormBody(body) {
      return rendered
    }
    return "[body not logged, \(body.count) bytes]"
  }

  private func redactedFormBody(_ body: Data) -> String? {
    guard let encoded = String(data: body, encoding: .utf8), encoded.contains("=") else {
      return nil
    }
    var components = URLComponents()
    components.percentEncodedQuery = encoded.replacingOccurrences(of: "+", with: "%20")
    guard let queryItems = components.queryItems, !queryItems.isEmpty else {
      return nil
    }
    return queryItems
      .map { "\($0.name)=\(isRedacted($0.name) ? redactedValue : ($0.value ?? ""))" }
      .joined(separator: "&")
  }

  private func redactedJSON(_ json: Any) -> Any {
    if let dictionary = json as? [String: Any] {
      return dictionary.reduce(into: [String: Any]()) { result, element in
        result[element.key] = isRedacted(element.key) ? redactedValue : redactedJSON(element.value)
      }
    }
    if let array = json as? [Any] {
      return array.map { redactedJSON($0) }
    }
    return json
  }
}
