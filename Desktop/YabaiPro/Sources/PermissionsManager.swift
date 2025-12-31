//
//  PermissionsManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation
import ApplicationServices
import AppKit
import CoreGraphics

class PermissionsManager {
    static let shared = PermissionsManager()

    var hasAccessibilityPermission: Bool {
        // Check without prompting - only returns true/false
        return AXIsProcessTrusted()
    }

    var hasScreenRecordingPermission: Bool {
        // Check if we have screen recording permission
        // This is a bit tricky - we try to create a screenshot and see if it succeeds
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        // If we can get window info, we likely have permission
        return !windowList.isEmpty
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func requestScreenRecordingPermission() {
        // Trigger screen recording permission by attempting to capture screen
        // This will prompt the user for permission
        _ = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }

    func openPrivacySecuritySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy") {
            NSWorkspace.shared.open(url)
        }
    }
}
