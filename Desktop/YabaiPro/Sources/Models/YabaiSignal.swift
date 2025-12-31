//
//  YabaiSignal.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

struct YabaiSignal: Identifiable, Codable, Equatable {
    var id = UUID()
    var index: Int?
    var event: SignalEvent
    var action: String
    var label: String?
    var app: String?
    var title: String?
    var active: Bool?
    var excludeApp: String?
    var structuredActions: [SignalAction]?

    enum SignalEvent: String, Codable {
        case application_launched
        case application_terminated
        case application_front_switched
        case application_activated
        case application_deactivated
        case application_hidden
        case application_visible
        case window_created
        case window_destroyed
        case window_focused
        case window_moved
        case window_resized
        case window_minimized
        case window_deminimized
        case window_title_changed
        case space_created
        case space_destroyed
        case space_changed
        case display_added
        case display_removed
        case display_moved
        case display_resized
        case display_changed
        case mouse_clicked
    }

    var displayName: String {
        if let label = label, !label.isEmpty {
            return label
        }

        if let actions = structuredActions, !actions.isEmpty {
            let actionNames = actions.map { $0.displayName }.joined(separator: " + ")
            return "\(event.rawValue) → \(actionNames)"
        }

        return "\(event.rawValue) → \(action)"
    }

    var description: String {
        var desc = "Event: \(event.rawValue)"

        if let actions = structuredActions, !actions.isEmpty {
            let actionDescriptions = actions.map { "\($0.displayName) (\($0.toShellCommand()))" }.joined(separator: "; ")
            desc += ", Actions: \(actionDescriptions)"
        } else {
            desc += ", Action: \(action)"
        }

        if let index = index {
            desc += ", Index: \(index)"
        }
        if let app = app, !app.isEmpty {
            desc += ", App: \(app)"
        }
        if let excludeApp = excludeApp, !excludeApp.isEmpty {
            desc += ", Exclude App: \(excludeApp)"
        }
        return desc
    }
}

extension YabaiSignal {
    static func fromYabaiOutput(_ output: String) -> [YabaiSignal] {
        // Parse yabai -m signal --list output (JSON format)
        guard let data = output.data(using: .utf8) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let signals = try? decoder.decode([YabaiSignal].self, from: data) else {
            return []
        }
        return signals
    }

    /// Attempt to migrate a raw action string into structured actions
    static func migrateActionString(_ actionString: String) -> [SignalAction]? {
        // Split by common separators
        let separators = [" && ", "; "]
        var commands = [actionString]

        for separator in separators {
            if actionString.contains(separator) {
                commands = actionString.components(separatedBy: separator)
                break
            }
        }

        var structuredActions: [SignalAction] = []

        for command in commands {
            let trimmedCommand = command.trimmingCharacters(in: .whitespaces)

            if let action = parseSingleCommand(trimmedCommand) {
                structuredActions.append(action)
            } else {
                // If any command can't be parsed, return nil (can't migrate)
                return nil
            }
        }

        return structuredActions.isEmpty ? nil : structuredActions
    }

    private static func parseSingleCommand(_ command: String) -> SignalAction? {
        let trimmed = command.trimmingCharacters(in: .whitespaces)

        // Handle shell commands (not yabai commands)
        if !trimmed.hasPrefix("yabai -m ") {
            return SignalAction(command: .shellCommand, parameters: ["command": trimmed])
        }

        // Remove "yabai -m " prefix
        let yabaiCommand = String(trimmed.dropFirst("yabai -m ".count))

        // Parse different command types
        if yabaiCommand.hasPrefix("window --focus ") {
            let direction = String(yabaiCommand.dropFirst("window --focus ".count))
            return SignalAction(command: .windowFocus, parameters: ["direction": direction])
        }

        if yabaiCommand.hasPrefix("window --swap ") {
            let direction = String(yabaiCommand.dropFirst("window --swap ".count))
            return SignalAction(command: .windowSwap, parameters: ["direction": direction])
        }

        if yabaiCommand.hasPrefix("window --warp ") {
            let direction = String(yabaiCommand.dropFirst("window --warp ".count))
            return SignalAction(command: .windowWarp, parameters: ["direction": direction])
        }

        if yabaiCommand == "window --toggle float" {
            return SignalAction(command: .windowToggleFloat, parameters: [:])
        }

        if yabaiCommand == "window --toggle zoom-fullscreen" {
            return SignalAction(command: .windowToggleFullscreen, parameters: [:])
        }

        if yabaiCommand == "window --toggle stack" {
            return SignalAction(command: .windowToggleStack, parameters: [:])
        }

        if yabaiCommand.hasPrefix("window --move abs:") {
            let coords = String(yabaiCommand.dropFirst("window --move abs:".count))
            let parts = coords.split(separator: ":")
            if parts.count == 2 {
                return SignalAction(command: .windowMoveAbsolute,
                                   parameters: ["x": String(parts[0]), "y": String(parts[1])])
            }
        }

        if yabaiCommand.hasPrefix("window --move rel:") {
            let coords = String(yabaiCommand.dropFirst("window --move rel:".count))
            let parts = coords.split(separator: ":")
            if parts.count == 2 {
                return SignalAction(command: .windowMoveRelative,
                                   parameters: ["x": String(parts[0]), "y": String(parts[1])])
            }
        }

        if yabaiCommand.hasPrefix("window --resize abs:") {
            let dims = String(yabaiCommand.dropFirst("window --resize abs:".count))
            let parts = dims.split(separator: ":")
            if parts.count == 2 {
                return SignalAction(command: .windowResizeAbsolute,
                                   parameters: ["width": String(parts[0]), "height": String(parts[1])])
            }
        }

        if yabaiCommand.hasPrefix("window --resize rel:") {
            let dims = String(yabaiCommand.dropFirst("window --resize rel:".count))
            let parts = dims.split(separator: ":")
            if parts.count == 2 {
                return SignalAction(command: .windowResizeRelative,
                                   parameters: ["width": String(parts[0]), "height": String(parts[1])])
            }
        }

        if yabaiCommand.hasPrefix("window --space ") {
            let space = String(yabaiCommand.dropFirst("window --space ".count))
            return SignalAction(command: .windowMoveToSpace, parameters: ["space": space])
        }

        if yabaiCommand.hasPrefix("window --display ") {
            let display = String(yabaiCommand.dropFirst("window --display ".count))
            return SignalAction(command: .windowMoveToDisplay, parameters: ["display": display])
        }

        if yabaiCommand.hasPrefix("config window_opacity ") {
            let state = String(yabaiCommand.dropFirst("config window_opacity ".count))
            return SignalAction(command: .configWindowOpacity, parameters: ["state": state])
        }

        if yabaiCommand.hasPrefix("config active_window_opacity ") {
            let opacity = String(yabaiCommand.dropFirst("config active_window_opacity ".count))
            return SignalAction(command: .configWindowOpacityActive, parameters: ["opacity": opacity])
        }

        if yabaiCommand.hasPrefix("config normal_window_opacity ") {
            let opacity = String(yabaiCommand.dropFirst("config normal_window_opacity ".count))
            return SignalAction(command: .configWindowOpacityNormal, parameters: ["opacity": opacity])
        }

        if yabaiCommand.hasPrefix("config window_shadow ") {
            let state = String(yabaiCommand.dropFirst("config window_shadow ".count))
            return SignalAction(command: .configWindowShadow, parameters: ["state": state])
        }

        if yabaiCommand.hasPrefix("config mouse_follows_focus ") {
            let state = String(yabaiCommand.dropFirst("config mouse_follows_focus ".count))
            return SignalAction(command: .configMouseFollowsFocus, parameters: ["state": state])
        }

        if yabaiCommand.hasPrefix("config focus_follows_mouse ") {
            let state = String(yabaiCommand.dropFirst("config focus_follows_mouse ".count))
            return SignalAction(command: .configFocusFollowsMouse, parameters: ["state": state])
        }

        if yabaiCommand.hasPrefix("space --focus ") {
            let index = String(yabaiCommand.dropFirst("space --focus ".count))
            return SignalAction(command: .spaceFocus, parameters: ["index": index])
        }

        if yabaiCommand == "space --balance" {
            return SignalAction(command: .spaceBalance, parameters: [:])
        }

        if yabaiCommand.hasPrefix("display --focus ") {
            let index = String(yabaiCommand.dropFirst("display --focus ".count))
            return SignalAction(command: .displayFocus, parameters: ["index": index])
        }

        if yabaiCommand == "display --focus next" {
            return SignalAction(command: .displayFocusNext, parameters: [:])
        }

        if yabaiCommand == "display --focus prev" {
            return SignalAction(command: .displayFocusPrev, parameters: [:])
        }

        if yabaiCommand == "display --focus recent" {
            return SignalAction(command: .displayFocusRecent, parameters: [:])
        }

        if yabaiCommand == "display --focus mouse" {
            return SignalAction(command: .displayFocusMouse, parameters: [:])
        }

        // If we can't parse it, return nil
        return nil
    }
}




