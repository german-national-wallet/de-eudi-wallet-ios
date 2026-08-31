//
//  Colors+Extenstion.swift
//  logic-ui
//

//
// This is the only public color API: views use these names, never the generated
// constants in Colors.swift. Names follow the Figma design tokens
// (design-tokens/*.tokens.json) so exports diff cleanly against this file.
// The app currently forces light mode (Application.swift), so every semantic
// color resolves to the light variant.
public extension DesignSystem.Styles.Colors {

  // MARK: PID
  static let colorPID = colorPIDLight
  static let onColorPID = onColorPIDLight
  static let backgroundPIDLight = backgroundPID_lightLight
  static let backgroundPIDMedium = backgroundPID_mediumLight

  // MARK: Status
  static let warning = warningLight
  static let success = successLight
  static let onSuccess = onSuccessLight

  // MARK: Primary
  static let primary = schemesPrimaryLight
  static let onPrimary = schemesOnPrimaryLight
  static let primaryContainer = schemesPrimaryContainer
  static let onPrimaryContainer = schemesOnPrimaryContainer
  static let primaryOutline = schemesPrimaryOutlineLight
  static let inversePrimary = schemesInversePrimaryLight

  // MARK: Secondary
  static let secondary = schemesSecondaryLight
  static let onSecondary = schemesOnSecondaryLight
  static let secondaryContainer = schemesSecondaryContainerLight
  static let onSecondaryContainer = schemesOnSecondaryContainerLight

  // MARK: Tertiary
  static let tertiary = schemesTertiaryLight
  static let onTertiary = schemesOnTertiaryLight
  static let tertiaryContainer = schemesTertiaryContainerLight
  static let onTertiaryContainer = schemesOnTertiaryContainerLight
  static let tertiaryOutline = schemesTertiaryOutlineLight

  // MARK: Error
  static let error = schemesErrorLight
  static let onError = schemesOnErrorLight
  static let errorContainer = schemesErrorContainerLight
  static let onErrorContainer = schemesOnErrorContainerLight
  static let errorOutline = schemesErrorOutlineLight

  // MARK: Background
  static let background = schemesBackgroundLight
  static let onBackground = schemesOnBackgroundLight
  static let onBackgroundVariant = schemesOnBackgroundVariantLight

  // MARK: Surface
  static let surface = schemesSurfaceLight
  static let onSurface = schemesOnSurfaceLight
  static let surfaceVariant = schemesSurfaceVariantLight
  static let onSurfaceVariant = schemesOnSurfaceVariantLight
  static let surfaceTint = schemesSurfaceTintLight
  static let surfaceDim = schemesSurfaceDimLight
  static let surfaceBright = schemesSurfaceBrightLight
  static let surfaceContainerLowest = schemesSurfaceContainerLowestLight
  static let surfaceContainerLow = schemesSurfaceContainerLowLight
  static let surfaceContainer = schemesSurfaceContainerLight
  static let surfaceContainerHigh = schemesSurfaceContainerHighLight
  static let surfaceContainerHighest = schemesSurfaceContainerHighestLight
  static let inverseSurface = schemesInverseSurfaceLight
  static let inverseOnSurface = schemesInverseOnSurfaceLight

  // MARK: Outline & misc
  static let outline = schemesOutlineLight
  static let outlineVariant = schemesOutlineVariantLight
  static let shadow = schemesShadow
  static let scrim = schemesScrim
}
