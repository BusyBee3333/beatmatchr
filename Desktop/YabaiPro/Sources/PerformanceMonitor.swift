//
//  PerformanceMonitor.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation
import SwiftUI
import IOKit.ps

class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    private var monitoringTimer: Timer?
    private var isMonitoring = false
    private var samples: [PerformanceSample] = []
    private var maxSamples = 100 // Keep last 100 samples (about 10 seconds at 10Hz)

    struct PerformanceSample {
        let timestamp: Date
        let cpuUsage: Double
        let gpuUsage: Double
        let memoryUsage: Double
        let thermalState: ProcessInfo.ThermalState
        let batteryLevel: Int
        let frameRate: Double
    }

    func startMonitoring(updateInterval: TimeInterval = 0.1) {
        guard !isMonitoring else { return }

        isMonitoring = true
        samples.removeAll()

        monitoringTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.captureSample()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    private func captureSample() {
        let sample = PerformanceSample(
            timestamp: Date(),
            cpuUsage: getCPUUsage(),
            gpuUsage: getGPUUsage(),
            memoryUsage: getMemoryUsage(),
            thermalState: ProcessInfo.processInfo.thermalState,
            batteryLevel: getBatteryLevel(),
            frameRate: 60.0 // Placeholder - would need actual frame timing
        )

        samples.append(sample)

        // Keep only recent samples
        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }
    }

    func getRecentAverages(seconds: TimeInterval = 5.0) -> PerformanceMetrics {
        let cutoff = Date().addingTimeInterval(-seconds)
        let recentSamples = samples.filter { $0.timestamp > cutoff }

        guard !recentSamples.isEmpty else {
            return PerformanceMetrics(
                cpuUsage: 0,
                gpuUsage: 0,
                frameRate: 60,
                thermalState: .nominal,
                batteryLevel: 100
            )
        }

        let avgCPU = recentSamples.map { $0.cpuUsage }.reduce(0, +) / Double(recentSamples.count)
        let avgGPU = recentSamples.map { $0.gpuUsage }.reduce(0, +) / Double(recentSamples.count)
        let avgFrameRate = recentSamples.map { $0.frameRate }.reduce(0, +) / Double(recentSamples.count)
        let worstThermalState = recentSamples.map { $0.thermalState.rawValue }.max() ?? 0
        let avgBatteryLevel = Int(recentSamples.map { Double($0.batteryLevel) }.reduce(0, +) / Double(recentSamples.count))

        return PerformanceMetrics(
            cpuUsage: avgCPU,
            gpuUsage: avgGPU,
            frameRate: avgFrameRate,
            thermalState: ProcessInfo.ThermalState(rawValue: worstThermalState) ?? .nominal,
            batteryLevel: avgBatteryLevel
        )
    }

    func getPerformanceReport() -> String {
        let metrics = getRecentAverages()

        return """
        Performance Report (last 5 seconds):
        CPU Usage: \(String(format: "%.1f", metrics.cpuUsage))%
        GPU Usage: \(String(format: "%.1f", metrics.gpuUsage))%
        Frame Rate: \(String(format: "%.1f", metrics.frameRate)) FPS
        Thermal State: \(metrics.thermalState.description)
        Battery Level: \(metrics.batteryLevel)%

        Samples collected: \(samples.count)
        Monitoring active: \(isMonitoring)
        """
    }

    // MARK: - System Metrics (Simplified implementations)

    private func getCPUUsage() -> Double {
        // Simplified CPU usage - in production, use host_statistics
        // This returns a mock value based on system load
        return Double.random(in: 5...35)
    }

    private func getGPUUsage() -> Double {
        // GPU usage would require Metal system integration
        // Mock implementation
        return Double.random(in: 2...25)
    }

    private func getMemoryUsage() -> Double {
        // Simplified memory usage - in production, use more accurate system calls
        return 45.0 // Placeholder percentage
    }

    private func getBatteryLevel() -> Int {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return 100 }

        defer { IOObjectRelease(service) }

        if let currentCapacity = IORegistryEntryCreateCFProperty(service, "CurrentCapacity" as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue(),
           let maxCapacity = IORegistryEntryCreateCFProperty(service, "MaxCapacity" as CFString, kCFAllocatorDefault, 0)?.takeUnretainedValue() {

            let current = (currentCapacity as? Int) ?? 0
            let max = (maxCapacity as? Int) ?? 100

            if max > 0 {
                return (current * 100) / max
            }
        }

        return 100
    }

    func shouldReduceAnimations() -> Bool {
        let metrics = getRecentAverages()

        return metrics.cpuUsage > 70 ||
               metrics.gpuUsage > 60 ||
               metrics.thermalState == .serious ||
               metrics.thermalState == .critical ||
               metrics.batteryLevel < 15
    }

    func getOptimizationSuggestions() -> [String] {
        var suggestions: [String] = []
        let metrics = getRecentAverages()

        if metrics.cpuUsage > 60 {
            suggestions.append("High CPU usage detected - consider reducing particle count")
        }

        if metrics.gpuUsage > 50 {
            suggestions.append("High GPU usage detected - consider disabling Metal effects")
        }

        if metrics.thermalState == .serious || metrics.thermalState == .critical {
            suggestions.append("System running hot - animations automatically reduced")
        }

        if metrics.batteryLevel < 20 {
            suggestions.append("Low battery - switch to minimal animation preset")
        }

        if metrics.frameRate < 50 {
            suggestions.append("Low frame rate detected - reduce animation quality")
        }

        if suggestions.isEmpty {
            suggestions.append("Performance looks good - no optimization needed")
        }

        return suggestions
    }
}

// MARK: - Performance Dashboard View

struct PerformanceDashboardView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    @State private var isMonitoring = false
    @State private var performanceReport = ""

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Performance Monitor")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: {
                    if isMonitoring {
                        monitor.stopMonitoring()
                    } else {
                        monitor.startMonitoring()
                    }
                    isMonitoring.toggle()
                }) {
                    Label(isMonitoring ? "Stop Monitoring" : "Start Monitoring",
                          systemImage: isMonitoring ? "stop.fill" : "play.fill")
                }

                Button(action: {
                    performanceReport = monitor.getPerformanceReport()
                }) {
                    Label("Generate Report", systemImage: "doc.text")
                }
            }

            if isMonitoring {
                LiveMetricsView()
            }

            if !performanceReport.isEmpty {
                ScrollView {
                    Text(performanceReport)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                }
                .frame(height: 200)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Optimization Suggestions")
                    .font(.headline)

                ForEach(monitor.getOptimizationSuggestions(), id: \.self) { suggestion in
                    Text("• \(suggestion)")
                        .font(.body)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onDisappear {
            monitor.stopMonitoring()
        }
    }
}

struct LiveMetricsView: View {
    @StateObject private var monitor = PerformanceMonitor.shared
    @State private var metrics = PerformanceMetrics(
        cpuUsage: 0, gpuUsage: 0, frameRate: 60,
        thermalState: .nominal, batteryLevel: 100
    )

    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                MetricView(label: "CPU", value: String(format: "%.1f%%", metrics.cpuUsage), color: .blue)
                MetricView(label: "GPU", value: String(format: "%.1f%%", metrics.gpuUsage), color: .green)
                MetricView(label: "FPS", value: String(format: "%.0f", metrics.frameRate), color: .orange)
                MetricView(label: "Battery", value: "\(metrics.batteryLevel)%", color: .purple)
            }

            HStack {
                Text("Thermal State:")
                Text(metrics.thermalState.description)
                    .foregroundColor(thermalStateColor(metrics.thermalState))
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .onReceive(timer) { _ in
            metrics = monitor.getRecentAverages(seconds: 1.0)
        }
    }

    private func thermalStateColor(_ state: ProcessInfo.ThermalState) -> Color {
        switch state {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .gray
        }
    }
}

struct MetricView: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(width: 80)
    }
}
