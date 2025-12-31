//
//  WindowAnimationManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import Combine
import MetalKit

class WindowAnimationManager: ObservableObject {
    static let shared = WindowAnimationManager()

    @Published var windowStates: [UInt32: WindowAnimationState] = [:]
    @Published var globalAnimationTime: Double = 0.0
    @Published var isMonitoringActive = false

    // UI-controlled Metal animation settings
    private var metalAnimationsEnabled = false
    private var directWindowMetalEnabled = false

    private let commandRunner = YabaiCommandRunner.shared
    private var monitoringTask: Task<Void, Never>?
    private var animationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let overlayManager = WindowOverlayManager.shared
    private let metalBinder = WindowMetalBinder.shared
    private var eventTask: Task<Void, Never>?

    private init() {
        setupAnimationTimer()
        startMonitoring()
        startEventSubscription()
    }

    // Method to update Metal animation settings from UI
    func updateMetalSettings(metalAnimationsEnabled: Bool, directWindowMetalEnabled: Bool) {
        self.metalAnimationsEnabled = metalAnimationsEnabled
        self.directWindowMetalEnabled = directWindowMetalEnabled
    }

    deinit {
        stopMonitoring()
        animationTimer?.invalidate()
        overlayManager.hideAllAnimationOverlays()
        eventTask?.cancel()
    }

    private func setupAnimationTimer() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { [weak self] _ in
            self?.globalAnimationTime += 1/60.0
        }
    }

    func startMonitoring() {
        guard !isMonitoringActive else { return }

        isMonitoringActive = true
        monitoringTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.updateWindowStates()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
    }

    func stopMonitoring() {
        isMonitoringActive = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    private func startEventSubscription() {
        eventTask = Task {
            let eventStream = YabaiCommandRunner.shared.subscribeToYabaiEvents()

            do {
                for try await event in eventStream {
                    await handleYabaiEvent(event)
                }
            } catch {
                print("Error in yabai event subscription: \(error)")
            }
        }
    }

    private func handleYabaiEvent(_ event: YabaiEvent) async {
        guard let windowId = event.windowId else { return }

        // Get animation settings
        let settings = AnimationPerformanceManager.shared.optimalSettings(
            metalAnimationsEnabled: metalAnimationsEnabled,
            directWindowMetalEnabled: directWindowMetalEnabled
        )

        // Only proceed if Metal animations are enabled
        guard settings.metalEffectsEnabled else { return }

        switch event.eventType {
        case .windowFocus:
            // Start focus animation on the real window
            if let windowState = windowStates[windowId] {
                do {
                    try await metalBinder.attachMetalLayer(
                        to: windowId,
                        frame: windowState.frame,
                        animationType: .liquidBorder
                    )

                    // Get yabai animation duration and start Metal animation
                    if let duration = await getYabaiAnimationDuration(),
                       let easing = await getYabaiAnimationEasing() {
                        metalBinder.startAnimation(on: windowId, duration: duration, easing: easing)
                    }
                } catch {
                    print("Failed to attach Metal animation to window \(windowId): \(error)")
                    // Fallback to overlay
                    overlayManager.showAnimationOverlay(for: windowId, state: windowState, settings: settings)
                }
            }

        case .windowMove, .windowResize:
            // Update layer position/size for ongoing animations
            if let windowState = windowStates[windowId] {
                metalBinder.updateLayerFrame(for: windowId, frame: windowState.frame)
                overlayManager.updateAnimationOverlay(for: windowId, state: windowState, settings: settings)
            }

        case .windowDestroy:
            // Clean up Metal layer and overlay
            metalBinder.detachMetalLayer(from: windowId)
            overlayManager.hideAnimationOverlay(for: windowId)

        default:
            break
        }
    }

    private func getYabaiAnimationDuration() async -> TimeInterval? {
        do {
            let configData = try await commandRunner.queryJSON("config")
            if let config = try? JSONDecoder().decode([String: String].self, from: configData),
               let durationStr = config["window_animation_duration"],
               let duration = Double(durationStr) {
                return duration
            }
        } catch {
            print("Failed to get yabai animation duration: \(error)")
        }
        return 0.2 // Default
    }

    private func getYabaiAnimationEasing() async -> AnimationEasing? {
        do {
            let configData = try await commandRunner.queryJSON("config")
            if let config = try? JSONDecoder().decode([String: String].self, from: configData),
               let easingStr = config["window_animation_easing"] {
                return AnimationEasing(rawValue: easingStr)
            }
        } catch {
            print("Failed to get yabai animation easing: \(error)")
        }
        return .easeOutCubic // Default
    }

    private func updateWindowStates() async {
        do {
            // Get current window data from yabai
            let windowsData = try await commandRunner.queryWindows()
            let spacesData = try await commandRunner.querySpaces()

            // Parse the data
            let windows = try parseWindows(from: windowsData)
            _ = try parseSpaces(from: spacesData) // Parse spaces for future use

            // Update window states on main thread
            await MainActor.run {
                updateAnimationStates(for: windows)
            }

        } catch {
            print("Failed to update window animation states: \(error)")
        }
    }

    private func parseWindows(from data: Data) throws -> [YabaiWindow] {
        let windows = try JSONDecoder().decode([YabaiWindowJSON].self, from: data)
        return windows.map { json in
            YabaiWindow(
                id: json.id,
                frame: CGRect(x: json.frame.x, y: json.frame.y, width: json.frame.w, height: json.frame.h),
                hasFocus: json.hasFocus
            )
        }
    }

    private func parseSpaces(from data: Data) throws -> [YabaiSpace] {
        let spaces = try JSONDecoder().decode([YabaiSpaceJSON].self, from: data)
        return spaces.map { json in
            YabaiSpace(
                index: json.index,
                focused: json.hasFocus ? json.firstWindow : nil
            )
        }
    }


    private func updateAnimationStates(for windows: [YabaiWindow]) {
        var updatedStates = [UInt32: WindowAnimationState]()

        for window in windows {
            let wasFocused = windowStates[window.id]?.isFocused ?? false
            let isNowFocused = window.hasFocus

            // Create or update animation state
            if let existingState = windowStates[window.id] {
                var state = existingState // Create explicit mutable copy
                // Update existing state
                if !wasFocused && isNowFocused {
                    // Window just gained focus
                    state.isFocused = true
                    state.focusStartTime = Date()
                    state.morphProgress = 0.0
                    state.focusPoint = CGPoint(x: window.frame.midX, y: window.frame.midY)

                    // Animate morph progress
                    withAnimation(.easeOut(duration: 0.5)) {
                        state.morphProgress = 1.0
                    }
                } else if wasFocused && !isNowFocused {
                    // Window lost focus
                    state.isFocused = false
                    state.focusLostTime = Date()
                }

                updatedStates[window.id] = state

            } else {
                // Create new state
                let newState = WindowAnimationState(
                    windowId: window.id,
                    isFocused: isNowFocused,
                    frame: window.frame,
                    focusStartTime: isNowFocused ? Date() : nil,
                    focusPoint: isNowFocused ? CGPoint(x: window.frame.midX, y: window.frame.midY) : nil,
                    morphProgress: isNowFocused ? 0.0 : 1.0
                )

                if isNowFocused {
                    // Animate new focused window
                    withAnimation(.easeOut(duration: 0.5)) {
                        newState.morphProgress = 1.0
                    }
                }

                updatedStates[window.id] = newState
            }
        }

        // Remove states for windows that no longer exist
        let currentWindowIds = Set(windows.map { $0.id })
        let removedWindowIds = Set(windowStates.keys).subtracting(currentWindowIds)

        // Hide overlays for removed windows
        for windowId in removedWindowIds {
            overlayManager.hideAnimationOverlay(for: windowId)
        }

        windowStates = updatedStates.filter { currentWindowIds.contains($0.key) }

        // Update overlays for all current windows
        let settings = AnimationPerformanceManager.shared.optimalSettings(
            metalAnimationsEnabled: metalAnimationsEnabled,
            directWindowMetalEnabled: directWindowMetalEnabled
        )
        for (windowId, state) in windowStates {
            if state.isFocused || state.morphProgress > 0 {
                overlayManager.updateAnimationOverlay(for: windowId, state: state, settings: settings)
            } else {
                overlayManager.hideAnimationOverlay(for: windowId)
            }
        }
    }

    func getAnimationView(for windowId: UInt32) -> AnyView {
        guard let state = windowStates[windowId] else {
            return AnyView(EmptyView())
        }

        let settings = AnimationPerformanceManager.shared.optimalSettings(
            metalAnimationsEnabled: metalAnimationsEnabled,
            directWindowMetalEnabled: directWindowMetalEnabled
        )

        return AnyView(
            WindowAnimationOverlay(
                state: state,
                settings: settings,
                globalTime: globalAnimationTime
            )
            .environmentObject(self)
        )
    }

    func handleWindowInteraction(windowId: UInt32, point: CGPoint, interactionType: InteractionType) {
        guard let existingState = windowStates[windowId] else { return }
        var state = existingState // Create explicit mutable copy

        state.lastInteractionTime = Date()
        state.focusPoint = point
        state.lastInteractionType = interactionType

        windowStates[windowId] = state

        // Trigger interaction-based animations
        switch interactionType {
        case .click:
            triggerRippleAnimation(for: windowId, at: point)
        case .hover:
            triggerHoverAnimation(for: windowId, at: point)
        case .focus:
            triggerFocusAnimation(for: windowId)
        case .drag:
            // Handle drag interactions
            break
        }
    }

    private func triggerRippleAnimation(for windowId: UInt32, at point: CGPoint) {
        // Implementation for ripple effects
        print("Triggering ripple animation for window \(windowId) at \(point)")
    }

    private func triggerHoverAnimation(for windowId: UInt32, at point: CGPoint) {
        guard let existingState = windowStates[windowId] else { return }
        var state = existingState

        // Check if hover magnification is enabled
        let hoverEnabled = ComprehensiveSettingsViewModel.shared.hoverMagnification
        guard hoverEnabled else { return }

        // Don't magnify if window is already magnified or focused
        if state.isMagnified || state.isFocused { return }

        // Apply magnification transformation
        let factor = ComprehensiveSettingsViewModel.shared.hoverMagnificationFactor
        let originalFrame = state.originalFrame ?? state.frame

        // Calculate magnified frame (centered on cursor if possible)
        let magnifiedWidth = originalFrame.width * CGFloat(factor)
        let magnifiedHeight = originalFrame.height * CGFloat(factor)

        // Center the magnification around the cursor point
        let offsetX = (magnifiedWidth - originalFrame.width) / 2.0
        let offsetY = (magnifiedHeight - originalFrame.height) / 2.0

        let magnifiedFrame = CGRect(
            x: originalFrame.minX - offsetX,
            y: originalFrame.minY - offsetY,
            width: magnifiedWidth,
            height: magnifiedHeight
        )

        state.frame = magnifiedFrame
        state.isMagnified = true
        state.magnificationPoint = point

        // Animate the change
        let duration = ComprehensiveSettingsViewModel.shared.hoverMagnificationDuration
        withAnimation(.easeOut(duration: duration)) {
            windowStates[windowId] = state
        }

        // Update Metal layer if it exists
        metalBinder.updateLayerFrame(for: windowId, frame: magnifiedFrame)

        print("🔍 Magnified window \(windowId) to \(factor)x at \(point)")
    }

    func handleHoverEnd(windowId: UInt32) {
        guard var state = windowStates[windowId], state.isMagnified else { return }

        // Restore original frame
        if let originalFrame = state.originalFrame {
            state.frame = originalFrame
            state.isMagnified = false
            state.magnificationPoint = nil

            // Animate back to original size
            let duration = ComprehensiveSettingsViewModel.shared.hoverMagnificationDuration
            withAnimation(.easeOut(duration: duration)) {
                windowStates[windowId] = state
            }

            // Update Metal layer
            metalBinder.updateLayerFrame(for: windowId, frame: originalFrame)

            print("🔍 Unmagnified window \(windowId)")
        }
    }

    private func triggerFocusAnimation(for windowId: UInt32) {
        // Implementation for focus effects
        print("Triggering focus animation for window \(windowId)")
    }

    // MARK: - Animation State Queries

    func getFocusedWindows() -> [WindowAnimationState] {
        return windowStates.values.filter { $0.isFocused }
    }

    func getWindowsNeedingAnimation() -> [WindowAnimationState] {
        return windowStates.values.filter { state in
            // Windows that are focused or recently lost focus
            state.isFocused ||
            (state.focusLostTime != nil && Date().timeIntervalSince(state.focusLostTime!) < 2.0)
        }
    }

    func resetAllAnimations() {
        for (windowId, existingState) in windowStates {
            var state = existingState // Create explicit mutable copy
            state.morphProgress = 0.0
            state.focusStartTime = nil
            state.focusLostTime = nil
            state.isFocused = false
            windowStates[windowId] = state
        }
    }

    // MARK: - Debug/Testing Functions

    /// Creates test window states for debugging animations
    func createTestWindowStates() {
        print("🎭 Creating test window states for animation debugging...")

        // Clear existing states first
        let oldCount = windowStates.count
        windowStates.removeAll()
        if oldCount > 0 {
            print("🧹 Cleared \(oldCount) existing window states")
        }

        let testFrames = [
            CGRect(x: 100, y: 100, width: 800, height: 600),
            CGRect(x: 950, y: 100, width: 800, height: 600),
            CGRect(x: 100, y: 750, width: 800, height: 600)
        ]

        for (index, frame) in testFrames.enumerated() {
            let windowId = UInt32(index + 1)
            let isFocused = (index == 0) // First window is focused

            let state = WindowAnimationState(
                windowId: windowId,
                isFocused: isFocused,
                frame: frame,
                focusStartTime: isFocused ? Date() : nil,
                focusPoint: isFocused ? CGPoint(x: frame.midX, y: frame.midY) : nil,
                morphProgress: isFocused ? 1.0 : 0.0
            )

            windowStates[windowId] = state
            print("✅ Created test window \(windowId): focused=\(isFocused), frame=\(frame)")
        }

        print("🎯 Test setup complete!")
        print("💡 Metal: \(MetalAnimationEngine.shared.isMetalAvailable ? "✅ Available" : "❌ Unavailable")")
        print("💡 Windows created: \(windowStates.count)")
        print("💡 Windows needing animation: \(getWindowsNeedingAnimation().count)")
        print("💡 Animation timer running: \(animationTimer != nil)")
        print("🔄 Animation time: \(globalAnimationTime)")

        // Force objectWillChange to trigger UI updates
        objectWillChange.send()
    }

    /// Debug function to print current window states
    func debugPrintWindowStates() {
        print("🔍 Current Window States:")
        for (windowId, state) in windowStates {
            print("  Window \(windowId): focused=\(state.isFocused), morph=\(state.morphProgress)")
        }
        print("🎨 Total windows with animation states: \(windowStates.count)")
    }
}

// MARK: - Supporting Types
// AnimationWindowInfo, InteractionType are defined in AnimationTypes.swift

class WindowAnimationState: ObservableObject {
    let windowId: UInt32
    @Published var isFocused: Bool
    @Published var frame: CGRect
    @Published var focusStartTime: Date?
    @Published var focusLostTime: Date?
    @Published var focusPoint: CGPoint?
    @Published var morphProgress: Double = 0.0
    @Published var lastInteractionTime: Date?
    @Published var lastInteractionType: InteractionType?

    // Hover magnification properties
    @Published var originalFrame: CGRect?  // Store original frame before magnification
    @Published var isMagnified = false
    @Published var magnificationPoint: CGPoint?

    init(windowId: UInt32, isFocused: Bool, frame: CGRect, focusStartTime: Date? = nil, focusPoint: CGPoint? = nil, morphProgress: Double = 0.0) {
        self.windowId = windowId
        self.isFocused = isFocused
        self.frame = frame
        self.focusStartTime = focusStartTime
        self.focusPoint = focusPoint
        self.morphProgress = morphProgress
        self.originalFrame = frame  // Store original frame for magnification restore
    }

    var timeSinceFocus: Double {
        guard let startTime = focusStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }

    var timeSinceInteraction: Double {
        guard let interactionTime = lastInteractionTime else { return Double.greatestFiniteMagnitude }
        return Date().timeIntervalSince(interactionTime)
    }
}

// InteractionType is defined in AnimationTypes.swift

// YabaiWindowJSON is now defined in YabaiCommandRunner.swift

private struct YabaiSpaceJSON: Codable {
    let index: UInt32
    let hasFocus: Bool
    let firstWindow: UInt32?

    enum CodingKeys: String, CodingKey {
        case index
        case hasFocus = "has-focus"
        case firstWindow = "first-window"
    }
}

struct YabaiWindow {
    let id: UInt32
    let frame: CGRect
    let hasFocus: Bool
}

struct YabaiSpace {
    let index: UInt32
    let focused: UInt32?
}

// MARK: - Animation Overlay View

struct WindowAnimationOverlay: View {
    @ObservedObject var state: WindowAnimationState
    let settings: AnimationSettings
    let globalTime: Double

    var body: some View {
        ZStack {
            // Metal-based animations (if enabled and available)
            if settings.metalEffectsEnabled && MetalAnimationEngine.shared.isMetalAvailable {
                MetalAnimationView(
                    animationType: .liquidBorder,
                    windowInfo: AnimationWindowInfo(
                        id: state.windowId,
                        isFocused: state.isFocused,
                        focusPoint: state.focusPoint,
                        morphProgress: state.morphProgress
                    ),
                    time: .constant(globalTime)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blendMode(.screen)
                .opacity(settings.metalEffectsEnabled ? 0.8 : 0.0)

                // Additional particle effects for focused windows
                if state.isFocused && settings.particleCount > 0 {
                    MetalAnimationView(
                        animationType: .flowingParticles,
                        windowInfo: AnimationWindowInfo(
                            id: state.windowId,
                            isFocused: true,
                            focusPoint: state.focusPoint,
                            morphProgress: state.morphProgress
                        ),
                        time: .constant(globalTime)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blendMode(.screen)
                    .opacity(0.6)
                }

            } else {
                // Canvas fallback
                CanvasFallbackOverlay(state: state, settings: settings, globalTime: globalTime)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .allowsHitTesting(false) // Don't interfere with window interactions
    }
}

// MARK: - Canvas Fallback

struct CanvasFallbackOverlay: View {
    let state: WindowAnimationState
    let settings: AnimationSettings
    let globalTime: Double

    var body: some View {
        Canvas { context, size in
            let time = Float(globalTime)

            if state.isFocused {
                // Draw liquid border effect
                drawLiquidBorder(in: context, size: size, time: time, isActive: true)
            }

            if state.isFocused && settings.particleCount > 0 {
                // Draw simple particle effects
                drawParticles(in: context, size: size, time: time, count: settings.particleCount)
            }
        }
    }

    private func drawLiquidBorder(in context: GraphicsContext, size: CGSize, time: Float, isActive: Bool) {
        let amplitude = isActive ? 4.0 : 1.0
        let segments = 32
        let borderWidth: CGFloat = 3.0

        var path = Path()

        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let x = t * size.width
            let baseY: CGFloat = 0

            // Create flowing wave
            let wave = CGFloat(sin(t * 6.28 + Double(time) * 2.0) * amplitude)

            let point = CGPoint(x: x, y: baseY + wave)

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        // Close the border path
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()

        context.stroke(path, with: .color(Color.blue.opacity(0.6)), lineWidth: borderWidth)
    }

    private func drawParticles(in context: GraphicsContext, size: CGSize, time: Float, count: Int) {
        for i in 0..<min(count, 15) {
            let t = Float(i) / Float(count)

            let x = cos(time * 0.5 + t * 6.28) * Float(size.width) * 0.3 + Float(size.width) * 0.5
            let y = sin(time * 0.7 + t * 6.28) * Float(size.height) * 0.3 + Float(size.height) * 0.5

            let particleSize: CGFloat = 4.0 + CGFloat(sin(time * 2 + t * 6.28)) * 2.0
            let rect = CGRect(x: CGFloat(x) - particleSize/2,
                            y: CGFloat(y) - particleSize/2,
                            width: particleSize,
                            height: particleSize)

            context.fill(Path(ellipseIn: rect), with: .color(Color.blue.opacity(0.4)))
        }
    }
}
