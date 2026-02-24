import Foundation
import Network

/// WebSocket server for broadcasting tweak replay commands to browsers
final class TweakBroadcastServer {
    static let shared = TweakBroadcastServer()

    private let wsPort: UInt16 = 19876
    private let httpPort: UInt16 = 19877
    private var wsListener: NWListener?
    private var httpListener: NWListener?
    private var connections: [NWConnection] = []
    private let queue = DispatchQueue(label: "TweakBroadcastServer")

    private init() {}

    func start() {
        startWebSocketServer()
        startHTTPServer()
    }

    func stop() {
        wsListener?.cancel()
        httpListener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
    }

    // MARK: - WebSocket Server (port 19876)

    private func startWebSocketServer() {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        let wsOptions = NWProtocolWebSocket.Options()
        wsOptions.autoReplyPing = true
        params.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        do {
            wsListener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: wsPort)!)
        } catch {
            print("[TweakBroadcast] Failed to create WebSocket listener: \(error)")
            return
        }

        wsListener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[TweakBroadcast] WebSocket server ready on port \(self.wsPort)")
            case .failed(let error):
                print("[TweakBroadcast] WebSocket server failed: \(error)")
            default:
                break
            }
        }

        wsListener?.newConnectionHandler = { [weak self] connection in
            self?.handleWebSocketConnection(connection)
        }

        wsListener?.start(queue: queue)
    }

    private func handleWebSocketConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("[TweakBroadcast] Browser connected")
                self?.queue.async {
                    self?.connections.append(connection)
                }
                self?.receiveWebSocketMessages(connection)
            case .failed, .cancelled:
                self?.queue.async {
                    self?.connections.removeAll { $0 === connection }
                }
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    private func receiveWebSocketMessages(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] content, context, _, error in
            if error != nil { return }
            // Keep connection alive by continuing to receive
            self?.receiveWebSocketMessages(connection)
        }
    }

    // MARK: - HTTP Server (port 19877)

    private func startHTTPServer() {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        do {
            httpListener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: httpPort)!)
        } catch {
            print("[TweakBroadcast] Failed to create HTTP listener: \(error)")
            return
        }

        httpListener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[TweakBroadcast] HTTP server ready on port \(self.httpPort)")
            case .failed(let error):
                print("[TweakBroadcast] HTTP server failed: \(error)")
            default:
                break
            }
        }

        httpListener?.newConnectionHandler = { [weak self] connection in
            self?.handleHTTPConnection(connection)
        }

        httpListener?.start(queue: queue)
    }

    private func handleHTTPConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                self.receiveHTTPRequest(connection)
            }
        }
        connection.start(queue: queue)
    }

    private func receiveHTTPRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, _, error in
            guard error == nil, let data = data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }

            // Check for replay endpoint
            if request.contains("POST") && request.contains("/__replay") {
                self?.broadcastReplay()
                self?.sendHTTPResponse(connection, status: "200 OK", body: "{\"ok\":true}")
            } else {
                self?.sendHTTPResponse(connection, status: "404 Not Found", body: "{\"error\":\"not found\"}")
            }
        }
    }

    private func sendHTTPResponse(_ connection: NWConnection, status: String, body: String) {
        let response = """
        HTTP/1.1 \(status)\r
        Content-Type: application/json\r
        Access-Control-Allow-Origin: *\r
        Content-Length: \(body.utf8.count)\r
        Connection: close\r
        \r
        \(body)
        """

        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    // MARK: - Broadcast

    func broadcastReplay() {
        let message = "{\"type\":\"replay\"}"
        guard let data = message.data(using: .utf8) else { return }

        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "replay", metadata: [metadata])

        queue.async {
            for connection in self.connections {
                connection.send(content: data, contentContext: context, completion: .contentProcessed { error in
                    if let error = error {
                        print("[TweakBroadcast] Send error: \(error)")
                    }
                })
            }
            print("[TweakBroadcast] Broadcast replay to \(self.connections.count) client(s)")
        }
    }
}
