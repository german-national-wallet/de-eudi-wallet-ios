//
//  PresentationErrorClassifierTests.swift
//  logic-core
//

import Testing
import Cuckoo
import Foundation
import enum OpenID4VP.ValidationError
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
            .networkUnavailable,
            .unclassified
        ]
        #expect(
            covered == reachable,
            "Classes with no fixture coverage: \(reachable.subtracting(covered).map(\.rawValue))"
        )
    }
    
    private func makeSut(isOnline: Bool) -> PresentationErrorClassifier {
        let reachabilityController = MockReachabilityController()
        stub(reachabilityController) { mock in
            when(mock.hasInternet()).thenReturn(isOnline)
        }
        return PresentationErrorClassifierImpl(reachabilityController: reachabilityController)
    }
}
