//
//  SignalActionModels.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

/// Represents a single yabai command action in a signal
struct SignalAction: Codable, Identifiable, Equatable {
    var id = UUID()
    var command: YabaiCommand
    var parameters: [String: String]

    enum YabaiCommand: String, Codable, CaseIterable {
        // Window commands
        case windowFocus = "window_focus"
        case windowSwap = "window_swap"
        case windowWarp = "window_warp"
        case windowToggleFloat = "window_toggle_float"
        case windowToggleFullscreen = "window_toggle_fullscreen"
        case windowToggleStack = "window_toggle_stack"
        case windowUnstack = "window_unstack"
        case windowInsert = "window_insert"
        case windowToggleSplit = "window_toggle_split"
        case windowMoveAbsolute = "window_move_absolute"
        case windowMoveRelative = "window_move_relative"
        case windowResizeAbsolute = "window_resize_absolute"
        case windowResizeRelative = "window_resize_relative"
        case windowToggleOpacity = "window_toggle_opacity"
        case windowToggleShadow = "window_toggle_shadow"
        case windowToggleBorder = "window_toggle_border"
        case windowMoveToSpace = "window_move_to_space"
        case windowMoveToDisplay = "window_move_to_display"
        case windowToggleZoomParent = "window_toggle_zoom_parent"
        case windowToggleZoomFullscreen = "window_toggle_zoom_fullscreen"
        case windowToggleExposé = "window_toggle_exposé"
        case windowTogglePip = "window_toggle_pip"

        // Space commands
        case spaceFocus = "space_focus"
        case spaceBalance = "space_balance"
        case spaceMirror = "space_mirror"
        case spaceRotate = "space_rotate"
        case spaceCreate = "space_create"
        case spaceDestroy = "space_destroy"
        case spaceMove = "space_move"
        case spaceLabel = "space_label"
        case spaceMoveToDisplay = "space_move_to_display"
        case spaceLayout = "space_layout"
        case spaceRotateSpecific = "space_rotate_specific"
        case spaceMirrorSpecific = "space_mirror_specific"
        case spaceBalanceSpecific = "space_balance_specific"
        case spacePadding = "space_padding"
        case spaceGap = "space_gap"

        // Display commands
        case displayFocus = "display_focus"
        case displayBalance = "display_balance"
        case displayFocusNext = "display_focus_next"
        case displayFocusPrev = "display_focus_prev"
        case displayFocusRecent = "display_focus_recent"
        case displayFocusMouse = "display_focus_mouse"
        case displayBalanceSpecific = "display_balance_specific"

        // Config commands
        case configWindowOpacity = "config_window_opacity"
        case configWindowOpacityActive = "config_window_opacity_active"
        case configWindowOpacityNormal = "config_window_opacity_normal"
        case configWindowShadow = "config_window_shadow"
        case configMouseFollowsFocus = "config_mouse_follows_focus"
        case configFocusFollowsMouse = "config_focus_follows_mouse"

        // Custom shell command
        case shellCommand = "shell_command"
    }

    var displayName: String {
        switch command {
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
        case .shellCommand: return "Run Shell Command"
        }
    }

    func toShellCommand() -> String {
        switch command {
        // Window commands
        case .windowFocus:
            if let direction = parameters["direction"] {
                return "yabai -m window --focus \(direction)"
            }
        case .windowSwap:
            if let direction = parameters["direction"] {
                return "yabai -m window --swap \(direction)"
            }
        case .windowWarp:
            if let direction = parameters["direction"] {
                return "yabai -m window --warp \(direction)"
            }
        case .windowToggleFloat:
            return "yabai -m window --toggle float"
        case .windowToggleFullscreen:
            return "yabai -m window --toggle zoom-fullscreen"
        case .windowToggleStack:
            return "yabai -m window --toggle stack"
        case .windowUnstack:
            return "yabai -m window --toggle float"
        case .windowInsert:
            if let position = parameters["position"] {
                return "yabai -m window --insert \(position)"
            }
        case .windowToggleSplit:
            return "yabai -m window --toggle split"
        case .windowMoveAbsolute:
            if let x = parameters["x"], let y = parameters["y"] {
                return "yabai -m window --move abs:\(x):\(y)"
            }
        case .windowMoveRelative:
            if let x = parameters["x"], let y = parameters["y"] {
                return "yabai -m window --move rel:\(x):\(y)"
            }
        case .windowResizeAbsolute:
            if let width = parameters["width"], let height = parameters["height"] {
                return "yabai -m window --resize abs:\(width):\(height)"
            }
        case .windowResizeRelative:
            if let width = parameters["width"], let height = parameters["height"] {
                return "yabai -m window --resize rel:\(width):\(height)"
            }
        case .windowToggleOpacity:
            return "yabai -m window --toggle opacity"
        case .windowToggleShadow:
            return "yabai -m window --toggle shadow"
        case .windowToggleBorder:
            return "yabai -m window --toggle border"
        case .windowMoveToSpace:
            if let space = parameters["space"] {
                return "yabai -m window --space \(space)"
            }
        case .windowMoveToDisplay:
            if let display = parameters["display"] {
                return "yabai -m window --display \(display)"
            }
        case .windowToggleZoomParent:
            return "yabai -m window --toggle zoom-parent"
        case .windowToggleZoomFullscreen:
            return "yabai -m window --toggle zoom-fullscreen"
        case .windowToggleExposé:
            return "yabai -m window --toggle exposé"
        case .windowTogglePip:
            return "yabai -m window --toggle pip"

        // Space commands
        case .spaceFocus:
            if let index = parameters["index"] {
                return "yabai -m space --focus \(index)"
            }
        case .spaceBalance:
            return "yabai -m space --balance"
        case .spaceMirror:
            if let axis = parameters["axis"] {
                return "yabai -m space --mirror \(axis)-axis"
            }
        case .spaceRotate:
            if let degrees = parameters["degrees"] {
                return "yabai -m space --rotate \(degrees)"
            }
        case .spaceCreate:
            return "yabai -m space --create"
        case .spaceDestroy:
            if let index = parameters["index"] {
                return "yabai -m space --destroy \(index)"
            }
        case .spaceMove:
            if let from = parameters["from"], let to = parameters["to"] {
                return "yabai -m space \(from) --move \(to)"
            }
        case .spaceLabel:
            if let index = parameters["index"], let label = parameters["label"] {
                return "yabai -m space \(index) --label \"\(label)\""
            }
        case .spaceMoveToDisplay:
            if let space = parameters["space"], let display = parameters["display"] {
                return "yabai -m space \(space) --display \(display)"
            }
        case .spaceLayout:
            if let index = parameters["index"], let layout = parameters["layout"] {
                return "yabai -m space \(index) --layout \(layout)"
            }
        case .spaceRotateSpecific:
            if let index = parameters["index"], let degrees = parameters["degrees"] {
                return "yabai -m space \(index) --rotate \(degrees)"
            }
        case .spaceMirrorSpecific:
            if let index = parameters["index"], let axis = parameters["axis"] {
                return "yabai -m space \(index) --mirror \(axis)-axis"
            }
        case .spaceBalanceSpecific:
            if let index = parameters["index"] {
                return "yabai -m space \(index) --balance"
            }
        case .spacePadding:
            if let index = parameters["index"],
               let top = parameters["top"], let bottom = parameters["bottom"],
               let left = parameters["left"], let right = parameters["right"] {
                let padding = "\(top):\(bottom):\(left):\(right)"
                return "yabai -m space \(index) --padding abs:\(padding)"
            }
        case .spaceGap:
            if let index = parameters["index"], let gap = parameters["gap"] {
                return "yabai -m space \(index) --gap abs:\(gap)"
            }

        // Display commands
        case .displayFocus:
            if let index = parameters["index"] {
                return "yabai -m display --focus \(index)"
            }
        case .displayBalance:
            return "yabai -m display --balance"
        case .displayFocusNext:
            return "yabai -m display --focus next"
        case .displayFocusPrev:
            return "yabai -m display --focus prev"
        case .displayFocusRecent:
            return "yabai -m display --focus recent"
        case .displayFocusMouse:
            return "yabai -m display --focus mouse"
        case .displayBalanceSpecific:
            if let index = parameters["index"] {
                return "yabai -m display \(index) --balance"
            }

        // Config commands
        case .configWindowOpacity:
            if let state = parameters["state"] {
                return "yabai -m config window_opacity \(state)"
            }
        case .configWindowOpacityActive:
            if let opacity = parameters["opacity"] {
                return "yabai -m config active_window_opacity \(opacity)"
            }
        case .configWindowOpacityNormal:
            if let opacity = parameters["opacity"] {
                return "yabai -m config normal_window_opacity \(opacity)"
            }
        case .configWindowShadow:
            if let state = parameters["state"] {
                return "yabai -m config window_shadow \(state)"
            }
        case .configMouseFollowsFocus:
            if let state = parameters["state"] {
                return "yabai -m config mouse_follows_focus \(state)"
            }
        case .configFocusFollowsMouse:
            if let state = parameters["state"] {
                return "yabai -m config focus_follows_mouse \(state)"
            }

        case .shellCommand:
            return parameters["command"] ?? ""
        }

        return "# Invalid command configuration"
    }
}

/// Schema defining the parameters required for each command type
struct CommandSchema {
    let command: SignalAction.YabaiCommand
    let parameters: [ParameterSchema]

    struct ParameterSchema {
        let key: String
        let label: String
        let type: ParameterType
        let required: Bool
        let defaultValue: String?
        let options: [String]?

        init(key: String, label: String, type: ParameterType, required: Bool, defaultValue: String?, options: [String]? = nil) {
            self.key = key
            self.label = label
            self.type = type
            self.required = required
            self.defaultValue = defaultValue
            self.options = options
        }

        enum ParameterType {
            case text
            case number
            case slider(min: Double, max: Double, step: Double)
            case picker
            case toggle
        }
    }

    static func schema(for command: SignalAction.YabaiCommand) -> CommandSchema {
        switch command {
        case .windowFocus, .windowSwap, .windowWarp:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "direction", label: "Direction", type: .picker, required: true, defaultValue: nil,
                               options: ["north", "east", "south", "west", "prev", "next", "first", "last"])
            ])

        case .windowInsert:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "position", label: "Position", type: .picker, required: true, defaultValue: nil,
                               options: ["north", "east", "south", "west"])
            ])

        case .windowMoveAbsolute, .windowMoveRelative:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "x", label: "X Position", type: .number, required: true, defaultValue: "0"),
                ParameterSchema(key: "y", label: "Y Position", type: .number, required: true, defaultValue: "0")
            ])

        case .windowResizeAbsolute, .windowResizeRelative:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "width", label: "Width", type: .number, required: true, defaultValue: "800"),
                ParameterSchema(key: "height", label: "Height", type: .number, required: true, defaultValue: "600")
            ])

        case .windowMoveToSpace:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "space", label: "Space Index", type: .number, required: true, defaultValue: "1")
            ])

        case .windowMoveToDisplay:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "display", label: "Display Index", type: .number, required: true, defaultValue: "1")
            ])

        case .spaceFocus, .spaceDestroy, .spaceLabel, .spaceLayout, .spaceRotateSpecific, .spaceMirrorSpecific, .spaceBalanceSpecific:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "index", label: "Space Index", type: .number, required: true, defaultValue: "1")
            ])

        case .spaceMirror, .spaceMirrorSpecific:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "axis", label: "Axis", type: .picker, required: true, defaultValue: nil,
                               options: ["x", "y"])
            ])

        case .spaceRotate, .spaceRotateSpecific:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "degrees", label: "Degrees", type: .picker, required: true, defaultValue: nil,
                               options: ["90", "180", "270"])
            ])

        case .spaceMove:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "from", label: "From Space", type: .number, required: true, defaultValue: "1"),
                ParameterSchema(key: "to", label: "To Space", type: .number, required: true, defaultValue: "2")
            ])

        case .spaceMoveToDisplay:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "space", label: "Space Index", type: .number, required: true, defaultValue: "1"),
                ParameterSchema(key: "display", label: "Display Index", type: .number, required: true, defaultValue: "1")
            ])

        case .spacePadding:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "index", label: "Space Index", type: .number, required: true, defaultValue: "1"),
                ParameterSchema(key: "top", label: "Top", type: .number, required: true, defaultValue: "0"),
                ParameterSchema(key: "bottom", label: "Bottom", type: .number, required: true, defaultValue: "0"),
                ParameterSchema(key: "left", label: "Left", type: .number, required: true, defaultValue: "0"),
                ParameterSchema(key: "right", label: "Right", type: .number, required: true, defaultValue: "0")
            ])

        case .spaceGap:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "index", label: "Space Index", type: .number, required: true, defaultValue: "1"),
                ParameterSchema(key: "gap", label: "Gap Size", type: .number, required: true, defaultValue: "0")
            ])

        case .displayFocus, .displayBalanceSpecific:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "index", label: "Display Index", type: .number, required: true, defaultValue: "1")
            ])

        case .configWindowOpacity, .configWindowShadow, .configMouseFollowsFocus, .configFocusFollowsMouse:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "state", label: "State", type: .picker, required: true, defaultValue: nil,
                               options: ["on", "off"])
            ])

        case .configWindowOpacityActive, .configWindowOpacityNormal:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "opacity", label: "Opacity", type: .slider(min: 0.0, max: 1.0, step: 0.1), required: true, defaultValue: "1.0")
            ])

        case .shellCommand:
            return CommandSchema(command: command, parameters: [
                ParameterSchema(key: "command", label: "Shell Command", type: .text, required: true, defaultValue: "")
            ])

        default:
            return CommandSchema(command: command, parameters: [])
        }
    }
}
