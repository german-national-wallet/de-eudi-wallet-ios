//
//  IOSDesignSystem.swift
//  IOSDesignSystem
//

import Foundation

/// `DesignSystem` serves as a centralized namespace for organizing foundational styles
/// and UI components within the design system. It follows a structured approach to
/// keep global variables and elements well-organized and accessible via dot notation.
///
/// Usage Example:
/// ```swift
/// let primaryColor = DesignSystem.Styles.Colors.primary
/// let customButton = DesignSystem.Components.CustomButton()
/// ```
public struct DesignSystem {
  
  /// `Styles` encapsulates fundamental design elements like colors, typography, spacing, etc.
  /// These foundational elements are used throughout the design system to maintain consistency.
  public struct Styles {
    
    /// `Colors` defines the standard color palette for the design system.
    /// Example usage:
    /// ```swift
    /// let primaryColor = DesignSystem.Styles.Colors.primary
    /// ```
    public struct Colors {}
    
    /// `Typography` defines the standard fonts palette for the design system.
    /// Example usage:
    /// ```swift
    /// let body = DesignSystem.Styles.Typography.body
    /// ```
    public struct Typography {}
    
    /// `Spacers` defines the standard spacing for the design system.
    /// Example usage:
    /// ```swift
    /// VSpacer.large()
    /// ```
    public struct Spacers {}
    
    /// `FontWeight` defines the weights for the fonts in design system.
    /// Example usage:
    /// ```swift
    /// .fontWeight(DSStyle.FontWeight.regular_400)
    /// ```
    public struct FontWeight {}
    
    /// `FontKerning` defines the kerning (character spacing) values used across the design system.
    ///
    /// Example usage:
    /// ```swift
    /// Text("Hello")
    ///     .kerning(DSStyle.FontKerning.tight)
    /// ```
    ///
    /// Use these values to ensure consistent letter spacing throughout the app.
    public struct FontKerning {}
    
    /// `Sizes` defines commonly used size constants in the Design System,
    /// such as heights, paddings, and icon dimensions.
    ///
    /// Example usage:
    /// ```swift
    /// .frame(height: DSStyle.Sizes.buttonHeight)
    /// ```
    public struct Sizes {}
    
    /// `LineLimits` defines commonly used line limits constants in the Design System,
    /// used for limiting the number of lines in a view.
    ///
    /// Example usage:
    /// ```swift
    /// .lineLimit(LineLimits.unlimited)
    /// ```
    public struct LineLimits {}

    /// `Shadow` defines standard drop-shadow tokens for the design system.
    ///
    /// Example usage:
    /// ```swift
    /// someView.dsShadow(DSShadow.card)
    /// ```
    public struct Shadow {}

  }
  
  /// `Components` contains reusable UI elements that are built using
  /// foundational styles. These components ensure consistency across the app.
  /// Example usage:
  /// ```swift
  /// let customButton = DesignSystem.Components.CustomButton()
  /// ```
  public struct Components {
    public struct Buttons {}
    public struct Toggles {}
    public struct Labels {}
  }
}
