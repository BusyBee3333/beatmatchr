//
//  SystemTransparencyManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import AppKit

class WindowOverlayManager {
    static let shared = WindowOverlayManager()

    private var overlayWindows: [UInt32: NSWindow] = [:]
    private var animationHostingControllers: [UInt32: NSHostingController<WindowAnimationOverlay>] = [:]

    func showAnimationOverlay(for windowId: UInt32, state: WindowAnimationState, settings: AnimationSettings) {
        print("🎨 Creating overlay for window \(windowId) at \(state.frame)")
        // Remove existing overlay for this window if it exists
        hideAnimationOverlay(for: windowId)

        guard settings.metalEffectsEnabled && MetalAnimationEngine.shared.isMetalAvailable else {
            print("⚠️ Metal not available or disabled for window \(windowId)")
            return
        }

        // Create overlay window
        let overlayWindow = NSWindow(
            contentRect: NSRect(origin: .zero, size: state.frame.size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.level = .floating
        overlayWindow.ignoresMouseEvents = true
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .transient]

        // Position overlay over the actual window
        overlayWindow.setFrameOrigin(NSPoint(x: state.frame.origin.x, y: state.frame.origin.y))

        // Create animation view
        let animationView = WindowAnimationOverlay(state: state, settings: settings, globalTime: WindowAnimationManager.shared.globalAnimationTime)
        let hostingController = NSHostingController(rootView: animationView)

        overlayWindow.contentViewController = hostingController

        // Store references
        overlayWindows[windowId] = overlayWindow
        animationHostingControllers[windowId] = hostingController

        // Show overlay
        overlayWindow.makeKeyAndOrderFront(nil)
    }

    func updateAnimationOverlay(for windowId: UInt32, state: WindowAnimationState, settings: AnimationSettings) {
        if let overlayWindow = overlayWindows[windowId],
           let hostingController = animationHostingControllers[windowId] {

            // Update window position and size
            overlayWindow.setFrame(NSRect(origin: NSPoint(x: state.frame.origin.x, y: state.frame.origin.y),
                                        size: state.frame.size), display: false)

            // Update animation view
            let animationView = WindowAnimationOverlay(state: state, settings: settings, globalTime: WindowAnimationManager.shared.globalAnimationTime)
            hostingController.rootView = animationView

        } else if settings.metalEffectsEnabled && MetalAnimationEngine.shared.isMetalAvailable {
            // Create overlay if it doesn't exist
            showAnimationOverlay(for: windowId, state: state, settings: settings)
        }
    }

    func hideAnimationOverlay(for windowId: UInt32) {
        if let overlayWindow = overlayWindows[windowId] {
            overlayWindow.close()
            overlayWindows.removeValue(forKey: windowId)
            animationHostingControllers.removeValue(forKey: windowId)
        }
    }

    func hideAllAnimationOverlays() {
        for windowId in overlayWindows.keys {
            hideAnimationOverlay(for: windowId)
        }
    }
}

class SystemTransparencyManager {
    static let shared = SystemTransparencyManager()

    // Removed - overlay windows caused crashes
    private var isSelectiveMode = false
    private weak var statusBarButton: NSButton?

    func setStatusBarButton(_ button: NSButton) {
        self.statusBarButton = button
    }

    func applySelectiveTransparency(backgroundAlpha: CGFloat, iconAlpha: CGFloat = 1.0) async {
        print("SystemTransparencyManager: Applying menu bar transparency: \(backgroundAlpha)")

        // Only use yabai's menubar_opacity which actually works
        await setYabaiMenuBarOpacity(backgroundAlpha)

        // Apply icon opacity to our own status bar button only
        await MainActor.run {
            self.statusBarButton?.alphaValue = iconAlpha
        }

        isSelectiveMode = (backgroundAlpha < 1.0)
    }

    func disableSelectiveTransparency() async {
        print("SystemTransparencyManager: Disabling selective transparency")

        // Reset our icon opacity to fully visible
        await MainActor.run {
            self.statusBarButton?.alphaValue = 1.0
        }

        // Reset to normal yabai control
        await resetYabaiMenuBar()

        isSelectiveMode = false
    }

    // Removed - no longer needed after simplification

    private func setYabaiMenuBarOpacity(_ alpha: CGFloat) async {
        await withCheckedContinuation { continuation in
            let command = "yabai -m config menubar_opacity \(alpha)"
            print("SystemTransparencyManager: Running yabai command: \(command)")

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]

            process.terminationHandler = { process in
                print("SystemTransparencyManager: Yabai command completed with code: \(process.terminationStatus)")
                continuation.resume()
            }

            do {
                try process.run()
            } catch {
                print("SystemTransparencyManager: Failed to run yabai command: \(error)")
                continuation.resume()
            }
        }
    }

    // Removed - system-wide icon transparency doesn't work with current macOS limitations

    // Removed - overlay windows caused crashes

    // Removed - no longer needed after simplification

    private func resetYabaiMenuBar() async {
        // Reset to yabai's default behavior
        await setYabaiMenuBarOpacity(1.0)
    }

    // Removed - no longer needed after simplification

    // Utility method to check if selective mode is active
    var selectiveModeActive: Bool {
        return isSelectiveMode
    }
}
