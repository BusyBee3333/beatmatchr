//
//  AnimationPerformanceManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation
import IOKit.ps
import Metal

class AnimationPerformanceManager {
    static let shared = AnimationPerformanceManager()

    private var performanceMode: PerformanceMode = .auto
    private var metalCapability: MetalCapability = .unknown
    private var lastAssessmentTime: Date = Date.distantPast
    private var assessmentCacheTime: TimeInterval = 30.0 // Cache for 30 seconds

enum MetalCapability {
    case ultraHighPerformance, highPerformance, mediumPerformance, lowPerformance, unsupported, unknown
}

enum PerformanceMode {
    case auto, ultra, high, medium, low, minimal
}

    private init() {
        assessMetalCapability()
    }

    func optimalSettings(metalAnimationsEnabled: Bool = false, directWindowMetalEnabled: Bool = false) -> AnimationSettings {
        // Re-assess if cache is stale
        if Date().timeIntervalSince(lastAssessmentTime) > assessmentCacheTime {
            assessMetalCapability()
            lastAssessmentTime = Date()
        }

        let batteryLevel = getBatteryLevel()
        let thermalState = ProcessInfo.processInfo.thermalState
        let cpuUsage = getCPUUsage()

        // Auto mode logic
        if performanceMode == .auto {
            var settings = AnimationSettings.default

            // Check UI settings first - if Metal is disabled in UI, don't enable it
            let canUseMetal = metalAnimationsEnabled

            // Battery considerations
            if batteryLevel < 20 {
                settings.particleCount = min(settings.particleCount, 5)
                settings.metalEffectsEnabled = false
                settings.frameRateLimit = 30
            }

            // Thermal considerations
            if thermalState == .critical {
                settings.particleCount = 0
                settings.metalEffectsEnabled = false
                settings.frameRateLimit = 15
            } else if thermalState == .serious {
                settings.particleCount = min(settings.particleCount, 8)
                settings.frameRateLimit = 30
            }

            // CPU usage considerations
            if cpuUsage > 80 {
                settings.particleCount = min(settings.particleCount, 10)
                settings.frameRateLimit = 30
            }

            // Metal capability considerations - only enable if UI allows it
            if canUseMetal {
                switch metalCapability {
                case .ultraHighPerformance, .highPerformance:
                    // High-performance Metal GPU - enable enhanced features
                    settings.metalEffectsEnabled = true
                    settings.particleCount = 20
                    settings.frameRateLimit = 120
                case .mediumPerformance:
                    // Medium performance - still enable Metal but reduce particles
                    settings.metalEffectsEnabled = true
                    settings.particleCount = min(settings.particleCount, 12)
                    settings.frameRateLimit = 60
                case .lowPerformance:
                    // Low performance - enable Metal with minimal effects
                    settings.metalEffectsEnabled = true
                    settings.particleCount = min(settings.particleCount, 5)
                    settings.frameRateLimit = 30
                case .unsupported:
                    // No Metal support - fall back to Canvas
                    settings.metalEffectsEnabled = false
                    settings.fallbackToCanvas = true
                case .unknown:
                    // Unknown performance - enable Metal optimistically but only if UI allows
                    settings.metalEffectsEnabled = false // Conservative approach - don't enable unknown Metal
                    settings.particleCount = min(settings.particleCount, 8)
                }
            } else {
                // Metal animations disabled in UI
                settings.metalEffectsEnabled = false
                settings.fallbackToCanvas = true
            }

            return settings

        } else {
            // Manual mode - return preset for selected performance mode
            return settingsForMode(performanceMode)
        }
    }

    func setPerformanceMode(_ mode: PerformanceMode) {
        performanceMode = mode
    }

    private func settingsForMode(_ mode: PerformanceMode) -> AnimationSettings {
        switch mode {
        case .auto:
            // Auto mode returns the optimal settings based on current conditions
            return optimalSettings()

        case .ultra:
            return AnimationSettings(
                metalEffectsEnabled: true,
                particleCount: 25,
                rippleCount: 5,
                morphingEnabled: true,
                gradientsEnabled: true,
                frameRateLimit: 60,
                qualityScale: 1.0
            )

        case .high:
            return AnimationSettings(
                metalEffectsEnabled: true,
                particleCount: 15,
                rippleCount: 3,
                morphingEnabled: true,
                gradientsEnabled: true,
                frameRateLimit: 60,
                qualityScale: 0.9
            )

        case .medium:
            return AnimationSettings(
                metalEffectsEnabled: true,
                particleCount: 8,
                rippleCount: 2,
                morphingEnabled: false,
                gradientsEnabled: true,
                frameRateLimit: 45,
                qualityScale: 0.7
            )

        case .low:
            return AnimationSettings(
                metalEffectsEnabled: false,
                particleCount: 3,
                rippleCount: 1,
                morphingEnabled: false,
                gradientsEnabled: false,
                frameRateLimit: 30,
                qualityScale: 0.5
            )

        case .minimal:
            return AnimationSettings(
                metalEffectsEnabled: false,
                particleCount: 0,
                rippleCount: 0,
                morphingEnabled: false,
                gradientsEnabled: false,
                frameRateLimit: 15,
                qualityScale: 0.3
            )
        }
    }

    private func assessMetalCapability() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            metalCapability = .unsupported
            return
        }

        // Check GPU family support
        let hasFeatureSet1 = device.supportsFamily(.apple1)
        let hasFeatureSet2 = device.supportsFamily(.apple2)

        // Enhanced Metal 2.0 capabilities (no Metal 3 on macOS 12)

        // Check memory and performance characteristics
        let recommendedMaxWorkingSet = device.recommendedMaxWorkingSetSize
        let hasUnifiedMemory = device.hasUnifiedMemory

        // Determine capability level
        if hasFeatureSet2 && recommendedMaxWorkingSet >= 1_073_741_824 { // 1GB+
            metalCapability = .highPerformance
        } else if hasFeatureSet1 && (hasUnifiedMemory || recommendedMaxWorkingSet >= 536_870_912) { // 512MB+
            metalCapability = .mediumPerformance
        } else if hasFeatureSet1 {
            metalCapability = .lowPerformance
        } else {
            metalCapability = .unsupported
        }
    }

    func getBatteryLevel() -> Int {
        // Use IOKit to get battery information
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return 100 } // Assume plugged in if no battery

        defer { IOObjectRelease(service) }

        if let currentCapacity = IORegistryEntryCreateCFProperty(service, "CurrentCapacity" as CFString, kCFAllocatorDefault, 0),
           let maxCapacity = IORegistryEntryCreateCFProperty(service, "MaxCapacity" as CFString, kCFAllocatorDefault, 0) {

            // Properly extract integer values from CFTypeRef
            let current = currentCapacity.takeRetainedValue() as? Int ?? 0
            let max = maxCapacity.takeRetainedValue() as? Int ?? 100

            if max > 0 {
                return (current * 100) / max
            }
        }

        return 100 // Default to full battery
    }

    private func getCPUUsage() -> Double {
        // Simple CPU usage estimation
        // In a real implementation, you'd use host_statistics or similar
        // For now, return a conservative estimate
        return 30.0
    }

    // MARK: - Performance Monitoring

    func startPerformanceMonitoring() {
        // Set up periodic performance checks
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkPerformanceThresholds()
        }
    }

    private func checkPerformanceThresholds() {
        let batteryLevel = getBatteryLevel()
        let thermalState = ProcessInfo.processInfo.thermalState

        // Auto-adjust performance if needed
        if performanceMode == .auto {
            if batteryLevel < 10 || thermalState == .critical {
                // Force minimal mode
                NotificationCenter.default.post(
                    name: .animationPerformanceChanged,
                    object: nil,
                    userInfo: ["mode": PerformanceMode.minimal]
                )
            } else if thermalState == .serious && batteryLevel < 20 {
                // Force low mode
                NotificationCenter.default.post(
                    name: .animationPerformanceChanged,
                    object: nil,
                    userInfo: ["mode": PerformanceMode.low]
                )
            }
        }
    }

    // MARK: - Public API

    func getCurrentCapability() -> MetalCapability {
        if metalCapability == .unknown {
            assessMetalCapability()
        }
        return metalCapability
    }

    func isMetalRecommended() -> Bool {
        return metalCapability == .highPerformance || metalCapability == .mediumPerformance
    }

    func getPerformanceRecommendations() -> [String] {
        var recommendations: [String] = []

        if metalCapability == .unsupported {
            recommendations.append("Metal not supported - using Canvas fallback")
        }

        let batteryLevel = getBatteryLevel()
        if batteryLevel < 20 {
            recommendations.append("Low battery - consider reducing animation quality")
        }

        let thermalState = ProcessInfo.processInfo.thermalState
        if thermalState == .serious || thermalState == .critical {
            recommendations.append("High temperature - animations automatically reduced")
        }

        return recommendations
    }
}

// MARK: - Animation Settings Structure
// AnimationSettings is defined in AnimationTypes.swift

// MARK: - Notifications

extension Notification.Name {
    static let animationPerformanceChanged = Notification.Name("animationPerformanceChanged")
}
