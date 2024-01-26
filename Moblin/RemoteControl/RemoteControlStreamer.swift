import Foundation

protocol RemoteControlStreamerDelegate: AnyObject {
    func connected()
    func disconnected()
    func getStatus(onComplete: @escaping (RemoteControlStatusTopLeft, RemoteControlStatusTopRight) -> Void)
    func getSettings(onComplete: @escaping (RemoteControlSettings) -> Void)
    func setScene(id: UUID, onComplete: @escaping () -> Void)
    func setBitratePreset(id: UUID, onComplete: @escaping () -> Void)
    func setZoom(x: Float, onComplete: @escaping () -> Void)
}

class RemoteControlStreamer {
    private var clientUrl: URL
    private var password: String
    private weak var delegate: (any RemoteControlStreamerDelegate)?
    private var webSocket: URLSessionWebSocketTask
    private var task: Task<Void, Error>?
    private var connected = false

    init(clientUrl: URL, password: String, delegate: RemoteControlStreamerDelegate) {
        self.clientUrl = clientUrl
        self.password = password
        self.delegate = delegate
        webSocket = URLSession(configuration: .default).webSocketTask(with: clientUrl)
    }

    func start() {
        stop()
        logger.info("remote-control-streamer: start")
        task = Task.init {
            while true {
                setupConnection()
                do {
                    try await receiveMessages()
                } catch {
                    logger.debug("remote-control-streamer: error: \(error.localizedDescription)")
                }
                if Task.isCancelled {
                    logger.debug("remote-control-streamer: Cancelled")
                    break
                }
                if connected {
                    delegate?.disconnected()
                    connected = false
                }
                logger.debug("remote-control-streamer: Disconnected")
                try await Task.sleep(nanoseconds: 5_000_000_000)
                logger.debug("remote-control-streamer: Reconnecting")
            }
        }
    }

    func stop() {
        logger.info("remote-control-streamer: stop")
        task?.cancel()
        task = nil
        connected = false
    }

    func stateChanged(state: RemoteControlState) {
        send(message: .event(data: .state(data: state)))
    }

    private func setupConnection() {
        webSocket = URLSession.shared.webSocketTask(with: clientUrl)
        webSocket.resume()
    }

    private func send(message: RemoteControlMessageToAssistant) {
        do {
            try webSocket.send(.string(message.toJson())) { _ in }
        } catch {
            logger.info("remote-control-streamer: Encode failed")
        }
    }

    private func receiveMessages() async throws {
        while true {
            let message = try await webSocket.receive()
            if Task.isCancelled {
                break
            }
            switch message {
            case let .data(message):
                logger.debug("remote-control-streamer: Got data \(message)")
            case let .string(message):
                logger.debug("remote-control-streamer: Got message \(message)")
                do {
                    switch try RemoteControlMessageToStreamer.fromJson(data: message) {
                    case let .hello(apiVersion: apiVersion, authentication: authentication):
                        handleHello(apiVersion: apiVersion, authentication: authentication)
                    case let .request(id: id, data: data):
                        handleRequest(id: id, data: data)
                    }
                } catch {
                    logger.info("remote-control-streamer: Decode failed")
                }
            default:
                logger.debug("remote-control-streamer: ???")
            }
        }
    }

    private func handleHello(apiVersion _: String, authentication: RemoteControlAuthentication) {
        let hash = remoteControlHashPassword(
            challenge: authentication.challenge,
            salt: authentication.salt,
            password: password
        )
        send(message: .identify(authentication: hash))
        connected = true
        delegate?.connected()
    }

    private func handleRequest(id: Int, data: RemoteControlRequest) {
        guard let delegate else {
            return
        }
        switch data {
        case .getStatus:
            delegate.getStatus { topLeft, topRight in
                self.send(message: .response(
                    id: id,
                    result: .ok,
                    data: .getStatus(topLeft: topLeft, topRight: topRight)
                ))
            }
        case .getSettings:
            delegate.getSettings { data in
                self.send(message: .response(id: id, result: .ok, data: .getSettings(data: data)))
            }
        case let .setScene(id: sceneId):
            delegate.setScene(id: sceneId) {
                self.send(message: .response(id: id, result: .ok, data: nil))
            }
        case let .setBitratePreset(id: bitratePresetId):
            delegate.setBitratePreset(id: bitratePresetId) {
                self.send(message: .response(id: id, result: .ok, data: nil))
            }
        case let .setZoom(x: x):
            delegate.setZoom(x: x) {
                self.send(message: .response(id: id, result: .ok, data: nil))
            }
        default:
            send(message: .response(id: id, result: .unknownRequest, data: nil))
        }
    }
}