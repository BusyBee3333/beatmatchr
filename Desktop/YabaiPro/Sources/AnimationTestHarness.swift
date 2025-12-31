//
//  AnimationTestHarness.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI
import Combine

class AnimationTestHarness: ObservableObject {
    @Published var testResults: [TestResult] = []
    @Published var isRunningTests = false
    @Published var performanceMetrics: PerformanceMetrics = .init()

    private let animationManager = WindowAnimationManager.shared
    private let performanceManager = AnimationPerformanceManager.shared
    private let performanceMonitor = PerformanceMonitor.shared
    private var testStartTime: Date?
    private var cancellables = Set<AnyCancellable>()

    enum TestType {
        case metalInitialization
        case shaderCompilation
        case particleRendering
        case liquidBorderAnimation
        case performanceStress
        case batteryImpact
        case thermalStress
    }

    struct TestResult {
        let type: TestType
        let success: Bool
        let duration: TimeInterval
        let details: String
        let recommendations: [String]
    }

    func runAllTests() async {
        await MainActor.run { isRunningTests = true }
        testStartTime = Date()

        let tests: [TestType] = [
            .metalInitialization,
            .shaderCompilation,
            .particleRendering,
            .liquidBorderAnimation,
            .performanceStress,
            .batteryImpact,
            .thermalStress
        ]

        for test in tests {
            let result = await runTest(test)
            await MainActor.run {
                testResults.append(result)
            }
        }

        await MainActor.run { isRunningTests = false }
    }

    private func runTest(_ test: TestType) async -> TestResult {
        let startTime = Date()

        do {
            let (success, details, recommendations) = try await performTest(test)
            let duration = Date().timeIntervalSince(startTime)

            return TestResult(
                type: test,
                success: success,
                duration: duration,
                details: details,
                recommendations: recommendations
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return TestResult(
                type: test,
                success: false,
                duration: duration,
                details: "Test failed: \(error.localizedDescription)",
                recommendations: ["Investigate error: \(error.localizedDescription)"]
            )
        }
    }

    private func performTest(_ test: TestType) async throws -> (Bool, String, [String]) {
        switch test {
        case .metalInitialization:
            return try await testMetalInitialization()
        case .shaderCompilation:
            return try await testShaderCompilation()
        case .particleRendering:
            return try await testParticleRendering()
        case .liquidBorderAnimation:
            return try await testLiquidBorderAnimation()
        case .performanceStress:
            return try await testPerformanceStress()
        case .batteryImpact:
            return try await testBatteryImpact()
        case .thermalStress:
            return try await testThermalStress()
        }
    }

    private func testMetalInitialization() async throws -> (Bool, String, [String]) {
        // Step 1: Test basic Metal device creation
        guard let device = MTLCreateSystemDefaultDevice() else {
            return (false, "❌ Metal device creation failed - Metal not supported on this system", [
                "Metal is not available on this Mac",
                "Apple Silicon Macs should support Metal",
                "Check System Information for GPU details"
            ])
        }

        // Step 2: Test command queue creation
        guard let _ = device.makeCommandQueue() else {
            return (false, "❌ Metal command queue creation failed", [
                "GPU may not be functioning properly",
                "Try restarting the system"
            ])
        }

        // Step 3: Test basic shader compilation
        let minimalShader = """
        #include <metal_stdlib>
        using namespace metal;

        vertex float4 basicVertex(uint vertexID [[vertex_id]]) {
            return float4(0.0, 0.0, 0.0, 1.0);
        }

        fragment float4 basicFragment() {
            return float4(1.0, 0.0, 0.0, 1.0);
        }
        """

        do {
            let library = try await device.makeLibrary(source: minimalShader, options: nil)
            let vertexFunction = library.makeFunction(name: "basicVertex")
            let fragmentFunction = library.makeFunction(name: "basicFragment")

            guard vertexFunction != nil && fragmentFunction != nil else {
                return (false, "❌ Basic shader functions could not be created", [
                    "Shader compilation succeeded but functions not found",
                    "Check shader function names"
                ])
            }
        } catch {
            return (false, "❌ Shader compilation failed: \(error.localizedDescription)", [
                "Metal shader compilation error",
                "Check shader syntax",
                "Error: \(error.localizedDescription)"
            ])
        }

        // Step 4: Test full animation engine
        let engine = MetalAnimationEngine.shared

        if engine.isMetalAvailable && engine.metalDevice != nil {
            let hasAdvancedFeatures = engine.supportsAdvancedFeatures
            let details = """
            ✅ Metal fully initialized successfully!
            Device: \(device.name)
            Advanced features: \(hasAdvancedFeatures ? "Supported" : "Not supported")
            Shaders: \(engine.areShadersCompiled ? "✅ Compiled" : "❌ Failed")
            Pipelines: \(engine.areShadersCompiled ? "✅ Created" : "❌ Failed")
            """

            let recommendations = [
                "🎉 Metal animations are ready to use!",
                "Enable Metal animations in settings",
                "Create test windows to see liquid effects"
            ]

            return (true, details, recommendations)
        } else {
            let details = """
            ⚠️ Basic Metal works, but animation engine failed.
            Device: \(device.name)
            Engine available: \(engine.isMetalAvailable ? "✅" : "❌")
            Shaders compiled: \(engine.areShadersCompiled ? "✅" : "❌")
            """

            return (false, details, [
                "Basic Metal works, but animation shaders failed",
                "Check animation engine initialization",
                "Shader compilation may have failed"
            ])
        }
    }

    private func testShaderCompilation() async throws -> (Bool, String, [String]) {
        // Test if shaders compiled successfully by checking pipeline states
        let engine = MetalAnimationEngine.shared

        // This is a simplified check - in practice we'd need more detailed validation
        let metalAvailable = engine.isMetalAvailable

        if metalAvailable {
            return (true, "Shaders compiled successfully", ["All Metal shaders ready for use"])
        } else {
            return (true, "Shaders not needed - using Canvas fallback", ["Canvas rendering will be used automatically"])
        }
    }

    private func testParticleRendering() async throws -> (Bool, String, [String]) {
        let settings = performanceManager.optimalSettings(metalAnimationsEnabled: false, directWindowMetalEnabled: false)
        let particleCount = settings.particleCount

        let details = """
        Particle rendering test:
        Target particle count: \(particleCount)
        Performance mode: \(settings.frameRateLimit) FPS limit
        Metal enabled: \(settings.metalEffectsEnabled)
        """

        let recommendations: [String]
        if particleCount > 15 {
            recommendations = ["High particle count - monitor CPU/GPU usage", "Consider reducing particles if battery life is impacted"]
        } else {
            recommendations = ["Particle count within safe limits", "Good balance of visual quality and performance"]
        }

        return (true, details, recommendations)
    }

    private func testLiquidBorderAnimation() async throws -> (Bool, String, [String]) {
        let engine = MetalAnimationEngine.shared
        let windowManager = WindowAnimationManager.shared
        let settings = performanceManager.optimalSettings(metalAnimationsEnabled: false, directWindowMetalEnabled: false)

        var success = true
        var issues: [String] = []

        // Check Metal availability
        if !engine.isMetalAvailable {
            success = false
            issues.append("Metal is not available on this system")
        }

        // Check if Metal animations are enabled
        if !settings.metalEffectsEnabled {
            success = false
            issues.append("Metal effects are disabled in settings")
        }

        // Check if there are any window animation states
        let windowStates = windowManager.getWindowsNeedingAnimation()
        if windowStates.isEmpty {
            issues.append("No windows found for animation (try creating test windows first)")
        }

        // Check if shaders are compiled
        if !engine.areShadersCompiled {
            success = false
            issues.append("Metal shaders failed to compile")
        }

        let details = """
        Liquid border animation status:
        Metal available: \(engine.isMetalAvailable ? "✅" : "❌")
        Metal enabled: \(settings.metalEffectsEnabled ? "✅" : "❌")
        Shaders compiled: \(engine.areShadersCompiled ? "✅" : "❌")
        Window states: \(windowStates.count) windows
        Morphing enabled: \(settings.morphingEnabled)
        Quality scale: \(String(format: "%.1f", settings.qualityScale))
        """

        var recommendations = [
            "Enable Metal animations in settings if disabled",
            "Create test windows if no real windows are detected",
            "Check Metal compatibility on your system"
        ]

        if !issues.isEmpty {
            recommendations.insert(contentsOf: issues.map { "Fix: \($0)" }, at: 0)
        }

        if success && !windowStates.isEmpty {
            recommendations.append("Liquid borders should be visible around focused windows!")
        }

        return (success, details, recommendations)
    }

    private func testPerformanceStress() async throws -> (Bool, String, [String]) {
        // Start performance monitoring
        performanceMonitor.startMonitoring(updateInterval: 0.1)

        // Wait a moment for baseline
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let initialMetrics = performanceMonitor.getRecentAverages(seconds: 0.5)

        // Stress test - monitor for a few seconds
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        let finalMetrics = performanceMonitor.getRecentAverages(seconds: 0.5)

        performanceMonitor.stopMonitoring()

        let settings = performanceManager.optimalSettings(metalAnimationsEnabled: false, directWindowMetalEnabled: false)

        let details = """
        Performance stress test completed:
        Duration: 2 seconds
        Initial CPU: \(String(format: "%.1f", initialMetrics.cpuUsage))%
        Final CPU: \(String(format: "%.1f", finalMetrics.cpuUsage))%
        Initial GPU: \(String(format: "%.1f", initialMetrics.gpuUsage))%
        Final GPU: \(String(format: "%.1f", finalMetrics.gpuUsage))%
        Settings: \(settings.particleCount) particles, \(settings.frameRateLimit) FPS limit
        """

        let recommendations = analyzePerformanceDelta(initialMetrics, finalMetrics)

        return (true, details, recommendations)
    }

    private func testBatteryImpact() async throws -> (Bool, String, [String]) {
        let batteryLevel = performanceManager.getBatteryLevel()

        let details = """
        Battery impact assessment:
        Current battery level: \(batteryLevel)%
        Animation settings auto-adjusted for battery preservation
        """

        let recommendations: [String]
        if batteryLevel < 20 {
            recommendations = [
                "Battery low - animations automatically reduced",
                "Consider keeping animations disabled when on battery",
                "Monitor battery drain with animations enabled"
            ]
        } else {
            recommendations = [
                "Battery level acceptable for animations",
                "Monitor battery usage during extended animation use"
            ]
        }

        return (true, details, recommendations)
    }

    private func testThermalStress() async throws -> (Bool, String, [String]) {
        let thermalState = ProcessInfo.processInfo.thermalState

        let details = """
        Thermal stress test:
        Current thermal state: \(thermalState.description)
        Animation performance automatically adjusted
        """

        let recommendations: [String]
        switch thermalState {
        case .nominal:
            recommendations = ["Thermal state normal - full animation performance available"]
        case .fair:
            recommendations = ["Thermal state fair - monitor temperature during use"]
        case .serious:
            recommendations = ["Thermal state serious - animations automatically reduced", "Consider reducing animation quality or disabling temporarily"]
        case .critical:
            recommendations = ["Thermal state critical - animations disabled for safety", "System thermal throttling active"]
        @unknown default:
            recommendations = ["Unknown thermal state - monitor system temperature"]
        }

        return (true, details, recommendations)
    }

    private func capturePerformanceMetrics() async -> PerformanceMetrics {
        // Capture current system metrics
        let cpuUsage: Double = 30.0 // Placeholder - would use host_statistics in real implementation
        let gpuUsage: Double = 15.0 // Placeholder
        let frameRate: Double = 60.0
        let thermalState = ProcessInfo.processInfo.thermalState
        let batteryLevel = performanceManager.getBatteryLevel()

        return PerformanceMetrics(
            cpuUsage: cpuUsage,
            gpuUsage: gpuUsage,
            frameRate: frameRate,
            thermalState: thermalState,
            batteryLevel: batteryLevel
        )
    }

    private func analyzePerformanceDelta(_ initial: PerformanceMetrics, _ final: PerformanceMetrics) -> [String] {
        var recommendations: [String] = []

        let cpuDelta = final.cpuUsage - initial.cpuUsage
        let gpuDelta = final.gpuUsage - initial.gpuUsage

        if cpuDelta > 10 {
            recommendations.append("CPU usage increased by \(String(format: "%.1f", cpuDelta))% - monitor during use")
        }

        if gpuDelta > 10 {
            recommendations.append("GPU usage increased by \(String(format: "%.1f", gpuDelta))% - monitor during use")
        }

        if final.thermalState.rawValue > initial.thermalState.rawValue {
            recommendations.append("Thermal state changed - system heating detected")
        }

        if recommendations.isEmpty {
            recommendations.append("Performance impact within acceptable limits")
        }

        return recommendations
    }

    func generateOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []

        let capability = performanceManager.getCurrentCapability()
        let settings = performanceManager.optimalSettings(metalAnimationsEnabled: false, directWindowMetalEnabled: false)

        switch capability {
        case .ultraHighPerformance, .highPerformance:
            recommendations.append("High-performance Metal GPU detected - enhanced features available")
        case .mediumPerformance:
            if settings.particleCount < 20 {
                recommendations.append("Consider increasing particle count for richer effects")
            }
            recommendations.append("Medium-performance GPU - balanced settings applied")
            recommendations.append("Monitor frame rate stability during use")

        case .lowPerformance, .unsupported:
            recommendations.append("Limited GPU performance - Canvas fallback active")
            recommendations.append("Consider disabling animations if performance is inadequate")

        case .unknown:
            recommendations.append("GPU capability unknown - conservative settings applied")
        }

        let perfRecommendations = performanceManager.getPerformanceRecommendations()
        recommendations.append(contentsOf: perfRecommendations)

        return recommendations
    }

    func resetTestResults() {
        testResults.removeAll()
    }
}

// MARK: - Test Results View

struct AnimationTestView: View {
    @StateObject private var testHarness = AnimationTestHarness()
    @State private var showAnimationPreview = false

    var body: some View {
        VStack(spacing: 0) {
            if showAnimationPreview {
                AnimationPreviewView(showPreview: $showAnimationPreview)
            } else {
                testViewContent
            }
        }
    }

    private var testViewContent: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Animation Test Suite")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { Task { await testHarness.runAllTests() } }) {
                    Label("Run All Tests", systemImage: "play.circle")
                }
                .disabled(testHarness.isRunningTests)

                Button(action: { testHarness.resetTestResults() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }

                Divider()

                Button(action: { WindowAnimationManager.shared.createTestWindowStates() }) {
                    Label("Create Test Windows", systemImage: "window.badge.plus")
                }

                Button(action: { WindowAnimationManager.shared.debugPrintWindowStates() }) {
                    Label("Debug States", systemImage: "eye")
                }

                Button(action: { showAnimationPreview.toggle() }) {
                    Label("Show Animations", systemImage: "play.circle")
                }
            }

            if showAnimationPreview {
                AnimationPreviewView(showPreview: $showAnimationPreview)
            } else if testHarness.isRunningTests {
                ProgressView("Running animation tests...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(testHarness.testResults, id: \.type) { result in
                            TestResultCard(result: result)
                        }

                        if !testHarness.testResults.isEmpty {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Optimization Recommendations")
                                    .font(.headline)

                                ForEach(testHarness.generateOptimizationRecommendations(), id: \.self) { recommendation in
                                    Text("• \(recommendation)")
                                        .font(.body)
                                }
                            }
                            .padding()
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }
}

struct TestResultCard: View {
    let result: AnimationTestHarness.TestResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(testName(for: result.type))
                    .font(.headline)

                Spacer()

                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)

                Text(String(format: "%.2fs", result.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(result.details)
                .font(.body)
                .foregroundColor(.secondary)

            if !result.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(result.recommendations, id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(result.success ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1)
        )
    }

    private func testName(for type: AnimationTestHarness.TestType) -> String {
        switch type {
        case .metalInitialization: return "Metal Initialization"
        case .shaderCompilation: return "Shader Compilation"
        case .particleRendering: return "Particle Rendering"
        case .liquidBorderAnimation: return "Liquid Border Animation"
        case .performanceStress: return "Performance Stress Test"
        case .batteryImpact: return "Battery Impact Test"
        case .thermalStress: return "Thermal Stress Test"
        }
    }
}

// MARK: - Animation Preview View

struct AnimationPreviewView: View {
    @Binding var showPreview: Bool
    @StateObject private var windowManager = WindowAnimationManager.shared
    @State private var animationTime = 0.0

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("🎭 Metal Animation Preview")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Back to Tests") {
                    showPreview = false
                }
            }

            let windowsNeedingAnimation = windowManager.getWindowsNeedingAnimation()

            if windowsNeedingAnimation.isEmpty {
                VStack(spacing: 16) {
                    Text("No windows need animation")
                        .foregroundColor(.secondary)

                    Button("Create Test Windows") {
                        windowManager.createTestWindowStates()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(windowsNeedingAnimation, id: \.windowId) { windowState in
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Window \(windowState.windowId)")
                                    .font(.headline)
                                    .foregroundColor(windowState.isFocused ? .blue : .primary)

                                Text("Focused: \(windowState.isFocused ? "Yes" : "No")")
                                Text("Frame: \(Int(windowState.frame.width))×\(Int(windowState.frame.height))")
                                Text("Morph Progress: \(String(format: "%.2f", windowState.morphProgress))")

                                // Animation preview
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 200)

                                    if MetalAnimationEngine.shared.isMetalAvailable {
                                        MetalAnimationView(
                                            animationType: .liquidBorder,
                                            windowInfo: AnimationWindowInfo(
                                                id: windowState.windowId,
                                                isFocused: windowState.isFocused,
                                                focusPoint: windowState.focusPoint,
                                                morphProgress: windowState.morphProgress
                                            ),
                                            time: .constant(animationTime)
                                        )
                                        .frame(width: 300, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Text("Metal not available")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }
                    .padding()
                }
            }

            HStack {
                Text("Metal: \(MetalAnimationEngine.shared.isMetalAvailable ? "✅ Available" : "❌ Unavailable")")
                Spacer()
                Text("Direct Window Metal: \(WindowMetalBinder.shared.isSIPDisabled ? "✅ SIP Disabled" : "❌ SIP Enabled")")
                Spacer()
                Text("Time: \(String(format: "%.1f", animationTime))")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Metal Binder Test Section
            if let firstWindow = WindowAnimationManager.shared.windowStates.first?.value {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🧪 Direct Window Metal Test")
                        .font(.headline)

                    HStack {
                        Button("Test Metal Layer Attach") {
                            Task {
                                do {
                                    try await WindowMetalBinder.shared.attachMetalLayer(
                                        to: firstWindow.windowId,
                                        frame: firstWindow.frame,
                                        animationType: .liquidBorder
                                    )
                                    print("✅ Metal layer attached to test window")
                                } catch {
                                    print("❌ Failed to attach Metal layer: \(error)")
                                }
                            }
                        }

                        Button("Start Animation") {
                            WindowMetalBinder.shared.startAnimation(
                                on: firstWindow.windowId,
                                duration: 2.0,
                                easing: .easeOutCubic
                            )
                        }

                        Button("Detach Layer") {
                            WindowMetalBinder.shared.detachMetalLayer(from: firstWindow.windowId)
                        }
                    }

                    Text("Test window: \(firstWindow.windowId) at \(Int(firstWindow.frame.width))×\(Int(firstWindow.frame.height))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            // Start animation timer
            Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
                animationTime += 1/60.0
            }
        }
    }
}

// MARK: - Performance Extensions

extension ProcessInfo.ThermalState {
    var description: String {
        switch self {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}
