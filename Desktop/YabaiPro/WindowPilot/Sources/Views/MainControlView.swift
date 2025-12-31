import SwiftUI

struct MainControlView: View {
    @EnvironmentObject var discovery: DiscoveryManager
    @EnvironmentObject var client: RemoteClient

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                Text("WINDOW PILOT")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)

                HStack(spacing: 12) {
                    ForEach(discovery.discoveredServices, id: \.self) { svc in
                        Button(action: { discovery.selectService(svc) }) {
                            Text(svc)
                                .padding(8)
                                .background(discovery.selectedService == svc ? Color.cyan.opacity(0.2) : Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                }

                Spacer()

                // D-pad
                VStack(spacing: 12) {
                    Button(action: { Task { try? await client.focus(direction: "north") } }) {
                        Image(systemName: "arrow.up")
                            .font(.title)
                            .padding(18)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }

                    HStack(spacing: 20) {
                        Button(action: { Task { try? await client.focus(direction: "west") } }) {
                            Image(systemName: "arrow.left")
                                .font(.title2)
                                .padding(16)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }

                        Button(action: { Task { try? await client.toggleFloat() } }) {
                            Image(systemName: "square.on.circle")
                                .font(.title2)
                                .padding(16)
                                .background(Color.cyan)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                        }

                        Button(action: { Task { try? await client.focus(direction: "east") } }) {
                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .padding(16)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }

                    Button(action: { Task { try? await client.focus(direction: "south") } }) {
                        Image(systemName: "arrow.down")
                            .font(.title)
                            .padding(18)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 24)

                Spacer()

                // Pairing / status
                HStack {
                    if let pin = client.currentPIN {
                        Text("PIN: \(pin)")
                            .font(.caption)
                            .foregroundColor(.cyan)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }

                    Spacer()

                    Button(action: { discovery.refresh() }) {
                        Text("Refresh")
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("WindowPilot")
        }
    }
}

struct MainControlView_Previews: PreviewProvider {
    static var previews: some View {
        MainControlView()
            .environmentObject(DiscoveryManager.shared)
            .environmentObject(RemoteClient.shared)
    }
}













