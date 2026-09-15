//
//  TestIssuanceVarificationInteractor.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 21.10.24.
//

import XCTest
@testable import feature_issuance
@testable import logic_test

final class TestIssuanceVarificationInteractor: XCTestCase {
    var sut: IssuanceVerificationInteractorImpl!
    var mockIssuanceWorkflowInteractor: MockIssuanceWorkflowInteractor!
    var mockDelegate: MockIssuanceVerificationInteractorDelegate!
    
    override func setUp() {
        super.setUp()
        
        mockIssuanceWorkflowInteractor = MockIssuanceWorkflowInteractor()
        mockDelegate = MockIssuanceVerificationInteractorDelegate()
        
        stub(mockIssuanceWorkflowInteractor) { mock in
            when(mock.delegate.set(any())).thenDoNothing()
        }

        sut = IssuanceVerificationInteractorImpl(issuenceWorkflowInteractor: mockIssuanceWorkflowInteractor)
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockIssuanceWorkflowInteractor = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testStart_ShouldStartWorkflowController() {
        let testURL = URL(string: "https://test.com")!
        
        stub(mockIssuanceWorkflowInteractor) { mock in
          when(mock.start(tokenURL: anyString(), pin: "123456")).thenDoNothing()
        }

      stub(mockIssuanceWorkflowInteractor) { mock in
        when(mock.changeWorkFlowType(any())).thenDoNothing()
      }

      sut.start(tokenURL: testURL, pin: "123456")

      verify(mockIssuanceWorkflowInteractor).start(tokenURL: equal(to: testURL.absoluteString), pin: "123456")
    }
    
    func testDidRecognizeCard_ShouldCallDelegate() {
        stub(mockDelegate) { mock in
            when(mock.didRecognizeCard()).thenDoNothing()
        }

        sut.didRecognizeCardByWorkflowConroller()

        verify(mockDelegate).didRecognizeCard()
    }
    
    func testDidNotRecognizeCardByWorkflowController_ShouldTriggerDelegate() {
        stub(mockDelegate) { mock in
            when(mock.didNotRecognizeCard()).thenDoNothing()
        }

        sut.didNotRecognizeCardByWorkflowConroller()

        verify(mockDelegate).didNotRecognizeCard()
    }
    
    func testRequestPin_ShouldCallDelegate() {
        stub(mockDelegate) { mock in
            when(mock.requestPin()).thenDoNothing()
        }

        sut.requestPinByWorkflowConroller()

        verify(mockDelegate).requestPin()
    }
    
    func testDidReceiveSuccessByWorkflowController_ShouldTriggerDelegate() async {
        let testResult = "SuccessResult"
        
        stub(mockDelegate) { mock in
            when(mock.didSuccess(result: anyString())).thenDoNothing()
        }
        
        await sut.didReceiveSuccessByWorkflowConroller(testResult)

        verify(mockDelegate).didSuccess(result: equal(to: testResult))
    }
    
    func testStop_ShouldCallWorkflowControllerStop() {
        stub(mockIssuanceWorkflowInteractor) { mock in
            when(mock.stop()).thenDoNothing()
        }
        
        sut.stop()
        
        verify(mockIssuanceWorkflowInteractor).stop()
    }
    
    func testSetPin_ShouldCallWorkflowControllerSetPin() {
        let testPin = "1234"
        stub(mockIssuanceWorkflowInteractor) { mock in
            when(mock.setPin(testPin)).thenDoNothing()
        }
        
        sut.setPin(testPin)
        
        verify(mockIssuanceWorkflowInteractor).setPin(testPin)
    }
}
