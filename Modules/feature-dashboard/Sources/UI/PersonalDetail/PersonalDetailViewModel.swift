//
//  PersonalDetailViewModel.swift
//  feature-dashboard
//
import Foundation
import logic_ui
import logic_core
import logic_resources
import logic_business

struct PersonalDetailState: ViewState {
  let document: DocClaimsDecodable
  let documentType: DocumentTypeIdentifier
}

final class PersonalDetailViewModel<Router: RouterHost>: ViewModel<Router, PersonalDetailState> {
  private let interactor: DashboardInteractor
  @Published var credentialDetailItems: [ListItem] = []
  
  init(
    router: Router,
    interactor: DashboardInteractor,
    document: DocClaimsDecodable
  ) {
    self.interactor = interactor

    let raw = document.documentTypeIdentifier.rawValue
    let docType = DocumentTypeIdentifier(rawValue: raw)

    let state = PersonalDetailState(
      document: document,
      documentType: docType
    )

    super.init(
      router: router,
      initialState: state
    )
    
    configureClaimDisplay()

  }
  
  func configureClaimDisplay() {
    let allItems = viewState.document.docClaims.map { claim in
      let rawValue = claim.children?.first?.stringValue ?? claim.stringValue
      
      let value = rawValue.isValidISODate()
      ? convertDateFormat(rawValue, fromFormat: DateFormatType.iso8601DateTime.rawValue)
      : rawValue
      
      return ListItem(
        title: claim.displayName ?? claim.name,
        detail: value,
        index: claim.order
      )
    }
    
    credentialDetailItems = allItems.sorted { $0.index < $1.index }
  }
  
  private func convertDateFormat(_ date: String, fromFormat: String = DateFormatType.yyyyMMdd.rawValue, toFormat: String = "dd. MMM yyyy") -> String {
    return (date.toFormattedDateString(from: fromFormat, to: toFormat, locale: Locale.current) ?? "")
  }
  
  private func convertDEToFullName(code: String) -> String {
    code.uppercased() == "DE" ? "Deutschland" : code
  }
  
  private func parseAgeEqualOrOver(_ ageEqualOrOver: String) -> String {
    let trimmed = ageEqualOrOver.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
    let pairs = trimmed.split(separator: ",")
    var result = [String]()
    for pair in pairs {
        let keyValue = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        if keyValue.count == 2 {
          let value = keyValue[1]=="Y" ? LocalizableStringKey.pidIssuanceDataConsentLabelAgeEqualOrOverYes.toString.capitalized : LocalizableStringKey.pidIssuanceDataConsentLabelAgeEqualOrOverNo.toString.capitalized
          result.append("\(keyValue[0]) \(LocalizableStringKey.years.toString.capitalized): \(value)")
        }
    }
    let res = result.sorted { $0 < $1 }.joined(separator: "\n")
    return res
  }
  
  struct ListItem {
    let title: String
    let detail: String
    let index: Int
    let showDivider: Bool
    
    init(title: String, detail: String, index: Int, showDivider: Bool = false) {
      self.title = title
      self.detail = detail
      self.index = index
      self.showDivider = showDivider
    }
  }
}
