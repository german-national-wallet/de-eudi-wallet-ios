//
//  EIDInteractorEvent.swift
//  feature-issuance
//
import Foundation

public enum EIDInteractionEvent: Equatable {
    case cardInsertionRequested
    case cardRecognized
    case canRequested
    case pinRequested(remainingAttempts: Int?)
    case newPINRequested
    case pukRequested
    case identificationStarted
    case identificationSucceeded(redirectURL: URL?)
    case identificationCancelled
    case pinChangeStarted
    case pinChangeSucceeded
    case pinChangeCancelled
}

enum RedactedEIDInteractionEventError: CustomNSError {
    case cardInsertionRequested
    case cardRecognized
    case canRequested
    case pinRequested
    case newPINRequested
    case pukRequested
    case identificationStarted
    case identificationSucceededWithRedirect
    case identificationSucceededWithoutRedirect
    case identificationRequestConfirmationRequested
    case identificationCancelled
    case pinChangeStarted
    case pinChangeSucceeded
    case pinChangeCancelled
    case certificateDescriptionRetrieved
    
    init(_ event: EIDInteractionEvent) {
        switch event {
        case .cardInsertionRequested: self = .cardInsertionRequested
        case .cardRecognized: self = .cardRecognized
        case .canRequested: self = .canRequested
        case .pinRequested: self = .pinRequested
        case .newPINRequested: self = .newPINRequested
        case .pukRequested: self = .pukRequested
        case .identificationStarted: self = .identificationStarted
        case .identificationSucceeded(redirectURL: .some): self = .identificationSucceededWithRedirect
        case .identificationSucceeded(redirectURL: .none): self = .identificationSucceededWithoutRedirect
        case .identificationCancelled: self = .identificationCancelled
        case .pinChangeStarted: self = .pinChangeStarted
        case .pinChangeSucceeded: self = .pinChangeSucceeded
        case .pinChangeCancelled: self = .pinChangeCancelled
        }
    }
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: "\(self)"]
    }
}
