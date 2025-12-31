//
//  MetalAnimationView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import MetalKit

struct MetalAnimationView: View {
    let animationType: AnimationType
    let windowInfo: AnimationWindowInfo?
    @Binding var time: Double

    enum AnimationType: String {
        case liquidBorder
        case flowingParticles
        case rippleEffect
        case morphingShape
    }

    var body: some View {
        ZStack {
            // Try Metal first if available
            if MetalAnimationEngine.shared.isMetalAvailable {
                MetalView(animationType: animationType, windowInfo: windowInfo, time: $time)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .drawingGroup() // Enable GPU rendering
            }

            // Canvas fallback (always rendered, but hidden if Metal works)
            CanvasFallbackView(animationType: animationTypeFromString(animationType.rawValue) ?? .liquidBorder,
                             windowInfo: windowInfo, time: $time)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(MetalAnimationEngine.shared.isMetalAvailable ? 0.0 : 1.0)
        }
        .allowsHitTesting(false)
    }

    private func animationTypeFromString(_ string: String) -> CanvasFallbackView.AnimationType? {
        switch string {
        case "liquidBorder": return .liquidBorder
        case "flowingParticles": return .flowingParticles
        case "rippleEffect": return .rippleEffect
        case "morphingShape": return .morphingShape
        default: return nil
        }
    }
}

// MARK: - Metal View (NSViewRepresentable)
struct MetalView: NSViewRepresentable {
    let animationType: MetalAnimationView.AnimationType
    let windowInfo: AnimationWindowInfo?
    @Binding var time: Double

    func makeNSView(context: Context) -> MTKView {
        let metalView = MTKView()
        metalView.device = MetalAnimationEngine.shared.metalDevice
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 60

        // Configure for transparency
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metalView.colorPixelFormat = .bgra8Unorm

        // Disable depth/stencil
        metalView.depthStencilPixelFormat = .invalid

        context.coordinator.metalView = metalView
        context.coordinator.animationType = animationType
        context.coordinator.windowInfo = windowInfo

        // Start rendering loop
        metalView.delegate = context.coordinator

        return metalView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.animationType = animationType
        context.coordinator.windowInfo = windowInfo

        // Trigger redraw
        nsView.setNeedsDisplay(nsView.bounds)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(time: $time)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        var metalView: MTKView?
        var animationType: MetalAnimationView.AnimationType = .liquidBorder
        var windowInfo: AnimationWindowInfo?
        @Binding var time: Double

        private let engine = MetalAnimationEngine.shared

        init(time: Binding<Double>) {
            self._time = time
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable else { return }

            // Update animation time
            let currentTime = Float(time)

            // Get current drawable texture
            let texture = drawable.texture

            // Render based on animation type
            switch animationType {
            case .liquidBorder:
                renderLiquidBorder(to: texture, time: currentTime, in: view)

            case .flowingParticles:
                renderFlowingParticles(to: texture, time: currentTime, in: view)

            case .rippleEffect:
                renderRippleEffect(to: texture, time: currentTime, in: view)

            case .morphingShape:
                renderMorphingShape(to: texture, time: currentTime, in: view)
            }

            // Present drawable
            drawable.present()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            // Handle resize if needed
        }

        private func renderLiquidBorder(to texture: MTLTexture, time: Float, in view: MTKView) {
            let isActive = windowInfo?.isFocused ?? false
            let bounds = view.bounds

            // Default blue color with some transparency
            let color = SIMD4<Float>(0.3, 0.6, 1.0, 0.4)

            engine.renderLiquidBorder(to: texture,
                                    time: time,
                                    bounds: bounds,
                                    isActive: isActive,
                                    color: color)
        }

        private func renderFlowingParticles(to texture: MTLTexture, time: Float, in view: MTKView) {
            // Generate particles for this frame
            let particles = generateParticles(for: view.bounds.size, time: time, count: 15)

            engine.renderParticles(to: texture,
                                 particles: particles,
                                 time: time,
                                 viewportSize: view.bounds.size)
        }

        private func renderRippleEffect(to texture: MTLTexture, time: Float, in view: MTKView) {
            guard let focusPoint = windowInfo?.focusPoint else { return }

            let ripple = RippleUniforms(
                center: SIMD2<Float>(Float(focusPoint.x), Float(focusPoint.y)),
                radius: Float(time * 100.0), // Expanding radius
                strength: max(0.0, 1.0 - time * 0.5), // Fading strength
                color: SIMD4<Float>(0.5, 0.8, 1.0, 0.6)
            )

            engine.renderRipples(to: texture,
                               ripples: [ripple],
                               time: time,
                               viewportSize: view.bounds.size)
        }

        private func renderMorphingShape(to texture: MTLTexture, time: Float, in view: MTKView) {
            // This would require additional shader work - for now, fall back to liquid border
            renderLiquidBorder(to: texture, time: time, in: view)
        }

        private func generateParticles(for size: CGSize, time: Float, count: Int) -> [ParticleUniforms] {
            var particles: [ParticleUniforms] = []

            for i in 0..<count {
                let t = Float(i) / Float(count)

                // Create flowing motion
                let x = cos(time * 0.5 + t * 6.28) * Float(size.width) * 0.3 + Float(size.width) * 0.5
                let y = sin(time * 0.7 + t * 6.28) * Float(size.height) * 0.3 + Float(size.height) * 0.5

                let particle = ParticleUniforms(
                    position: SIMD2<Float>(x, y),
                    velocity: SIMD2<Float>(
                        cos(time + t * 6.28) * 20,
                        sin(time + t * 6.28) * 20
                    ),
                    color: SIMD4<Float>(
                        0.3 + sin(time + t) * 0.2,  // Red
                        0.6 + cos(time + t) * 0.2,  // Green
                        1.0,                        // Blue
                        0.6                         // Alpha
                    ),
                    size: 4.0 + sin(time * 2 + t * 6.28) * 2.0,
                    life: 1.0
                )

                particles.append(particle)
            }

            return particles
        }
    }
}

// MARK: - Shared Types
// AnimationWindowInfo is defined in AnimationTypes.swift

// MARK: - Preview Provider
struct MetalAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)

            MetalAnimationView(
                animationType: .liquidBorder,
                windowInfo: AnimationWindowInfo(id: 1, isFocused: true, focusPoint: nil, morphProgress: 0.5),
                time: .constant(0.0)
            )
            .frame(width: 200, height: 150)
            .border(Color.red, width: 1)
        }
        .frame(width: 300, height: 200)
        .previewDisplayName("Liquid Border Animation")
    }
}
