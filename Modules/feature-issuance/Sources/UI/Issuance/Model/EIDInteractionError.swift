//
//  EIDErrorModel.swift
//  feature-issuance
//

import Foundation

public enum EIDInteractionError: Error, Equatable {
    case cardDeactivated

    case frameworkError(_ error: String? = nil, callback: String = #function, message: String? = nil)
    case identificationFailed(resultMajor: String, resultMinor: String?, refreshURL: URL?)
    case identificationFailedWithBadRequest
    case pinChangeFailed
    case unexpectedReadAttribute(String)
}

enum RedactedEIDInteractionError: CustomNSError, Hashable {
    case frameworkError(callback: String, message: String?)
    case identificationFailed(resultMajor: String, resultMinor: String?)
    case identificationFailedWithBadRequest
    case identificationFailedWithRequestMismatch
    case pinChangeFailed
    case unexpectedReadAttribute

    init?(_ eIDInteractionError: EIDInteractionError) {
        switch eIDInteractionError {
        case .frameworkError(_, let callback, let message):
            self = .frameworkError(callback: callback, message: message)
        case .unexpectedReadAttribute:
            self = .unexpectedReadAttribute
        case .identificationFailed(let resultMajor, let resultMinor, _):
            self = .identificationFailed(resultMajor: resultMajor, resultMinor: resultMinor)
        case .identificationFailedWithBadRequest:
            self = .identificationFailedWithBadRequest
        //case .identificationFailedWithRequestMismatch:
         //   self = .identificationFailedWithRequestMismatch
        case .pinChangeFailed:
            self = .pinChangeFailed
        default:
            return nil
        }
    }
    
    var errorUserInfo: [String: Any] {
        switch self {
        case .frameworkError(callback: let callback, message: let message):
            var description = "frameworkError(callback: \(callback)"
            if let message {
                description += ", message: \(message)"
            }
            return [NSDebugDescriptionErrorKey: description]
        case .identificationFailed(let resultMajor, let resultMinor):
            var description = "identificationFailed(resultMajor: \(resultMajor)"
            if let resultMinor {
                description += ", resultMinor: \(resultMinor)"
            }
            return [NSDebugDescriptionErrorKey: description]
        case .unexpectedReadAttribute,
             .identificationFailedWithBadRequest,
             .pinChangeFailed,
             .identificationFailedWithRequestMismatch:
            return [NSDebugDescriptionErrorKey: "\(self)"]
        }
    }
}
