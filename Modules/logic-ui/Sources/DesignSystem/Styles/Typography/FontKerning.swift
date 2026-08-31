//
//  FontKerning.swift
//  DesignSystem
//

import Foundation

/// Kerning values used in the Design System for consistent character spacing across text styles.
///
/// These values define the space between characters (`kerning`) for different font weights or styles.
/// Apply them using the `.kerning(...)` modifier in SwiftUI.
///
/// Example usage:
/// ```swift
/// Text("Hello, World!")
///     .kerning(DesignSystem.Styles.FontKerning.regular)
/// ```
///
/// - Note: The values are in points (CGFloat).
public extension DesignSystem.Styles.FontKerning {
    
    /// Standard kerning for regular text.
    static let regular: CGFloat = 0.5

    /// Slightly wider kerning, used for medium-weight or subheadline text.
    static let medium: CGFloat = 1.0

    /// Extra kerning, typically for headings or heavy display text.
    static let heavy: CGFloat = 1.5
}
