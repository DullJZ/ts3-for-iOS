import Foundation
import TS3Kit

enum UIConnectionState {
    case disconnected
    case connecting
    case connected
}

struct TS3ChannelSummary: Identifiable {
    let id: Int
    var name: String
    var topic: String?
    var isCurrent: Bool
}

@MainActor
final class TS3AppModel: ObservableObject {
    @Published var state: UIConnectionState = .disconnected
    @Published var channels: [TS3ChannelSummary] = []
    @Published var isTalking = false
    @Published var logs: [TS3LogEntry] = []
    @Published var isShowingDebug = false
    @Published var lastError: String?

    @Published var serverHost = ""
    @Published var serverPort = "9987"
    @Published var serverPassword = ""
    @Published var nickname = "iOS" 

    private var client: TS3Client?

    var connectedStatus: String {
        switch state {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        }
    }

    var talkStatus: String {
        isTalking ? "Sending microphone audio" : "Mic idle"
    }

    var currentChannel: TS3ChannelSummary? {
        channels.first { $0.isCurrent }
    }

    private func setCurrentChannel(id: Int, name: String? = nil, topic: String? = nil) {
        var didFindChannel = false
        channels = channels.map { summary in
            var updated = summary
            let isCurrent = summary.id == id
            if isCurrent {
                didFindChannel = true
                updated.name = name ?? summary.name
                updated.topic = topic ?? summary.topic
            }
            updated.isCurrent = isCurrent
            return updated
        }

        if !didFindChannel, let name {
            channels.append(TS3ChannelSummary(id: id, name: name, topic: topic, isCurrent: true))
            channels.sort { $0.id < $1.id }
        }
    }

    func connect() {
        lastError = nil
        state = .connecting

        let port = Int(serverPort) ?? 9987
        let config = TS3ClientConfig(
            host: serverHost,
            port: port,
            nickname: nickname,
            serverPassword: serverPassword.isEmpty ? nil : serverPassword
        )

        let newClient = TS3Client(config: config)
        newClient.delegate = self
        newClient.logHandler = { [weak self] entry in
            DispatchQueue.main.async {
                self?.appendLog(entry)
            }
        }
        client = newClient

        Task {
            do {
                try await newClient.connect()
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.state = .disconnected
                }
            }
        }
    }

    func disconnect() {
        client?.disconnect(reason: "ui-disconnect")
        client = nil
        state = .disconnected
        channels = []
        isTalking = false
    }

    func joinChannel(_ channel: TS3ChannelSummary) {
        Task {
            do {
                try await client?.joinChannel(channelId: channel.id, password: nil)
                setCurrentChannel(id: channel.id, name: channel.name, topic: channel.topic)
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func createChannel(name: String, password: String) {
        Task {
            do {
                let channelId = try await client?.createChannel(name: name, password: password.isEmpty ? nil : password)
                if let channelId {
                    try await client?.joinChannel(channelId: channelId, password: password.isEmpty ? nil : password)
                    setCurrentChannel(id: channelId, name: name)
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func toggleTalking() {
        isTalking.toggle()
        if isTalking {
            client?.startMicrophone()
        } else {
            client?.stopMicrophone()
        }
    }

    func appendLog(_ entry: TS3LogEntry) {
        logs.append(entry)
        if logs.count > 500 {
            logs.removeFirst(logs.count - 500)
        }
    }

    func clearLogs() {
        logs.removeAll()
    }
}

extension TS3AppModel: TS3ClientDelegate {
    func ts3ClientDidConnect(_ client: TS3Client) {
        state = .connected
    }

    func ts3Client(_ client: TS3Client, didDisconnectWith error: Error?) {
        if let error {
            lastError = error.localizedDescription
        }
        state = .disconnected
    }

    func ts3Client(_ client: TS3Client, didUpdateChannels channels: [TS3Channel]) {
        self.channels = channels.map { channel in
            TS3ChannelSummary(
                id: channel.id,
                name: channel.name,
                topic: channel.topic,
                isCurrent: channel.id == client.currentChannelId
            )
        }
    }
}
