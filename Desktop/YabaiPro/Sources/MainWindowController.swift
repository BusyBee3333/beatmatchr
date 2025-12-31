//
//  MainWindowController.swift
//  YabaiPro
//

import Cocoa
import SwiftUI

class MainWindowController: NSWindowController {
    init() {
        super.init(window: nil)
        setupMainWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMainWindow() {
        let contentView = MainSettingsView()

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 700),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.center()
        window.title = "YabaiPro"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 700, height: 500)

        self.window = window
    }

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}




