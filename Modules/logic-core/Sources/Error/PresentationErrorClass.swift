//
//  PresentationErrorClass.swift
//  logic-core
//
import Foundation

public enum PresentationErrorOrigin: String, Sendable {
    case relyingParty
    case wallet
    case device
    case user
    case unknown
}

public enum PresentationErrorClass: String, Sendable, Equatable, CaseIterable {
    case userDeclined
    case credentialNotAvailable
    case walletInternal
    case walletPinBlocked
    case relyingPartyRequestInvalid
    case relyingPartyNotTrusted
    case networkUnavailable
    case unclassified
    
    public var origin: PresentationErrorOrigin {
        switch self {
        case .userDeclined, .walletPinBlocked: .user
        case .credentialNotAvailable, .walletInternal: .wallet
        case .relyingPartyRequestInvalid, .relyingPartyNotTrusted: .relyingParty
        case .networkUnavailable: .device
        case .unclassified: .unknown
        }
    }
}
