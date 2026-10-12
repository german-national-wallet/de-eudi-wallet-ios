//
//  ClassifiedPresentationError.swift
//  logic-core
//

import Foundation

public struct ClassifiedPresentationError: Error {
    public let errorClass: PresentationErrorClass
    public let diagnosticCode: String?
    public let diagnosticCase: String?
    public let underlying: Error
    
    public init(
        errorClass: PresentationErrorClass,
        diagnosticCode: String? = nil,
        diagnosticCase: String? = nil,
        underlying: Error
    ) {
        self.errorClass = errorClass
        self.diagnosticCode = diagnosticCode
        self.diagnosticCase = diagnosticCase
        self.underlying = underlying
    }
}
