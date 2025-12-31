//
//  main.swift
//  AnimationDemo
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

@main
struct AnimationDemoApp: App {
    var body: some Scene {
        WindowGroup {
            AnimationDemoView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact)
    }
}

struct AnimationDemoView: View {
    @State private var selectedAnimation: AnimationType = .liquidBorder
    @State private var isFocused = true
    @State private var animationTime = 0.0
    @State private var particleCount = 15

    var body: some View {
        VStack(spacing: 20) {
            Text("Metal Liquid Animations Demo")
                .font(.title)
                .fontWeight(.bold)

            // Animation selector
            Picker("Animation Type", selection: $selectedAnimation) {
                Text("Liquid Border").tag(AnimationType.liquidBorder)
                Text("Flowing Particles").tag(AnimationType.flowingParticles)
                Text("Ripple Effect").tag(AnimationType.rippleEffect)
                Text("Morphing Shape").tag(AnimationType.morphingShape)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Controls
            HStack(spacing: 20) {
                Toggle("Focused", isOn: $isFocused)
                    .toggleStyle(.switch)

                VStack {
                    Text("Particles: \(particleCount)")
                    Slider(value: .init(get: { Double(particleCount) }, set: { particleCount = Int($0) }),
                           in: 5...25, step: 1)
                }
                .frame(width: 150)

                Button("Reset") {
                    animationTime = 0.0
                }
            }
            .padding(.horizontal)

            // Animation display
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 300, height: 200)

                MetalAnimationView(
                    animationType: selectedAnimation,
                    windowInfo: AnimationWindowInfo(
                        id: 1,
                        isFocused: isFocused,
                        focusPoint: isFocused ? CGPoint(x: 150, y: 100) : nil,
                        morphProgress: isFocused ? 1.0 : 0.0
                    ),
                    time: $animationTime
                )
                .frame(width: 280, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(width: 320, height: 220)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )

            // Status
            HStack {
                Circle()
                    .fill(MetalAnimationEngine.shared.isMetalAvailable ? Color.green : Color.red)
                    .frame(width: 12, height: 12)

                Text(MetalAnimationEngine.shared.isMetalAvailable ?
                     "Metal Available - GPU Acceleration Active" :
                     "Metal Unavailable - Using Canvas Fallback")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            // Start animation timer
            Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
                animationTime += 1/60.0
            }
        }
    }
}











