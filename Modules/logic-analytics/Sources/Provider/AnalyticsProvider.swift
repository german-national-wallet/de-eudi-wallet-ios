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

public protocol AnalyticsProvider {
  func initialize(key: String)
  func logScreen(screen: String, arguments: [String: String])
  func logEvent(event: String, arguments: [String: String])
  func startTrace(name: String, initialAttributes: [String: String])
  @discardableResult
  func endTrace(finalAttributes: [String: String], errorDescription: String?) -> String?
  var currentTraceID: String? { get }
}

import Foundation
import OpenTelemetryApi
import OpenTelemetrySdk
import StdoutExporter
import OpenTelemetryProtocolExporterHttp
import URLSessionInstrumentation
import logic_business
import SwiftDotenv

class OpenTelemetryAnalyticsProvider: AnalyticsProvider {

  private struct Constant {
    struct File {
      static let env = ".env"
    }
    struct Path {
      static let traces = "/v1/traces"
      static let logs = "/v1/logs"
    }
    struct Key {
      static let serviceName = "service.name"
      static let serviceVersion = "service.version"
      static let authAPIToken = "X_AUTH_API_TOKEN"
      static let authToken = "X-Auth-Token"
      static let otlpHost = "WALLET_OTLP_HOST_URL"
      static let otlpServiceName = "WALLET_OTLP_SERVICE_NAME"
      static let spanID = "span_id"
      static let traceID = "trace_id"
      static let errorDescription = "error_description"
      static let urlFull = "url_full"
      static let httpURL = "http.url"
      static let httpTarget = "http.target"
      static let httpRequestMethod = "http_request_method"
      static let httpRequestHeaderPrefix = "http_request_header_"
      static let httpResponseStatusCode = "http_response_status_code"
      static let httpResponseHeaderPrefix = "http_response_header_"
    }
    struct Value {
      static let instrumentationName = "com.eudiwalletde.opentelemetry"
      static let instrumentationScopeName = "network.instrumentation"
      static let unknown = "unknown"
    }
    static let redactedValue = "REDACTED"
    static let redactedHeaders: Set<String> = [
      "x-auth-token",
      "authorization",
      "proxy-authorization",
      "www-authenticate",
      "dpop",
      "dpop-nonce",
      "signature",
      "signature-input",
      "auth-challenge",
      "mdvm-token",
      "mdvm-wi-id",
      "wpb-wi-id",
      "oauth-client-attestation",
      "oauth-client-attestation-pop",
      "rwsca-account-id",
      "rwsca-pin-session-token",
      "location",
      "cookie",
      "set-cookie"
    ]
  }

  private var activeSpan: Span?
  private let configLogic: ConfigLogic?
  private let debugConfigController: DebugConfigController?
  private let logger: Logging?

  init(
    configLogic: ConfigLogic?,
    debugConfigController: DebugConfigController?,
    logger: Logging?
  ) {
    self.configLogic = configLogic
    self.debugConfigController = debugConfigController
    self.logger = logger
  }

  func initialize(key: String) {
    initializeOpenTelemetry()
    initializeURLSessionInstrumentation()
  }

  private func initializeOpenTelemetry() {
    guard let path = Bundle.main.path(forResource: Constant.File.env, ofType: nil) else {
      fatalError("Missing .env file")
    }

    do {
      try Dotenv.configure(atPath: path)
    } catch {
      logger?.e("missing .env")
    }
    let overrideToken = debugConfigController?.overrides.otlpAuthToken
    guard
      let authToken = overrideToken ?? ProcessInfo.processInfo.environment[Constant.Key.authAPIToken],
      !authToken.isEmpty
    else {
      return
    }
    guard
      let tracesEndpoint = getCollectorURL(path: Constant.Path.traces),
      let logsEndpoint = getCollectorURL(path: Constant.Path.logs)
    else {
      logger?.e("invalid OTLP collector url")
      return
    }

    let commonHeaders = [(Constant.Key.authToken, authToken)]
    let resource = Resource(attributes: [
      Constant.Key.serviceName: .string(Constant.Key.otlpServiceName.valueFromBundle),
      Constant.Key.serviceVersion: .string(configLogic?.appVersion ?? Constant.Value.unknown)
    ])

    let telemetryConfiguration: URLSessionConfiguration = .default
    telemetryConfiguration.urlCache = nil
    let httpClient = BaseHTTPClient(session: URLSession(configuration: telemetryConfiguration))
    let traceExporter = OtlpHttpTraceExporter(
      endpoint: tracesEndpoint,
      httpClient: httpClient,
      envVarHeaders: commonHeaders
    )
    let tracerProviderBuilder = TracerProviderBuilder()
      .add(spanProcessor: BatchSpanProcessor(spanExporter: traceExporter))
      .with(resource: resource)
    #if DEBUG
    let consoleExporter = StdoutSpanExporter()
    let consoleProcessor = SimpleSpanProcessor(spanExporter: consoleExporter)
    _ = tracerProviderBuilder.add(spanProcessor: consoleProcessor)
    #endif
    OpenTelemetry.registerTracerProvider(
      tracerProvider: tracerProviderBuilder.build()
    )

    let logExporter = OtlpHttpLogExporter(
      endpoint: logsEndpoint,
      httpClient: httpClient,
      envVarHeaders: commonHeaders
    )
    OpenTelemetry.registerLoggerProvider(
      loggerProvider: LoggerProviderBuilder()
        .with(processors: [
          BatchLogRecordProcessor(
            logRecordExporter: logExporter
          )
        ])
        .with(resource: resource)
        .build()
    )

    _ = OpenTelemetry.instance.loggerProvider
      .loggerBuilder(instrumentationScopeName: Constant.Value.instrumentationScopeName)
      .build()
  }

  private func initializeURLSessionInstrumentation() {
    let configuration = URLSessionInstrumentationConfiguration(
      shouldRecordPayload: { _ in
        return false
      },
      shouldInstrument: { [weak self] request in
        if let urlString = request.url?.absoluteString,
           let collectorURL = self?.getCollectorURL(),
           !urlString.contains(collectorURL.absoluteString) {
          return true
        }
        return false
      },
      nameSpan: { request -> String? in
        guard let url = request.url,
              let method = request.httpMethod,
              let host = url.host else {
          return nil
        }
        return "\(method) \(host)\(url.path.isEmpty ? "/" : url.path)"
      },
      spanCustomization: { [weak self] request, spanBuilder in
        guard let self else { return }
        if let activeSpan = self.activeSpan {
          spanBuilder.setParent(activeSpan)
        }
        spanBuilder.setAttribute(key: Constant.Key.httpURL, value: self.sanitizedURL(request.url))
        spanBuilder.setAttribute(key: Constant.Key.httpTarget, value: self.sanitizedTarget(request.url))
      },
      createdRequest: { [weak self] request, span in
        self?.logRequest(request, span: span)
      },
      receivedResponse: { [weak self] response, data, span in
        self?.logResponse(response, data, span: span)
      }
    )
    _ = URLSessionInstrumentation(configuration: configuration).startedRequestSpans
  }

  // MARK: - Logging

  private func redactedHeaderValue(_ name: String, _ value: String) -> String {
    Constant.redactedHeaders.contains(name.lowercased()) ? Constant.redactedValue : value
  }

  private func sanitizedURL(_ url: URL?) -> String {
    guard let url, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return Constant.Value.unknown
    }
    components.query = nil
    components.fragment = nil
    return components.string ?? Constant.Value.unknown
  }

  private func sanitizedTarget(_ url: URL?) -> String {
    guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return Constant.Value.unknown
    }
    return components.path.isEmpty ? "/" : components.path
  }

  private func logRequest(_ request: URLRequest, span: Span?) {
    var attributes: [String: AttributeValue] = [
      Constant.Key.httpRequestMethod: .string(request.httpMethod ?? Constant.Value.unknown),
      Constant.Key.urlFull: .string(sanitizedURL(request.url))
    ]

    if let activeSpan = span ?? OpenTelemetry.instance.contextProvider.activeSpan {
      attributes[Constant.Key.traceID] = .string(activeSpan.context.traceId.hexString)
      attributes[Constant.Key.spanID] = .string(activeSpan.context.spanId.hexString)
    }

    if let headers = request.allHTTPHeaderFields {
      for (key, value) in headers {
        attributes[Constant.Key.httpRequestHeaderPrefix + key.normalizedHTTPHeaderKey] =
          .string(redactedHeaderValue(key, value))
      }
    }

    let logger = OpenTelemetry.instance.loggerProvider.get(instrumentationScopeName: Constant.Value.instrumentationScopeName)
    logger.logRecordBuilder()
      .setAttributes(attributes)
      .emit()
  }

  private func logResponse(_ response: URLResponse, _ data: DataOrFile?, span: Span) {
    guard let httpResponse = response as? HTTPURLResponse else {
      return
    }

    var attributes: [String: AttributeValue] = [
      Constant.Key.httpResponseStatusCode: .int(httpResponse.statusCode),
      Constant.Key.urlFull: .string(sanitizedURL(httpResponse.url)),
      Constant.Key.traceID: .string(span.context.traceId.hexString),
      Constant.Key.spanID: .string(span.context.spanId.hexString)
    ]

    for (key, value) in httpResponse.allHeaderFields {
      if let keyString = key as? String, let valueString = value as? String {
        attributes[Constant.Key.httpResponseHeaderPrefix + keyString.normalizedHTTPHeaderKey] =
          .string(redactedHeaderValue(keyString, valueString))
      }
    }

    let logger = OpenTelemetry.instance.loggerProvider.get(instrumentationScopeName: Constant.Value.instrumentationScopeName)
    logger.logRecordBuilder()
      .setAttributes(attributes)
      .emit()
  }

  func logScreen(screen: String, arguments: [String: String]) {
    // Empty on purpose, we're not logging screen events, yet
  }

  func logEvent(event: String, arguments: [String: String]) {
    // Empty on purpose, we're not logging events, yet
  }

  func startTrace(name: String, initialAttributes: [String: String]) {
    let spanBuilder = tracer.spanBuilder(spanName: name).setActive(true)

    for (key, value) in initialAttributes {
      spanBuilder.setAttribute(key: key, value: value)
    }
    let span = spanBuilder.startSpan()
    activeSpan = span
  }

  @discardableResult
  func endTrace(finalAttributes: [String: String], errorDescription: String?) -> String? {
    guard let span = OpenTelemetry.instance.contextProvider.activeSpan ?? activeSpan else {
      logger?.e("no active span")
      return nil
    }

    let traceID = span.context.traceId.hexString
    for (key, value) in finalAttributes {
      span.setAttribute(key: key, value: value)
    }
    if let errorDescription {
      span.setAttribute(key: Constant.Key.errorDescription, value: errorDescription)
      span.status = .error(description: errorDescription)
    }
    span.end()
    activeSpan = nil
    return traceID
  }

  var currentTraceID: String? {
    (OpenTelemetry.instance.contextProvider.activeSpan ?? activeSpan)?.context.traceId.hexString
  }

  // MARK: - Helpers

  private func getCollectorURL(path: String = "") -> URL? {
    URL(string: (configLogic?.walletOTLPURL ?? Constant.Key.otlpHost.valueFromBundle) + path)
  }

  private lazy var tracer: Tracer = {
    OpenTelemetry.instance.tracerProvider.get(instrumentationName: Constant.Value.instrumentationName)
  }()
}
