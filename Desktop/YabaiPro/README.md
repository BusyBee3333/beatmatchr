# YabaiPro

A lightweight macOS menu bar app for managing Yabai window manager settings. Provides an easy-to-use interface for toggling aesthetics, focus behavior, and applying presets.

## Features

- **Menu Bar Integration**: Clean status bar icon with popover interface
- **Aesthetic Controls**:
  - Fade inactive windows (SIP required)
  - Disable window shadows (SIP required)
  - Adjustable menu bar opacity (SIP required)
  - Window gap/padding slider
- **Focus & Behavior**:
  - Focus follows mouse toggle
- **Presets**: Quick "Default" and "Minimalist" configurations
- **Live Application**: Changes apply immediately to running Yabai instance
- **Config Persistence**: Updates `~/.yabairc` with your settings

## Requirements

- macOS 12.0+
- [Yabai](https://github.com/koekeishiya/yabai) installed and running
- Accessibility permissions granted to the app

## Installation

### From Source (Swift Package)

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/YabaiPro.git
   cd YabaiPro
   ```

2. Build with Swift:
   ```bash
   swift build -c release
   ```

3. Copy the executable to Applications:
   ```bash
   cp .build/release/YabaiPro /Applications/
   ```

### From Xcode

1. Open `Package.swift` in Xcode
2. Build and run the project
3. The app will appear in your menu bar

## Setup

### 1. Grant Accessibility Permissions

YabaiPro needs Accessibility permissions to control window management:

1. When you first run YabaiPro, it will show an alert asking for permissions
2. Click "Open System Settings" or go to:
   - System Settings → Privacy & Security → Accessibility
3. Add and enable YabaiPro in the list

### 2. Configure Yabai

Ensure Yabai is properly installed and configured. YabaiPro will create/update your `~/.yabairc` file.

## Usage

1. **Launch YabaiPro**: The app runs in the menu bar (rectangle.split.3x3 icon)
2. **Click the icon**: Opens the settings popover
3. **Adjust settings**: Toggle options and use sliders as needed
4. **Apply changes**: Click "Apply Changes" to update Yabai immediately
5. **Use presets**: Click "Default" or "Minimalist" for quick configurations

## SIP (System Integrity Protection) Features

Some features require SIP to be disabled:

- Fade inactive windows
- Disable window shadows
- Transparent menu bar

### To disable SIP:

1. Restart your Mac in Recovery Mode (hold Command + R during startup)
2. Open Terminal from the menu bar
3. Run: `csrutil disable`
4. Restart your Mac

⚠️ **Warning**: Disabling SIP reduces system security. Re-enable with `csrutil enable` when done.

## Troubleshooting

### Changes not applying?
- Ensure Yabai is running: `brew services start yabai`
- Check permissions in System Settings
- Restart Yabai: `launchctl kickstart -k gui/$(id -u)/org.yabai.yabai`

### Config file issues?
- YabaiPro backs up your `~/.yabairc` to `~/.yabairc.backup` before changes
- Restore backup if needed: `cp ~/.yabairc.backup ~/.yabairc`

### Permission denied errors?
- Re-grant Accessibility permissions
- Check that YabaiPro has execute permissions: `chmod +x /Applications/YabaiPro`

## Development

### Project Structure

```
YabaiPro/
├── Sources/
│   ├── YabaiProApp.swift      # Main app entry
│   ├── StatusBarController.swift  # Menu bar management
│   ├── SettingsView.swift     # UI components
│   ├── SettingsViewModel.swift # Business logic
│   ├── ConfigManager.swift    # ~/.yabairc management
│   ├── YabaiCommandRunner.swift # Command execution
│   └── PermissionsManager.swift # Accessibility permissions
├── Package.swift              # Swift package definition
└── README.md                  # This file
```

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests (when added)
swift test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with Yabai
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Acknowledgments

- [Yabai](https://github.com/koekeishiya/yabai) - The underlying window manager
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - For the beautiful interface

## Remote Control (iPhone companion)

YabaiPro can expose a local HTTP/WebSocket server that allows a companion iOS app ("WindowPilot") to control Yabai remotely over the local network.

Quick start:
1. Open YabaiPro and go to Settings → Remote Control.
2. Click "Start Server & Pair" to start the local server and generate a 6-digit PIN.
3. On the iPhone app (or a web client), discover the Mac via Bonjour (`_yabaipro._tcp`) and enter the PIN to pair.
4. The iOS app will receive a token which it stores in the Keychain and uses for future commands (Authorization: Bearer &lt;token&gt;).

Security notes:
- The server binds to `127.0.0.1` and advertises via Bonjour on the local network. Pairing uses an ephemeral PIN (default 2-minute lifetime).
- Paired devices are persisted to `Application Support` as `yabaipro_paired_devices.json`. Tokens are kept short-lived on the client and can be revoked from the app.

API (MVP):
- POST `/pair/start` -> { pin: "XXXXXX" }
- POST `/pair/confirm` { pin: "XXXXXX", name?: "My iPhone" } -> { token: "..." }
- GET `/state` -> { windows: [...], spaces: [...] }
- POST `/window/focus` { direction: "north" }
- POST `/space/focus` { index: 2 }

This feature is experimental. See the `Sources/RemoteServer.swift` and `Sources/RemoteAuthManager.swift` files for implementation details.

## Tailscale (recommended for remote pairing)

If you use Tailscale, pairing your iPhone to YabaiPro is simple and secure because Tailscale provides an encrypted mesh network between your devices.

Quick steps
1. Install and sign into Tailscale on both your Mac and iPhone.
2. In YabaiPro, open Settings → Remote Control and click "Start Server & Pair". The app will show a 6-digit PIN and list reachable addresses (LAN and Tailscale IPs) plus a QR code you can scan with your iPhone.
3. On the iPhone, use the companion app or any HTTP client to visit the displayed URL (for example `http://100.x.y.z:PORT/pair/start`) or scan the QR code. Confirm pairing in the app by entering the PIN when prompted.
4. After `POST /pair/confirm` returns a token, the iPhone client stores it and uses `Authorization: Bearer <token>` for future commands.

Notes and tips
- The macOS server binds to all interfaces (0.0.0.0) so it is reachable from LAN addresses and Tailscale IPs. The Settings UI shows the list of reachable HTTP URLs and a QR code for easy pairing.
- If you use Tailscale MagicDNS, you can also use the MagicDNS hostname (e.g., `my-mac.tailnet.example`) instead of the raw IP.
- For local-only testing (no phone), YabaiPro still supports loopback testing via `127.0.0.1` when run locally from the build.

Security recommendations
- Keep pairing PINs short-lived (default 2 minutes) and require the Bearer token for all protected endpoints (already implemented).
- Prefer connecting over Tailscale (encrypted mesh). Do not open the server port to the public internet unless you enable additional TLS/ACL protections.
- Use Tailscale ACLs to restrict which devices on your tailnet can reach your Mac.
- If you need to allow access outside Tailscale, consider adding TLS and stronger authentication (mutual TLS or OAuth) before exposing the server.

Troubleshooting
- If the iPhone cannot reach the Mac over Tailscale, verify Tailscale is running on both devices and check the Mac's reachable addresses shown in Settings. Running `tailscale ip -4` on the Mac prints your Tailscale IPv4 address.
