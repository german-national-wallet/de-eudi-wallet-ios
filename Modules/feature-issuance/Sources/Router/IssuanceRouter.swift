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
import logic_ui
import logic_business
import MdocDataModel18013
import feature_common
import logic_analytics
import logic_core

@MainActor
public final class IssuanceRouter {
  
  public static func resolve(module: FeatureIssuanceRouteModule, host: some RouterHost) -> AnyView {
    switch module {
    case .issuanceAddDocument(config: let config):
      AddDocumentView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            AddDocumentInteractor.self
          ),
          deepLinkController: DIGraph.resolver.force(
            DeepLinkController.self
          ),
          secureEnclaveController: DIGraph.resolver.force(
            SecureEnclaveController.self
          ),
          analyticsController: DIGraph.resolver.force(
            AnalyticsController.self
          ),
          config: config
        )
      ).eraseToAnyView()
    case .issuanceDocumentDetails(config: let config):
      DocumentDetailsView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            DocumentDetailsInteractor.self
          ),
          config: config
        )
      ).eraseToAnyView()
    case .issuanceSuccess(
      let config,
      let uiModels
    ):
      DocumentIssuanceSuccessView(
        with: .init(
          router: host,
          config: config,
          deepLinkController: DIGraph.resolver.force(
            DeepLinkController.self
          ),
          requestItems: uiModels.compactMap { $0 as? ListItemSection<Sendable> }
        )
      ).eraseToAnyView()
    case .credentialOfferRequest(config: let config):
      DocumentOfferView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            DocumentOfferInteractor.self
          ), secureEnclaveController: DIGraph.resolver.force(
            SecureEnclaveController.self
          ), credentialsInteractor: DIGraph.resolver.force(
            CredentialsInteractor.self
          ),
          config: config
        )
      ).eraseToAnyView()
    case .issuanceCode(config: let config):
      OfferCodeView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            DocumentOfferInteractor.self
          ),
          config: config
        )
      ).eraseToAnyView()
    case .issuanceCard(config: let config, requestURI: let requestURI, let eidPin, let eidPinFlow, let delegate):
      IssuanceCardView(
        with: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            IssuanceCardInteractor.self
          ), parInteractor: DIGraph.resolver.force(
            PARInteractor.self
          ),
          issuanceVarificationInteractor: DIGraph.resolver.force(
            IssuanceVerificationInteractor.self
          ),
          secureEnclaveController: DIGraph.resolver.force(
            SecureEnclaveController.self
          ),
          quickPinInteractor: DIGraph.resolver.force(
            QuickPinInteractor.self
          ),
          analyticsController: DIGraph.resolver.force(
            AnalyticsController.self
          ),
          config: config,
          requestURI: requestURI,
          eidPin: eidPin,
          eidFlow: eidPinFlow,
          delegate: delegate,
          logger: DIGraph.resolver.force(Logging.self)
        )
      ).eraseToAnyView()
    case .pinView(let config, let onCANEntered, let issuanceVerificationInteractor):
      if let issuanceVerificationInteractor {
        PINView(
          viewModel: .init(
            router: host,
            interactor: DIGraph.resolver.force(
              BiometryInteractor.self
            ),
            issuanceVarificationInteractor: issuanceVerificationInteractor,
            prefsController: DIGraph.resolver.force(
              PrefsController.self
            ),
            secureEnclaveController: DIGraph.resolver.force(SecureEnclaveController.self),
            parInteractor: DIGraph.resolver.force(PARInteractor.self),
            config: config,
            onPinEntered: onCANEntered,
            pinSessionInteractor: DIGraph.resolver.force(PinSessionInteractor.self),
            logger: DIGraph.resolver.force(Logging.self)
          )
        ).eraseToAnyView()
      } else {
        PINView(
          viewModel: .init(
            router: host,
            interactor: DIGraph.resolver.force(
              BiometryInteractor.self
            ),
            issuanceVarificationInteractor: DIGraph.resolver.force(
              IssuanceVerificationInteractor.self
            ),
            prefsController: DIGraph.resolver.force(
              PrefsController.self
            ),
            secureEnclaveController: DIGraph.resolver.force(SecureEnclaveController.self),
            parInteractor: DIGraph.resolver.force(PARInteractor.self),
            config: config,
            onPinEntered: onCANEntered,
            pinSessionInteractor: DIGraph.resolver.force(PinSessionInteractor.self),
            logger: DIGraph.resolver.force(Logging.self)

          )
        ).eraseToAnyView()
      }
    case .canView(let config, let onPinEntered, let issuanceVerificationInteractor):
      CANView(
        viewModel: .init(
          router: host,
          interactor: DIGraph.resolver.force(BiometryInteractor.self),
          issuanceVarificationInteractor: issuanceVerificationInteractor,
          prefsController: DIGraph.resolver.force(
            PrefsController.self
          ),
          secureEnclaveController: DIGraph.resolver.force(SecureEnclaveController.self),
          parInteractor: DIGraph.resolver.force(PARInteractor.self),
          config: config,
          onPinEntered: onPinEntered,
          pinSessionInteractor: DIGraph.resolver.force(PinSessionInteractor.self),
          logger: DIGraph.resolver.force(Logging.self)
        ),
        onPinEntered: onPinEntered
      ).eraseToAnyView()

    case .setEidTransportPinInstructionsView(let config, let issuanceVerificationInteractor):
      InstructionsView(
        viewModel: .init(
          router: host,
          config: UIConfig.InstructionsViewConfig(
            mainTitle: .setupPinTransportViewTitle,
            message: .setupPinTransportViewMessage,
            image: Theme.shared.image.transportPinLetter,
            illustrationWidthFactor: 0.5,
            primaryButtonTitle: .setupPinTransportViewPrimaryButtonTitle,
            secondaryButtonTitle: .setupPinTransportViewSecondaryButtonTitle,
            primaryRoute: .featureIssuanceModule(
              .setEidPinView(
                config: config,
                onPinEntered: PinCallbackWrapper(onEntered: { _ in }),
                issuanceVerificationInteractor: issuanceVerificationInteractor
              )
            )
          )
        )
      ).eraseToAnyView()
      
    case .setEidPinView(_, let onCANEntered, let issuanceVerificationInteractor):
      PINView(
        viewModel: .init(
          router: host,
          interactor: DIGraph.resolver.force(
            BiometryInteractor.self
          ),
          issuanceVarificationInteractor: issuanceVerificationInteractor,
          prefsController: DIGraph.resolver.force(
            PrefsController.self
          ),
          secureEnclaveController: DIGraph.resolver.force(SecureEnclaveController.self),
          parInteractor: DIGraph.resolver.force(PARInteractor.self),
          config: UIConfig.Biometry(
            navigationTitle: .transportPinViewTitle,
            caption: .setupPinTransportViewSecondaryButtonTitle,
            quickPinOnlyCaption: .space,
            navigationSuccessType: .pop,
            navigationErrorScreen: nil,
            navigationBackType: .pop,
            isPreAuthorization: true,
            shouldInitializeBiometricOnCreate: true,
            invalidPinTitle: .issuanceCanEntryTitle,
            pinScreenType: .transportPinFlow,
            imageIcon: Theme.shared.image.transportPinLetter,
            imageSize: CGSize(width: 150, height: 200),
            quickPinSize: 5
          ),
          onPinEntered: onCANEntered,
          pinSessionInteractor: DIGraph.resolver.force(PinSessionInteractor.self),
          logger: DIGraph.resolver.force(Logging.self)
        )
      )
      .eraseToAnyView()
      
    case .setNewEidInstructionsPinView(_, let issuanceVerificationInteractor, let pinCallbackWrapper, let pinScreenType):
      InstructionsView(
        viewModel: .init(
          router: host,
          config: UIConfig.InstructionsViewConfig(
            mainTitle: .setupNewPinInstructionViewTitle,
            message: .eidSetupCardPinIntroParagraph,
            image: Theme.shared.image.ausweisPinAndCard,
            illustrationWidthFactor: 0.5,
            primaryButtonTitle: .setupNewPinInstructionViewPrimaryButtonTilte,
            secondaryButtonTitle: nil,
            primaryRoute: .featureIssuanceModule(
              .pinView(
                config: UIConfig.Biometry(
                  navigationTitle: .setNewEidPinOne,
                  caption: nil,
                  quickPinOnlyCaption: .space,
                  navigationSuccessType: .pop,
                  navigationErrorScreen: nil,
                  navigationBackType: .pop,
                  isPreAuthorization: false,
                  shouldInitializeBiometricOnCreate: true,
                  invalidPinTitle: .issuanceCanEntryTitle,
                  pinScreenType: pinScreenType,
                  imageIcon: Theme.shared.image.personalausweisLogo,
                  imageSize: CGSize(width: 105.0089, height: 144.0464),
                  quickPinSize: 6
                ),
                onPinEntered: pinCallbackWrapper,
                issuanceVerificationInteractor: issuanceVerificationInteractor
              )
            )
          )
        )
      ).eraseToAnyView()
      
    case .issuancePidPreviewView(config: let config):
      IssuancePidPreviewView(
        with: .init(
          router: host,
          config: config
        )
      ).eraseToAnyView()

    case .issuanceSuccessView(config: let config, callback: let callback):
      SuccessView(viewModel: .init(
        config: config,
        callback: callback,
        deepLinkController: DIGraph.resolver.force(DeepLinkController.self),
        router: host
      )).eraseToAnyView()
      
    case .issuanceOnboardingCardView:
      IssuanceOnboardingCardView(
        onBack: { host.pop() },
        onPrimaryOptionTapped: {
          host.push(with: .featureIssuanceModule(
            .issuanceOnboardingInstructionView(
              issuanceVerificationInteractor: DIGraph.resolver.force(
                IssuanceVerificationInteractor.self
              )
            )
          ))
        },
        onSecondaryOptionTapped: {
          host.push(with: .featureCommonModule(
            .illustratedNoticeView(
              config: IllustratedNoticeUiConfig(
                title: .pidNoCardAvailableInfoTitle,
                message: .pidNoCardAvailableInfoParagraph,
                illustration: Theme.shared.image.burgeramtInfo,
                primaryButtonTitle: .globalOfficeButton,
                primaryAction: .findBurgeramt
              )
            )
          ))
        }
      ).eraseToAnyView()

    case .issuanceOnboardingView:
      InstructionsView(
        viewModel: .init(
          router: host,
          config: UIConfig.InstructionsViewConfig(
            mainTitle: .issuanceOnboardingTitle,
            message: .issuanceOnboardingMessage,
            image: Theme.shared.image.multipleAusweisCards,
            illustrationWidthFactor: 0.7,
            primaryButtonTitle: .issuanceOnboardingPrimaryButtonTitle,
            introStyle: .stepped(currentStep: 1, totalSteps: 4),
            primaryRoute: .featureIssuanceModule(
              .issuanceOnboardingInstructionView(
                issuanceVerificationInteractor: DIGraph.resolver.force(
                  IssuanceVerificationInteractor.self
                )
              )
            )))
       ).eraseToAnyView()
      
    case .issuanceOnboardingInstructionView(let issuanceInteractor):
      IssuanceOnboardingPinCardView(
        router: host,
        issuanceInteractor: issuanceInteractor,
        onBack: { host.pop() },
        onClose: { host.popTo(with: .featureDashboardModule(.dashboard)) },
        onCardPinKnownTapped: {
          host.push(with: .featureIssuanceModule(
            .issuanceProcessOverviewView(
              issuanceVerificationInteractor: issuanceInteractor
            )
          ))
        },
        onSetPinWithLetterTapped: {
          guard let issuanceInteractor else { return }
          host.push(with: .featureIssuanceModule(
            .setEidTransportPinInstructionsView(
              config: NoConfig(),
              issuanceVerificationInteractor: issuanceInteractor
            )
          ))
        }
      ).eraseToAnyView()

    case .issuanceProcessOverviewView(let issuanceInteractor):
      IssuanceProcessOverviewView(
        router: host,
        issuanceInteractor: issuanceInteractor,
        onBack: { host.pop() },
        onClose: { host.popTo(with: .featureDashboardModule(.dashboard)) },
        onContinue: {
          host.push(with: .featureIssuanceModule(
            .consentView(
              issuanceVerificationInteractor: issuanceInteractor
            )
          ))
        }
      ).eraseToAnyView()

    case .consentView(let issuanceInteractor):
      IssuanceConsentView(
        with: .init(
          router: host,
          config: UIConfig.IssuanceConsentViewConfig(
            primaryRoute: .featureIssuanceModule(
            .pinView(
              config: UIConfig.Biometry(
                navigationTitle: .issuanceEidPinEntryTitle,
                caption: .issuanceEidUnkownTitle,
                quickPinOnlyCaption: .space,
                navigationSuccessType: .pop,
                navigationBackType: .pop,
                isPreAuthorization: true,
                shouldInitializeBiometricOnCreate: true,
                invalidPinTitle: .issuanceErrorWrongCan,
                pinScreenType: .issueEidPinFlow,
                progressSteps: .init(current: 2, total: 4),
                imageIcon: nil
              ),
              issuanceVerificationInteractor: issuanceInteractor
            )),
          issuanceInteractor: issuanceInteractor
          )
        )
      ).eraseToAnyView()
    case .walletPinSetupInstructionView(config: let config):
      InstructionsView(
        viewModel: .init(
          router: host,
          config: config
        )
      ).eraseToAnyView()
    case .issuanceLoadingView(config: let config):
      IssuanceLoadingView(
        with: .init(
          router: host,
          config: config,
          secureEnclaveController: DIGraph.resolver.force(
            SecureEnclaveController.self
          ),
          addDocumentInteractor: DIGraph.resolver.force(
            AddDocumentInteractor.self
          ),
          analyticsController: DIGraph.resolver.force(
            AnalyticsController.self
          ),
          mdvmInteractor: DIGraph.resolver.force(
            MDVMInteractor.self
          ),
          rwscaInteractor: DIGraph.resolver.force(
            RWSCAInteractor.self
          ),
          pinSessionInteractor: DIGraph.resolver.force(
            PinSessionInteractor.self
          ),
          logger: DIGraph.resolver.force(Logging.self)
        )
      ).eraseToAnyView()
    case .issuerDetailsView(config: let config):
      IssuerDetailsView(with: .init(router: host, config: config))
        .eraseToAnyView()
    case .credentialOfferConsentView(config: let config):
      CredentialOfferConsentView(with:
          .init(
            router: host,
            config: config,
            interactor: DIGraph.resolver.force(DocumentOfferInteractor.self)
          )
      )
      .eraseToAnyView()
    case .documentLoaderView(config: let config, onFailure: let onFailure):
      DocumentLoaderView(with:
          .init(
            router: host,
            config: config,
            interactor: DIGraph.resolver.force(DocumentOfferInteractor.self),
            onFailure: onFailure,
            logger: DIGraph.resolver.force(Logging.self)
          )
      )
      .eraseToAnyView()
    }
  }
}
