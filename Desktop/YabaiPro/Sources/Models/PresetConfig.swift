//
//  PresetConfig.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

struct PresetConfig: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var description: String?
    var createdAt: Date
    var config: [String: String]? // yabai config key-value pairs
    var rules: [YabaiRule]?
    var signals: [YabaiSignal]?

    var displayName: String {
        name
    }

    init(name: String, description: String? = nil, config: [String: String], rules: [YabaiRule]? = nil, signals: [YabaiSignal]? = nil) {
        self.name = name
        self.description = description
        self.createdAt = Date()
        self.config = config
        self.rules = rules
        self.signals = signals
    }
}

extension PresetConfig {
    static var `default`: PresetConfig {
        PresetConfig(
            name: "Default",
            description: "Standard yabai configuration",
            config: [
                "window_gap": "6",
                "window_opacity": "off",
                "window_shadow": "on",
                "focus_follows_mouse": "off",
                "mouse_follows_focus": "off",
                "layout": "bsp"
            ]
        )
    }

    static var minimalist: PresetConfig {
        PresetConfig(
            name: "Minimalist",
            description: "Clean, minimal appearance",
            config: [
                "window_gap": "12",
                "window_opacity": "on",
                "normal_window_opacity": "0.85",
                "window_shadow": "off",
                "focus_follows_mouse": "autoraise",
                "mouse_follows_focus": "on",
                "layout": "bsp",
                "menubar_opacity": "0.7"
            ]
        )
    }

    static var gaming: PresetConfig {
        PresetConfig(
            name: "Gaming",
            description: "Optimized for gaming with minimal interference",
            config: [
                "window_gap": "0",
                "window_opacity": "off",
                "window_shadow": "off",
                "focus_follows_mouse": "off",
                "mouse_follows_focus": "off",
                "layout": "float",
                "window_topmost": "off"
            ]
        )
    }

    static var coding: PresetConfig {
        PresetConfig(
            name: "Coding",
            description: "Optimized for development work",
            config: [
                "window_gap": "8",
                "window_opacity": "off",
                "window_shadow": "on",
                "focus_follows_mouse": "autofocus",
                "mouse_follows_focus": "off",
                "layout": "bsp",
                "split_ratio": "0.6",
                "auto_balance": "on"
            ]
        )
    }
}
