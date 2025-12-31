//
//  ActionBuilderView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

struct ActionBuilderView: View {
    @Binding var structuredActions: [SignalAction]
    let title: String

    @State private var showingAddAction = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "terminal")
                    .foregroundColor(.orange)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { showingAddAction = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(ActionValidator.getRecommendedActions(for: structuredActions).isEmpty ? .gray : .green)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help(ActionValidator.getRecommendedActions(for: structuredActions).isEmpty ? "No compatible actions available" : "Add Action")
                .disabled(ActionValidator.getRecommendedActions(for: structuredActions).isEmpty)
            }

            if structuredActions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "terminal")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No actions configured")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Click the + button to add your first action")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(structuredActions) { action in
                        ActionRowView(
                            action: action,
                            onUpdate: { updatedAction in
                                if let index = structuredActions.firstIndex(where: { $0.id == action.id }) {
                                    structuredActions[index] = updatedAction
                                }
                            },
                            onDelete: {
                                structuredActions.removeAll { $0.id == action.id }
                            }
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddAction) {
            AddActionSheet(existingActions: structuredActions) { newAction in
                structuredActions.append(newAction)
                showingAddAction = false
            } onCancel: {
                showingAddAction = false
            }
        }
    }
}

struct ActionRowView: View {
    let action: SignalAction
    let onUpdate: (SignalAction) -> Void
    let onDelete: () -> Void

    @State private var parameters: [String: String]
    @State private var isExpanded = false

    init(action: SignalAction, onUpdate: @escaping (SignalAction) -> Void, onDelete: @escaping () -> Void) {
        self.action = action
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._parameters = State(initialValue: action.parameters)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: iconForCommand(action.command))
                    .foregroundColor(colorForCommand(action.command))

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(action.toShellCommand())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)

            // Parameters (when expanded)
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()

                    let schema = CommandSchema.schema(for: action.command)
                    ForEach(schema.parameters, id: \.key) { param in
                        ParameterInputView(
                            schema: param,
                            value: Binding(
                                get: { parameters[param.key] ?? param.defaultValue ?? "" },
                                set: { newValue in
                                    parameters[param.key] = newValue
                                    var updatedAction = action
                                    updatedAction.parameters = parameters
                                    onUpdate(updatedAction)
                                }
                            )
                        )
                    }
                }
                .padding()
                .background(Color(.windowBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private func iconForCommand(_ command: SignalAction.YabaiCommand) -> String {
        switch command {
        case .windowFocus, .windowSwap, .windowWarp: return "arrow.right.square"
        case .windowToggleFloat: return "square.on.square"
        case .windowToggleFullscreen: return "arrow.up.left.and.arrow.down.right"
        case .windowToggleStack: return "square.stack"
        case .windowMoveAbsolute, .windowMoveRelative: return "arrow.up.and.down.and.arrow.left.and.right"
        case .windowResizeAbsolute, .windowResizeRelative: return "arrow.up.left.and.arrow.down.right"
        case .windowMoveToSpace: return "square.grid.2x2"
        case .windowMoveToDisplay: return "display"
        case .configWindowOpacity, .configWindowOpacityActive, .configWindowOpacityNormal: return "circle.opacity"
        case .shellCommand: return "terminal"
        default: return "gear"
        }
    }

    private func colorForCommand(_ command: SignalAction.YabaiCommand) -> Color {
        switch command {
        case .windowFocus, .windowSwap, .windowWarp: return .blue
        case .windowToggleFloat: return .purple
        case .windowToggleFullscreen: return .green
        case .windowMoveAbsolute, .windowMoveRelative, .windowResizeAbsolute, .windowResizeRelative: return .orange
        case .configWindowOpacity, .configWindowOpacityActive, .configWindowOpacityNormal: return .pink
        case .shellCommand: return .gray
        default: return .secondary
        }
    }
}

struct ParameterInputView: View {
    let schema: CommandSchema.ParameterSchema
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(schema.label)
                .font(.subheadline)
                .foregroundColor(.primary)

            switch schema.type {
            case .text:
                TextField(schema.label, text: $value)
                    .textFieldStyle(.roundedBorder)

            case .number:
                TextField(schema.label, text: $value)
                    .textFieldStyle(.roundedBorder)

            case .slider(let min, let max, let step):
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(schema.label)
                        Spacer()
                        Text(String(format: "%.1f", Double(value) ?? 0.0))
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(value) ?? 0.0 },
                            set: { value = String(format: "%.1f", $0) }
                        ),
                        in: min...max,
                        step: step
                    )
                }

            case .picker:
                if let options = schema.options {
                    Picker("", selection: $value) {
                        ForEach(options, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

            case .toggle:
                Toggle(schema.label, isOn: Binding(
                    get: { value == "on" },
                    set: { value = $0 ? "on" : "off" }
                ))
            }

            if !schema.required {
                Text("Optional")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddActionSheet: View {
    let existingActions: [SignalAction]
    let onAdd: (SignalAction) -> Void
    let onCancel: () -> Void

    @State private var selectedCommand: SignalAction.YabaiCommand?
    @State private var parameters: [String: String] = [:]

    private var recommendedCommands: [SignalAction.YabaiCommand] {
        ActionValidator.getRecommendedActions(for: existingActions)
    }

    var body: some View {
        NavigationView {
            VStack {
                if selectedCommand == nil {
                    List {
                        ForEach(recommendedCommands, id: \.self) { command in
                            Button(action: { selectedCommand = command }) {
                                HStack {
                                    Image(systemName: iconForCommand(command))
                                        .foregroundColor(colorForCommand(command))
                                    Text(command.displayName)
                                        .foregroundColor(.primary)
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        if recommendedCommands.isEmpty {
                            Text("No compatible actions available")
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .listStyle(.plain)
                } else if let command = selectedCommand {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Image(systemName: iconForCommand(command))
                                    .foregroundColor(colorForCommand(command))
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text(command.displayName)
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Text("Configure parameters for this action")
                                        .foregroundColor(.secondary)
                                }
                            }

                            let schema = CommandSchema.schema(for: command)
                            ForEach(schema.parameters, id: \.key) { param in
                                ParameterInputView(
                                    schema: param,
                                    value: Binding(
                                        get: { parameters[param.key] ?? param.defaultValue ?? "" },
                                        set: { parameters[param.key] = $0 }
                                    )
                                )
                            }

                            if schema.parameters.isEmpty {
                                Text("This action doesn't require any parameters.")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(selectedCommand == nil ? "Add Action" : "Configure Action")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedCommand == nil ? "" : "Add") {
                        if let command = selectedCommand {
                            let action = SignalAction(command: command, parameters: parameters)
                            onAdd(action)
                        }
                    }
                    .disabled(selectedCommand == nil)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    private func iconForCommand(_ command: SignalAction.YabaiCommand) -> String {
        // Reuse the same logic from ActionRowView
        switch command {
        case .windowFocus, .windowSwap, .windowWarp: return "arrow.right.square"
        case .windowToggleFloat: return "square.on.square"
        case .windowToggleFullscreen: return "arrow.up.left.and.arrow.down.right"
        case .windowToggleStack: return "square.stack"
        case .windowMoveAbsolute, .windowMoveRelative: return "arrow.up.and.down.and.arrow.left.and.right"
        case .windowResizeAbsolute, .windowResizeRelative: return "arrow.up.left.and.arrow.down.right"
        case .windowMoveToSpace: return "square.grid.2x2"
        case .windowMoveToDisplay: return "display"
        case .configWindowOpacity, .configWindowOpacityActive, .configWindowOpacityNormal: return "circle.opacity"
        case .ruleAdd: return "list.bullet.rectangle"
        case .shellCommand: return "terminal"
        default: return "gear"
        }
    }

    private func colorForCommand(_ command: SignalAction.YabaiCommand) -> Color {
        // Reuse the same logic from ActionRowView
        switch command {
        case .windowFocus, .windowSwap, .windowWarp: return .blue
        case .windowToggleFloat: return .purple
        case .windowToggleFullscreen: return .green
        case .windowMoveAbsolute, .windowMoveRelative, .windowResizeAbsolute, .windowResizeRelative: return .orange
        case .configWindowOpacity, .configWindowOpacityActive, .configWindowOpacityNormal: return .pink
        case .ruleAdd: return .teal
        case .shellCommand: return .gray
        default: return .secondary
        }
    }
}

extension SignalAction.YabaiCommand {
    var displayName: String {
        // Reuse the displayName logic from SignalAction
        switch self {
        case .windowFocus: return "Focus Window"
        case .windowSwap: return "Swap Window"
        case .windowWarp: return "Warp Window"
        case .windowToggleFloat: return "Toggle Float"
        case .windowToggleFullscreen: return "Toggle Fullscreen"
        case .windowToggleStack: return "Toggle Stack"
        case .windowUnstack: return "Unstack Window"
        case .windowInsert: return "Insert Window"
        case .windowToggleSplit: return "Toggle Split"
        case .windowMoveAbsolute: return "Move Window (Absolute)"
        case .windowMoveRelative: return "Move Window (Relative)"
        case .windowResizeAbsolute: return "Resize Window (Absolute)"
        case .windowResizeRelative: return "Resize Window (Relative)"
        case .windowToggleOpacity: return "Toggle Opacity"
        case .windowToggleShadow: return "Toggle Shadow"
        case .windowToggleBorder: return "Toggle Border"
        case .windowMoveToSpace: return "Move to Space"
        case .windowMoveToDisplay: return "Move to Display"
        case .windowToggleZoomParent: return "Toggle Zoom Parent"
        case .windowToggleZoomFullscreen: return "Toggle Zoom Fullscreen"
        case .windowToggleExposé: return "Toggle Exposé"
        case .windowTogglePip: return "Toggle Picture-in-Picture"
        case .spaceFocus: return "Focus Space"
        case .spaceBalance: return "Balance Space"
        case .spaceMirror: return "Mirror Space"
        case .spaceRotate: return "Rotate Space"
        case .spaceCreate: return "Create Space"
        case .spaceDestroy: return "Destroy Space"
        case .spaceMove: return "Move Space"
        case .spaceLabel: return "Label Space"
        case .spaceMoveToDisplay: return "Move Space to Display"
        case .spaceLayout: return "Set Space Layout"
        case .spaceRotateSpecific: return "Rotate Specific Space"
        case .spaceMirrorSpecific: return "Mirror Specific Space"
        case .spaceBalanceSpecific: return "Balance Specific Space"
        case .spacePadding: return "Set Space Padding"
        case .spaceGap: return "Set Space Gap"
        case .displayFocus: return "Focus Display"
        case .displayBalance: return "Balance Display"
        case .displayFocusNext: return "Focus Next Display"
        case .displayFocusPrev: return "Focus Previous Display"
        case .displayFocusRecent: return "Focus Recent Display"
        case .displayFocusMouse: return "Focus Display Under Mouse"
        case .displayBalanceSpecific: return "Balance Specific Display"
        case .configWindowOpacity: return "Set Window Opacity"
        case .configWindowOpacityActive: return "Set Active Window Opacity"
        case .configWindowOpacityNormal: return "Set Normal Window Opacity"
        case .configWindowShadow: return "Set Window Shadow"
        case .configMouseFollowsFocus: return "Set Mouse Follows Focus"
        case .configFocusFollowsMouse: return "Set Focus Follows Mouse"
        case .ruleAdd: return "Add Yabai Rule"
        case .shellCommand: return "Run Shell Command"
        }
    }
}

struct ActionBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        ActionBuilderView(
            structuredActions: .constant([
                SignalAction(command: .windowFocus, parameters: ["direction": "next"]),
                SignalAction(command: .configWindowOpacityActive, parameters: ["opacity": "0.8"])
            ]),
            title: "Actions"
        )
        .padding()
        .frame(width: 600, height: 400)
    }
}
