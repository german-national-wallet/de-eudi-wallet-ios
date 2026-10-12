//
//  WalletRevocationSaveKeyState.swift
//  feature-startup
//

import logic_ui

@Copyable
struct WalletRevocationSaveKeyState: ViewState {
  let isSavedElsewhere: Bool
  let isCodeCopied: Bool
}
