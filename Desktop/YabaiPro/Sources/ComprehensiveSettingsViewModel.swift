//
//  ComprehensiveSettingsViewModel.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Supporting Enums
// Enums are defined in SettingsViewModel.swift to avoid duplication

typealias SettingsFocusMode = FocusMode
typealias SettingsWindowOriginDisplay = WindowOriginDisplay
typealias SettingsWindowPlacement = WindowPlacement
typealias SettingsSplitType = SplitType
typealias SettingsMouseModifier = MouseModifier
typealias SettingsMouseAction = MouseAction
typealias SettingsMouseDropAction = MouseDropAction
typealias SettingsLayoutType = LayoutType
typealias SettingsAnimationEasing = AnimationEasing

enum AnimationPreset: String, CaseIterable, Identifiable {
    case minimal, liquid, rich
    var id: Self { self }

    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .liquid: return "Liquid"
        case .rich: return "Rich"
        }
    }

    var settings: AnimationSettings {
        switch self {
        case .minimal:
            return AnimationSettings(
                metalEffectsEnabled: false,
                particleCount: 0,
                rippleCount: 0,
                morphingEnabled: false,
                gradientsEnabled: false,
                frameRateLimit: 30,
                qualityScale: 0.5
            )
        case .liquid:
            return AnimationSettings(
                metalEffectsEnabled: true,
                particleCount: 12,
                rippleCount: 2,
                morphingEnabled: false,
                gradientsEnabled: true,
                frameRateLimit: 60,
                qualityScale: 0.8
            )
        case .rich:
            return AnimationSettings(
                metalEffectsEnabled: true,
                particleCount: 20,
                rippleCount: 4,
                morphingEnabled: true,
                gradientsEnabled: true,
                frameRateLimit: 60,
                qualityScale: 1.0
            )
        }
    }
}

enum AnimationPerformanceMode: String, CaseIterable, Identifiable {
    case auto, ultra, high, medium, low, minimal
    var id: Self { self }

    var displayName: String {
        switch self {
        case .auto: return "Auto (Recommended)"
        case .ultra: return "Ultra"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .minimal: return "Minimal"
        }
    }
}

typealias SettingsAnimationPerformanceMode = AnimationPerformanceMode

enum SettingsCategory: String, CaseIterable, Identifiable {
    case global, windows, spaces, displays, rules, signals, presets
    var id: Self { self }
}

// MARK: - Main ViewModel

class ComprehensiveSettingsViewModel: ObservableObject {
    static let shared = ComprehensiveSettingsViewModel()

    // MARK: - Global Settings
    @Published var mouseFollowsFocus = false
    @Published var focusFollowsMouse: SettingsFocusMode = .off
    @Published var windowOriginDisplay: SettingsWindowOriginDisplay = .default
    @Published var windowPlacement: SettingsWindowPlacement = .first_child
    @Published var windowZoomPersist = false
    @Published var windowTopmost = false
    @Published var splitRatio: Double = 0.5
    @Published var splitType: SettingsSplitType = .auto
    @Published var autoBalance = false
    @Published var mouseModifier: SettingsMouseModifier = .alt
    @Published var mouseAction1: SettingsMouseAction = .move
    @Published var mouseAction2: SettingsMouseAction = .resize
    @Published var mouseDropAction: SettingsMouseDropAction = .swap

    // MARK: - Window Aesthetics
    @Published var windowOpacity = false
    @Published var windowOpacityDuration: Double = 0.0
    @Published var activeWindowOpacity: Double = 1.0
    @Published var normalWindowOpacity: Double = 1.0
    @Published var windowShadow = true
    @Published var windowMagnification = false
    @Published var windowMagnificationFactor: Double = 1.0
    @Published var windowMagnificationDuration: Double = 0.0

    // MARK: - Hover Magnification
    @Published var hoverMagnification = false
    @Published var hoverMagnificationFactor: Double = 1.1
    @Published var hoverMagnificationDuration: Double = 0.3
    @Published var hoverMagnificationDelay: Double = 0.2

    // MARK: - Trackpad Gestures (for TrackpadGestureManager)
    @Published var twoFingerResizeEnabled = false
    @Published var resizeSensitivity: Double = 1.0
    @Published var gestureHapticFeedbackEnabled = true
    @Published var windowBorder = false
    @Published var windowBorderWidth: Double = 1.0
    @Published var windowBorderRadius: Double = 0.0
    @Published var windowBorderBlur = false
    @Published var activeWindowBorderColor: Color = .blue
    @Published var normalWindowBorderColor: Color = .gray
    @Published var insertFeedbackColor: Color = .green

    // MARK: - Layout Settings
    @Published var layout: SettingsLayoutType = .bsp
    @Published var topPadding: Double = 0
    @Published var bottomPadding: Double = 0
    @Published var leftPadding: Double = 0
    @Published var rightPadding: Double = 0
    @Published var windowGap: Double = 6
    @Published var windowAnimationDuration: Double = 0.0
    @Published var windowAnimationEasing: SettingsAnimationEasing = .easeOutCubic

    // MARK: - Metal Animations (Beta)
    @Published var metalAnimationsEnabled = false
    @Published var directWindowMetalEnabled = false
    @Published var animationPreset: AnimationPreset = .minimal
    @Published var animationPerformanceMode: SettingsAnimationPerformanceMode = .auto

    // MARK: - Menu Bar (SIP Required)
    @Published var menuBarOpacity: Double = 1.0

    // MARK: - Rules & Signals Management
    @Published var rules: [YabaiRule] = []
    @Published var signals: [YabaiSignal] = []
    @Published var customPresets: [PresetConfig] = []

    // MARK: - UI State
    @Published var isApplying = false
    @Published var isPreviewing = false
    @Published var lastStatus: String?
    @Published var showSIPWarning = false
    @Published var scriptingAdditionStatus: String?
    @Published var hasAccessibilityPermission = false
    @Published var hasScreenRecordingPermission = false
    @Published var activeCategory: SettingsCategory = .global
    @Published var useStructuredSignalEditor = false  // Feature flag for new signal editor

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let configManager = ConfigManager()
    private let commandRunner = YabaiCommandRunner()
    private let scriptingAdditionManager = YabaiScriptingAdditionManager.shared
    private let permissionsManager = PermissionsManager.shared
    private let animationManager = WindowAnimationManager.shared
    private let performanceManager = AnimationPerformanceManager.shared

    // MARK: - Computed Properties
    var hasUnappliedChanges: Bool {
        // TODO: Implement change detection
        false
    }

    var sipRequiredFeaturesEnabled: Bool {
        windowOpacity || !windowShadow || windowBorder || menuBarOpacity < 1.0
    }

    // Feature support detection
    var windowMagnificationSupported: Bool {
        // window_magnification not yet implemented in yabai (future feature)
        false
    }

    var hoverMagnificationSupported: Bool {
        // Hover magnification works with our custom implementation
        // Requires global mouse tracking which works with SIP disabled
        true
    }

    var windowBorderSupported: Bool {
        // window_border not yet implemented in yabai (future feature)
        false
    }

    var windowTopmostSupported: Bool {
        // window_topmost not yet implemented in yabai (future feature)
        false
    }

    // MARK: - Initialization
    init() {
        loadCurrentSettings()
        checkPermissions()
        checkScriptingAdditionStatus()
        setupSubscriptions()
        setupAnimationBindings()
    }

    private func setupSubscriptions() {
        // Update SIP warnings when relevant settings change
        Publishers.CombineLatest(
            $windowOpacity,
            Publishers.CombineLatest4(
                $windowShadow,
                $windowBorder,
                $windowMagnification,
                $menuBarOpacity
            )
        )
        .sink { [weak self] _, _ in
            self?.updateSIPWarning()
        }
        .store(in: &cancellables)
    }

    private func setupAnimationBindings() {
        // Bind animation settings to managers
        $directWindowMetalEnabled
            .sink { [weak self] enabled in
                // This setting affects how Metal animations are applied
                // The WindowMetalBinder will check this when deciding whether to use direct binding
                // Update Metal settings in animation manager
                self?.animationManager.updateMetalSettings(
                    metalAnimationsEnabled: self?.metalAnimationsEnabled ?? false,
                    directWindowMetalEnabled: enabled
                )
                print("Direct window Metal binding: \(enabled ? "enabled" : "disabled")")
            }
            .store(in: &cancellables)

        $metalAnimationsEnabled
            .sink { [weak self] enabled in
                self?.animationManager.isMonitoringActive = enabled
                // Update Metal settings in animation manager
                self?.animationManager.updateMetalSettings(
                    metalAnimationsEnabled: enabled,
                    directWindowMetalEnabled: self?.directWindowMetalEnabled ?? false
                )
                if enabled {
                    let modeString = self?.animationPerformanceMode.rawValue ?? "auto"
                    if modeString == "auto" {
                        self?.performanceManager.setPerformanceMode(.auto)
                    } else if modeString == "ultra" {
                        self?.performanceManager.setPerformanceMode(.ultra)
                    } else if modeString == "high" {
                        self?.performanceManager.setPerformanceMode(.high)
                    } else if modeString == "medium" {
                        self?.performanceManager.setPerformanceMode(.medium)
                    } else if modeString == "low" {
                        self?.performanceManager.setPerformanceMode(.low)
                    } else {
                        self?.performanceManager.setPerformanceMode(.minimal)
                    }
                }
            }
            .store(in: &cancellables)

        $animationPerformanceMode
            .sink { [weak self] mode in
                let modeString = mode.rawValue
                if modeString == "auto" {
                    self?.performanceManager.setPerformanceMode(.auto)
                } else if modeString == "ultra" {
                    self?.performanceManager.setPerformanceMode(.ultra)
                } else if modeString == "high" {
                    self?.performanceManager.setPerformanceMode(.high)
                } else if modeString == "medium" {
                    self?.performanceManager.setPerformanceMode(.medium)
                } else if modeString == "low" {
                    self?.performanceManager.setPerformanceMode(.low)
                } else {
                    self?.performanceManager.setPerformanceMode(.minimal)
                }
            }
            .store(in: &cancellables)

        // Listen for performance changes
        NotificationCenter.default.publisher(for: .animationPerformanceChanged)
            .sink { [weak self] notification in
                if let mode = notification.userInfo?["mode"] as? AnimationPerformanceMode {
                    self?.animationPerformanceMode = SettingsAnimationPerformanceMode(rawValue: mode.rawValue) ?? .auto
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Settings Loading
    func loadCurrentSettings() {
        Task {
            do {
                let config = try await configManager.readConfig()
                await MainActor.run {
                    applyConfigToState(config)
                }

                // Load rules and signals
                let loadedRules = try await configManager.readRules()
                let loadedSignals = try await configManager.readSignals()

                await MainActor.run {
                    self.rules = loadedRules
                    self.signals = loadedSignals
                }
            } catch {
                await MainActor.run {
                    lastStatus = "Error loading settings: \(error.localizedDescription)"
                }
            }
        }
    }

    private func applyConfigToState(_ config: [String: String]) {
        // Global settings
        mouseFollowsFocus = config["mouse_follows_focus"] == "on"
        focusFollowsMouse = FocusMode(rawValue: config["focus_follows_mouse"] ?? "off") ?? .off
        windowOriginDisplay = WindowOriginDisplay(rawValue: config["window_origin_display"] ?? "default") ?? .default
        windowPlacement = WindowPlacement(rawValue: config["window_placement"] ?? "first_child") ?? .first_child
        windowZoomPersist = config["window_zoom_persist"] == "on"
        windowTopmost = config["window_topmost"] == "on"
        splitRatio = Double(config["split_ratio"] ?? "0.5") ?? 0.5
        splitType = SplitType(rawValue: config["split_type"] ?? "auto") ?? .auto
        autoBalance = config["auto_balance"] == "on"
        mouseModifier = MouseModifier(rawValue: config["mouse_modifier"] ?? "alt") ?? .alt
        mouseAction1 = MouseAction(rawValue: config["mouse_action1"] ?? "move") ?? .move
        mouseAction2 = MouseAction(rawValue: config["mouse_action2"] ?? "resize") ?? .resize
        mouseDropAction = MouseDropAction(rawValue: config["mouse_drop_action"] ?? "swap") ?? .swap

        // Window aesthetics
        windowOpacity = config["window_opacity"] == "on"
        windowOpacityDuration = Double(config["window_opacity_duration"] ?? "0.0") ?? 0.0
        activeWindowOpacity = Double(config["active_window_opacity"] ?? "1.0") ?? 1.0
        normalWindowOpacity = Double(config["normal_window_opacity"] ?? "1.0") ?? 1.0
        windowShadow = config["window_shadow"] != "off"
        windowMagnification = config["window_magnification"] == "on"
        windowMagnificationFactor = Double(config["window_magnification_magnify"] ?? "1.0") ?? 1.0
        windowMagnificationDuration = Double(config["window_magnification_duration"] ?? "0.0") ?? 0.0

        // Hover magnification (app-specific, not in yabai config)
        // TODO: Implement proper persistence for these settings
        hoverMagnification = false // Default to off initially
        hoverMagnificationFactor = 1.1
        hoverMagnificationDuration = 0.3
        hoverMagnificationDelay = 0.2
        windowBorder = config["window_border"] == "on"
        windowBorderWidth = Double(config["window_border_width"] ?? "1.0") ?? 1.0
        windowBorderRadius = Double(config["window_border_radius"] ?? "0.0") ?? 0.0
        windowBorderBlur = config["window_border_blur"] == "on"

        // Layout
        layout = LayoutType(rawValue: config["layout"] ?? "bsp") ?? .bsp
        topPadding = Double(config["top_padding"] ?? "0") ?? 0
        bottomPadding = Double(config["bottom_padding"] ?? "0") ?? 0
        leftPadding = Double(config["left_padding"] ?? "0") ?? 0
        rightPadding = Double(config["right_padding"] ?? "0") ?? 0
        windowGap = Double(config["window_gap"] ?? "6") ?? 6
        windowAnimationDuration = Double(config["window_animation_duration"] ?? "0.0") ?? 0.0
        windowAnimationEasing = AnimationEasing(rawValue: config["window_animation_easing"] ?? "ease_out_cubic") ?? .easeOutCubic

        // Menu bar
        menuBarOpacity = Double(config["menubar_opacity"] ?? "1.0") ?? 1.0

        // Metal animations (custom config keys)
        metalAnimationsEnabled = config["metal_animations_enabled"] == "on"
        directWindowMetalEnabled = config["direct_window_metal_enabled"] == "on"
        animationPreset = AnimationPreset(rawValue: config["animation_preset"] ?? "minimal") ?? .minimal
        animationPerformanceMode = SettingsAnimationPerformanceMode(rawValue: config["animation_performance_mode"] ?? "auto") ?? .auto
    }

    // MARK: - Apply Changes
    func applyAllChanges(preview: Bool = false) async throws {
        await MainActor.run { isApplying = true }
        defer {
            // Ensure isApplying gets reset even if there's an error
            Task { await MainActor.run { isApplying = false } }
        }

        do {
            let configUpdates = buildConfigUpdates()
            let commands = buildCommandsFromUpdates(configUpdates)

            if preview {
                await MainActor.run { isPreviewing = true }
                try await runCommandsDry(commands)
                await MainActor.run {
                    isPreviewing = false
                    lastStatus = "Preview applied - changes are temporary"
                }
            } else {
                try await runCommands(commands)
                try await configManager.updateSettings(configUpdates)
                await MainActor.run {
                    lastStatus = "Changes applied successfully at \(Date.now.formatted(date: .omitted, time: .shortened))"
                }
            }
        } catch {
            await MainActor.run {
                lastStatus = "Error: \(error.localizedDescription)"
            }
            throw error
        }
    }

    private func buildConfigUpdates() -> [String: String] {
        var updates: [String: String] = [:]

        // Global
        updates["mouse_follows_focus"] = mouseFollowsFocus ? "on" : "off"
        updates["focus_follows_mouse"] = focusFollowsMouse.rawValue
        updates["window_origin_display"] = windowOriginDisplay.rawValue
        updates["window_placement"] = windowPlacement.rawValue
        updates["window_zoom_persist"] = windowZoomPersist ? "on" : "off"
        // window_topmost not supported in yabai v7.1.16
        // updates["window_topmost"] = windowTopmost ? "on" : "off"
        updates["split_ratio"] = String(format: "%.2f", splitRatio)
        updates["split_type"] = splitType.rawValue
        updates["auto_balance"] = autoBalance ? "on" : "off"
        updates["mouse_modifier"] = mouseModifier.rawValue
        updates["mouse_action1"] = mouseAction1.rawValue
        updates["mouse_action2"] = mouseAction2.rawValue
        updates["mouse_drop_action"] = mouseDropAction.rawValue

        // Window aesthetics
        updates["window_opacity"] = windowOpacity ? "on" : "off"
        updates["window_opacity_duration"] = String(format: "%.2f", windowOpacityDuration)
        updates["active_window_opacity"] = String(format: "%.2f", activeWindowOpacity)
        updates["normal_window_opacity"] = String(format: "%.2f", normalWindowOpacity)
        updates["window_shadow"] = windowShadow ? "on" : "off"
        // window_magnification not supported in yabai v7.1.16
        // updates["window_magnification"] = windowMagnification ? "on" : "off"
        // updates["window_magnification_magnify"] = String(format: "%.2f", windowMagnificationFactor)
        // updates["window_magnification_duration"] = String(format: "%.2f", windowMagnificationDuration)
        // window_border not supported in yabai v7.1.16
        // updates["window_border"] = windowBorder ? "on" : "off"
        // updates["window_border_width"] = String(format: "%.1f", windowBorderWidth)
        // updates["window_border_radius"] = String(format: "%.1f", windowBorderRadius)
        // updates["window_border_blur"] = windowBorderBlur ? "on" : "off"

        // Layout
        updates["layout"] = layout.rawValue
        updates["top_padding"] = String(Int(topPadding))
        updates["bottom_padding"] = String(Int(bottomPadding))
        updates["left_padding"] = String(Int(leftPadding))
        updates["right_padding"] = String(Int(rightPadding))
        updates["window_gap"] = String(Int(windowGap))
        updates["window_animation_duration"] = String(format: "%.2f", windowAnimationDuration)
        updates["window_animation_easing"] = windowAnimationEasing.rawValue

        // Menu bar - only menubar_opacity is supported
        updates["menubar_opacity"] = String(format: "%.2f", menuBarOpacity)

        // Metal animations (custom config - stored separately)
        // Note: Animation settings are handled by the animation managers, not yabai config
        // We store them for persistence but don't send to yabai
        updates["metal_animations_enabled"] = metalAnimationsEnabled ? "on" : "off"
        updates["direct_window_metal_enabled"] = directWindowMetalEnabled ? "on" : "off"
        updates["animation_preset"] = animationPreset.rawValue
        updates["animation_performance_mode"] = animationPerformanceMode.rawValue

        return updates
    }

    private func buildCommandsFromUpdates(_ updates: [String: String]) -> [String] {
        // Only send keys to yabai that yabai actually supports.
        // Some settings are app-specific (animation/metal settings) and should be persisted
        // but not applied via `yabai -m config`.
        let yabaiSupportedKeys: Set<String> = [
            "mouse_follows_focus",
            "focus_follows_mouse",
            "window_origin_display",
            "window_placement",
            "window_zoom_persist",
            "split_ratio",
            "split_type",
            "auto_balance",
            "mouse_modifier",
            "mouse_action1",
            "mouse_action2",
            "mouse_drop_action",
            "window_opacity",
            "window_opacity_duration",
            "active_window_opacity",
            "normal_window_opacity",
            "window_shadow",
            "layout",
            "top_padding",
            "bottom_padding",
            "left_padding",
            "right_padding",
            "window_gap",
            "window_animation_duration",
            "window_animation_easing",
            "menubar_opacity"
        ]

        return updates.compactMap { key, value in
            yabaiSupportedKeys.contains(key) ? "yabai -m config \(key) \(value)" : nil
        }
    }

    private func runCommands(_ commands: [String]) async throws {
        for command in commands {
            try await commandRunner.run(command: command)
        }
    }

    private func runCommandsDry(_ commands: [String]) async throws {
        // For preview, we run the commands but they will be temporary
        // In a real implementation, you might want to store original values and restore them
        try await runCommands(commands)
    }

    // MARK: - Rules Management
    func addRule(_ rule: YabaiRule) async throws {
        try await configManager.addRule(rule)
        rules.append(rule)
    }

    func removeRule(at index: Int) async throws {
        try await configManager.removeRule(index: index)
        rules.remove(at: index)
    }

    func updateRule(_ rule: YabaiRule, at index: Int) async throws {
        try await removeRule(at: index)
        try await addRule(rule)
        rules[index] = rule
    }

    // MARK: - Signals Management
    func addSignal(_ signal: YabaiSignal) async throws {
        try await configManager.addSignal(signal)
        signals.append(signal)
    }

    func removeSignal(at index: Int) async throws {
        try await configManager.removeSignal(index: index)
        signals.remove(at: index)
    }

    func updateSignal(_ signal: YabaiSignal, at index: Int) async throws {
        // Use the signal's yabai index for removal, not the array index
        if let yabaiIndex = signals[index].index {
            try await configManager.removeSignal(index: yabaiIndex)
        } else {
            // Fallback: if no yabai index, use array index (this shouldn't happen for loaded signals)
            try await removeSignal(at: index)
        }

        // Add the updated signal
        try await addSignal(signal)

        // Update the array at the original position to maintain UI order
        signals[index] = signal
    }

    // MARK: - Presets
    func applyPreset(_ preset: PresetConfig) async throws {
        // Apply config
        let config = preset.config ?? [:]
        try await configManager.writeConfig(config)
        applyConfigToState(config)

        // Apply rules
        if let rules = preset.rules {
            for rule in rules {
                try await addRule(rule)
            }
        }

        // Apply signals
        if let signals = preset.signals {
            for signal in signals {
                try await addSignal(signal)
            }
        }

        await MainActor.run {
            lastStatus = "Preset '\(preset.name)' applied successfully"
        }
    }

    func createPreset(name: String, description: String? = nil) {
        let currentConfig = buildConfigUpdates()
        let preset = PresetConfig(
            name: name,
            description: description,
            config: currentConfig,
            rules: rules,
            signals: signals
        )
        customPresets.append(preset)
        savePresets()
    }

    func deletePreset(_ preset: PresetConfig) {
        customPresets.removeAll { $0.id == preset.id }
        savePresets()
    }

    private func savePresets() {
        // TODO: Implement preset persistence
    }

    // MARK: - Quick Actions
    func toggleFloat() async throws {
        try await commandRunner.toggleWindowFloat()
    }

    func toggleFullscreen() async throws {
        try await commandRunner.toggleWindowFullscreen()
    }

    func balanceWindows() async throws {
        try await commandRunner.balanceSpace()
    }

    func mirrorSpace(axis: MirrorAxis) async throws {
        try await commandRunner.mirrorSpace(axis: axis)
    }

    func rotateSpace(degrees: Int) async throws {
        try await commandRunner.rotateSpace(degrees: degrees)
    }

    func focusDisplay(index: UInt32) async throws {
        try await commandRunner.focusDisplay(index: index)
    }

    func balanceDisplay() async throws {
        try await commandRunner.balanceDisplay()
    }

    // MARK: - Permission & System Checks
    private func checkPermissions() {
        hasAccessibilityPermission = permissionsManager.hasAccessibilityPermission
        hasScreenRecordingPermission = permissionsManager.hasScreenRecordingPermission
    }

    private func checkScriptingAdditionStatus() {
        Task {
            let sipDisabled = await scriptingAdditionManager.isSIPDisabled()
            let saLoaded = await scriptingAdditionManager.isScriptingAdditionLoaded()

            await MainActor.run {
                if !sipDisabled && sipRequiredFeaturesEnabled {
                    scriptingAdditionStatus = "❌ SIP enabled - window features unavailable"
                } else if sipRequiredFeaturesEnabled {
                    scriptingAdditionStatus = saLoaded ? "✅ Ready" : "⚠️ Scripting addition not loaded"
                } else {
                    scriptingAdditionStatus = nil
                }
            }
        }
    }

    private func updateSIPWarning() {
        Task {
            let sipDisabled = await scriptingAdditionManager.isSIPDisabled()
            await MainActor.run {
                showSIPWarning = !sipDisabled && sipRequiredFeaturesEnabled
            }
        }
    }

    // MARK: - Backup & Restore
    func createBackup() async throws {
        try await configManager.createBackup()
        await MainActor.run {
            lastStatus = "Backup created successfully"
        }
    }

    func restoreLatestBackup() async throws {
        try await configManager.restoreLatestBackup()
        loadCurrentSettings()
        await MainActor.run {
            lastStatus = "Backup restored successfully"
        }
    }

    func listBackups() -> [URL] {
        configManager.listBackups()
    }
}
