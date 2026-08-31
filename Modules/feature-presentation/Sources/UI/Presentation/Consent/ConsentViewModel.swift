//
//  ConsentViewModel.swift
//  feature-presentation
//
import Foundation
import logic_ui
import logic_core
import logic_analytics
import feature_common
import logic_resources
import feature_issuance

struct ConsentItem {
  let docId: String
  let title: String
  let description: String
}

struct ConsentItemGroup {
  let credentialTitle: String
  let credentialID: String
  let items: [ConsentItem]
}

final class ConsentViewModel<Router: RouterHost>: BaseRequestViewModel<Router> {
  @Published var consentItems: [ConsentItem] = []
  @Published var consentItemGroups: [ConsentItemGroup] = []
  @Published var isConfirmationPopupVisible = false
  
  let interactor: PresentationInteractor
  let pinSessionInteractor: PinSessionInteractor
  private let analyticsController: AnalyticsController

  private let relyingParty: String
  private let pidDocTypeRawValues: Set<String> = [
    DocumentTypeIdentifier.mDocPid.rawValue,
    DocumentTypeIdentifier.sdJwtPid.rawValue
  ]
  let confirmationPopupViewModel = ConfirmationPopupViewModel()
  
  init(
    router: Router,
    interactor: PresentationInteractor,
    pinSessionInteractor: PinSessionInteractor,
    analyticsController: AnalyticsController,
    originator: AppRoute,
    relyingParty: String
  ) {
    self.interactor = interactor
    self.pinSessionInteractor = pinSessionInteractor
    self.analyticsController = analyticsController
    self.relyingParty = relyingParty
    super.init(router: router, originator: originator)
  }
  
  override func doWork() async {
    self.onStartLoading()

    let result = await Task.detached { () -> Result<OnlineAuthenticationRequestSuccessModel, Error> in
      return await self.interactor.onDeviceEngagement()
    }.value

    switch result {
    case .success(let authenticationRequest):
      consentItemGroups = authenticationRequest.requestDataCells.map { requestDataCell in
        .init(
          credentialTitle: requestDataCell.section.title,
          credentialID: requestDataCell.section.id, 
          items: flattenConsentItems(
            requestDataCell.section.listItems,
            sectionId: requestDataCell.section.id
          )
        )
      }
      consentItems = consentItemGroups.flatMap(\.items)
      
      self.onReceivedItems(
        with: authenticationRequest.requestDataCells,
        title: .requestDataTitle(
          [authenticationRequest.relyingParty]
        ),
        relyingParty: .custom(authenticationRequest.relyingParty),
        isTrusted: authenticationRequest.isTrusted
      )
      setState {
        $0.copy(
          contentHeaderConfig: .init(
            appIconAndTextData: AppIconAndTextData(
              appIcon: ThemeManager.shared.image.logoEuDigitalIndentityWallet,
              appText: ThemeManager.shared.image.euditext
            ),
            description: .dataSharingTitle,
            mainText: getTitle(),
            relyingPartyData: RelyingPartyData(
              isVerified: viewState.isTrusted,
              name: getRelyingParty(),
              description: getCaption()
            )
          )
        )
      }
    case .failure:
      self.onEmptyDocuments()
    }
  }
  
  override func onShare() {
    Task {
      let items = self.viewState.items
      let documentIDs = items.map(\.section.id)
      let isPIDRequest = interactor.isPIDPresentation(documentIDs: documentIDs)

      let result = await Task.detached { () -> Result<RequestItemConvertible, Error> in
        return await self.interactor.onResponsePrepare(requestItems: items)
      }.value

      switch result {
      case .success:
        if let route = isPIDRequest ? self.getPinRoute() : self.getSuccessRoute() {
          self.router.push(with: route)
        } else {
          self.router.popTo(
            with: self.getPopRoute() ?? .featureDashboardModule(.dashboard)
          )
        }
      case .failure(let error):
        if isPIDRequest {
          pinSessionInteractor.clear()
        }
        self.onError(with: error)
      }
    }
  }
  
  override func getSuccessRoute() -> AppRoute? {
    return switch interactor.getCoordinator() {
    case .success(let remoteSessionCoordinator):
        .featurePresentationModule(
          .presentationLoader(
            relyingParty: getRelyingParty().toString,
            relyingPartyIsTrusted: getRelyingPartyIsTrusted(),
            presentationCoordinator: remoteSessionCoordinator,
            originator: getOriginator(),
            items: viewState.items.filterSelectedRows(), dataUiItems: viewState.items
          )
        )
    case .failure: nil
    }
  }
  
  func getPinRoute() -> AppRoute? {
    return switch interactor.getCoordinator() {
    case .success(let remoteSessionCoordinator):
        .featurePresentationModule(
          .showPinView(
              config: UIConfig.Biometry(
                navigationTitle: .enterPassword,
                caption: .requestDataShareBiometryCaption,
                primaryButtonTitle: .pidPresentationWalletPinEntryPrimButton,
                quickPinOnlyCaption: .space,
                navigationSuccessType: .push(
                  .featurePresentationModule(
                    .presentationLoader(
                      relyingParty: getRelyingParty().toString,
                      relyingPartyIsTrusted: getRelyingPartyIsTrusted(),
                      presentationCoordinator: remoteSessionCoordinator,
                      originator: getOriginator(),
                      items: viewState.items.filterSelectedRows(), dataUiItems: viewState.items
                    )
                  )
                ),
                navigationErrorScreen: nil,
                navigationBackType: .pop,
                isPreAuthorization: false,
                shouldInitializeBiometricOnCreate: true,
                invalidPinTitle: .invalidQuickPin,
                pinScreenType: .verifyWalletPinFlow,
                imageIcon: Theme.shared.image.setupWalletPin,
                items: viewState.items
              )
            )
        )
    case .failure: nil
    }
  }
  
  func onDecline() {
    confirmationPopupViewModel.configure(
      title: LocalizableStringKey.confirmItendificationRefusal.toString,
      detail: LocalizableStringKey.confirmItendificationRefusalMessage.toString,
      primaryButtontitle: LocalizableStringKey.back.toString,
      secondaryButtontitle: LocalizableStringKey.yesReject.toString,
        primaryAction: {
          self.isConfirmationPopupVisible = false
        },
        secondaryAction: {
          // The user rejected the request: close the trace as declined, not as a failure.
          self.analyticsController.endTrace(
            finalAttributes: [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.declined],
            errorDescription: nil
          )
          self.isConfirmationPopupVisible = false
          self.router.popTo(
            with: self.getPopRoute() ?? .featureDashboardModule(.dashboard)
          )
        }
    )
    isConfirmationPopupVisible = true
  }
  
  private func getLocalizedFieldName(_ fieldName: String) -> String {
    // Map backend field names to localization keys
    switch fieldName.lowercased() {
    case "birth_date", "birthdate", "date_of_birth":
      return LocalizableStringKey.dateOfBirth.toString
    case "first_name", "given_name", "givennames":
      return LocalizableStringKey.givenName.toString
    case "last_name", "family_name", "familyname", "surname":
      return LocalizableStringKey.familyName.toString
    case "place_of_birth", "birth_place":
      return LocalizableStringKey.placeOfBirth.toString
    case "nationality", "nationalities":
      return LocalizableStringKey.nationality.toString
    case "issuing_country", "country":
      return LocalizableStringKey.issuingCountry.toString
    case "valid_until", "expiry_date", "exp":
      return LocalizableStringKey.validInUntil.toString
    case "created_at", "iat", "issuance_date":
      return LocalizableStringKey.createdOn.toString
    case "age_in_years", "age":
      return LocalizableStringKey.ageInYears.toString
    case "birth_year":
      return LocalizableStringKey.birthYear.toString
    case "age_equal_or_over":
      return LocalizableStringKey.ageEqualOrOver.toString
    case "issuing_authority", "authority":
      return LocalizableStringKey.issuingAuthority.toString
    case "address":
      return LocalizableStringKey.address.toString
    case "title":
      return LocalizableStringKey.title.toString
    case "name":
      return LocalizableStringKey.name.toString
    case "resident_country":
      return LocalizableStringKey.eIDAttributeResidentCountry.toString
    case "resident_postal_code":
      return LocalizableStringKey.eIDAttributeResidentPostal.toString
    case "resident_city":
      return LocalizableStringKey.eIDAttributeResidentCity.toString
    case "resident_street":
      return LocalizableStringKey.eIDAttributeResidentStreet.toString
    default:
      // If no mapping found, try to use the dynamic localization system
      return LocalizableStringKey.dynamic(key: fieldName).toString
    }
  }

  private func flattenConsentItems<T: Sendable>(
    _ items: [ExpandableListItem<T>],
    sectionId: String, title: String = ""
  ) -> [ConsentItem] {
    items.flatMap { item -> [ConsentItem] in
      switch item {
      case .single:
        return [
          .init(
            docId: sectionId,
            title: getLocalizedFieldName(item.title),
            description: item.mainText.toString
          )
        ]
      case .nested(let nested):
        return flattenConsentItems(nested.expanded, sectionId: sectionId, title: getLocalizedFieldName(item.title))
      }
    }
  }
}
