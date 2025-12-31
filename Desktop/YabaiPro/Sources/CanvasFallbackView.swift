//
//  CanvasFallbackView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

// MARK: - Shared Types
// WindowInfo, AnimationSettings are defined in AnimationTypes.swift

struct CanvasFallbackView: View {
    let animationType: AnimationType
    let windowInfo: AnimationWindowInfo?
    @Binding var time: Double

    enum AnimationType: String {
        case liquidBorder
        case flowingParticles
        case rippleEffect
        case morphingShape
        case glowingBorder
        case energyField
    }

    var body: some View {
        Canvas { context, size in
            switch animationType {
            case .liquidBorder:
                renderLiquidBorderCanvas(context: context, size: size, time: Float(time))
            case .flowingParticles:
                renderFlowingParticlesCanvas(context: context, size: size, time: Float(time))
            case .rippleEffect:
                if let point = windowInfo?.focusPoint {
                    renderRippleEffectCanvas(context: context, size: size, time: Float(time), focusPoint: point)
                }
            case .morphingShape:
                renderMorphingShapeCanvas(context: context, size: size, time: Float(time), morphProgress: windowInfo?.morphProgress ?? 0.0)

            case .glowingBorder:
                renderGlowingBorderCanvas(context: context, size: size, time: Float(time))

            case .energyField:
                renderEnergyFieldCanvas(context: context, size: size, time: Float(time))
            }
        }
        .allowsHitTesting(false)
    }

    private func renderLiquidBorderCanvas(context: GraphicsContext, size: CGSize, time: Float) {
        let isActive = windowInfo?.isFocused ?? false
        let amplitude = isActive ? 4.0 : 1.0
        let segments = 32

        var path = Path()

        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let x = t * size.width
            let baseY: CGFloat = 0

            // Create flowing wave using sine functions
            let wave1 = sin(t * 6.28 + Double(time) * 2.0) * amplitude
            let wave2 = sin(t * 12.56 + Double(time) * 1.5) * amplitude * 0.5
            let totalWave = wave1 + wave2

            let point = CGPoint(x: x, y: baseY + totalWave)

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        // Create bottom path to close the border
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()

        // Fill with gradient
        let gradient = Gradient(colors: [
            Color.blue.opacity(isActive ? 0.6 : 0.3),
            Color.cyan.opacity(isActive ? 0.4 : 0.2),
            Color.blue.opacity(isActive ? 0.2 : 0.1)
        ])

        context.fill(path, with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        context.stroke(path, with: .color(Color.blue.opacity(isActive ? 0.8 : 0.5)), lineWidth: 2)
    }

    private func renderFlowingParticlesCanvas(context: GraphicsContext, size: CGSize, time: Float) {
        let particleCount = 15

        for i in 0..<particleCount {
            let t = Float(i) / Float(particleCount)

            // Create flowing motion
            let angle1 = time * 0.5 + t * 6.28
            let angle2 = time * 0.7 + t * 6.28 * 2

            let x = cos(angle1) * Float(size.width) * 0.3 + Float(size.width) * 0.5
            let y = sin(angle2) * Float(size.height) * 0.3 + Float(size.height) * 0.5

            let particleSize: CGFloat = 4.0 + CGFloat(sin(time * 2 + t * 6.28)) * 2.0

            // Create gradient for each particle
            let colors = [Color.blue, Color.cyan, Color.white.opacity(0.5)]
            let gradient = Gradient(colors: colors)

            let rect = CGRect(x: CGFloat(x) - particleSize/2,
                            y: CGFloat(y) - particleSize/2,
                            width: particleSize,
                            height: particleSize)

            // Draw particle with soft glow
            let path = Path(ellipseIn: rect)
            context.fill(path, with: .radialGradient(gradient, center: CGPoint(x: Double(x), y: Double(y)), startRadius: 0, endRadius: Double(particleSize/2)))

            // Add subtle outline
            context.stroke(path, with: .color(Color.blue.opacity(0.3)), lineWidth: 0.5)
        }
    }

    private func renderRippleEffectCanvas(context: GraphicsContext, size: CGSize, time: Float, focusPoint: CGPoint) {
        let rippleCount = 3
        let maxRadius = max(size.width, size.height) * 0.8

        for i in 0..<rippleCount {
            let delay = Float(i) * 0.3
            let rippleTime = time - delay

            if rippleTime > 0 {
                let radius = rippleTime * 100.0
                let alpha = max(0.0, 1.0 - Double(rippleTime) * 0.5)

                if Double(radius) < Double(maxRadius) {
                    let rect = CGRect(x: focusPoint.x - CGFloat(radius),
                                    y: focusPoint.y - CGFloat(radius),
                                    width: CGFloat(radius * 2),
                                    height: CGFloat(radius * 2))

                    let path = Path(ellipseIn: rect)

                    // Create ripple with gradient
            let colors = [Color.blue.opacity(Double(alpha) * 0.6), Color.clear]
            let gradient = Gradient(colors: colors)

            context.stroke(path, with: .radialGradient(gradient, center: focusPoint, startRadius: CGFloat(radius * 0.8), endRadius: CGFloat(radius)))
                }
            }
        }
    }

    private func renderMorphingShapeCanvas(context: GraphicsContext, size: CGSize, time: Float, morphProgress: Double) {
        let center = CGPoint(x: size.width/2, y: size.height/2)
        let baseRadius = min(size.width, size.height) * 0.3
        let morphFactor = Float(morphProgress)

        var path = Path()

        // Create morphing shape with organic curves
        let segments = 16
        for i in 0..<segments {
            let angle = (Float(i) / Float(segments)) * 2 * .pi
            let wave1 = sin(angle * 3 + time * 2) * morphFactor * 20
            let wave2 = cos(angle * 5 + time * 1.5) * morphFactor * 10

            let radius = baseRadius + CGFloat(wave1 + wave2)
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius

            let point = CGPoint(x: x, y: y)

            if i == 0 {
                path.move(to: point)
            } else {
                // Create smooth curves
                let prevAngle = (Float(i-1) / Float(segments)) * 2 * .pi
                let prevWave1 = sin(prevAngle * 3 + time * 2) * morphFactor * 20
                let prevWave2 = cos(prevAngle * 5 + time * 1.5) * morphFactor * 10
                let prevRadius = baseRadius + CGFloat(prevWave1 + prevWave2)
                let prevX = center.x + CGFloat(cos(prevAngle)) * prevRadius
                let prevY = center.y + CGFloat(sin(prevAngle)) * prevRadius

                let controlX = (prevX + x) / 2
                let controlY = (prevY + y) / 2

                path.addQuadCurve(to: point, control: CGPoint(x: controlX, y: controlY))
            }
        }

        path.closeSubpath()

        // Fill with animated gradient
        let colors = [
            Color.blue.opacity(0.6 + Double(morphFactor) * 0.4),
            Color.purple.opacity(0.4 + Double(morphFactor) * 0.6),
            Color.cyan.opacity(0.3 + Double(morphFactor) * 0.7)
        ]
        let gradient = Gradient(colors: colors)

        context.fill(path, with: .radialGradient(gradient, center: center, startRadius: 0, endRadius: baseRadius * 2))

        // Add subtle border
        context.stroke(path, with: .color(Color.white.opacity(0.3)), lineWidth: 1)
    }

    private func renderGlowingBorderCanvas(context: GraphicsContext, size: CGSize, time: Float) {
        let isActive = windowInfo?.isFocused ?? false
        let amplitude = isActive ? 6.0 : 2.0
        let segments = 64  // More segments for smoother glow

        var path = Path()
        let pulse = sin(time * 4.0) * 0.3 + 0.7  // Pulsing intensity

        for i in 0...segments {
            let t = Double(i) / Double(segments)
            let x = t * size.width
            let baseY: CGFloat = 0

            // Create flowing wave with enhanced amplitude for glow effect
            let wave1 = sin(t * 6.28 + Double(time) * 2.0) * amplitude
            let wave2 = sin(t * 12.56 + Double(time) * 1.5) * amplitude * 0.5
            let totalWave = wave1 + wave2

            let point = CGPoint(x: x, y: baseY + totalWave)

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        // Create bottom path to close the border
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()

        // Glowing gradient with pulsing
        let alpha = isActive ? Double(pulse) * 0.9 : Double(pulse) * 0.6
        let gradient = Gradient(colors: [
            Color.cyan.opacity(alpha),
            Color.blue.opacity(alpha * 0.7),
            Color.white.opacity(alpha * 0.3)
        ])

        context.fill(path, with: .linearGradient(gradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
        context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: 2)
    }

    private func renderEnergyFieldCanvas(context: GraphicsContext, size: CGSize, time: Float) {
        // Combine liquid border with energy particles
        renderGlowingBorderCanvas(context: context, size: size, time: time)

        // Add energy particles
        let particleCount = 20
        for i in 0..<particleCount {
            let t = Float(i) / Float(particleCount)

            // Chaotic energy motion
            let angle1 = time * 1.2 + t * 6.28 * 2
            let angle2 = time * 0.8 + t * 6.28 * 3

            let x = cos(angle1) * Float(size.width) * 0.4 + Float(size.width) * 0.5
            let y = sin(angle2) * Float(size.height) * 0.4 + Float(size.height) * 0.5

            let particleSize: CGFloat = 3.0 + CGFloat(sin(time * 4 + t * 6.28)) * 3.0

            let rect = CGRect(x: CGFloat(x) - particleSize/2,
                            y: CGFloat(y) - particleSize/2,
                            width: particleSize,
                            height: particleSize)

            let path = Path(ellipseIn: rect)

            // Electric blue energy particles
            let colors = [Color.white, Color.cyan.opacity(0.8), Color.blue.opacity(0.6)]
            let gradient = Gradient(colors: colors)

            context.fill(path, with: .radialGradient(gradient, center: CGPoint(x: Double(x), y: Double(y)), startRadius: 0, endRadius: Double(particleSize/2)))
        }
    }
}

// MARK: - Shared Types
// WindowInfo and AnimationSettings are defined in AnimationTypes.swift
