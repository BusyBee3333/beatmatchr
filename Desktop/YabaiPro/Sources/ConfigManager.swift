//
//  ConfigManager.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

class ConfigManager {
    private let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".yabairc")

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()

    // MARK: - Config Management

    func readConfig() async throws -> [String: String] {
        let url = configPath
        let data = try Data(contentsOf: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw ConfigError.invalidEncoding
        }

        return parseConfig(content)
    }

    func writeConfig(_ config: [String: String]) async throws {
        let url = configPath

        // Create timestamped backup
        try await createBackup()

        // Generate config content
        var content = ""
        for (key, value) in config.sorted(by: { $0.key < $1.key }) {
            content += "yabai -m config \(key) \(value)\n"
        }

        // Write new config
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            // Restore backup on error
            try await restoreLatestBackup()
            throw error
        }
    }

    func updateSettings(_ updates: [String: String]) async throws {
        let currentConfig = try await readConfig()
        var newConfig = currentConfig

        // Apply updates
        for (key, value) in updates {
            newConfig[key] = value
        }

        try await writeConfig(newConfig)
    }

    // MARK: - Configuration Import/Export

    func exportConfig(to url: URL) async throws {
        let config = try await readConfig()
        let jsonData = try JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
        try jsonData.write(to: url)
    }

    func importConfig(from url: URL) async throws {
        let jsonData = try Data(contentsOf: url)
        guard let config = try JSONSerialization.jsonObject(with: jsonData) as? [String: String] else {
            throw ConfigError.invalidConfiguration("Invalid config file format")
        }

        // Validate config before importing
        let validationErrors = validateConfig(config)
        if !validationErrors.isEmpty {
            throw ConfigError.invalidConfiguration("Validation failed: \(validationErrors.joined(separator: "; "))")
        }

        try await writeConfig(config)
    }

    func validateConfig(_ config: [String: String]) -> [String] {
        var errors: [String] = []

        // Validate numeric ranges
        if let gap = Double(config["window_gap"] ?? ""), gap < 0 || gap > 50 {
            errors.append("Window gap must be between 0 and 50")
        }

        // Validate opacity ranges
        let opacityKeys = ["window_opacity", "active_window_opacity", "normal_window_opacity", "menubar_opacity"]
        for key in opacityKeys {
            if let opacity = Double(config[key] ?? ""), opacity < 0 || opacity > 1 {
                errors.append("\(key) must be between 0.0 and 1.0")
            }
        }

        // Validate split ratio
        if let ratio = Double(config["split_ratio"] ?? ""), ratio < 0.1 || ratio > 0.9 {
            errors.append("Split ratio must be between 0.1 and 0.9")
        }

        // Validate animation duration
        if let duration = Double(config["window_animation_duration"] ?? ""), duration < 0 || duration > 2.0 {
            errors.append("Animation duration must be between 0.0 and 2.0 seconds")
        }

        return errors
    }

    // MARK: - Configuration Profiles

    func saveProfile(name: String, description: String) async throws -> ConfigurationProfile {
        let config = try await readConfig()
        let profile = ConfigurationProfile(
            name: name,
            description: description,
            config: config,
            createdAt: Date(),
            isSystemProfile: false
        )
        // In a real implementation, you'd save this to persistent storage
        return profile
    }

    func loadProfile(_ profile: ConfigurationProfile) async throws {
        try await writeConfig(profile.config)
    }

    func deleteProfile(_ profile: ConfigurationProfile) async throws {
        // In a real implementation, you'd remove this from persistent storage
        // For now, just validate it's not a system profile
        guard !profile.isSystemProfile else {
            throw ConfigError.invalidConfiguration("Cannot delete system profiles")
        }
    }

    // MARK: - Backup Management

    func createBackup() async throws {
        let url = configPath
        let backupURL = url.appendingPathExtension("backup.\(dateFormatter.string(from: Date()))")

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.copyItem(at: url, to: backupURL)
        }
    }

    func restoreLatestBackup() async throws {
        let url = configPath
        let directoryURL = url.deletingLastPathComponent()

        guard let contents = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            throw ConfigError.fileNotFound
        }

        // Find latest backup
        let backupFiles = contents.filter { $0.lastPathComponent.hasPrefix(".yabairc.backup.") }
                                 .sorted { $0.lastPathComponent > $1.lastPathComponent }

        guard let latestBackup = backupFiles.first else {
            throw ConfigError.noBackupAvailable
        }

        try FileManager.default.copyItem(at: latestBackup, to: url)
    }

    func listBackups() -> [URL] {
        let directoryURL = configPath.deletingLastPathComponent()

        guard let contents = try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }

        return contents.filter { $0.lastPathComponent.hasPrefix(".yabairc.backup.") }
                      .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    // MARK: - Rules Management

    func readRules() async throws -> [YabaiRule] {
        let command = "yabai -m rule --list"
        let output = try await YabaiCommandRunner().runCaptureStdout(command)
        guard let outputStr = String(data: output, encoding: .utf8) else {
            return []
        }
        return YabaiRule.fromYabaiOutput(outputStr)
    }

    func addRule(_ rule: YabaiRule) async throws {
        var args = ["yabai", "-m", "rule", "--add"]

        // Only add parameters that have non-empty values
        if let app = rule.app, !app.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("app=\(app)")
        }
        if let title = rule.title, !title.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("title=\(title)")
        }
        if let role = rule.role, !role.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("role=\(role)")
        }
        if let subrole = rule.subrole, !subrole.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("subrole=\(subrole)")
        }

        // Always include these as they have defaults (only supported parameters for yabai v7.1.16)
        args.append("manage=\(rule.manage?.rawValue ?? "on")")
        args.append("sticky=\(rule.sticky?.rawValue ?? "off")")
        args.append("mouse_follows_focus=\(rule.mouseFollowsFocus ?? false ? "on" : "off")")
        args.append("opacity=\(rule.opacity ?? 1.0)")
        args.append("sub-layer=\(rule.layer?.rawValue ?? "normal")")
        // Note: border parameter is not supported in yabai v7.1.16

        if let label = rule.label, !label.trimmingCharacters(in: .whitespaces).isEmpty {
            args.append("label=\(label)")
        }

        // Ensure we have at least one matching criterion (app, title, role, or subrole)
        let hasMatchingCriterion = (rule.app?.trimmingCharacters(in: .whitespaces).isEmpty == false) ||
                                   (rule.title?.trimmingCharacters(in: .whitespaces).isEmpty == false) ||
                                   (rule.role?.trimmingCharacters(in: .whitespaces).isEmpty == false) ||
                                   (rule.subrole?.trimmingCharacters(in: .whitespaces).isEmpty == false)

        guard hasMatchingCriterion else {
            throw ConfigError.invalidConfiguration("Rule must have at least one matching criterion (app, title, role, or subrole)")
        }

        let command = args.joined(separator: " ")
        try await YabaiCommandRunner().run(command: command)
    }

    func removeRule(index: Int) async throws {
        try await YabaiCommandRunner().run(command: "yabai -m rule --remove \(index)")
    }

    // MARK: - Signals Management

    func readSignals() async throws -> [YabaiSignal] {
        let command = "yabai -m signal --list"
        let output = try await YabaiCommandRunner().runCaptureStdout(command)
        guard let outputStr = String(data: output, encoding: .utf8) else {
            return []
        }
        var signals = YabaiSignal.fromYabaiOutput(outputStr)

        // Attempt to migrate raw actions to structured actions
        for i in 0..<signals.count {
            if signals[i].structuredActions == nil || signals[i].structuredActions?.isEmpty == true {
                if let migrated = YabaiSignal.migrateActionString(signals[i].action) {
                    signals[i].structuredActions = migrated
                }
            }
        }

        return signals
    }

    func addSignal(_ signal: YabaiSignal) async throws {
        // Use structured actions if available, otherwise fall back to raw action
        let actionString: String
        if let structuredActions = signal.structuredActions, !structuredActions.isEmpty {
            actionString = serializeActions(structuredActions)
        } else {
            actionString = signal.action
        }

        var args = ["yabai", "-m", "signal", "--add", "event=\(signal.event.rawValue)", "action=\(actionString)"]

        if let label = signal.label { args.append("label=\(label)") }
        if let app = signal.app { args.append("app=\(app)") }
        if let excludeApp = signal.excludeApp { args.append("app!=\(excludeApp)") }

        try await YabaiCommandRunner().run(command: args.joined(separator: " "))
    }

    private func serializeActions(_ actions: [SignalAction]) -> String {
        return actions.map { $0.toShellCommand() }.joined(separator: " && ")
    }

    func removeSignal(index: Int) async throws {
        try await YabaiCommandRunner().run(command: "yabai -m signal --remove \(index)")
    }

    // MARK: - Private Methods

    private func parseConfig(_ content: String) -> [String: String] {
        var config = [String: String]()

        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("yabai -m config") else { continue }

            let components = trimmed.components(separatedBy: .whitespaces)
            guard components.count >= 4 else { continue }

            let key = components[3]
            let value = components.dropFirst(4).joined(separator: " ")
            config[key] = value
        }

        return config
    }

    // MARK: - Backup Management

}

enum ConfigError: Error, LocalizedError {
    case invalidEncoding
    case fileNotFound
    case permissionDenied
    case noBackupAvailable
    case invalidConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .invalidEncoding:
            return "Unable to read configuration file encoding"
        case .fileNotFound:
            return "Configuration file not found"
        case .permissionDenied:
            return "Permission denied accessing configuration file"
        case .noBackupAvailable:
            return "No backup files available for restore"
        case .invalidConfiguration(let message):
            return message
        }
    }
}

// MARK: - Configuration Profiles

struct ConfigurationProfile: Codable, Identifiable, Hashable {
    var id = UUID()
    let name: String
    let description: String
    let config: [String: String]
    let createdAt: Date
    let isSystemProfile: Bool

    static func == (lhs: ConfigurationProfile, rhs: ConfigurationProfile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static let defaultProfiles: [ConfigurationProfile] = [
        ConfigurationProfile(
            name: "Minimalist",
            description: "Clean, minimal interface with transparency",
            config: [
                "window_opacity": "on",
                "normal_window_opacity": "0.9",
                "window_shadow": "off",
                "menubar_opacity": "0.7",
                "window_gap": "12",
                "layout": "bsp",
                "split_ratio": "0.5",
                "auto_balance": "off"
            ],
            createdAt: Date(),
            isSystemProfile: true
        ),
        ConfigurationProfile(
            name: "Power User",
            description: "Optimized for productivity with detailed controls",
            config: [
                "focus_follows_mouse": "autoraise",
                "mouse_follows_focus": "on",
                "window_border": "on",
                "active_window_border_color": "0xffd700",
                "window_gap": "6",
                "layout": "bsp",
                "split_ratio": "0.5",
                "auto_balance": "on",
                "window_animation_duration": "0.2"
            ],
            createdAt: Date(),
            isSystemProfile: true
        ),
        ConfigurationProfile(
            name: "Traditional",
            description: "Classic window management behavior",
            config: [
                "focus_follows_mouse": "off",
                "mouse_follows_focus": "off",
                "window_shadow": "on",
                "window_gap": "6",
                "layout": "bsp",
                "split_ratio": "0.5",
                "auto_balance": "off",
                "window_animation_duration": "0.0"
            ],
            createdAt: Date(),
            isSystemProfile: true
        )
    ]
}
