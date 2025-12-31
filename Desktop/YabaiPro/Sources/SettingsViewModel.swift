//
//  SettingsViewModel.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import Combine

private let scriptingAdditionManager = YabaiScriptingAdditionManager.shared

enum Preset {
    case `default`
    case minimalist
}

// MARK: - Layout Enums

enum LayoutType: String, CaseIterable {
    case bsp, stack, float
}

enum SplitType: String, CaseIterable {
    case vertical, horizontal, auto
}

enum WindowPlacement: String, CaseIterable {
    case first_child, second_child

    var displayName: String {
        switch self {
        case .first_child: return "First Child"
        case .second_child: return "Second Child"
        }
    }
}

struct GlobalPadding {
    let top: Double
    let bottom: Double
    let left: Double
    let right: Double
}

// MARK: - Mouse & Focus Enums

enum FocusMode: String, CaseIterable {
    case off, autofocus, autoraise
}

enum WindowOriginDisplay: String, CaseIterable {
    case `default`, focused, cursor
}

enum MouseModifier: String, CaseIterable {
    case fn, cmd, alt, ctrl, shift
}

enum MouseAction: String, CaseIterable {
    case move, resize
}

enum MouseDropAction: String, CaseIterable {
    case swap, stack
}

enum AnimationEasing: String, CaseIterable {
    case linear, easeIn, easeOut, easeInOut, easeOutCubic, easeInOutCubic

    var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .easeIn: return "Ease In"
        case .easeOut: return "Ease Out"
        case .easeInOut: return "Ease In/Out"
        case .easeOutCubic: return "Ease Out Cubic"
        case .easeInOutCubic: return "Ease In/Out Cubic"
        }
    }
}

class SettingsViewModel: ObservableObject {
    // Aesthetics
    @Published var fadeInactiveWindows = false {
        didSet {
            updateSIPWarning()
            checkScriptingAdditionStatus()
        }
    }
    @Published var inactiveWindowOpacity: Double = 0.9
    private var appliedInactiveWindowOpacity: Double = 0.9
    @Published var disableShadows = false {
        didSet {
            updateSIPWarning()
            checkScriptingAdditionStatus()
        }
    }
    @Published var useSelectiveTransparency = false {
        didSet {
            Task {
                if !useSelectiveTransparency {
                    // Reset to normal mode asynchronously
                    await SystemTransparencyManager.shared.disableSelectiveTransparency()
                }
                updateSIPWarning()
            }
        }
    }
    @Published var menuBarOpacity: Double = 1.0 {
        didSet { updateSIPWarning() }
    }
    @Published var menuBarBackgroundOpacity: Double = 1.0 {
        didSet { updateSIPWarning() }
    }
    @Published var menuBarIconOpacity: Double = 1.0 {
        didSet { updateSIPWarning() }
    }
    @Published var windowGap: Double = 6.0

    // Focus & Behavior
    @Published var focusFollowsMouse = false

    // Layout Configuration
    @Published var layoutType: LayoutType = .bsp
    @Published var splitRatio: Double = 0.5
    @Published var splitType: SplitType = .auto
    @Published var autoBalance: Bool = false
    @Published var windowPlacement: WindowPlacement = .first_child

    // Padding & Spacing
    @Published var globalPadding: GlobalPadding = GlobalPadding(top: 0, bottom: 0, left: 0, right: 0)

    // Mouse & Focus Configuration
    @Published var mouseFollowsFocus: Bool = false
    @Published var focusFollowsMouseMode: FocusMode = .off
    @Published var windowOriginDisplay: WindowOriginDisplay = .default
    @Published var mouseModifier: MouseModifier = .alt
    @Published var mouseAction1: MouseAction = .move
    @Published var mouseAction2: MouseAction = .resize
    @Published var mouseDropAction: MouseDropAction = .swap

    // Window Behavior Configuration
    @Published var windowZoomPersist: Bool = false
    @Published var windowTopmost: Bool = false

    // Animation Configuration
    @Published var windowAnimationDuration: Double = 0.0
    @Published var windowAnimationEasing: AnimationEasing = .easeOutCubic

    // UI State
    @Published var isApplying = false
    @Published var lastStatus: String?
    @Published var showSIPWarning = false
    @Published var hasAccessibilityPermission = false
    @Published var hasScreenRecordingPermission = false
    @Published var scriptingAdditionStatus: String?
    @Published var remotePairingPIN: String?
    @Published var isRemoteServerRunning: Bool = false
    @Published var reachableAddresses: [String] = []
    @Published var currentQRCode: NSImage?

    var hasUnappliedChanges: Bool {
        if fadeInactiveWindows {
            return abs(inactiveWindowOpacity - appliedInactiveWindowOpacity) > 0.01
        }
        return false
    }

    private var cancellables = Set<AnyCancellable>()
    private let configManager = ConfigManager()
    private let commandRunner = YabaiCommandRunner()
    private let permissionsManager = PermissionsManager.shared
    private let remoteAuth = RemoteAuthManager.shared
    private var remoteServer: RemoteServer?

    init() {
        loadCurrentSettings()
        checkPermissions()
        checkScriptingAdditionStatus()
    }

    func applyPreset(_ preset: Preset) {
        switch preset {
        case .default:
            fadeInactiveWindows = false
            disableShadows = false
            menuBarOpacity = 1.0
            windowGap = 6.0
            focusFollowsMouse = false

        case .minimalist:
            fadeInactiveWindows = true
            disableShadows = true
            menuBarOpacity = 0.7
            windowGap = 12.0
            focusFollowsMouse = true
        }
    }

    // MARK: - Remote Pairing

    func startRemoteServerIfNeeded() {
        // Attempt to start server if not running
        if isRemoteServerRunning { return }
        do {
            try RemoteServer.shared.start()
            remoteServer = RemoteServer.shared
            isRemoteServerRunning = true
            updateReachableAddresses()
        } catch {
            isRemoteServerRunning = false
            lastStatus = "Failed to start remote server: \(error.localizedDescription)"
        }
    }

    func startPairing() {
        // Ensure server is running
        startRemoteServerIfNeeded()
        // Generate PIN via auth manager
        let pin = remoteAuth.generatePIN()
        Task { @MainActor in
            remotePairingPIN = pin
            updateReachableAddresses()
        }
    }

    func stopRemoteServer() {
        remoteServer?.stop()
        remoteServer = nil
        isRemoteServerRunning = false
    }

    func applyChanges() {
        // Check permissions first
        if !permissionsManager.hasAccessibilityPermission {
            permissionsManager.requestAccessibilityPermission()
            return
        }

        isApplying = true
        lastStatus = "Applying changes..."

        Task {
            do {
                // Apply aesthetics
                try await applyAestheticSettings()

                // Apply focus settings
                try await applyFocusSettings()

                // Apply advanced configuration
                try await applyLayoutSettings()
                try await applyPaddingSettings()
                try await applyMouseSettings()
                try await applyWindowBehaviorSettings()
                try await applyAnimationSettings()

                // Update config file
                try await updateConfigFile()

                // Apply menu bar background transparency if enabled
                if useSelectiveTransparency {
                    await SystemTransparencyManager.shared.applySelectiveTransparency(
                        backgroundAlpha: CGFloat(menuBarBackgroundOpacity),
                        iconAlpha: 1.0  // Always keep our icon fully visible
                    )
                }

                await MainActor.run {
                    lastStatus = "Changes applied successfully at \(Date.now.formatted(date: .omitted, time: .shortened))"
                    isApplying = false
                }
            } catch {
                await MainActor.run {
                    lastStatus = "Error: \(error.localizedDescription)"
                    isApplying = false
                }
            }
        }
    }

    private func applyAestheticSettings() async throws {
        // Check if scripting addition is needed for window features
        let needsScriptingAddition = fadeInactiveWindows || disableShadows

        if needsScriptingAddition {
            print("SettingsViewModel: Window features enabled, ensuring scripting addition is loaded...")

            // Check SIP status first
            if !(await scriptingAdditionManager.isSIPDisabled()) {
                await MainActor.run {
                    lastStatus = "❌ SIP must be disabled for window appearance features"
                }
                throw ScriptingAdditionError.sipEnabled
            }

            // Ensure scripting addition is loaded
            do {
                try await scriptingAdditionManager.ensureScriptingAdditionLoaded()
                await MainActor.run {
                    lastStatus = "✅ Ready"
                    checkScriptingAdditionStatus() // Update status display
                }
            } catch {
                await MainActor.run {
                    lastStatus = "❌ Failed to load scripting addition: \(error.localizedDescription)"
                    checkScriptingAdditionStatus() // Update status display
                }
                throw error
            }
        }

        // Window opacity
        if fadeInactiveWindows {
            let opacityCommand = "yabai -m config window_opacity on && yabai -m config normal_window_opacity \(inactiveWindowOpacity)"
            try await commandRunner.run(command: opacityCommand)
            print("SettingsViewModel: Enabled window opacity at \(inactiveWindowOpacity)")
            await MainActor.run {
                appliedInactiveWindowOpacity = inactiveWindowOpacity
                lastStatus = "Set inactive window opacity to \(String(format: "%.1f", inactiveWindowOpacity))"
            }
        } else {
            let opacityCommand = "yabai -m config window_opacity off"
            try await commandRunner.run(command: opacityCommand)
            print("SettingsViewModel: Disabled window opacity")
            await MainActor.run {
                appliedInactiveWindowOpacity = 0.0
                lastStatus = "Disabled window opacity"
            }
        }

        // Window shadows
        if disableShadows {
            let shadowCommand = "yabai -m config window_shadow off"
            try await commandRunner.run(command: shadowCommand)
            print("SettingsViewModel: Disabled window shadows")
        } else {
            let shadowCommand = "yabai -m config window_shadow on"
            try await commandRunner.run(command: shadowCommand)
            print("SettingsViewModel: Enabled window shadows")
        }

        // Menu bar opacity - use selective or standard approach
        if useSelectiveTransparency {
            // Selective transparency will be applied later in applyChanges()
        } else {
            try await commandRunner.run(command: "yabai -m config menubar_opacity \(menuBarOpacity)")
        }

        // Window gap
        try await commandRunner.run(command: "yabai -m config window_gap \(Int(windowGap))")
    }

    private func applyFocusSettings() async throws {
        let focusCommand = focusFollowsMouse ?
            "yabai -m config focus_follows_mouse autoraise" :
            "yabai -m config focus_follows_mouse off"
        try await commandRunner.run(command: focusCommand)
    }

    // MARK: - Layout Configuration

    func applyLayoutSettings() async throws {
        try await commandRunner.setConfig("layout", value: layoutType.rawValue)
        try await commandRunner.setConfig("split_ratio", value: String(format: "%.2f", splitRatio))
        try await commandRunner.setConfig("split_type", value: splitType.rawValue)
        try await commandRunner.setConfig("auto_balance", value: autoBalance ? "on" : "off")
        try await commandRunner.setConfig("window_placement", value: windowPlacement.rawValue)
    }

    func applyPaddingSettings() async throws {
        try await commandRunner.setConfig("top_padding", value: String(Int(globalPadding.top)))
        try await commandRunner.setConfig("bottom_padding", value: String(Int(globalPadding.bottom)))
        try await commandRunner.setConfig("left_padding", value: String(Int(globalPadding.left)))
        try await commandRunner.setConfig("right_padding", value: String(Int(globalPadding.right)))
        // windowGap is already handled in applyAestheticSettings
    }

    func applyMouseSettings() async throws {
        try await commandRunner.setConfig("mouse_follows_focus", value: mouseFollowsFocus ? "on" : "off")
        try await commandRunner.setConfig("focus_follows_mouse", value: focusFollowsMouseMode.rawValue)
        try await commandRunner.setConfig("window_origin_display", value: windowOriginDisplay.rawValue)
        try await commandRunner.setConfig("mouse_modifier", value: mouseModifier.rawValue)
        try await commandRunner.setConfig("mouse_action1", value: mouseAction1.rawValue)
        try await commandRunner.setConfig("mouse_action2", value: mouseAction2.rawValue)
        try await commandRunner.setConfig("mouse_drop_action", value: mouseDropAction.rawValue)
    }

    func applyWindowBehaviorSettings() async throws {
        try await commandRunner.setConfig("window_zoom_persist", value: windowZoomPersist ? "on" : "off")
        try await commandRunner.setConfig("window_topmost", value: windowTopmost ? "on" : "off")
    }

    func applyAnimationSettings() async throws {
        try await commandRunner.setConfig("window_animation_duration", value: String(format: "%.1f", windowAnimationDuration))
        try await commandRunner.setConfig("window_animation_easing", value: windowAnimationEasing.rawValue)
    }

    private func updateConfigFile() async throws {
        var updates: [String: String] = [:]
        updates["window_opacity"] = fadeInactiveWindows ? "on" : "off"
        updates["normal_window_opacity"] = String(format: "%.2f", fadeInactiveWindows ? inactiveWindowOpacity : 0.0)
        updates["window_shadow"] = disableShadows ? "off" : "on"

        // Save transparency settings - selective transparency not supported in yabai v7.1.16
        updates["menubar_opacity"] = String(format: "%.1f", menuBarOpacity)

        updates["window_gap"] = "\(Int(windowGap))"
        updates["focus_follows_mouse"] = focusFollowsMouse ? "autoraise" : "off"

        // Layout settings
        updates["layout"] = layoutType.rawValue
        updates["split_ratio"] = String(format: "%.2f", splitRatio)
        updates["split_type"] = splitType.rawValue
        updates["auto_balance"] = autoBalance ? "on" : "off"
        updates["window_placement"] = windowPlacement.rawValue

        // Padding settings
        updates["top_padding"] = String(Int(globalPadding.top))
        updates["bottom_padding"] = String(Int(globalPadding.bottom))
        updates["left_padding"] = String(Int(globalPadding.left))
        updates["right_padding"] = String(Int(globalPadding.right))

        // Mouse settings
        updates["mouse_follows_focus"] = mouseFollowsFocus ? "on" : "off"
        updates["focus_follows_mouse"] = focusFollowsMouseMode.rawValue
        updates["window_origin_display"] = windowOriginDisplay.rawValue
        updates["mouse_modifier"] = mouseModifier.rawValue
        updates["mouse_action1"] = mouseAction1.rawValue
        updates["mouse_action2"] = mouseAction2.rawValue
        updates["mouse_drop_action"] = mouseDropAction.rawValue

        // Window behavior settings
        updates["window_zoom_persist"] = windowZoomPersist ? "on" : "off"
        updates["window_topmost"] = windowTopmost ? "on" : "off"

        // Animation settings
        updates["window_animation_duration"] = String(format: "%.1f", windowAnimationDuration)
        updates["window_animation_easing"] = windowAnimationEasing.rawValue

        try await configManager.updateSettings(updates)
    }

    private func loadCurrentSettings() {
        Task {
            do {
                let config = try await configManager.readConfig()

                await MainActor.run {
                    fadeInactiveWindows = config["window_opacity"] == "on"
                    inactiveWindowOpacity = Double(config["normal_window_opacity"] ?? "0.90") ?? 0.90
                    appliedInactiveWindowOpacity = inactiveWindowOpacity
                    disableShadows = config["window_shadow"] == "off"
                    // Selective transparency not supported in yabai v7.1.16
                    useSelectiveTransparency = false
                    menuBarOpacity = Double(config["menubar_opacity"] ?? "1.0") ?? 1.0
                    menuBarBackgroundOpacity = 1.0
                    menuBarIconOpacity = 1.0
                    windowGap = Double(config["window_gap"] ?? "6") ?? 6.0
                    focusFollowsMouse = config["focus_follows_mouse"] == "autoraise"

                    // Load layout settings
                    layoutType = LayoutType(rawValue: config["layout"] ?? "bsp") ?? .bsp
                    splitRatio = Double(config["split_ratio"] ?? "0.5") ?? 0.5
                    splitType = SplitType(rawValue: config["split_type"] ?? "auto") ?? .auto
                    autoBalance = config["auto_balance"] == "on"
                    windowPlacement = WindowPlacement(rawValue: config["window_placement"] ?? "first_child") ?? .first_child

                    // Load padding settings
                    let topPad = Double(config["top_padding"] ?? "0") ?? 0
                    let bottomPad = Double(config["bottom_padding"] ?? "0") ?? 0
                    let leftPad = Double(config["left_padding"] ?? "0") ?? 0
                    let rightPad = Double(config["right_padding"] ?? "0") ?? 0
                    globalPadding = GlobalPadding(top: topPad, bottom: bottomPad, left: leftPad, right: rightPad)

                    // Load mouse settings
                    mouseFollowsFocus = config["mouse_follows_focus"] == "on"
                    focusFollowsMouseMode = FocusMode(rawValue: config["focus_follows_mouse"] ?? "off") ?? .off
                    windowOriginDisplay = WindowOriginDisplay(rawValue: config["window_origin_display"] ?? "default") ?? .default
                    mouseModifier = MouseModifier(rawValue: config["mouse_modifier"] ?? "alt") ?? .alt
                    mouseAction1 = MouseAction(rawValue: config["mouse_action1"] ?? "move") ?? .move
                    mouseAction2 = MouseAction(rawValue: config["mouse_action2"] ?? "resize") ?? .resize
                    mouseDropAction = MouseDropAction(rawValue: config["mouse_drop_action"] ?? "swap") ?? .swap

                    // Load window behavior settings
                    windowZoomPersist = config["window_zoom_persist"] == "on"
                    windowTopmost = config["window_topmost"] == "on"

                    // Load animation settings
                    windowAnimationDuration = Double(config["window_animation_duration"] ?? "0.0") ?? 0.0
                    windowAnimationEasing = AnimationEasing(rawValue: config["window_animation_easing"] ?? "easeOutCubic") ?? .easeOutCubic
                }
            } catch {
                // If we can't read config, use defaults
                print("Could not load current settings: \(error)")
            }
        }
    }

    private func updateSIPWarning() {
        Task {
            let sipDisabled = await scriptingAdditionManager.isSIPDisabled()
            _ = await scriptingAdditionManager.isScriptingAdditionLoaded()

            await MainActor.run {
                // Only show warnings if there are actual issues
                let needsSIPDisabled = fadeInactiveWindows || disableShadows
                _ = fadeInactiveWindows || disableShadows

                // Show SIP warning only if SIP is enabled AND user wants features that need it disabled
                showSIPWarning = !sipDisabled && needsSIPDisabled
            }
        }
    }

    private func checkPermissions() {
        hasAccessibilityPermission = permissionsManager.hasAccessibilityPermission
        hasScreenRecordingPermission = permissionsManager.hasScreenRecordingPermission
    }

    private func checkScriptingAdditionStatus() {
        Task {
            let sipDisabled = await scriptingAdditionManager.isSIPDisabled()
            _ = await scriptingAdditionManager.isScriptingAdditionLoaded()

            await MainActor.run {
                // Only show status when there are window features enabled or issues
                let hasWindowFeatures = fadeInactiveWindows || disableShadows

                if !sipDisabled && hasWindowFeatures {
                    scriptingAdditionStatus = "❌ SIP enabled - window features unavailable"
                } else if hasWindowFeatures {
                    scriptingAdditionStatus = "✅ Ready"
                } else {
                    // Don't show status when no window features are enabled
                    scriptingAdditionStatus = nil
                }
            }
        }
    }

    func openAccessibilitySettings() {
        permissionsManager.openAccessibilitySettings()
    }

    func updateReachableAddresses() {
        Task { @MainActor in
            guard let server = RemoteServer.shared as RemoteServer? else { return }
            let ips = server.reachableIPAddresses()
            let port = server.port
            reachableAddresses = ips.map { "http://\($0):\(port)" }
            // generate QR for first address if available
            if let first = reachableAddresses.first {
                currentQRCode = generateQRCode(from: first)
            } else {
                currentQRCode = nil
            }
        }
    }

    private func generateQRCode(from string: String) -> NSImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("Q", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaled = ciImage.transformed(by: transform)
        let rep = NSCIImageRep(ciImage: scaled)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}
