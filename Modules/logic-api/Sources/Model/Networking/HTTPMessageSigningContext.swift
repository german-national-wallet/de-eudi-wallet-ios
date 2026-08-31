//
//  HTTPMessageSigningContext.swift
//  logic-api
//

public struct HTTPMessageSigningContext {
  public let method: String
  public let path: String
  public let headers: [String: String]
  public let contentTypeHeader: HTTPHeader?

  public init(
    method: String,
    path: String,
    headers: [String: String],
    contentTypeHeader: HTTPHeader?
  ) {
    self.method = method
    self.path = path
    self.headers = headers
    self.contentTypeHeader = contentTypeHeader
  }
}
