//
//  LiveShellPreview.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

struct LiveShellPreview: View {
    @Binding var structuredActions: [SignalAction]
    @Binding var rawAction: String
    let title: String

    @State private var manualOverride = false
    @State private var editedCommand = ""

    private var computedCommand: String {
        if structuredActions.isEmpty {
            return ""
        }
        return structuredActions.map { $0.toShellCommand() }.joined(separator: " && ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .foregroundColor(.green)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                if manualOverride {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Text("Manual Edit")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Shell Command:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ZStack(alignment: .topLeading) {
                    if manualOverride {
                        TextEditor(text: $editedCommand)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: manualOverride ? 2 : 0)
                            )
                            .onChange(of: editedCommand) { newValue in
                                rawAction = newValue
                            }
                    } else {
                        ScrollView {
                            Text(computedCommand.isEmpty ? "No actions configured" : computedCommand)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(computedCommand.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .textSelection(.enabled)
                        }
                        .frame(minHeight: 60)
                        .background(Color(.textBackgroundColor).opacity(0.5))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }
                }

                HStack {
                    if manualOverride {
                        Button(action: revertToStructured) {
                            Text("Revert to Structured")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Text("Manual edits won't round-trip to structured actions")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Button(action: enableManualEdit) {
                            Text("Edit Manually")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)

                        Text("Click to edit the command directly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .onChange(of: structuredActions) { _ in
            if !manualOverride {
                rawAction = computedCommand
            }
        }
        .onChange(of: rawAction) { newValue in
            if !manualOverride && newValue != computedCommand {
                // Raw action was modified externally, enable manual override
                manualOverride = true
                editedCommand = newValue
            }
        }
        .onAppear {
            // Initialize
            if !manualOverride {
                rawAction = computedCommand
            }
        }
    }

    private func enableManualEdit() {
        manualOverride = true
        editedCommand = computedCommand
    }

    private func revertToStructured() {
        manualOverride = false
        editedCommand = ""
        rawAction = computedCommand
    }
}

struct LiveShellPreview_Previews: PreviewProvider {
    static var previews: some View {
        LiveShellPreview(
            structuredActions: .constant([
                SignalAction(command: .windowFocus, parameters: ["direction": "next"]),
                SignalAction(command: .configWindowOpacityActive, parameters: ["opacity": "0.8"])
            ]),
            rawAction: .constant("yabai -m window --focus next && yabai -m config active_window_opacity 0.8"),
            title: "Live Preview"
        )
        .padding()
        .frame(width: 500, height: 200)
    }
}
