import Cocoa
import WebKit
import SwiftUI

class WebRuleEditorViewController: NSViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var editingRule: YabaiRule?

    var onSave: ((YabaiRule) -> Void)?
    var onCancel: (() -> Void)?

    init(editingRule: YabaiRule? = nil) {
        self.editingRule = editingRule
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let userController = WKUserContentController()

        // Add script message handlers for communication
        userController.add(self, name: "saveRule")
        userController.add(self, name: "cancelRule")

        webConfiguration.userContentController = userController

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self

        // Enable keyboard input and focus
        webView.setValue(false, forKey: "drawsBackground")

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the HTML content
        if let htmlPath = Bundle.main.path(forResource: "rule-editor", ofType: "html") {
            let htmlUrl = URL(fileURLWithPath: htmlPath)
            webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())
        } else {
            // Fallback: inline HTML
            loadInlineHTML()
        }

        // Ensure the web view can receive keyboard input
        webView.becomeFirstResponder()
    }

    private func loadInlineHTML() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    margin: 20px;
                    background: #f5f5f7;
                    color: #333;
                }
                .form-group {
                    margin-bottom: 15px;
                }
                label {
                    display: block;
                    margin-bottom: 5px;
                    font-weight: 500;
                }
                input, select {
                    width: 100%;
                    padding: 8px;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    font-size: 14px;
                    box-sizing: border-box;
                }
                input:focus, select:focus {
                    outline: none;
                    border-color: #007aff;
                    box-shadow: 0 0 0 2px rgba(0, 122, 255, 0.2);
                }
                .checkbox-group {
                    display: flex;
                    align-items: center;
                    margin-bottom: 10px;
                }
                .checkbox-group input[type="checkbox"] {
                    width: auto;
                    margin-right: 8px;
                }
                .button-group {
                    display: flex;
                    justify-content: flex-end;
                    gap: 10px;
                    margin-top: 20px;
                }
                button {
                    padding: 8px 16px;
                    border: none;
                    border-radius: 4px;
                    font-size: 14px;
                    cursor: pointer;
                }
                .save-btn {
                    background: #007aff;
                    color: white;
                }
                .cancel-btn {
                    background: #f5f5f5;
                    color: #333;
                    border: 1px solid #ddd;
                }
                button:hover {
                    opacity: 0.9;
                }
                .section {
                    background: white;
                    padding: 15px;
                    border-radius: 8px;
                    margin-bottom: 15px;
                    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
                }
                h3 {
                    margin-top: 0;
                    margin-bottom: 10px;
                    color: #666;
                    font-size: 12px;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
            </style>
        </head>
        <body>
            <div class="section">
                <h3>Matching Criteria</h3>
                <div class="form-group">
                    <label for="app">Application:</label>
                    <input type="text" id="app" placeholder="e.g., Safari, Chrome">
                </div>
                <div class="form-group">
                    <label for="title">Window Title:</label>
                    <input type="text" id="title" placeholder="e.g., contains text">
                </div>
                <div class="form-group">
                    <label for="role">Role:</label>
                    <select id="role">
                        <option value="">Any</option>
                        <option value="AXWindow">Window</option>
                        <option value="AXDialog">Dialog</option>
                        <option value="AXSheet">Sheet</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="subrole">Subrole:</label>
                    <select id="subrole">
                        <option value="">Any</option>
                        <option value="AXStandardWindow">Standard Window</option>
                        <option value="AXDialog">Dialog</option>
                        <option value="AXSystemDialog">System Dialog</option>
                    </select>
                </div>
            </div>

            <div class="section">
                <h3>Actions</h3>
                <div class="checkbox-group">
                    <input type="checkbox" id="manage">
                    <label for="manage">Manage window</label>
                </div>
                <div class="checkbox-group">
                    <input type="checkbox" id="sticky">
                    <label for="sticky">Sticky window</label>
                </div>
                <div class="checkbox-group">
                    <input type="checkbox" id="mouse_follows_focus">
                    <label for="mouse_follows_focus">Mouse follows focus</label>
                </div>
                <div class="form-group">
                    <label for="layer">Layer:</label>
                    <select id="layer">
                        <option value="below">Below</option>
                        <option value="normal">Normal</option>
                        <option value="above">Above</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="opacity">Opacity:</label>
                    <input type="number" id="opacity" min="0.0" max="1.0" step="0.1" value="1.0">
                </div>
                <div class="checkbox-group">
                    <input type="checkbox" id="border">
                    <label for="border">Show border</label>
                </div>
            </div>

            <div class="button-group">
                <button class="cancel-btn" onclick="cancelRule()">Cancel</button>
                <button class="save-btn" onclick="saveRule()">Create Rule</button>
            </div>

            <script>
                // Focus first input field on load
                document.getElementById('app').focus();

                // Load existing rule data if editing
                window.onload = function() {
                    // This would be populated with existing rule data
                    console.log('Rule editor loaded');
                };

                function saveRule() {
                    const rule = {
                        app: document.getElementById('app').value || null,
                        title: document.getElementById('title').value || null,
                        role: document.getElementById('role').value || null,
                        subrole: document.getElementById('subrole').value || null,
                        manage: document.getElementById('manage').checked,
                        sticky: document.getElementById('sticky').checked,
                        mouse_follows_focus: document.getElementById('mouse_follows_focus').checked,
                        layer: document.getElementById('layer').value,
                        opacity: parseFloat(document.getElementById('opacity').value),
                        border: document.getElementById('border').checked
                    };

                    // Send to native app
                    window.webkit.messageHandlers.saveRule.postMessage(rule);
                }

                function cancelRule() {
                    window.webkit.messageHandlers.cancelRule.postMessage({});
                }

                // Handle Enter key in inputs
                document.addEventListener('keydown', function(e) {
                    if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        saveRule();
                    } else if (e.key === 'Escape') {
                        e.preventDefault();
                        cancelRule();
                    }
                });
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "saveRule":
            if let ruleDict = message.body as? [String: Any] {
                // Extract values to make type-checking easier
                let app = ruleDict["app"] as? String
                let title = ruleDict["title"] as? String
                let role = ruleDict["role"] as? String
                let subrole = ruleDict["subrole"] as? String
                let manage = (ruleDict["manage"] as? Bool ?? true) ? YabaiRule.ManageState.on : YabaiRule.ManageState.off
                let sticky = (ruleDict["sticky"] as? Bool ?? false) ? YabaiRule.StickyState.on : YabaiRule.StickyState.off
                let mouseFollowsFocus = ruleDict["mouse_follows_focus"] as? Bool ?? false
                let layerString = ruleDict["layer"] as? String ?? "normal"
                let layer = YabaiRule.WindowLayer(rawValue: layerString) ?? YabaiRule.WindowLayer.normal
                let opacity = ruleDict["opacity"] as? Double ?? 1.0
                let border = (ruleDict["border"] as? Bool ?? false) ? YabaiRule.BorderState.on : YabaiRule.BorderState.off

                let rule = YabaiRule(
                    app: app,
                    title: title,
                    role: role,
                    subrole: subrole,
                    manage: manage,
                    sticky: sticky,
                    mouseFollowsFocus: mouseFollowsFocus,
                    layer: layer,
                    opacity: opacity,
                    border: border
                )
                onSave?(rule)
                dismissController()
            }
        case "cancelRule":
            onCancel?()
            dismissController()
        default:
            break
        }
    }

    private func dismissController() {
        if let window = view.window {
            window.close()
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Web view loaded, ensure it can receive keyboard input
        DispatchQueue.main.async {
            webView.window?.makeFirstResponder(webView)
        }
    }
}

// MARK: - Window Controller

class WebRuleEditorWindowController: NSWindowController, NSWindowDelegate {
    private var webViewController: WebRuleEditorViewController

    init(editingRule: YabaiRule? = nil) {
        webViewController = WebRuleEditorViewController(editingRule: editingRule)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        super.init(window: window)

        window.center()
        window.title = editingRule == nil ? "Create Rule" : "Edit Rule"
        window.contentViewController = webViewController
        window.isReleasedWhenClosed = false
        window.delegate = self

        webViewController.onSave = { [weak self] rule in
            // Forward to parent window controller if needed
            self?.onSave?(rule)
        }

        webViewController.onCancel = { [weak self] in
            self?.onCancel?()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var onSave: ((YabaiRule) -> Void)?
    var onCancel: (() -> Void)?

    func showWindow() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Ensure web view gets focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let webView = self.webViewController.view as? WKWebView {
                self.window?.makeFirstResponder(webView)
            }
        }
    }

    // NSWindowDelegate method
    func windowWillClose(_ notification: Notification) {
        onCancel?()
    }
}

