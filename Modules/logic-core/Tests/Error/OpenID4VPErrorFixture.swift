//
//  OpenID4VPErrorFixture.swift
//  logic-core
//

import Foundation
import Combine
import enum OpenID4VP.ValidationError
import struct OpenID4VP.NetworkFailure

@testable import logic_business
@testable import logic_core

enum OpenID4VPErrorFixture {

    struct Input {
        let walletErrorCode: WalletError.Code?
        let validationError: ValidationError?
        let transportFailure: TransportFailure?
        
        struct ForeignError: Error {}

        static func walletError(_ code: WalletError.Code, _ validationError: ValidationError? = nil) -> Input {
            Input(walletErrorCode: code, validationError: validationError, transportFailure: nil)
        }
        
        static func transport(_ failure: TransportFailure) -> Input {
            Input(walletErrorCode: .internalError, validationError: nil, transportFailure: failure)
        }
        
        static let foreign = Input(walletErrorCode: nil, validationError: nil, transportFailure: nil)

        func makeError() -> Error {
            guard let walletErrorCode else {
                return ForeignError()
            }
            if let transportFailure {
                return WalletError(description: "transport fixture", code: walletErrorCode, innerError: transportFailure)
            }
            let serviceError = WalletError(description: "OpenID4VP request error: fixture", code: walletErrorCode, innerError: validationError)
            return WalletError(description: serviceError.description, code: walletErrorCode, innerError: serviceError)
        }
    }

    struct Case {
        let row: Int
        let protocolError: String
        let reason: String
        let skipReason: String?
        let hasInternet: Bool
        let expectedClass: PresentationErrorClass?
        let inputs: [Input]?

        static func skipped(_ csvRow: Int, _ protocolError: String, reason: String, because skipReason: String) -> Case {
            Case(row: csvRow, protocolError: protocolError, reason: reason, skipReason: skipReason, hasInternet: true, expectedClass: nil, inputs: nil)
        }

        static func row(_ csvRow: Int, _ protocolError: String, _ expectedClass: PresentationErrorClass, _ inputs: Input..., online: Bool = true, reason: String) -> Case {
            Case(row: csvRow, protocolError: protocolError, reason: reason, skipReason: nil, hasInternet: online, expectedClass: expectedClass, inputs: inputs)
        }
    }

    struct SyntheticCase {
        let id: String
        let reason: String
        let hasInternet: Bool
        let expectedClass: PresentationErrorClass
        let inputs: [Input]

        static func synthetic(_ id: String, _ expectedClass: PresentationErrorClass, _ inputs: Input..., online: Bool = true, reason: String) -> SyntheticCase {
            SyntheticCase(id: id, reason: reason, hasInternet: online, expectedClass: expectedClass, inputs: inputs)
        }
    }
}

// swiftlint:disable line_length
extension OpenID4VPErrorFixture {

    static let cases: [Case] = [
        .skipped(1, "access_denied", reason: "User declined to share.", because: "User rejection is a UI action, not an error."),
        .row(2, "access_denied", .credentialNotAvailable, .walletError(.noDocumentsAvailable), reason: "Wallet holds no matching credential. The wallet-kit dispatches negative consent to the verifier but rethrows the original wallet error."),
        .skipped(3, "access_denied", reason: "User authentication failed (3 PIN errors). Spec expects access_denied; neither platform sends anything.", because: "Raised as BackendError(ACCOUNT_LOCKED) in the PIN flow, not as a WalletError."),
        .row(4, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingResponseType), reason: "response_type missing or blank. Request-object validation."),
        .row(5, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingResponseType), reason: "response_type is not vp_token. Request-object validation."),
        .row(6, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingNonce), reason: "nonce missing. Request-object validation."),
        .row(7, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidRequest), reason: "direct_post / direct_post.jwt with a redirect_uri present. ResponseMode rejects it since openid4vp 0.43.0."),
        .row(8, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidRequest), reason: "query / fragment mode with a response_uri present. ResponseMode rejects it since openid4vp 0.43.0."),
        .row(9, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .responseUriBindingFailed("response_uri host 'other.example.com' must match client_id 'verifier.example.com'")), reason: "x509_san_dns client: host of response_uri / redirect_uri differs from client_id. ClientAuthenticator checks the binding since openid4vp 0.43.0 and reports invalid_client; treated as a request problem to match Android."),
        .row(10, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .unsupportedResponseMode("direct_post")), reason: "Unknown response_mode value. Not sent by Android either (no dispatch details without a known mode)."),
        .row(11, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingRequiredField(".responseUri")), reason: "direct_post / direct_post.jwt without response_uri. Not sent (no URI to post to)."),
        .row(12, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingRequiredField(".responseUri")), reason: "response_uri is not a valid URL. Not sent (no URI to post to)."),
        .row(13, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingRequiredField(".redirectUri")), reason: "query / fragment mode without redirect_uri. Not sent."),
        .row(14, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingRequiredField(".redirectUri")), reason: "redirect_uri is not a valid URI. Not sent."),
        .row(15, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .multipleQuerySources), reason: "Both dcql_query and a non-openid scope present. Request-object validation."),
        .row(16, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidQuerySource), reason: "Neither dcql_query nor scope present (or scope is only 'openid'). Request-object validation."),
        .row(17, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("The data couldn’t be read because it isn’t in the correct format.")), reason: "dcql_query does not deserialise. A DecodingError is still wrapped as an untyped validationError. Request-object validation."),
        .row(18, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidRequest), reason: "DCQL asks for a format other than mso_mdoc or dc+sd-jwt. ResolvedRequestData rejects unsupported query formats since openid4vp 0.43.0."),
        .row(19, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidVerifierAttestationFormat), reason: "verifier_info does not deserialise. Reported as invalid_client by the library. Request-object validation."),
        .row(20, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidVerifierAttestationCredentialIds), reason: "verifier_info credential_ids reference ids that are not in the DCQL. Reported as invalid_client by the library. Request-object validation."),
        .row(21, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidJarmRequirement), reason: "direct_post.jwt without client_metadata. Request-object validation."),
        .row(22, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "direct_post.jwt with client_metadata but no jwks. Request-object validation."),
        .row(23, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "jwks present but empty. Request-object validation."),
        .row(24, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidRequest), reason: "Two JWKs share a kid. WebKeySet rejects duplicate kids since openid4vp 0.43.0."),
        .row(25, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "jwks is JSON but not a valid JWK Set. Request-object validation."),
        .row(26, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "No JWK carries both kid and alg. Request-object validation."),
        .row(27, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "No JWK with alg ECDH-ES usable for encryption. Wallet supports ECDH-ES only. Request-object validation."),
        .row(28, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "encrypted_response_enc_values_supported has no overlap with A128CBC-HS256 / A256GCM (Android) or A128GCM / A256GCM (iOS). Request-object validation."),
        .row(29, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "encrypted_response_enc_values_supported present but empty. Request-object validation."),
        .row(30, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "encrypted_response_enc_values_supported given for a non-JWT response_mode. Request-object validation."),
        .row(31, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidRequest), reason: "vp_formats_supported in client_metadata lacks a format the DCQL requests. ResolvedRequestData checks the verifier formats since openid4vp 0.43.0."),
        .row(32, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .missingClientId), reason: "No client_id in the authorization request URI. Raised while fetching or authenticating the request."),
        .row(33, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidUseOfBothRequestAndRequestUri), reason: "Both request and request_uri present. Raised while fetching or authenticating the request."),
        .row(34, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .unsignedRequestNotPermitted(scheme: "x509_san_dns")), reason: "x509_san_dns client_id used in a plain (unsigned) request. Reported as invalid_client by the library; a malformed request, not a trust verdict."),
        .row(35, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidClient, .unsignedRequestNotPermitted(scheme: "x509_hash")), reason: "x509_hash client_id used in a plain (unsigned) request. Reported as invalid_client by the library; a malformed request, not a trust verdict."),
        .row(36, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .unsupportedClientIdScheme("openid_federation:https://verifier.example.com")), reason: "client_id fails to parse. Raised while fetching or authenticating the request."),
        .row(37, "invalid_client", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .unsupportedClientIdScheme("redirect_uri:https://verifier.example.com")), reason: "client_id prefix is not x509_san_dns or x509_hash. WalletAuthorizationRequestResolver rejects prefixes the wallet does not configure; the library maps it to invalid_request since 0.43.0."),
        .row(38, "invalid_client", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .invalidClientId), reason: "client_id prefix does not survive VerifierId parsing unchanged. The library maps it to invalid_request since 0.43.0."),
        .row(39, "invalid_request_uri_method", .relyingPartyRequestInvalid, .walletError(.invalidRequestUriMethod, .invalidRequestUriMethod), reason: "request_uri_method is not exactly 'get' or 'post', or is combined with request by value. Raised while fetching or authenticating the request."),
        .row(40, "invalid_request_uri", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidJwtPayload), reason: "GET or POST to request_uri returned an error. invalid_request_object has no WalletError.Code, so the wallet-kit keeps .invalidQueryResolution."),
        .row(41, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("Invalid compact serialization")), reason: "JAR is not a parseable signed JWT. JAR problem. Raised while fetching or authenticating the request."),
        .row(42, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("algorithm should not be nil")), reason: "JOSE header has no alg. JAR problem. Raised while fetching or authenticating the request."),
        .row(43, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("nonce's do not match")), reason: "alg is not ES256, ES384 or ES512. JAR problem. Raised while fetching or authenticating the request."),
        .row(44, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("client_id's do not match")), reason: "client_id in the URI differs from the one inside the JAR. JAR problem. Raised while fetching or authenticating the request."),
        .row(45, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("wallet_nonce mismatch")), .walletError(.invalidRequest, .validationError("wallet_nonce missing in JWT")), reason: "POST request_uri_method: JAR does not echo the wallet_nonce. JAR problem. Raised while fetching or authenticating the request."),
        .row(46, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidClient, .missingCertificateInHeader), .walletError(.invalidRequest, .validationError("x5c header field does not contain a serialized leaf certificate")), reason: "No x5c in the JOSE header. ClientAuthenticator reports the typed case first; AccessValidator still uses the untyped string. JAR problem."),
        .row(47, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("Certificate at index 0 in x5c chain failed to parse: The data couldn’t be read because it isn’t in the correct format.")), reason: "No certificate in x5c parses. parseCertificates fails closed with an untyped string since openid4vp 0.43.0. JAR problem."),
        .row(48, "invalid_request_object", .relyingPartyNotTrusted, .walletError(.trustError, .validationError("Could not trust certificate chain")), reason: "Chain not trusted by the wallet's reader trust store. The wallet-kit chain verifier records the failure, so the code is already .trustError. JAR problem."),
        .row(49, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidClient, .clientIdNotInCertificateSAN(clientId: "verifier.example.com", certificateSANs: [])), reason: "x509_san_dns: leaf certificate has no DNS SAN. By decision not treated as a trust failure, so it falls to the default relying-party class."),
        .row(50, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidClient, .clientIdNotInCertificateSAN(clientId: "verifier.example.com", certificateSANs: ["other.example.com"])), reason: "x509_san_dns: client_id not among the DNS SANs. By decision not treated as a trust failure, so it falls to the default relying-party class."),
        .row(51, "invalid_request_object", .relyingPartyNotTrusted, .walletError(.invalidClient, .clientIdCertificateHashMismatch(clientId: "client-hash", expectedHash: "leaf-hash")), reason: "x509_hash: client_id is not the base64url SHA-256 of the leaf certificate. Typed case since openid4vp 0.43.0. JAR problem."),
        .row(52, "invalid_request_object", .relyingPartyNotTrusted, .walletError(.invalidRequest, .validationError("Unable to verify signature using public key from leaf certificate")), .walletError(.invalidRequest, .validationError("Unable to decode public key from leaf certificate")), reason: "Signature, typ (oauth-authz-req+jwt) or time claims fail verification. AccessValidator still reports these as untyped strings under invalid_request. JAR problem."),
        .row(53, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("Unable to decode transaction data")), reason: "transaction_data entry has no type. transaction_data validation. Request-object validation."),
        .row(54, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("Unable to decode transaction data")), reason: "transaction_data entry has no credential_ids. transaction_data validation. Request-object validation."),
        .row(55, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("Transaction data must be an object")), reason: "type is not a string / entry is not an object. transaction_data validation. Request-object validation."),
        .row(56, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("Unable to decode transaction data")), reason: "Entry is not base64url-encoded JSON. transaction_data validation. Request-object validation."),
        .row(57, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("Unknown credential_ids")), reason: "credential_ids reference ids not in the DCQL. transaction_data validation. Request-object validation."),
        .row(58, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("credential_ids must not be empty")), reason: "credential_ids is empty. Checked since openid4vp 0.43.0. transaction_data validation."),
        .skipped(59, "invalid_transaction_data", reason: "Referenced credentials mix formats. transaction_data validation. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .skipped(60, "invalid_transaction_data", reason: "Referenced credentials are mso_mdoc; transaction data is only defined for SD-JWT. transaction_data validation. Request-object validation.", because: "The iOS library accepts mdoc alternatives for transaction data."),
        .row(61, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("transaction_data_hashes_alg must be a non-empty array of strings")), reason: "transaction_data_hashes_alg present but empty. Checked since openid4vp 0.43.0. transaction_data validation."),
        .row(62, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("Unsupported transaction data type: urn:eudi:payment:1")), reason: "Transaction data type the wallet does not register. transaction_data validation. Request-object validation."),
        .row(63, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidTransactionData, .invalidTransactionData("Unsupported transaction data hash algorithms")), reason: "transaction_data_hashes_alg lists only algorithms the wallet does not support for that type. Checked since openid4vp 0.43.0. transaction_data validation."),
        .row(64, "vp_formats_not_supported", .relyingPartyRequestInvalid, .walletError(.vpFormatsNotSupported, .invalidFormat), reason: "client_metadata vp_formats_supported has no format or algorithm in common with the wallet. ResolvedRequestData intersects the formats since openid4vp 0.43.0."),
        .row(65, "invalid_request (iOS only)", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .validationError("Invalid aud value, should be: https://self-issued.me/v2")), reason: "JAR aud claim does not match the wallet audience.")
    ]

    static let syntheticCases: [SyntheticCase] = [
        .synthetic("offline-overrides-invalid-request", .networkUnavailable, .walletError(.invalidRequest, .missingNonce), online: false, reason: "A request-resolution failure while the device is offline is reported as offline."),
        .synthetic("offline-overrides-legacy-query-resolution", .networkUnavailable, .walletError(.invalidQueryResolution, .invalidJwtPayload), online: false, reason: "The legacy .invalidQueryResolution code is still overridden while offline."),
        .synthetic("offline-does-not-override-trust", .relyingPartyNotTrusted, .walletError(.invalidClient, .clientIdCertificateHashMismatch(clientId: "client-hash", expectedHash: "leaf-hash")), online: false, reason: "A trust failure stays a trust failure even when the device is offline."),
        .synthetic("offline-does-not-override-missing-credential", .credentialNotAvailable, .walletError(.noDocumentsAvailable), online: false, reason: "A missing credential stays a missing credential even when the device is offline."),
        .synthetic("trust-failure-without-side-channel", .relyingPartyNotTrusted, .walletError(.invalidRequest, .validationError("Could not trust certificate chain")), reason: "chainVerifier bailed out before writing readerCertificateValidationMessage, so only the message identifies the trust failure."),
        .synthetic("untrusted-chain-typed", .relyingPartyNotTrusted, .walletError(.invalidClient, .untrustedCertificateChain("No certificate in chain")), reason: "ClientAuthenticator reports an unusable x5c chain with the typed case since openid4vp 0.43.0."),
        .synthetic("invalid-request-signature-typed", .relyingPartyNotTrusted, .walletError(.invalidClient, .invalidRequestSignature("Unable to process JWT")), reason: "ClientAuthenticator reports a JAR it cannot verify with the typed case since openid4vp 0.43.0."),
        .synthetic("invalid-client-metadata-is-not-trust", .relyingPartyRequestInvalid, .walletError(.invalidClient, .invalidClientMetadata), reason: "invalid_client also covers malformed client metadata, which is a request problem."),
        .synthetic("wallet-configuration-failure", .walletInternal, .walletError(.invalidQueryResolution, .nonDispatchable(.missingConfiguration)), reason: "getWalletConf() returned nil, an identified wallet-side failure. processing_error has no WalletError.Code, so the code stays .invalidQueryResolution."),
        .synthetic("offline-does-not-override-wallet-internal", .walletInternal, .walletError(.invalidQueryResolution, .nonDispatchable(.missingConfiguration)), online: false, reason: "A local key-generation failure is not a connectivity problem, so the offline dialog must not be shown."),
        .synthetic("wallet-unavailable-inner-case", .walletInternal, .walletError(.invalidQueryResolution, .walletUnavailable), .walletError(.invalidRequest, .walletUnavailable), reason: "An inner ValidationError.walletUnavailable stays wallet-side even if the wallet-kit does not lift it to the matching WalletError code."),
        .synthetic("wallet-unavailable", .walletInternal, .walletError(.walletUnavailable), reason: "wallet_unavailable is a wallet-side protocol error."),
        .synthetic("wallet-kit-own-query-resolution", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution), reason: "The wallet-kit's own checks (malformed QR data, unsupported presentation query) keep .invalidQueryResolution without a ValidationError."),
        .synthetic("internal-error", .unclassified, .walletError(.internalError), reason: "Wallet-side failure with no verifier attribution."),
        .synthetic("access-denied-without-attribution", .unclassified, .walletError(.accessDenied), reason: "A bare access_denied carries no credential or user context, so it cannot be attributed."),
        .synthetic("not-secured-request", .relyingPartyRequestInvalid, .walletError(.notSecuredRequest), reason: "Plain request from a client id scheme that requires a signed request."),
        .synthetic("foreign-error-type", .unclassified, .foreign, reason: "Anything that is not a WalletError cannot be attributed."),
        .synthetic("network-transport-failure", .relyingPartyUnreachable, .walletError(.invalidRequest, .networkError(.init(stage: .GET, url: nil, underlying: URLError(.timedOut)))), reason: "The request object never arrived while online: the typed library error is recognised as a transport failure and attributed to the relying party."),
        .synthetic("network-transport-failure-offline", .networkUnavailable, .walletError(.invalidRequest, .networkError(.init(stage: .GET, url: nil, underlying: URLError(.timedOut)))), online: false, reason: "The same typed library error while reachability says offline is reported as offline."),
        .synthetic("network-server-failure", .relyingPartyRequestInvalid, .walletError(.invalidRequest, .networkError(.init(stage: .POST, url: nil, statusCode: 401))), reason: "The verifier answered the request_uri fetch with a non-2xx status, so the request is attributed to the relying party."),
        .synthetic("transport-request-fetch-timeout", .relyingPartyUnreachable, .transport(.init(kind: .timeout, source: .openID4VPRequest)), .transport(.init(kind: .unreachable, source: .openID4VPRequest)), reason: "The request object never arrived: only the relying party can be restarted."),
        .synthetic("transport-response-uri-unreachable", .relyingPartyUnreachable, .transport(.init(kind: .unreachable, source: .openID4VPResponse)), reason: "The response_uri could not be reached at all."),
        .synthetic("transport-response-post-timeout", .connectionTimedOut, .transport(.init(kind: .timeout, source: .openID4VPResponse)), .transport(.init(kind: .timeout, source: .openID4VPResponse, statusCode: 504)), reason: "Posting the response was slow; the verifier is not known to be at fault."),
        .synthetic("transport-other-client-timeout", .connectionTimedOut, .transport(.init(kind: .timeout, source: .walletBackend)), .transport(.init(kind: .unreachable, source: .openID4VCI)), .transport(.init(kind: .timeout, source: .unknown)), reason: "Wallet services or an unwrapped URLError timed out during the presentation."),
        .synthetic("transport-reachability-offline", .networkUnavailable, .transport(.init(kind: .timeout, source: .openID4VPRequest)), online: false, reason: "An answerless timeout while reachability says offline is reported as offline."),
        .synthetic("transport-server-answer-while-offline", .connectionTimedOut, .transport(.init(kind: .timeout, source: .openID4VPResponse, statusCode: 504)), online: false, reason: "A status code proves the network worked; a reachability blip must not relabel it as offline."),
        .synthetic("transport-rate-limited", .rateLimited, .transport(.init(kind: .rateLimited, source: .openID4VPRequest, statusCode: 429)), .transport(.init(kind: .rateLimited, source: .walletBackend, statusCode: 429, retryAfter: 60)), reason: "A 429 from any endpoint gets the rate-limit dialog; the Retry-After, when known, fills in the wait."),
        .synthetic("credential-codes", .credentialNotAvailable, .walletError(.credentialNotFound), .walletError(.dcqlQueryNotSatisfied), .walletError(.credentialSetNotSatisfied), .walletError(.claimSetNotSatisfied), .walletError(.claimValueMismatch), .walletError(.claimNotFound), reason: "Every DCQL matching failure means the wallet cannot satisfy the request with its credentials."),
        .synthetic("invalid-wrprc", .relyingPartyNotTrusted, .walletError(.invalidWrprc), reason: "The verifier registration certificate (WRPRC) failed validation."),
        .synthetic("response-encryption-missing", .relyingPartyRequestInvalid, .walletError(.responseEncryptionMissing), reason: "direct_post.jwt without a response encryption specification from the verifier."),
        .synthetic("wallet-side-codes", .walletInternal, .walletError(.storageError), .walletError(.fileAccessError), .walletError(.unsupportedAlgorithm), .walletError(.invalidStatusToken), reason: "Local storage, file, crypto or status token failures are wallet-side."),
        .synthetic("unmapped-codes-stay-unclassified", .unclassified, .walletError(.bleNotAuthorized), .walletError(.offerResolutionFailed), .walletError(.userCancelledLogin), reason: "Codes outside the presentation error taxonomy fall to the default branch."),
        .synthetic("new-code-without-validation-error", .relyingPartyRequestInvalid, .walletError(.invalidClient), .walletError(.invalidScope), .walletError(.vpFormatsNotSupported), .walletError(.invalidRequestUriMethod), reason: "A protocol code without an inner ValidationError (e.g. an AuthorizationError) is a request problem."),
        .synthetic("non-dispatchable-other-inner", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .nonDispatchable(.invalidJwtPayload)), reason: "Only a missing wallet configuration makes a non-dispatchable error wallet-internal."),
        .synthetic("offline-overrides-unclassified", .networkUnavailable, .walletError(.internalError), .foreign, online: false, reason: "An unattributable failure while offline is reported as offline."),
        .synthetic("offline-overrides-new-invalid-client", .networkUnavailable, .walletError(.invalidClient, .invalidClientMetadata), online: false, reason: "The offline override also applies to the new protocol codes when the class is requestInvalid."),
        .synthetic("offline-does-not-override-marker-trust", .relyingPartyNotTrusted, .walletError(.invalidRequest, .validationError("Unable to verify signature using public key from leaf certificate")), online: false, reason: "A trust failure recognised by the string marker stays a trust failure while offline."),
        .synthetic("foreign-error-type", .unclassified, .foreign, reason: "Anything that is not a WalletError cannot be attributed.")
    ]
}
// swiftlint:enable line_length
