//
//  YabaiScriptingAdditionManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

class YabaiScriptingAdditionManager {
    static let shared = YabaiScriptingAdditionManager()

    private let commandRunner = YabaiCommandRunner()

    // Check if yabai scripting addition is loaded by testing a command that requires it
    func isScriptingAdditionLoaded() async -> Bool {
        do {
            // Test with window_opacity command - this requires scripting addition
            // Use timeout to avoid hanging if yabai is unresponsive
            try await commandRunner.run(command: "timeout 5 yabai -m config window_opacity on")
            return true
        } catch {
            // If it fails, scripting addition is likely not loaded
            return false
        }
    }

    // Load the yabai scripting addition (requires sudo)
    func loadScriptingAddition() async throws {
        print("YabaiScriptingAdditionManager: Loading scripting addition...")

        // Try multiple approaches for loading the scripting addition
        let loadCommands = [
            // Method 1: Use osascript with clear prompt (most user-friendly)
            """
            osascript -e '
            tell application "Terminal"
                activate
                do script "echo Loading yabai scripting addition... && sudo yabai --load-sa"
            end tell'
            """,

            // Method 2: Direct osascript with admin privileges
            """
            osascript -e 'do shell script "yabai --load-sa" with administrator privileges'
            """,

            // Method 3: Manual instruction (fallback)
            "echo 'Please run this manually in Terminal: sudo yabai --load-sa'"
        ]

        var lastError: Error?

        for (index, command) in loadCommands.enumerated() {
            do {
                print("YabaiScriptingAdditionManager: Trying loading method \(index + 1)")
                try await commandRunner.run(command: command)

                // Give it time to load
                try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

                // Check if it worked
                if await isScriptingAdditionLoaded() {
                    print("YabaiScriptingAdditionManager: Scripting addition loaded successfully using method \(index + 1)")
                    return
                } else {
                    print("YabaiScriptingAdditionManager: Method \(index + 1) completed but verification failed")
                }
            } catch {
                print("YabaiScriptingAdditionManager: Method \(index + 1) failed: \(error)")
                lastError = error
            }
        }

        // If all methods failed, provide clear error
        throw ScriptingAdditionError.loadFailed("All loading methods failed. Last error: \(lastError?.localizedDescription ?? "Unknown")")
    }

    // Ensure scripting addition is loaded, loading it if necessary
    func ensureScriptingAdditionLoaded() async throws {
        if await isScriptingAdditionLoaded() {
            print("YabaiScriptingAdditionManager: Scripting addition already loaded")
            return
        }

        print("YabaiScriptingAdditionManager: Scripting addition not loaded, attempting to load...")
        try await loadScriptingAddition()

        // Final verification
        if await isScriptingAdditionLoaded() {
            print("YabaiScriptingAdditionManager: Verification successful - scripting addition is now loaded")
        } else {
            throw ScriptingAdditionError.verificationFailed
        }
    }

    // Check if SIP is disabled (required for scripting addition)
    func isSIPDisabled() async -> Bool {
        do {
            // Check SIP status using csrutil
            try await commandRunner.run(command: "csrutil status | grep -q 'disabled'")
            return true
        } catch {
            return false
        }
    }
}

enum ScriptingAdditionError: Error, LocalizedError {
    case loadFailed(String)
    case verificationFailed
    case sipEnabled

    var errorDescription: String? {
        switch self {
        case .loadFailed(let details):
            return "Failed to load yabai scripting addition: \(details)"
        case .verificationFailed:
            return "Scripting addition loaded but verification failed. Try restarting yabai."
        case .sipEnabled:
            return "SIP must be disabled to use window appearance features. Run 'csrutil disable' in Recovery Mode."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .loadFailed:
            return "Try running 'sudo yabai --load-sa' manually in Terminal, then restart YabaiPro."
        case .verificationFailed:
            return "Restart yabai with 'brew services restart yabai', then restart YabaiPro."
        case .sipEnabled:
            return "Boot into Recovery Mode (Command+R), run 'csrutil disable', restart, then run 'sudo yabai --load-sa'."
        }
    }
}
