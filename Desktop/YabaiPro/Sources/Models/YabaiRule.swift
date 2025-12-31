//
//  YabaiRule.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Foundation

struct YabaiRule: Identifiable, Codable, Equatable {
    var id = UUID()
    var app: String?
    var title: String?
    var role: String?
    var subrole: String?
    var manage: ManageState?
    var sticky: StickyState?
    var mouseFollowsFocus: Bool?
    var layer: WindowLayer?
    var opacity: Double?
    var border: BorderState?
    var label: String?

    enum ManageState: String, Codable {
        case on, off
    }

    enum StickyState: String, Codable {
        case on, off
    }

    enum WindowLayer: String, Codable {
        case below, normal, above
    }

    enum BorderState: String, Codable {
        case on, off
    }

    var description: String {
        var parts = [String]()
        if let app = app { parts.append("App: \(app)") }
        if let title = title { parts.append("Title: \(title)") }
        if let role = role { parts.append("Role: \(role)") }
        if let subrole = subrole { parts.append("Subrole: \(subrole)") }
        return parts.joined(separator: ", ")
    }

    var displayName: String {
        label ?? description
    }
}

extension YabaiRule {
    static func fromYabaiOutput(_ output: String) -> [YabaiRule] {
        // Parse yabai -m rule --list output (JSON format)
        guard let data = output.data(using: .utf8),
              let rules = try? JSONDecoder().decode([YabaiRule].self, from: data) else {
            return []
        }
        return rules
    }
}




