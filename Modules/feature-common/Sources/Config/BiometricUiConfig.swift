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
import logic_resources
import Foundation
import MdocDataModel18013

public extension UIConfig {
  struct Biometry: UIConfigType, Equatable {
    
    public struct ProgressSteps: Equatable {
      public let current: Int
      public let total: Int

      public init(current: Int, total: Int) {
        self.current = current
        self.total = total
      }
    }

    public let navigationTitle: LocalizableStringKey
    public let displayLogo: Bool
    public let title: LocalizableStringKey?
    public let caption: LocalizableStringKey?
    public let primaryButtonTitle: LocalizableStringKey?
    public let quickPinOnlyCaption: LocalizableStringKey
    public let navigationSuccessType: ThreeWayNavigationType
    public let navigationErrorScreen: ThreeWayNavigationType?
    public let navigationBackType: ThreeWayNavigationType?
    public let isPreAuthorization: Bool
    public let shouldInitializeBiometricOnCreate: Bool
    public let invalidPinTitle: LocalizableStringKey
    public let pinScreenType: PINScreenType
    public let progressSteps: ProgressSteps?
    public let showsHelpButton: Bool
    public let quickPinSize: Int
    public let imageIcon: Image?
    public let imageSize: CGSize
    public let pinForConfirmationFlow: String?
    public let finishAuthorizationResponseDTO: FinishAuthorizationResponse?
    public let items: [RequestDataUiModel]?

    /// `imageIcon` is excluded: a SwiftUI `Image` does not offer reliable value equality between
    /// separately constructed instances, so leaving it in a synthesized `==` makes two otherwise
    /// identical configurations compare unequal. Every other stored property is compared.
    public static func == (lhs: Biometry, rhs: Biometry) -> Bool {
      lhs.navigationTitle == rhs.navigationTitle
      && lhs.displayLogo == rhs.displayLogo
      && lhs.title == rhs.title
      && lhs.caption == rhs.caption
      && lhs.primaryButtonTitle == rhs.primaryButtonTitle
      && lhs.quickPinOnlyCaption == rhs.quickPinOnlyCaption
      && lhs.navigationSuccessType == rhs.navigationSuccessType
      && lhs.navigationErrorScreen == rhs.navigationErrorScreen
      && lhs.navigationBackType == rhs.navigationBackType
      && lhs.isPreAuthorization == rhs.isPreAuthorization
      && lhs.shouldInitializeBiometricOnCreate == rhs.shouldInitializeBiometricOnCreate
      && lhs.invalidPinTitle == rhs.invalidPinTitle
      && lhs.pinScreenType == rhs.pinScreenType
      && lhs.progressSteps == rhs.progressSteps
      && lhs.showsHelpButton == rhs.showsHelpButton
      && lhs.quickPinSize == rhs.quickPinSize
      && lhs.imageSize == rhs.imageSize
      && lhs.pinForConfirmationFlow == rhs.pinForConfirmationFlow
      && lhs.finishAuthorizationResponseDTO == rhs.finishAuthorizationResponseDTO
      && lhs.items == rhs.items
    }

    public var log: String {
      return "navigationTitle: \(navigationTitle.toString)" +
      "displayLogo: \(displayLogo)" +
      "title: \(title?.toString ?? "none")" +
      " onSuccessNav: \(navigationSuccessType.key)" +
      " onBackNav: \(navigationBackType?.key ?? "none")" +
      " isPreAuthorization: \(isPreAuthorization)" +
      " shouldInitializeBiometricOnCreate: \(shouldInitializeBiometricOnCreate)" +
      " invalidPinTitle: \(invalidPinTitle.toString)" +
      " pinScreenType: \(pinScreenType)"
    }

    public init(
      navigationTitle: LocalizableStringKey,
      displayLogo: Bool = true,
      title: LocalizableStringKey? = nil,
      caption: LocalizableStringKey? = nil,
      primaryButtonTitle: LocalizableStringKey? = nil,
      quickPinOnlyCaption: LocalizableStringKey,
      navigationSuccessType: ThreeWayNavigationType,
      navigationErrorScreen: ThreeWayNavigationType? = nil,
      navigationBackType: ThreeWayNavigationType?,
      isPreAuthorization: Bool = false,
      shouldInitializeBiometricOnCreate: Bool,
      iconImage: Image? = nil,
      invalidPinTitle: LocalizableStringKey,
      pinScreenType: PINScreenType,
      progressSteps: ProgressSteps? = nil,
      showsHelpButton: Bool = false,
      imageIcon: Image? = Theme.shared.image.personalausweisLogo,
      imageSize: CGSize = CGSize(width: 72, height: 72),
      quickPinSize: Int = 6,
      pinForConfirmationFlow: String? = nil,
      finishAuthorizationResponseDTO: FinishAuthorizationResponse? = nil,
      items: [RequestDataUiModel]? = nil
    ) {
      self.navigationTitle = navigationTitle
      self.displayLogo = displayLogo
      self.title = title
      self.caption = caption
      self.primaryButtonTitle = primaryButtonTitle
      self.quickPinOnlyCaption = quickPinOnlyCaption
      self.navigationSuccessType = navigationSuccessType
      self.navigationErrorScreen = navigationErrorScreen
      self.navigationBackType = navigationBackType
      self.isPreAuthorization = isPreAuthorization
      self.shouldInitializeBiometricOnCreate = shouldInitializeBiometricOnCreate
      self.invalidPinTitle = invalidPinTitle
      self.pinScreenType = pinScreenType
      self.progressSteps = progressSteps
      self.showsHelpButton = showsHelpButton
      self.imageIcon = imageIcon
      self.imageSize = imageSize
      self.quickPinSize = quickPinSize
      self.pinForConfirmationFlow = pinForConfirmationFlow
      self.finishAuthorizationResponseDTO = finishAuthorizationResponseDTO
      self.items = items
    }
  }
}
