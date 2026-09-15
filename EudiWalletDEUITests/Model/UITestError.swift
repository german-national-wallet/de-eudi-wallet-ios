//
//  UITestError.swift
//  IDGo
//
//  Created by Tamas Dancsi  on 06.03.26.
//

import Foundation

struct UITestError: LocalizedError {
  let message: String
  var errorDescription: String? { message }
}
