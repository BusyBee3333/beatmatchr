//
//  CommandPaletteView.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import SwiftUI

struct CommandPaletteView: View {
    @State private var searchText = ""
    @State private var selectedCommand: Command?

    private let commandRunner = YabaiCommandRunner()

    var commands: [Command] {
        [
        // Window commands
        Command(name: "Focus North", action: { try await commandRunner.focusWindow(direction: .north) }),
        Command(name: "Focus East", action: { try await commandRunner.focusWindow(direction: .east) }),
        Command(name: "Focus South", action: { try await commandRunner.focusWindow(direction: .south) }),
        Command(name: "Focus West", action: { try await commandRunner.focusWindow(direction: .west) }),
        Command(name: "Float Window", action: { try await commandRunner.toggleWindowFloat() }),
        Command(name: "Fullscreen Window", action: { try await commandRunner.toggleWindowFullscreen() }),
        Command(name: "Stack Window", action: { try await commandRunner.stackWindow(direction: .north) }),
        Command(name: "Toggle Window Split", action: { try await commandRunner.toggleWindowSplit() }),
        Command(name: "Zoom Parent", action: { try await commandRunner.toggleWindowZoomParent() }),

        // Advanced Positioning Commands
        Command(name: "Move to Top-Left", action: { try await commandRunner.moveWindowAbsolute(x: 100, y: 100) }),
        Command(name: "Move to Top-Right", action: { try await commandRunner.moveWindowAbsolute(x: 1200, y: 100) }),
        Command(name: "Move to Bottom-Left", action: { try await commandRunner.moveWindowAbsolute(x: 100, y: 700) }),
        Command(name: "Move to Bottom-Right", action: { try await commandRunner.moveWindowAbsolute(x: 1200, y: 700) }),
        Command(name: "Move Center", action: { try await commandRunner.moveWindowAbsolute(x: 600, y: 400) }),
        Command(name: "Resize Editor Size", action: { try await commandRunner.resizeWindowAbsolute(width: 1400, height: 900) }),
        Command(name: "Resize Sidebar", action: { try await commandRunner.resizeWindowAbsolute(width: 600, height: 900) }),
        Command(name: "Resize Terminal", action: { try await commandRunner.resizeWindowAbsolute(width: 1400, height: 250) }),
        Command(name: "Move Left 50px", action: { try await commandRunner.moveWindowRelative(deltaX: -50, deltaY: 0) }),
        Command(name: "Move Right 50px", action: { try await commandRunner.moveWindowRelative(deltaX: 50, deltaY: 0) }),
        Command(name: "Move Up 50px", action: { try await commandRunner.moveWindowRelative(deltaX: 0, deltaY: -50) }),
        Command(name: "Move Down 50px", action: { try await commandRunner.moveWindowRelative(deltaX: 0, deltaY: 50) }),

        // Cursor + Brave Layout Presets
        Command(name: "Cursor + Brave: Main Layout", action: { try await commandRunner.applyCursorBraveMainLayout() }),
        Command(name: "Cursor + Brave: Research Layout", action: { try await commandRunner.applyCursorBraveResearchLayout() }),
        Command(name: "Cursor + Brave: API Layout", action: { try await commandRunner.applyCursorBraveAPILayout() }),

        // Space commands
        Command(name: "Create Space", action: { _ = try await commandRunner.createSpace() }),
        Command(name: "Balance Space", action: { try await commandRunner.balanceSpace() }),
        Command(name: "Mirror X", action: { try await commandRunner.mirrorSpace(axis: .x) }),
        Command(name: "Mirror Y", action: { try await commandRunner.mirrorSpace(axis: .y) }),
        Command(name: "Rotate 90°", action: { try await commandRunner.rotateSpace(degrees: 90) }),
        Command(name: "Rotate 180°", action: { try await commandRunner.rotateSpace(degrees: 180) }),
        Command(name: "Rotate 270°", action: { try await commandRunner.rotateSpace(degrees: 270) }),

        // Display commands
        Command(name: "Focus Next Display", action: { try await commandRunner.focusDisplayNext() }),
        Command(name: "Focus Previous Display", action: { try await commandRunner.focusDisplayPrev() }),
        Command(name: "Focus Recent Display", action: { try await commandRunner.focusDisplayRecent() }),
        Command(name: "Focus Display with Mouse", action: { try await commandRunner.focusDisplayMouse() }),
        Command(name: "Balance Display", action: { try await commandRunner.balanceDisplay() }),

        // Layout commands
        Command(name: "Set BSP Layout", action: { try await commandRunner.setConfig("layout", value: "bsp") }),
        Command(name: "Set Stack Layout", action: { try await commandRunner.setConfig("layout", value: "stack") }),
        Command(name: "Set Float Layout", action: { try await commandRunner.setConfig("layout", value: "float") }),
        ]
    }

    var filteredCommands: [Command] {
        if searchText.isEmpty {
            return commands
        }
        return commands.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search commands...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))

            Divider()

            // Command list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredCommands, id: \.name) { command in
                        Button(action: {
                            Task {
                                do {
                                    try await command.action()
                                } catch {
                                    print("Command failed: \(error)")
                                }
                            }
                        }) {
                            HStack {
                                Text(command.name)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            selectedCommand?.name == command.name ?
                            Color(.selectedControlColor) : Color.clear
                        )

                        if command.name != filteredCommands.last?.name {
                            Divider()
                                .padding(.horizontal, 12)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 350)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separatorColor), lineWidth: 1)
        )
    }
}

struct Command: Identifiable {
    let id = UUID()
    let name: String
    let action: () async throws -> Void
}

// Preview
struct CommandPaletteView_Previews: PreviewProvider {
    static var previews: some View {
        CommandPaletteView()
    }
}
