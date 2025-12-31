//
//  YabaiProApp.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import AppKit
import Metal

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: MainWindowController?
    var remoteServer: RemoteServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Log Metal capabilities on startup
        logMetalCapabilities()

        // Initialize animation manager (starts monitoring windows)
        _ = WindowAnimationManager.shared

        // Initialize hover magnification manager (starts mouse tracking)
        _ = HoverMagnificationManager.shared

        // Create and show the main application window
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow()
        // Start remote server for iPhone companion (binds to network interfaces)
        do {
            try RemoteServer.shared.start()
            remoteServer = RemoteServer.shared
        } catch {
            print("Failed to start RemoteServer: \(error)")
        }
    }

    private func logMetalCapabilities() {
        print("🚀 YabaiPro Metal Capabilities:")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        guard let device = MTLCreateSystemDefaultDevice() else {
            print("❌ No Metal device available")
            return
        }

        print("📱 GPU: \(device.name)")

        #if os(macOS)
        if #available(macOS 13.0, *) {
            let hasMetal3 = device.supportsFamily(.apple7) ||
                           device.supportsFamily(.apple8) ||
                           device.supportsFamily(.apple9)

            if hasMetal3 {
                print("🎯 Metal 3: ✅ Supported")
                print("   └── Advanced GPU features available")
            } else {
                print("🎯 Metal 3: ❌ Not Supported")
            }
        } else {
            print("🎯 Metal 3: ❌ macOS < 13.0")
        }
        #endif

        let metalEngine = MetalAnimationEngine.shared
        _ = metalEngine.metalDevice // Trigger lazy initialization

        print("🎨 Enhanced Rendering: \(metalEngine.supportsAdvancedFeatures ? "✅ Available" : "⚠️ Limited")")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

}

@main
struct YabaiProApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene - AppDelegate handles the main window
        Settings {
            EmptyView()
        }
    }
}
