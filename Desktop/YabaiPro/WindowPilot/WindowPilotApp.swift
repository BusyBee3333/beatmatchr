import SwiftUI

@main
struct WindowPilotApp: App {
    @StateObject private var discovery = DiscoveryManager.shared
    @StateObject private var client = RemoteClient.shared

    var body: some Scene {
        WindowGroup {
            MainControlView()
                .environmentObject(discovery)
                .environmentObject(client)
        }
    }
}













