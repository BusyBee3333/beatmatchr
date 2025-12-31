//
//  MainSettingsView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

struct HelpButton: View {
    let helpText: String
    @State private var showingHelp = false

    var body: some View {
        Button(action: { showingHelp = true }) {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingHelp) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Help")
                    .font(.headline)
                Text(helpText)
                    .font(.body)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 300)
        }
    }
}

struct MainSettingsView: View {
    @StateObject private var viewModel = ComprehensiveSettingsViewModel()
    @State private var selectedTab = SettingsCategory.rules
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("YabaiPro Settings")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close settings")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))

            Divider()

            // Tab View
            TabView(selection: $selectedTab) {
                GlobalSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Global", systemImage: "gear")
                    }
                    .tag(SettingsCategory.global)

                WindowSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Windows", systemImage: "macwindow")
                    }
                    .tag(SettingsCategory.windows)

                SpaceSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Spaces", systemImage: "rectangle.split.3x3")
                    }
                    .tag(SettingsCategory.spaces)

                DisplaySettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Displays", systemImage: "display")
                    }
                    .tag(SettingsCategory.displays)

                RulesSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Rules", systemImage: "list.bullet")
                    }
                    .tag(SettingsCategory.rules)

                SignalsSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Signals", systemImage: "bolt")
                    }
                    .tag(SettingsCategory.signals)

                PresetsSettingsView(viewModel: viewModel)
                    .tabItem {
                        Label("Presets", systemImage: "bookmark")
                    }
                    .tag(SettingsCategory.presets)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            // Footer with Apply/Status
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    HStack {
                        Button("Preview Changes") {
                            Task {
                                try await viewModel.applyAllChanges(preview: true)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isApplying || viewModel.isPreviewing)
                        .help("Apply changes temporarily to preview them")

                        HelpButton(helpText: """
                            Test your configuration changes without making them permanent.

                            Preview mode applies all settings to the running yabai instance, allowing you to see exactly how your changes look and feel. If you don't like the results, simply close and reopen applications to return to the previous state.

                            • Changes are temporary and don't modify your ~/.yabairc file
                            • Perfect for experimenting with new layouts or aesthetics
                            • Allows you to test before committing to permanent changes

                            Use this when you're unsure about a setting and want to try it out first.
                            """)
                    }

                    HStack {
                        Button("Apply Changes") {
                            Task {
                                try await viewModel.applyAllChanges(preview: false)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isApplying || viewModel.isPreviewing)
                        .help("Apply changes permanently and update configuration")

                        HelpButton(helpText: """
                            Permanently apply your configuration changes.

                            This writes all settings to your ~/.yabairc file and applies them to the running yabai instance. These changes will persist across system restarts and application launches.

                            • Updates your yabai configuration file
                            • Changes take effect immediately
                            • Settings are remembered for future sessions
                            • Creates automatic backups before making changes

                            Use this when you're satisfied with your configuration and want to make it permanent.
                            """)
                    }

                    HStack {
                        Button("Create Backup") {
                            Task {
                                try await viewModel.createBackup()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isApplying)
                        .help("Create a backup of current configuration")

                        HelpButton(helpText: """
                            Manually create a timestamped backup of your current yabai configuration.

                            Backups are automatically created before any changes, but you can also create them manually before making experimental changes or before major configuration overhauls.

                            • Backups are stored as ~/.yabairc.backup.YYYY-MM-DD_HH-MM-SS
                            • Use the Restore Latest button to revert if needed
                            • Keeps multiple backup versions for safety
                            • Never hurts to backup before making changes!

                            Think of this as a "save point" in a video game - create one before trying risky changes.
                            """)
                    }

                    Spacer()

                    if viewModel.isApplying {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Applying...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if viewModel.isPreviewing {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Previewing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Status and Warnings
                VStack(alignment: .leading, spacing: 4) {
                    if let status = viewModel.lastStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("Error") ? .red : .primary)
                    }

                    // Permissions Status Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required Permissions")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)

                        // Accessibility Permission
                        HStack {
                            if viewModel.hasAccessibilityPermission {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Accessibility: Granted")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Accessibility: Required")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Button("Grant Access") {
                                    PermissionsManager.shared.requestAccessibilityPermission()
                                }
                                .font(.caption)
                            }
                            Spacer()
                            Button("Open Settings") {
                                PermissionsManager.shared.openAccessibilitySettings()
                            }
                            .font(.caption2)
                            .foregroundColor(.blue)
                        }

                        // Screen Recording Permission
                        HStack {
                            if viewModel.hasScreenRecordingPermission {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Screen Recording: Granted")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Screen Recording: Required for animations")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Button("Grant Access") {
                                    PermissionsManager.shared.requestScreenRecordingPermission()
                                }
                                .font(.caption)
                            }
                            Spacer()
                            Button("Open Settings") {
                                PermissionsManager.shared.openScreenRecordingSettings()
                            }
                            .font(.caption2)
                            .foregroundColor(.blue)
                        }
                    }

                    if viewModel.showSIPWarning {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("SIP must be disabled for window appearance features")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    if let saStatus = viewModel.scriptingAdditionStatus {
                        HStack {
                            if saStatus.contains("❌") {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            } else if saStatus.contains("⚠️") {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            Text(saStatus.replacingOccurrences(of: "❌ ", with: "").replacingOccurrences(of: "⚠️ ", with: "").replacingOccurrences(of: "✅ ", with: ""))
                                .font(.caption)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))
        }
        .frame(minWidth: 700, minHeight: 600)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Supporting Views (Stubs for now)

struct GlobalSettingsView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Mouse & Focus Behavior") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Mouse Follows Focus", isOn: $viewModel.mouseFollowsFocus)
                            HelpButton(helpText: """
                                When enabled, the mouse cursor automatically moves to the center of newly focused windows.

                                This creates a seamless experience where focusing a window (via keyboard shortcuts or other means) also moves your mouse cursor to that window, making it ready for immediate interaction.

                                • Useful for keyboard-heavy workflows
                                • Can be disorienting if you prefer to keep your mouse in one place
                                """)
                        }

                        HStack {
                            Text("Focus Follows Mouse:")
                            Picker("", selection: $viewModel.focusFollowsMouse) {
                                Text("Off").tag(FocusMode.off)
                                Text("Autofocus").tag(FocusMode.autofocus)
                                Text("Autoraise").tag(FocusMode.autoraise)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            HelpButton(helpText: """
                                Controls how windows are focused when you move your mouse over them.

                                • Off: Mouse movement alone doesn't change focus. Windows are only focused via explicit actions (clicks, keyboard shortcuts).
                                • Autofocus: Moving mouse over a window focuses it immediately without raising it to the front.
                                • Autoraise: Moving mouse over a window focuses it AND brings it to the front of other windows.

                                Autofocus is recommended for most users - it provides focus-follows-mouse behavior without the visual disruption of windows constantly popping to the front.
                                """)
                        }

                        HStack {
                            Text("Window Origin Display:")
                            Picker("", selection: $viewModel.windowOriginDisplay) {
                                Text("Default").tag(WindowOriginDisplay.default)
                                Text("Focused").tag(WindowOriginDisplay.focused)
                                Text("Cursor").tag(WindowOriginDisplay.cursor)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                Determines which display new windows open on when launched.

                                • Default: Uses macOS default behavior (usually the display with the active application)
                                • Focused: Opens on the display that contains the currently focused window
                                • Cursor: Opens on the display where your mouse cursor is currently located

                                This setting ensures new windows appear on the display you're actively using, reducing the need to manually move windows between displays.
                                """)
                        }
                    }
                }

                GroupBox("Window Management") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Window Placement:")
                            Picker("", selection: $viewModel.windowPlacement) {
                                Text("First Child").tag(WindowPlacement.first_child)
                                Text("Second Child").tag(WindowPlacement.second_child)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                Controls how new windows are inserted into the bsp (binary space partitioning) layout tree.

                                • First Child: New windows become the first child of the current node, appearing before existing windows in the layout
                                • Second Child: New windows become the second child, appearing after existing windows

                                This affects the visual order and splitting behavior when new windows are added to existing spaces. The difference is subtle but can affect how your layout evolves as you add windows.
                                """)
                        }

                        HStack {
                            Toggle("Window Zoom Persists", isOn: $viewModel.windowZoomPersist)
                            HelpButton(helpText: """
                                When enabled, windows remember their zoomed (fullscreen) state when switching between spaces.

                                • Enabled: If you fullscreen a window in one space, it stays fullscreen when you return to that space
                                • Disabled: Windows return to their normal tiled state when switching spaces, even if they were fullscreen before

                                Useful if you want certain windows to always be fullscreen in specific spaces, but can be confusing if you forget which windows are zoomed in hidden spaces.
                                """)
                        }

                        if viewModel.windowTopmostSupported {
                            HStack {
                                Toggle("Floating Windows Always on Top", isOn: $viewModel.windowTopmost)
                                HelpButton(helpText: """
                                    Controls whether floating windows (windows not managed by bsp layout) always appear above tiled windows.

                                    • Enabled: Floating windows are always visible above tiled windows, even when tiled windows are focused
                                    • Disabled: Floating windows follow normal macOS layering rules and can be obscured by tiled windows

                                    Essential for floating windows like palettes, toolbars, or always-visible utilities that you don't want hidden behind your main application windows.

                                    Note: This feature is planned for a future yabai version and is not yet implemented.
                                    """)
                            }
                        }

                        HStack {
                            Toggle("Auto Balance Windows", isOn: $viewModel.autoBalance)
                            HelpButton(helpText: """
                                When enabled, yabai automatically redistributes window sizes to maintain balanced proportions whenever windows are added, removed, or resized.

                                • Enabled: Windows are constantly kept at optimal sizes relative to each other
                                • Disabled: Window sizes remain as manually adjusted until explicitly balanced

                                Auto-balance ensures your layout always looks clean and proportional, but can be disruptive if you prefer custom window sizing.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Split Ratio: \(String(format: "%.1f", viewModel.splitRatio))")
                                Slider(value: $viewModel.splitRatio, in: 0.1...0.9, step: 0.1)
                            }
                            HelpButton(helpText: """
                                Sets the default size ratio when windows are split in the bsp layout.

                                Values closer to 0.5 create more balanced splits, while values closer to 0.1 or 0.9 create more dramatic size differences between adjacent windows.

                                • 0.5: Perfectly balanced splits (recommended for most users)
                                • 0.6: Left/top windows get 60% space, right/bottom get 40%
                                • 0.3: Left/top windows get 30% space, right/bottom get 70%

                                This is the default ratio - individual window ratios can still be adjusted manually after creation.
                                """)
                        }
                    }
                }

                GroupBox("Mouse Actions") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Mouse Modifier:")
                            Picker("", selection: $viewModel.mouseModifier) {
                                Text("Fn").tag(MouseModifier.fn)
                                Text("Alt").tag(MouseModifier.alt)
                                Text("Shift").tag(MouseModifier.shift)
                                Text("Cmd").tag(MouseModifier.cmd)
                                Text("Ctrl").tag(MouseModifier.ctrl)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                The keyboard modifier key that must be held to enable mouse-based window manipulation.

                                When this key is held while clicking and dragging windows:
                                • Mouse Button 1 performs the primary action (move or resize)
                                • Mouse Button 2 performs the secondary action (move or resize)
                                • Mouse drop performs the drop action (swap or stack)

                                Choose a modifier that's comfortable for you and doesn't conflict with application shortcuts. Alt (Option) is recommended as it's rarely used for mouse operations.
                                """)
                        }

                        HStack {
                            Text("Mouse Button 1:")
                            Picker("", selection: $viewModel.mouseAction1) {
                                Text("Move").tag(MouseAction.move)
                                Text("Resize").tag(MouseAction.resize)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                The action performed when clicking and dragging with mouse button 1 (usually left-click) while holding the mouse modifier key.

                                • Move: Drag to reposition windows within or between spaces
                                • Resize: Drag window edges/corners to change window size

                                Primary mouse button should typically be set to Move for most intuitive window management.
                                """)
                        }

                        HStack {
                            Text("Mouse Button 2:")
                            Picker("", selection: $viewModel.mouseAction2) {
                                Text("Move").tag(MouseAction.move)
                                Text("Resize").tag(MouseAction.resize)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                The action performed when clicking and dragging with mouse button 2 (usually right-click) while holding the mouse modifier key.

                                • Move: Alternative way to reposition windows
                                • Resize: Alternative way to resize windows

                                Set this to Resize if mouse button 1 is Move, or vice versa, to have both move and resize capabilities available.
                                """)
                        }

                        HStack {
                            Text("Mouse Drop Action:")
                            Picker("", selection: $viewModel.mouseDropAction) {
                                Text("Swap").tag(MouseDropAction.swap)
                                Text("Stack").tag(MouseDropAction.stack)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                What happens when you release a window after moving it with the mouse (drop action).

                                • Swap: The moved window swaps positions with whatever window it was dropped on
                                • Stack: The moved window is stacked on top of the window it was dropped on, creating a stack layout

                                Swap is more predictable for rearranging window positions, while Stack is useful for creating grouped window layouts.
                                """)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct WindowSettingsView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Basic Aesthetics") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Window Opacity", isOn: $viewModel.windowOpacity)
                            HelpButton(helpText: """
                                Enables or disables window transparency effects.

                                When enabled, windows can have different opacity levels for active vs inactive states. This creates a visual hierarchy that helps you identify which window is currently focused.

                                • Requires SIP to be disabled on macOS
                                • Active windows: Currently focused window opacity
                                • Normal windows: Background window opacity
                                • Transition: How smoothly opacity changes when switching focus

                                Useful for reducing visual clutter while maintaining window awareness.
                                """)
                        }

                        if viewModel.windowOpacity {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Active Window: \(String(format: "%.1f", viewModel.activeWindowOpacity))")
                                    Slider(value: $viewModel.activeWindowOpacity, in: 0.0...1.0, step: 0.1)
                                }
                                HelpButton(helpText: """
                                    Opacity level for the currently focused window.

                                    • 1.0 = Fully opaque (normal window)
                                    • 0.5 = 50% transparent (see-through)
                                    • 0.0 = Fully transparent (invisible)

                                    Typically set to 1.0 (fully opaque) to keep the active window clearly visible, while background windows are more transparent.
                                    """)
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Normal Window: \(String(format: "%.1f", viewModel.normalWindowOpacity))")
                                    Slider(value: $viewModel.normalWindowOpacity, in: 0.0...1.0, step: 0.1)
                                }
                                HelpButton(helpText: """
                                    Opacity level for inactive (background) windows.

                                    • Higher values (0.8-1.0): Windows remain quite visible
                                    • Medium values (0.3-0.7): Creates clear focus hierarchy
                                    • Lower values (0.1-0.3): Very subtle background windows

                                    Setting this lower than active window opacity creates a clear visual distinction between focused and background windows.
                                    """)
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Transition Duration: \(String(format: "%.1f", viewModel.windowOpacityDuration))s")
                                    Slider(value: $viewModel.windowOpacityDuration, in: 0.0...2.0, step: 0.1)
                                }
                                HelpButton(helpText: """
                                    How long it takes for windows to fade between opacity levels when focus changes.

                                    • 0.0s: Instant opacity changes (no animation)
                                    • 0.2-0.5s: Smooth, noticeable transitions
                                    • 1.0s+: Slow, dramatic transitions

                                    Fast transitions (0.0-0.2s) feel responsive but can be jarring. Slow transitions look elegant but may feel sluggish.
                                    """)
                            }
                        }

                        HStack {
                            Toggle("Window Shadows", isOn: $viewModel.windowShadow)
                            HelpButton(helpText: """
                                Controls whether windows cast drop shadows.

                                • Enabled: Windows have realistic drop shadows that help define their boundaries and create depth
                                • Disabled: Windows have sharp, flat edges without shadows (clean, minimal look)

                                Disabling shadows creates a more minimal, modern appearance but can make it harder to distinguish window boundaries, especially with transparent backgrounds.

                                Note: Requires SIP to be disabled to modify window shadows.
                                """)
                        }

                        if viewModel.windowMagnificationSupported {
                            HStack {
                                Toggle("Window Magnification", isOn: $viewModel.windowMagnification)
                                HelpButton(helpText: """
                                    Enables dynamic window magnification effects.

                                    When enabled, windows can smoothly scale up when focused and scale back down when unfocused, creating a "zoom" effect that emphasizes the active window.

                                    • Factor: How much larger focused windows become (1.0 = no magnification)
                                    • Duration: How quickly the magnification occurs

                                    This creates a strong visual focus indicator but can be disorienting for some users.

                                    Note: This feature is planned for a future yabai version and is not yet implemented.
                                    """)
                            }

                            if viewModel.windowMagnification {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Factor: \(String(format: "%.1f", viewModel.windowMagnificationFactor))x")
                                    Slider(value: $viewModel.windowMagnificationFactor, in: 1.0...2.0, step: 0.1)
                                }
                                HelpButton(helpText: """
                                    Magnification scale factor for focused windows.

                                    • 1.0x: No magnification (windows stay normal size)
                                    • 1.2x: 20% larger when focused
                                    • 1.5x: 50% larger when focused
                                    • 2.0x: Double size when focused

                                    Values above 1.5x can be quite dramatic and may cause windows to exceed screen boundaries.
                                    """)
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Duration: \(String(format: "%.1f", viewModel.windowMagnificationDuration))s")
                                    Slider(value: $viewModel.windowMagnificationDuration, in: 0.0...2.0, step: 0.1)
                                }
                                HelpButton(helpText: """
                                    How long magnification transitions take.

                                    • 0.0s: Instant magnification changes
                                    • 0.2-0.5s: Smooth, noticeable scaling
                                    • 1.0s+: Slow, dramatic scaling effects

                                    Longer durations create more elegant effects but can feel sluggish during rapid window switching.
                                    """)
                            }
                            }
                        }

                        if viewModel.hoverMagnificationSupported {
                            HStack {
                                Toggle("Hover Magnification", isOn: $viewModel.hoverMagnification)
                                HelpButton(helpText: """
                                    Enables window magnification when hovering with the mouse cursor.

                                    When enabled, windows will smoothly scale up when you hover over them and scale back down when you move the cursor away.

                                    • Factor: How much larger windows become on hover (1.0 = no magnification)
                                    • Duration: How quickly the magnification occurs
                                    • Delay: How long to wait before starting magnification

                                    This creates a dynamic focus effect that's great for quickly identifying windows.

                                    Note: Requires global mouse tracking and works best with SIP disabled.
                                    """)
                            }

                            if viewModel.hoverMagnification {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Factor: \(String(format: "%.1f", viewModel.hoverMagnificationFactor))x")
                                        Slider(value: $viewModel.hoverMagnificationFactor, in: 1.0...1.5, step: 0.1)
                                    }
                                    HelpButton(helpText: """
                                        Magnification scale factor for hovered windows.

                                        • 1.0x: No magnification (windows stay normal size)
                                        • 1.2x: 20% larger when hovered
                                        • 1.5x: 50% larger when hovered

                                        Values above 1.3x may cause windows to exceed screen boundaries.
                                        """)
                                }

                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Duration: \(String(format: "%.1f", viewModel.hoverMagnificationDuration))s")
                                        Slider(value: $viewModel.hoverMagnificationDuration, in: 0.1...1.0, step: 0.1)
                                    }
                                    HelpButton(helpText: """
                                        How long magnification transitions take.

                                        • 0.1-0.2s: Quick, responsive scaling
                                        • 0.3-0.5s: Smooth, noticeable scaling
                                        • 0.6-1.0s: Elegant, slow scaling

                                        Faster durations feel more responsive for quick window scanning.
                                        """)
                                }

                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Delay: \(String(format: "%.1f", viewModel.hoverMagnificationDelay))s")
                                        Slider(value: $viewModel.hoverMagnificationDelay, in: 0.0...1.0, step: 0.1)
                                    }
                                    HelpButton(helpText: """
                                        Delay before magnification starts when hovering.

                                        • 0.0s: Instant magnification (can be distracting)
                                        • 0.2-0.5s: Brief pause prevents accidental magnification
                                        • 1.0s: Long delay for careful hovering

                                        A small delay prevents windows from constantly scaling when moving the cursor across them.
                                        """)
                                }
                            }
                        }
                    }
                }

                if viewModel.windowBorderSupported {
                    GroupBox("Window Borders") {
                        VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Window Borders", isOn: $viewModel.windowBorder)
                            HelpButton(helpText: """
                                Adds customizable colored borders around windows for enhanced visual distinction.

                                Borders help identify window boundaries and focus states, especially useful when:
                                • Using transparent windows
                                • Working with many windows simultaneously
                                • Wanting clear visual hierarchy

                                Different colors can be set for active vs inactive windows, and borders can have rounded corners and blur effects.
                                """)
                        }

                        if viewModel.windowBorder {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Width: \(Int(viewModel.windowBorderWidth))px")
                                    Slider(value: $viewModel.windowBorderWidth, in: 1...10, step: 1)
                                }
                                HelpButton(helpText: """
                                    Thickness of window borders in pixels.

                                    • 1-2px: Subtle, minimal borders
                                    • 3-5px: Noticeable but not overwhelming
                                    • 6-10px: Bold, prominent borders

                                    Thicker borders are more visible but can make windows feel smaller and may overlap content at window edges.
                                    """)
                            }

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Radius: \(Int(viewModel.windowBorderRadius))px")
                                    Slider(value: $viewModel.windowBorderRadius, in: 0...20, step: 1)
                                }
                                HelpButton(helpText: """
                                    Corner radius for window borders.

                                    • 0px: Sharp, square corners
                                    • 5-10px: Noticeably rounded corners
                                    • 15-20px: Very rounded, pill-like corners

                                    Rounded corners create a more modern, softer appearance. Match this with your system's corner radius preference.
                                    """)
                            }

                            HStack {
                                Toggle("Border Blur", isOn: $viewModel.windowBorderBlur)
                                HelpButton(helpText: """
                                    Adds a soft blur effect to window borders.

                                    • Enabled: Borders have a subtle glow/soft edge effect
                                    • Disabled: Borders have sharp, crisp edges

                                    Blur creates a more elegant, less harsh appearance but can make borders slightly less defined.
                                    """)
                            }

                            HStack {
                                ColorPicker("Active Border Color", selection: $viewModel.activeWindowBorderColor)
                                HelpButton(helpText: """
                                    Border color for the currently focused window.

                                    Choose a color that stands out against your desktop background and window contents. Bright, saturated colors work well for clear focus indication.

                                    Common choices: Blue, Green, Orange, Purple
                                    """)
                            }

                            HStack {
                                ColorPicker("Normal Border Color", selection: $viewModel.normalWindowBorderColor)
                                HelpButton(helpText: """
                                    Border color for inactive (background) windows.

                                    Use a more subdued color than active borders. Gray or muted tones work well to avoid distracting from the focused window.

                                    Should contrast with active color but be much more subtle.
                                    """)
                            }

                            HStack {
                                ColorPicker("Insert Feedback Color", selection: $viewModel.insertFeedbackColor)
                                HelpButton(helpText: """
                                    Color shown when dragging windows to indicate insertion points in the layout.

                                    This visual feedback appears as colored overlays or highlights when you're moving windows around in the bsp layout, showing where the window will be placed.

                                    Choose a bright, noticeable color that clearly indicates drop zones.
                                    """)
                            }
                        }
                    }
                }
                }

                GroupBox("Layout & Animation") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Layout:")
                            Picker("", selection: $viewModel.layout) {
                                Text("BSP").tag(LayoutType.bsp)
                                Text("Stack").tag(LayoutType.stack)
                                Text("Float").tag(LayoutType.float)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            HelpButton(helpText: """
                                The window management algorithm used for new spaces.

                                • BSP (Binary Space Partitioning): Windows are automatically tiled and split into a tree layout. Most efficient for multiple windows.
                                • Stack: Windows are stacked on top of each other, with only the top window visible. Good for focused work.
                                • Float: Windows float freely like normal macOS windows. Traditional window management.

                                BSP is recommended for most users - it automatically manages window positions and sizes.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Window Gap: \(Int(viewModel.windowGap))px")
                                Slider(value: $viewModel.windowGap, in: 0...50, step: 1)
                            }
                            HelpButton(helpText: """
                                Space between adjacent windows in pixels.

                                • 0px: Windows touch edges (no gap)
                                • 6px: Standard spacing (recommended)
                                • 12-24px: More breathing room between windows
                                • 50px+: Very spaced out layout

                                Gaps make window boundaries more obvious and create visual separation, but reduce usable window space.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Animation Duration: \(String(format: "%.1f", viewModel.windowAnimationDuration))s")
                                Slider(value: $viewModel.windowAnimationDuration, in: 0.0...2.0, step: 0.1)
                            }
                            HelpButton(helpText: """
                                How long window layout transitions take when windows are moved, resized, or rearranged.

                                • 0.0s: Instant layout changes (immediate response)
                                • 0.1-0.3s: Quick, responsive animations
                                • 0.5-1.0s: Smooth, noticeable transitions
                                • 2.0s: Very slow, dramatic animations

                                Faster animations feel more responsive but can be jarring. Slower animations look polished but may feel sluggish.
                                """)
                        }

                        HStack {
                            Text("Animation Easing:")
                            Picker("", selection: $viewModel.windowAnimationEasing) {
                                Text("Ease Out Cubic").tag(AnimationEasing.easeOutCubic)
                                Text("Ease In/Out Cubic").tag(AnimationEasing.easeInOutCubic)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                The acceleration/deceleration curve for window animations.

                                • Ease Out Cubic: Starts fast, slows down at end (natural, smooth finish)
                                • Ease In/Out Cubic: Slow start and end, fast middle (most natural feel)

                                Ease In/Out Cubic provides the most natural, iOS-like animation feel and is recommended for most users.
                                """)
                        }

                        Divider()

                        // Metal Animations (Beta)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Toggle("Enable Metal Animations (Beta)", isOn: $viewModel.metalAnimationsEnabled)
                                    .toggleStyle(.switch)
                                HelpButton(helpText: """
                                    Experimental GPU-accelerated window animations using Metal.

                                    Features:
                                    • Liquid window borders that flow like water
                                    • Flowing particle effects around focused windows
                                    • Morphing window shapes during transitions
                                    • Ripple effects on window interactions

                                    Performance:
                                    • Optimized for Apple Silicon (M1/M2/M3)
                                    • Automatic quality scaling based on battery/thermal state
                                    • Graceful fallback to Canvas rendering if needed

                                    This is a beta feature. Requires macOS 15.0+ and may impact battery life during intensive use.
                                    """)
                            }

                            HStack {
                                Toggle("Direct Window Metal Binding (Advanced)", isOn: $viewModel.directWindowMetalEnabled)
                                    .toggleStyle(.switch)
                                HelpButton(helpText: """
                                Attach Metal animations directly to application windows instead of using overlay windows.

                                ⚠️  REQUIREMENTS:
                                • System Integrity Protection (SIP) must be disabled
                                • macOS 15.0+ with Apple Silicon
                                • May cause instability if apps don't handle layer injection well

                                🎯 ADVANTAGES:
                                • True integration with window animations
                                • No separate overlay windows
                                • Perfect synchronization with yabai timing
                                • Lower system overhead

                                If disabled, animations will use transparent overlay windows (safer but less integrated).
                                """)
                            }

                            if viewModel.metalAnimationsEnabled {
                                HStack {
                                    Text("Animation Preset:")
                                    Picker("", selection: $viewModel.animationPreset) {
                                        Text("Minimal").tag(AnimationPreset.minimal)
                                        Text("Liquid").tag(AnimationPreset.liquid)
                                        Text("Rich").tag(AnimationPreset.rich)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                    HelpButton(helpText: """
                                        Preset animation quality levels:

                                        • Minimal: Subtle effects, maximum performance
                                        • Liquid: Balanced effects and performance (recommended)
                                        • Rich: Maximum visual effects, higher resource usage

                                        Presets automatically adjust particle counts, effects, and frame rates based on your hardware capabilities.
                                        """)
                                }

                                HStack {
                                    Text("Performance Mode:")
                                    Picker("", selection: $viewModel.animationPerformanceMode) {
                                        Text("Auto").tag(SettingsAnimationPerformanceMode.auto)
                                        Text("Ultra").tag(SettingsAnimationPerformanceMode.ultra)
                                        Text("High").tag(SettingsAnimationPerformanceMode.high)
                                        Text("Medium").tag(SettingsAnimationPerformanceMode.medium)
                                        Text("Low").tag(SettingsAnimationPerformanceMode.low)
                                        Text("Minimal").tag(SettingsAnimationPerformanceMode.minimal)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                    HelpButton(helpText: """
                                        Animation performance and quality control:

                                        • Auto: Automatically adjusts based on battery, temperature, and system load
                                        • Ultra/High/Medium: Manual quality levels
                                        • Low/Minimal: Reduced effects for maximum battery life

                                        Auto mode is recommended - it provides beautiful animations while preserving system performance.
                                        """)
                                }
                            }
                        }
                    }
                }

                // Animation Testing & Diagnostics
                GroupBox("Animation Testing (Beta)") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test and optimize Metal animations on your system.")
                            .foregroundColor(.secondary)

                        HStack {
                            Button(action: {
                                // Show test harness window
                                let testView = AnimationTestView()
                                let hostingController = NSHostingController(rootView: testView)

                                let window = NSWindow(
                                    contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                                    styleMask: [.titled, .closable, .resizable],
                                    backing: .buffered,
                                    defer: false
                                )

                                window.center()
                                window.title = "Animation Test Suite"
                                window.contentViewController = hostingController
                                window.makeKeyAndOrderFront(nil)
                            }) {
                                Label("Open Test Suite", systemImage: "testtube.2")
                            }

                            Button(action: {
                                // Show performance monitor
                                let monitorView = PerformanceDashboardView()
                                let hostingController = NSHostingController(rootView: monitorView)

                                let window = NSWindow(
                                    contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                                    styleMask: [.titled, .closable, .resizable],
                                    backing: .buffered,
                                    defer: false
                                )

                                window.center()
                                window.title = "Performance Monitor"
                                window.contentViewController = hostingController
                                window.makeKeyAndOrderFront(nil)
                            }) {
                                Label("Performance Monitor", systemImage: "gauge")
                            }

                            HelpButton(helpText: """
                                Comprehensive testing suite for Metal animations.

                                Tests include:
                                • Metal initialization and shader compilation
                                • Particle rendering performance
                                • Battery and thermal impact assessment
                                • Visual quality verification
                                • Performance optimization recommendations

                                Use this to ensure animations work correctly on your system and get personalized optimization suggestions.
                                """)
                        }

                        Text("Note: Test results help optimize animations for your specific hardware configuration.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                GroupBox("Padding") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Top: \(Int(viewModel.topPadding))px")
                                Slider(value: $viewModel.topPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space at the top of each display, pushing windows down from the screen edge.

                                Useful for:
                                • Making room for menu bars or status bars
                                • Preventing windows from appearing behind notches
                                • Creating consistent top margins

                                Top padding is applied to all spaces on all displays.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Bottom: \(Int(viewModel.bottomPadding))px")
                                Slider(value: $viewModel.bottomPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space at the bottom of each display, pushing windows up from the screen edge.

                                Useful for:
                                • Dock accommodation (if not using auto-hide)
                                • Creating bottom margins for visual balance
                                • Preventing windows from being obscured by screen features

                                Bottom padding is applied to all spaces on all displays.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Left: \(Int(viewModel.leftPadding))px")
                                Slider(value: $viewModel.leftPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space on the left side of each display, pushing windows in from the left edge.

                                Useful for:
                                • Creating left margins for visual balance
                                • Making room for side panels or widgets
                                • Accounting for asymmetric screen layouts

                                Left padding is applied to all spaces on all displays.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Right: \(Int(viewModel.rightPadding))px")
                                Slider(value: $viewModel.rightPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space on the right side of each display, pushing windows in from the right edge.

                                Useful for:
                                • Creating right margins for visual balance
                                • Making room for side panels or widgets
                                • Accounting for asymmetric screen layouts

                                Right padding is applied to all spaces on all displays.
                                """)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct SpaceSettingsView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    @State private var selectedSpace: Int = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Global Space Settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("These settings apply to all spaces unless overridden")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HelpButton(helpText: """
                                Global space settings affect all spaces across all displays.

                                These are the baseline settings that apply everywhere. Individual spaces can have their own overrides for gap and padding, but most users keep these consistent across all spaces for a uniform experience.

                                Changes here affect all existing and new spaces immediately.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Space Gap: \(Int(viewModel.windowGap))px")
                                Slider(value: $viewModel.windowGap, in: 0...50, step: 1)
                            }
                            HelpButton(helpText: """
                                The default gap between windows in all spaces.

                                This creates visual breathing room between windows and makes boundaries more obvious. A gap of 6px is the yabai default and works well for most displays.

                                Larger gaps create more visual separation but reduce the space available for window content. Very small or zero gaps create a more minimal, touch-edge appearance.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Top Padding: \(Int(viewModel.topPadding))px")
                                Slider(value: $viewModel.topPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space at the top of each space, pushing all windows down from the top screen edge.

                                Useful for:
                                • Menu bar accommodation (set to ~25px)
                                • Notch avoidance on MacBook Pro
                                • Creating consistent top margins
                                • Making room for external status bars

                                Applied to all spaces globally.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Bottom Padding: \(Int(viewModel.bottomPadding))px")
                                Slider(value: $viewModel.bottomPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space at the bottom of each space, pushing all windows up from the bottom screen edge.

                                Useful for:
                                • Dock accommodation when not auto-hiding (set to ~80px)
                                • Creating bottom margins for balance
                                • Avoiding screen features or bezels
                                • Preventing windows from being obscured by screen features

                                Applied to all spaces globally.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Left Padding: \(Int(viewModel.leftPadding))px")
                                Slider(value: $viewModel.leftPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space on the left side of each space, pushing all windows in from the left edge.

                                Useful for:
                                • Creating left margins for visual balance
                                • Making room for side panels or widgets
                                • Accounting for asymmetric monitor setups
                                • Avoiding screen features on the left edge

                                Applied to all spaces globally.
                                """)
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Right Padding: \(Int(viewModel.rightPadding))px")
                                Slider(value: $viewModel.rightPadding, in: 0...100, step: 1)
                            }
                            HelpButton(helpText: """
                                Empty space on the right side of each space, pushing all windows in from the right edge.

                                Useful for:
                                • Creating right margins for visual balance
                                • Making room for side panels or widgets
                                • Accounting for asymmetric monitor setups
                                • Avoiding screen features on the right edge

                                Right padding is applied to all spaces globally.
                                """)
                        }
                    }
                }

                GroupBox("Space-Specific Settings") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Configure individual spaces (coming in future update)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HelpButton(helpText: """
                                Future feature: Configure individual spaces with custom settings.

                                This will allow different spaces to have:
                                • Different gap sizes
                                • Different padding values
                                • Different layouts (bsp, stack, float)
                                • Custom labels and colors

                                For example, you could have:
                                • Space 1 (Web): Large padding, relaxed layout
                                • Space 2 (Code): Small gaps, focused layout
                                • Space 3 (Design): Float layout for creative work
                                """)
                        }

                        HStack {
                            Text("Space:")
                            Picker("", selection: $selectedSpace) {
                                ForEach(1...10, id: \.self) { space in
                                    Text("Space \(space)").tag(space)
                                }
                            }
                            .pickerStyle(.menu)
                            .disabled(true) // Not implemented yet
                            HelpButton(helpText: """
                                Select which space to configure individually.

                                Once implemented, this dropdown will let you choose a specific space (1-10) and customize its settings independently of the global defaults.

                                Useful for creating specialized workspaces, like a dedicated coding space with minimal gaps or a design space with floating layout.
                                """)
                        }
                    }
                }

                GroupBox("Space Management") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Quick Actions")
                                .font(.headline)
                            HelpButton(helpText: """
                                Immediate actions you can perform on the current space.

                                These buttons provide direct access to common space operations without needing keyboard shortcuts. All actions apply to whichever space is currently active.

                                Use these for quick layout adjustments or when learning yabai before setting up keyboard shortcuts.
                                """)
                        }

                        HStack(spacing: 12) {
                            Button("Balance Current Space") {
                                Task {
                                    try await viewModel.balanceWindows()
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Redistribute window sizes to create balanced proportions")

                            Button("Mirror X-Axis") {
                                Task {
                                    try await viewModel.mirrorSpace(axis: .x)
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Flip the layout horizontally (left-right mirror)")

                            Button("Mirror Y-Axis") {
                                Task {
                                    try await viewModel.mirrorSpace(axis: .y)
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Flip the layout vertically (top-bottom mirror)")
                        }

                        HStack(spacing: 12) {
                            Button("Rotate 90°") {
                                Task {
                                    try await viewModel.rotateSpace(degrees: 90)
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Rotate the entire layout 90 degrees clockwise")

                            Button("Rotate 180°") {
                                Task {
                                    try await viewModel.rotateSpace(degrees: 180)
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Rotate the entire layout 180 degrees (upside down)")

                            Button("Rotate 270°") {
                                Task {
                                    try await viewModel.rotateSpace(degrees: 270)
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Rotate the entire layout 270 degrees clockwise")
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct DisplaySettingsView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    @State private var selectedDisplay: Int = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Display Management") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Configure display-specific settings and behavior")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HelpButton(helpText: """
                                Control how yabai behaves with multiple displays.

                                In multi-monitor setups, you can configure:
                                • Which display gets focus when switching
                                • How windows are distributed across displays
                                • Display-specific layout balancing
                                • Window placement rules for different screens

                                These settings help create a seamless multi-monitor experience where windows behave predictably across your display array.
                                """)
                        }

                        HStack {
                            Text("Focus Display:")
                            Picker("", selection: $selectedDisplay) {
                                ForEach(1...3, id: \.self) { display in
                                    Text("Display \(display)").tag(display)
                                }
                            }
                            .pickerStyle(.segmented)
                            HelpButton(helpText: """
                                Select which display to perform actions on.

                                When you have multiple monitors connected, this determines which display the action buttons below will affect. Displays are numbered starting from your primary display (usually the one with the menu bar).

                                Useful for managing windows on specific monitors without having to manually focus that display first.
                                """)
                        }

                        HStack(spacing: 12) {
                            Button("Focus Display \(selectedDisplay)") {
                                Task {
                                    try await viewModel.focusDisplay(index: UInt32(selectedDisplay))
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Make display \(selectedDisplay) the active display (moves focus and mouse there)")

                            Button("Balance Display \(selectedDisplay)") {
                                Task {
                                    try await viewModel.balanceDisplay()
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Redistribute window sizes on display \(selectedDisplay) to create balanced proportions")
                        }
                    }
                }

                GroupBox("Window Placement") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("New Window Display:")
                            Picker("", selection: $viewModel.windowOriginDisplay) {
                                Text("Default").tag(WindowOriginDisplay.default)
                                Text("Focused").tag(WindowOriginDisplay.focused)
                                Text("Cursor").tag(WindowOriginDisplay.cursor)
                            }
                            .labelsHidden()
                            HelpButton(helpText: """
                                Determines which display new windows open on when launched.

                                • Default: Uses macOS default behavior (usually the display with the active application)
                                • Focused: Opens on the display that contains the currently focused window
                                • Cursor: Opens on the display where your mouse cursor is currently located

                                This setting ensures new windows appear on the display you're actively using, reducing the need to manually move windows between displays.
                                """)
                        }

                        HStack {
                            Text("This setting controls where new application windows appear when launched.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HelpButton(helpText: """
                                Window placement is crucial in multi-monitor setups.

                                Without proper placement rules, new windows might open on the "wrong" display, forcing you to manually move them. This setting ensures windows open where you expect them to.

                                The Cursor option is particularly useful if you tend to launch applications while your mouse is already on the target display.
                                """)
                        }
                    }
                }

                GroupBox("Display Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Display Query (coming in future update)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HelpButton(helpText: """
                                Future feature: Real-time display information and configuration.

                                This section will provide:
                                • Connected display details (resolution, position, refresh rate)
                                • Display arrangement visualization
                                • Per-display padding overrides
                                • Display-specific layout settings
                                • Display connection/disconnection handling

                                Useful for power users with complex multi-monitor setups who need granular control over each display's behavior.
                                """)
                        }

                        HStack {
                            Text("This section will show information about connected displays and allow configuration of display-specific padding and layout.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            HelpButton(helpText: """
                                Advanced multi-monitor management is planned for this section.

                                Currently, yabai treats all displays somewhat uniformly. Future versions will allow:
                                • Different gap sizes per display
                                • Different padding per display
                                • Display-specific layout algorithms
                                • Custom display labels and identification

                                This will be especially useful for users with displays of different sizes or orientations.
                                """)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct RulesSettingsView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("Window Rules")
                        .font(.title3)
                        .fontWeight(.semibold)
                    HelpButton(helpText: """
                        Window Rules: Advanced automation for specific applications and windows.

                        Rules allow you to create exceptions to yabai's normal behavior for specific windows or applications. For example:

                        • Make certain apps float instead of tile (design tools, video players)
                        • Give specific windows custom opacity or borders
                        • Exclude problematic applications from yabai management
                        • Create sticky windows that appear on all spaces

                        Rules are processed in order, so more specific rules should come before general ones. Use the Test Rules feature to ensure your rules work as expected.

                        Common use cases:
                        • Floating: Video calls, system preferences, design palettes
                        • Sticky: Always-visible utilities, dashboards, monitors
                        • Opacity: Reduce visual clutter for background apps
                        • Layer: Control window stacking order
                        """)
                }

                Spacer()

                HStack {
                    Button(action: { showRuleEditorWindow(nil) }) {
                        Label("Add Rule", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isApplying)

                    HelpButton(helpText: """
                        Create a new window rule.

                        Opens the rule editor where you can specify:
                        • Which windows/applications to match (by name, role, etc.)
                        • What behavior to apply (float, sticky, opacity, etc.)
                        • A descriptive label for the rule

                        Rules are applied immediately when created and will affect existing windows that match the criteria.

                        Tip: Start with broad rules and add more specific ones as needed. Test each rule by opening the target application.
                        """)
                }
            }
            .padding(.horizontal)

            if viewModel.rules.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No rules configured")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Rules allow you to automatically apply specific behaviors to windows based on their properties.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Create Your First Rule") {
                        showRuleEditorWindow(nil)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 40)
            } else {
                List {
                    ForEach(viewModel.rules) { rule in
                        RuleRowView(rule: rule, viewModel: viewModel)
                            .contextMenu {
                                Button("Edit") {
                                    showRuleEditorWindow(rule)
                                }

                                Button("Delete", role: .destructive) {
                                    if let index = viewModel.rules.firstIndex(where: { $0.id == rule.id }) {
                                        Task {
                                            try await viewModel.removeRule(at: index)
                                        }
                                    }
                                }
                            }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                try await viewModel.removeRule(at: index)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(.vertical)
    }

    private func showRuleEditorWindow(_ editingRule: YabaiRule?) {
        let windowController = RuleEditorWindowController(
            editingRule: editingRule,
            onSave: { rule in
                Task {
                    do {
                        if editingRule != nil,
                           let index = self.viewModel.rules.firstIndex(where: { $0.id == editingRule!.id }) {
                            try await self.viewModel.updateRule(rule, at: index)
                        } else {
                            try await self.viewModel.addRule(rule)
                        }
                    } catch {
                        // Show error alert
                        let alert = NSAlert()
                        alert.messageText = "Error Saving Rule"
                        alert.informativeText = error.localizedDescription
                        alert.runModal()
                    }
                }
            },
            onCancel: {
                // Handle cancel - window will close automatically
            }
        )

        windowController.showWindow()
    }

}

struct InlineRuleEditor: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    let editingRule: YabaiRule?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var app: String = ""
    @State private var title: String = ""
    @State private var role: String = ""
    @State private var subrole: String = ""
    @State private var manage: YabaiRule.ManageState = .on
    @State private var sticky: YabaiRule.StickyState = .off
    @State private var mouseFollowsFocus: Bool = false
    @State private var layer: YabaiRule.WindowLayer = .normal
    @State private var opacity: Double = 1.0
    @State private var border: YabaiRule.BorderState = .off
    @State private var label: String = ""

    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case app, title, role, subrole, label
    }

    init(viewModel: ComprehensiveSettingsViewModel, editingRule: YabaiRule?, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.viewModel = viewModel
        self.editingRule = editingRule
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize state from editing rule
        if let rule = editingRule {
            _app = State(initialValue: rule.app ?? "")
            _title = State(initialValue: rule.title ?? "")
            _role = State(initialValue: rule.role ?? "")
            _subrole = State(initialValue: rule.subrole ?? "")
            _manage = State(initialValue: rule.manage ?? .on)
            _sticky = State(initialValue: rule.sticky ?? .off)
            _mouseFollowsFocus = State(initialValue: rule.mouseFollowsFocus ?? false)
            _layer = State(initialValue: rule.layer ?? .normal)
            _opacity = State(initialValue: rule.opacity ?? 1.0)
            _border = State(initialValue: rule.border ?? .off)
            _label = State(initialValue: rule.label ?? "")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Modern header with gradient
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 60)

                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: editingRule == nil ? "plus.circle.fill" : "pencil.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(editingRule == nil ? "Create New Rule" : "Edit Rule")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Configure window management behavior")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            }

            Divider()

            // Beautiful scrollable content with cards
            ScrollView {
                VStack(spacing: 24) {
                    // Window Matching Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.3.group")
                                .foregroundColor(.blue)
                            Text("Window Matching")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        VStack(spacing: 16) {
                            ModernTextField(
                                title: "Application Name",
                                placeholder: "e.g., Safari, Terminal",
                                text: $app
                            )
                            .focused($focusedField, equals: .app)

                            ModernTextField(
                                title: "Window Title",
                                placeholder: "e.g., Untitled, Settings",
                                text: $title
                            )
                            .focused($focusedField, equals: .title)

                            HStack(spacing: 16) {
                                ModernTextField(
                                    title: "Window Role",
                                    placeholder: "e.g., AXWindow",
                                    text: $role
                                )
                                .focused($focusedField, equals: .role)

                                ModernTextField(
                                    title: "Window Subrole",
                                    placeholder: "e.g., AXStandardWindow",
                                    text: $subrole
                                )
                                .focused($focusedField, equals: .subrole)
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Behavior Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                                .foregroundColor(.green)
                            Text("Window Behavior")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Management")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $manage) {
                                        Text("Manage Window").tag(YabaiRule.ManageState.on)
                                        Text("Don't Manage").tag(YabaiRule.ManageState.off)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sticky Behavior")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Picker("", selection: $sticky) {
                                        Text("Normal").tag(YabaiRule.StickyState.off)
                                        Text("Sticky").tag(YabaiRule.StickyState.on)
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mouse Behavior")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Toggle("Mouse follows focus", isOn: $mouseFollowsFocus)
                                    .toggleStyle(.switch)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Window Layer")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Picker("", selection: $layer) {
                                    Text("Normal").tag(YabaiRule.WindowLayer.normal)
                                    Text("Below Others").tag(YabaiRule.WindowLayer.below)
                                    Text("Above Others").tag(YabaiRule.WindowLayer.above)
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Appearance Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "paintbrush")
                                .foregroundColor(.orange)
                            Text("Appearance")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Window Border")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Picker("", selection: $border) {
                                    Text("No Border").tag(YabaiRule.BorderState.off)
                                    Text("Show Border").tag(YabaiRule.BorderState.on)
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Window Opacity")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(opacity * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Slider(value: $opacity, in: 0.0...1.0, step: 0.1)
                                    .accentColor(.blue)
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Label Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "tag")
                                .foregroundColor(.purple)
                            Text("Rule Label")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        ModernTextField(
                            title: "Descriptive Name",
                            placeholder: "e.g., Floating Terminal, Sticky Calendar",
                            text: $label
                        )
                        .focused($focusedField, equals: .label)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Validation message
                    if !isValidRule {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            Text("Please specify at least one matching criterion (app, title, role, or subrole)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }

            Divider()

            // Modern footer with gradient
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.05), Color.gray.opacity(0.1)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 60)

                HStack {
                    Spacer()

                    Button(action: onCancel) {
                        Text("Cancel")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape)

                    Button(action: saveRule) {
                        Text(editingRule == nil ? "Create Rule" : "Save Changes")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidRule)
                    .keyboardShortcut(.return)
                }
                .padding(.horizontal, 24)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .onSubmit {
            // Handle keyboard navigation
            switch focusedField {
            case .app:
                focusedField = .title
            case .title:
                focusedField = .role
            case .role:
                focusedField = .subrole
            case .subrole:
                focusedField = .label
            case .label:
                if isValidRule {
                    saveRule()
                }
            case .none:
                focusedField = .app
            }
        }
    }

    private var isValidRule: Bool {
        !(app.isEmpty && title.isEmpty && role.isEmpty && subrole.isEmpty)
    }

    private func saveRule() {
        let rule = YabaiRule(
            app: app.isEmpty ? nil : app,
            title: title.isEmpty ? nil : title,
            role: role.isEmpty ? nil : role,
            subrole: subrole.isEmpty ? nil : subrole,
            manage: manage,
            sticky: sticky,
            mouseFollowsFocus: mouseFollowsFocus,
            layer: layer,
            opacity: opacity,
            border: border,
            label: label.isEmpty ? nil : label
        )

        Task {
            do {
                if let editingRule = editingRule,
                   let index = viewModel.rules.firstIndex(where: { $0.id == editingRule.id }) {
                    try await viewModel.updateRule(rule, at: index)
                } else {
                    try await viewModel.addRule(rule)
                }
                onSave()
            } catch {
                print("Error saving rule: \(error)")
            }
        }
    }
}

struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 14))
        }
    }
}

struct RuleRowView: View {
    let rule: YabaiRule
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(rule.displayName)
                    .font(.headline)

                Spacer()

                if rule.manage == .off {
                    Text("Don't Manage")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }

                if rule.sticky == .on {
                    Text("Sticky")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                if rule.opacity != nil && rule.opacity != 1.0 {
                    Text("Opacity: \(String(format: "%.1f", rule.opacity ?? 1.0))")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 16) {
                if let app = rule.app {
                    Label(app, systemImage: "app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let title = rule.title {
                    Label(title, systemImage: "text.bubble")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let role = rule.role {
                    Label(role, systemImage: "rectangle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// Pure NSTextField implementation for guaranteed keyboard input
struct AppKitTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var fontSize: CGFloat = 14

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = text
        textField.placeholderString = placeholder
        textField.font = NSFont.systemFont(ofSize: fontSize)
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.backgroundColor = .textBackgroundColor
        textField.textColor = .textColor
        textField.isEditable = true
        textField.isSelectable = true
        textField.delegate = context.coordinator

        // Ensure the text field can become first responder
        textField.refusesFirstResponder = false

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Only update if the values are different to avoid cursor jumping
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        if nsView.placeholderString != placeholder {
            nsView.placeholderString = placeholder
        }
        nsView.font = NSFont.systemFont(ofSize: fontSize)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            self._text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                // Update binding immediately when text changes
                DispatchQueue.main.async {
                    self.text = textField.stringValue
                }
            }
        }

        func controlTextDidEndEditing(_ obj: Notification) {
            // Final update when editing ends
            if let textField = obj.object as? NSTextField {
                DispatchQueue.main.async {
                    self.text = textField.stringValue
                }
            }
        }
    }
}

// NSTextField wrapper for proper keyboard input
struct TextFieldWrapper: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        nsView.placeholderString = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            self._text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                text = textField.stringValue
            }
        }
    }
}


struct SignalsSettingsView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    @State private var showingSignalEditor = false
    @State private var editingSignal: YabaiSignal?

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("Signals & Automation")
                        .font(.title3)
                        .fontWeight(.semibold)
                    HelpButton(helpText: """
                        Signals: Event-driven automation and scripting integration.

                        Signals allow yabai to execute custom commands when specific events occur in your window management session. This enables powerful automation and integration with other tools.

                        Available events:
                        • Application lifecycle (launched, terminated, focus changes)
                        • Window events (created, destroyed, moved, resized, minimized)
                        • Space changes (created, destroyed, switched)
                        • Display changes (added, removed, moved, resized)

                        Common use cases:
                        • Refresh status bars when spaces change (sketchybar, simple-bar)
                        • Auto-focus specific applications when they launch
                        • Run scripts when displays are connected/disconnected
                        • Update external tools when windows are created/destroyed

                        Signals execute asynchronously and won't block yabai's normal operation. Use them to keep your desktop environment in sync with external tools and scripts.

                        Example signal: "window_focused" → "sketchybar --trigger window_focus"
                        """)
                }

                Spacer()

                // Feature flag toggle
                Toggle("Structured Signal Editor (Beta)", isOn: $viewModel.useStructuredSignalEditor)
                    .toggleStyle(.switch)
                    .help("Enable the new visual signal editor with app dropdowns and action builder")

                HStack {
                    Button(action: {
                        editingSignal = nil
                        showingSignalEditor = true
                    }) {
                        Label("Add Signal", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isApplying)

                    HelpButton(helpText: """
                        Create a new automation signal.

                        Opens the signal editor where you can:
                        • Choose which event triggers the signal
                        • Specify the command to execute
                        • Optionally filter by application
                        • Add a descriptive label

                        Signals execute immediately when their trigger event occurs. Test your commands manually first to ensure they work correctly.

                        Common commands:
                        • sketchybar --trigger [event]
                        • simple-bar --update
                        • ~/.config/yabai/scripts/[script].sh
                        • yabai -m [additional yabai command]

                        Start simple: create a signal that logs to console, then build up to more complex automation.
                        """)
                }
            }
            .padding(.horizontal)

            if showingSignalEditor {
                // Beautiful inline signal editor
                InlineSignalEditor(
                    viewModel: viewModel,
                    editingSignal: editingSignal,
                    onSave: {
                        showingSignalEditor = false
                        editingSignal = nil
                    },
                    onCancel: {
                        showingSignalEditor = false
                        editingSignal = nil
                    }
                )
                .transition(.opacity)
                .animation(.easeInOut, value: showingSignalEditor)
            } else if viewModel.signals.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bolt")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No signals configured")
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Signals allow you to run custom commands when specific yabai events occur.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Create Your First Signal") {
                        editingSignal = nil
                        showingSignalEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 40)
            } else {
                List {
                    ForEach(viewModel.signals) { signal in
                        SignalRowView(signal: signal, viewModel: viewModel)
                            .contextMenu {
                                Button("Edit") {
                                    editingSignal = signal
                                    showingSignalEditor = true
                                }

                                Button("Delete", role: .destructive) {
                                    if let index = viewModel.signals.firstIndex(where: { $0.id == signal.id }) {
                                        Task {
                                            try await viewModel.removeSignal(at: index)
                                        }
                                    }
                                }
                            }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                try await viewModel.removeSignal(at: index)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(.vertical)
    }

}

struct InlineSignalEditor: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    let editingSignal: YabaiSignal?
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var event: YabaiSignal.SignalEvent = .window_created
    @State private var action: String = ""
    @State private var structuredActions: [SignalAction] = []
    @State private var app: String = ""
    @State private var excludeApp: String = ""
    @State private var label: String = ""

    @FocusState private var focusedField: SignalField?
    enum SignalField: Hashable {
        case app, excludeApp, action, label
    }

    init(viewModel: ComprehensiveSettingsViewModel, editingSignal: YabaiSignal?, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.viewModel = viewModel
        self.editingSignal = editingSignal
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize state from editing signal
        if let signal = editingSignal {
            _event = State(initialValue: signal.event)
            _action = State(initialValue: signal.action)
            _structuredActions = State(initialValue: signal.structuredActions ?? [])
            _app = State(initialValue: signal.app ?? "")
            _excludeApp = State(initialValue: signal.excludeApp ?? "")
            _label = State(initialValue: signal.label ?? "")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Modern header with gradient
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.green.opacity(0.1), Color.teal.opacity(0.1)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 60)

                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: editingSignal == nil ? "bolt.circle.fill" : "bolt.trianglebadge.exclamationmark")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(editingSignal == nil ? "Create New Signal" : "Edit Signal")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text("Set up event-driven automation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            }

            Divider()

            // Beautiful scrollable content with cards
            ScrollView {
                VStack(spacing: 24) {
                    // Event Selection Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "cursorarrow.click")
                                .foregroundColor(.green)
                            Text("Trigger Event")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Type")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("", selection: $event) {
                                Group {
                                    Text("Application Launched").tag(YabaiSignal.SignalEvent.application_launched)
                                    Text("Application Terminated").tag(YabaiSignal.SignalEvent.application_terminated)
                                    Text("Application Front Switched").tag(YabaiSignal.SignalEvent.application_front_switched)
                                    Text("Application Activated").tag(YabaiSignal.SignalEvent.application_activated)
                                    Text("Application Deactivated").tag(YabaiSignal.SignalEvent.application_deactivated)
                                    Text("Application Hidden").tag(YabaiSignal.SignalEvent.application_hidden)
                                    Text("Application Visible").tag(YabaiSignal.SignalEvent.application_visible)
                                }

                                Group {
                                    Text("Window Created").tag(YabaiSignal.SignalEvent.window_created)
                                    Text("Window Destroyed").tag(YabaiSignal.SignalEvent.window_destroyed)
                                    Text("Window Focused").tag(YabaiSignal.SignalEvent.window_focused)
                                    Text("Window Moved").tag(YabaiSignal.SignalEvent.window_moved)
                                    Text("Window Resized").tag(YabaiSignal.SignalEvent.window_resized)
                                    Text("Window Minimized").tag(YabaiSignal.SignalEvent.window_minimized)
                                    Text("Window Deminimized").tag(YabaiSignal.SignalEvent.window_deminimized)
                                    Text("Window Title Changed").tag(YabaiSignal.SignalEvent.window_title_changed)
                                }

                                Group {
                                    Text("Space Created").tag(YabaiSignal.SignalEvent.space_created)
                                    Text("Space Destroyed").tag(YabaiSignal.SignalEvent.space_destroyed)
                                    Text("Space Changed").tag(YabaiSignal.SignalEvent.space_changed)
                                    Text("Display Added").tag(YabaiSignal.SignalEvent.display_added)
                                    Text("Display Removed").tag(YabaiSignal.SignalEvent.display_removed)
                                    Text("Display Moved").tag(YabaiSignal.SignalEvent.display_moved)
                                    Text("Display Resized").tag(YabaiSignal.SignalEvent.display_resized)
                                    Text("Display Changed").tag(YabaiSignal.SignalEvent.display_changed)
                                    Text("Mouse Clicked").tag(YabaiSignal.SignalEvent.mouse_clicked)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()

                            Text("The yabai event that will trigger this signal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Application Filter Card
                    Group {
                        if viewModel.useStructuredSignalEditor {
                            AppDropdownView(
                                selectedApp: $app,
                                title: "Specific Application",
                                placeholder: "Select application"
                            )

                            AppDropdownView(
                                selectedApp: $excludeApp,
                                title: "Exclude Application",
                                placeholder: "Select application to exclude"
                            )
                        } else {
                            ModernTextField(
                                title: "Specific Application (optional)",
                                placeholder: "e.g., Safari, Terminal",
                                text: $app
                            )
                            .focused($focusedField, equals: .app)

                            ModernTextField(
                                title: "Exclude Application (optional)",
                                placeholder: "e.g., Finder, System Settings",
                                text: $excludeApp
                            )
                            .focused($focusedField, equals: .excludeApp)
                        }
                    }

                    Text("Leave empty to trigger on any application, or use exclude to skip specific apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Action Builder Card
                    Group {
                        if viewModel.useStructuredSignalEditor {
                            ActionBuilderView(
                                structuredActions: $structuredActions,
                                title: "Actions"
                            )

                            // Live Shell Preview Card
                            LiveShellPreview(
                                structuredActions: $structuredActions,
                                rawAction: $action,
                                title: "Live Preview"
                            )
                        } else {
                            ModernTextField(
                                title: "Command to Execute",
                                placeholder: "Shell command",
                                text: $action
                            )
                            .focused($focusedField, equals: .action)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Common Examples:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• yabai -m window --focus next")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("• sketchybar --trigger window_focus")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("• ~/.config/yabai/scripts/refresh.sh")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("• simple-bar --update")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Signal Label Card
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "tag")
                                .foregroundColor(.purple)
                            Text("Signal Label")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        ModernTextField(
                            title: "Descriptive Name",
                            placeholder: "e.g., Focus Notification, Space Changed",
                            text: $label
                        )
                        .focused($focusedField, equals: .label)

                        Text("Optional name to help identify this signal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    )

                    // Validation message
                    if structuredActions.isEmpty && action.trimmingCharacters(in: .whitespaces).isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            Text("Please specify actions to execute")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }

            Divider()

            // Modern footer with gradient
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.05), Color.gray.opacity(0.1)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 60)

                HStack {
                    Spacer()

                    Button(action: onCancel) {
                        Text("Cancel")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape)

                    Button(action: saveSignal) {
                        Text(editingSignal == nil ? "Create Signal" : "Save Changes")
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(structuredActions.isEmpty && action.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return)
                }
                .padding(.horizontal, 24)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(.windowBackgroundColor))
        .onSubmit {
            // Handle keyboard navigation
            switch focusedField {
            case .app:
                focusedField = .excludeApp
            case .excludeApp:
                focusedField = .action
            case .action:
                focusedField = .label
            case .label:
                if !structuredActions.isEmpty || !action.trimmingCharacters(in: .whitespaces).isEmpty {
                    saveSignal()
                }
            case .none:
                focusedField = .app
            }
        }
    }

    private func saveSignal() {
        let signal = YabaiSignal(
            event: event,
            action: action.trimmingCharacters(in: .whitespaces),
            label: label.isEmpty ? nil : label,
            app: app.isEmpty ? nil : app,
            excludeApp: excludeApp.isEmpty ? nil : excludeApp,
            structuredActions: structuredActions.isEmpty ? nil : structuredActions
        )

        Task {
            do {
                if let editingSignal = editingSignal,
                   let index = viewModel.signals.firstIndex(where: { $0.id == editingSignal.id }) {
                    try await viewModel.updateSignal(signal, at: index)
                } else {
                    try await viewModel.addSignal(signal)
                }
                onSave()
            } catch {
                print("Error saving signal: \(error)")
            }
        }
    }
}

struct SignalRowView: View {
    let signal: YabaiSignal
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(signal.displayName)
                    .font(.headline)

                Spacer()

                Text(signal.event.rawValue)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }

            HStack(spacing: 16) {
                Label("Action: \(signal.action)", systemImage: "terminal")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let app = signal.app {
                    Label("App: \(app)", systemImage: "app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let excludeApp = signal.excludeApp {
                    Label("Exclude: \(excludeApp)", systemImage: "app.badge")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// NSTextField wrapper for proper keyboard input
struct SignalTextFieldWrapper: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text
        textField.placeholderString = placeholder
        textField.delegate = context.coordinator
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        nsView.placeholderString = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            self._text = text
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                text = textField.stringValue
            }
        }
    }
}

struct SignalEditorView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    let editingSignal: YabaiSignal?
    var onDismiss: (() -> Void)?

    @State private var event: YabaiSignal.SignalEvent = .window_created
    @State private var action: String = ""
    @State private var label: String = ""
    @State private var app: String = ""
    @State private var excludeApp: String = ""

    // Focus management
    @FocusState private var focusedField: SignalField?
    enum SignalField: Hashable {
        case app, excludeApp, action, label
    }

    init(viewModel: ComprehensiveSettingsViewModel, editingSignal: YabaiSignal?, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.editingSignal = editingSignal
        self.onDismiss = {
            // Stop the modal session and call the dismiss callback
            NSApp.stopModal()
            onDismiss?()
        }

        // Initialize state from editing signal
        if let signal = editingSignal {
            _event = State(initialValue: signal.event)
            _action = State(initialValue: signal.action)
            _label = State(initialValue: signal.label ?? "")
            _app = State(initialValue: signal.app ?? "")
            _excludeApp = State(initialValue: signal.excludeApp ?? "")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(editingSignal == nil ? "Add Signal" : "Edit Signal")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { onDismiss?() }) {
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

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GroupBox("Trigger Event") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Event Type")
                                .font(.headline)

                            Picker("", selection: $event) {
                                Group {
                                    Text("Application Launched").tag(YabaiSignal.SignalEvent.application_launched)
                                    Text("Application Terminated").tag(YabaiSignal.SignalEvent.application_terminated)
                                    Text("Application Front Switched").tag(YabaiSignal.SignalEvent.application_front_switched)
                                    Text("Application Activated").tag(YabaiSignal.SignalEvent.application_activated)
                                    Text("Application Deactivated").tag(YabaiSignal.SignalEvent.application_deactivated)
                                    Text("Application Hidden").tag(YabaiSignal.SignalEvent.application_hidden)
                                    Text("Application Visible").tag(YabaiSignal.SignalEvent.application_visible)
                                }

                                Group {
                                    Text("Window Created").tag(YabaiSignal.SignalEvent.window_created)
                                    Text("Window Destroyed").tag(YabaiSignal.SignalEvent.window_destroyed)
                                    Text("Window Focused").tag(YabaiSignal.SignalEvent.window_focused)
                                    Text("Window Moved").tag(YabaiSignal.SignalEvent.window_moved)
                                    Text("Window Resized").tag(YabaiSignal.SignalEvent.window_resized)
                                    Text("Window Minimized").tag(YabaiSignal.SignalEvent.window_minimized)
                                    Text("Window Deminimized").tag(YabaiSignal.SignalEvent.window_deminimized)
                                    Text("Window Title Changed").tag(YabaiSignal.SignalEvent.window_title_changed)
                                }

                                Group {
                                    Text("Space Created").tag(YabaiSignal.SignalEvent.space_created)
                                    Text("Space Destroyed").tag(YabaiSignal.SignalEvent.space_destroyed)
                                    Text("Space Changed").tag(YabaiSignal.SignalEvent.space_changed)
                                    Text("Display Added").tag(YabaiSignal.SignalEvent.display_added)
                                    Text("Display Removed").tag(YabaiSignal.SignalEvent.display_removed)
                                    Text("Display Moved").tag(YabaiSignal.SignalEvent.display_moved)
                                    Text("Display Resized").tag(YabaiSignal.SignalEvent.display_resized)
                                    Text("Display Changed").tag(YabaiSignal.SignalEvent.display_changed)
                                    Text("Mouse Clicked").tag(YabaiSignal.SignalEvent.mouse_clicked)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(height: 120)

                            Text("The yabai event that will trigger this signal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    GroupBox("Application Filter") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Specific Application (Optional)")
                                .font(.headline)
                            AppKitTextField(text: $app, placeholder: "e.g., Safari, Terminal")
                                .frame(height: 24)

                            Text("Exclude Application (Optional)")
                                .font(.headline)
                            AppKitTextField(text: $excludeApp, placeholder: "e.g., Finder, System Settings")
                                .frame(height: 24)

                            Text("Leave empty to trigger on any application, or use exclude to skip specific apps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    GroupBox("Action Command") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Command to Execute")
                                .font(.headline)
                            AppKitTextField(text: $action, placeholder: "Shell command")
                                .frame(height: 24)
                            Text("Shell command to run when the event occurs")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Common Examples:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• yabai -m window --focus next")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• sketchybar --trigger window_focus")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• ~/.config/yabai/scripts/refresh.sh")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("• simple-bar --update")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    GroupBox("Signal Label") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Descriptive Name")
                                .font(.headline)
                            AppKitTextField(text: $label, placeholder: "e.g., Focus Notification, Space Changed")
                                .frame(height: 24)
                            Text("Optional name to help identify this signal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Validation message
                    if action.trimmingCharacters(in: .whitespaces).isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Please specify a command to execute")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }

            Divider()

            // Footer with buttons
            HStack {
                Spacer()

                Button("Cancel") {
                    onDismiss?()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)

                Button(editingSignal == nil ? "Add Signal" : "Save Changes") {
                    saveSignal()
                }
                .buttonStyle(.borderedProminent)
                .disabled(action.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.return)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.windowBackgroundColor))
        }
        .frame(minWidth: 600, maxWidth: 800, minHeight: 700, maxHeight: 900)
        .background(Color(.windowBackgroundColor))
    }

    private func saveSignal() {
        let signal = YabaiSignal(
            event: event,
            action: action.trimmingCharacters(in: .whitespaces),
            label: label.isEmpty ? nil : label,
            app: app.isEmpty ? nil : app,
            excludeApp: excludeApp.isEmpty ? nil : excludeApp
        )

        Task {
            do {
                if let editingSignal = editingSignal,
                   let index = viewModel.signals.firstIndex(where: { $0.id == editingSignal.id }) {
                    try await viewModel.updateSignal(signal, at: index)
                } else {
                    try await viewModel.addSignal(signal)
                }
                onDismiss?()
            } catch {
                // Handle error - in a real app, show an alert
                print("Error saving signal: \(error)")
            }
        }
    }
}

struct PresetsSettingsView: View {
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    @State private var showingCreatePreset = false
    @State private var showingImportDialog = false
    @State private var presetName = ""

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("Configuration Presets")
                        .font(.title3)
                        .fontWeight(.semibold)
                    HelpButton(helpText: """
                        Presets: Save and restore complete yabai configurations.

                        Presets capture your entire yabai setup including:
                        • All global configuration settings
                        • Window rules and their parameters
                        • Signal handlers and automation
                        • Layout preferences and padding

                        Built-in presets provide starting points for common use cases:
                        • Default: Standard yabai behavior
                        • Minimalist: Clean, minimal aesthetics
                        • Gaming: Optimized for gaming (float layout, no gaps)
                        • Coding: Focused development environment

                        Custom presets let you save your perfected setup and quickly restore it later. Perfect for:
                        • Switching between work contexts (coding vs design)
                        • Testing new configurations safely
                        • Sharing setups with others
                        • Backup and recovery

                        Create presets often - they're like save points for your window management configuration!
                        """)
                }

                Spacer()

                HStack {
                    Menu {
                        Button("Create from Current") {
                            showingCreatePreset = true
                        }

                        Button("Import from File...") {
                            showingImportDialog = true
                        }

                        Button("Export Current...") {
                            exportCurrentConfig()
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                    .menuStyle(.borderedButton)

                    HelpButton(helpText: """
                        Advanced preset management actions.

                        • Create from Current: Save your current configuration as a new preset
                        • Import from File: Load a preset from a saved file (JSON format)
                        • Export Current: Save your current setup to a file for backup or sharing

                        Use Export when you want to:
                        • Backup your perfect configuration
                        • Share your setup with others
                        • Transfer settings between machines
                        • Keep versions of different configurations

                        Imported presets are added to your custom presets collection.
                        """)
                }
            }
            .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Built-in Presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Built-in Presets")
                            .font(.headline)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                            PresetCard(preset: .default, viewModel: viewModel, helpText: """
                                The standard yabai configuration - a great starting point for most users.

                                Features:
                                • 6px window gaps for clean separation
                                • Normal window shadows and opacity
                                • Focus follows mouse disabled (manual focus)
                                • BSP layout for automatic tiling
                                • Standard 0.5 split ratios
                                • Autobalance enabled for consistent proportions

                                This preset provides yabai's default behavior while adding the visual polish of gaps and balanced layouts. Perfect for users new to tiling window managers.
                                """)
                            PresetCard(preset: .minimalist, viewModel: viewModel, helpText: """
                                Clean, minimal aesthetics with enhanced focus-follows-mouse behavior.

                                Features:
                                • 12px gaps for more breathing room
                                • Disabled window shadows for flat, modern look
                                • Focus follows mouse with autoraise
                                • 70% menu bar transparency
                                • BSP layout with balanced splits
                                • Mouse follows focus enabled

                                Designed for users who want a clean, distraction-free environment. The larger gaps and autoraise focus behavior create a more relaxed, less click-heavy experience. Great for focused work sessions.
                                """)
                            PresetCard(preset: .gaming, viewModel: viewModel, helpText: """
                                Optimized for gaming and media consumption.

                                Features:
                                • Float layout (no automatic tiling)
                                • Zero window gaps for maximum screen real estate
                                • Disabled shadows and opacity effects
                                • Focus follows mouse disabled
                                • Floating windows don't stay on top
                                • No auto-balance (manual control)

                                Perfect for gaming, video playback, and any scenario where you want traditional macOS window behavior without yabai's tiling interference. Windows behave like normal macOS windows.
                                """)
                            PresetCard(preset: .coding, viewModel: viewModel, helpText: """
                                Optimized for development and coding workflows.

                                Features:
                                • 8px window gaps (clean but not excessive)
                                • Autofocus mouse behavior (smooth but not intrusive)
                                • BSP layout with 0.6 split ratios (wider code windows)
                                • Auto-balance enabled for consistency
                                • Normal shadows and opacity
                                • Mouse follows focus for cursor tracking

                                Designed for programmers and developers who benefit from:
                                • Wider windows for code editing (60% splits favor width)
                                • Consistent layouts across spaces
                                • Smooth focus transitions
                                • Clean visual hierarchy without distractions
                                """)
                        }
                    }

                    // Custom Presets
                    if !viewModel.customPresets.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Custom Presets")
                                .font(.headline)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 12) {
                                ForEach(viewModel.customPresets) { preset in
                                    CustomPresetCard(preset: preset, viewModel: viewModel)
                                }
                            }
                        }
                    }

                    // Backup Management
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Backup & Restore")
                                .font(.headline)
                            HelpButton(helpText: """
                                Automatic and manual backups of your yabai configuration.

                                YabaiPro automatically creates timestamped backups before making any changes to your ~/.yabairc file. This ensures you can always recover from accidental misconfigurations.

                                Backup files are stored as:
                                ~/.yabairc.backup.YYYY-MM-DD_HH-MM-SS

                                Manual backups are useful for:
                                • Creating save points before major changes
                                • Preserving known-good configurations
                                • Testing experimental setups safely

                                Restore operations replace your current ~/.yabairc with the backup version. Changes take effect immediately - you may need to restart applications for full effect.

                                Keep several backups - disk space is cheap, frustration from lost configurations is expensive!
                                """)
                        }

                        HStack {
                            Button("Create Backup") {
                                Task {
                                    try await viewModel.createBackup()
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Manually create a timestamped backup of current configuration")

                            Button("Restore Latest") {
                                Task {
                                    try await viewModel.restoreLatestBackup()
                                }
                            }
                            .buttonStyle(.bordered)
                            .help("Replace current config with the most recent backup")

                            Spacer()

                            HStack {
                                Text("\(viewModel.listBackups().count) backups available")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HelpButton(helpText: """
                                    Shows how many backup files exist.

                                    Each backup represents a snapshot of your configuration at a specific point in time. More backups mean more recovery options.

                                    Backups are created:
                                    • Automatically before any changes via YabaiPro
                                    • Manually when you click 'Create Backup'
                                    • When using 'Apply Changes' (not Preview)

                                    Old backups are never automatically deleted - you can manually remove them if you run low on disk space.
                                    """)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .padding(.vertical)
        .alert("Create Preset", isPresented: $showingCreatePreset) {
            TextField("Preset Name", text: $presetName)
            Button("Cancel", role: .cancel) {
                presetName = ""
            }
            Button("Create") {
                viewModel.createPreset(name: presetName)
                presetName = ""
            }
        } message: {
            Text("Save current configuration as a reusable preset")
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                if let file = files.first {
                    importPreset(from: file)
                }
            case .failure:
                // Handle error
                break
            }
        }
    }

    private func exportCurrentConfig() {
        // TODO: Implement export functionality
    }

    private func importPreset(from url: URL) {
        // TODO: Implement import functionality
    }
}

struct PresetCard: View {
    let preset: PresetConfig
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel
    let helpText: String?

    init(preset: PresetConfig, viewModel: ComprehensiveSettingsViewModel, helpText: String? = nil) {
        self.preset = preset
        self.viewModel = viewModel
        self.helpText = helpText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(preset.name)
                    .font(.headline)

                if let helpText = helpText {
                    HelpButton(helpText: helpText)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .opacity(isCurrentPreset ? 1 : 0)
            }

            if let description = preset.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if let rulesCount = preset.rules?.count, rulesCount > 0 {
                    Label("\(rulesCount)", systemImage: "list.bullet")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let signalsCount = preset.signals?.count, signalsCount > 0 {
                    Label("\(signalsCount)", systemImage: "bolt")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(preset.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Button("Apply Preset") {
                Task {
                    try await viewModel.applyPreset(preset)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isApplying)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrentPreset ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    private var isCurrentPreset: Bool {
        // TODO: Implement logic to check if this preset matches current config
        false
    }
}

struct CustomPresetCard: View {
    let preset: PresetConfig
    @ObservedObject var viewModel: ComprehensiveSettingsViewModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PresetCard(preset: preset, viewModel: viewModel)

            Button {
                viewModel.deletePreset(preset)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .padding(4)
        }
    }
}
