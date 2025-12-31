//
//  StatusBarController.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import AppKit

class StatusBarController: NSObject, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var settingsWindow: NSWindow?
    private var settingsViewModel = ComprehensiveSettingsViewModel()

    func showMenuBarItem() {
        print("YabaiPro: ===== STARTING MENU BAR SETUP =====")

        // Check if we have accessibility permission first
        let hasPermission = PermissionsManager.shared.hasAccessibilityPermission
        print("YabaiPro: Has accessibility permission: \(hasPermission)")

        if !hasPermission {
            print("YabaiPro: No permission - requesting it now...")
            PermissionsManager.shared.requestAccessibilityPermission()
            print("YabaiPro: Permission dialog should be showing")
            // Give it a moment for the permission dialog
            Thread.sleep(forTimeInterval: 3.0)
            print("YabaiPro: Continuing after permission dialog")
        } else {
            print("YabaiPro: Permission already granted")
        }

        // Try to create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("YabaiPro: Status item created: \(statusItem != nil)")

        guard let statusItem = statusItem else {
            print("YabaiPro: ERROR - Failed to create status item")
            return
        }

        print("YabaiPro: Status item button: \(statusItem.button != nil)")

        guard let button = statusItem.button else {
            print("YabaiPro: ERROR - Status item has no button")
            return
        }

        // Use a proper SF Symbol icon like other menu bar apps
        if let image = NSImage(systemSymbolName: "rectangle.3.group", accessibilityDescription: "YabaiPro") {
            button.image = image
        } else {
            // Fallback to text if SF Symbol not available
            button.title = "⌘"
        }
        // Add startup indicator to tooltip
        let isFromLaunchAgent = ProcessInfo.processInfo.environment["YABAIPRO_AUTO_LAUNCH"] == "true"
        button.toolTip = "YabaiPro - Click to configure yabai" + (isFromLaunchAgent ? " (Auto-launched)" : "")
        button.action = #selector(self.toggleSettingsWindow)
        button.target = self

        // Set the status bar button reference for transparency management
        SystemTransparencyManager.shared.setStatusBarButton(button)

        print("YabaiPro: Button configured with rectangle icon")
        print("YabaiPro: Action: \(button.action != nil)")
        print("YabaiPro: Target: \(button.target != nil)")

        setupWindow()
        print("YabaiPro: ===== MENU BAR SETUP COMPLETE =====")
    }

    private func setupWindow() {
        let contentView = MainSettingsView()
            .environmentObject(settingsViewModel)

        let hostingController = NSHostingController(rootView: contentView)

        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        settingsWindow?.center()
        settingsWindow?.title = "YabaiPro"
        settingsWindow?.contentViewController = hostingController
        settingsWindow?.isReleasedWhenClosed = false
        settingsWindow?.delegate = self
    }

    @objc func toggleSettingsWindow() {
        print("YabaiPro: Toggle settings window called")

        if settingsWindow == nil {
            setupWindow()
        }

        if let window = settingsWindow {
            if window.isVisible {
                window.close()
                print("YabaiPro: Settings window closed")
            } else {
                // Proper activation sequence for regular macOS app
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                window.makeMain()
                window.makeFirstResponder(window.contentView)

                // Ensure focus after window is shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApp.activate(ignoringOtherApps: true)
                    window.makeKey()
                    window.makeFirstResponder(window.contentView)
                }

                print("YabaiPro: Settings window shown with proper focus")
            }
        }
    }

    // Legacy popover support for backward compatibility
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: SettingsView(viewModel: SettingsViewModel())
        )
    }

    @objc func togglePopover() {
        // For now, show the full settings window instead of popover
        toggleSettingsWindow()
    }
}

// MARK: - Enhanced Status Bar Controller

@objc class EnhancedStatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var currentSpaceLabel: String = "?"
    private var currentWindowTitle: String = ""
    private var layoutMode: String = "bsp"

    // Quick action buttons
    private var spaceButton: NSButton!
    private var layoutButton: NSButton!

    private let commandRunner = YabaiCommandRunner()

    func setupEnhancedStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Create custom view with multiple elements
        let customView = NSView(frame: NSRect(x: 0, y: 0, width: 120, height: 22))

        // Space indicator
        spaceButton = NSButton(title: "1", target: self, action: #selector(spaceClicked))
        spaceButton.frame = NSRect(x: 0, y: 0, width: 25, height: 22)
        spaceButton.bezelStyle = .inline
        spaceButton.font = NSFont.systemFont(ofSize: 12)
        customView.addSubview(spaceButton)

        // Layout indicator
        layoutButton = NSButton(title: "BSP", target: self, action: #selector(layoutClicked))
        layoutButton.frame = NSRect(x: 25, y: 0, width: 35, height: 22)
        layoutButton.bezelStyle = .inline
        layoutButton.font = NSFont.systemFont(ofSize: 10)
        customView.addSubview(layoutButton)

        // Window counter
        let windowLabel = NSTextField(labelWithString: "⊞")
        windowLabel.frame = NSRect(x: 60, y: 0, width: 20, height: 22)
        windowLabel.font = NSFont.systemFont(ofSize: 14)
        customView.addSubview(windowLabel)

        // Settings button
        let settingsButton = NSButton(image: NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings")!,
                                    target: self, action: #selector(showSettings))
        settingsButton.frame = NSRect(x: 80, y: 0, width: 22, height: 22)
        settingsButton.bezelStyle = .inline
        customView.addSubview(settingsButton)

        statusItem.button?.addSubview(customView)

        // Start status updates
        startStatusUpdates()
    }

    @objc func spaceClicked() {
        // Show space switcher
        showSpaceSwitcher()
    }

    @objc func layoutClicked() {
        // Cycle layout modes
        cycleLayout()
    }

    @objc func showSettings() {
        // Show main settings window
        StatusBarController().toggleSettingsWindow()
    }

    func startStatusUpdates() {
        Task {
            while true {
                await updateStatusInfo()
                try await Task.sleep(nanoseconds: 1_000_000_000) // Update every second
            }
        }
    }

    func updateStatusInfo() async {
        do {
            let spaces = try await commandRunner.querySpaces()
            let windows = try await commandRunner.queryWindows()

            // Parse current space and window info
            await MainActor.run {
                updateStatusDisplay(spaces: spaces, windows: windows)
            }
        } catch {
            print("Failed to update status: \(error)")
        }
    }

    func updateStatusDisplay(spaces: Data, windows: Data) {
        // Parse JSON and update status bar
        do {
            let spacesArray = try JSONDecoder().decode([SpaceInfo].self, from: spaces)
            _ = try JSONDecoder().decode([WindowInfo].self, from: windows)

            // Find current space
            if let currentSpace = spacesArray.first(where: { $0.focused == 1 }) {
                currentSpaceLabel = "\(currentSpace.index)"
                layoutMode = currentSpace.type
                spaceButton.title = currentSpaceLabel
                layoutButton.title = layoutMode.uppercased()
            }

            // Count windows in current space (could be used for status display)
            // let windowCount = windowsArray.filter { $0.space == spacesArray.first(where: { $0.focused == 1 })?.index }.count
        } catch {
            print("Failed to parse status data: \(error)")
        }
    }

    func showSpaceSwitcher() {
        // Create a simple space switcher menu
        let menu = NSMenu()

        Task {
            do {
                let spaces = try await commandRunner.querySpaces()
                let spacesArray = try JSONDecoder().decode([SpaceInfo].self, from: spaces)

                for space in spacesArray {
                    let item = NSMenuItem(title: "Space \(space.index)", action: #selector(switchToSpace(_:)), keyEquivalent: "\(space.index)")
                    item.tag = Int(space.index)
                    item.target = self
                    menu.addItem(item)
                }

                menu.addItem(NSMenuItem.separator())
                menu.addItem(NSMenuItem(title: "Create Space", action: #selector(createNewSpace), keyEquivalent: "n"))
                menu.addItem(NSMenuItem(title: "Destroy Current Space", action: #selector(destroyCurrentSpace), keyEquivalent: "d"))

                menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
            } catch {
                print("Failed to show space switcher: \(error)")
            }
        }
    }

    @objc func switchToSpace(_ sender: NSMenuItem) {
        Task {
            try await commandRunner.focusSpace(index: UInt32(sender.tag))
        }
    }

    @objc func createNewSpace() {
        Task {
            _ = try await commandRunner.createSpace()
        }
    }

    @objc func destroyCurrentSpace() {
        Task {
            // This would need to get current space index first
            try await commandRunner.destroySpace(index: 1) // Placeholder
        }
    }

    func cycleLayout() {
        Task {
            do {
                let spaces = try await commandRunner.querySpaces()
                let spacesArray = try JSONDecoder().decode([SpaceInfo].self, from: spaces)

                if let currentSpace = spacesArray.first(where: { $0.focused == 1 }) {
                    let nextLayout: SpaceLayout
                    switch currentSpace.type {
                    case "bsp": nextLayout = .stack
                    case "stack": nextLayout = .float
                    case "float": nextLayout = .bsp
                    default: nextLayout = .bsp
                    }

                    try await commandRunner.setSpaceLayout(index: currentSpace.index, layout: nextLayout)
                }
            } catch {
                print("Failed to cycle layout: \(error)")
            }
        }
    }

    func createQuickActionMenu() -> NSMenu {
        let menu = NSMenu()

        // Space management
        let spaceMenu = NSMenu()
        spaceMenu.addItem(NSMenuItem(title: "Create Space", action: #selector(createNewSpace), keyEquivalent: "n"))
        spaceMenu.addItem(NSMenuItem(title: "Destroy Space", action: #selector(destroyCurrentSpace), keyEquivalent: "d"))
        spaceMenu.addItem(NSMenuItem.separator())

        // Add space switching items dynamically
        Task {
            do {
                let spaces = try await commandRunner.querySpaces()
                let spacesArray = try JSONDecoder().decode([SpaceInfo].self, from: spaces)

                for space in spacesArray {
                    let item = NSMenuItem(title: "Space \(space.index)", action: #selector(switchToSpace(_:)), keyEquivalent: "\(space.index)")
                    item.tag = Int(space.index)
                    item.target = self
                    spaceMenu.addItem(item)
                }
            } catch {
                print("Failed to load spaces for menu: \(error)")
            }
        }

        let spaceMenuItem = NSMenuItem(title: "Spaces", action: nil, keyEquivalent: "")
        spaceMenuItem.submenu = spaceMenu
        menu.addItem(spaceMenuItem)

        // Window management
        let windowMenu = NSMenu()
        windowMenu.addItem(NSMenuItem(title: "Float Window", action: #selector(toggleFloat), keyEquivalent: "f"))
        windowMenu.addItem(NSMenuItem(title: "Fullscreen", action: #selector(toggleFullscreen), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Stack Window", action: #selector(toggleStack), keyEquivalent: "s"))

        let windowMenuItem = NSMenuItem(title: "Windows", action: nil, keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        menu.addItem(windowMenuItem)

        return menu
    }

    @objc func toggleFloat() {
        Task {
            try await commandRunner.toggleWindowFloat()
        }
    }

    @objc func toggleFullscreen() {
        Task {
            try await commandRunner.toggleWindowFullscreen()
        }
    }

    @objc func toggleStack() {
        Task {
            try await commandRunner.toggleWindowStack()
        }
    }
}

// Supporting structs for JSON parsing
struct SpaceInfo: Codable {
    let index: UInt32
    let focused: Int
    let type: String
}

struct WindowInfo: Codable {
    let id: UInt32
    let space: UInt32
}
