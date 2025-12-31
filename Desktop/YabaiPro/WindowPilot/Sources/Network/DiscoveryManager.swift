import Foundation
import Combine

final class DiscoveryManager: ObservableObject {
    static let shared = DiscoveryManager()

    @Published var discoveredServices: [String] = []
    @Published var selectedService: String?

    private var browser: NetServiceBrowser?
    private var services: [NetService] = []

    private init() {
        // start browsing automatically
        refresh()
    }

    func refresh() {
        discoveredServices = []
        services = []
        browser?.stop()
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: "_yabaipro._tcp.", inDomain: "local.")
    }

    func selectService(_ name: String) {
        selectedService = name
    }
}

extension DiscoveryManager: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.append(service)
        discoveredServices.append(service.name)
    }
}













