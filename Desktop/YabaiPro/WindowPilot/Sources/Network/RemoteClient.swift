import Foundation
import Combine

final class RemoteClient: ObservableObject {
    static let shared = RemoteClient()

    @Published var currentPIN: String?
    @Published var token: String?

    private init() {}

    private func baseURL(for serviceName: String) -> URL? {
        // For scaffolding, resolve via localhost; real implementation should resolve NetService
        // We'll attempt localhost with a common port placeholder, server advertises actual port in future
        return URL(string: "http://127.0.0.1:0")
    }

    func startPairing(on host: String = "127.0.0.1", port: Int) async throws -> String {
        guard let url = URL(string: "http://\(host):\(port)/pair/start") else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
           let pin = obj["pin"] as? String {
            DispatchQueue.main.async {
                self.currentPIN = pin
            }
            return pin
        }
        throw URLError(.badServerResponse)
    }

    func confirmPairing(pin: String, host: String = "127.0.0.1", port: Int) async throws -> String {
        guard let url = URL(string: "http://\(host):\(port)/pair/confirm") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ["pin": pin, "name": "WindowPilot"]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
           let token = obj["token"] as? String {
            DispatchQueue.main.async {
                self.token = token
            }
            return token
        }
        throw URLError(.badServerResponse)
    }

    func focus(direction: String) async throws {
        guard let token = token else { throw URLError(.userAuthenticationRequired) }
        // placeholder - real host/port resolution needed
        guard let url = URL(string: "http://127.0.0.1:0/window/focus") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["direction": direction])
        _ = try await URLSession.shared.data(for: req)
    }

    func toggleFloat() async throws {
        guard let token = token else { throw URLError(.userAuthenticationRequired) }
        guard let url = URL(string: "http://127.0.0.1:0/window/toggle_float") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await URLSession.shared.data(for: req)
    }
}













