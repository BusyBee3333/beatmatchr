//
//  AnimationTypes.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

// MARK: - Shared Animation Types

struct AnimationWindowInfo {
    let id: UInt32
    let isFocused: Bool
    let focusPoint: CGPoint?
    let morphProgress: Double
}

enum InteractionType {
    case click, hover, focus, drag
}

struct AnimationSettings {
    var metalEffectsEnabled: Bool = true
    var particleCount: Int = 15
    var rippleCount: Int = 3
    var morphingEnabled: Bool = true
    var gradientsEnabled: Bool = true
    var frameRateLimit: Int = 60
    var qualityScale: Double = 1.0
    var fallbackToCanvas: Bool = false

    static var `default`: AnimationSettings {
        return AnimationSettings()
    }

    static var minimal: AnimationSettings {
        return AnimationSettings(
            metalEffectsEnabled: false,
            particleCount: 0,
            rippleCount: 0,
            morphingEnabled: false,
            gradientsEnabled: false,
            frameRateLimit: 15,
            qualityScale: 0.3,
            fallbackToCanvas: true
        )
    }
}

// MARK: - Animation Event Types

struct AnimationEvent {
    let windowId: UInt32
    let type: AnimationEventType
    let point: CGPoint?
    let timestamp: Date

    enum AnimationEventType {
        case focusGained
        case focusLost
        case click
        case hover
        case morphComplete
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
    var cpuUsage: Double = 0.0
    var gpuUsage: Double = 0.0
    var frameRate: Double = 60.0
    var thermalState: ProcessInfo.ThermalState = .nominal
    var batteryLevel: Int = 100

    var shouldReduceQuality: Bool {
        return cpuUsage > 80 || gpuUsage > 80 || thermalState == .critical || batteryLevel < 20
    }
}
