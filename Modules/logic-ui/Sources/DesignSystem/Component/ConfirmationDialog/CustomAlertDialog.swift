//
//  CustomAlertDialog.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct CustomAlertDialogConfig: Identifiable {
  public let id: UUID
  public let title: LocalizableStringKey
  public let role: Role
  public let trailingIcon: Image?
  public let isCancel: Bool
  public let action: () -> Void

  public enum Role {
    case primary
    case secondary
    case destructive
    case plain
  }

  public init(
    id: UUID = UUID(),
    title: LocalizableStringKey,
    role: Role,
    trailingIcon: Image? = nil,
    isCancel: Bool = false,
    action: @escaping () -> Void
  ) {
    self.id = id
    self.title = title
    self.role = role
    self.trailingIcon = trailingIcon
    self.isCancel = isCancel
    self.action = action
  }
}

extension Array where Element == CustomAlertDialogConfig {
  var cancelButton: CustomAlertDialogConfig? {
    first { $0.isCancel }
  }

  // The cancel button, or else the last non-destructive one: it is never a destructive action or an external link.
  var initialFocusButton: CustomAlertDialogConfig? {
    cancelButton ?? last { $0.role != .destructive } ?? first
  }
}

enum CustomAlertDialogEscape: Equatable {
  case close
  case runCancel(UUID)
  case ignore

  static func outcome(buttons: [CustomAlertDialogConfig], dismissOnBackgroundTap: Bool) -> Self {
    if dismissOnBackgroundTap {
      return .close
    }
    return buttons.cancelButton.map { .runCancel($0.id) } ?? .ignore
  }
}

enum CustomAlertDialogPresentation {
  case overlay
  case modal
}

final class DeferredDialogAction {
  private var action: (() -> Void)?

  func store(_ action: @escaping () -> Void) {
    self.action = action
  }

  func runOnce() {
    let pending = action
    action = nil
    pending?()
  }
}

struct CustomAlertDialog: View {
  var icon: Image?
  var iconColor: Color = DSColor.onSurface
  var title: String
  var subtitle: String?
  var buttons: [CustomAlertDialogConfig]

  @AccessibilityFocusState private var isTitleFocused: Bool
  @FocusState private var focusedButton: UUID?

  var body: some View {
    VStack(spacing: 20) {

      VStack(spacing: 8) {
        if let icon {
          icon
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
            .foregroundColor(iconColor)
            .padding(.bottom, DSStyle.Spacers.SPACING_SMALL)
            .accessibilityHidden(true)
        }

        Text(title)
          .font(DSTypography.Title.large)
          .foregroundColor(DSColor.onSurface)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
          .accessibilityFocused($isTitleFocused)

        if let subtitle {
          Text(subtitle)
            .font(DSTypography.Body.medium)
            .foregroundColor(DSColor.onSurfaceVariant)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
        ForEach(buttons) { button in
          dialogButton(for: button)
            .focused($focusedButton, equals: button.id)
        }
      }
    }
    .padding(24)
    .frame(maxWidth: 320)
    .background(DSColor.background)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .shadow(radius: 20)
    .accessibilityElement(children: .contain)
    .accessibilityAddTraits(.isModal)
    .defaultFocus($focusedButton, buttons.initialFocusButton?.id)
    .onAppear {
      isTitleFocused = true
    }
  }

  @ViewBuilder
  private func dialogButton(for config: CustomAlertDialogConfig) -> some View {
    switch config.role {
    case .primary:
      DSPrimaryButton(
        title: config.title.toString,
        action: config.action
      )

    case .secondary:
      DSSecondaryButton(
        title: config.title.toString,
        trailingIcon: config.trailingIcon,
        action: config.action
      )

    case .destructive:
      Button(action: config.action) {
        Text(config.title.toString)
          .font(DSTypography.Label.large)
          .fontWeight(DSStyle.FontWeight.medium_500)
          .foregroundColor(DSColor.error)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(
        DSButton.FilledPressedButtonStyle(
          outlineColor: DSColor.errorOutline,
          pressedBackgroundColor: DSColor.errorContainer.opacity(0.6),
          defaultBackgroundColor: DSColor.errorContainer,
          borderWidth: 1
        )
      )

    case .plain:
      DSSecondaryButton(
        title: config.title.toString,
        showsBorder: false,
        backgroundColor: DSColor.background,
        action: config.action
      )
    }
  }
}

struct ScrollIfNeeded<Content: View>: View {
  @ViewBuilder var content: Content

  var body: some View {
    ViewThatFits(in: .vertical) {
      content
      ScrollView {
        content
      }
      .scrollBounceBehavior(.basedOnSize)
    }
  }
}

struct CustomAlertDialogModifier: ViewModifier {
  @Binding var isPresented: Bool

  var icon: Image?
  var iconColor: Color
  var title: String
  var subtitle: String?
  var buttons: [CustomAlertDialogConfig]
  var dismissOnBackgroundTap: Bool
  var presentation: CustomAlertDialogPresentation

  @State private var deferredAction = DeferredDialogAction()
  @State private var isModalVisible = false

  @ViewBuilder
  func body(content: Content) -> some View {
    switch presentation {
    case .overlay:
      overlay(content)
    case .modal:
      modal(content)
    }
  }

  private func overlay(_ content: Content) -> some View {
    ZStack {
      content

      if isPresented {
        Color.black.opacity(0.4)
          .ignoresSafeArea()
          .transition(.opacity)
          .accessibilityHidden(true)
          .onTapGesture {
            if dismissOnBackgroundTap {
              withAnimation {
                isPresented = false
              }
            }
          }

        dialog { action in
          action()
          isPresented = false
        }
        .transition(.scale.combined(with: .opacity))
        .zIndex(1)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: isPresented)
  }

  // A system modal keeps VoiceOver and keyboard focus inside the dialog and returns it to the trigger on close.
  // Button actions run only after the modal is gone, so they can navigate safely.
  private func modal(_ content: Content) -> some View {
    content
      .fullScreenCover(isPresented: $isPresented, onDismiss: deferredAction.runOnce) {
        ZStack {
          Color.black.opacity(0.4)
            .ignoresSafeArea()
            .accessibilityHidden(true)
            .onTapGesture {
              if dismissOnBackgroundTap {
                closeModal(then: {})
              }
            }

          ScrollIfNeeded {
            dialog(onButton: closeModal)
          }
          .padding(DSStyle.Spacers.SPACING_LARGE_MEDIUM)
          .scaleEffect(isModalVisible ? 1 : 0.9)
        }
        .opacity(isModalVisible ? 1 : 0)
        .onAppear {
          withAnimation(.easeInOut(duration: 0.25)) {
            isModalVisible = true
          }
        }
        .onDisappear {
          isModalVisible = false
        }
        .presentationBackground(.clear)
      }
      .transaction(value: isPresented) { transaction in
        transaction.disablesAnimations = true
      }
  }

  private func dialog(onButton: @escaping (@escaping () -> Void) -> Void) -> some View {
    CustomAlertDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      buttons: buttons.map { button in
        CustomAlertDialogConfig(
          id: button.id,
          title: button.title,
          role: button.role,
          trailingIcon: button.trailingIcon,
          isCancel: button.isCancel
        ) {
          onButton(button.action)
        }
      }
    )
    .accessibilityAction(.escape) {
      escape(onButton: onButton)
    }
    .onKeyPress(.escape) {
      escape(onButton: onButton)
      return .handled
    }
  }

  private func escape(onButton: (@escaping () -> Void) -> Void) {
    switch CustomAlertDialogEscape.outcome(buttons: buttons, dismissOnBackgroundTap: dismissOnBackgroundTap) {
    case .close:
      onButton({})
    case .runCancel:
      if let cancel = buttons.cancelButton {
        onButton(cancel.action)
      }
    case .ignore:
      break
    }
  }

  private func closeModal(then action: @escaping () -> Void) {
    deferredAction.store(action)
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      isPresented = false
    }
  }
}

extension View {
  public func centerDialog(
    isPresented: Binding<Bool>,
    icon: Image? = nil,
    iconColor: Color = DSColor.onSurface,
    title: LocalizableStringKey,
    subtitle: LocalizableStringKey? = nil,
    buttons: [CustomAlertDialogConfig],
    dismissOnBackgroundTap: Bool = true
  ) -> some View {
    alertDialog(
      isPresented: isPresented,
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      buttons: buttons,
      dismissOnBackgroundTap: dismissOnBackgroundTap,
      presentation: .overlay
    )
  }

  func alertDialog(
    isPresented: Binding<Bool>,
    icon: Image?,
    iconColor: Color,
    title: LocalizableStringKey,
    subtitle: LocalizableStringKey?,
    buttons: [CustomAlertDialogConfig],
    dismissOnBackgroundTap: Bool,
    presentation: CustomAlertDialogPresentation
  ) -> some View {
    modifier(
      CustomAlertDialogModifier(
        isPresented: isPresented,
        icon: icon,
        iconColor: iconColor,
        title: title.toString,
        subtitle: subtitle?.toString,
        buttons: buttons,
        dismissOnBackgroundTap: dismissOnBackgroundTap,
        presentation: presentation
      )
    )
  }
}
