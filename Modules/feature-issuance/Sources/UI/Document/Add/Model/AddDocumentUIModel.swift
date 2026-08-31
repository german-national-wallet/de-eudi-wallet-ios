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
import logic_resources
import logic_core
import logic_ui

public struct AddDocumentUIModel: Identifiable, Sendable, Equatable {

  public let id: String
  public let listItem: ListItemData
  public let configId: String
  public var isEnabled: Bool
  public var isLoading: Bool
  public let docType: String?
  public let vct: String?
  public let format: String
  public let alias: String

  public init(
    listItem: ListItemData,
    isEnabled: Bool,
    isLoading: Bool = false,
    configId: String,
    docType: String? = nil,
    vct: String? = nil,
    format: String,
    alias: String
  ) {
    self.id = UUID().uuidString
    self.isEnabled = isEnabled
    self.listItem = listItem
    self.isLoading = isLoading
    self.configId = configId
    self.docType = docType
    self.vct = vct
    self.format = format
    self.alias = alias
  }
}

public extension AddDocumentUIModel {
  static var mocks: [AddDocumentUIModel] {
    [
      .init(
        listItem: .init(mainText: .custom("Document name 1")),
        isEnabled: true,
        isLoading: true,
        configId: "id",
        format: "vc+sd-jwt",
        alias: "SD Jwt"
      ),
      .init(
        listItem: .init(mainText: .custom("Document name 2")),
        isEnabled: true,
        isLoading: true,
        configId: "id",
        format: "vc+sd-jwt",
        alias: "SD Jwt"
      ),
      .init(
        listItem: .init(mainText: .custom("Document name 3")),
        isEnabled: true,
        isLoading: true,
        configId: "id",
        format: "vc+sd-jwt",
        alias: "SD Jwt"
      ),
      .init(
        listItem: .init(mainText: .custom("Document name 4")),
        isEnabled: true,
        isLoading: true,
        configId: "id",
        format: "vc+sd-jwt",
        alias: "SD Jwt"
      )
    ]
  }
}
