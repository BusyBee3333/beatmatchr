//
//  ActionValidator.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

/// Validation result for action compatibility
enum ValidationResult: Equatable {
    case valid
    case warning(String)
    case error(String)
}

/// Utility for validating action combinations in signals
struct ActionValidator {
    /// Check if a new action can be added to existing actions
    static func validateNewAction(_ newAction: SignalAction, existingActions: [SignalAction]) -> ValidationResult {
        // Check for direct conflicts
        for existing in existingActions {
            if let conflict = checkConflict(newAction, existing) {
                return conflict
            }
        }

        // Check for general best practices
        if let warning = checkBestPractices(newAction, existingActions) {
            return warning
        }

        return .valid
    }

    /// Check if two actions conflict with each other
    private static func checkConflict(_ action1: SignalAction, _ action2: SignalAction) -> ValidationResult? {
        let cmd1 = action1.command
        let cmd2 = action2.command

        // Window positioning conflicts
        if (cmd1 == .windowMoveAbsolute || cmd1 == .windowMoveRelative) &&
           (cmd2 == .windowMoveAbsolute || cmd2 == .windowMoveRelative) {
            return .warning("Multiple window moves may conflict. Consider combining into a single move.")
        }

        // Window sizing conflicts
        if (cmd1 == .windowResizeAbsolute || cmd1 == .windowResizeRelative) &&
           (cmd2 == .windowResizeAbsolute || cmd2 == .windowResizeRelative) {
            return .warning("Multiple window resizes may conflict. Consider using a single resize.")
        }

        // Float/stack conflicts
        if cmd1 == .windowToggleFloat && cmd2 == .windowToggleStack {
            return .error("Cannot toggle both float and stack in the same signal.")
        }

        // Opacity conflicts
        let opacityCommands: Set<SignalAction.YabaiCommand> = [.configWindowOpacity, .configWindowOpacityActive, .configWindowOpacityNormal]
        if opacityCommands.contains(cmd1) && opacityCommands.contains(cmd2) {
            return .warning("Multiple opacity settings may override each other.")
        }

        // Space focus conflicts
        if cmd1 == .spaceFocus && cmd2 == .spaceFocus {
            return .warning("Multiple space focus commands may conflict.")
        }

        // Display focus conflicts
        let displayFocusCommands: Set<SignalAction.YabaiCommand> = [.displayFocus, .displayFocusNext, .displayFocusPrev, .displayFocusRecent, .displayFocusMouse]
        if displayFocusCommands.contains(cmd1) && displayFocusCommands.contains(cmd2) {
            return .warning("Multiple display focus commands may conflict.")
        }

        return nil
    }

    /// Check for best practice violations
    private static func checkBestPractices(_ newAction: SignalAction, _ existingActions: [SignalAction]) -> ValidationResult? {
        let allActions = existingActions + [newAction]

        // Too many actions in a single signal
        if allActions.count > 5 {
            return .warning("Consider breaking complex signals into multiple simpler signals for better maintainability.")
        }

        // Mixed concerns (window + space + display operations)
        let windowCommands = allActions.filter { $0.command.rawValue.hasPrefix("window_") }
        let spaceCommands = allActions.filter { $0.command.rawValue.hasPrefix("space_") }
        let displayCommands = allActions.filter { $0.command.rawValue.hasPrefix("display_") }

        let operationTypes = [windowCommands, spaceCommands, displayCommands].filter { !$0.isEmpty }.count
        if operationTypes > 2 {
            return .warning("Signal mixes window, space, and display operations. Consider splitting into focused signals.")
        }

        return nil
    }

    /// Get a list of recommended actions that can be added next
    static func getRecommendedActions(for existingActions: [SignalAction]) -> [SignalAction.YabaiCommand] {
        var recommended: [SignalAction.YabaiCommand] = []

        // If we have window operations, suggest related window actions
        let hasWindowOps = existingActions.contains { $0.command.rawValue.hasPrefix("window_") }
        if hasWindowOps {
            recommended.append(contentsOf: [
                .windowFocus, .windowToggleFloat, .windowToggleFullscreen,
                .windowMoveToSpace, .windowMoveToDisplay, .configWindowOpacityActive
            ])
        }

        // If we have space operations, suggest related space actions
        let hasSpaceOps = existingActions.contains { $0.command.rawValue.hasPrefix("space_") }
        if hasSpaceOps {
            recommended.append(contentsOf: [
                .spaceFocus, .spaceBalance, .spaceCreate, .spaceDestroy
            ])
        }

        // If we have display operations, suggest related display actions
        let hasDisplayOps = existingActions.contains { $0.command.rawValue.hasPrefix("display_") }
        if hasDisplayOps {
            recommended.append(contentsOf: [
                .displayFocus, .displayBalance, .displayFocusNext, .displayFocusPrev
            ])
        }

        // If we have config operations, suggest related config actions
        let hasConfigOps = existingActions.contains { $0.command.rawValue.hasPrefix("config_") }
        if hasConfigOps {
            recommended.append(contentsOf: [
                .configWindowOpacity, .configWindowOpacityNormal, .configWindowShadow,
                .configMouseFollowsFocus, .configFocusFollowsMouse
            ])
        }

        // Always suggest shell commands as fallback
        recommended.append(.shellCommand)

        // Remove commands that would conflict
        recommended = recommended.filter { cmd in
            let testAction = SignalAction(command: cmd, parameters: [:])
            let result = ActionValidator.validateNewAction(testAction, existingActions: existingActions)
            if case .error = result {
                return false
            }
            return true
        }

        // Remove duplicates and sort
        let unique = Array(Set(recommended))
        return unique.sorted { $0.displayName < $1.displayName }
    }
}
