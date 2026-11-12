//
//  PresentationErrorClassifier.swift
//  logic-core
//

import Foundation
import logic_api
import logic_business
import enum OpenID4VP.ValidationError

public protocol PresentationErrorClassifier: Sendable {
    func classify(_ error: Error) -> ClassifiedPresentationError
}

final class PresentationErrorClassifierImpl: PresentationErrorClassifier {

    private static let maxInnerErrorDepth = 8

    private static let trustFailureMarkers: [String] = [
        "Could not trust certificate chain",
        "Unable to verify signature",
        "Unable to decode public key from leaf certificate"
    ]
    
    private let connectivityMonitor: NetworkConnectivityMonitor
    
    init(connectivityMonitor: NetworkConnectivityMonitor) {
        self.connectivityMonitor = connectivityMonitor
    }

    func classify(_ error: Error) -> ClassifiedPresentationError {
        if let failure = TransportFailure.find(in: error) {
            return classifyTransport(failure, underlying: error)
        }
        guard let walletError = error as? WalletError else {
            return ClassifiedPresentationError(errorClass: applyOfflineOverride(to: .unclassified, error: error), underlying: error)
        }

        let validationError = firstValidationError(in: walletError)
        let resolved = resolveClassByCode(for: walletError, validationError: validationError)

        return ClassifiedPresentationError(
            errorClass: applyOfflineOverride(to: resolved, error: error),
            diagnosticCode: walletError.code.rawValue,
            diagnosticCase: validationError.map(label(for:)),
            underlying: error
        )
    }

    // MARK: - Resolutions
    
    private func classifyTransport(_ failure: TransportFailure, underlying: Error) -> ClassifiedPresentationError {
        let resolved: PresentationErrorClass = switch (failure.kind, failure.source) {
        case (.timeout, .openID4VPRequest), (.unreachable, .openID4VPRequest), (.unreachable, .openID4VPResponse):
            .relyingPartyUnreachable
        case (.timeout, _), (.unreachable, _):
            .connectionTimedOut
        case (.rateLimited, _):
            .rateLimited
        }
        let effective = failure.statusCode != nil ? resolved : applyOfflineOverride(to: resolved, error: underlying)
        return ClassifiedPresentationError(
            errorClass: effective,
            origin: origin(of: failure, classifiedAs: effective),
            diagnosticCode: failure.statusCode.map { "HTTP \($0)" },
            diagnosticCase: failure.source.rawValue,
            transportFailure: failure,
            underlying: underlying
        )
    }
    
  private func origin(
      of failure: TransportFailure,
      classifiedAs errorClass: PresentationErrorClass
  ) -> PresentationErrorOrigin {
        if errorClass == .networkUnavailable {
            return .device
        }
        switch failure.source {
        case .openID4VPRequest, .openID4VPResponse: return .relyingParty
        case .openID4VCI, .walletBackend: return .wallet
        case .unknown: return .unknown
        }
    }
    
    private func resolveClassByCode(
        for walletError: WalletError,
        validationError: ValidationError?
    ) -> PresentationErrorClass {
        if case .networkError(let failure)? = validationError {
            return failure.isServerResponse ? .relyingPartyRequestInvalid : .networkUnavailable
        }
        switch walletError.code {
        case .noDocumentsAvailable, .credentialNotFound, .dcqlQueryNotSatisfied, .credentialSetNotSatisfied,
                .claimSetNotSatisfied, .claimValueMismatch, .claimNotFound:
            return .credentialNotAvailable
        case .trustError, .invalidWrprc:
            return .relyingPartyNotTrusted
        case .notSecuredRequest, .responseEncryptionMissing:
            return .relyingPartyRequestInvalid
        case .invalidRequest, .invalidClient, .invalidTransactionData, .invalidRequestUriMethod, .invalidScope,
                .vpFormatsNotSupported, .invalidQueryResolution:
            return resolveClassByValidationError(validationError)
        case .storageError, .fileAccessError, .unsupportedAlgorithm, .invalidStatusToken, .walletUnavailable:
            return .walletInternal
        default:
            return .unclassified
        }
    }

    private func resolveClassByValidationError(_ validationError: ValidationError?) -> PresentationErrorClass {
      guard let validationError else {
        return .relyingPartyRequestInvalid
      }
      switch validationError {
      case .nonDispatchable(.missingConfiguration), .walletUnavailable:
        return .walletInternal
      case .untrustedCertificateChain, .clientIdCertificateHashMismatch, .invalidRequestSignature:
        return .relyingPartyNotTrusted
      case .validationError(let message):
        return isTrustFailure(message) ? .relyingPartyNotTrusted : .relyingPartyRequestInvalid
      default:
        return .relyingPartyRequestInvalid
      }
    }

    private func isTrustFailure(_ message: String) -> Bool {
        Self.trustFailureMarkers.contains { message.contains($0) }
    }
    
    private func applyOfflineOverride(to errorClass: PresentationErrorClass, error: Error) -> PresentationErrorClass {
        let overridable: Set<PresentationErrorClass> = [
            .relyingPartyRequestInvalid, .relyingPartyUnreachable, .connectionTimedOut, .unclassified
        ]
        guard overridable.contains(errorClass) else {
            return errorClass
        }
        return error.isNoInternet || connectivityMonitor.isOffline ? .networkUnavailable : errorClass
    }

    private func firstValidationError(in error: Error) -> ValidationError? {
        var current: Error? = error
        var depth = 0

        while let candidate = current, depth < Self.maxInnerErrorDepth {
            if let validationError = candidate as? ValidationError {
                return validationError
            }
            current = (candidate as? WalletError)?.innerError
            depth += 1
        }
        return nil
    }

    // MARK: -

    private func label(for validationError: ValidationError) -> String {
        trustLabel(for: validationError) ?? requestLabel(for: validationError)
    }

    /// Relying party authentication and trust related cases.
    private func trustLabel(for validationError: ValidationError) -> String? {
        switch validationError {
        case .untrustedCertificateChain: "untrustedCertificateChain"
        case .clientIdNotInCertificateSAN: "clientIdNotInCertificateSAN"
        case .clientIdCertificateHashMismatch: "clientIdCertificateHashMismatch"
        case .invalidRequestSignature: "invalidRequestSignature"
        case .missingCertificateInHeader: "missingCertificateInHeader"
        case .unsignedRequestNotPermitted: "unsignedRequestNotPermitted"
        case .responseUriBindingFailed: "responseUriBindingFailed"
        case .preregisteredClientNotFound: "preregisteredClientNotFound"
        case .invalidVerifierAttestationFormat: "invalidVerifierAttestationFormat"
        case .invalidVerifierAttestationCredentialIds: "invalidVerifierAttestationCredentialIds"
        default: nil
        }
    }

    /// Request structure, query and transport related cases.
    private func requestLabel(for validationError: ValidationError) -> String {
        switch validationError {
        case .validationError: "validationError"
        case .invalidClientMetadata: "invalidClientMetadata"
        case .invalidJarmRequirement: "invalidJarmRequirement"
        case .missingResponseType: "missingResponseType"
        case .missingNonce: "missingNonce"
        case .missingRequiredField: "missingRequiredField"
        case .missingClientId: "missingClientId"
        case .invalidClientId: "invalidClientId"
        case .unsupportedClientIdScheme: "unsupportedClientIdScheme"
        case .unsupportedResponseMode: "unsupportedResponseMode"
        case .invalidRequest: "invalidRequest"
        case .invalidJwtPayload: "invalidJwtPayload"
        case .invalidRequestUriMethod: "invalidRequestUriMethod"
        case .invalidUseOfBothRequestAndRequestUri: "invalidUseOfBothRequestAndRequestUri"
        case .multipleQuerySources: "multipleQuerySources"
        case .invalidQuerySource: "invalidQuerySource"
        case .invalidScope: "invalidScope"
        case .invalidFormat: "invalidFormat"
        case .invalidTransactionData: "invalidTransactionData"
        case .walletUnavailable: "walletUnavailable"
        case .nonDispatchable: "nonDispatchable"
        case .networkError: "networkError"
        default: "other"
        }
    }
}
