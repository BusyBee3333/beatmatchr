//
//  MetalAnimationEngine.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Metal
import MetalKit
import Foundation

class MetalAnimationEngine {
    static let shared = MetalAnimationEngine()

    // MARK: - Metal Resources
    private var device: MTLDevice?

    // MARK: - Public Accessors
    var metalDevice: MTLDevice? {
        return device
    }
    private var commandQueue: MTLCommandQueue?
    private var library: MTLLibrary?

    // MARK: - Render Pipelines
    private var liquidBorderPipeline: MTLRenderPipelineState?
    private var particlePipeline: MTLRenderPipelineState?
    private var ripplePipeline: MTLRenderPipelineState?

    // MARK: - Buffers
    private var quadVertexBuffer: MTLBuffer?
    private var particleBuffer: MTLBuffer?

    // MARK: - Initialization
    private init() {
        setupMetal()
        createPipelines()
        createBuffers()
    }

    private func setupMetal() {
        // Get default Metal device (optimized for Apple Silicon)
        device = MTLCreateSystemDefaultDevice()

        // Create command queue for GPU commands
        commandQueue = device?.makeCommandQueue()

        // Load pre-compiled shaders from bundle
        do {
            library = try device?.makeDefaultLibrary(bundle: .main)
        } catch {
            print("Failed to load Metal library: \(error)")
            library = nil
        }
    }

    private func createPipelines() {
        guard let device = device, let library = library else {
            print("Metal device or library not available")
            return
        }

        // Liquid Border Pipeline
        do {
            let liquidDescriptor = MTLRenderPipelineDescriptor()
            liquidDescriptor.vertexFunction = library.makeFunction(name: "liquidBorderVertex")
            liquidDescriptor.fragmentFunction = library.makeFunction(name: "liquidBorderFragment")
            liquidDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            liquidDescriptor.colorAttachments[0].isBlendingEnabled = true
            liquidDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            liquidDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

            liquidBorderPipeline = try device.makeRenderPipelineState(descriptor: liquidDescriptor)
        } catch {
            print("Failed to create liquid border pipeline: \(error)")
        }

        // Particle Pipeline
        do {
            let particleDescriptor = MTLRenderPipelineDescriptor()
            particleDescriptor.vertexFunction = library.makeFunction(name: "particleVertex")
            particleDescriptor.fragmentFunction = library.makeFunction(name: "particleFragment")
            particleDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            particleDescriptor.colorAttachments[0].isBlendingEnabled = true
            particleDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            particleDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

            particlePipeline = try device.makeRenderPipelineState(descriptor: particleDescriptor)
        } catch {
            print("Failed to create particle pipeline: \(error)")
        }

        // Ripple Pipeline
        do {
            let rippleDescriptor = MTLRenderPipelineDescriptor()
            rippleDescriptor.vertexFunction = library.makeFunction(name: "rippleVertex")
            rippleDescriptor.fragmentFunction = library.makeFunction(name: "rippleFragment")
            rippleDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            rippleDescriptor.colorAttachments[0].isBlendingEnabled = true
            rippleDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            rippleDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

            ripplePipeline = try device.makeRenderPipelineState(descriptor: rippleDescriptor)
        } catch {
            print("Failed to create ripple pipeline: \(error)")
        }
    }

    private func createBuffers() {
        guard let device = device else { return }

        // Quad vertices for full-screen rendering
        let quadVertices: [Float] = [
            -1.0, -1.0,  // bottom left
             1.0, -1.0,  // bottom right
            -1.0,  1.0,  // top left
             1.0,  1.0   // top right
        ]

        quadVertexBuffer = device.makeBuffer(bytes: quadVertices,
                                            length: quadVertices.count * MemoryLayout<Float>.size,
                                            options: .storageModeShared)

        // Particle buffer (will be resized dynamically)
        particleBuffer = device.makeBuffer(length: 1000 * MemoryLayout<ParticleUniforms>.size,
                                         options: .storageModeShared)
    }

    // MARK: - Rendering Methods
    func renderLiquidBorder(to texture: MTLTexture,
                           time: Float,
                           bounds: CGRect,
                           isActive: Bool,
                           color: SIMD4<Float> = SIMD4<Float>(0.3, 0.6, 1.0, 0.8)) {
        guard let commandQueue = commandQueue,
              let pipeline = liquidBorderPipeline,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor(for: texture)) else {
            return
        }

        // Set pipeline
        encoder.setRenderPipelineState(pipeline)

        // Vertex data
        let vertices = createBorderVertices(bounds: bounds, time: time, amplitude: isActive ? 4.0 : 1.0)
        let vertexBuffer = device?.makeBuffer(bytes: vertices,
                                            length: vertices.count * MemoryLayout<Float>.size,
                                            options: .storageModeShared)

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        var mutableTime = time
        var mutableBounds = bounds
        encoder.setVertexBytes(&mutableTime, length: MemoryLayout<Float>.size, index: 1)
        encoder.setVertexBytes(&mutableBounds, length: MemoryLayout<CGRect>.size, index: 2)

        // Fragment uniforms
        var uniforms = LiquidBorderUniforms(time: time, amplitude: isActive ? 4.0 : 1.0, color: color)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<LiquidBorderUniforms>.size, index: 0)

        // Draw
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count / 2)
        encoder.endEncoding()

        commandBuffer.commit()
    }

    func renderParticles(to texture: MTLTexture,
                        particles: [ParticleUniforms],
                        time: Float,
                        viewportSize: CGSize) {
        guard let commandQueue = commandQueue,
              let pipeline = particlePipeline,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor(for: texture)),
              let particleBuffer = particleBuffer else {
            return
        }

        // Update particle buffer
        if particles.count * MemoryLayout<ParticleUniforms>.size <= particleBuffer.length {
            memcpy(particleBuffer.contents(), particles, particles.count * MemoryLayout<ParticleUniforms>.size)
        }

        encoder.setRenderPipelineState(pipeline)
        encoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        var mutableTime = time
        var mutableViewportSize = viewportSize
        encoder.setVertexBytes(&mutableTime, length: MemoryLayout<Float>.size, index: 1)
        encoder.setVertexBytes(&mutableViewportSize, length: MemoryLayout<CGSize>.size, index: 2)

        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)
        encoder.endEncoding()

        commandBuffer.commit()
    }

    func renderRipples(to texture: MTLTexture,
                      ripples: [RippleUniforms],
                      time: Float,
                      viewportSize: CGSize) {
        guard let commandQueue = commandQueue,
              let pipeline = ripplePipeline,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor(for: texture)) else {
            return
        }

        encoder.setRenderPipelineState(pipeline)

        for ripple in ripples {
            let currentRipple = ripple
            var mutableRipple = currentRipple
            var mutableTime = time
            var mutableViewportSize = viewportSize
            encoder.setVertexBytes(&mutableRipple, length: MemoryLayout<RippleUniforms>.size, index: 0)
            encoder.setVertexBytes(&mutableTime, length: MemoryLayout<Float>.size, index: 1)
            encoder.setVertexBytes(&mutableViewportSize, length: MemoryLayout<CGSize>.size, index: 2)

            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        encoder.endEncoding()
        commandBuffer.commit()
    }

    // MARK: - Helper Methods
    private func createBorderVertices(bounds: CGRect, time: Float, amplitude: Float) -> [Float] {
        var vertices: [Float] = []
        let segments = 32  // Higher for smoother curves
        let borderWidth: Float = 3.0

        for i in 0...segments {
            let t = Float(i) / Float(segments)
            let x = Float(bounds.minX) + t * Float(bounds.width)
            let baseY = Float(bounds.minY)

            // Create flowing wave
            let wave = sinf(t * 6.28 + time * 2.0) * amplitude

            // Outer vertex
            vertices.append(x)
            vertices.append(baseY + wave)

            // Inner vertex (offset inward)
            vertices.append(x)
            vertices.append(baseY + wave + borderWidth)
        }

        return vertices
    }

    private func renderPassDescriptor(for texture: MTLTexture) -> MTLRenderPassDescriptor {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = texture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        descriptor.colorAttachments[0].storeAction = .store
        return descriptor
    }

    // MARK: - Capability Checking
    var isMetalAvailable: Bool {
        return device != nil && library != nil
    }

    var supportsAdvancedFeatures: Bool {
        guard let device = device else { return false }
        return device.supportsFeatureSet(.macOS_GPUFamily2_v1)
    }
}

// MARK: - Uniform Structures
struct LiquidBorderUniforms {
    var time: Float
    var amplitude: Float
    var color: SIMD4<Float>
}

struct ParticleUniforms {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var color: SIMD4<Float>
    var size: Float
    var life: Float
}

struct RippleUniforms {
    var center: SIMD2<Float>
    var radius: Float
    var strength: Float
    var color: SIMD4<Float>
}
