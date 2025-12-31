//
//  SettingsView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YabaiPro")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom, 8)

            // Presets
            VStack(alignment: .leading, spacing: 8) {
                Text("Presets")
                    .font(.headline)

                HStack {
                    Button("Default") {
                        viewModel.applyPreset(.default)
                    }
                    .buttonStyle(.bordered)

                    Button("Minimalist") {
                        viewModel.applyPreset(.minimalist)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Divider()

            // Aesthetics
            VStack(alignment: .leading, spacing: 12) {
                Text("Aesthetics")
                    .font(.headline)

                Toggle("Fade Inactive Windows", isOn: $viewModel.fadeInactiveWindows)
                    .help("Makes inactive windows semi-transparent (requires SIP disabled)")

                if viewModel.fadeInactiveWindows {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Inactive Window Opacity: \(String(format: "%.1f", viewModel.inactiveWindowOpacity))")
                                .font(.subheadline)
                            if viewModel.hasUnappliedChanges {
                                Text("(unsaved)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        Slider(value: $viewModel.inactiveWindowOpacity, in: 0.0...1.0, step: 0.1)
                            .help("Set opacity for inactive windows (0.0 = fully transparent, 1.0 = fully opaque). Click 'Apply Changes' to save.")
                    }
                    .padding(.leading, 16)
                    .padding(.top, 4)
                }

                Toggle("Disable Window Shadows", isOn: $viewModel.disableShadows)
                    .help("Creates a sharp, clean look (requires SIP disabled)")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Menu Bar Opacity: \(String(format: "%.1f", viewModel.menuBarOpacity))")
                        .font(.subheadline)
                    Slider(value: $viewModel.menuBarOpacity, in: 0.0...1.0, step: 0.1)
                        .help("0.0 = fully transparent, 1.0 = fully opaque (requires SIP disabled)")
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Window Gap: \(Int(viewModel.windowGap))")
                        .font(.subheadline)
                    Slider(value: $viewModel.windowGap, in: 0...20, step: 1)
                }
            }

            Divider()

            // Focus & Behavior
            VStack(alignment: .leading, spacing: 12) {
                Text("Focus & Behavior")
                    .font(.headline)

                Toggle("Focus Follows Mouse", isOn: $viewModel.focusFollowsMouse)
                    .help("Automatically focus windows under the mouse cursor")
            }

            Divider()

            // Apply Button
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button("Apply Changes") {
                        viewModel.applyChanges()
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    if viewModel.isApplying {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }

                if let status = viewModel.lastStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !viewModel.hasAccessibilityPermission {
                    HStack {
                        Text("⚠️ Accessibility permission required")
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("Grant Access") {
                            viewModel.openAccessibilitySettings()
                        }
                        .font(.caption)
                    }
                    .padding(.top, 4)
                }

                if viewModel.showSIPWarning {
                    Text("⚠️ Some features require SIP to be disabled in Recovery Mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }

                if let saStatus = viewModel.scriptingAdditionStatus {
                    Text(saStatus)
                        .font(.caption)
                        .foregroundColor(saStatus.contains("❌") ? .red : saStatus.contains("⚠️") ? .orange : .green)
                        .padding(.top, 4)
                }
                
                // Remote pairing UI
                VStack(alignment: .leading, spacing: 6) {
                    Text("Remote Control")
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button(viewModel.isRemoteServerRunning ? "Start Pairing" : "Start Server & Pair") {
                                viewModel.startPairing()
                            }
                            .buttonStyle(.bordered)

                            if let pin = viewModel.remotePairingPIN {
                                Text("PIN: \(pin)")
                                    .font(.caption)
                                    .padding(.leading, 6)
                                    .foregroundColor(.cyan)
                            }
                        }

                        // Reachable addresses and QR
                        if !viewModel.reachableAddresses.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Reachable Addresses:")
                                    .font(.caption)
                                ForEach(viewModel.reachableAddresses, id: \.self) { addr in
                                    HStack {
                                        Text(addr)
                                            .font(.caption2)
                                            .lineLimit(1)
                                        Spacer()
                                        Button("Copy") {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(addr, forType: .string)
                                        }
                                        .buttonStyle(.bordered)
                                        if let qr = viewModel.currentQRCode {
                                            Button("Show QR") {
                                                // show as separate window
                                                let vc = NSHostingController(rootView: Image(nsImage: qr).resizable().scaledToFit().frame(width: 280, height: 280))
                                                let win = NSWindow(contentViewController: vc)
                                                win.styleMask = [.titled, .closable]
                                                win.title = "Scan to Pair"
                                                win.makeKeyAndOrderFront(nil)
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(width: 320)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel())
    }
}
