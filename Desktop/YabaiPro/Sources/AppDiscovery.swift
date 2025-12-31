//
//  AppDiscovery.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation
import AppKit

/// Represents a discovered application that can be used for signal filtering
struct DiscoveredApp: Identifiable, Hashable, Equatable {
    let id: String  // bundleIdentifier or generated ID
    let displayName: String
    let bundleIdentifier: String?
    let isRunning: Bool

    static func == (lhs: DiscoveredApp, rhs: DiscoveredApp) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Provider for discovering applications on the system
class AppDiscovery {
    static let shared = AppDiscovery()

    private init() {}

    /// Get all currently running applications
    func getRunningApps() -> [DiscoveredApp] {
        let runningApps = NSWorkspace.shared.runningApplications

        return runningApps
            .filter { $0.activationPolicy == .regular } // Only user-facing apps
            .map { app in
                DiscoveredApp(
                    id: app.bundleIdentifier ?? app.localizedName ?? UUID().uuidString,
                    displayName: app.localizedName ?? "Unknown App",
                    bundleIdentifier: app.bundleIdentifier,
                    isRunning: true
                )
            }
            .sorted { $0.displayName < $1.displayName }
    }

    /// Get all running applications plus common system apps
    func getAllDiscoverableApps() -> [DiscoveredApp] {
        var apps = getRunningApps()

        // Add common system apps that might not be running
        let commonApps = [
            ("com.apple.Safari", "Safari"),
            ("com.google.Chrome", "Google Chrome"),
            ("com.apple.Terminal", "Terminal"),
            ("com.apple.finder", "Finder"),
            ("com.apple.TextEdit", "TextEdit"),
            ("com.apple.Preview", "Preview"),
            ("com.apple.Mail", "Mail"),
            ("com.apple.Notes", "Notes"),
            ("com.apple.Calculator", "Calculator"),
            ("com.apple.Dictionary", "Dictionary"),
            ("com.apple.SystemPreferences", "System Preferences"),
            ("com.apple.ActivityMonitor", "Activity Monitor"),
            ("com.apple.Console", "Console"),
            ("com.apple.DiskUtility", "Disk Utility")
        ]

        for (bundleId, displayName) in commonApps {
            // Only add if not already in running apps
            if !apps.contains(where: { $0.bundleIdentifier == bundleId }) {
                apps.append(DiscoveredApp(
                    id: bundleId,
                    displayName: displayName,
                    bundleIdentifier: bundleId,
                    isRunning: false
                ))
            }
        }

        return apps.sorted { $0.displayName < $1.displayName }
    }

    /// Launch an application if it's not running
    func launchApp(_ app: DiscoveredApp) async throws {
        guard !app.isRunning, let bundleId = app.bundleIdentifier else {
            return
        }

        let workspace = NSWorkspace.shared
        try await workspace.openApplication(at: URL(fileURLWithPath: "/Applications/\(app.displayName).app"),
                                          configuration: NSWorkspace.OpenConfiguration())
    }

    /// Check if an application is currently running
    func isAppRunning(_ bundleIdentifier: String) -> Bool {
        return NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleIdentifier
        }
    }
}
