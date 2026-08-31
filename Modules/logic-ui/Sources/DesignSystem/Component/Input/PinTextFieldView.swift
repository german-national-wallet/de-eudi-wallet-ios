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

public struct PinTextFieldView: View {

  public enum EntryMode {
    case numeric
    case alphanumeric
  }

  // MARK: - Properties
  private let maxDigits: Int
  private let isSecureEntry: Binding<Bool>
  private let showsSecureEntryToggle: Bool
  private let errorMessage: String?
  private let entryMode: EntryMode

  @State private var stateForDigit: [FieldState]
  @State private var currentIndex: Int = 0
  @State private var isOnScreen = false

  // MARK: - Observables
  @Binding private var numericText: String
  @Binding private var canFocus: Bool

  @FocusState private var focused: Bool

  private let borderWidth: CGFloat = 1
  private let focusedBorderWidth: CGFloat = 2

  private var activeIndex: Int {
    return currentIndex - 1
  }

  private var computeDotsSize: (width: CGFloat, height: CGFloat) {
    (
      width: 32.0 / UIScreen.main.zoomFactor,
      height: 44.0 / UIScreen.main.zoomFactor
    )
  }

  private var entryProgressKey: LocalizableStringKey {
    let counts = ["\(numericText.count)", "\(maxDigits)"]
    return switch entryMode {
    case .numeric: .pinAccessibilityDigitsEntered(counts)
    case .alphanumeric: .pinAccessibilityCharactersEntered(counts)
    }
  }

  private var toggleIconSize: CGFloat {
    computeDotsSize.height - DSStyle.Spacers.SPACING_MEDIUM
  }

  private var currentToggleIconSize: CGFloat {
    let onCanvas: CGFloat = 24
    let offCanvas: CGFloat = 20
    return isSecureEntry.wrappedValue
    ? toggleIconSize
    : toggleIconSize * (offCanvas / onCanvas)
  }

  private var toggleWidth: CGFloat {
    showsSecureEntryToggle ? computeDotsSize.height + DSStyle.Spacers.SPACING_MEDIUM_SMALL : .zero
  }

  private var boxesPerRow: Int {
    let available = getScreenRect().width - DSStyle.Spacers.SPACING_MEDIUM_LARGE * 2 - toggleWidth
    let fitting = Int((available + DSStyle.Spacers.SPACING_MEDIUM_SMALL) / (computeDotsSize.width + DSStyle.Spacers.SPACING_MEDIUM_SMALL))
    return min(maxDigits, max(1, fitting))
  }

  private var rowRanges: [Range<Int>] {
    guard maxDigits > 0 else { return [] }

    let rowCount = Int((Double(maxDigits) / Double(boxesPerRow)).rounded(.up))
    let base = maxDigits / rowCount
    let remainder = maxDigits % rowCount

    var ranges: [Range<Int>] = []
    var start = 0
    for row in 0..<rowCount {
      let count = row < remainder ? base + 1 : base
      ranges.append(start..<(start + count))
      start += count
    }
    return ranges
  }

  public init(
    numericText: Binding<String>,
    maxDigits: Int,
    isSecureEntry: Binding<Bool> = .constant(true),
    canFocus: Binding<Bool> = .constant(true),
    showsSecureEntryToggle: Bool = false,
    errorMessage: String? = nil,
    entryMode: EntryMode = .numeric
  ) {
    self._numericText = numericText
    self._canFocus = canFocus
    self.maxDigits = maxDigits
    self.isSecureEntry = isSecureEntry
    self.showsSecureEntryToggle = showsSecureEntryToggle
    self.errorMessage = errorMessage
    self.entryMode = entryMode

    self.stateForDigit = Array(repeating: FieldState.inactive, count: maxDigits)
  }

  public var body: some View {
    VStack(spacing: 15) {
      HStack(spacing: .zero) {
        pinDots
          .accessibilityHidden(true)
          .overlay { backgroundField }

        secureEntryToggle
      }
      .frame(maxWidth: .infinity)
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM_LARGE)

      if let errorMessage, !errorMessage.isEmpty {
        errorLabel(errorMessage)
      }
    }
    .onChange(of: errorMessage) { message in
      guard let message, !message.isEmpty else { return }
      UIAccessibility.post(notification: .announcement, argument: message)
    }
  }

  private var pinDots: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
      ForEach(rowRanges, id: \.lowerBound) { row in
        HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
          ForEach(row, id: \.self) { index in
            digitBox(
              isFilled: index < numericText.count,
              isFocusedBox: index == currentIndex && focused
            )
            .frame(width: computeDotsSize.width, height: computeDotsSize.height)
            .overlay(createMainComponent(input: getEachDigit(at: index)))
          }
        }
      }
    }
  }

  @ViewBuilder
  private var secureEntryToggle: some View {
    let minimumTouchTarget: CGFloat = 44
    if showsSecureEntryToggle {
      Button(
        action: { isSecureEntry.wrappedValue.toggle() },
        label: {
          (isSecureEntry.wrappedValue ? Theme.shared.image.eyeIcon : Theme.shared.image.eyeIconOff)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: currentToggleIconSize, height: currentToggleIconSize)
            .foregroundColor(DSColor.onSurface)
            .frame(width: computeDotsSize.height, height: computeDotsSize.height)
            .background(
              Circle()
                .fill(DSColor.tertiaryContainer)
                .overlay(
                  Circle()
                    .stroke(DSColor.tertiaryOutline, lineWidth: 1)
                )
            )
            .frame(minWidth: minimumTouchTarget, minHeight: minimumTouchTarget)
        }
      )
      .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM_SMALL)
      .accessibilityIdentifier("pinSecureEntryToggle")
      .accessibilityLabel(
        Text(
          isSecureEntry.wrappedValue
          ? LocalizableStringKey.globalShowDigitsButtonA11y.toLocalizedStringKey
          : LocalizableStringKey.globalHideDigitsButtonA11y.toLocalizedStringKey
        )
      )
    }
  }

  private func errorLabel(_ message: String) -> some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      // Template rendered on purpose: the bundled `info-circle` carries its own colours, and its
      // light variant is white, so it stays invisible until it takes the error colour.
      Theme.shared.image.infoCircleImage
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: DSStyle.Sizes.Icons.small, height: DSStyle.Sizes.Icons.small)
        .foregroundColor(DSColor.error)

      Text(message)
        .font(DSTypography.Label.large)
        .foregroundStyle(DSColor.error)
        .multilineTextAlignment(.leading)
    }
    .frame(width: entryRowWidth, alignment: .leading)
  }

  /// Width the entry row occupies, which is narrower than the space it is centred in.
  private var entryRowWidth: CGFloat {
    let columns = CGFloat(rowRanges.first?.count ?? maxDigits)
    var width = columns * computeDotsSize.width
      + max(columns - 1, 0) * DSStyle.Spacers.SPACING_MEDIUM_SMALL

    if showsSecureEntryToggle {
      let minimumTouchTarget: CGFloat = DSStyle.Sizes.Icons.xxLarge
      width += DSStyle.Spacers.SPACING_MEDIUM_SMALL + max(computeDotsSize.height, minimumTouchTarget)
    }

    return width
  }

  private func digitBox(isFilled: Bool, isFocusedBox: Bool) -> some View {
    RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.small)
      .fill(isFilled ? DSColor.primaryContainer : DSColor.tertiaryContainer)
      .overlay(
        RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.small)
          .strokeBorder(
            isFocusedBox ? DSColor.primaryOutline : DSColor.tertiaryOutline,
            lineWidth: isFocusedBox ? focusedBorderWidth : borderWidth
          )
          .opacity(isFilled ? 0 : 1)
      )
  }

  @ViewBuilder
  private func createMainComponent(input: String) -> some View {

    let size = computeDotsSize.width / 3

    if input.isEmpty {
      EmptyView()
    } else if isSecureEntry.wrappedValue {
      Theme.shared.image.circle
        .resizable()
        .frame(width: size, height: size, alignment: .center)
        .foregroundColor(DSColor.onPrimaryContainer)
    } else {
      Text(input)
        .font(DSStyle.Typography.Title.large)
        .foregroundColor(DSColor.onPrimaryContainer)
    }
  }

  private var backgroundField: some View {
    let boundPin = Binding<String>(get: { self.numericText }, set: { newValue in
      self.numericText = newValue
      self.currentIndex = newValue.count > maxDigits ? maxDigits : newValue.count
      self.submitPin()
    })

    return TextField(
      "",
      text: boundPin,
      onEditingChanged: { isEditing in
        if isEditing, self.stateForDigit[safe: numericText.count] != nil {
          self.stateForDigit[numericText.count] = .active
        }
      },
      onCommit: {
        submitPin()
        stateForDigit = Array(repeating: FieldState.inactive, count: maxDigits)
      }
    )
    .onChange(of: numericText, perform: { numericText in
      for index in (0..<maxDigits) {
        self.stateForDigit[index] = numericText.count == index  ? .active : .inactive
      }
    })
    .accentColor(.clear)
    .foregroundColor(.clear)
    .keyboardType(entryMode == .numeric ? .numberPad : .asciiCapable)
    .textInputAutocapitalization(entryMode == .numeric ? .never : .characters)
    .autocorrectionDisabled()
    .focused($focused)
    .accessibilityIdentifier("pinTextView")
    .accessibilityLabel(Text(LocalizableStringKey.pinAccessibilityFieldLabel.toLocalizedStringKey))
    .accessibilityValue(Text(entryProgressKey.toLocalizedStringKey))
    .onAppearDelayed {
      // Applied unconditionally and guarded here instead of through `.if(canFocus)`: a
      // conditional modifier changes the view's identity, so the text field was rebuilt on every
      // submit, and the rebuild re-ran this delayed focus.
      guard self.isOnScreen, self.canFocus else { return }
      self.focused = true
    }
    .onChange(of: canFocus) { canFocus in
      self.focused = canFocus
    }
    .onAppear { self.isOnScreen = true }
    .onDisappear {
      self.isOnScreen = false
      self.focused = false
    }
  }

  private func submitPin() {
    guard !numericText.isEmpty else {
      return
    }

    if numericText.count > maxDigits {
      numericText = String(numericText.prefix(maxDigits))
      submitPin()
    }
  }

  private func getEachDigit(at index: Int) -> String {
    switch entryMode {
    case .numeric:
      guard index < numericText.digits.count else { return "" }
      return self.numericText.digits[index].numberString
    case .alphanumeric:
      guard index < numericText.count else { return "" }
      return String(self.numericText[numericText.index(numericText.startIndex, offsetBy: index)])
    }
  }
}

private extension String {

  var digits: [Int] {
    var result = [Int]()
    for char in self {
      if let number = Int(String(char)) {
        result.append(number)
      }
    }
    return result
  }
}

private extension Int {

  var numberString: String {
    guard self < 10 else { return "0" }
    return String(self)
  }
}

extension PinTextFieldView {
  enum FieldState {
    case inactive
    case active

    var color: Color {
      return switch self {
      case .inactive:
        Theme.shared.color.outlineVariant
      case .active:
        Theme.shared.color.primary
      }
    }
  }
}

struct PinTextFieldViewPreview: View {
  @State private var numerText = ""

  var body: some View {
    VStack(alignment: .center) {
      PinTextFieldView(
        numericText: $numerText,
        maxDigits: 6,
        isSecureEntry: .constant(true)
      )

      PinTextFieldView(
        numericText: $numerText,
        maxDigits: 6,
        isSecureEntry: .constant(true)
      )

      PinTextFieldView(
        numericText: $numerText,
        maxDigits: 6,
        isSecureEntry: .constant(true),
        errorMessage: "The code you entered is not correct."
      )
    }
    .padding()
  }
}

#Preview {
  Group {
    PinTextFieldViewPreview().lightModePreview()
    PinTextFieldViewPreview().darkModePreview()
  }
}
