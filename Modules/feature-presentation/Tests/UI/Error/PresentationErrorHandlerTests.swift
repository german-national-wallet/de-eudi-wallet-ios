//
//  PresentationErrorHandlerTests.swift
//  feature-presentation
//

import XCTest
import Cuckoo
import logic_analytics
import logic_api
import logic_core
import logic_ui
import logic_resources
@testable import feature_presentation
@testable import feature_test

final class PresentationErrorHandlerTests: XCTestCase {
    
    private var classifier: MockPresentationErrorClassifier!
    private var analyticsController: MockAnalyticsController!
    private var walletKitController: MockWalletKitController!
    private var sut: PresentationErrorHandlerImpl!
    private let originator: AppRoute = .featureDashboardModule(.dashboard)
    
    override func setUp() {
        super.setUp()
        
        classifier = MockPresentationErrorClassifier()
        analyticsController = MockAnalyticsController()
        walletKitController = MockWalletKitController()
        sut = PresentationErrorHandlerImpl(
            classifier: classifier,
            analyticsController: analyticsController,
            walletKitController: walletKitController
        )
        stub(analyticsController) { mock in
            when(mock.currentTraceID.get).thenReturn("active-trace")
            when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
        }
        stub(walletKitController) { mock in
            when(mock.fetchIssuedDocuments(with: any())).thenReturn([])
        }
    }
    
    override func tearDown() {
        sut = nil
        walletKitController = nil
        analyticsController = nil
        classifier = nil
        
        super.tearDown()
    }
    
    // MARK: - Dialog states
    
    func testHandle_WhenUnclassified_ThenGenericDialogCarriesTraceIdWithoutErrorCode() {
        stubClassifier(.unclassified)
        
        let dialog = dialog(handling: TestNSError.generic)
        
        XCTAssertEqual(dialog?.title, .globalGenericPresentationErrorTitle)
        XCTAssertEqual(dialog?.message, .globalGenericPresentationErrorParagraph)
        XCTAssertNil(dialog?.errorCode)
        XCTAssertEqual(dialog?.traceId, "trace-id")
        XCTAssertEqual(dialog?.primary.title, .globalGenericPresentationErrorPrimButton)
        XCTAssertEqual(dialog?.primary.action, .popTo(originator))
        XCTAssertNil(dialog?.secondary)
    }
    
    func testHandle_WhenRequestInvalid_ThenDialogShowsDiagnosticCodeAndCase() {
        stubClassifier(.relyingPartyRequestInvalid, code: "invalidQueryResolution", diagnosticCase: "missingNonce")
        
        let dialog = dialog(handling: TestNSError.generic)
        
        XCTAssertEqual(dialog?.title, .pidPresentationMalformedPresentationTitle)
        XCTAssertEqual(dialog?.message, .pidPresentationMalformedPresentationParagraph)
        XCTAssertEqual(dialog?.primary.title, .pidPresentationMalformedPresentationPrimButton)
        XCTAssertEqual(dialog?.errorCode, "invalidQueryResolution.missingNonce")
        XCTAssertEqual(dialog?.traceId, "trace-id")
    }
    
    func testHandle_WhenWalletInternal_ThenGenericDialogCarriesDiagnosticCode() {
        stubClassifier(.walletInternal, code: "storageError")
        
        let dialog = dialog(handling: TestNSError.generic)
        
        XCTAssertEqual(dialog?.title, .globalGenericPresentationErrorTitle)
        XCTAssertEqual(dialog?.message, .globalGenericPresentationErrorParagraph)
        XCTAssertEqual(dialog?.primary.title, .globalGenericPresentationErrorPrimButton)
        XCTAssertEqual(dialog?.errorCode, "storageError")
        XCTAssertEqual(dialog?.traceId, "trace-id")
    }
    
    func testHandle_WhenNetworkUnavailable_ThenOfflineDialogWithoutErrorCode() {
        stubClassifier(.networkUnavailable, code: "invalidQueryResolution")
        
        let dialog = dialog(handling: TestNSError.generic)
        
        XCTAssertEqual(dialog?.title, .globalNoInternetErrorTitle)
        XCTAssertEqual(dialog?.message, .globalNoInternetErrorParagraph)
        XCTAssertEqual(dialog?.primary.title, .globalNoInternetErrorPrimButton)
        XCTAssertNil(dialog?.errorCode)
        XCTAssertEqual(dialog?.primary.action, .popTo(originator))
    }
    
    func testHandle_WhenEndTraceReturnsNil_ThenDialogFallsBackToActiveTraceId() {
        stubClassifier(.unclassified)
        stub(analyticsController) { mock in
            when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn(nil)
        }
        
        let dialog = dialog(handling: TestNSError.generic)
        
        XCTAssertEqual(dialog?.traceId, "active-trace")
    }
    
    func testHandle_WhenClassified_ThenTraceEndsWithClassAttributes() {
        stubClassifier(.relyingPartyRequestInvalid, code: "notSecuredRequest")
        
        _ = sut.handle(TestNSError.generic, originator: originator)
        
        let expected = [
            AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.failure,
            AnalyticsConstants.TraceAttribute.errorClass: PresentationErrorClass.relyingPartyRequestInvalid.rawValue,
            AnalyticsConstants.TraceAttribute.errorOrigin: PresentationErrorOrigin.relyingParty.rawValue,
            AnalyticsConstants.TraceAttribute.errorCode: "notSecuredRequest"
        ]
        verify(analyticsController).endTrace(
            finalAttributes: equal(to: expected),
            errorDescription: equal(to: String(describing: TestNSError.generic,))
        )
    }
    
    // MARK: - Notice Screen states

    func testHandle_WhenNotTrusted_ThenNoticeOffersReportAndBackToService() {
        stubClassifier(.relyingPartyNotTrusted, code: "trustError")
        
        let notice = notice(handling: TestNSError.generic)
        
        XCTAssertEqual(notice?.title, .pidPresentationDialogRpUnkownTitle)
        XCTAssertEqual(notice?.message, .pidPresentationDialogRpUnkownParagraphCertFailed)
        XCTAssertEqual(notice?.originator, originator)
        XCTAssertEqual(notice?.primary.title, .pidPresentationDialogRpUnkownPrimButton)
        guard case .reportSuspicion = notice?.primary.action else {
            return XCTFail("expected reportSuspicion, got \(String(describing: notice?.primary.action))")
        }
        XCTAssertEqual(notice?.secondary?.title, .pidPresentationDialogRpUnkownSecButton)
        
        guard case .popTo(let route) = notice?.secondary?.action else {
            return XCTFail("expected popTo, got \(String(describing: notice?.secondary?.action))")
        }
        XCTAssertEqual(route, originator)
    }
    
    func testHandle_WhenCredentialNotAvailableAndNoPID_ThenPidMissingNotice() {
        stubClassifier(.credentialNotAvailable, code: "credentialNotFound")
        
        let notice = notice(handling: TestNSError.generic)
        
        XCTAssertEqual(notice?.title, .pidPresentationNoIssuedPidTitle)
        XCTAssertEqual(notice?.message, .pidPresentationNoIssuedPidParagraph)
        XCTAssertEqual(notice?.primary.title, .pidPresentationNoIssuedPidPrimButton)
        XCTAssertNil(notice?.secondary)
        verify(walletKitController).fetchIssuedDocuments(with: any())
    }
    
    func testHandle_WhenCredentialNotAvailableAndPIDIssued_ThenCredentialMissingNotice() {
        stubClassifier(.credentialNotAvailable, code: "dcqlQueryNotSatisfied")
        stub(walletKitController) { mock in
            when(mock.fetchIssuedDocuments(with: any())).thenReturn([Constants.euPidModel])
        }
        
        let notice = notice(handling: TestNSError.generic)
        
        XCTAssertEqual(notice?.title, .eaaPresentationCredentialNotFoundTitle)
        XCTAssertEqual(notice?.message, .eaaPresentationCredentialNotFoundParagraphCredentalNotAvailable)
        XCTAssertEqual(notice?.primary.title, .globalToOverviewButton)
        XCTAssertNil(notice?.secondary)
    }
    
    // MARK: - RWSCA failures on the send path
    
    func testHandle_WhenBackendAccountUnknown_ThenResetDialogWithServerCodeAndAnalyticsTrace() {
        let error = BackendError.serverError(
            code: RWSCAServerErrorCode.accountUnknown,
            description: "unknown account",
            traceID: "server-trace"
        )
        
        let dialog = dialog(handling: error)
        
        XCTAssertEqual(dialog?.title, .pidPresentationRwscdAccountUnknownTitle)
        XCTAssertEqual(dialog?.errorCode, RWSCAServerErrorCode.accountUnknown)
        XCTAssertEqual(dialog?.traceId, "trace-id")
        XCTAssertEqual(dialog?.primary.title, .pidPresentationRwscdAccountUnknownPrimButton)
        XCTAssertEqual(dialog?.primary.action, .addDigitalIDAgain)
        XCTAssertEqual(dialog?.secondary?.title, .pidPresentationRwscdAccountUnknownSecButton)
        XCTAssertEqual(dialog?.secondary?.action, .popTo(originator))
        verify(classifier, never()).classify(any())
        let expected = [
            AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.failure,
            AnalyticsConstants.TraceAttribute.errorCode: RWSCAServerErrorCode.accountUnknown,
            AnalyticsConstants.TraceAttribute.serverTraceID: "server-trace"
        ]
        verify(analyticsController).endTrace(
            finalAttributes: equal(to: expected),
            errorDescription: equal(to: String(describing: error))
        )
    }
    
    func testHandle_WhenBackendAuthVerificationFailed_ThenGotItDialog() {
        let error = BackendError.serverError(
            code: RWSCAServerErrorCode.authVerificationFailed,
            description: "verification failed",
            traceID: ""
        )
        
        let dialog = dialog(handling: error)
        
        XCTAssertEqual(dialog?.title, .pidPresentationRwscdAuthVerificationFailedTitle)
        XCTAssertEqual(dialog?.errorCode, RWSCAServerErrorCode.authVerificationFailed)
        XCTAssertEqual(dialog?.primary.title, .pidPresentationRwscdAuthVerificationFailedPrimButton)
        XCTAssertEqual(dialog?.primary.action, .popTo(originator))
        XCTAssertNil(dialog?.secondary)
    }
    
    func testHandle_WhenBackendCodeUnknown_ThenGenericDialogKeepsCode() {
        let error = BackendError.serverError(code: "SOMETHING_ELSE", description: "", traceID: "server-trace")
        
        let dialog = dialog(handling: error)
        
        XCTAssertEqual(dialog?.title, .globalGenericPresentationErrorTitle)
        XCTAssertEqual(dialog?.errorCode, "SOMETHING_ELSE")
        XCTAssertEqual(dialog?.traceId, "trace-id")
    }
    
    func testHandle_WhenBackendErrorHasNoCode_ThenClassifierDecides() {
        stubClassifier(.unclassified)
        
        let dialog = dialog(handling: BackendError.unknown)
        
        XCTAssertEqual(dialog?.title, .globalGenericPresentationErrorTitle)
        XCTAssertNil(dialog?.errorCode)
        verify(classifier).classify(any())
    }

    // MARK: - Retry

    func testHandle_WhenNetworkUnavailableWithRetry_ThenRetryIsPrimaryAndLeaveIsSecondary() {
        stubClassifier(.networkUnavailable, code: "invalidQueryResolution")
        let retry = PresentationErrorDialogConfig.RetryAction(action: {})

        guard case .dialog(let dialog) = sut.handle(TestNSError.generic, originator: originator, retryAction: retry) else {
            return XCTFail("expected a dialog presentation")
        }

        XCTAssertEqual(dialog.primary.title, .globalTryAgainButton)
        XCTAssertEqual(dialog.primary.action, .retry(retry))
        XCTAssertEqual(dialog.secondary?.title, .globalNoInternetErrorPrimButton)
        XCTAssertEqual(dialog.secondary?.action, .popTo(originator))
    }

    func testHandle_WhenNotNetworkUnavailable_ThenRetryActionIsIgnored() {
        let retry = PresentationErrorDialogConfig.RetryAction(action: {})
        for errorClass in PresentationErrorClass.allCases where errorClass != .networkUnavailable {
            stubClassifier(errorClass, code: "any")
            let presentation = sut.handle(TestNSError.generic, originator: originator, retryAction: retry)
            if case .dialog(let dialog) = presentation {
                XCTAssertNotEqual(dialog.primary.action, .retry(retry), "\(errorClass)")
                XCTAssertNotEqual(dialog.secondary?.action, .retry(retry), "\(errorClass)")
              }
        }
    }

    // MARK: - Helpers
    
    private func stubClassifier(
        _ errorClass: PresentationErrorClass,
        code: String? = nil,
        diagnosticCase: String? = nil
    ) {
        stub(classifier) { mock in
            when(mock.classify(any())).thenReturn(
                ClassifiedPresentationError(
                    errorClass: errorClass,
                    diagnosticCode: code,
                    diagnosticCase: diagnosticCase,
                    underlying: TestNSError.generic
                )
            )
        }
    }
    
    private func dialog(
        handling error: Error,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PresentationErrorDialogConfig? {
        if case .dialog(let config) = sut.handle(error, originator: originator) {
            return config
        }
        XCTFail("expected a dialog presentation", file: file, line: line)
        return nil
    }
    
    private func notice(
        handling error: Error,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PresentationErrorNoticeConfig? {
        if case .notice(let config) = sut.handle(error, originator: originator) {
            return config
        }
        XCTFail("expected a notice presentation", file: file, line: line)
        return nil
    }
}

private enum TestNSError {
    static let generic = NSError(domain: "PresentationErrorHandlerTests", code: 1)
}


