//
//  RemoteAuthManager.swift
//  YabaiPro
//
//  Lightweight pairing manager for local network devices
//

import Foundation

final class RemoteAuthManager {
    static let shared = RemoteAuthManager()

    struct PairedDevice: Codable {
        var name: String
        var token: String
        var pairedAt: Date
    }

    private let storageURL: URL
    private var pairedDevices: [PairedDevice] = []

    // ephemeral PIN -> token mapping (in-memory)
    private var pendingPins: [String: String] = [:]
    private let pinLifetimeSeconds: TimeInterval = 120

    private init() {
        let fm = FileManager.default
        let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport ?? URL(fileURLWithPath: NSTemporaryDirectory())
        storageURL = dir.appendingPathComponent("yabaipro_paired_devices.json")
        load()
    }

    private func load() {
        do {
            let data = try Data(contentsOf: storageURL)
            pairedDevices = try JSONDecoder().decode([PairedDevice].self, from: data)
        } catch {
            pairedDevices = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(pairedDevices)
            try FileManager.default.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: storageURL, options: [.atomic])
        } catch {
            print("RemoteAuthManager: failed to save paired devices: \(error)")
        }
    }

    func generatePIN() -> String {
        // generate 6-digit pin
        let pin = String(format: "%06d", Int.random(in: 0...999999))
        let token = UUID().uuidString
        pendingPins[pin] = token

        // schedule expiration
        DispatchQueue.global().asyncAfter(deadline: .now() + pinLifetimeSeconds) { [weak self] in
            self?.pendingPins[pin] = nil
        }
        return pin
    }

    func confirmPIN(_ pin: String, deviceName: String?) -> String? {
        guard let token = pendingPins[pin] else { return nil }
        pendingPins[pin] = nil

        let name = deviceName ?? "iPhone-\(Int.random(in: 1000...9999))"
        let device = PairedDevice(name: name, token: token, pairedAt: Date())
        pairedDevices.append(device)
        save()
        return token
    }

    func revokeDevice(named name: String) {
        pairedDevices.removeAll { $0.name == name }
        save()
    }

    func isTokenPaired(_ token: String) -> Bool {
        pairedDevices.contains { $0.token == token }
    }

    func listPairedDevices() -> [PairedDevice] {
        pairedDevices
    }
}













