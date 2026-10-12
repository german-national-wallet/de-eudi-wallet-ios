//
//  PresentationErrorClassifier.swift
//  logic-core
//

import Foundation
import logic_business
import enum OpenID4VP.ValidationError

public protocol PresentationErrorClassifier: Sendable {
    func classify(_ error: Error) -> ClassifiedPresentationError
}

final class PresentationErrorClassifierImpl: PresentationErrorClassifier {
    
    private static let maxInnerErrorDepth = 8
    
    private static let trustFailureMarkers: [String] = [
        "Could not trust certificate chain",
        "ClientId does not match leaf certificate's SHA-256 hash",
        "Unable to verify signature",
        "Unable to decode public key from leaf certificate"
    ]
    
    private let reachabilityController: ReachabilityController
    
    init(reachabilityController: ReachabilityController) {
        self.reachabilityController = reachabilityController
    }
    
    func classify(_ error: Error) -> ClassifiedPresentationError {
        guard let walletError = error as? WalletError else {
            return ClassifiedPresentationError(errorClass: applyOfflineOverride(to: .unclassified), underlying: error)
        }
        
        let validationError = firstValidationError(in: walletError)
        let resolved = resolveClassByCode(for: walletError, validationError: validationError)
        
        return ClassifiedPresentationError(
            errorClass: applyOfflineOverride(to: resolved),
            diagnosticCode: walletError.code.rawValue,
            diagnosticCase: validationError.map(label(for:)),
            underlying: error
        )
    }
    
    // MARK: - Resolutions
    
    private func resolveClassByCode(
        for walletError: WalletError,
        validationError: ValidationError?
    ) -> PresentationErrorClass {
        switch walletError.code {
        case .noDocumentsAvailable, .credentialNotFound, .dcqlQueryNotSatisfied, .credentialSetNotSatisfied,
                .claimSetNotSatisfied, .claimValueMismatch, .claimNotFound:
            return .credentialNotAvailable
        case .trustError, .invalidWrprc:
            return .relyingPartyNotTrusted
        case .notSecuredRequest, .responseEncryptionMissing:
            return .relyingPartyRequestInvalid
        case .invalidQueryResolution:
            return resolveClassByValidationErrorType(validationError)
        case .storageError, .fileAccessError, .unsupportedAlgorithm, .invalidStatusToken:
            return .walletInternal
        default:
            return .unclassified
        }
    }
    
    private func resolveClassByValidationErrorType(_ validationError: ValidationError?) -> PresentationErrorClass {
        guard let validationError else {
            return .relyingPartyRequestInvalid
        }
        switch validationError {
        case .nonDispatchable(.missingConfiguration):
            return .walletInternal
        case .validationError(let message):
            return isTrustFailure(message) ? .relyingPartyNotTrusted : .relyingPartyRequestInvalid
        default:
            return .relyingPartyRequestInvalid
        }
    }
    
    private func isTrustFailure(_ message: String) -> Bool {
        Self.trustFailureMarkers.contains { message.contains($0) }
    }
    
    private func applyOfflineOverride(to errorClass: PresentationErrorClass) -> PresentationErrorClass {
        guard errorClass == .relyingPartyRequestInvalid || errorClass == .unclassified else {
            return errorClass
        }
        return reachabilityController.hasInternet() ? errorClass : .networkUnavailable
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
        switch validationError {
        case .validationError: "validationError"
        case .invalidClientMetadata: "invalidClientMetadata"
        case .missingResponseType: "missingResponseType"
        case .missingNonce: "missingNonce"
        case .nonDispatchable: "nonDispatchable"
        default: "other"
        }
    }
}
