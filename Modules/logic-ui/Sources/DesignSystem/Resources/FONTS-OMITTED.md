# Fonts are not published

The brand typeface (Diatype) is commercially licensed and cannot be
redistributed, so this directory is empty in the public mirror. See the
"Fonts" section of the repository README.

`CustomFonts.loadFonts()` registers each face by name and `guard let`s on a
missing file, so the app builds and runs without them and falls back to the
system font.

This file is not decoration: `Package.swift` declares
`resources: [.process("DesignSystem/Resources")]`, and Swift Package Manager
only generates the `Bundle.module` accessor for a target that actually has at
least one resource. With the fonts stripped and this directory otherwise
empty, `CustomFonts.swift` fails to compile on `Bundle.module`. Keep a file
here for as long as the fonts are omitted.
