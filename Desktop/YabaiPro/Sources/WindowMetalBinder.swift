//
//  WindowMetalBinder.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation
import AppKit
import Metal
import QuartzCore

class WindowMetalBinder {
    static let shared = WindowMetalBinder()

    private var metalLayers: [UInt32: CAMetalLayer] = [:]
    private var renderers: [UInt32: MetalWindowRenderer] = [:]
    private var animationTasks: [UInt32: Task<Void, Never>] = [:]

    private let metalDevice = MTLCreateSystemDefaultDevice()

    // MARK: - SIP Check
    var isSIPDisabled: Bool {
        // Check if SIP is disabled by trying to access a protected file
        let fileManager = FileManager.default
        let protectedPath = "/System/Library/Keychains/apsd.keychain"
        return fileManager.isReadableFile(atPath: protectedPath)
    }

    // MARK: - Public API

    func attachMetalLayer(to windowId: UInt32, frame: CGRect, animationType: MetalAnimationView.AnimationType) async throws {
        guard isSIPDisabled else {
            print("❌ SIP is enabled - direct window Metal binding requires SIP to be disabled")
            throw WindowMetalError.sipEnabled
        }

        guard let metalDevice = metalDevice else {
            throw WindowMetalError.metalUnavailable
        }

        print("🔧 Attaching Metal layer to window \(windowId)")

        // Find the actual NSWindow for this yabai window ID
        guard let nsWindow = findNSWindow(for: windowId) else {
            print("❌ Could not find NSWindow for yabai window \(windowId)")
            throw WindowMetalError.windowNotFound
        }

        // Create Metal layer
        let metalLayer = CAMetalLayer()
        metalLayer.device = metalDevice
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.frame = frame
        metalLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0
        metalLayer.isOpaque = false

        // Try to attach to the window's layer hierarchy
        // This uses private APIs and requires SIP to be disabled
        do {
            try attachLayerToWindow(metalLayer, window: nsWindow)
            metalLayers[windowId] = metalLayer

            // Start rendering
            let renderer = MetalWindowRenderer(layer: metalLayer, animationType: animationType)
            renderers[windowId] = renderer

            print("✅ Metal layer attached to window \(windowId)")
        } catch {
            print("❌ Failed to attach Metal layer: \(error)")
            throw error
        }
    }

    func updateLayerFrame(for windowId: UInt32, frame: CGRect) {
        if let metalLayer = metalLayers[windowId] {
            metalLayer.frame = frame
        }
    }

    func detachMetalLayer(from windowId: UInt32) {
        if let metalLayer = metalLayers[windowId] {
            // Stop any ongoing animation
            animationTasks[windowId]?.cancel()
            animationTasks.removeValue(forKey: windowId)

            // Remove the layer
            metalLayer.removeFromSuperlayer()
            metalLayers.removeValue(forKey: windowId)
            renderers.removeValue(forKey: windowId)

            print("🔌 Detached Metal layer from window \(windowId)")
        }
    }

    func startAnimation(on windowId: UInt32, duration: TimeInterval, easing: AnimationEasing) {
        guard let renderer = renderers[windowId] else { return }

        // Cancel any existing animation
        animationTasks[windowId]?.cancel()

        // Start new animation
        let task = Task {
            let startTime = Date()
            let endTime = startTime.addingTimeInterval(duration)

            while !Task.isCancelled && Date() < endTime {
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = min(elapsed / duration, 1.0)
                let easedProgress = applyEasing(easing, progress: progress)

                renderer.renderFrame(progress: easedProgress)
                try? await Task.sleep(nanoseconds: 16_666_667) // ~60fps
            }

            // Animation complete
            renderer.renderFrame(progress: 1.0)
        }

        animationTasks[windowId] = task
    }

    // MARK: - Private Methods

    private func findNSWindow(for yabaiWindowId: UInt32) -> NSWindow? {
        // Get all windows from all applications
        guard let windowList = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        // Find the window with matching yabai ID
        // This is a simplified approach - in practice you'd need to correlate
        // yabai's window IDs with CG window numbers
        for windowInfo in windowList {
            if let windowNumber = windowInfo[kCGWindowNumber as String] as? Int,
               let ownerPid = windowInfo[kCGWindowOwnerPID as String] as? Int32 {

                // Try to find NSWindow for this CG window
                // This requires private APIs when SIP is disabled
                if let nsWindow = findNSWindowForCGWindow(windowNumber: CGWindowID(windowNumber), pid: pid_t(ownerPid)) {
                    // Additional validation would go here
                    return nsWindow
                }
            }
        }

        return nil
    }

    private func findNSWindowForCGWindow(windowNumber: CGWindowID, pid: pid_t) -> NSWindow? {
        // This requires private APIs - simplified placeholder
        // In a real implementation, you'd use CoreGraphics private functions
        // to get the NSWindow from the CGWindowID

        // Placeholder - return nil for now
        // Real implementation would use something like:
        // CGSGetWindowOwner, CGSGetConnectionID, etc.
        return nil
    }

    private func attachLayerToWindow(_ layer: CAMetalLayer, window: NSWindow) throws {
        // This requires private APIs when SIP is disabled
        // Simplified placeholder - real implementation would use:
        // - CGSWindowAddSurface or similar private functions
        // - Or inject into the window's layer hierarchy

        guard let windowLayer = window.contentView?.layer else {
            throw WindowMetalError.layerAttachFailed
        }

        // Add as sublayer - this might work for some cases
        windowLayer.addSublayer(layer)

        // In a real implementation, you'd use private CGS functions:
        // CGSAddSurface, CGSSetSurfaceLayer, etc.
    }

    private func applyEasing(_ easing: AnimationEasing, progress: Double) -> Double {
        switch easing {
        case .linear:
            return progress
        case .easeIn:
            return progress * progress * progress
        case .easeOut:
            return 1 - pow(1 - progress, 3)
        case .easeInOut:
            return progress < 0.5 ?
                4 * progress * progress * progress :
                1 - pow(-2 * progress + 2, 3) / 2
        case .easeOutCubic:
            return 1 - pow(1 - progress, 3)
        case .easeInOutCubic:
            return progress < 0.5 ?
                4 * progress * progress * progress :
                1 - pow(-2 * progress + 2, 3) / 2
        }
    }
}

// MARK: - Supporting Types

class MetalWindowRenderer {
    private let metalLayer: CAMetalLayer
    private let animationType: MetalAnimationView.AnimationType
    private let commandQueue: MTLCommandQueue?
    private let library: MTLLibrary?

    init(layer: CAMetalLayer, animationType: MetalAnimationView.AnimationType) {
        self.metalLayer = layer
        self.animationType = animationType

        guard let device = layer.device as? MTLDevice else {
            commandQueue = nil
            library = nil
            return
        }

        commandQueue = device.makeCommandQueue()

        // Load minimal shaders
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float4 color;
        };

        vertex VertexOut basicVertex(uint vertexID [[vertex_id]]) {
            return { float4(0, 0, 0, 1), float4(1, 0, 0, 1) };
        }

        fragment float4 basicFragment(VertexOut in [[stage_in]]) {
            return in.color;
        }
        """

        library = try? device.makeLibrary(source: shaderSource, options: nil)
    }

    func renderFrame(progress: Double) {
        guard let commandQueue = commandQueue,
              let drawable = metalLayer.nextDrawable(),
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: createRenderPassDescriptor(for: drawable.texture)) else {
            return
        }

        // Simple animation based on progress
        var color = SIMD4<Float>(Float(progress), 0.5, 1.0 - Float(progress), 0.8)

        encoder.setFragmentBytes(&color, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func createRenderPassDescriptor(for texture: MTLTexture) -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        descriptor.colorAttachments[0].storeAction = .store
        return descriptor
    }
}

enum WindowMetalError: Error {
    case sipEnabled
    case metalUnavailable
    case windowNotFound
    case layerAttachFailed
}
