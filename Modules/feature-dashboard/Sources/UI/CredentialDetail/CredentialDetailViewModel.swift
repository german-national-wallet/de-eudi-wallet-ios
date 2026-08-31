//
//  CredentialDetailViewModel.swift
//  feature-dashboard
//
import Foundation
import logic_ui
import logic_core
import logic_resources
import feature_startup
import feature_common
import logic_business
import logic_api

@Copyable
struct UserProfileState: ViewState {
  let document: DocClaimsDecodable
}

final class CredentialDetailViewModel<Router: RouterHost>: ViewModel<Router, UserProfileState> {
  private let interactor: DashboardInteractor
  private let deepLinkController: DeepLinkController
  private let pidRevokeInteractor: PIDRevokeInteractor

  @Published var documentName: String = ""
  @Published var validityDate: String = ""
  @Published var documentIssuanceDate: String = ""
  @Published var isErrorPopupVisible = false
  var errorPopupViewModel = ConfirmationPopupViewModel()

  init(
    router: Router,
    interactor: DashboardInteractor,
    document: DocClaimsDecodable,
    deepLinkController: DeepLinkController,
    pidRevokeInteractor: PIDRevokeInteractor
  ) {
    self.interactor = interactor
    self.deepLinkController = deepLinkController
    self.pidRevokeInteractor = pidRevokeInteractor

    super.init(
      router: router,
      initialState: .init(
        document: document
      )
    )
    setData()
  }
  
  func viewProfileDetailTapped() {
    router.push(with: .featureDashboardModule(.personalDetail(viewState.document)))
  }
  
  func setData() {
    let doc = viewState.document
    setIssuerName(doc)
    setPIDExpirationDate(doc)
    setIssuanceDate(createdDate: doc.createdAt)
  }
  
  private func setIssuerName(_ doc: DocClaimsDecodable) {
    if isCredentialPID() {
      self.documentName = LocalizableStringKey.dashboardCardTitle.toString
    } else {
      self.documentName = doc.display?.first?.name ?? ""
    }
  }
  
  private func setPIDExpirationDate(_ doc: DocClaimsDecodable) {
    if let expirationDate = doc.docClaims.first(where: { $0.name == "exp" || $0.name == "expiry_date" })?.dataValue.description {
      if let date = Date.convertISO8601String(expirationDate) {
        validityDate = date
      } else {
        validityDate = expirationDate
      }
    }
  }
  
  func isCredentialPID() -> Bool {
    let rawValue = viewState.document.documentTypeIdentifier.rawValue
    return DocumentTypeIdentifier(rawValue: rawValue) == .mDocPid || DocumentTypeIdentifier(rawValue: rawValue) == .sdJwtPid
  }

  func deleteCredential() async throws {
    do {
      if isCredentialPID() {
        try await pidRevokeInteractor.deletePIDFromWallet()
      } else {
        try await interactor.deleteDocument(with: viewState.document.id)
      }
    } catch let error as BackendError {
      errorPopupViewModel.configure(backendError: error) { [weak self] in
        self?.isErrorPopupVisible = false
      }
      isErrorPopupVisible = true
      return
    } catch {
      errorPopupViewModel.configureDefaultError { [weak self] in
        self?.isErrorPopupVisible = false
      }
      isErrorPopupVisible = true
      return
    }

    let additionalDocs = try interactor.getAdditionalDocuments() ?? []
    let pidDoc = try interactor.getPIDDocument()
    let isWalletEmpty = additionalDocs.isEmpty && pidDoc == nil

    if isWalletEmpty {
      await resetToStartup()
    } else {
      router.pop()
    }
  }

  private func resetToStartup() async {
      await deepLinkController.setDeeplinkFlowFlag(false)
      router.popTo(with: .featureStartupModule(.startup))
  }
  
  func setIssuanceDate(createdDate: Date) {
    documentIssuanceDate = createdDate.formatDate(format: "dd.MM.yyyy")
  }
}
