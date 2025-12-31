WindowPilot iOS prototype

This directory contains a minimal SwiftUI prototype for the iPhone companion app.

Files:
- WindowPilotApp.swift — app entry
- Sources/Views/MainControlView.swift — primary control UI (D-pad, pairing status)
- Sources/Network/DiscoveryManager.swift — mDNS discovery stub
- Sources/Network/RemoteClient.swift — REST pairing & command client (scaffold)
- Sources/Models/WindowState.swift — simple models for windows and spaces

Notes:
- This is scaffolding to bootstrap development. Network resolution of NetService to host/port and Keychain storage for tokens should be implemented next.













