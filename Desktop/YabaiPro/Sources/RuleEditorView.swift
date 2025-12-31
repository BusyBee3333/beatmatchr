//
//  RuleEditorView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

struct RuleEditorView: View {
    @State private var rule: YabaiRule
    @FocusState private var focusedField: Field?
    let isEditing: Bool
    let onSave: (YabaiRule) -> Void
    let onCancel: () -> Void

    enum Field: Hashable {
        case app, title, role, subrole, opacity
    }

    init(editingRule: YabaiRule? = nil, onSave: @escaping (YabaiRule) -> Void, onCancel: @escaping () -> Void) {
        self._rule = State(initialValue: editingRule ?? YabaiRule())
        self.isEditing = editingRule != nil
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Rule" : "Create Rule")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 24))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))

            Divider()

            // Form content
            ScrollView {
                Form {
                    Section("Matching Criteria") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Application")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                TextField("e.g., Safari, Chrome", text: Binding(
                                    get: { rule.app ?? "" },
                                    set: { rule.app = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .app)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Window Title")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                TextField("e.g., contains text", text: Binding(
                                    get: { rule.title ?? "" },
                                    set: { rule.title = $0.isEmpty ? nil : $0 }
                                ))
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .title)
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Role")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Picker("", selection: Binding(
                                        get: { rule.role ?? "" },
                                        set: { rule.role = $0.isEmpty ? nil : $0 }
                                    )) {
                                        Text("Any").tag("")
                                        Text("Window").tag("AXWindow")
                                        Text("Dialog").tag("AXDialog")
                                        Text("Sheet").tag("AXSheet")
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Subrole")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Picker("", selection: Binding(
                                        get: { rule.subrole ?? "" },
                                        set: { rule.subrole = $0.isEmpty ? nil : $0 }
                                    )) {
                                        Text("Any").tag("")
                                        Text("Standard Window").tag("AXStandardWindow")
                                        Text("Dialog").tag("AXDialog")
                                        Text("System Dialog").tag("AXSystemDialog")
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }

                    Section("Window Behavior") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Manage Window", isOn: Binding(
                                get: { rule.manage != .off },
                                set: { rule.manage = $0 ? .on : .off }
                            ))

                            Toggle("Sticky Window", isOn: Binding(
                                get: { rule.sticky == .on },
                                set: { rule.sticky = $0 ? .on : .off }
                            ))

                            Toggle("Mouse Follows Focus", isOn: Binding(
                                get: { rule.mouseFollowsFocus ?? false },
                                set: { rule.mouseFollowsFocus = $0 }
                            ))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Window Layer")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Picker("", selection: Binding(
                                    get: { rule.layer ?? .normal },
                                    set: { rule.layer = $0 }
                                )) {
                                    Text("Below").tag(YabaiRule.WindowLayer.below)
                                    Text("Normal").tag(YabaiRule.WindowLayer.normal)
                                    Text("Above").tag(YabaiRule.WindowLayer.above)
                                }
                                .pickerStyle(.segmented)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Opacity: \(String(format: "%.1f", rule.opacity ?? 1.0))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Slider(value: Binding(
                                    get: { rule.opacity ?? 1.0 },
                                    set: { rule.opacity = $0 }
                                ), in: 0.0...1.0, step: 0.1)
                                .focused($focusedField, equals: .opacity)
                            }

                            // Note: Border control removed - not supported in yabai v7.1.16
                        }
                    }
                }
                // .formStyle(.grouped) - requires macOS 13.0+
                .padding(.vertical)
            }

            Divider()

            // Footer with buttons
            HStack {
                Spacer()

                Button(action: onCancel) {
                    Text("Cancel")
                        .fontWeight(.medium)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)

                Button(action: saveRule) {
                    Text(isEditing ? "Save Changes" : "Create Rule")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidRule)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 600)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            // Focus first field after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .app
            }
        }
        .onSubmit {
            // Handle Tab navigation
            switch focusedField {
            case .app:
                focusedField = .title
            case .title:
                // Skip to opacity since layer is a segmented control
                focusedField = .opacity
            case .opacity:
                saveRule()
            default:
                saveRule()
            }
        }
    }

    private var isValidRule: Bool {
        // At least one matching criterion must be provided
        return rule.app != nil || rule.title != nil || rule.role != nil || rule.subrole != nil
    }

    private func saveRule() {
        guard isValidRule else { return }
        onSave(rule)
    }
}

struct RuleEditorView_Previews: PreviewProvider {
    static var previews: some View {
        RuleEditorView(onSave: { _ in }, onCancel: { })
    }
}
