//
//  HTTPSignatureService.swift
//  logic-api
//

import Foundation
import Security
import CryptoKit

public protocol HTTPSignatureService {
  /// Creates the Content-Digest header value so the signed request body integrity can be verified by the server.
  func createContentDigest(for body: Data) -> String
  /// Creates the Signature-Input header value describing which components are signed and with which key metadata.
  func createSignatureInput(fields: [String], keyID: String, algorithm: String) -> String
  /// Creates the canonical signature base string that both client and server must build identically before signature verification.
  func createSignatureBase(
    method: String,
    path: String,
    signedHeaders: [(name: String, value: String)],
    signatureInput: String
  ) -> String
  /// Signs the canonical base string with the private key to produce the Signature header value for HTTP message signing.
  func createSignature(base: String, privateKey: SecKey, algorithm: SecKeyAlgorithm) throws -> String
  /// Builds the Signature and Signature-Input headers for one or more HTTP message signatures on the same request.
  func makeSignatureHeaders(
    context: HTTPMessageSigningContext,
    signatures: [HTTPMessageSignature]
  ) throws -> [String: String]
}

public struct HTTPSignatureServiceImpl: HTTPSignatureService {
  private struct SigningResult {
    let signatureInput: String
    let signature: String
  }

  public init() {
    /// Public init
  }

  public func createContentDigest(for body: Data) -> String {
    let hash = Data(SHA256.hash(data: body)).base64EncodedString()
    return "sha-256=:\(hash):"
  }

  public func createSignatureInput(fields: [String], keyID: String, algorithm: String) -> String {
    let created = Int(Date().timeIntervalSince1970)
    let fieldsToken = fields.map { "\"\($0)\"" }.joined(separator: " ")
    return "(\(fieldsToken));keyid=\"\(keyID)\";alg=\"\(algorithm)\";created=\(created)"
  }

  public func createSignatureBase(
    method: String,
    path: String,
    signedHeaders: [(name: String, value: String)],
    signatureInput: String
  ) -> String {
    let methodLine = "\"@method\": \(method.uppercased())"
    let pathLine = "\"@path\": \(path)"
    let headerLines = signedHeaders.map { "\"\($0.name.lowercased())\": \($0.value)" }
    let signatureParamsLine = "\"@signature-params\": \(signatureInput)"

    return ([methodLine, pathLine] + headerLines + [signatureParamsLine]).joined(separator: "\n")
  }

  public func createSignature(base: String, privateKey: SecKey, algorithm: SecKeyAlgorithm) throws -> String {
    guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
      throw HTTPMessageSigningError.signingFailed
    }

    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(
      privateKey,
      algorithm,
      Data(base.utf8) as CFData,
      &error
    ) as Data? else {
      _ = error?.takeRetainedValue()
      throw HTTPMessageSigningError.signingFailed
    }

    return signature.base64EncodedString()
  }

  public func makeSignatureHeaders(
    context: HTTPMessageSigningContext,
    signatures: [HTTPMessageSignature]
  ) throws -> [String: String] {
    guard signatures.isEmpty == false else {
      throw HTTPMessageSigningError.missingSignatures
    }

    let signingResults = try signatures.map { signature in
      try makeSigningResult(context: context, signature: signature)
    }

    var finalHeaders = context.headers
    if let contentTypeHeader = context.contentTypeHeader {
      finalHeaders[contentTypeHeader.name] = contentTypeHeader.value
    }
    finalHeaders[MDVMConstants.Header.signatureInput] = zip(signatures, signingResults)
      .map { "\($0.name)=\($1.signatureInput)" }
      .joined(separator: ",")
    finalHeaders[MDVMConstants.Header.signature] = zip(signatures, signingResults)
      .map { "\($0.name)=:\($1.signature):" }
      .joined(separator: ",")
    return finalHeaders
  }

  private func makeSigningResult(
    context: HTTPMessageSigningContext,
    signature: HTTPMessageSignature
  ) throws -> SigningResult {
    let signatureInput = createSignatureInput(
      fields: signature.fields,
      keyID: signature.keyID,
      algorithm: signature.algorithm
    )
    let signatureBase = createSignatureBase(
      method: context.method,
      path: "/\(context.path)",
      signedHeaders: try makeSignedHeaders(from: context.headers, fields: signature.fields),
      signatureInput: signatureInput
    )

    do {
      let signature = try createSignature(
        base: signatureBase,
        privateKey: signature.privateKey,
        algorithm: .ecdsaSignatureMessageX962SHA256
      )
      return SigningResult(signatureInput: signatureInput, signature: signature)
    } catch {
      throw HTTPMessageSigningError.signingFailed
    }
  }

  private func makeSignedHeaders(
    from headers: [String: String],
    fields: [String]
  ) throws -> [(name: String, value: String)] {
    try fields.compactMap { field in
      guard field.hasPrefix("@") == false else { return nil }
      guard let header = headers.first(where: { $0.key.lowercased() == field.lowercased() }) else {
        throw HTTPMessageSigningError.missingSignedHeader(field)
      }
      return (name: header.key, value: header.value)
    }
  }
}
