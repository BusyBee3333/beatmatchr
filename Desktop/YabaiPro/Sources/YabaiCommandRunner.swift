//
//  YabaiCommandRunner.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

class YabaiCommandRunner {
    static let shared = YabaiCommandRunner()

    // MARK: - Event Subscription
    private var eventStream: AsyncThrowingStream<YabaiEvent, Error>?
    private var eventContinuation: AsyncThrowingStream<YabaiEvent, Error>.Continuation?
    private var lastWindowStates: [YabaiWindowJSON] = []
    private var isSubscribed = false

    // MARK: - Basic Command Execution

    func run(command: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        // Set up proper environment with Homebrew PATH
        var environment = ProcessInfo.processInfo.environment
        if let existingPath = environment["PATH"] {
            environment["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:" + existingPath
        } else {
            environment["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin"
        }
        process.environment = environment

        process.arguments = ["-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        // Check for errors
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if !errorData.isEmpty {
            let errorString = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
            if process.terminationStatus != 0 {
                throw CommandError.executionFailed(command: command, error: errorString)
            }
        }
    }

    // MARK: - JSON Query Methods

    func queryJSON(_ query: String) async throws -> Data {
        let command = "yabai -m query --\(query)"

        // Retry a few times because yabai may occasionally return empty/truncated output
        let maxAttempts = 5
        for attempt in 1...maxAttempts {
            let data = try await runCaptureStdout(command)
            if data.count > 0 {
                if let first = String(data: data.prefix(1), encoding: .utf8),
                   first == "[" || first == "{" {
                    return data
                } else {
                    print("⚠️ yabai query returned unexpected prefix: '\(String(describing: String(data: data.prefix(1), encoding: .utf8)))'; attempt \(attempt)/\(maxAttempts)")
                }
            } else {
                print("⚠️ yabai query returned empty output; attempt \(attempt)/\(maxAttempts)")
            }
            try await Task.sleep(nanoseconds: UInt64(50_000_000 * attempt)) // backoff
        }

        // Final attempt - return whatever we get (caller will handle parse error)
        return try await runCaptureStdout(command)
    }

    func queryWindows() async throws -> Data {
        try await queryJSON("windows")
    }

    func querySpaces() async throws -> Data {
        try await queryJSON("spaces")
    }

    func queryDisplays() async throws -> Data {
        try await queryJSON("displays")
    }

    func queryWindow(id: UInt32) async throws -> Data {
        try await queryJSON("windows --window \(id)")
    }

    func querySpace(index: UInt32) async throws -> Data {
        try await queryJSON("spaces --space \(index)")
    }

    func queryDisplay(index: UInt32) async throws -> Data {
        try await queryJSON("displays --display \(index)")
    }

    // MARK: - Window Operations

    func focusWindow(direction: WindowDirection) async throws {
        try await run(command: "yabai -m window --focus \(direction.rawValue)")
    }

    func swapWindow(direction: WindowDirection) async throws {
        try await run(command: "yabai -m window --swap \(direction.rawValue)")
    }

    func warpWindow(direction: WindowDirection) async throws {
        try await run(command: "yabai -m window --warp \(direction.rawValue)")
    }

    func toggleWindowFloat() async throws {
        try await run(command: "yabai -m window --toggle float")
    }

    func toggleWindowFullscreen() async throws {
        try await run(command: "yabai -m window --toggle zoom-fullscreen")
    }

    // MARK: - Window Stacking Commands

    func stackWindow(direction: WindowDirection) async throws {
        try await run(command: "yabai -m window --stack \(direction.rawValue)")
    }

    func toggleWindowStack() async throws {
        try await run(command: "yabai -m window --toggle stack")
    }

    func unstackWindow() async throws {
        try await run(command: "yabai -m window --toggle float")  // Unstacks by floating
    }

    // MARK: - Window Insertion Commands

    func insertWindow(at position: WindowInsertPosition) async throws {
        try await run(command: "yabai -m window --insert \(position.rawValue)")
    }

    func toggleWindowSplit() async throws {
        try await run(command: "yabai -m window --toggle split")
    }

    // MARK: - Grid & Layout Commands

    func gridWindow(grid: WindowGrid) async throws {
        let gridString = "\(grid.rows):\(grid.cols):\(grid.startX):\(grid.startY):\(grid.width):\(grid.height)"
        try await run(command: "yabai -m window --grid \(gridString)")
    }

    func toggleWindowNativeFullscreen() async throws {
        try await run(command: "yabai -m window --toggle native-fullscreen")
    }

    func toggleWindowExposé() async throws {
        try await run(command: "yabai -m window --toggle exposé")
    }

    func toggleWindowPip() async throws {
        try await run(command: "yabai -m window --toggle pip")
    }

    // MARK: - Window Movement & Zoom

    func moveWindowToSpace(spaceIndex: UInt32) async throws {
        try await run(command: "yabai -m window --space \(spaceIndex)")
    }

    func moveWindowToDisplay(displayIndex: UInt32) async throws {
        try await run(command: "yabai -m window --display \(displayIndex)")
    }

    func toggleWindowZoomParent() async throws {
        try await run(command: "yabai -m window --toggle zoom-parent")
    }

    func toggleWindowZoomFull() async throws {  // Already exists, but keeping for completeness
        try await run(command: "yabai -m window --toggle zoom-fullscreen")
    }

    // MARK: - Advanced Window Positioning

    func moveWindowAbsolute(x: Double, y: Double) async throws {
        try await run(command: "yabai -m window --move abs:\(Int(x)):\(Int(y))")
    }

    func moveWindowRelative(deltaX: Double, deltaY: Double) async throws {
        try await run(command: "yabai -m window --move rel:\(Int(deltaX)):\(Int(deltaY))")
    }

    func resizeWindowAbsolute(width: Double, height: Double) async throws {
        try await run(command: "yabai -m window --resize abs:\(Int(width)):\(Int(height))")
    }

    func resizeWindowRelative(deltaWidth: Double, deltaHeight: Double) async throws {
        try await run(command: "yabai -m window --resize rel:\(Int(deltaWidth)):\(Int(deltaHeight))")
    }

    func resizeWindow(id: UInt32, width: Double, height: Double) async throws {
        try await run(command: "yabai -m window \(id) --resize abs:\(Int(width)):\(Int(height))")
    }

    func moveWindow(id: UInt32, x: Double?, y: Double?) async throws {
        var args = [String]()
        if let x = x {
            args.append("x:\(Int(x))")
        }
        if let y = y {
            args.append("y:\(Int(y))")
        }
        if !args.isEmpty {
            try await run(command: "yabai -m window \(id) --move abs:\(args.joined(separator: ":"))")
        }
    }

    // MARK: - Cursor + Brave Development Layouts

    func setupCursorBraveLayout() async throws {
        // This will position windows for Cursor + Brave development workflow
        // Note: Requires windows to be focused first, then positioned
        print("💡 Cursor + Brave layout setup ready - focus windows and use positioning commands")
    }

    /// Positions Cursor as main editor (left 2/3) with Brave on right
    func applyCursorBraveMainLayout() async throws {
        // Note: This assumes you have Cursor and Brave windows open
        // You'd need to focus each window first, then call these functions
        print("🎯 Main Layout: Focus Cursor window, then use 'Resize Editor Size' and 'Move to Top-Left'")
        print("🌐 Focus Brave window, then use 'Resize Sidebar' and 'Move to Top-Right'")
    }

    /// Positions windows for research + coding workflow
    func applyCursorBraveResearchLayout() async throws {
        print("📚 Research Layout: Cursor (70% left), Brave (30% right)")
        print("💡 Focus Cursor: 'Resize Editor Size' at position (50,50)")
        print("🌐 Focus Brave: 'Resize Sidebar' at position (1370,50)")
    }

    /// Positions windows for API development
    func applyCursorBraveAPILayout() async throws {
        print("🔗 API Layout: Cursor (main), Brave (docs + testing split)")
        print("💻 Focus Cursor: Editor size at (100,100)")
        print("📖 Focus Brave docs: Sidebar at (1320,100)")
        print("🧪 Focus Brave testing: Sidebar at (1320,520)")
    }

    // MARK: - Space Operations

    func focusSpace(index: UInt32) async throws {
        try await run(command: "yabai -m space --focus \(index)")
    }

    func balanceSpace() async throws {
        try await run(command: "yabai -m space --balance")
    }

    func mirrorSpace(axis: MirrorAxis) async throws {
        try await run(command: "yabai -m space --mirror \(axis.rawValue)-axis")
    }

    func rotateSpace(degrees: Int) async throws {
        try await run(command: "yabai -m space --rotate \(degrees)")
    }

    // MARK: - Space Creation & Destruction

    func createSpace() async throws -> UInt32 {
        let output = try await runCaptureStdout("yabai -m space --create")
        // Parse the new space index from output
        guard let outputStr = String(data: output, encoding: .utf8),
              let spaceIndex = UInt32(outputStr.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw CommandError.invalidOutput
        }
        return spaceIndex
    }

    func destroySpace(index: UInt32) async throws {
        try await run(command: "yabai -m space --destroy \(index)")
    }

    // MARK: - Space Movement & Labeling

    func moveSpace(fromIndex: UInt32, toIndex: UInt32) async throws {
        try await run(command: "yabai -m space \(fromIndex) --move \(toIndex)")
    }

    func labelSpace(index: UInt32, label: String) async throws {
        try await run(command: "yabai -m space \(index) --label \"\(label)\"")
    }

    func moveSpaceToDisplay(spaceIndex: UInt32, displayIndex: UInt32) async throws {
        try await run(command: "yabai -m space \(spaceIndex) --display \(displayIndex)")
    }

    // MARK: - Space Layout Management

    func setSpaceLayout(index: UInt32, layout: SpaceLayout) async throws {
        try await run(command: "yabai -m space \(index) --layout \(layout.rawValue)")
    }

    func rotateSpace(index: UInt32, degrees: Int) async throws {  // Per-space
        try await run(command: "yabai -m space \(index) --rotate \(degrees)")
    }

    func mirrorSpace(index: UInt32, axis: MirrorAxis) async throws {  // Per-space
        try await run(command: "yabai -m space \(index) --mirror \(axis.rawValue)-axis")
    }

    func balanceSpace(index: UInt32) async throws {  // Per-space
        try await run(command: "yabai -m space \(index) --balance")
    }

    // MARK: - Space Padding & Gaps

    func setSpacePadding(index: UInt32, padding: SpacePadding) async throws {
        let paddingStr = "\(Int(padding.top)):\(Int(padding.bottom)):\(Int(padding.left)):\(Int(padding.right))"
        try await run(command: "yabai -m space \(index) --padding abs:\(paddingStr)")
    }

    func setSpaceGap(index: UInt32, gap: Double) async throws {
        try await run(command: "yabai -m space \(index) --gap abs:\(Int(gap))")
    }

    // MARK: - Display Operations

    func focusDisplay(index: UInt32) async throws {
        try await run(command: "yabai -m display --focus \(index)")
    }

    func balanceDisplay() async throws {
        try await run(command: "yabai -m display --balance")
    }

    // MARK: - Advanced Display Focus

    func focusDisplayNext() async throws {
        try await run(command: "yabai -m display --focus next")
    }

    func focusDisplayPrev() async throws {
        try await run(command: "yabai -m display --focus prev")
    }

    func focusDisplayRecent() async throws {
        try await run(command: "yabai -m display --focus recent")
    }

    func focusDisplayMouse() async throws {
        try await run(command: "yabai -m display --focus mouse")
    }

    // MARK: - Display Space Management

    func balanceDisplay(index: UInt32) async throws {  // Per-display
        try await run(command: "yabai -m display \(index) --balance")
    }

    // MARK: - Config Operations

    func setConfig(_ key: String, value: String) async throws {
        try await run(command: "yabai -m config \(key) \(value)")
    }

    // MARK: - Utility Methods

    func runCaptureStdout(_ command: String) async throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")

        // Set up proper environment with Homebrew PATH
        var environment = ProcessInfo.processInfo.environment
        if let existingPath = environment["PATH"] {
            environment["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:" + existingPath
        } else {
            environment["PATH"] = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin"
        }
        process.environment = environment

        process.arguments = ["-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        // Check for errors first
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if !errorData.isEmpty {
            let errorString = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown error"
            if process.terminationStatus != 0 {
                throw CommandError.executionFailed(command: command, error: errorString)
            }
        }

        // Return stdout
        return outputPipe.fileHandleForReading.readDataToEndOfFile()
    }

    func isYabaiRunning() async -> Bool {
        do {
            try await run(command: "pgrep -x yabai > /dev/null")
            return true
        } catch {
            return false
        }
    }

    // MARK: - Event Subscription
    func subscribeToYabaiEvents() -> AsyncThrowingStream<YabaiEvent, Error> {
        if eventStream == nil {
            eventStream = AsyncThrowingStream { continuation in
                self.eventContinuation = continuation

                Task {
                    do {
                        try await self.startEventSubscription()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
        return eventStream!
    }

    private func startEventSubscription() async throws {
        print("🎧 Starting yabai event subscription...")

        // NOTE: registering yabai signals via `yabai -m signal --add` can fail across yabai versions;
        // to maximize compatibility we skip adding signals and rely on robust polling below.
        isSubscribed = true
        print("✅ Yabai event polling started (signals not registered to maximize compatibility)")

        // Start monitoring for changes via polling
        // This is more reliable than trying to parse signal outputs
        while true {
            do {
                let currentWindowsData = try await queryWindows()
                let currentWindows = try JSONDecoder().decode([YabaiWindowJSON].self, from: currentWindowsData)

                // Detect changes and generate events
                let events = detectWindowChanges(from: lastWindowStates, to: currentWindows)
                for event in events {
                    eventContinuation?.yield(event)
                }

                lastWindowStates = currentWindows
                try await Task.sleep(nanoseconds: 50_000_000) // 50ms polling interval
            } catch {
                print("Error in event monitoring: \(error)")
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms on error
            }
        }
    }

    private func detectWindowChanges(from oldWindows: [YabaiWindowJSON], to newWindows: [YabaiWindowJSON]) -> [YabaiEvent] {
        var events: [YabaiEvent] = []

        let oldIds = Set(oldWindows.map { $0.id })
        let newIds = Set(newWindows.map { $0.id })

        // Detect new windows
        let createdIds = newIds.subtracting(oldIds)
        for id in createdIds {
            if let _ = newWindows.first(where: { $0.id == id }) {
                events.append(YabaiEvent(type: "window_create", payload: ["id": AnyCodable(id)]))
            }
        }

        // Detect destroyed windows
        let destroyedIds = oldIds.subtracting(newIds)
        for id in destroyedIds {
            events.append(YabaiEvent(type: "window_destroy", payload: ["id": AnyCodable(id)]))
        }

        // Detect focus changes
        let oldFocused = oldWindows.first(where: { $0.hasFocus })?.id
        let newFocused = newWindows.first(where: { $0.hasFocus })?.id

        if oldFocused != newFocused && newFocused != nil {
            events.append(YabaiEvent(type: "window_focus", payload: ["id": AnyCodable(newFocused!)]))
        }

        // Detect position/size changes (simplified - in practice you'd compare frames)
        for newWindow in newWindows {
            if let oldWindow = oldWindows.first(where: { $0.id == newWindow.id }) {
                if abs(oldWindow.frame.x - newWindow.frame.x) > 1 ||
                   abs(oldWindow.frame.y - newWindow.frame.y) > 1 ||
                   abs(oldWindow.frame.w - newWindow.frame.w) > 1 ||
                   abs(oldWindow.frame.h - newWindow.frame.h) > 1 {
                    events.append(YabaiEvent(type: "window_move", payload: ["id": AnyCodable(newWindow.id)]))
                }
            }
        }

        return events
    }
}

// MARK: - Yabai Validator

class YabaiValidator {
    private let commandRunner = YabaiCommandRunner()
    private let scriptingAdditionManager = YabaiScriptingAdditionManager.shared
    private let permissionsManager = PermissionsManager.shared

    func validateWindowId(_ id: UInt32) async -> Bool {
        do {
            _ = try await commandRunner.queryWindow(id: id)
            return true
        } catch {
            return false
        }
    }

    func validateSpaceIndex(_ index: UInt32) async -> Bool {
        do {
            let spaces = try await commandRunner.querySpaces()
            let spaceArray = try JSONDecoder().decode([ValidationSpaceInfo].self, from: spaces)
            return spaceArray.contains { $0.index == index }
        } catch {
            return false
        }
    }

    func validateDisplayIndex(_ index: UInt32) async -> Bool {
        do {
            let displays = try await commandRunner.queryDisplays()
            let displayArray = try JSONDecoder().decode([ValidationDisplayInfo].self, from: displays)
            return displayArray.contains { $0.index == index }
        } catch {
            return false
        }
    }

    func validateCommandPrerequisites(for command: YabaiCommand) async -> [YabaiError] {
        var errors: [YabaiError] = []

        switch command {
        case .windowOpacity, .windowShadow:
            if !(await scriptingAdditionManager.isScriptingAdditionLoaded()) {
                errors.append(.scriptingAdditionRequired(feature: "Window appearance features"))
            }
        case .focusFollowsMouse:
            if !permissionsManager.hasAccessibilityPermission {
                errors.append(.permissionDenied(permission: "Accessibility"))
            }
        }

        return errors
    }

}

// MARK: - Yabai Event System

struct YabaiEvent: Codable {
    let type: String
    let payload: [String: AnyCodable]

    enum EventType: String {
        case windowFocus = "window_focus"
        case windowMove = "window_move"
        case windowResize = "window_resize"
        case windowCreate = "window_create"
        case windowDestroy = "window_destroy"
        case windowFloat = "window_float"
        case windowMinimize = "window_minimize"
        case spaceChange = "space_change"
        case displayChange = "display_change"
    }

    var eventType: EventType? {
        EventType(rawValue: type)
    }

    var windowId: UInt32? {
        payload["id"]?.value as? UInt32
    }

    var spaceId: UInt32? {
        payload["space"]?.value as? UInt32 ?? payload["space_id"]?.value as? UInt32
    }

    var displayId: UInt32? {
        payload["display"]?.value as? UInt32 ?? payload["display_id"]?.value as? UInt32
    }
}

// Type-erased wrapper for Any values in Codable
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [AnyCodable]:
            try container.encode(arrayValue)
        case let dictValue as [String: AnyCodable]:
            try container.encode(dictValue)
        default:
            try container.encodeNil()
        }
    }
}

struct YabaiWindowJSON: Codable {
    let id: UInt32
    let frame: Frame
    let hasFocus: Bool

    struct Frame: Codable {
        let x: Double
        let y: Double
        let w: Double
        let h: Double
    }

    enum CodingKeys: String, CodingKey {
        case id
        case frame
        case hasFocus = "has-focus"
    }
}

// MARK: - Supporting Types for Validation

enum YabaiCommand {
    case windowOpacity, windowShadow, focusFollowsMouse
    // Add other commands as needed
}

struct ValidationSpaceInfo: Codable {
    let index: UInt32
    let focused: Int
    let type: String
}

struct ValidationDisplayInfo: Codable {
    let index: UInt32
    // Add other display properties as needed
}

// MARK: - Supporting Types

enum WindowDirection: String {
    case north, east, south, west, prev, next, first, last
}

enum MirrorAxis: String {
    case x, y
}

enum WindowInsertPosition: String {
    case north, east, south, west
}

struct WindowGrid {
    let rows: Int
    let cols: Int
    let startX: Int
    let startY: Int
    let width: Int
    let height: Int
}

enum SpaceLayout: String {
    case bsp, stack, float
}

struct SpacePadding {
    let top: Double
    let bottom: Double
    let left: Double
    let right: Double
}

enum YabaiError: LocalizedError {
    case commandFailed(command: String, error: String)
    case invalidWindowId(id: UInt32)
    case invalidSpaceIndex(index: UInt32)
    case invalidDisplayIndex(index: UInt32)
    case scriptingAdditionRequired(feature: String)
    case sipRestriction(feature: String)
    case permissionDenied(permission: String)
    case executionFailed(command: String, error: String)
    case invalidJSON(data: Data)
    case yabaiNotRunning
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .commandFailed(let command, let error):
            return "Command failed: \(command)\nError: \(error)"
        case .invalidWindowId(let id):
            return "Invalid window ID: \(id)"
        case .invalidSpaceIndex(let index):
            return "Invalid space index: \(index)"
        case .invalidDisplayIndex(let index):
            return "Invalid display index: \(index)"
        case .scriptingAdditionRequired(let feature):
            return "\(feature) requires scripting addition. Run 'sudo yabai --load-sa'"
        case .sipRestriction(let feature):
            return "\(feature) is restricted by System Integrity Protection"
        case .permissionDenied(let permission):
            return "\(permission) permission required"
        case .executionFailed(let command, let error):
            return "Command failed: \(command)\nError: \(error)"
        case .invalidJSON:
            return "Failed to parse JSON response from yabai"
        case .yabaiNotRunning:
            return "yabai is not running"
        case .invalidOutput:
            return "Failed to parse command output"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .scriptingAdditionRequired:
            return "Load scripting addition with 'sudo yabai --load-sa' and restart YabaiPro"
        case .sipRestriction:
            return "Disable SIP temporarily or use SIP-compatible features"
        case .permissionDenied(let permission):
            return "Grant \(permission) permission in System Settings > Privacy & Security"
        case .yabaiNotRunning:
            return "Start yabai with 'brew services start yabai' or 'yabai --start-service'"
        default:
            return nil
        }
    }
}

enum CommandError: Error, LocalizedError {
    case executionFailed(command: String, error: String)
    case invalidJSON(data: Data)
    case yabaiNotRunning
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .executionFailed(let command, let error):
            return "Command failed: \(command)\nError: \(error)"
        case .invalidJSON:
            return "Failed to parse JSON response from yabai"
        case .yabaiNotRunning:
            return "yabai is not running"
        case .invalidOutput:
            return "Failed to parse command output"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .yabaiNotRunning:
            return "Start yabai with 'brew services start yabai' or 'yabai --start-service'"
        default:
            return nil
        }
    }
}
