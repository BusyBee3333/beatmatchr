//
//  RuleEditorWindowController.swift
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

import Cocoa
import SwiftUI

class RuleEditorWindowController: NSWindowController, NSWindowDelegate {
    private var hostingController: NSHostingController<RuleEditorView>

    init(editingRule: YabaiRule? = nil, onSave: ((YabaiRule) -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        // Create the SwiftUI view with callbacks
        let ruleEditorView = RuleEditorView(
            editingRule: editingRule,
            onSave: { rule in
                onSave?(rule)
                // Close window after callback
                DispatchQueue.main.async {
                    NSApp.keyWindow?.close()
                }
            },
            onCancel: {
                onCancel?()
                // Close window after callback
                DispatchQueue.main.async {
                    NSApp.keyWindow?.close()
                }
            }
        )

        hostingController = NSHostingController(rootView: ruleEditorView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        window.center()
        window.title = editingRule == nil ? "Create Rule" : "Edit Rule"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showWindow() {
        print("🪟 RULE EDITOR: Showing SwiftUI-based rule editor window")

        guard let window = window else {
            print("❌ RULE EDITOR: No window to show")
            return
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        print("✅ RULE EDITOR: Window should now be visible")
    }

    // NSWindowDelegate method
    func windowWillClose(_ notification: Notification) {
        // Window is closing, nothing special needed since callbacks are handled in the view
    }
}