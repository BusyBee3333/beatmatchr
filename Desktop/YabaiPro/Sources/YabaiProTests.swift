//
//  YabaiProTests.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import XCTest
@testable import YabaiPro

class YabaiProTests: XCTestCase {

    func testSignalActionSerialization() {
        // Test basic window focus action
        let action = SignalAction(command: .windowFocus, parameters: ["direction": "next"])
        let shellCommand = action.toShellCommand()
        XCTAssertEqual(shellCommand, "yabai -m window --focus next")
    }

    func testSignalActionComplexSerialization() {
        // Test window move action
        let action = SignalAction(command: .windowMoveAbsolute, parameters: ["x": "100", "y": "200"])
        let shellCommand = action.toShellCommand()
        XCTAssertEqual(shellCommand, "yabai -m window --move abs:100:200")
    }

    func testSignalActionConfigSerialization() {
        // Test config action
        let action = SignalAction(command: .configWindowOpacityActive, parameters: ["opacity": "0.8"])
        let shellCommand = action.toShellCommand()
        XCTAssertEqual(shellCommand, "yabai -m config active_window_opacity 0.8")
    }

    func testSignalActionShellCommand() {
        // Test shell command
        let action = SignalAction(command: .shellCommand, parameters: ["command": "echo hello"])
        let shellCommand = action.toShellCommand()
        XCTAssertEqual(shellCommand, "echo hello")
    }

    func testMultipleActionSerialization() {
        let actions = [
            SignalAction(command: .windowFocus, parameters: ["direction": "next"]),
            SignalAction(command: .configWindowOpacityActive, parameters: ["opacity": "0.8"])
        ]

        let serialized = actions.map { $0.toShellCommand() }.joined(separator: " && ")
        let expected = "yabai -m window --focus next && yabai -m config active_window_opacity 0.8"
        XCTAssertEqual(serialized, expected)
    }

    func testActionValidation() {
        // Test that conflicting actions are detected
        let action1 = SignalAction(command: .windowToggleFloat, parameters: [:])
        let action2 = SignalAction(command: .windowToggleStack, parameters: [:])

        let result = ActionValidator.validateNewAction(action2, existingActions: [action1])
        switch result {
        case .error(let message):
            XCTAssertTrue(message.contains("Cannot toggle both float and stack"))
        default:
            XCTFail("Expected error for conflicting float/stack actions")
        }
    }

    func testActionMigration() {
        // Test migration of simple command
        let rawAction = "yabai -m window --focus next"
        let migrated = YabaiSignal.migrateActionString(rawAction)

        XCTAssertNotNil(migrated)
        XCTAssertEqual(migrated?.count, 1)
        XCTAssertEqual(migrated?.first?.command, .windowFocus)
        XCTAssertEqual(migrated?.first?.parameters["direction"], "next")
    }

    func testActionMigrationComplex() {
        // Test migration of chained commands
        let rawAction = "yabai -m window --focus next && yabai -m config active_window_opacity 0.8"
        let migrated = YabaiSignal.migrateActionString(rawAction)

        XCTAssertNotNil(migrated)
        XCTAssertEqual(migrated?.count, 2)
        XCTAssertEqual(migrated?[0].command, .windowFocus)
        XCTAssertEqual(migrated?[1].command, .configWindowOpacityActive)
    }

    func testActionMigrationFailure() {
        // Test that unparseable actions return nil
        let rawAction = "some unknown command"
        let migrated = YabaiSignal.migrateActionString(rawAction)

        XCTAssertNil(migrated)
    }

    func testCommandSchema() {
        // Test that schemas are properly defined
        let schema = CommandSchema.schema(for: .windowFocus)
        XCTAssertEqual(schema.parameters.count, 1)
        XCTAssertEqual(schema.parameters[0].key, "direction")
        XCTAssertTrue(schema.parameters[0].required)
    }

    func testSignalDisplayName() {
        // Test structured action display name
        let actions = [SignalAction(command: .windowFocus, parameters: ["direction": "next"])]
        let signal = YabaiSignal(
            event: .window_focused,
            action: "yabai -m window --focus next",
            structuredActions: actions
        )

        XCTAssertTrue(signal.displayName.contains("Focus Window"))
    }
}
