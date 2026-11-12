//
//  ClassifiedPresentationError.swift
//  logic-core
//

import Foundation

public struct ClassifiedPresentationError: Error {
    public let errorClass: PresentationErrorClass
    public let origin: PresentationErrorOrigin
    public let diagnosticCode: String?
    public let diagnosticCase: String?
    public let transportFailure: TransportFailure?
    public let underlying: Error
    
    public init(
        errorClass: PresentationErrorClass,
        origin: PresentationErrorOrigin? = nil,
        diagnosticCode: String? = nil,
        diagnosticCase: String? = nil,
        transportFailure: TransportFailure? = nil,
        underlying: Error
    ) {
        self.errorClass = errorClass
        self.origin = origin ?? errorClass.origin
        self.diagnosticCode = diagnosticCode
        self.diagnosticCase = diagnosticCase
        self.transportFailure = transportFailure
        self.underlying = underlying
    }
}
