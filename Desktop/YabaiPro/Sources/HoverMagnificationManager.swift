//
//  HoverMagnificationManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation
import AppKit
import Combine

class HoverMagnificationManager: ObservableObject {
    static let shared = HoverMagnificationManager()

    @Published var isEnabled = false
    @Published var magnificationFactor: Double = 1.1
    @Published var animationDuration: Double = 0.3
    @Published var hoverDelay: Double = 0.2

    private var mouseMonitor: Any?
    private var currentHoveredWindowId: UInt32?
    private var magnificationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let commandRunner = YabaiCommandRunner.shared
    private let animationManager = WindowAnimationManager.shared

    private init() {
        setupMouseTracking()
        setupSettingsObservers()
    }

    private func setupMouseTracking() {
        // Global mouse move event monitoring
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.handleMouseMoved(event: event)
        }
    }

    private func setupSettingsObservers() {
        // Observe settings changes from ComprehensiveSettingsViewModel
        let settingsViewModel = ComprehensiveSettingsViewModel.shared

        settingsViewModel.$hoverMagnification
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                if enabled {
                    self?.enable()
                } else {
                    self?.disable()
                }
            }
            .store(in: &cancellables)

        settingsViewModel.$hoverMagnificationFactor
            .receive(on: DispatchQueue.main)
            .assign(to: &$magnificationFactor)

        settingsViewModel.$hoverMagnificationDuration
            .receive(on: DispatchQueue.main)
            .assign(to: &$animationDuration)

        settingsViewModel.$hoverMagnificationDelay
            .receive(on: DispatchQueue.main)
            .assign(to: &$hoverDelay)
    }

    private func handleMouseMoved(event: NSEvent) {
        guard isEnabled else { return }

        let mouseLocation = NSEvent.mouseLocation

        // Find window under cursor
        guard let windowId = findWindowUnderCursor(at: mouseLocation) else {
            handleHoverEnd()
            return
        }

        // If hovering over a different window
        if windowId != currentHoveredWindowId {
            handleHoverEnd()
            handleHoverStart(windowId: windowId, at: mouseLocation)
        }
    }

    private func findWindowUnderCursor(at point: NSPoint) -> UInt32? {
        // Use CGWindowList to find window under cursor
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        // Convert screen coordinates to window coordinates for each window
        for windowInfo in windowList {
            guard let windowId = windowInfo[kCGWindowNumber as String] as? Int,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"] else {
                continue
            }

            let windowRect = CGRect(x: x, y: y, width: width, height: height)

            // Check if point is within window bounds
            if windowRect.contains(CGPoint(x: point.x, y: point.y)) {
                // Verify this is a yabai-managed window by checking if we have animation state for it
                if animationManager.windowStates[UInt32(windowId)] != nil {
                    return UInt32(windowId)
                }
            }
        }

        return nil
    }

    private func handleHoverStart(windowId: UInt32, at point: CGPoint) {
        currentHoveredWindowId = windowId

        // Cancel any existing timer
        magnificationTimer?.invalidate()

        // Start delay timer
        magnificationTimer = Timer.scheduledTimer(withTimeInterval: hoverDelay, repeats: false) { [weak self] _ in
            self?.performMagnification(windowId: windowId, at: point)
        }
    }

    private func handleHoverEnd() {
        guard let windowId = currentHoveredWindowId else { return }

        // Cancel magnification timer
        magnificationTimer?.invalidate()
        magnificationTimer = nil

        // Start unmagnification
        performUnmagnification(windowId: windowId)

        currentHoveredWindowId = nil
    }

    private func performMagnification(windowId: UInt32, at point: CGPoint) {
        // Trigger hover animation through existing animation manager
        animationManager.handleWindowInteraction(
            windowId: windowId,
            point: point,
            interactionType: .hover
        )
    }

    private func performUnmagnification(windowId: UInt32) {
        // Handle hover end through animation manager
        animationManager.handleHoverEnd(windowId: windowId)
    }

    func enable() {
        isEnabled = true
        print("🔍 Hover magnification enabled")
    }

    func disable() {
        isEnabled = false
        handleHoverEnd()
        print("🔍 Hover magnification disabled")
    }

    func updateSettings(factor: Double, duration: Double, delay: Double) {
        magnificationFactor = factor
        animationDuration = duration
        hoverDelay = delay
    }
}










