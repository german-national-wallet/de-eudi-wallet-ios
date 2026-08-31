//
//  BackendError.swift
//  logic-api
//

import Foundation
import logic_resources

public enum BackendError: Error, Equatable {

  /// The service answered with its standard error envelope.
  case serverError(code: String, description: String, traceID: String)
  /// A response arrived but was not usable.
  case invalidResponse
  /// The response body did not match the expected shape.
  case decodingFailed
  /// Signing the request failed locally, so it was never sent.
  case signingFailed
  /// The response is missing a header that must be signed.
  case missingSignedHeader(String)
  /// No account is registered with the service yet.
  case notRegistered
  /// Nothing server-sent to report: transport failures, or a local state anomaly.
  case unknown

  public var errorCode: String {
    guard case .serverError(let code, _, _) = self else { return "" }
    return code
  }

  public var traceId: String {
    guard case .serverError(_, _, let traceID) = self else { return "" }
    return traceID
  }

  public var serverDescription: String {
    guard case .serverError(_, let description, _) = self else { return "" }
    return description
  }

  public var errorContent: RemoteErrorResponseStruct {
    RemoteErrorResponseStruct(
      title: LocalizableStringKey.globalErrorTitle,
      paragraph: LocalizableStringKey.globalErrorParagraph,
      primaryButtonTitle: LocalizableStringKey.globalErrorPrimaryButtonTitle,
      secondaryButtonTitle: nil
    )
  }
}
