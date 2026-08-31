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
    action: @escaping () -> Void
  ) {
    self.id = id
    self.title = title
    self.role = role
    self.trailingIcon = trailingIcon
    self.action = action
  }
}

struct CustomAlertDialog: View {
  var icon: Image?
  var title: String
  var subtitle: String
  var buttons: [CustomAlertDialogConfig]

  var body: some View {
    VStack(spacing: 20) {

      VStack(spacing: 8) {
        if let icon {
          icon
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
            .foregroundColor(DSColor.onSurface)
            .padding(.bottom, DSStyle.Spacers.SPACING_SMALL)
            .accessibilityHidden(true)
        }

        Text(title)
          .font(DSTypography.Title.large)
          .foregroundColor(DSColor.onSurface)
          .multilineTextAlignment(.center)

        Text(subtitle)
          .font(DSTypography.Body.medium)
          .foregroundColor(DSColor.onSurfaceVariant)
          .multilineTextAlignment(.center)
      }

      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
        ForEach(buttons) { button in
          dialogButton(for: button)
        }
      }
    }
    .padding(24)
    .frame(maxWidth: 320)
    .background(DSColor.background)
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .shadow(radius: 20)
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

struct CustomAlertDialogModifier: ViewModifier {
  @Binding var isPresented: Bool

  var icon: Image?
  var title: String
  var subtitle: String
  var buttons: [CustomAlertDialogConfig]

  func body(content: Content) -> some View {
    ZStack {
      content

      if isPresented {
        // Dimmed Background
        Color.black.opacity(0.4)
          .ignoresSafeArea()
          .transition(.opacity)
          .onTapGesture {
            withAnimation {
              isPresented = false
            }
          }

        CustomAlertDialog(
          icon: icon,
          title: title,
          subtitle: subtitle,
          buttons: wrappedButtons()
        )
        .transition(.scale.combined(with: .opacity))
        .zIndex(1)
      }
    }
    .animation(.easeInOut(duration: 0.25), value: isPresented)
  }

  private func wrappedButtons() -> [CustomAlertDialogConfig] {
    buttons.map { button in
      CustomAlertDialogConfig(
        title: button.title,
        role: button.role,
        trailingIcon: button.trailingIcon
      ) {
        button.action()
        isPresented = false
      }
    }
  }
}

extension View {
  public func centerDialog(
    isPresented: Binding<Bool>,
    icon: Image? = nil,
    title: LocalizableStringKey,
    subtitle: LocalizableStringKey,
    buttons: [CustomAlertDialogConfig]
  ) -> some View {
    self.modifier(
      CustomAlertDialogModifier(
        isPresented: isPresented,
        icon: icon,
        title: title.toString,
        subtitle: subtitle.toString,
        buttons: buttons
      )
    )
  }
}
