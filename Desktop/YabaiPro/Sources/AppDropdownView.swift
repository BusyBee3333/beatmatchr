//
//  AppDropdownView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

struct AppDropdownView: View {
    @Binding var selectedApp: String
    let title: String
    let placeholder: String

    @State private var discoveredApps: [DiscoveredApp] = []
    @State private var isLoading = false
    @State private var showCustomInput = false
    @State private var customAppName = ""

    private let appDiscovery = AppDiscovery.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "app.badge")
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            if showCustomInput {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField(placeholder, text: $customAppName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if !customAppName.isEmpty {
                                    selectedApp = customAppName
                                }
                            }

                        Button(action: {
                            showCustomInput = false
                            customAppName = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Enter application name (e.g., Safari, Chrome)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Picker("", selection: $selectedApp) {
                    Text("Any Application").tag("")

                    Divider()

                    ForEach(discoveredApps) { app in
                        HStack {
                            Text(app.displayName)
                            if !app.isRunning {
                                Image(systemName: "power")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        .tag(app.bundleIdentifier ?? app.displayName)
                    }

                    Divider()

                    Text("Custom Application...").tag("__custom__")
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .onChange(of: selectedApp) { newValue in
                    handleAppSelection(newValue)
                }
            }

            Text("Select an application or choose 'Custom' to enter manually")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            loadApps()
        }
    }

    private func loadApps() {
        isLoading = true
        discoveredApps = appDiscovery.getAllDiscoverableApps()
        isLoading = false
    }

    private func handleAppSelection(_ appIdentifier: String) {
        if appIdentifier == "__custom__" {
            showCustomInput = true
            selectedApp = ""
            return
        }

        guard let selectedAppInfo = discoveredApps.first(where: {
            ($0.bundleIdentifier ?? $0.displayName) == appIdentifier
        }) else {
            return
        }

        // If app is not running, offer to launch it
        if !selectedAppInfo.isRunning {
            Task {
                do {
                    try await appDiscovery.launchApp(selectedAppInfo)
                    // Refresh the app list after launching
                    await MainActor.run {
                        loadApps()
                    }
                } catch {
                    print("Failed to launch app \(selectedAppInfo.displayName): \(error)")
                    // Still allow selection even if launch fails
                }
            }
        }
    }
}

struct AppDropdownView_Previews: PreviewProvider {
    static var previews: some View {
        AppDropdownView(
            selectedApp: .constant("com.apple.Safari"),
            title: "Application",
            placeholder: "e.g., Safari, Chrome"
        )
        .padding()
        .frame(width: 400)
    }
}
