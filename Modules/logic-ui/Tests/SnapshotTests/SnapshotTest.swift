//
//  SnapshotTest.swift
//  logic-ui
//
//  Created by Ahrer Arnold (ahrer@youniqx.com) on 02.02.26.
//

import Foundation
import XCTest
import SnapshotTesting
import SwiftUI

/// Class for snapshot testing.
/// Provides utilities for snapshot comparison, and skipping tests if needed.
@MainActor
class SnapshotTest: XCTestCase {
    
    enum Mode: CustomStringConvertible {
        case light
        case dark
        
        var description: String {
            switch self {
            case .light:
                return "light"
            case .dark:
                return "dark"
            }
        }
    }
    
    // Flag for snapshot recording. Modify if needed.
    private var isRecording: Bool = false
    
    // Flag for skipping tests. Modify if needed.
    private var shouldSkipTests: Bool = false
    
    var isLandscape: Bool = false
    
    /// Compares a snapshot of a given view with a stored snapshot.
    /// - Parameters:
    ///     - view: The view to snapshot.
    ///     - name: The name of the test case. Defaults to the calling function's name.
    ///     - mode: The UI mode (light or dark).
    func assertScreenSnapshot(matching view: some View, testName name: String = #function, mode: Mode = .light) {
        guard !shouldSkipTests else {
            print("Test \(name) skipped.")
            return
        }
        
        let hostingController = UIHostingController(rootView: view)
        if self.isLandscape {
            hostingController.view.frame = CGRect(x: 0,
                                                  y: 0,
                                                  width: UIScreen.main.bounds.height,
                                                  height: UIScreen.main.bounds.width)
        } else {
            hostingController.view.frame = UIScreen.main.bounds
        }
        let language = self.currentLanguage
        let viewport = "\(Int(hostingController.view.frame.width))x\(Int(hostingController.view.frame.height))"
        
        let snapshotName =
        "\(Swift.type(of: self))_\(viewport)_\(name)-\(mode.description)-\(language)".lowercased()
        
        assertSnapshot(of: hostingController,
                       as: .image,
                       record: isRecording,
                       testName: snapshotName)
    }
    
    private var currentLanguage: String {
        let lang = Locale.preferredLanguages.first?.lowercased()
        return lang?.contains("de") == true ? "de" : "en"
    }
}
