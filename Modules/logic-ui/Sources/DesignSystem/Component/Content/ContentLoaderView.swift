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

public struct ContentLoaderView: View {
  private let width: CGFloat
  private let loadingText: String
  private let progress: ProgressState

  public init(
    width: CGFloat = 50,
    loadingText: String = LocalizableStringKey.appName.toString,
    progress: ProgressState = .loading
  ) {
    self.width = width
    self.loadingText = loadingText
    self.progress = progress
  }

  @ViewBuilder
  public var body: some View {
    VStack {
      Spacer()
      ProgressRing(state: progress, size: width)
      HStack {
        Spacer()
        DSTitleLabel(loadingText)
          .padding(.top, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
        Spacer()
      }
      Spacer()
    }
  }
}

#Preview {
  Group {
    ContentLoaderView()
      .lightModePreview()
    ContentLoaderView()
      .darkModePreview()
  }
}
