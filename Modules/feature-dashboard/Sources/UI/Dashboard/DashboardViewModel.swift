/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import logic_ui
import logic_business
import logic_core
import feature_common
import feature_issuance

@Copyable
struct DashboardState<Router: RouterHost>: ViewState {
  let homeTab: HomeTabView<Router>?
  let documentTab: DocumentTabView<Router>?
  let transactionTab: TransactionTabView<Router>?
  let toolBarContent: ToolBarContent
  let navigationTitle: LocalizableStringKey
}

enum SelectedTab {
  case home
  case documents
  case transactions
}

final class DashboardViewModel<Router: RouterHost>: ViewModel<Router, DashboardState<Router>> {

  private let dashboardInteractor: DashboardInteractor
  private let deepLinkController: DeepLinkController
  private let credentialsInteractor: CredentialsInteractor
  private let secureEnclaveController: SecureEnclaveController
  private let configLogic: ConfigLogic

  @Published var selectedTab: SelectedTab = .home

  init(
    router: Router,
    dashboardInteractor: DashboardInteractor,
    homeTabInteractor: HomeTabInteractor,
    documentTabInteractor: DocumentTabInteractor,
    transactionTabInteractor: TransactionTabInteractor,
    credentialsInteractor: CredentialsInteractor,
    secureEnclaveController: SecureEnclaveController,
    configLogic: ConfigLogic,
    deepLinkController: DeepLinkController
  ) {
    self.dashboardInteractor = dashboardInteractor
    self.deepLinkController = deepLinkController
    self.credentialsInteractor = credentialsInteractor
    self.secureEnclaveController = secureEnclaveController
    self.configLogic = configLogic
    
      super.init(
        router: router,
        initialState: .init(
          homeTab: nil,
          documentTab: nil,
          transactionTab: nil,
          toolBarContent: .init(
            trailingActions: nil,
            leadingActions: nil
          ),
          navigationTitle: .custom("")
        )
      )
//    super.init(
//      router: router,
//      initialState: .init(
//        isLoading: true,
//        documents: DocumentUIModel.mocks(),
//        bearer: BearerUIModel.mock(),
//        phase: .active,
//        pendingBleModalAction: false,
//        appVersion: interactor.getAppVersion(),
//        allowUserInteraction: interactor.hasIssuedDocuments(),
//        pendingDeletionDocument: nil,
//        succededIssuedDocuments: [],
//        failedDocuments: [],
//        moreOptions: [.changeQuickPin]
//      )
//    )

      createTabs(
        homeTabInteractor: homeTabInteractor,
        documentTabInteractor: documentTabInteractor,
        transactionTabInteractor: transactionTabInteractor,
        credentialsInteractor: credentialsInteractor,
        secureEnclaveController: secureEnclaveController,
        configLogic: configLogic
      )

  }

    private func createTabs(
      homeTabInteractor: HomeTabInteractor,
      documentTabInteractor: DocumentTabInteractor,
      transactionTabInteractor: TransactionTabInteractor,
      credentialsInteractor: CredentialsInteractor,
      secureEnclaveController: SecureEnclaveController,
      configLogic: ConfigLogic
    ) {

      func updateState(toolbar: ToolBarContent, title: LocalizableStringKey) {
        self.setState {
          $0.copy(
            toolBarContent: toolbar,
            navigationTitle: title
          )
        }
      }

      setState {
        $0.copy(
          homeTab: HomeTabView(
            with: .init(
              router: router,
              interactor: homeTabInteractor,
              onUpdateToolbar: { toolbar, title in
                updateState(toolbar: toolbar, title: title)
              }
            )
          ),
          documentTab: DocumentTabView(
            with: .init(
              router: router,
              interactor: documentTabInteractor,
              credentialsInteractor: credentialsInteractor,
              secureEnclaveController: secureEnclaveController,
              configLogic: configLogic,
              onUpdateToolbar: { toolbar, title in
                updateState(toolbar: toolbar, title: title)
              }
            )
          ),
          transactionTab: TransactionTabView(
            with: .init(
              router: router,
              interactor: transactionTabInteractor,
              onUpdateToolbar: { toolbar, title in
                updateState(toolbar: toolbar, title: title)
              }
            )
          )
        )
      }
    }
    
    func handleDeepLink() async {
      if let deepLink = deepLinkController.getPendingDeepLinkAction() {
        deepLinkController.handleDeepLinkAction(
          routerHost: router,
          deepLinkExecutable: deepLink,
          remoteSessionCoordinator: deepLink.requiresCoordinator
          ? await dashboardInteractor.getWalletKitController().startSameDevicePresentation(deepLink: deepLink.link)
          : nil
        )
      }
    }

  /*func fetch() async {
    switch await interactor.fetchDashboard(failedDocuments: viewState.failedDocuments) {
    case .success(let bearer, let documents, let hasIssuedDocuments):
      setState {
        $0.copy(
          isLoading: false,
          documents: documents,
          bearer: bearer,
          allowUserInteraction: hasIssuedDocuments
        )
      }
    onDocumentsRetrievedPostActions()
    case .failure:
      setState {
        $0.copy(isLoading: false, documents: [])
      }
    }
  }

    func setPhase(with phase: ScenePhase) async {
    setState { $0.copy(phase: phase) }
    if phase == .active && viewState.pendingBleModalAction {
      DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
        self.setState { $0.copy(pendingBleModalAction: false) }
        self.toggleBleModal()
      }
    }
    if phase == .active {
        onDocumentsRetrievedPostActions()
    }
    if phase == .background {
      onPause()
    }
  }

  func onPause() {
    self.deferredTask?.cancel()
  }

  func onDocumentDetails(documentId: String) {

    isSuccededDocumentsModalShowing = false

    router.push(
      with: .featureIssuanceModule(
        .issuanceDocumentDetails(
          config: IssuanceDetailUiConfig(flow: .extraDocument(documentId))
        )
      )
    )
  }

  func onShare() {
    Task { [weak self] in
      guard let self else { return }

      switch await self.interactor.getBleAvailability() {
      case .available:
          await self.router.push(
          with: .featureProximityModule(
            .proximityConnection(
              presentationCoordinator: self.walletKitController.startProximityPresentation(),
              originator: .featureDashboardModule(.dashboard)
            )
          )
        )
      case .noPermission, .disabled:
        self.toggleBleModal()
      default:
        break
      }
    }
  }

  func onDeleteDeferredDocument(with document: DocumentUIModel) {
    setState { $0.copy(pendingDeletionDocument: document) }
    toggleDeleteDeferredModal()
  }

  func toggleDeleteDeferredModal() {
    isDeleteDeferredModalShowing = !isDeleteDeferredModalShowing
  }

  func deleteDeferredDocument() {
    toggleDeleteDeferredModal()
    guard let document = viewState.pendingDeletionDocument else {
      return
    }
    setState { $0.copy(isLoading: true).copy(pendingDeletionDocument: nil) }
    Task {
      switch await interactor.deleteDeferredDocument(with: document.value.id) {
      case .success:
        await fetch()
      case .noDocuments:
        router.popTo(with: .featureStartupModule(.startup))
      case .failure:
        setState { $0.copy(isLoading: false) }
      }
    }
  }

  func toggleBleModal() {
    guard viewState.phase == .active else {
      setState { $0.copy(pendingBleModalAction: true) }
      return
    }
    isBleModalShowing = !isBleModalShowing
  }

  func onBleSettings() {
    toggleBleModal()
    interactor.openBleSettings()
  }

  func onAdd() {
    router.push(
      with: .featureIssuanceModule(
        .issuanceAddDocument(
          config: IssuanceFlowUiConfig(flow: .extraDocument)
        )
      )
    )
  }

  func onMore() {
    setState {
      $0.copy(
        moreOptions: buildArray {
          DashboardState.MoreModalOption.changeQuickPin
            
            /*
            DashboardState.MoreModalOption.scanQrCode
             */
            
          if let url = interactor.retrieveLogFileUrl() {
            DashboardState.MoreModalOption.retrieveLogs(url)
          }
        }
      )
    }
    isMoreModalShowing = !isMoreModalShowing
  }

  func onUpdatePin() {
    onHideMore()
    router.push(with: .featureCommonModule(.quickPin(config: QuickPinUiConfig(flow: .update))))
  }

  func onShowScanner() {
    onHideMore()
    router.push(with: .featureCommonModule(.qrScanner(config: ScannerUiConfig(flow: .presentation))))
  }

  private func onHideMore() {
    isMoreModalShowing = false
  }

  private func listenForSuccededIssuedModalChanges() {
    $isSuccededDocumentsModalShowing
      .dropFirst()
      .removeDuplicates()
      .sink { [weak self] value in
        guard let self = self else { return }
        if !value {
          self.setState { $0.copy(succededIssuedDocuments: []) }
        }
      }.store(in: &cancellables)
  }

    private func onDocumentsRetrievedPostActions() {
      if let deepLink = deepLinkController.getPendingDeepLinkAction() {
        Task {
          deepLinkController.handleDeepLinkAction(
            routerHost: router,
            deepLinkExecutable: deepLink,
            remoteSessionCoordinator: deepLink.requiresCoordinator
            ? await walletKitController.startSameDevicePresentation(deepLink: deepLink.link)
            : nil
          )
        }
      } else if interactor.hasDeferredDocuments() && (self.deferredTask == nil || self.deferredTask?.isCancelled == true) {
        self.deferredTask = Task {
          try? await Task.sleep(seconds: 5)
          return await interactor.requestDeferredIssuance()
        }
        Task {
          guard let task = self.deferredTask else { return }
          let partialState = try? await task.value
          switch partialState {
          case .completion(let issued, let failed):
            self.deferredTask?.cancel()
            self.setState {
              $0.copy(
                succededIssuedDocuments: !isSuccededDocumentsModalShowing
                ? issued
                : $0.succededIssuedDocuments,
                failedDocuments: failed
              )
            }
            await fetch()
          case .cancelled, .none: break
          }
        }
      }
      checkForSuccededIssuedDocuments()
    }

  private func checkForSuccededIssuedDocuments() {
    guard
      !viewState.succededIssuedDocuments.isEmpty,
      !isSuccededDocumentsModalShowing
    else {
      return
    }
    onHideMore()
    isBleModalShowing = false
    isDeleteDeferredModalShowing = false
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
      self.isSuccededDocumentsModalShowing = true
    }
  }*/
}
