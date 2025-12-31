//
//  RemoteServer.swift
//  YabaiPro
//
//  Minimal HTTP + WebSocket server using SwiftNIO for local control
//

import Foundation
import NIO
import NIOHTTP1
import Network

final class RemoteServer {
    static let shared = RemoteServer()

    private var group: EventLoopGroup?
    private var channel: Channel?
    private var netService: NetService?
    private let yabaiRunner = YabaiCommandRunner()
    private let auth = RemoteAuthManager.shared

    private(set) var port: Int = 0
    private init() {}

    func start() throws {
        // create event loop group
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.group = group

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler(yabaiRunner: self.yabaiRunner, auth: self.auth))
                }
            }
        // Bind to all interfaces so devices on the LAN or a VPN (e.g., Tailscale) can reach the server
        let channel = try bootstrap.bind(host: "0.0.0.0", port: 0).wait()
        self.channel = channel
        if let localAddress = channel.localAddress, let port = localAddress.port {
            self.port = port
            advertise(port: port)
            print("RemoteServer: listening on 127.0.0.1:\(port)")
        } else {
            throw NSError(domain: "RemoteServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to bind"])
        }
    }

    func stop() {
        if let svc = netService {
            svc.stop()
            netService = nil
        }
        if let ch = channel {
            _ = ch.close()
            channel = nil
        }
        if let g = group {
            do {
                try g.syncShutdownGracefully()
            } catch {
                print("RemoteServer: error shutting down: \(error)")
            }
            group = nil
        }
    }

    private func advertise(port: Int) {
        // Advertise via Bonjour
        let service = NetService(domain: "local.", type: "_yabaipro._tcp.", name: "YabaiPro", port: Int32(port))
        service.publish()
        self.netService = service
    }

    /// Returns a list of non-loopback IPv4 addresses for this host.
    func reachableIPAddresses() -> [String] {
        var results: [String] = []
        var ifaddrPointer: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddrPointer) == 0, let firstAddr = ifaddrPointer {
            var ptr = firstAddr
            while true {
                let flags = Int32(ptr.pointee.ifa_flags)
                let addr = ptr.pointee.ifa_addr.pointee
                let family = addr.sa_family
                if family == UInt8(AF_INET) {
                    // Exclude loopback
                    if (flags & IFF_LOOPBACK) == 0 {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        var sa = ptr.pointee.ifa_addr.pointee
                        let result = getnameinfo(&sa, socklen_t(sa.sa_len), &hostname, socklen_t(hostname.count),
                                                 nil, 0, NI_NUMERICHOST)
                        if result == 0 {
                            let address = String(cString: hostname)
                            results.append(address)
                        }
                    }
                }
                if let next = ptr.pointee.ifa_next {
                    ptr = next
                } else {
                    break
                }
            }
            freeifaddrs(ifaddrPointer)
        }
        return results
    }
}

// MARK: - HTTP Handler

private final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private var requestHead: HTTPRequestHead?
    private var buffer: ByteBuffer?
    private let yabaiRunner: YabaiCommandRunner
    private let auth: RemoteAuthManager

    init(yabaiRunner: YabaiCommandRunner, auth: RemoteAuthManager) {
        self.yabaiRunner = yabaiRunner
        self.auth = auth
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)
        switch part {
        case .head(let head):
            requestHead = head
            buffer = context.channel.allocator.buffer(capacity: 0)
        case .body(var chunk):
            buffer?.writeBuffer(&chunk)
        case .end:
            handleRequest(context: context)
        }
    }

    private func handleRequest(context: ChannelHandlerContext) {
        guard let head = requestHead else { return }
        let method = head.method
        let uri = head.uri

        var bodyString: String = ""
        if let buf = buffer {
            bodyString = buf.getString(at: buf.readerIndex, length: buf.readableBytes) ?? ""
        }

        // Basic routing
        if method == .POST && uri == "/pair/start" {
            let pin = auth.generatePIN()
            let json = ["pin": pin]
            sendJSON(context: context, status: .ok, object: json)
            return
        }

        if method == .POST && uri == "/pair/confirm" {
            if let data = bodyString.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let pin = obj["pin"] as? String {
                let name = obj["name"] as? String
                if let token = auth.confirmPIN(pin, deviceName: name) {
                    sendJSON(context: context, status: .ok, object: ["token": token])
                } else {
                    sendJSON(context: context, status: .unauthorized, object: ["error": "invalid_pin"])
                }
            } else {
                sendJSON(context: context, status: .badRequest, object: ["error": "bad_payload"])
            }
            return
        }

        // Protected endpoints: require Authorization header
        var token: String?
        if let authHeader = requestHead?.headers.first(name: "Authorization") {
            if authHeader.hasPrefix("Bearer ") {
                token = String(authHeader.dropFirst("Bearer ".count))
            }
        }

        if uri == "/state" && method == .GET {
            Task {
                do {
                    let windowsData = try await yabaiRunner.queryWindows()
                    let spacesData = try await yabaiRunner.querySpaces()
                    // return raw JSON merged
                    let windows = try JSONSerialization.jsonObject(with: windowsData)
                    let spaces = try JSONSerialization.jsonObject(with: spacesData)
                    let payload: [String:Any] = ["windows": windows, "spaces": spaces]
                    sendJSON(context: context, status: .ok, object: payload)
                } catch {
                    sendJSON(context: context, status: .internalServerError, object: ["error": "\(error)"])
                }
            }
            return
        }

        // window focus
        if method == .POST && uri == "/window/focus" {
            guard let token = token, auth.isTokenPaired(token) else {
                sendJSON(context: context, status: .unauthorized, object: ["error": "unauthorized"])
                return
            }
            if let data = bodyString.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let direction = obj["direction"] as? String,
               let dir = WindowDirection(rawValue: direction) {
                Task {
                    do {
                        try await yabaiRunner.focusWindow(direction: dir)
                        sendJSON(context: context, status: .ok, object: ["result": "ok"])
                    } catch {
                        sendJSON(context: context, status: .internalServerError, object: ["error": "\(error)"])
                    }
                }
            } else {
                sendJSON(context: context, status: .badRequest, object: ["error": "bad_payload"])
            }
            return
        }

        if method == .POST && uri == "/space/focus" {
            guard let token = token, auth.isTokenPaired(token) else {
                sendJSON(context: context, status: .unauthorized, object: ["error": "unauthorized"])
                return
            }
            if let data = bodyString.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
               let idx = obj["index"] as? Int {
                Task {
                    do {
                        try await yabaiRunner.focusSpace(index: UInt32(idx))
                        sendJSON(context: context, status: .ok, object: ["result": "ok"])
                    } catch {
                        sendJSON(context: context, status: .internalServerError, object: ["error": "\(error)"])
                    }
                }
            } else {
                sendJSON(context: context, status: .badRequest, object: ["error": "bad_payload"])
            }
            return
        }

        // fallback 404
        sendJSON(context: context, status: .notFound, object: ["error": "not_found"])
    }

    private func sendJSON(context: ChannelHandlerContext, status: HTTPResponseStatus, object: Any) {
        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: object)
        } catch {
            let str = "{\"error\":\"serialization_failed\"}"
            let buffer = context.channel.allocator.buffer(string: str)
            var headers = HTTPHeaders()
            headers.add(name: "Content-Type", value: "application/json")
            let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: .internalServerError, headers: headers)
            context.write(self.wrapOutboundOut(.head(head)), promise: nil)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
            return
        }

        var buffer = context.channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Content-Length", value: "\(buffer.readableBytes)")
        let head = HTTPResponseHead(version: .init(major: 1, minor: 1), status: status, headers: headers)
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
}


