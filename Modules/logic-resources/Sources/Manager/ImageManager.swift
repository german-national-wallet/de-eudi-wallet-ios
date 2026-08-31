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

import SwiftUI

public protocol ImageManagerProtocol: Sendable {
  var logo: Image { get }
  var faceId: Image { get }
  var id: Image { get }
  var nfc: Image { get }
  var touchId: Image { get }
  var arrowLeft: Image { get }
  var arrowBack: Image { get }
  var chevronUp: Image { get }
  var chevronDown: Image { get }
  var chevronRight: Image { get }
  var chevronLeft: Image { get }
  var xmark: Image { get }
  var exclamationmarkCircle: Image { get }
  var circle: Image { get }
  var checkmarkCircleFill: Image { get }
  var checkmarkSquareFill: Image { get }
  var square: Image { get }
  var plus: Image { get }
  var share: Image { get }
  var checkMarkSealFill: Image { get }
  var photo: Image { get }
  var trash: Image { get }
  var viewFinder: Image { get }
  var clock: Image { get }
  var clockIndicator: Image { get }
  var errorIndicator: Image { get }
  var errorIndicatorIcon: Image { get }
  var signDocument: Image { get }
  var euditext: Image { get }
  var walletVerified: Image { get }
  var bell: Image { get }
  var menuIcon: Image { get }
  var filterMenuIcon: Image { get }
  var bookmarkIcon: Image { get }
  var bookmarkIconFill: Image { get }
  var gearshape: Image { get }
  var checkmark: Image { get }
  var hourglassImage: Image { get }
  var chooseDocumentImage: Image { get }
  var scanDocumentImage: Image { get }
  var infoCircle: Image { get }
  var relyingPartyVerified: Image { get }
  var docFill: Image { get }
  var logoEuDigitalIndentityWallet: Image { get }
  var homeContract: Image { get }
  var homeIdentity: Image { get }
  var successSecuredWallet: Image { get }
  var digitalIdIssuance: Image { get }
  var documentSuccessPending: Image { get }
  var balance: Image { get }
  var language: Image { get }
  var locationOn: Image { get }
  var apartment: Image { get }
  var storefront: Image { get }
  var verifiedUser: Image { get }
  var defaultLogo: Image { get }
  var signature: Image { get }
  var workspace: Image { get }
  var event: Image { get }
  var idCard: Image { get }
  var personOutline: Image { get }
  var history: Image { get }
  var arrowRight: Image { get }
  var arrowBackIcon: Image { get }
  var backButtonIcon: Image { get }
  var arrowForward: Image { get }
  var burgerMenu: Image { get }
  var infoCircleImage: Image { get }
  var deEagleWingImage: Image { get }
  var deEagleWingCroppedImage: Image { get }
  var wrongPinIcon: Image { get }
  var erikaCanFront1: Image { get }
  var erikaCanFront2: Image { get }
  var demoPids1: Image { get }
  var demoPids2: Image { get }
  var eidLogo: Image { get }
  var securityCheckIcon: Image { get }
  var personalausweisLogo: Image { get }
  var transportPinLetter: Image { get }
  var tranportPinEnvelope: Image { get }
  var phoneIPhone: Image { get }
  var checkCircle: Image { get }
  var orangeRetryError: Image { get }
  var multipleAusweisCards: Image { get }
  var ausweisPinAndCard: Image { get }
  var setupWalletPin: Image { get }
  var userPhonePin: Image { get }
  var warningIndicator: Image { get }
  var redWarningIndicator: Image { get }
  var backgroundPID: Image { get }
  var backgroundSplash: Image { get }
  var bdrLogo: Image { get }
  var ausweisCanHighlighted: Image { get }
  var squareArrowDown: Image { get }
  var idCardIconGreen: Image { get }
  var person: Image { get }
  var eyeIcon: Image { get }
  var eyeIconOff: Image { get }
  var arrowheadUp: Image { get }
  var arrowheadDown: Image { get }
  var addPID: Image { get }
  var credentialNotFound: Image { get }
  var shareIcon: Image { get }
  var copyIcon: Image { get }
  var checkboxSelected: Image { get }
  var checkboxUnselected: Image { get }
  var workInProgessLockIcon: Image { get }
  var workInProgessIcon: Image { get }
  var help: Image { get }
  var buildingBlocks: Image { get }
  var externalLink: Image { get }
  var burgeramtInfo: Image { get }
  var pinCodeAsset: Image { get }
  var pinIllusItem: Image { get }
}

final class ImageManager: ImageManagerProtocol {
  enum ImageEnum: String {
    case faceId = "face-id"
    case id = "id"
    case nfc = "nfc"
    case touchId = "touch-id"
    case logo = "logo"
    case arrowLeft = "arrow.left"
    case arrowBack = "arrow_back"
    case arrowBackIcon = "arrow-back"
    case backButton = "back-button"
    case arrowForward = "arrow-forward"
    case chevronUp = "chevron.up"
    case chevronDown = "chevron.down"
    case chevronRight = "chevron.right"
    case chevronLeft = "chevron.left"
    case xmark = "close_24"
    case exclamationmarkCircle = "exclamationmark.circle"
    case circle = "circle.fill"
    case checkmarkCircleFill = "checkmark.circle.fill"
    case checkmarkSquareFill = "checkmark.square.fill"
    case square = "square"
    case plus = "plus"
    case share = "square.and.arrow.up"
    case checkMarkSealFill = "checkmark.seal.fill"
    case photo = "photo.fill"
    case trash = "trash"
    case viewFinder = "viewfinder"
    case clock = "ic-clock"
    case errorIndicatorIcon = "ic-error-indicator"
    case clockIndicator = "clock.fill"
    case errorIndicator = "exclamationmark.circle.fill"
    case signDocument = "doc"
    case euditext = "EUDI-text"
    case walletVerified = "wallet-verified"
    case bell
    case menuIcon = "line.3.horizontal"
    case filterMenuIcon = "filter-menu-icon"
    case bookmarkIcon = "bookmark"
    case bookmarkIconFill = "bookmark.fill"
    case gearshape
    case checkmark
    case hourglassImage
    case chooseDocumentImage = "choose-document-image"
    case scanDocumentImage = "scan-document-image"
    case infoCircle = "info.circle"
    case relyingPartyVerified = "relying-party-verified"
    case docFill = "doc.fill"
    case logoEuDigitalIndentityWallet = "logo-eu-digital-indentity-wallet"
    case homeContract = "home-contract"
    case homeIdentity = "home-identity"
    case successSecuredWallet = "success-secured-wallet"
    case digitalIdIssuance = "digital-id-issuance"
    case documentSuccessPending = "document-success-pending"
    case balance = "balance"
    case apartment = "apartment"
    case storefront = "storefront"
    case verified_user = "verified_user"
    case language = "language"
    case location_on = "location_on"
    case default_logo = "logo_placeholder"
    case signature = "signature"
    case workspace = "workspace"
    case event = "event"
    case idCard = "id_card"
    case personOutline = "person_outline"
    case history = "history"
    case arrowRight = "arrow_right"
    case burgerMenu = "burger-menu"
    case infoCircleImage = "info-circle"
    case deEagleWingImage = "de-eagle-wing"
    case deEagleWingCroppedImage = "de-eagle-wing-transparent"
    case wrongPinIcon = "wrong-pin-lm"
    case erikaCanFront1 = "erika_can_front1"
    case erikaCanFront2 = "erika_can_front2"
    case demoPids1 = "demo_pids1"
    case demoPids2 = "demo_pids2"
    case eidLogo = "eid_logo"
    case securityCheckIcon = "security_check_icon"
    case personalausweisLogo = "personalausweis-logo"
    case tranportPinEnvelope = "ausweis_envelope"
    case tranportPinLetter = "transport_letter_pin"
    case phoneIPhone = "phone-iphone"
    case checkCircle = "check-circle"
    case orangeRetryError = "orange-close"
    case multipleAusweisCards = "multiple_ausweis_cards"
    case ausweisPinAndCard = "ausweis_pin_and_card"
    case setupWalletPin = "setup_pin_phone_icon"
    case userPhonePin = "user_phone_pin"
    case warningIndicator = "warning-indicator"
    case redWarningIndicator = "red_warning"
    case backgroundPID = "dashboard_background"
    case backgroundSplash = "bg_splash"
    case bdrLogo = "logo_bdr"
    case ausweisCanHighlighted = "ausweis_can_highlighted"
    case squareArrowDown = "square.and.arrow.down"
    case idCardIconGreen = "offer_view_icon"
    case person = "person"
    case eyeIcon = "eye_icon"
    case eyeIconOff = "eye_icon_off"
    case arrowheadUp = "arrowhead_up"
    case arrowheadDown = "arrowhead_down"
    case addPID = "add_pid"
    case credentialNotFound = "credential_not_found"
    case shareIcon = "share_icon"
    case copyIcon = "copy_icon"
    case checkboxSelected = "checkbox_selected"
    case checkboxUnselected = "checkbox_unselected"
    case workInProgessLockIcon = "work-in-progress-lock"
    case workInProgessIcon = "wip_card"
    case help = "questionmark.circle"
    case buildingBlocks = "building_blocks"
    case externalLink = "external_link"
    case burgeramtInfo = "burgeramt_info"
    case pinCodeAsset = "pin_code_assets"
    case pinIllusItem = "pin_illus_item"
  }

  // MARK: - Properties

  let bundle: Bundle
  // MARK: - Lifecycle

  init(bundle: Bundle) {
    self.bundle = bundle
  }
  // MARK: - Images
  var faceId: Image {
    Image(ImageEnum.faceId.rawValue, bundle: bundle)
  }
  var id: Image {
    Image(ImageEnum.id.rawValue, bundle: bundle)
  }
  var nfc: Image {
    Image(ImageEnum.nfc.rawValue, bundle: bundle)
  }
  var touchId: Image {
    Image(ImageEnum.touchId.rawValue, bundle: bundle)
  }
  var logo: Image {
    Image(ImageEnum.logo.rawValue, bundle: bundle)
  }
  var arrowLeft: Image {
    Image(systemName: ImageEnum.arrowLeft.rawValue)
  }
  var arrowBack: Image {
    Image(ImageEnum.arrowBack.rawValue, bundle: bundle)
  }
  var chevronUp: Image {
    Image(systemName: ImageEnum.chevronUp.rawValue)
  }
  var chevronDown: Image {
    Image(systemName: ImageEnum.chevronDown.rawValue)
  }
  var chevronRight: Image {
    Image(systemName: ImageEnum.chevronRight.rawValue)
  }
  var chevronLeft: Image {
    Image(systemName: ImageEnum.chevronLeft.rawValue)
  }
  var xmark: Image {
    Image(ImageEnum.xmark.rawValue, bundle: bundle)
  }
  var exclamationmarkCircle: Image {
    Image(systemName: ImageEnum.exclamationmarkCircle.rawValue)
  }
  var circle: Image {
    Image(systemName: ImageEnum.circle.rawValue)
  }
  var checkmarkCircleFill: Image {
    Image(systemName: ImageEnum.checkmarkCircleFill.rawValue)
  }
  var checkmarkSquareFill: Image {
    Image(systemName: ImageEnum.checkmarkSquareFill.rawValue)
  }
  var square: Image {
    Image(systemName: ImageEnum.square.rawValue)
  }
  var plus: Image {
    Image(ImageEnum.plus.rawValue, bundle: bundle)
  }
  var share: Image {
    Image(systemName: ImageEnum.share.rawValue)
  }
  var checkMarkSealFill: Image {
    Image(systemName: ImageEnum.checkMarkSealFill.rawValue)
  }
  var photo: Image {
    Image(systemName: ImageEnum.photo.rawValue)
  }
  var trash: Image {
    Image(systemName: ImageEnum.trash.rawValue)
  }
  var viewFinder: Image {
    Image(systemName: ImageEnum.viewFinder.rawValue)
  }
  var clock: Image {
    Image(ImageEnum.clock.rawValue, bundle: bundle)
  }
  var clockIndicator: Image {
    Image(systemName: ImageEnum.clockIndicator.rawValue)
  }
  var errorIndicator: Image {
    Image(systemName: ImageEnum.errorIndicator.rawValue)
  }
  var signDocument: Image {
    Image(systemName: ImageEnum.signDocument.rawValue)
  }
  var euditext: Image {
    Image(ImageEnum.euditext.rawValue, bundle: bundle)
  }
  var walletVerified: Image {
    Image(ImageEnum.walletVerified.rawValue, bundle: bundle)
  }
  var bell: Image {
    Image(systemName: ImageEnum.bell.rawValue)
  }
  var menuIcon: Image {
    Image(systemName: ImageEnum.menuIcon.rawValue)
  }
  var filterMenuIcon: Image {
    Image(ImageEnum.filterMenuIcon.rawValue, bundle: bundle)
  }
  var bookmarkIcon: Image {
    Image(systemName: ImageEnum.bookmarkIcon.rawValue)
  }
  var bookmarkIconFill: Image {
    Image(systemName: ImageEnum.bookmarkIconFill.rawValue)
  }
  var gearshape: Image {
    Image(systemName: ImageEnum.gearshape.rawValue)
  }
  var checkmark: Image {
    Image(systemName: ImageEnum.checkmark.rawValue)
  }
  var hourglassImage: Image {
    Image(ImageEnum.hourglassImage.rawValue, bundle: bundle)
  }
  var chooseDocumentImage: Image {
    Image(ImageEnum.chooseDocumentImage.rawValue, bundle: bundle)
  }
  var scanDocumentImage: Image {
    Image(ImageEnum.scanDocumentImage.rawValue, bundle: bundle)
  }
  var infoCircle: Image {
    Image(systemName: ImageEnum.infoCircle.rawValue)
  }
  var relyingPartyVerified: Image {
    Image(ImageEnum.relyingPartyVerified.rawValue, bundle: bundle)
  }
  var docFill: Image {
    Image(systemName: ImageEnum.docFill.rawValue)
  }
  var logoEuDigitalIndentityWallet: Image {
    Image(ImageEnum.logoEuDigitalIndentityWallet.rawValue, bundle: bundle)
  }
  var homeContract: Image {
    Image(ImageEnum.homeContract.rawValue, bundle: bundle)
  }
  var homeIdentity: Image {
    Image(ImageEnum.homeIdentity.rawValue, bundle: bundle)
  }
  var successSecuredWallet: Image {
    Image(ImageEnum.successSecuredWallet.rawValue, bundle: bundle)
  }
  var digitalIdIssuance: Image {
    Image(ImageEnum.digitalIdIssuance.rawValue, bundle: bundle)
  }
  var documentSuccessPending: Image {
    Image(ImageEnum.documentSuccessPending.rawValue, bundle: bundle)
  }
  var balance: Image {
    Image(ImageEnum.balance.rawValue, bundle: bundle)
  }
  var apartment: Image {
    Image(ImageEnum.apartment.rawValue, bundle: bundle)
  }
  var storefront: Image {
    Image(ImageEnum.storefront.rawValue, bundle: bundle)
  }
  var verifiedUser: Image {
    Image(ImageEnum.verified_user.rawValue, bundle: bundle)
  }
  var language: Image {
    Image(ImageEnum.language.rawValue, bundle: bundle)
  }
  var locationOn: Image {
    Image(ImageEnum.location_on.rawValue, bundle: bundle)
  }
  var defaultLogo: Image {
    Image(ImageEnum.default_logo.rawValue, bundle: bundle)
  }
  var signature: Image {
    Image(ImageEnum.signature.rawValue, bundle: bundle)
  }
  var workspace: Image {
    Image(ImageEnum.workspace.rawValue, bundle: bundle)
  }
  var event: Image {
    Image(ImageEnum.event.rawValue, bundle: bundle)
  }
  var idCard: Image {
    Image(ImageEnum.idCard.rawValue, bundle: bundle)
  }
  var personOutline: Image {
    Image(ImageEnum.personOutline.rawValue, bundle: bundle)
  }
  var history: Image {
    Image(ImageEnum.history.rawValue, bundle: bundle)
  }
  var arrowRight: Image {
    Image(ImageEnum.arrowRight.rawValue, bundle: bundle)
  }
  var arrowBackIcon: Image {
    Image(ImageEnum.arrowBackIcon.rawValue, bundle: bundle)
  }
  var backButtonIcon: Image {
    Image(ImageEnum.backButton.rawValue, bundle: bundle)
  }
  var arrowForward: Image {
    Image(ImageEnum.arrowForward.rawValue, bundle: bundle)
  }
  var burgerMenu: Image {
    Image(ImageEnum.burgerMenu.rawValue, bundle: bundle)
  }
  var infoCircleImage: Image {
    Image(ImageEnum.infoCircleImage.rawValue, bundle: bundle)
  }
  var deEagleWingImage: Image {
    Image(ImageEnum.deEagleWingImage.rawValue, bundle: bundle)
  }
  var deEagleWingCroppedImage: Image {
    Image(ImageEnum.deEagleWingCroppedImage.rawValue, bundle: bundle)
  }
  var wrongPinIcon: Image {
      Image(ImageEnum.wrongPinIcon.rawValue, bundle: bundle)
  }
  var erikaCanFront1: Image {
    Image(ImageEnum.erikaCanFront1.rawValue, bundle: bundle)
  }
  var erikaCanFront2: Image {
    Image(ImageEnum.erikaCanFront2.rawValue, bundle: bundle)
  }
  var demoPids1: Image {
    Image(ImageEnum.demoPids1.rawValue, bundle: bundle)
  }
  var demoPids2: Image {
    Image(ImageEnum.demoPids2.rawValue, bundle: bundle)
  }
  var eidLogo: Image {
    Image(ImageEnum.eidLogo.rawValue, bundle: bundle)
  }
  var securityCheckIcon: Image {
      Image(ImageEnum.securityCheckIcon.rawValue, bundle: bundle)
  }
  var personalausweisLogo: Image {
    Image(ImageEnum.personalausweisLogo.rawValue, bundle: bundle)
  }
  var transportPinLetter: Image {
    Image(ImageEnum.tranportPinLetter.rawValue, bundle: bundle)
  }
  var tranportPinEnvelope: Image {
    Image(ImageEnum.tranportPinEnvelope.rawValue, bundle: bundle)
  }
  var phoneIPhone: Image {
    Image(ImageEnum.phoneIPhone.rawValue, bundle: bundle)
  }
  var checkCircle: Image {
    Image(ImageEnum.checkCircle.rawValue, bundle: bundle)
  }
  var orangeRetryError: Image {
    Image(ImageEnum.orangeRetryError.rawValue, bundle: bundle)
  }
  var multipleAusweisCards: Image {
    Image(ImageEnum.multipleAusweisCards.rawValue, bundle: bundle)
  }
  var ausweisPinAndCard: Image {
    Image(ImageEnum.ausweisPinAndCard.rawValue, bundle: bundle)
  }
  var setupWalletPin: Image {
    Image(ImageEnum.setupWalletPin.rawValue, bundle: bundle)
  }
  var userPhonePin: Image {
    Image(ImageEnum.userPhonePin.rawValue, bundle: bundle)
  }
  var warningIndicator: Image {
    Image(ImageEnum.warningIndicator.rawValue, bundle: bundle)
  }
  var redWarningIndicator: Image {
    Image(ImageEnum.redWarningIndicator.rawValue, bundle: bundle)
  }
  var backgroundPID: Image {
    Image(ImageEnum.backgroundPID.rawValue, bundle: bundle)
  }
  var backgroundSplash: Image {
    Image(ImageEnum.backgroundSplash.rawValue, bundle: bundle)
  }
  var bdrLogo: Image {
    Image(ImageEnum.bdrLogo.rawValue, bundle: bundle)
  }
  var ausweisCanHighlighted: Image {
    Image(ImageEnum.ausweisCanHighlighted.rawValue, bundle: bundle)
  }
  var errorIndicatorIcon: Image {
    Image(ImageEnum.errorIndicatorIcon.rawValue, bundle: bundle)
  }
  var squareArrowDown: Image {
    Image(systemName: ImageEnum.squareArrowDown.rawValue)
  }
  var idCardIconGreen: Image {
    Image(ImageEnum.idCardIconGreen.rawValue, bundle: bundle)
  }
  var person: Image {
    Image(ImageEnum.person.rawValue, bundle: bundle)
  }
  var eyeIcon: Image {
    Image(ImageEnum.eyeIcon.rawValue, bundle: bundle)
  }
  var eyeIconOff: Image {
    Image(ImageEnum.eyeIconOff.rawValue, bundle: bundle)
  }
  var arrowheadUp: Image {
    Image(ImageEnum.arrowheadUp.rawValue, bundle: bundle)
  }
  var arrowheadDown: Image {
    Image(ImageEnum.arrowheadDown.rawValue, bundle: bundle)
  }
  var addPID: Image {
    Image(ImageEnum.addPID.rawValue, bundle: bundle)
  }
  var credentialNotFound: Image {
    Image(ImageEnum.credentialNotFound.rawValue, bundle: bundle)
  }
  var shareIcon: Image {
    Image(ImageEnum.shareIcon.rawValue, bundle: bundle)
  }
  var copyIcon: Image {
    Image(ImageEnum.copyIcon.rawValue, bundle: bundle)
  }
  var checkboxSelected: Image {
    Image(ImageEnum.checkboxSelected.rawValue, bundle: bundle)
  }
  var checkboxUnselected: Image {
    Image(ImageEnum.checkboxUnselected.rawValue, bundle: bundle)
  }
  var workInProgessLockIcon: Image {
    Image(ImageEnum.workInProgessLockIcon.rawValue, bundle: bundle)
  }
  var workInProgessIcon: Image {
    Image(ImageEnum.workInProgessIcon.rawValue, bundle: bundle)
  }
  var help: Image {
    Image(systemName: ImageEnum.help.rawValue)
  }
  var buildingBlocks: Image {
    Image(ImageEnum.buildingBlocks.rawValue, bundle: bundle)
  }
  var externalLink: Image {
    Image(ImageEnum.externalLink.rawValue, bundle: bundle)
  }
  var burgeramtInfo: Image {
    Image(ImageEnum.burgeramtInfo.rawValue, bundle: bundle)
  }
  var pinCodeAsset: Image {
    Image(ImageEnum.pinCodeAsset.rawValue, bundle: bundle)
  }
  var pinIllusItem: Image {
    Image(ImageEnum.pinIllusItem.rawValue, bundle: bundle)
  }
}
