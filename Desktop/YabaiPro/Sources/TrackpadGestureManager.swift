//
//  TrackpadGestureManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

// CGEvent tap callback function
func eventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }

    let manager = Unmanaged<TrackpadGestureManager>.fromOpaque(userInfo).takeUnretainedValue()
    manager.handleCGEvent(event, type: type)

    return Unmanaged.passUnretained(event)
}

class TrackpadGestureManager {
    static let shared = TrackpadGestureManager()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var keyboardMonitor: Any?

    // Resize state
    private var isInResizeMode = false
    private var initialResizePosition: CGPoint?
    private var originalWindowFrame: CGRect?

    private let yabaiRunner = YabaiCommandRunner.shared

    private init() {}

    func startMonitoring() {
        print("🎯 Starting trackpad gesture monitoring...")

        // Check if we have accessibility permissions
        let hasAccessibility = AXIsProcessTrusted()
        if !hasAccessibility {
            print("⚠️  Accessibility permissions not granted - gesture monitoring disabled")
            return
        }

        // Create CGEvent tap to capture scroll wheel events (which include multi-touch)
        let eventMask: CGEventMask = 1 << CGEventType.scrollWheel.rawValue

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        if let tap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            print("✅ Trackpad gesture monitoring started with CGEvent tap")
        } else {
            print("❌ Failed to create CGEvent tap - may need Accessibility permissions")
        }

        // Keep keyboard test for debugging
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == 49 && event.modifierFlags.contains(.command) { // Space + Cmd
                print("🎯 Test resize triggered via keyboard shortcut")
                self?.triggerTestResize()
            }
        }

        print("💡 Test resize with Cmd+Space")
    }

    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
        print("🛑 Trackpad gesture monitoring stopped")
    }

    func handleCGEvent(_ event: CGEvent, type: CGEventType) {
        // Only process if gestures are enabled in settings
        guard ComprehensiveSettingsViewModel.shared.twoFingerResizeEnabled else {
            return
        }

        if type == .scrollWheel {
            handleScrollWheelEvent(event)
        }
    }

    private func handleScrollWheelEvent(_ event: CGEvent) {
        let pointDeltaX = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2)
        let pointDeltaY = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        let isMomentum = event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0

        if abs(pointDeltaX) > 0.1 || abs(pointDeltaY) > 0.1 {
            print("🎯 Scroll gesture detected - deltaX: \(pointDeltaX), deltaY: \(pointDeltaY)")

            let mouseLocation = NSEvent.mouseLocation
            let centerPoint = CGPoint(x: mouseLocation.x, y: mouseLocation.y)

            if !isInResizeMode {
                startResizeIfNeeded(at: centerPoint)
            } else {
                let sensitivity = ComprehensiveSettingsViewModel.shared.resizeSensitivity
                let adjustedDeltaX = pointDeltaX * sensitivity * 2
                let adjustedDeltaY = pointDeltaY * sensitivity * 2

                let newPoint = CGPoint(
                    x: centerPoint.x + adjustedDeltaX,
                    y: centerPoint.y + adjustedDeltaY
                )
                continueResize(to: newPoint)
            }
        }

        if abs(pointDeltaX) < 0.01 && abs(pointDeltaY) < 0.01 && isInResizeMode && isMomentum {
            endResize()
        }
    }

    private func startResizeIfNeeded(at point: CGPoint) {
        print("🎯 Starting resize check at point: \(point)")
        Task {
            guard let windowInfo = await getWindowUnderPoint(point) else {
                print("🎯 No window found under cursor")
                return
            }

            guard isWindowResizable(windowInfo) else { return }

            print("🎯 Starting two-finger resize on window \(windowInfo.id)")

            isInResizeMode = true
            initialResizePosition = point
            originalWindowFrame = CGRect(x: windowInfo.frame.x, y: windowInfo.frame.y,
                                       width: windowInfo.frame.w, height: windowInfo.frame.h)

            if ComprehensiveSettingsViewModel.shared.gestureHapticFeedbackEnabled {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            }
        }
    }

    private func continueResize(to point: CGPoint) {
        guard isInResizeMode,
              let initialPos = initialResizePosition,
              let originalFrame = originalWindowFrame else { return }

        Task {
            guard let currentWindow = await getFocusedWindow() else {
                print("🎯 No focused window found for resize")
                return
            }

            let windowId = currentWindow.id
            let deltaX = point.x - initialPos.x
            let deltaY = point.y - initialPos.y
            let direction = ResizeDirection.from(deltaX: deltaX, deltaY: deltaY)
            let sensitivity = ComprehensiveSettingsViewModel.shared.resizeSensitivity

            do {
                switch direction {
                case .right:
                    let newWidth = originalFrame.width + (deltaX * sensitivity)
                    try await yabaiRunner.resizeWindow(id: windowId, width: newWidth, height: originalFrame.height)

                case .left:
                    let newWidth = originalFrame.width + (-deltaX * sensitivity)
                    let newX = originalFrame.minX + (deltaX * sensitivity)
                    try await yabaiRunner.resizeWindow(id: windowId, width: newWidth, height: originalFrame.height)
                    try await yabaiRunner.moveWindow(id: windowId, x: newX, y: nil)

                case .up:
                    let newHeight = originalFrame.height + (-deltaY * sensitivity)
                    let newY = originalFrame.minY + (deltaY * sensitivity)
                    try await yabaiRunner.resizeWindow(id: windowId, width: originalFrame.width, height: newHeight)
                    try await yabaiRunner.moveWindow(id: windowId, x: nil, y: newY)

                case .down:
                    let newHeight = originalFrame.height + (deltaY * sensitivity)
                    try await yabaiRunner.resizeWindow(id: windowId, width: originalFrame.width, height: newHeight)

                case .diagonal:
                    let scaleFactor = max(abs(deltaX), abs(deltaY)) * sensitivity / 100.0
                    let newWidth = originalFrame.width * (1 + scaleFactor)
                    let newHeight = originalFrame.height * (1 + scaleFactor)
                    try await yabaiRunner.resizeWindow(id: windowId, width: newWidth, height: newHeight)
                }
            } catch {
                print("Error resizing window: \(error)")
            }
        }
    }

    func endResize() {
        if isInResizeMode {
            print("🎯 Ending two-finger resize")
            isInResizeMode = false
            initialResizePosition = nil
            originalWindowFrame = nil

            if ComprehensiveSettingsViewModel.shared.gestureHapticFeedbackEnabled {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            }
        }
    }

    private func getFocusedWindow() async -> YabaiWindowJSON? {
        do {
            let windowsData = try await yabaiRunner.queryWindows()
            let windows = try JSONDecoder().decode([YabaiWindowJSON].self, from: windowsData)
            return windows.first { $0.hasFocus }
        } catch {
            print("Error getting focused window: \(error)")
            return nil
        }
    }

    private func triggerTestResize() {
        let mouseLocation = NSEvent.mouseLocation
        print("🎯 Testing resize at mouse location: \(mouseLocation)")

        Task {
            guard let windowInfo = await getWindowUnderPoint(mouseLocation) else {
                print("🎯 No window found at mouse location")
                return
            }

            print("🎯 Found window: \(windowInfo.id) - testing resize")

            do {
                let newWidth = windowInfo.frame.w + 50
                let newHeight = windowInfo.frame.h + 30
                try await yabaiRunner.resizeWindow(id: windowInfo.id, width: newWidth, height: newHeight)
                print("✅ Test resize successful - window should be larger")
            } catch {
                print("❌ Test resize failed: \(error)")
            }
        }
    }

    private func getWindowUnderPoint(_ point: CGPoint) async -> YabaiWindowJSON? {
        do {
            let windowsData = try await yabaiRunner.queryWindows()
            let windows = try JSONDecoder().decode([YabaiWindowJSON].self, from: windowsData)

            for window in windows {
                let frame = CGRect(x: window.frame.x, y: window.frame.y,
                                 width: window.frame.w, height: window.frame.h)
                if frame.contains(point) {
                    return window
                }
            }

            return windows.first { $0.hasFocus }
        } catch {
            print("Error getting windows: \(error)")
            return nil
        }
    }

    private func isWindowResizable(_ window: YabaiWindowJSON) -> Bool {
        return window.id > 100
    }
}

enum ResizeDirection {
    case right, left, up, down, diagonal

    static func from(deltaX: CGFloat, deltaY: CGFloat) -> ResizeDirection {
        let absX = abs(deltaX)
        let absY = abs(deltaY)

        if absX > absY * 2 { return deltaX > 0 ? .right : .left }
        if absY > absX * 2 { return deltaY > 0 ? .up : .down }
        return .diagonal
    }
}