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

protocol LocalizableManagerType: Sendable {
  static var shared: LocalizableManagerType { get }
  func get(with key: LocalizableStringKey) -> String
}

final class LocalizableManager: LocalizableManagerType {
  
  static let shared: LocalizableManagerType = LocalizableManager()
  
  private let bundle: Bundle
  
  private init() {
    self.bundle = .assetsBundle
  }
  
  // TODO: To be removed when the keys are provided.
  private func missingKeys(_ key: String) -> String {
    switch key {
    case "security_check_title":
        return "Platform authentication is disabled"
    default:
      return ""
    }
  }
  
  private func mapKey(_ oldKey: String) -> String {
    let keyMapping: [String: String] = [
      // Basic UI elements
      "search": "app_onboarding.welcome.prim_button", // Placeholder - need to find actual search key
      "add_doc": "app_onboarding.no_cards.prim_button", // Placeholder - need to find actual add_doc key
      "cancel_button": "pid_presentation.dialog_rp_rejection.sec_button", // "Abbrechen"
      "ok_button": "pid_presentation.rp_info.prim_button", // "Weiter"
      "share_button": "pid_presentation.success.prim_button", // Placeholder
      "try_again": "pid_issuance.dialog_server_error.prim_button", // Completed
      "next": "app_onboarding.welcome.prim_button", // "Weiter"
      "back": "pid_presentation.dialog_rp_rejection.sec_button", // "Abbrechen"
      "close": "pid_presentation.dialog_rp_rejection.sec_button", // "Abbrechen"
      "done_button": "pid_presentation.success.prim_button", // Placeholder
      "delete_button": "pid_inspection.pid_details.sec_button", // Completed
      
      // Success/Error messages
      "success": "pid_presentation.success.title", // Placeholder
      "generic_error_title": "pid_presentation.dialog_server_error.server_error_title",
      "generic_error_description": "pid_presentation.dialog_server_error.error_server_paragraph",
      
      // PIN/Password related
      "invalid_quick_pin": "pid_presentation.wallet_pin_entry.error_wrong_pin",
      "quick_pin_enter_a_pin": "pid_presentation.wallet_pin_entry.title",
      "quick_pin_confirm_pin": "pid_presentation.wallet_pin_entry.title",
      "biometry_confirm_request": "pid_presentation.sheet_wallet_pin_entry.title",
      
      // Document related
      "add_document_title": "pid_issuance.onboarding_cards.title",
      "add_document_request": "pid_issuance.onboarding_cards.paragraph",
      "add_document_subtitle": "pid_issuance.onboarding_cards.paragraph",
      "view_document_details": "pid_presentation.data_consent.title",
      "document_added": "pid_issuance.sheet_success_issuance.title",
      
      // Data sharing
      "request_data_share_caption": "pid_presentation.rp_info.paragraph_1",
      "request_data_share_title": "pid_presentation.rp_info.title",
      "request_data_info_notice": "pid_presentation.rp_info.paragraph_2",
      "request_data_sheet_caption": "pid_presentation.data_consent.title",
      "share_data_review_title": "pid_presentation.data_consent.title",
      "successfully_shared_following_information": "pid_presentation.success.paragraph",
      "incomplete_request_data_selecting": "pid_presentation.dialog_rp_overasking.paragraph_overasking",
      
      // Issuance related
      "issuance_success_title_punctuated": "pid_issuance.sheet_success_issuance.title",
      "issuance_success_caption": "pid_issuance.sheet_success_issuance.paragraph",
      "issuance_success_next_button": "pid_issuance.sheet_success_issuance.prim_button",
      "issuance_details_continue_button": "pid_issuance.data_consent.prim_button",
      "issuance_details_doc_deletion_title": "pid_presentation.dialog_rp_rejection.title",
      "issuance_details_doc_deletion_caption": "pid_presentation.dialog_rp_rejection.paragraph",
      
      // QR/Scanner related
      "scan_qr_code": "pid_presentation.rp_info.title", // Placeholder
      "scanner_qr_title": "pid_presentation.rp_info.title", // Placeholder
      "scanner_qr_caption": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "scanner_qr_title_issuing": "pid_issuance.onboarding_cards.title", // Placeholder
      "scanner_qr_title_presentation": "pid_presentation.rp_info.title", // Placeholder
      "scanner_qr_caption_issuing": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "scanner_qr_caption_presentation": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "qr_scan_informative_text": "pid_presentation.rp_info.paragraph_2", // Placeholder
      
      // Authentication
      "login_title": "pid_presentation.wallet_pin_entry.title",
      "login_caption": "pid_presentation.sheet_wallet_pin_entry.paragraph",
      "login_caption_quick_pin_only": "pid_presentation.sheet_wallet_pin_entry.paragraph",
      
      // Quick PIN setup
      "quick_pin_set_title": "pid_issuance.wallet_pin_intro.title",
      "quick_pin_set_step_one_caption": "pid_issuance.wallet_pin_intro.paragraph",
      "quick_pin_set_step_two_caption": "pid_issuance.wallet_pin_reenter.title",
      "quick_pin_next_button": "pid_issuance.wallet_pin_intro.prim_button",
      "quick_pin_confirm_button": "pid_issuance.wallet_pin_reenter.prim_button",
      "quick_pin_set_success": "pid_issuance.wallet_pin_reenter.succes",
      "quick_pin_set_success_button": "pid_issuance.wallet_pin_reenter.prim_button",
      "quick_pin_dont_match": "pid_issuance.wallet_pin_setup.error",
      
      // Quick PIN update
      "quick_pin_update_title": "pid_issuance.wallet_pin_setup.title",
      "quick_pin_update_step_one_caption": "pid_issuance.wallet_pin_intro.paragraph",
      "quick_pin_update_step_two_caption": "pid_issuance.wallet_pin_reenter.title",
      "quick_pin_update_step_three_caption": "pid_issuance.wallet_pin_setup.title",
      "quick_pin_update_success": "pid_issuance.wallet_pin_reenter.succes",
      "quick_pin_update_success_button": "pid_issuance.wallet_pin_reenter.prim_button",
      "quick_pin_update_cancellation_title": "pid_presentation.dialog_rp_rejection.title",
      "quick_pin_update_cancellation_caption": "pid_presentation.dialog_rp_rejection.paragraph",
      "quick_pin_update_cancellation_continue": "pid_presentation.dialog_rp_rejection.prim_button",
      
      // Biometry
      "biometry_open_settings": "pid_presentation.sheet_wallet_pin_entry.title", // Placeholder
      "change_quick_pin_option": "pid_issuance.wallet_pin_setup.title", // Placeholder
      
      // Document fields
      "name": "pid_issuance.data_consent_issuer.label_name",
      "given_name": "pid_presentation.data_consent.label_first_names",
      "family_name": "pid_presentation.data_consent.label_birth_name",
      "birth_year": "pid_presentation.data_consent.label_age_birth_year",
      "age_in_years": "pid_presentation.data_consent.label_age_in_years",
      "birth_family_name": "pid_presentation.data_consent.label_birth_name",
      "age_equal_or_over": "pid_presentation.data_consent.label_age_equal_or_over",
      "issuing_authority": "pid_presentation.data_consent.label_issuing_authority",
      "issuing_date": "pid_presentation.data_consent.label_created_at",
      "distributor": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "years": "pid_presentation.data_consent.label_age_in_years", // Placeholder
      "address": "pid_presentation.data_consent.label_adress",
      "title": "pid_presentation.data_consent.label_title",
      "nationality": "pid_presentation.data_consent.label_nationality",
      "date_of_birth": "pid_presentation.data_consent.label_birth_date",
      "place_of_birth": "pid_presentation.data_consent.label_place_of_birth",
      "issuing_country": "pid_presentation.data_consent.label_issuing_country",
      "valid_until": "pid_presentation.data_consent.label_expire_date",
      "created_date": "pid_presentation.data_consent.label_created_at",
      
      // Categories
      "category_government": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "category_health": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "category_education": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "category_finance": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "category_retail": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "category_other": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "category_social_security": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "category_travel": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      
      // App specific
      "app-name": "global.app_name", // Completed
      "My EU Wallet": "global.app_name", // Completed
      
      // Common actions
      "yes": "pid_issuance.data_consent.label_age_equal_or_over_yes", // "Ja, löschen"
      "no": "pid_issuance.data_consent.label_age_equal_or_over_no", // "Abbrechen"
      "reject": "pid_presentation.rp_info.sec_button", // "Ablehnen"
      "return": "pid_presentation.dialog_rp_rejection.sec_button", // "Abbrechen"
      "yes_reject": "pid_presentation.dialog_rp_rejection.prim_button", // "Ja, löschen"
      
      // Error messages
      "error_unable_fetch_documents": "pid_presentation.dialog_server_error.error_server_paragraph",
      "error_unable_fetch_document": "pid_presentation.dialog_server_error.error_server_paragraph",
      "error_unable_present_documents": "pid_presentation.dialog_server_error.error_server_paragraph",
      "fetch_error_transaction_log": "pid_presentation.dialog_server_error.error_server_paragraph",
      "parSetupFailed": "pid_presentation.dialog_server_error.server_error_title",
      
      // Issuance specific
      "issuance_request": "pid_issuance.onboarding_cards.title",
      "issue_button": "pid_issuance.data_consent.prim_button",
      "unable_to_issue_and_store_documents": "pid_presentation.dialog_server_error.error_server_paragraph",
      "issuance_failed": "pid_presentation.dialog_server_error.server_error_title",
      "in_progress": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "pending": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      
      // Presentation specific
      "presentation_confirmation_title": "pid_presentation.rp_info.title",
      "presentation_confirmation_description1": "pid_presentation.rp_info.paragraph_1",
      "presentation_confirmation_description2": "pid_presentation.rp_info.paragraph_2",
      "presentation_confirmation_continue_button": "pid_presentation.rp_info.prim_button",
      "presentation_confirmation_cancel_button": "pid_presentation.rp_info.sec_button",
      
      // Data consent
      "rp-consent-title": "pid_presentation.rp_info.title",
      "send_data": "pid_presentation.rp_info.prim_button", // Placeholder
      "password_entry_title": "pid_presentation.wallet_pin_entry.title",
      "enter_password": "pid_presentation.wallet_pin_entry.title",
      "what_is_password": "pid_presentation.sheet_wallet_pin_entry.title",
      "data_sent_successfully": "pid_presentation.success.title",
      "data_sent_successfully_message": "pid_presentation.success.paragraph",
      "back_to_provider": "pid_presentation.success.prim_button", // Placeholder
      "report_problem": "pid_issuance.data_consent_issuer.sec_button", // Completed
      "what_is_security_password": "pid_presentation.sheet_wallet_pin_entry.title",
      "enter_security_password": "pid_presentation.wallet_pin_entry.title",
      "enter_your_password": "pid_presentation.wallet_pin_entry.title",
      
      // Purpose and data
      "purpose": "pid_presentation.rp_info.title", // Placeholder
      "account_opening": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "required_data": "pid_presentation.data_consent.title",
      "only_following_data_will_be_sent": "pid_presentation.data_consent.paragraph", // Placeholder
      "personal_data": "pid_presentation.data_consent.title",
      "confirm_itendification_refusal": "pid_presentation.dialog_rp_rejection.title",
      "confirm_itendification_refusal_message": "pid_presentation.dialog_rp_rejection.paragraph",
      "confirm_identification_refusal": "pid_presentation.dialog_rp_rejection.title",
      "confirm_identification_refusal_message": "pid_presentation.dialog_rp_rejection.paragraph",
      
      // Certificate and signature
      "certificate": "pid_presentation.data_consent.label_created_at", // Placeholder
      "signature": "pid_presentation.data_consent.label_created_at", // Placeholder
      "issuer": "pid_presentation.data_consent.label_issuing_authority",
      "country": "pid_presentation.data_consent.label_issuing_country",
      "rp_details": "pid_presentation.rp_info.title", // Placeholder
      "publisher": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "activity": "pid_presentation.data_consent.label_created_at", // Placeholder
      "valid_in_until": "pid_presentation.data_consent.label_expire_date",
      "verified_in_wallet_until": "pid_presentation.data_consent.label_expire_date",
      "created_on": "pid_presentation.data_consent.label_created_at",
      
      // Document actions
      "delete_pid": "pid_presentation.dialog_rp_rejection.title", // Placeholder
      "create_with_personal_ausweis": "pid_issuance.onboarding_cards.title", // Placeholder
      "delete_document": "pid_inspection.pid_details.sec_button", // "Completed"
      "delete_document_confirm_dialog": "pid_presentation.dialog_rp_rejection.paragraph",
      
      // Dashboard
      "home": "global.app_name", // Placeholder
      "documents": "pid_presentation.data_consent.title", // Placeholder
      "transactions": "pid_presentation.data_consent.label_created_at", // Placeholder
      "authenticate_authorise_transactions": "pid_presentation.wallet_pin_entry.title", // Placeholder
      "electronically_sign_digital_documents": "pid_presentation.data_consent.title", // Placeholder
      "learn_more": "pid_presentation.sheet_wallet_pin_entry.info_security_pin_button", // Placeholder
      "choose_from_list": "pid_inspection.initial_dashboard.title", // Placeholder
      "choose_from_list_title": "pid_inspection.initial_dashboard.title", // Completed
      "add_documents_to_wallet": "pid_issuance.onboarding_cards.paragraph",
      "details": "pid_presentation.data_consent.title", // Placeholder
      "data_sharing_request": "pid_presentation.rp_info.title",
      "data_shared": "pid_presentation.success.title",
      "data_sharing_title": "pid_presentation.rp_info.title",
      "trusted_relying_party": "pid_presentation.rp_info.title", // Placeholder
      "trusted_relying_party_description": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "issuer_want_wallet_addition": "pid_issuance.onboarding_cards.title", // Placeholder
      "filter_by_issuer": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      "alert_access_online_services": "pid_presentation.rp_info.title", // Placeholder
      "alert_access_online_services_message": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "alert_sign_documents_safely": "pid_presentation.data_consent.title", // Placeholder
      "alert_sign_documents_safely_message": "pid_presentation.data_consent.paragraph", // Placeholder
      "authenticate": "pid_presentation.wallet_pin_entry.title",
      "in_person": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "Online": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "from_device": "pid_presentation.data_consent.title", // Placeholder
      "autodashboard_authenticate_dialog_message": "pid_presentation.wallet_pin_entry.title", // Placeholder
      "saved_to_favorites": "pid_presentation.success.title", // Placeholder
      "succesfully_added_following_to_wallet": "pid_issuance.sheet_success_issuance.paragraph",
      "removed_from_favorites": "pid_presentation.dialog_rp_rejection.title", // Placeholder
      "saved_to_favorites_message": "pid_presentation.success.paragraph", // Placeholder
      "removed_from_favorites_messages": "pid_presentation.dialog_rp_rejection.paragraph", // Placeholder
      "view_details": "pid_presentation.data_consent.title", // Placeholder
      "requests_the_following": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "wallet_is_secured": "pid_presentation.sheet_wallet_pin_entry.paragraph", // Placeholder
      "no_results": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      "no_results_description": "pid_presentation.dialog_rp_unkown.paragraph_cert_failed", // Placeholder
      "proximity_connection_nfc_description": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "or_share_via_nfc": "pid_presentation.rp_info.paragraph_2", // Placeholder
      
      // Filters and sorting
      "filters": "pid_presentation.data_consent.title", // Placeholder
      "sort_by_issued_date": "pid_presentation.data_consent.label_created_at", // Placeholder
      "show_results": "pid_presentation.data_consent.prim_button", // Placeholder
      "reset": "pid_presentation.dialog_rp_rejection.sec_button", // Placeholder
      "all": "pid_presentation.data_consent.title", // Placeholder
      "descending": "pid_presentation.data_consent.title", // Placeholder
      "ascending": "pid_presentation.data_consent.title", // Placeholder
      "expiry": "pid_presentation.data_consent.label_expire_date", // Placeholder
      "expiry_period": "pid_presentation.data_consent.label_expire_date", // Placeholder
      "filter_by_state": "pid_presentation.data_consent.title", // Placeholder
      "sort_by": "pid_presentation.data_consent.title", // Placeholder
      "order_by": "pid_presentation.data_consent.title", // Placeholder
      "filter_by_category": "pid_presentation.data_consent.title", // Placeholder
      "search_documents": "pid_presentation.data_consent.title", // Placeholder
      
      // Document states
      "default": "pid_presentation.data_consent.title", // Placeholder
      "valid": "pid_presentation.data_consent.label_expire_date", // Placeholder
      "revoke": "pid_presentation.dialog_rp_rejection.prim_button", // Placeholder
      "expired": "pid_presentation.data_consent.label_expire_date", // Placeholder
      "date_issued": "pid_presentation.data_consent.label_created_at",
      "expiry_date": "pid_presentation.data_consent.label_expire_date",
      "next_seven_days": "pid_presentation.data_consent.label_expire_date", // Placeholder
      "next_thirty_days": "pid_presentation.data_consent.label_expire_date", // Placeholder
      "beyond_thirty_days": "pid_presentation.data_consent.label_expire_date", // Placeholder
      "before_today": "pid_presentation.data_consent.label_expire_date", // Placeholder
      
      // Other
      "changelog": "pid_presentation.data_consent.title", // Placeholder
      "show_details": "pid_presentation.data_consent.toggle_visible_button",
      "hide_details": "pid_presentation.data_consent.toggle_unvisible_button",
      "why_is_data_needed_title": "pid_issuance.sheet_explain_data.title", // Completed
      "why_is_data_needed_description": "pid_issuance.sheet_explain_data.paragraph", // Completed
      "card_pin_entered_wrong_twice": "pid_issuance.can_intro.title", // Completed
      "can_info_title": "pid_issuance.can_entry.sec_button",
      "can_info_desc": "pid_issuance.sheet_can.paragraph",
      "can_eingeben": "pid_issuance.can_intro.prim_button", // Completed
      "issuance_can_entry_title": "pid_issuance.can_entry.title",
      "issuance_error_wrong_can": "pid_issuance.can_entry.error_wrong_can", // Completed
      "card_pin_entered_wrong_description": "pid_issuance.can_intro.paragraph_1",
      "security_check_alert_tile": "pid_issuance.card_pin_entry.title", // Placeholder
      "security_check_title": "app_onboarding.pa_not_set.title",
      "security_check_description": "pid_issuance.card_pin_entry.error", // Placeholder
      "security_check_alert_description": "pid_issuance.card_pin_entry.error", // Placeholder
      "security_check_button_title": "app_onboarding.pa_not_set.prim_button",
      "issuance_eid_pin_entry_title": "pid_issuance.card_pin_entry.title",
      "issuance_scanning_title": "nfc_scanning.nfc_tap.title_card_pin", // Complete
      "issuance_button_karten_pin": "pid_issuance.sheet_eID_PIN_not_set.prim_button", // Placeholder
      "issuance_button_find_burgeramt": "pid_issuance.sheet_eID_PIN_not_set.sec_button", // Completed
      "issuance_eid_unkown_paragraph_1": "pid_issuance.sheet_eID_PIN_not_set.paragraph_1",
      "issuance_eid_unkown_paragraph_2": "pid_issuance.sheet_eID_PIN_not_set.paragraph_2",
      "issuance_eid_unkown_paragraph_31": "pid_issuance.sheet_eID_PIN_not_set.list_1",
      "issuance_eid_unkown_paragraph_32": "pid_issuance.sheet_eID_PIN_not_set.list_2",
      "issuance_eid_unkown_paragraph_33": "pid_issuance.sheet_eID_PIN_not_set.list_3",
      "issuance_eid_unkown_title": "pid_issuance.sheet_eID_PIN_not_set.title",
      "burgeramt_service_link": "pid_issuance.sheet_eID_PIN_not_set.sec_button",
      "setup_pin_title": "eid_setup.transport_pin_intro.title", // Completed
      "setup_pin_primary_button_title": "eid_setup.transport_pin_intro.prim_button", // Completed
      "setup_pin_secondary_button_title": "eid_setup.transport_pin_entry.sec_button",
     // "setup_pin_message": "eid_setup.transport_pin_intro.paragraph",
      "setup_pin_transport_view_title": "eid_setup.transport_pin_intro.title",
      "setup_pin_transport_view_primary_button_title": "eid_setup.transport_pin_intro.prim_button",
      "setup_pin_transport_view_secondary_button_title": "eid_setup.transport_pin_intro.sec_button",
      "setup_pin_transport_view_message": "eid_setup.transport_pin_intro.paragraph",
      "setup_pin_sheet_title": "eid_setup.transport_pin_intro.sec_button", // Completed
      "setup_pin_sheet_message": "eid_setup.transport_pin_entry.error", // Placeholder
      "setup_pin_sheet_button_text": "eid_setup.transport_pin_entry.prim_button",
      "transport_pin_view_title": "eid_setup.transport_pin_entry.title",
      "setup_new_pin_instruction_view_title": "eid_setup.card_pin_intro.title",
      "setup_new_pin_instruction_view_primary_button_tilte": "eid_setup.card_pin_intro.prim_button",
      "setup_new_pin_instruction_view_secondary_button_title": "eid_setup.card_pin_intro.sec_button",
      "confirmation_pin_mismatch": "eid_setup.card_pin_setup.error",
      "scanning_tips": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "scanning_guide_para_1": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "scanning_guide_para_2": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "restart_scanning": "pid_issuance.onboarding_cards.prim_button", // Placeholder
      "scanning_help_popup_title": "pid_issuance.onboarding_cards.title", // Placeholder
      "scanning_help_popup_detail_para_1": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "scanning_help_popup_detail_para_2": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "scanning_help_popup_detail_para_3": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "scanning_help_customer_service_calling": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "scanning_customer_service_phone_number": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "transport_pin_correct": "eid_setup.transport_pin_entry.title", // Placeholder
      "card_pin_set": "eid_setup.card_pin_setup.title", // Placeholder
      "set_new_eid_pin_one": "eid_setup.card_pin_intro.title", // Placeholder
      "set_new_eid_pin_two": "eid_setup.card_pin_reenter.title", // Placeholder
      "try_again_in": "pid_presentation.retry_counter.counter_paragraph", // Placeholder
      "wallet_pin_forgotten": "pid_presentation.retry_counter.locked_title", // Placeholder
      "wallet_pin_multiple_wrong_entry": "pid_presentation.retry_counter.counter_title", // Placeholder
      "issuance_onboarding_title": "pid_issuance.onboarding_cards.title",
      "issuance_onboarding_message": "pid_issuance.onboarding_cards.paragraph",
      "issuance_onboarding_pin_info_view_title": "pid_issuance.onboarding_eid.title",
      "issuance_onboarding_pin_info_view_message": "pid_issuance.onboarding_eid.paragraph",
      "issuance_onboarding_pin_info_view_primary_button_title": "pid_issuance.onboarding_eid.prim_button",
      "issuance_onboarding_pin_info_view_secondary_button_title": "pid_issuance.onboarding_eid.sec_button",
      "issuance_onboarding_primary_button_title": "pid_issuance.onboarding_cards.prim_button",
      "karten_pin_correct": "eid_setup.card_pin_setup.title", // Placeholder
      "wallet_pin_setup_title": "pid_issuance.wallet_pin_intro.title", 
      "wallet_pin_setup_warning": "pid_issuance.wallet_pin_intro.paragraph", // Placeholder
      "wallet_pin_setup_primary_button_title": "pid_issuance.wallet_pin_intro.prim_button",
      "set_wallet_pin_title": "pid_issuance.wallet_pin_setup.title",
      "continue_title": "pid_issuance.wallet_pin_intro.prim_button", // Placeholder
      "wallet_pin_setup_confirm_title": "pid_issuance.wallet_pin_reenter.title",
      "setup_wallet_pin_incorrect_retype_entry": "pid_issuance.wallet_pin_setup.error",
      "try_again_in_few_minutes": "pid_presentation.retry_counter.counter_paragraph", // Placeholder
      "server_unavailable": "pid_presentation.dialog_server_error.server_error_title",
      "wallet_pin_try_again_in": "pid_presentation.retry_counter.counter_paragraph", // Placeholder
      "wallet_pin_last_try_left": "pid_presentation.retry_counter.warning_paragraph", // Placeholder
      "wallet_pin_blocked_message": "pid_presentation.retry_counter.blocked_paragraph",
      "wallet_pin_retry_info_detail": "pid_presentation.retry_counter.counter_overlay_paragraph", // Placeholder
      "wallet_pin_wrong_entry": "pid_presentation.wallet_pin_entry.error_wrong_pin",
      "wallet_pin_forgot_popup_desc": "pid_presentation.retry_counter.reset_overlay_paragraph", // Placeholder
      "wallet_reset_now": "pid_presentation.retry_counter.reset_overlay_title", // Placeholder
      "delete_eid_confirmation_title": "pid_presentation.dialog_rp_rejection.title", // Placeholder
      "delete_eid_confirmation_message": "pid_presentation.dialog_rp_rejection.paragraph", // Placeholder
      "digital_id_deleted": "pid_presentation.dialog_rp_rejection.prim_button", // Placeholder
      "to_wallet": "pid_presentation.success.prim_button", // Placeholder
      "dashboard_screen_secondary_text": "app_onboarding.welcome.paragraph", // Placeholder
      "dashboard_primary_button_title": "pid_inspection.initial_dashboard.prim_button", // Complete
      "issuance_consent_view_title": "pid_issuance.data_consent.title",
      "issuance_digital_id": "pid_issuance.data_consent.headline_credential", // Completed
      "issuance_consent_view_primary_button_title": "pid_issuance.data_consent.prim_button",
      "issuance_consent_view_secondary_button_title": "pid_issuance.data_consent.sec_button",
      "email": "pid_issuance.data_consent_issuer.label_email", // Completed
      "privacy_policy": "pid_issuance.data_consent_issuer.label_privacy", // Completed
      "certificate_valid_until": "pid_issuance.data_consent_issuer.label_certifacte_valid",
      "issued_by": "pid_issuance.data_consent.label_issued_by",
      "scanning-guide-para1": "nfc_scanning.nfc_tap.list_1", // Completed
      "scanning-guide-para2": "nfc_scanning.nfc_tap.list_2_ios", // Completed
      "scanning-guide-para3": "nfc_scanning.nfc_tap.list_3", // Completed
      
      // Issuance success and deferred
      "issuance_success_header_description_when_error": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "scoped_issuance_success_deferred_caption": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "scoped_issuance_success_deferred_caption_docname": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "scoped_issuance_success_deferred_caption_docname_and_issuer_name": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "issuance_success_deferred_caption": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "deferred_document_issued_modal_title": "pid_issuance.sheet_success_issuance.title", // Placeholder
      "deferred_document_issued_modal_caption": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "retrieve_logs": "pid_presentation.dialog_server_error.sec_button", // Placeholder
      
      // Credential offer
      "request_credential_offer_title": "pid_issuance.onboarding_cards.title", // Placeholder
      "request_credential_offer_caption": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "request_credential_offer_no_document": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "credential_offer_success_button": "pid_issuance.sheet_success_issuance.prim_button", // Placeholder
      "credential_offer_success_caption": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "credential_offer_partial_success_caption": "pid_issuance.sheet_success_issuance.paragraph", // Placeholder
      "issuance_code_title": "pid_issuance.onboarding_cards.title", // Placeholder
      "issuance_code_caption": "pid_issuance.onboarding_cards.paragraph", // Placeholder
      "transaction_code_format_error": "pid_issuance.can_entry.error_wrong_can", // Placeholder
      
      // Issuance cancellation
      "cancel_issuance_sheet_title": "pid_presentation.dialog_rp_rejection.title", // Placeholder
      "cancel_issuance_sheet_caption": "pid_presentation.dialog_rp_rejection.paragraph", // Placeholder
      "cancel_issuance_sheet_continue": "pid_presentation.dialog_rp_rejection.prim_button", // Placeholder
      
      // Unknown entities
      "unknown_verifier": "pid_presentation.dialog_rp_unkown.title",
      "unknown_issuer": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      "generic_issuer": "pid_presentation.data_consent.label_issuing_authority", // Placeholder
      
      // BLE/NFC
      "ble_disabled_modal_title": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      "ble_disabled_modal_content": "pid_presentation.dialog_rp_unkown.paragraph_cert_failed", // Placeholder
      "ble_disabled_modal_button": "pid_presentation.dialog_rp_unkown.sec_button", // Placeholder
      
      // Camera and scanning
      "camera_error": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      "missing_pid": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      "show_qr_tap": "pid_presentation.rp_info.prim_button", // Placeholder
      
      // Welcome and onboarding
      "welcome_back": "app_onboarding.welcome.title", // Completed
      "please_wait": "pid_presentation.retry_counter.counter_overlay_title", // Placeholder
      "more_options": "pid_presentation.data_consent.toggle_visible_button", // Placeholder
      "unavailable_field": "pid_presentation.data_consent.label_created_at", // Placeholder
      "proxmity_connectivity_caption": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "request_data_verified_entity": "pid_presentation.rp_info.title", // Placeholder
      "request_data_verified_entity_message": "pid_presentation.rp_info.paragraph_1", // Placeholder
      "request_data_no_document": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      "request_data_share_quick_pin_caption": "pid_presentation.wallet_pin_entry.title", // Placeholder
      "request_data_share_biometry_caption": "pid_presentation.sheet_wallet_pin_entry.title", // Placeholder
      
      // Item storage
      "item_not_found_in_storage": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      "items_not_found_in_storage": "pid_presentation.dialog_rp_unkown.title", // Placeholder
      
      // Sign document
      "sign_document": "pid_presentation.data_consent.title", // Placeholder
      "sign_document_subtitle": "pid_presentation.data_consent.paragraph", // Placeholder
      "select_document": "pid_presentation.data_consent.title", // Placeholder
      
      // Labels
      "label-created-at": "pid_presentation.data_consent.label_created_at",
      "var-label-delete-card": "pid_inspection.pid_details.sec_button", // "Completed"
      "var-date-of-creation": "pid_presentation.data_consent.label_created_at",
      
      // New additions - Verified
      "restart-scanning": "nfc_scanning.nfc_tap.prim_button",
      "scanning-tips": "nfc_scanning.nfc_tap.sec_button",
      "card-pin-set": "nfc_scanning.success_error.success_card_pin_setup_title_ios",
      "dashboard_card_title": "global.pid_credential_name",
      "wallet-pin-multiple-wrong-entry": "pid_presentation.retry_counter.counter_title",
      "wallet-pin-try-again-in": "pid_presentation.retry_counter.counter_paragraph",
      "wallet-pin-forgotten": "pid_presentation.retry_counter.counter_overlay_title",
      "wallet-reset-now": "pid_presentation.retry_counter.counter_overlay_sec_button",
       "add_new_eid_pin_one": "eid_setup.card_pin_intro.title"
   ]
    
    return keyMapping[oldKey] ?? oldKey
  }
    
    func get(with key: LocalizableStringKey) -> String {
      return switch key {
      case .dynamic(let key):
        bundle.localizedString(forKey: mapKey(key))
      case .custom(let literal):
        literal
      case .space:
        " "
      case .search:
        bundle.localizedString(forKey: mapKey("search"))
      case .genericErrorTitle:
        bundle.localizedString(forKey: mapKey("generic_error_title"))
      case .genericErrorDesc:
        bundle.localizedString(forKey: mapKey("generic_error_description"))
      case .biometryOpenSettings:
        bundle.localizedString(forKey: mapKey("biometry_open_settings"))
      case .invalidQuickPin:
        bundle.localizedString(forKey: mapKey("invalid_quick_pin"))
      case .tryAgain:
        bundle.localizedString(forKey: mapKey("try_again"))
      case .shareButton:
        bundle.localizedString(forKey: mapKey("share_button"))
      case .cancelButton:
        bundle.localizedString(forKey: mapKey("cancel_button"))
      case .requestDataCaption:
        bundle.localizedString(forKey: mapKey("request_data_share_caption"))
      case .requestDataInfoNotice:
        bundle.localizedString(forKey: mapKey("request_data_info_notice"))
      case .requestDataTitle(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("request_data_share_title"), arguments: args)
      case .documentAdded:
        bundle.localizedString(forKey: mapKey("document_added"))
      case .requestDataSheetCaption:
        bundle.localizedString(forKey: mapKey("request_data_sheet_caption"))
      case .okButton:
        bundle.localizedString(forKey: mapKey("ok_button"))
      case .shareDataReview:
        bundle.localizedString(forKey: mapKey("share_data_review_title"))
      case .success:
        bundle.localizedString(forKey: mapKey("success"))
      case .successfullySharedFollowingInformation:
        bundle.localizedString(forKey: mapKey("successfully_shared_following_information"))
      case .incompleteRequestDataSelection:
        bundle.localizedString(forKey: mapKey("incomplete_request_data_selecting"))
      case .addDoc:
        bundle.localizedString(forKey: mapKey("add_doc"))
      case .showQRTap:
        bundle.localizedString(forKey: mapKey("show_qr_tap"))
      case .welcomeBack(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("welcome_back"), arguments: args)
      case .viewDocumentDetails:
        bundle.localizedString(forKey: mapKey("view_document_details"))
      case .pleaseWait:
        bundle.localizedString(forKey: mapKey("please_wait"))
      case .requestDataShareQuickPinCaption:
        bundle.localizedString(forKey: mapKey("request_data_share_quick_pin_caption"))
      case .requestDataShareBiometryCaption:
        bundle.localizedString(forKey: mapKey("request_data_share_biometry_caption"))
      case .addDocumentTitle:
        bundle.localizedString(forKey: mapKey("add_document_title"))
      case .addDocumentRequest:
        bundle.localizedString(forKey: mapKey("add_document_request"))
      case .addDocumentSubtitle:
        bundle.localizedString(forKey: mapKey("add_document_subtitle"))
      case .proximityConnectivityCaption:
        bundle.localizedString(forKey: mapKey("proxmity_connectivity_caption"))
      case .unavailableField:
        bundle.localizedString(forKey: mapKey("unavailable_field"))
      case .requestDataVerifiedEntity:
        bundle.localizedString(forKey: mapKey("request_data_verified_entity"))
      case .requestDataVerifiedEntityMessage:
        bundle.localizedString(forKey: mapKey("request_data_verified_entity_message"))
      case .moreOptions:
        bundle.localizedString(forKey: mapKey("more_options"))
      case .changeQuickPinOption:
        bundle.localizedString(forKey: mapKey("change_quick_pin_option"))
      case .quickPinSetTitle:
        bundle.localizedString(forKey: mapKey("quick_pin_set_title"))
      case .quickPinSetCaptionOne:
        bundle.localizedString(forKey: mapKey("quick_pin_set_step_one_caption"))
      case .quickPinSetCaptionTwo:
        bundle.localizedString(forKey: mapKey("quick_pin_set_step_two_caption"))
      case .quickPinNextButton:
        bundle.localizedString(forKey: mapKey("quick_pin_next_button"))
      case .quickPinConfirmButton:
        bundle.localizedString(forKey: mapKey("quick_pin_confirm_button"))
      case .quickPinSetSuccess:
        bundle.localizedString(forKey: mapKey("quick_pin_set_success"))
      case .quickPinSetSuccessButton:
        bundle.localizedString(forKey: mapKey("quick_pin_set_success_button"))
      case .quickPinDoNotMatch:
        bundle.localizedString(forKey: mapKey("quick_pin_dont_match"))
      case .quickPinUpdateTitle:
        bundle.localizedString(forKey: mapKey("quick_pin_update_title"))
      case .quickPinUpdateCaptionOne:
        bundle.localizedString(forKey: mapKey("quick_pin_update_step_one_caption"))
      case .quickPinUpdateCaptionTwo:
        bundle.localizedString(forKey: mapKey("quick_pin_update_step_two_caption"))
      case .quickPinUpdateCaptionThree:
        bundle.localizedString(forKey: mapKey("quick_pin_update_step_three_caption"))
      case .quickPinUpdateSuccess:
        bundle.localizedString(forKey: mapKey("quick_pin_update_success"))
      case .quickPinUpdateSuccessButton:
        bundle.localizedString(forKey: mapKey("quick_pin_update_success_button"))
      case .quickPinUpdateCancellationTitle:
        bundle.localizedString(forKey: mapKey("quick_pin_update_cancellation_title"))
      case .quickPinUpdateCancellationCaption:
        bundle.localizedString(forKey: mapKey("quick_pin_update_cancellation_caption"))
      case .quickPinUpdateCancellationContinue:
        bundle.localizedString(forKey: mapKey("quick_pin_update_cancellation_continue"))
      case .issuanceDetailsContinueButton:
        bundle.localizedString(forKey: mapKey("issuance_details_continue_button"))
      case .successTitlePunctuated:
        bundle.localizedString(forKey: mapKey("issuance_success_title_punctuated"))
      case .issuanceSuccessCaption(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("issuance_success_caption"), arguments: args)
      case .issuanceSuccessNextButton:
        bundle.localizedString(forKey: mapKey("issuance_success_next_button"))
      case .unknownVerifier:
        bundle.localizedString(forKey: mapKey("unknown_verifier"))
      case .unknownIssuer:
        bundle.localizedString(forKey: mapKey("unknown_issuer"))
      case .genericIssuer:
        bundle.localizedString(forKey: mapKey("generic_issuer"))
      case .yes:
        bundle.localizedString(forKey: mapKey("yes"))
      case .no:
        bundle.localizedString(forKey: mapKey("no"))
      case .scanQrCode:
        bundle.localizedString(forKey: mapKey("scan_qr_code"))
      case .validUntil:
        bundle.localizedString(forKey: mapKey("valid_until"))
      case .bleDisabledModalTitle:
        bundle.localizedString(forKey: mapKey("ble_disabled_modal_title"))
      case .bleDisabledModalCaption:
        bundle.localizedString(forKey: mapKey("ble_disabled_modal_content"))
      case .bleDisabledModalButton:
        bundle.localizedString(forKey: mapKey("ble_disabled_modal_button"))
      case .requestDataNoDocument:
        bundle.localizedString(forKey: mapKey("request_data_no_document"))
      case .issuanceDetailsDeletionTitle(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("issuance_details_doc_deletion_title"), arguments: args)
      case .deleteDocument:
        bundle.localizedString(forKey: mapKey("delete_document"))
      case .issuanceDetailsDeletionCaption(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("issuance_details_doc_deletion_caption"), arguments: args)
      case .errorUnableFetchDocuments:
        bundle.localizedString(forKey: mapKey("error_unable_fetch_documents"))
      case .errorUnableFetchDocument:
        bundle.localizedString(forKey: mapKey("error_unable_fetch_document"))
      case .scannerQrTitle:
        bundle.localizedString(forKey: mapKey("scanner_qr_title"))
      case .scannerQrCaption:
        bundle.localizedString(forKey: mapKey("scanner_qr_caption"))
      case .cameraError:
        bundle.localizedString(forKey: mapKey("camera_error"))
      case .missingPid:
        bundle.localizedString(forKey: mapKey("missing_pid"))
      case .requestCredentialOfferTitle(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("request_credential_offer_title"), arguments: args)
      case .requestCredentialOfferCaption:
        bundle.localizedString(forKey: mapKey("request_credential_offer_caption"))
      case .requestCredentialOfferNoDocument:
        bundle.localizedString(forKey: mapKey("request_credential_offer_no_document"))
      case .unableToIssueAndStore:
        bundle.localizedString(forKey: mapKey("unable_to_issue_and_store_documents"))
      case .missingMetadata:
        bundle.localizedString(forKey: "missing_metadata")
      case .issueButton:
        bundle.localizedString(forKey: mapKey("issue_button"))
      case .cancelIssueSheetTitle:
        bundle.localizedString(forKey: mapKey("cancel_issuance_sheet_title"))
      case .cancelIssueSheetCaption:
        bundle.localizedString(forKey: mapKey("cancel_issuance_sheet_caption"))
      case .cancelIssueSheetContinue:
        bundle.localizedString(forKey: mapKey("cancel_issuance_sheet_continue"))
      case .credentialOfferSuccessButton:
        bundle.localizedString(forKey: mapKey("credential_offer_success_button"))
      case .credentialOfferSuccessCaption(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("credential_offer_success_caption"), arguments: args)
      case .credentialOfferPartialSuccessCaption(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("credential_offer_partial_success_caption"), arguments: args)
      case .issuanceCodeTitle(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("issuance_code_title"), arguments: args)
      case .issuanceCodeCaption(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("issuance_code_caption"), arguments: args)
      case .transactionCodeFormatError(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("transaction_code_format_error"), arguments: args)
      case .inProgress:
        bundle.localizedString(forKey: mapKey("in_progress"))
      case .scopedIssuanceSuccessDeferredCaption:
        bundle.localizedString(forKey: mapKey("scoped_issuance_success_deferred_caption"))
      case .scopedIssuanceSuccessDeferredCaptionDocName(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("scoped_issuance_success_deferred_caption_docname"), arguments: args)
      case .scopedIssuanceSuccessDeferredCaptionDocNameAndIssuer(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("scoped_issuance_success_deferred_caption_docname_and_issuer_name"), arguments: args)
      case .issuanceSuccessDeferredCaption(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("issuance_success_deferred_caption"), arguments: args)
      case .issuanceFailed:
        bundle.localizedString(forKey: mapKey("issuance_failed"))
      case .pending:
        bundle.localizedString(forKey: mapKey("pending"))
      case .deferredDocumentsIssuedModalTitle:
        bundle.localizedString(forKey: mapKey("deferred_document_issued_modal_title"))
      case .defferedDocumentsIssuedModalCaption:
        bundle.localizedString(forKey: mapKey("deferred_document_issued_modal_caption"))
      case .retrieveLogs:
        bundle.localizedString(forKey: mapKey("retrieve_logs"))
      case .qrScanInformativeText:
        bundle.localizedString(forKey: mapKey("qr_scan_informative_text"))
      case .unableToPresentAndShare:
        bundle.localizedString(forKey: mapKey("error_unable_present_documents"))
      case .signDocument:
        bundle.localizedString(forKey: mapKey("sign_document"))
      case .signDocumentSubtitle:
        bundle.localizedString(forKey: mapKey("sign_document_subtitle"))
      case .selectDocument:
        bundle.localizedString(forKey: mapKey("select_document"))
      case .itemNotFoundInStorage:
        bundle.localizedString(forKey: mapKey("item_not_found_in_storage"))
      case .itemsNotFoundInStorage:
        bundle.localizedString(forKey: mapKey("items_not_found_in_storage"))
      case .home:
        bundle.localizedString(forKey: mapKey("home"))
      case .transactions:
        bundle.localizedString(forKey: mapKey("transactions"))
      case .documents:
        bundle.localizedString(forKey: mapKey("documents"))
      case .authenticateAuthoriseTransactions:
        bundle.localizedString(forKey: mapKey("authenticate_authorise_transactions"))
      case .electronicallySignDigitalDocuments:
        bundle.localizedString(forKey: mapKey("electronically_sign_digital_documents"))
      case .learnMore:
        bundle.localizedString(forKey: mapKey("learn_more"))
      case .chooseFromList:
        bundle.localizedString(forKey: mapKey("choose_from_list"))
      case .chooseFromListTitle:
        bundle.localizedString(forKey: mapKey("choose_from_list_title"))
      case .addDocumentsToWallet:
        bundle.localizedString(forKey: mapKey("add_documents_to_wallet"))
      case .details:
        bundle.localizedString(forKey: mapKey("details"))
      case .dataSharingRequest:
        bundle.localizedString(forKey: mapKey("data_sharing_request"))
      case .dataShared:
        bundle.localizedString(forKey: mapKey("data_shared"))
      case .doneButton:
        bundle.localizedString(forKey: mapKey("done_button"))
      case .dataSharingTitle:
        bundle.localizedString(forKey: mapKey("data_sharing_title"))
      case .close:
        bundle.localizedString(forKey: mapKey("close"))
      case .trustedRelyingParty:
        bundle.localizedString(forKey: mapKey("trusted_relying_party"))
      case .trustedRelyingPartyDescription:
        bundle.localizedString(forKey: mapKey("trusted_relying_party_description"))
      case .issuerWantWalletAddition:
        bundle.localizedString(forKey: mapKey("issuer_want_wallet_addition"))
      case .filterByIssuer:
        bundle.localizedString(forKey: mapKey("filter_by_issuer"))
      case .alertAccessOnlineServices:
        bundle.localizedString(forKey: mapKey("alert_access_online_services"))
      case .alertAccessOnlineServicesMessage:
        bundle.localizedString(forKey: mapKey("alert_access_online_services_message"))
      case .alertSignDocumentsSafely:
        bundle.localizedString(forKey: mapKey("alert_sign_documents_safely"))
      case .alertSignDocumentsSafelyMessage:
        bundle.localizedString(forKey: mapKey("alert_sign_documents_safely_message"))
      case .authenticate:
        bundle.localizedString(forKey: mapKey("authenticate"))
      case .inPerson:
        bundle.localizedString(forKey: mapKey("in_person"))
      case .online:
        bundle.localizedString(forKey: mapKey("Online"))
      case .fromDevice:
        bundle.localizedString(forKey: mapKey("from_device"))
      case .autodashboardAuthenticateDialogMessage:
        bundle.localizedString(forKey: mapKey("autodashboard_authenticate_dialog_message"))
      case .deleteButton:
        bundle.localizedString(forKey: mapKey("delete_button"))
      case .savedToFavorites:
        bundle.localizedString(forKey: mapKey("saved_to_favorites"))
      case .succesfullyAddedFollowingToWallet:
        bundle.localizedString(forKey: mapKey("succesfully_added_following_to_wallet"))
      case .removedFromFavorites:
        bundle.localizedString(forKey: mapKey("removed_from_favorites"))
      case .savedToFavoritesMessage:
        bundle.localizedString(forKey: mapKey("saved_to_favorites_message"))
      case .removedFromFavoritesMessages:
        bundle.localizedString(forKey: mapKey("removed_from_favorites_messages"))
      case .scannerQrTitleIssuing:
        bundle.localizedString(forKey: mapKey("scanner_qr_title_issuing"))
      case .scannerQrTitlePresentation:
        bundle.localizedString(forKey: mapKey("scanner_qr_title_presentation"))
      case .scannerQrCaptionIssuing:
        bundle.localizedString(forKey: mapKey("scanner_qr_caption_issuing"))
      case .scannerQrCaptionPresentation:
        bundle.localizedString(forKey: mapKey("scanner_qr_caption_presentation"))
      case .quickPinEnterPin:
        bundle.localizedString(forKey: mapKey("quick_pin_enter_a_pin"))
      case .quickPinConfirmPin:
        bundle.localizedString(forKey: mapKey("quick_pin_confirm_pin"))
      case .biometryConfirmRequest:
        bundle.localizedString(forKey: mapKey("biometry_confirm_request"))
      case .viewDetails(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("view_details"), arguments: args)
      case .requestsTheFollowing:
        bundle.localizedString(forKey: mapKey("requests_the_following"))
      case .walletIsSecured:
        bundle.localizedString(forKey: mapKey("wallet_is_secured"))
      case .noResults:
        bundle.localizedString(forKey: mapKey("no_results"))
      case .noResultsDescription:
        bundle.localizedString(forKey: mapKey("no_results_description"))
      case .proximityConnectionNfcDescription:
        bundle.localizedString(forKey: mapKey("proximity_connection_nfc_description"))
      case .orShareViaNfc:
        bundle.localizedString(forKey: mapKey("or_share_via_nfc"))
      case .filters:
        bundle.localizedString(forKey: mapKey("filters"))
      case .sortByIssuedDateSectionTitle:
        bundle.localizedString(forKey: mapKey("sort_by_issued_date"))
      case .issuerSectionTitle:
        bundle.localizedString(forKey: mapKey("filter_by_issuer"))
      case .showResults:
        bundle.localizedString(forKey: mapKey("show_results"))
      case .reset:
        bundle.localizedString(forKey: mapKey("reset"))
      case .all:
        bundle.localizedString(forKey: mapKey("all"))
      case .descending:
        bundle.localizedString(forKey: mapKey("descending"))
      case .ascending:
        bundle.localizedString(forKey: mapKey("ascending"))
      case .expiryPeriodSectionTitle:
        bundle.localizedString(forKey: mapKey("expiry"))
      case .selectExpiryPeriod:
        bundle.localizedString(forKey: mapKey("expiry_period"))
      case .filterByState:
        bundle.localizedString(forKey: mapKey("filter_by_state"))
      case .sortBy:
        bundle.localizedString(forKey: mapKey("sort_by"))
      case .issuanceSuccessHeaderDescriptionWhenError:
        bundle.localizedString(forKey: mapKey("issuance_success_header_description_when_error"))
      case .deleteDocumentConfirmDialog:
        bundle.localizedString(forKey: mapKey("delete_document_confirm_dialog"))
      case .defaultLabel:
        bundle.localizedString(forKey: mapKey("default"))
      case .valid:
        bundle.localizedString(forKey: mapKey("valid"))
      case .revoke:
        bundle.localizedString(forKey: mapKey("revoke"))
      case .expired:
        bundle.localizedString(forKey: mapKey("expired"))
      case .dateIssued:
        bundle.localizedString(forKey: mapKey("date_issued"))
      case .expiryDate:
        bundle.localizedString(forKey: mapKey("expiry_date"))
      case .nextSevenDays:
        bundle.localizedString(forKey: mapKey("next_seven_days"))
      case .nextThirtyDays:
        bundle.localizedString(forKey: mapKey("next_thirty_days"))
      case .beyondThiryDays:
        bundle.localizedString(forKey: mapKey("beyond_thirty_days"))
      case .beforeToday:
        bundle.localizedString(forKey: mapKey("before_today"))
      case .issuanceRequest:
        bundle.localizedString(forKey: mapKey("issuance_request"))
      case .myEuWallet:
        bundle.localizedString(forKey: mapKey("My EU Wallet"))
      case .categoryGovernment:
        bundle.localizedString(forKey: mapKey("category_government"))
      case .categoryHealth:
        bundle.localizedString(forKey: mapKey("category_health"))
      case .categoryEducation:
        bundle.localizedString(forKey: mapKey("category_education"))
      case .categoryFinance:
        bundle.localizedString(forKey: mapKey("category_finance"))
      case .categoryRetail:
        bundle.localizedString(forKey: mapKey("category_retail"))
      case .categoryOther:
        bundle.localizedString(forKey: mapKey("category_other"))
      case .categorySocialSecurity:
        bundle.localizedString(forKey: mapKey("category_social_security"))
      case .categoryTravel:
        bundle.localizedString(forKey: mapKey("category_travel"))
      case .changelog:
        bundle.localizedString(forKey: mapKey("changelog"))
      case .orderBy:
        bundle.localizedString(forKey: mapKey("order_by"))
      case .filterByCategory:
        bundle.localizedString(forKey: mapKey("filter_by_category"))
      case .searchDocuments:
        bundle.localizedString(forKey: mapKey("search_documents"))
      case .pidPresentationMalformedPresentationTitle:
        bundle.localizedString(forKey: "pid_presentation.malformed_presentation.title")
      case .pidPresentationMalformedPresentationParagraph:
        bundle.localizedString(forKey: "pid_presentation.malformed_presentation.paragraph")
      case .pidPresentationMalformedPresentationPrimButton:
        bundle.localizedString(forKey: "pid_presentation.malformed_presentation.prim_button")
      case .pidPresentationCredentialNotFoundTitle:
        bundle.localizedString(forKey: "eaa_issuance.no_valid_credential.title")
      case .pidPresentationCredentialNotFoundParagraph:
        bundle.localizedString(forKey: "eaa_issuance.no_valid_credential.paragraph")
      case .pidPresentationCredentialNotFoundPrimButton:
        bundle.localizedString(forKey: "global.to_overview_button")
      case .presentationConfirmationTitle:
        bundle.localizedString(forKey: mapKey("presentation_confirmation_title"))
      case .presentationConfirmationDescription1:
        bundle.localizedString(forKey: mapKey("presentation_confirmation_description1"))
      case .presentationConfirmationDescription2:
        bundle.localizedString(forKey: mapKey("presentation_confirmation_description2"))
      case .presentationConfirmationContinueButton:
        bundle.localizedString(forKey: mapKey("presentation_confirmation_continue_button"))
      case .presentationConfirmationCancelButton:
        bundle.localizedString(forKey: mapKey("presentation_confirmation_cancel_button"))
      case .rpConsentTitle:
        bundle.localizedString(forKey: "pid_presentation.data_consent.title")
      case .sendData:
        bundle.localizedString(forKey: mapKey("send_data"))
      case .passwordEntryTitle:
        bundle.localizedString(forKey: mapKey("password_entry_title"))
      case .enterPassword:
        bundle.localizedString(forKey: mapKey("enter_password"))
      case .whatIsPassword:
        bundle.localizedString(forKey: mapKey("what_is_password"))
      case .dataSentSuccessfully:
        bundle.localizedString(forKey: mapKey("data_sent_successfully"))
      case .dataSentSuccessfullyMessage:
        bundle.localizedString(forKey: mapKey("data_sent_successfully_message"))
      case .backToProvider:
        bundle.localizedString(forKey: mapKey("back_to_provider"))
      case .reportProblem:
        bundle.localizedString(forKey: mapKey("report_problem"))
      case .whatIsSecurityPassword:
        bundle.localizedString(forKey: mapKey("what_is_security_password"))
      case .enterSecurityPassword:
        bundle.localizedString(forKey: mapKey("enter_security_password"))
      case .enterYourPassword:
        bundle.localizedString(forKey: mapKey("enter_your_password"))
      case .purpose:
        bundle.localizedString(forKey: mapKey("purpose"))
      case .accountOpening:
        bundle.localizedString(forKey: mapKey("account_opening"))
      case .requiredData:
        bundle.localizedString(forKey: mapKey("required_data"))
      case .onlyFollowingdataWillBeSent:
        bundle.localizedString(forKey: mapKey("only_following_data_will_be_sent"))
      case .personalData:
        bundle.localizedString(forKey: "pid_inspection.pid_details.list_1")
      case .reject:
        bundle.localizedString(forKey: mapKey("reject"))
      case .returnUser:
        bundle.localizedString(forKey: mapKey("return"))
      case .yesReject:
        bundle.localizedString(forKey: mapKey("yes_reject"))
      case .confirmItendificationRefusal:
        bundle.localizedString(forKey: mapKey("confirm_identification_refusal"))
      case .confirmItendificationRefusalMessage:
        bundle.localizedString(forKey: mapKey("confirm_identification_refusal_message"))
      case .whatIsSecurityPasswordMessage:
       bundle.localizedString(forKey: "pid_presentation.sheet_wallet_pin_entry.paragraph")
      case .certificate:
        bundle.localizedString(forKey: mapKey("certificate"))
      case .signature:
        bundle.localizedString(forKey: mapKey("signature"))
      case .issuer:
        bundle.localizedString(forKey: mapKey("issuer"))
      case .country:
        bundle.localizedString(forKey: mapKey("country"))
      case .rpDetails:
        bundle.localizedString(forKey: mapKey("rp_details"))
      case .publisher:
        bundle.localizedString(forKey: mapKey("publisher"))
      case .activity:
        bundle.localizedString(forKey: "pid_inspection.pid_details.list_3")
      case .validInUntil:
        bundle.localizedString(forKey: "pid_inspection.pid_details.label_2")
      case .createdOn:
        bundle.localizedString(forKey: "pid_inspection.pid_details.label_1")
      case .deletePID:
        bundle.localizedString(forKey: mapKey("var-label-delete-card"))
      case .createWithPersonalAusweis(let args):
        bundle.localizedStringWithArguments(forKey: mapKey("var-date-of-creation"), arguments: args)
      case .dashboardCardTitle:
        bundle.localizedString(forKey: mapKey("dashboard_card_title"))
      case .firstName:
        bundle.localizedString(forKey: mapKey("first_name"))
      case .lastName:
        bundle.localizedString(forKey: mapKey("last_name"))
      case .familyName:
        bundle.localizedString(forKey: mapKey("family_name"))
      case .title:
        bundle.localizedString(forKey: mapKey("title"))
      case .nationality:
        bundle.localizedString(forKey: mapKey("nationality"))
      case .dateOfBirth:
        bundle.localizedString(forKey: "pid_inspection.pid_personal_data.label_birth_date")
      case .placeOfBirth:
        bundle.localizedString(forKey: mapKey("place_of_birth"))
      case .issuingCountry:
        bundle.localizedString(forKey: mapKey("issuing_country"))
      case .address:
        bundle.localizedString(forKey: mapKey("address"))
      case .birthYear:
        bundle.localizedString(forKey: mapKey("birth_year"))
      case .ageInYears:
        bundle.localizedString(forKey: mapKey("age_in_years"))
      case .birthFamilyName:
        bundle.localizedString(forKey: mapKey("birth_family_name"))
      case .issuingAuthority:
        bundle.localizedString(forKey: mapKey("issuing_authority"))
      case .ageEqualOrOver:
        bundle.localizedString(forKey: mapKey("age_equal_or_over"))
      case .givenName:
        bundle.localizedString(forKey: mapKey("given_name"))
      case .issuingDate:
        bundle.localizedString(forKey: mapKey("issuing_date"))
      case .distributor:
        bundle.localizedString(forKey: "pid_inspection.pid_details.list_2")
      case .years:
        bundle.localizedString(forKey: mapKey("years"))
      case .name:
        bundle.localizedString(forKey: mapKey("name"))
      case .errorFetchTransactionLog:
        bundle.localizedString(forKey: mapKey("fetch_error_transaction_log"))
      case .parSetupFailed:
        bundle.localizedString(forKey: mapKey("parSetupFailed"))
      case .createdDate:
        bundle.localizedString(forKey: mapKey("label-created-at"))
      case .next:
        bundle.localizedString(forKey: mapKey("next"))
      case .back:
        bundle.localizedString(forKey: mapKey("back"))
      case .showDetails:
        bundle.localizedString(forKey: mapKey("show_details"))
      case .hideDetails:
        bundle.localizedString(forKey: mapKey("hide_details"))
      case .consentViewHeader(let arg1, let arg2, let arg3):
        bundle.localizedStringWithArguments(forKey: "pid_presentation.data_consent.headline_credential", arguments: [arg1, arg2, arg3])
      case .whyIsThisDataNeededTitle:
        bundle.localizedString(forKey: mapKey("why_is_data_needed_title"))
      case .whyIsThisDataNeededDescription:
        bundle.localizedString(forKey: mapKey("why_is_data_needed_description"))
      case .appName:
        bundle.localizedString(forKey: mapKey("app-name"))
      case .cardPinEnteredWrongTwice:
        bundle.localizedString(forKey: mapKey("card_pin_entered_wrong_twice"))
      case .canInfoTitle:
        bundle.localizedString(forKey: mapKey("can_info_title"))
      case .canInfoDesc:
        bundle.localizedString(forKey: mapKey("can_info_desc"))
      case .canEingeben:
        bundle.localizedString(forKey: mapKey("can_eingeben"))
      case .issuanceCanEntryTitle:
        bundle.localizedString(forKey: mapKey("issuance_can_entry_title"))
      case .issuanceErrorWrongCan:
        bundle.localizedString(forKey: mapKey("issuance_error_wrong_can"))
      case .cardPinEnteredWrongDescription:
        bundle.localizedString(forKey: mapKey("card_pin_entered_wrong_description"))
      case .securityCheckAlertTile:
        bundle.localizedString(forKey: mapKey("security_check_title"))
      case .securityCheckAlertDescription:
        bundle.localizedString(forKey: mapKey("app_onboarding.pa_is_set.paragraph"))
      case .securityCheckButtonTitle:
        bundle.localizedString(forKey: mapKey("security_check_button_title"))
      case .issuanceEidPinEntryTitle:
        bundle.localizedString(forKey: mapKey("issuance_eid_pin_entry_title"))
      case .issuanceScanningTitle:
        bundle.localizedString(forKey: mapKey("issuance_scanning_title"))
      case .issuanceButtonKartenPin:
        bundle.localizedString(forKey: mapKey("issuance_button_karten_pin"))
      case .issuanceButtonFindBurgeramt:
        bundle.localizedString(forKey: mapKey("issuance_button_find_burgeramt"))
      case .issuanceEidUnkownParagraph1:
        bundle.localizedString(forKey: mapKey("issuance_eid_unkown_paragraph_1"))
      case .issuanceEidUnkownParagraph2:
        bundle.localizedString(forKey: mapKey("issuance_eid_unkown_paragraph_2"))
      case .issuanceEidUnkownParagraph31:
        bundle.localizedString(forKey: mapKey("issuance_eid_unkown_paragraph_31"))
      case .issuanceEidUnkownParagraph32:
        bundle.localizedString(forKey: mapKey("issuance_eid_unkown_paragraph_32"))
      case .issuanceEidUnkownParagraph33:
        bundle.localizedString(forKey: mapKey("issuance_eid_unkown_paragraph_33"))
      case .issuanceEidUnkownTitle:
        bundle.localizedString(forKey: mapKey("issuance_eid_unkown_title"))
      case .setupPinTitle:
        bundle.localizedString(forKey: mapKey("setup_pin_title"))
      case .setupPinMessage:
        bundle.localizedString(forKey: mapKey("setup_pin_message"))
      case .setupPinPrimaryButtonTitle:
        bundle.localizedString(forKey: mapKey("setup_pin_primary_button_title"))
      case .setupPinSecondaryButtonTitle:
        bundle.localizedString(forKey: mapKey("setup_pin_secondary_button_title"))
      case .setupPinTransportViewTitle:
        bundle.localizedString(forKey: mapKey("setup_pin_transport_view_title"))
      case .setupPinTransportViewMessage:
        bundle.localizedString(forKey: mapKey("setup_pin_transport_view_message"))
      case .setupPinTransportViewPrimaryButtonTitle:
        bundle.localizedString(forKey: mapKey("setup_pin_transport_view_primary_button_title"))
      case .setupPinTransportViewSecondaryButtonTitle:
        bundle.localizedString(forKey: mapKey("setup_pin_transport_view_secondary_button_title"))
      case .setupPinSheetTitle:
        bundle.localizedString(forKey: mapKey("setup_pin_sheet_title"))
      case .setupPinSheetMessage:
        bundle.localizedString(forKey: "eid_setup.sheet_no_letter.paragraph")
      case .setupPinSheetButtonText:
        bundle.localizedString(forKey: "pid_issuance.sheet_eID_PIN_not_set.sec_button")
      case .transportPinViewTitle:
        bundle.localizedString(forKey: mapKey("transport_pin_view_title"))
      case .setupNewPinInstructionViewTitle:
        bundle.localizedString(forKey: mapKey("setup_new_pin_instruction_view_title"))
      case .setupNewPinInstructionViewPrimaryButtonTilte:
        bundle.localizedString(forKey: mapKey("setup_new_pin_instruction_view_primary_button_tilte"))
      case .setupNewPinInstructionViewSecondaryButtonTitle:
        bundle.localizedString(forKey: mapKey("setup_new_pin_instruction_view_secondary_button_title"))
      case .confirmationPinMismatch:
        bundle.localizedString(forKey: mapKey("confirmation_pin_mismatch"))
      case .scanningTips:
        bundle.localizedString(forKey: mapKey("scanning-tips"))
      case .scanningGuidePara1:
        bundle.localizedString(forKey: mapKey("scanning-guide-para1"))
      case .scanningGuidePara2:
        bundle.localizedString(forKey: mapKey("scanning-guide-para2"))
      case .scanningGuidePara3:
        bundle.localizedString(forKey: mapKey("scanning-guide-para3"))
      case .scanningBannerIOS:
        bundle.localizedString(forKey: "nfc_scanning.nfc_tap.banner_iOS")
      case .restartScanning:
        bundle.localizedString(forKey: mapKey("restart-scanning"))
      case .scanningHelpPopupTitle:
        bundle.localizedString(forKey: mapKey("nfc_scanning.sheet_nfc.title"))
      case .scanningHelpPopupDetailPara1:
        bundle.localizedString(forKey: mapKey("nfc_scanning.sheet_nfc.list_1"))
      case .scanningHelpPopupDetailPara2:
        bundle.localizedString(forKey: mapKey("nfc_scanning.sheet_nfc.list_2"))
      case .scanningHelpPopupDetailPara3:
        bundle.localizedString(forKey: mapKey("nfc_scanning.sheet_nfc.list_3"))
      case .scanningHelpCustomerServiceCalling:
        bundle.localizedString(forKey: mapKey("nfc_scanning.sheet_nfc.sec_button"))
      case .scanningCustomerServicePhoneNumber:
        bundle.localizedString(forKey: mapKey("scanning-help-customer-service-phone-number"))
      case .transportPinCorrect:
        bundle.localizedString(forKey: mapKey("transport-pin-correct"))
      case .setNewEidPinOne:
        bundle.localizedString(forKey: "eid_setup.card_pin_setup.title")
      case .setNewEidPinTwo:
        bundle.localizedString(forKey: mapKey("set_new_eid_pin_two"))
      case .tryAgainIn:
        bundle.localizedString(forKey: mapKey("try-again-in"))
      case .walletPinForgotten:
        bundle.localizedString(forKey: mapKey("wallet-pin-forgotten"))
      case .walletPinMultipleWrongEntry:
        bundle.localizedString(forKey: mapKey("wallet-pin-multiple-wrong-entry"))
      case .issuanceOnboardingTitle:
        bundle.localizedString(forKey: mapKey("issuance_onboarding_title"))
      case .issuanceOnboardingMessage:
        bundle.localizedString(forKey: mapKey("issuance_onboarding_message"))
      case .issuanceOnboardingPinInfoViewTitle:
        bundle.localizedString(forKey: mapKey("issuance_onboarding_pin_info_view_title"))
      case .issuanceOnboardingPinInfoViewMessage:
        bundle.localizedString(forKey: mapKey("issuance_onboarding_pin_info_view_message"))
      case .issuanceOnboardingPinInfoViewPrimaryButtonTitle:
        bundle.localizedString(forKey: mapKey("issuance_onboarding_pin_info_view_primary_button_title"))
      case .issuanceOnboardingPinInfoViewSecondaryButtonTitle:
        bundle.localizedString(forKey: mapKey("issuance_onboarding_pin_info_view_secondary_button_title"))
      case .issuanceOnboardingPinInfoViewTertiaryButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.onboarding_eid.tert_button_1")
      case .issuanceOnboardingPinInfoViewHelpButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.onboarding_eid.tert_button_2")
      case .pidNoCardAvailableInfoTitle:
        bundle.localizedString(forKey: "pid_issuance.no_card_available_info.title")
      case .pidNoCardAvailableInfoParagraph:
        bundle.localizedString(forKey: "pid_issuance.no_card_available_info.paragraph")
      case .globalOfficeButton:
        bundle.localizedString(forKey: "global.office_button")
      case .issuanceOnboardingPrimaryButtonTitle:
        bundle.localizedString(forKey: mapKey("issuance_onboarding_primary_button_title"))
      case .pidOnboardingCardsTitle:
        bundle.localizedString(forKey: "pid_issuance.onboarding_cards.title")
      case .pidOnboardingCardsList1:
        bundle.localizedString(forKey: "pid_issuance.onboarding_cards.list_1")
      case .pidOnboardingCardsList2:
        bundle.localizedString(forKey: "pid_issuance.onboarding_cards.list_2")
      case .pidOnboardingCardsPrimButton:
        bundle.localizedString(forKey: "pid_issuance.onboarding_cards.prim_button")
      case .pidOnboardingCardsSecButton:
        bundle.localizedString(forKey: "pid_issuance.onboarding_cards.sec_button")
      case .pidOnboardingCardsTertButton:
        bundle.localizedString(forKey: "pid_issuance.onboarding_cards.tert_button")
      case .pidProcessOverviewTitle:
        bundle.localizedString(forKey: "pid_issuance.process_overview.title")
      case .pidProcessOverviewList1:
        bundle.localizedString(forKey: "pid_issuance.process_overview.list_1")
      case .pidProcessOverviewList2:
        bundle.localizedString(forKey: "pid_issuance.process_overview.list_2")
      case .pidProcessOverviewList3:
        bundle.localizedString(forKey: "pid_issuance.process_overview.list_3")
      case .pidProcessOverviewList4:
        bundle.localizedString(forKey: "pid_issuance.process_overview.list_4")
      case .pidProcessOverviewTertButton:
        bundle.localizedString(forKey: "pid_issuance.process_overview.tert_button")
      case .pidProcessOverviewPrimButton:
        bundle.localizedString(forKey: "pid_issuance.process_overview.prim_button")
      case .pidIDPreviewTitle:
        bundle.localizedString(forKey: "pid_issuance.ID_preview.title")
      case .pidIDPreviewIssuerLabel:
        bundle.localizedString(forKey: "pid_issuance.ID_preview.label")
      case .pidIDPreviewCredentialSubline:
        bundle.localizedString(forKey: "overview.initial_pid_teaser.pid_issuer")
      case .pidIDPreviewIssuerName:
        bundle.localizedString(forKey: "__variable_text.pid_issuer.var_issuer_name")
      case .walletPinSetupBanner:
        bundle.localizedString(forKey: "pid_issuance.wallet_pin_intro.banner")
      case .pidEidFunctionInfoTitle:
        bundle.localizedString(forKey: "pid_issuance.eid_function_info.title")
      case .pidEidFunctionInfoParagraph1:
        bundle.localizedString(forKey: "pid_issuance.eid_function_info.paragraph_1")
      case .pidEidFunctionInfoParagraph2:
        bundle.localizedString(forKey: "pid_issuance.eid_function_info.paragraph_2")
      case .globalCloseHintButton:
        bundle.localizedString(forKey: "global.close_hint_button")
      case .globalCloseButton:
        bundle.localizedString(forKey: "global.close_button")
      case .kartenPinCorrect:
        bundle.localizedString(forKey: mapKey("nfc_scanning.success_error.success_card_pin_title_ios"))
      case .walletPinSetupTitle:
        bundle.localizedString(forKey: mapKey("wallet_pin_setup_title"))
      case .walletPinSetupWarning:
        bundle.localizedString(forKey: mapKey("wallet_pin_setup_warning"))
      case .walletPinSetupPrimaryButtonTitle:
        bundle.localizedString(forKey: mapKey("wallet_pin_setup_primary_button_title"))
      case .setWalletPinTitle:
        bundle.localizedString(forKey: mapKey("set_wallet_pin_title"))
      case .continueTitle:
        bundle.localizedString(forKey: mapKey("continue"))
      case .walletPinSetupConfirmTitle:
        bundle.localizedString(forKey: mapKey("wallet_pin_setup_confirm_title"))
      case .setupWalletPinIncorrectRetypeEntry:
        bundle.localizedString(forKey: mapKey("setup_wallet_pin_incorrect_retype_entry"))
      case .tryAgainInFewMinutes:
        bundle.localizedString(forKey: mapKey("try_again_in_few_minutes"))
      case .serverUnavailable:
        bundle.localizedString(forKey: mapKey("server_unavailable"))
      case .walletPinTryAgainIn:
        bundle.localizedString(forKey: mapKey("wallet-pin-try-again-in"))
      case .walletPinLastTryLeft:
        bundle.localizedString(forKey: mapKey("pid_presentation.retry_counter.warning_paragraph"))
      case .walletPinRetryInfoDetail:
        bundle.localizedString(forKey: "wallet-pin-retry-info-detail")
      case .walletPinWrongEntry:
        bundle.localizedString(forKey: "pid_presentation.wallet_pin_entry.error_wrong_pin")
      case .walletPinForgotPopupDesc:
        bundle.localizedString(forKey: "pid_presentation.retry_counter.counter_overlay_paragraph")
      case .walletResetNow:
        bundle.localizedString(forKey: mapKey("wallet-reset-now"))
      case .deleteEidConfirmationTitle:
        bundle.localizedString(forKey: mapKey("delete_eid_confirmation_title"))
      case .deleteEidConfirmationMessage:
        bundle.localizedString(forKey: mapKey("delete_eid_confirmation_message"))
      case .digitalIdDeleted:
        bundle.localizedString(forKey: mapKey("digital_id_deleted"))
      case .walletPinBlockedMessage:
        bundle.localizedString(forKey: mapKey("wallet_pin_blocked_message"))
      case .toWallet:
        bundle.localizedString(forKey: mapKey("to_wallet"))
      case .dashboardScreenSecondaryText:
        bundle.localizedString(forKey: mapKey("pid_inspection.initial_dashboard.paragraph"))
      case .dashboardPrimaryButtonTitle:
        bundle.localizedString(forKey: mapKey("dashboard_primary_button_title"))
      case .issuanceConsentViewTitle:
        bundle.localizedString(forKey: mapKey("issuance_consent_view_title"))
      case .issuanceDigitalID:
        bundle.localizedString(forKey: mapKey("issuance_digital_id"))
      case .issuanceConsentViewPrimaryButtonTitle:
        bundle.localizedString(forKey: mapKey("issuance_consent_view_primary_button_title"))
      case .issuanceConsentViewSecondaryButtonTitle:
        bundle.localizedString(forKey: mapKey("issuance_consent_view_secondary_button_title"))
      case .issuanceConsentViewShowMoreDataButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.data_consent.toggle_visible_button")
      case .issuanceConsentViewShowLessDataButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.data_consent.toggle_unvisible_button")
      case .issuanceConsentRejectInfoTitle:
        bundle.localizedString(forKey: "pid_issuance.data_consent_reject_info.title")
      case .issuanceConsentRejectInfoParagraph:
        bundle.localizedString(forKey: "pid_issuance.data_consent_reject_info.paragraph")
      case .issuanceConsentRejectInfoPrimaryButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.data_consent_reject_info.prim_button")
      case .email:
        bundle.localizedString(forKey: mapKey("email"))
      case .privacyPolicy:
        bundle.localizedString(forKey: mapKey("privacy_policy"))
      case .certificateValidUntil:
        bundle.localizedString(forKey: mapKey("certificate_valid_until"))
      case .issuedBy:
        bundle.localizedString(forKey: mapKey("issued_by"))
      case .loginTitle:
        // TODO: - Placeholder data
        bundle.localizedString(forKey: mapKey("issued_by"))
      case .loginCaptionQuickPinOnly:
        // TODO: - Placeholder data
        bundle.localizedString(forKey: mapKey("issued_by"))
      case .loginCaption:
        // TODO: - Placeholder data
        bundle.localizedString(forKey: mapKey("issued_by"))
      case .canCorrect:
        bundle.localizedString(forKey: "pid_issuance.can_success.title")
      case .canCorrectDescription:
        bundle.localizedString(forKey: "pid_issuance.can_success.paragraph_1") 
      case .pidIssuanceWalletPinSetupPrimButton:
        bundle.localizedString(forKey: "pid_issuance.wallet_pin_setup.prim_button")
      case .pidIssuanceCanEntryPrimButton:
        bundle.localizedString(forKey: "pid_issuance.can_entry.prim_button")
      case .canCorrectPrimButton:
        bundle.localizedString(forKey: "pid_issuance.can_success.prim_button")
      case .canCorrectSecButton:
        bundle.localizedString(forKey: "pid_issuance.can_success.sec_button")
      case .pidInspectionPidIssuerTitle:
        bundle.localizedString(forKey: "pid_inspection.pid_issuer.title")
      case .pidIssuanceWalletPinReenterPrimButton:
        bundle.localizedString(forKey: "pid_issuance.wallet_pin_reenter.prim_button")
      case .pidIssuanceDataConsentIssuerTitle:
        bundle.localizedString(forKey: "pid_issuance.data_consent_issuer.title")
      case .pidPresentationWalletPinEntryPrimButton:
        bundle.localizedString(forKey: "pid_presentation.wallet_pin_entry.prim_button")
      case .eidSetupCardPinIntroParagraph:
        bundle.localizedString(forKey: "eid_setup.card_pin_intro.paragraph")
      case .cardPinSet:
        bundle.localizedString(forKey: "eid_setup.card_pin_setup.title")
      case .eidSetupCardPinReenterPrimButton:
        bundle.localizedString(forKey: "eid_setup.card_pin_reenter.prim_button")
      case .cardPinSetSuccesfully:
        bundle.localizedString(forKey: "card-pin-set")
      case .pidIssuanceWalletPinReenterSucces:
        bundle.localizedString(forKey: "pid_issuance.wallet_pin_reenter.succes")
      case .pidIssuanceDataConsentLabelAgeEqualOrOverYes:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_age_equal_or_over_yes")
      case .pidIssuanceDataConsentLabelAgeEqualOrOverNo:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_age_equal_or_over_no")
      case .pidInspectionInitialDashboardTempLabel1:
        bundle.localizedString(forKey: "pid_inspection.initial_dashboard.temp_label_1")
      case .pidInspectionInitialDashboardTempLabel2:
        bundle.localizedString(forKey: "pid_inspection.initial_dashboard.temp_label_2")

        // EID Attributes:
      case .eIDAttributeBirthDate:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_birth_date")
      case .eIDAttributeBirthName:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_birth_name")
      case .eIDAttributeFirstNames:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_first_names")
      case .eIDAttributeNationality:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_nationality")
      case .eIDAttributeResidentCity:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_resident_city")
      case .eIDAttributeResidentPostal:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_resident_postal")
      case .eIDAttributeResidentStreet:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_resident_street")
      case .eIDAttributeName:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_name")
      case .eIDAttributeArtistName:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_artist_name")
      case .eIDAttributePlaceOfBirth:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_place_of_birth")
      case .eIDAttributeTitle:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_title")
      case .eIDAttributeAddress:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_address")
      case .eIDAttributeAgeInYears:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_age_in_years")
      case .eIDAttributeAgeBirthYear:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_age_birth_year")
      case .eIDAttributeAgeEqualOrOver:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_age_equal_or_over")
      case .eIDAttributeAgeEqualOrOverYes:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_age_equal_or_over_yes")
      case .eIDAttributeAgeEqualOrOverNo:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_age_equal_or_over_no")
      case .eIDAttributeIssuingCountry:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_issuing_country")
      case .eIDAttributeIssuingAuthority:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_issuing_authority")
      case .eIDAttributeCreatedAt:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_created_at")
      case .eIDAttributeExpireDate:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_expire_date")
      case .eIDAttributeDocumentType:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_document_type")
      case .eIDAttributeCommunityId:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_community_id")
      case .eIDAttributeAuxiliaryConditions:
          bundle.localizedString(forKey: "pid_issuance.data_consent.label_auxiliary_conditions")
      case .eIDAttributeResidentCountry:
        bundle.localizedString(forKey: "pid_issuance.data_consent.label_resident_country")
      
      // MARK: - Error cases
      case .walletRegistrationServiceUnavailableTitle:
        bundle.localizedString(forKey: "app_onboarding.wb_service_unavailable.title")
      case .walletRegistrationServiceUnavailableParagraph:
        bundle.localizedString(forKey: "app_onboarding.wb_service_unavailable.paragraph")
      case .walletRegistrationServiceUnavailablePrimaryButtonTitle:
        bundle.localizedString(forKey: "app_onboarding.wb_service_unavailable.prim_button")
        
      case .walletRegistrationBadRequestTitle:
        bundle.localizedString(forKey: "app_onboarding.wb_bad_request.title")
      case .walletRegistrationBadRequestParagraph:
        bundle.localizedString(forKey: "app_onboarding.wb_bad_request.paragraph")
      case .walletRegistrationBadRequestPrimaryButtonTitle:
        bundle.localizedString(forKey: "app_onboarding.wb_bad_request.prim_button")
        
      case .walletRegistrationInternalErrorTitle:
        bundle.localizedString(forKey: "app_onboarding.wb_internal_error.title")
      case .walletRegistrationInternalErrorParagraph:
        bundle.localizedString(forKey: "app_onboarding.wb_internal_error.paragraph")
      case .walletRegistrationInternalErrorPrimaryButtonTitle:
        bundle.localizedString(forKey: "app_onboarding.wb_internal_error.prim_button")
        
      case .walletRegistrationIntegrityVerificationFailedTitle:
        bundle.localizedString(forKey: "app_onboarding.wb_integrity_verification_failed.title")
      case .walletRegistrationIntegrityVerificationFailedParagraph:
        bundle.localizedString(forKey: "app_onboarding.wb_integrity_verification_failed.paragraph")

      case .rwscdRegistrationServiceUnavailableTitle:
        bundle.localizedString(forKey: "pid_issuance.rwscd_service_unavailable.title")
      case .rwscdRegistrationServiceUnavailableParagraph:
        bundle.localizedString(forKey: "pid_issuance.rwscd_service_unavailable.paragraph")
      case .rwscdRegistrationServiceUnavailablePrimaryButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.rwscd_service_unavailable.prim_button")
        
      case .rwscdRegistrationBadRequestTitle:
        bundle.localizedString(forKey: "pid_issuance.rwscd_bad_request.title")
      case .rwscdRegistrationBadRequestParagraph:
        bundle.localizedString(forKey: "pid_issuance.rwscd_bad_request.paragraph")
      case .rwscdRegistrationBadRequestPrimaryButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.rwscd_bad_request.prim_button")
        
      case .rwscdRegistrationInternalErrorTitle:
        bundle.localizedString(forKey: "pid_issuance.rwscd_internal_error.title")
      case .rwscdRegistrationInternalErrorParagraph:
        bundle.localizedString(forKey: "pid_issuance.rwscd_internal_error.paragraph")
      case .rwscdRegistrationInternalErrorPrimaryButtonTitle:
        bundle.localizedString(forKey: "pid_issuance.rwscd_internal_error.prim_button")
        
      case .walletAttestationAccountUnknownTitle:
        bundle.localizedString(forKey: "pid_presentation.wb_account_unknown.title")
      case .walletAttestationAccountUnknownParagraph:
        bundle.localizedString(forKey: "pid_presentation.wb_account_unknown.paragraph")
      case .walletAttestationAccountUnknownPrimaryButtonTitle:
        bundle.localizedString(forKey: "pid_presentation.wb_account_unknown.prim_button")
        
      case .walletAttestationAuthVerificationFailedTitle:
        bundle.localizedString(forKey: "pid_presentation.wb_auth_verification_failed.title")
      case .walletAttestationAuthVerificationFailedParagraph:
        bundle.localizedString(forKey: "pid_presentation.wb_auth_verification_failed.paragraph")
      case .walletAttestationAuthVerificationFailedPrimaryButtonTitle:
        bundle.localizedString(forKey: "pid_presentation.wb_auth_verification_failed.prim_button")
        
      case .globalErrorTitle:
        bundle.localizedString(forKey: "global.error.title")
      case .globalErrorParagraph:
        bundle.localizedString(forKey: "global.error.paragraph")
      case .globalErrorPrimaryButtonTitle:
        bundle.localizedString(forKey: "global.error.prim_button")
      case .pidPresentationRetryCounterResetOverlayTitle:
        bundle.localizedString(forKey: "pid_presentation.retry_counter.reset_overlay_title")
      case .pidPresentationRetryCounterResetOverlayParagraph:
        bundle.localizedString(forKey: "pid_presentation.retry_counter.reset_overlay_paragraph")
      case .pidPresentationRetryCounterResetOverlayButton:
        bundle.localizedString(forKey: "pid_presentation.retry_counter.reset_overlay_button")
      case .globalMenuItemSettings:
        bundle.localizedString(forKey: "global.menu_item.settings")
      case .globalRetrieveLogs:
        bundle.localizedString(forKey: "global.menu_item.retrieve_logs")
      case .globalErrorWalletRevoked:
        bundle.localizedString(forKey: "global.error.Wallet_revoked")
      case .globalErrorWalletRevokedBody:
        bundle.localizedString(forKey: "global.error.Wallet_revoked_body")
      case .globalErrorWalletRevokedPrimButton:
        bundle.localizedString(forKey: "global.error.Wallet_revoked_prim_button")
        
      case .transactionCodeViewTitle:
        bundle.localizedString(forKey: "trasaction_code_view_title")
      case .transactionCodeViewDescription:
        bundle.localizedString(forKey: "trasaction_code_view_description")
      case .logsDownloadDisclaimer:
        bundle.localizedString(forKey: "menu_item.retrieve_logs.disclaimer")
      case .globalMenu:
        bundle.localizedString(forKey: "global.menu_title")
      case .globalNext:
        bundle.localizedString(forKey: "global.next")

      case .eaaOfferViewTitle:
        bundle.localizedString(forKey: "eaa_issuance.eaa_info.title")
      case .eaaOfferViewSubTitle:
        bundle.localizedString(forKey: "eaa.offer_view.subtitle")
      case .eaaOfferViewTxCodeInfo(let args):
        bundle.localizedStringWithArguments(forKey: "eaa.offer_view.tx_code_info", arguments: args)
      case .eaaOfferViewPrimaryButtonTitle:
        bundle.localizedString(forKey: "eaa_issuance.transaction_code_intro.prim_button")
      case .eaaOfferTransactionCodeViewTitle(let args):
        bundle.localizedStringWithArguments(forKey: "eaa.offer.tx_code.title", arguments: args)
      case .eaaOfferTxCodeInvalidEntry:
        bundle.localizedString(forKey: "eaa_issuance.transaction_code_entry.error_1")
      case .eaaConsentViewTitle:
        bundle.localizedString(forKey: "eaa.consent_view.title")
      case .eaaConsentViewSubTitle:
        bundle.localizedString(forKey: "eaa.consent_view.subtitle")
      case .eaaConsentPrimaryButtonTitle:
        bundle.localizedString(forKey: "eaa.consent.primary_button_title")
      case .eaaConsentCancelPopupTitle:
        bundle.localizedString(forKey: "eaa.consent.cancel_popup.title")
      case .eaaConsentCancelPopupSubTitle:
        bundle.localizedString(forKey: "eaa.consent.cancel_popup.subtitle")
      case .eaaIssuanceDialogCancelTitle:
        bundle.localizedString(forKey: "eaa_issuance.dialog_cancel.title")
      case .eaaIssuanceDialogCancelSubTitle:
        bundle.localizedString(forKey: "eaa_issuance.dialog_cancel.paragraph")
      case .eaaIssuanceDialogCancelPrimButton:
        bundle.localizedString(forKey: "eaa_issuance.dialog_cancel.prim_button")
      case .eaaIssuanceDialogCancelSecButton:
        bundle.localizedString(forKey: "eaa_issuance.dialog_cancel.sec_button")
      case .eaaIssuanceTransactionCodeEntryPrimButton:
        bundle.localizedString(forKey: "eaa_issuance.transaction_code_entry.prim_button")
      case .eaaIssuanceLoadingTitle:
        bundle.localizedString(forKey: "eaa_issuance.loading.title")
      case .eaaIssuanceSuccessTitle:
        bundle.localizedString(forKey: "eaa_issuance.success.title")
      case .eaaIssuanceFailureTitle:
        bundle.localizedString(forKey: "eaa_issuance.credential_not_loaded_ext.title")
      case .eaaIssuanceFailureSubTitle:
        bundle.localizedString(forKey: "eaa_issuance.credential_not_loaded_ext.paragraph")
      case .buttonViewData:
        bundle.localizedString(forKey: "button_view_data")
      case .eaaOfferViewLoadingText:
        bundle.localizedString(forKey: "eaa.offer_view.loading.text")
      case .eaaOfferViewTxCodeFlowInstruction:
        bundle.localizedString(forKey: "eaa_issuance.transaction_code_intro.paragraph")
      case .pidPresentationRetryCounterRouteToOverview:
        bundle.localizedString(forKey: "pid_presentation.retry_counter.route_to_overview")

      case .globalBackButtonA11y:
        bundle.localizedString(forKey: "global.back_button_a11y")
      case .globalCloseButtonA11y:
        bundle.localizedString(forKey: "global.close_button_a11y")
      case .globalShowDigitsButtonA11y:
        bundle.localizedString(forKey: "global.show_digits_button_a11y")
      case .globalHideDigitsButtonA11y:
        bundle.localizedString(forKey: "global.hide_digits_button_a11y")

      case .headerAccessibilityHelp:
        bundle.localizedString(forKey: "header.accessibility.help")
      case .headerAccessibilityProgress(let args):
        bundle.localizedStringWithArguments(forKey: "header.accessibility.progress", arguments: args)
      case .pinAccessibilityFieldLabel:
        bundle.localizedString(forKey: "pin.accessibility.field_label")
      case .pinAccessibilityDigitsEntered(let args):
        bundle.localizedStringWithArguments(forKey: "pin.accessibility.digits_entered", arguments: args)
      case .pinAccessibilityCharactersEntered(let args):
        bundle.localizedStringWithArguments(forKey: "pin.accessibility.characters_entered", arguments: args)

      case .appOnboardingWalletRevocationIntroTitle:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_intro.title")
      case .appOnboardingWalletRevocationIntroPara1:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_intro.para.1")
      case .appOnboardingWalletRevocationIntroPara2:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_intro.para.2")
      case .appOnboardingWalletRevocationIntroPrimButton:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_intro.prim_button")
      case .appOnboardingWalletRevocationSaveKeyTitle:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_save_key.title")
      case .appOnboardingWalletRevocationSaveKeyHeadline1:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_save_key.headline_1")
      case .appOnboardingWalletRevocationSaveKeyCopyButton:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_save_key.button_inital_1")
      case .appOnboardingWalletRevocationSaveKeyCopiedButton:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_save_key.button_activated_1")
      case .appOnboardingWalletRevocationSaveKeyShareButton:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_save_key.button_3")
      case .appOnboardingWalletRevocationSaveKeyCheckboxLabel:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_save_key.checkbox_label")
      case .appOnboardingWalletRevocationSaveKeyPrimButton:
        bundle.localizedString(forKey: "app_onboarding.wallet_revocation_save_key.prim_button")
      case .eaaIssuerInfoTitle:
        bundle.localizedString(forKey: "eaa_issuance.eaa_info_issuer.title")
      }
    }
  }

fileprivate extension Bundle {
  func localizedString(forKey key: String) -> String {
    Bundle.localizedAssetsBundle().localizedString(forKey: key, value: nil, table: nil)
  }
  
  func localizedStringWithArguments(forKey key: String, arguments: [CVarArg]) -> String {
    String(format: Bundle.localizedAssetsBundle().localizedString(forKey: key, value: nil, table: nil), locale: nil, arguments: arguments)
  }
  
  static func localizedAssetsBundle() -> Bundle {
      guard let languageCode = Locale.preferredLanguages.first?.components(separatedBy: "-").first,
            let path = Bundle.assetsBundle.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path) else {
          return Bundle.assetsBundle
      }
      return bundle
  }
}
