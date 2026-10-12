//
//  OpenID4VPErrorFixture.swift
//  logic-core
//

import Foundation
import Combine
import enum OpenID4VP.ValidationError

@testable import logic_business
@testable import logic_core

enum OpenID4VPErrorFixture {
    
    struct Input {
        let walletErrorCode: WalletError.Code?
        let validationError: ValidationError?
        
        struct ForeignError: Error {}
        
        static func walletError(_ code: WalletError.Code, _ validationError: ValidationError? = nil) -> Input {
            Input(walletErrorCode: code, validationError: validationError)
        }
        
        static let foreign = Input(walletErrorCode: nil, validationError: nil)
        
        func makeError() -> Error {
            guard let walletErrorCode else {
                return ForeignError()
            }
            // wraps the ValidationError twice (PresentationSession + OpenId4VpService both wrap WalletError)
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
        .row(2, "access_denied", .credentialNotAvailable, .walletError(.noDocumentsAvailable), reason: "Wallet holds no matching credential. Spec expects access_denied; neither platform sends anything."),
        .skipped(3, "access_denied", reason: "User authentication failed (3 PIN errors). Spec expects access_denied; neither platform sends anything.", because: "Raised as BackendError(ACCOUNT_LOCKED) in the PIN flow, not as a WalletError."),
        .row(4, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .missingResponseType), reason: "response_type missing or blank. Request-object validation."),
        .row(5, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .missingResponseType), reason: "response_type is not vp_token. Request-object validation."),
        .row(6, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .missingNonce), reason: "nonce missing. Request-object validation."),
        .skipped(7, "invalid_request", reason: "direct_post / direct_post.jwt with a redirect_uri present. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .skipped(8, "invalid_request", reason: "query / fragment mode with a response_uri present. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .skipped(9, "invalid_request", reason: "x509_san_dns client: host of response_uri / redirect_uri differs from client_id. First part is the ResponseMode object (DirectPost, DirectPostJwt, Query, QueryJwt, Fragment, FragmentJwt). Request-object validation.", because: "The iOS library performs no equivalent check."),
        .row(10, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".unsupportedResponseMode direct_post")), reason: "Unknown response_mode value. Not sent by Android either (no dispatch details without a known mode)."),
        .row(11, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".missingRequiredField .responseUri")), reason: "direct_post / direct_post.jwt without response_uri. Not sent (no URI to post to)."),
        .row(12, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".missingRequiredField .responseUri")), reason: "response_uri is not a valid URL. Not sent (no URI to post to)."),
        .row(13, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".missingRequiredField .redirectUri")), reason: "query / fragment mode without redirect_uri. Not sent."),
        .row(14, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".missingRequiredField .redirectUri")), reason: "redirect_uri is not a valid URI. Not sent."),
        .row(15, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".multipleQuerySources")), reason: "Both dcql_query and a non-openid scope present. Request-object validation."),
        .row(16, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidQuerySource")), reason: "Neither dcql_query nor scope present (or scope is only 'openid'). Request-object validation."),
        .row(17, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("The data couldn’t be read because it isn’t in the correct format.")), reason: "dcql_query does not deserialise. Request-object validation."),
        .skipped(18, "invalid_request", reason: "DCQL asks for a format other than mso_mdoc or dc+sd-jwt. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .row(19, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidVerifierAttestationFormat")), reason: "verifier_info does not deserialise. Request-object validation."),
        .row(20, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidVerifierAttestationCredentialIds")), reason: "verifier_info credential_ids reference ids that are not in the DCQL. Request-object validation."),
        .row(21, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidJarmRequirement")), reason: "direct_post.jwt without client_metadata. Request-object validation."),
        .row(22, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "direct_post.jwt with client_metadata but no jwks. Request-object validation."),
        .row(23, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "jwks present but empty. Request-object validation."),
        .skipped(24, "invalid_request", reason: "Two JWKs share a kid. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .row(25, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "jwks is JSON but not a valid JWK Set. Request-object validation."),
        .row(26, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "No JWK carries both kid and alg. Request-object validation."),
        .row(27, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "No JWK with alg ECDH-ES usable for encryption. Wallet supports ECDH-ES only. Request-object validation."),
        .row(28, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "encrypted_response_enc_values_supported has no overlap with A128CBC-HS256 / A256GCM (Android) or A128GCM / A256GCM (iOS). Request-object validation."),
        .row(29, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "encrypted_response_enc_values_supported present but empty. Request-object validation."),
        .row(30, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .invalidClientMetadata), reason: "encrypted_response_enc_values_supported given for a non-JWT response_mode. Request-object validation."),
        .skipped(31, "invalid_request", reason: "vp_formats_supported in client_metadata lacks a format the DCQL requests. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .row(32, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("clientId is missing from plain request")), .walletError(.invalidQueryResolution, .validationError("clientId is missing")), reason: "No client_id in the authorization request URI. Raised while fetching or authenticating the request."),
        .row(33, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidUseOfBothRequestAndRequestUri")), reason: "Both request and request_uri present. Raised while fetching or authenticating the request."),
        .row(34, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Scheme x509_san_dns not supported")), reason: "x509_san_dns client_id used in a plain (unsigned) request. Raised while fetching or authenticating the request."),
        .row(35, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Scheme x509_hash not supported")), reason: "x509_hash client_id used in a plain (unsigned) request. Raised while fetching or authenticating the request."),
        .row(36, "invalid_request", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".unsupportedClientIdScheme openid_federation")), reason: "client_id fails to parse. Raised while fetching or authenticating the request."),
        .row(37, "invalid_client", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("No supported client Id scheme")), reason: "client_id prefix is not x509_san_dns or x509_hash (redirect_uri, decentralized_identifier, verifier_attestation, openid_federation, or no prefix)."),
        .row(38, "invalid_client", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidClientId")), reason: "Unreachable on Android: only raised for pre-registered, redirect_uri and DID clients."),
        .row(39, "invalid_request_uri_method", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidRequestUriMethod")), reason: "request_uri_method is not exactly 'get' or 'post', or is combined with request by value. Raised while fetching or authenticating the request."),
        .row(40, "invalid_request_uri", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError(".invalidJwtPayload")), reason: "GET or POST to request_uri returned an error. Raised while fetching or authenticating the request."),
        .row(41, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Invalid compact serialization")), reason: "JAR is not a parseable signed JWT. JAR problem. Raised while fetching or authenticating the request."),
        .row(42, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("algorithm should not be nil")), reason: "JOSE header has no alg. JAR problem. Raised while fetching or authenticating the request."),
        .row(43, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("nonce's do not match")), reason: "alg is not ES256, ES384 or ES512. JAR problem. Raised while fetching or authenticating the request."),
        .row(44, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("client_id's do not match")), reason: "client_id in the URI differs from the one inside the JAR. JAR problem. Raised while fetching or authenticating the request."),
        .row(45, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("wallet_nonce mismatch")), .walletError(.invalidQueryResolution, .validationError("wallet_nonce missing in JWT")), reason: "POST request_uri_method: JAR does not echo the wallet_nonce. JAR problem. Raised while fetching or authenticating the request."),
        .row(46, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("No certificate in header")), .walletError(.invalidQueryResolution, .validationError("x5c header field does not contain a serialized leaf certificate")), reason: "No x5c in the JOSE header. JAR problem. Raised while fetching or authenticating the request."),
        .row(47, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("No valid certificate in chain")), .walletError(.invalidQueryResolution, .validationError("No certificate in chain")), reason: "No certificate in x5c parses. JAR problem. Raised while fetching or authenticating the request."),
        .row(48, "invalid_request_object", .relyingPartyNotTrusted, .walletError(.trustError, .validationError("Could not trust certificate chain")), reason: "Chain not trusted by the wallet's reader trust store. Either the RP uses an unregistered certificate or the wallet's trust list is outdated. JAR problem. Raised while fetching or authenticating the request."),
        .row(49, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Client id (x509_san_dns:verifier.example.com not part of list ())")), reason: "x509_san_dns: leaf certificate has no DNS SAN. By decision not covered by a trust marker, so it falls to the default relying-party class."),
        .row(50, "invalid_request_object", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Client id (x509_san_dns:verifier.example.com not part of list ([\"other.example.com\"]))")), reason: "x509_san_dns: client_id not among the DNS SANs. By decision not covered by a trust marker, so it falls to the default relying-party class."),
        .row(51, "invalid_request_object", .relyingPartyNotTrusted, .walletError(.invalidQueryResolution, .validationError("ClientId does not match leaf certificate's SHA-256 hash")), reason: "x509_hash: client_id is not the base64url SHA-256 of the leaf certificate. JAR problem. Raised while fetching or authenticating the request."),
        .row(52, "invalid_request_object", .relyingPartyNotTrusted, .walletError(.invalidQueryResolution, .validationError("Unable to verify signature using public key from leaf certificate")), .walletError(.invalidQueryResolution, .validationError("Unable to decode public key from leaf certificate")), reason: "Signature, typ (oauth-authz-req+jwt) or time claims fail verification. JAR problem. Raised while fetching or authenticating the request."),
        .row(53, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Unable to decode transaction data")), reason: "transaction_data entry has no type. transaction_data validation. Request-object validation."),
        .row(54, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Unable to decode transaction data")), reason: "transaction_data entry has no credential_ids. transaction_data validation. Request-object validation."),
        .row(55, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Unable to decode transaction data")), reason: "type is not a string. transaction_data validation. Request-object validation."),
        .row(56, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Unable to decode transaction data")), reason: "Entry is not base64url-encoded JSON. transaction_data validation. Request-object validation."),
        .row(57, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Invalid credential IDs: [\"cred_1\"]")), reason: "credential_ids reference ids not in the DCQL. transaction_data validation. Request-object validation."),
        .skipped(58, "invalid_transaction_data", reason: "credential_ids is empty. transaction_data validation. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .skipped(59, "invalid_transaction_data", reason: "Referenced credentials mix formats. transaction_data validation. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .skipped(60, "invalid_transaction_data", reason: "Referenced credentials are mso_mdoc; transaction data is only defined for SD-JWT. transaction_data validation. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .skipped(61, "invalid_transaction_data", reason: "transaction_data_hashes_alg present but empty. transaction_data validation. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .row(62, "invalid_transaction_data", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Unsupported transaction data type: urn:eudi:payment:1")), reason: "Any well-formed SD-JWT transaction_data. The Android wallet registers no supported transaction data types, so every type is rejected. transaction_data validation. Request-object validation."),
        .skipped(63, "invalid_transaction_data", reason: "transaction_data_hashes_alg explicitly lists only algorithms the wallet does not support for that transaction data type. A configured type must always include sha-256 (lib Config.kt:169) and sha-256 is also the default when the RP omits the parameter, so this only fires when the RP names other algorithms without sha-256. transaction_data validation. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .skipped(64, "vp_formats_not_supported", reason: "client_metadata vp_formats_supported has no algorithm in common with the wallet (ES256), or none of the requested formats survive the intersection. Request-object validation.", because: "The iOS library performs no equivalent check."),
        .row(65, "invalid_request (iOS only)", .relyingPartyRequestInvalid, .walletError(.invalidQueryResolution, .validationError("Invalid aud value, should be: https://self-issued.me/v2")), reason: "JAR aud claim does not match the wallet audience.")
    ]
    
    static let syntheticCases: [SyntheticCase] = [
        .synthetic("offline-overrides-invalid-request", .networkUnavailable, .walletError(.invalidQueryResolution, .validationError(".invalidJwtPayload")), online: false, reason: "A request-resolution failure while the device is offline is reported as offline."),
        .synthetic("offline-does-not-override-trust", .relyingPartyNotTrusted, .walletError(.invalidQueryResolution, .validationError("Could not trust certificate chain")), online: false, reason: "A trust failure stays a trust failure even when the device is offline."),
        .synthetic("offline-does-not-override-missing-credential", .credentialNotAvailable, .walletError(.noDocumentsAvailable), online: false, reason: "A missing credential stays a missing credential even when the device is offline."),
        .synthetic("trust-failure-without-side-channel", .relyingPartyNotTrusted, .walletError(.invalidQueryResolution, .validationError("Could not trust certificate chain")), reason: "chainVerifier bailed out before writing readerCertificateValidationMessage, so only the message identifies the trust failure."),
        .synthetic("wallet-configuration-failure", .walletInternal, .walletError(.invalidQueryResolution, .nonDispatchable(.missingConfiguration)), reason: "getWalletConf() returned nil, an identified wallet-side failure."),
        .synthetic("offline-does-not-override-wallet-internal", .walletInternal, .walletError(.invalidQueryResolution, .nonDispatchable(.missingConfiguration)), online: false, reason: "A local key-generation failure is not a connectivity problem, so the offline dialog must not be shown."),
        .synthetic("internal-error", .unclassified, .walletError(.internalError), reason: "Wallet-side failure with no verifier attribution."),
        .synthetic("not-secured-request", .relyingPartyRequestInvalid, .walletError(.notSecuredRequest), reason: "Plain request from a client id scheme that requires a signed request."),
        .synthetic("foreign-error-type", .unclassified, .foreign, reason: "Anything that is not a WalletError cannot be attributed.")
    ]
}
// swiftlint:enable line_length
