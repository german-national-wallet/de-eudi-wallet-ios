//
//  PresentationErrorClassifierTests.swift
//  logic-core
//

import Testing
import Cuckoo
import Foundation
import logic_business
import enum OpenID4VP.ValidationError
import logic_api
import enum OpenID4VP.AuthorizationError

@testable import logic_core

@Suite("PresentationErrorClassifierImpl")
struct PresentationErrorClassifierTests {
    
    @Test("Every reachable list row maps to its documented class")
    func classifiesDocumentedCases() {
        for testCase in OpenID4VPErrorFixture.cases {
            guard let inputs = testCase.inputs, let expected = testCase.expectedClass else {
                #expect(
                    testCase.skipReason != nil,
                    "row \(testCase.row) carries no classifier input and no skip reason"
                )
                continue
            }
            let sut = makeSut(isOnline: testCase.hasInternet)
            for input in inputs {
                let classified = sut.classify(input.makeError())
                #expect(
                    classified.errorClass == expected,
          """
          row \(testCase.row) (\(testCase.protocolError)): expected \(expected.rawValue), \
          got \(classified.errorClass.rawValue). Reason: \(testCase.reason)
          """
                )
            }
        }
    }
    
    @Test("Cases the CSV does not cover behave as designed")
    func classifiesSyntheticCases() {
        for testCase in OpenID4VPErrorFixture.syntheticCases {
            let sut = makeSut(isOnline: testCase.hasInternet)
            for input in testCase.inputs {
                let classified = sut.classify(input.makeError())
                #expect(
                    classified.errorClass == testCase.expectedClass,
          """
          \(testCase.id): expected \(testCase.expectedClass.rawValue), \
          got \(classified.errorClass.rawValue). Reason: \(testCase.reason)
          """
                )
            }
        }
    }
    
    @Test("The fixture exercises every class the classifier can return")
    func fixtureCoversTaxonomy() {
        let covered = Set(
            OpenID4VPErrorFixture.cases.compactMap(\.expectedClass)
            + OpenID4VPErrorFixture.syntheticCases.map(\.expectedClass)
        )
        let reachable: Set<PresentationErrorClass> = [
            .credentialNotAvailable,
            .walletInternal,
            .relyingPartyRequestInvalid,
            .relyingPartyNotTrusted,
            .relyingPartyUnreachable,
            .connectionTimedOut,
            .rateLimited,
            .networkUnavailable,
            .unclassified
        ]
        #expect(
            covered == reachable,
            "Classes with no fixture coverage: \(reachable.subtracting(covered).map(\.rawValue))"
        )
    }
    
    @Test("Transport failures carry their source, status and origin into the result")
    func transportPayload() {
        let backendTimeout = classify(.init(kind: .timeout, source: .walletBackend))
        #expect(backendTimeout.errorClass == .connectionTimedOut)
        #expect(backendTimeout.origin == .wallet)
        #expect(backendTimeout.diagnosticCase == "walletBackend")
        #expect(backendTimeout.diagnosticCode == nil)
        #expect(backendTimeout.transportFailure == .init(kind: .timeout, source: .walletBackend))
        
        let gateway = classify(.init(kind: .timeout, source: .openID4VPResponse, statusCode: 504))
        #expect(gateway.errorClass == .connectionTimedOut)
        #expect(gateway.origin == .relyingParty)
        #expect(gateway.diagnosticCode == "HTTP 504")
        
        let rateLimited = classify(.init(kind: .rateLimited, source: .openID4VPRequest, statusCode: 429))
        #expect(rateLimited.errorClass == .rateLimited)
        #expect(rateLimited.origin == .relyingParty)
        #expect(rateLimited.diagnosticCode == "HTTP 429")
        
        let offline = classify(.init(kind: .unreachable, source: .openID4VPResponse), online: false)
        #expect(offline.errorClass == .networkUnavailable)
        #expect(offline.origin == .device)
        let description = offline.transportFailure.map(String.init(describing:))
        #expect(description == "TransportFailure unreachable via openID4VPResponse")
    }
    
    private func classify(_ failure: TransportFailure, online: Bool = true) -> ClassifiedPresentationError {
        makeSut(isOnline: online).classify(OpenID4VPErrorFixture.Input.transport(failure).makeError())
    }
    
    private func makeSut(isOnline: Bool) -> PresentationErrorClassifier {
        let connectivityMonitor = MockNetworkConnectivityMonitor()
        stub(connectivityMonitor) { mock in
            when(mock.isOffline.get).thenReturn(!isOnline)
        }
        return PresentationErrorClassifierImpl(connectivityMonitor: connectivityMonitor)
    }

    @Test("A no-internet error is classified as offline even while the monitor reports online")
    func noInternetErrorIsNetworkUnavailable() {
        let sut = makeSut(isOnline: true)

        #expect(sut.classify(URLError(.notConnectedToInternet)).errorClass == .networkUnavailable)
        #expect(sut.classify(NetworkError.noInternet).errorClass == .networkUnavailable)
    }

  // MARK: - Diagnostics

  // swiftlint:disable large_tuple
  @Test("Diagnostic code and case follow the wallet error code and the inner ValidationError")
  func reportsDiagnostics() {
    let cases: [(input: OpenID4VPErrorFixture.Input, code: String, diagnosticCase: String?)] = [
      (.walletError(.invalidQueryResolution, .missingNonce), "invalidQueryResolution", "missingNonce"),
      (.walletError(.invalidRequest, .missingClientId), "invalid_request", "missingClientId"),
      (.walletError(.invalidScope, .invalidScope), "invalid_scope", "invalidScope"),
      (.walletError(.invalidClient, .clientIdCertificateHashMismatch(clientId: "a", expectedHash: "b")),
       "invalid_client", "clientIdCertificateHashMismatch"),
      (.walletError(.invalidTransactionData, .invalidTransactionData("Unknown credential_ids")),
       "invalid_transaction_data", "invalidTransactionData"),
      (.walletError(.invalidQueryResolution, .nonDispatchable(.missingConfiguration)),
       "invalidQueryResolution", "nonDispatchable"),
      (.walletError(.invalidRequest, .conflictingData), "invalid_request", "other"),
      (.walletError(.noDocumentsAvailable), "noDocumentsAvailable", nil)
    ]
    let sut = makeSut(isOnline: true)
    for testCase in cases {
      let classified = sut.classify(testCase.input.makeError())
      #expect(classified.diagnosticCode == testCase.code)
      #expect(classified.diagnosticCase == testCase.diagnosticCase, "code \(testCase.code)")
    }
  }
  // swiftlint:enable large_tuple

  @Test("A foreign error carries no diagnostics and is passed through unchanged")
  func foreignErrorHasNoDiagnostics() {
    let classified = makeSut(isOnline: true).classify(OpenID4VPErrorFixture.Input.ForeignError())
    #expect(classified.diagnosticCode == nil)
    #expect(classified.diagnosticCase == nil)
    #expect(classified.underlying is OpenID4VPErrorFixture.Input.ForeignError)
  }

  @Test("The underlying wallet error keeps its context for the handler")
  func preservesUnderlyingContext() {
    let docType = "eu.europa.ec.eudi.pid.1"
    let context = ["docType": docType]
    let error = WalletError(description: "Credential not found", code: .credentialNotFound, context: context)
    let underlying = makeSut(isOnline: true).classify(error).underlying as? WalletError
    #expect(underlying?.code == .credentialNotFound)
    #expect(underlying?.context["docType"] == docType)
  }

  // MARK: - Inner error traversal

  @Test("The ValidationError is found only within the maximum inner error depth")
  func respectsInnerErrorDepthLimit() {
    let trustFailure = ValidationError.clientIdCertificateHashMismatch(clientId: "a", expectedHash: "b")
    let sut = makeSut(isOnline: true)
    // 7 wrappers put the ValidationError at index 7, the last index the classifier inspects
    let withinLimit = sut.classify(wrap(trustFailure, in: .invalidClient, times: 7))
    let beyondLimit = sut.classify(wrap(trustFailure, in: .invalidClient, times: 8))
    #expect(withinLimit.errorClass == .relyingPartyNotTrusted)
    #expect(withinLimit.diagnosticCase == "clientIdCertificateHashMismatch")
    #expect(beyondLimit.errorClass == .relyingPartyRequestInvalid)
    #expect(beyondLimit.diagnosticCase == nil)
  }

  @Test("A non-ValidationError inner error yields no diagnostic case")
  func ignoresNonValidationInnerError() {
    let inner = AuthorizationError.jwtDecryptionFailed
    let error = WalletError(description: "JAR decryption failed", code: .invalidRequest, innerError: inner)
    let classified = makeSut(isOnline: true).classify(error)
    #expect(classified.errorClass == .relyingPartyRequestInvalid)
    #expect(classified.diagnosticCode == "invalid_request")
    #expect(classified.diagnosticCase == nil)
  }

  // MARK: - Helpers

  private func wrap(_ validationError: ValidationError, in code: WalletError.Code, times: Int) -> Error {
    var current: Error = validationError
    for _ in 0..<times {
      current = WalletError(description: "wrapper", code: code, innerError: current)
    }
    return current
  }
}
