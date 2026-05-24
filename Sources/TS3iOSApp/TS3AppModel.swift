import Foundation
import TS3Kit
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(AVFAudio)
import AVFAudio
#endif

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

struct TS3UserSummary: Identifiable {
    let id: Int
    let channelId: Int
    let nickname: String
    let isCurrentUser: Bool
}

struct MicrophonePermissionPrompt: Identifiable {
    enum Action {
        case requestAccess
        case openSettings
    }

    let id = UUID()
    let title: String
    let message: String
    let confirmTitle: String
    let action: Action

    static let requestAccess = MicrophonePermissionPrompt(
        title: "Allow Microphone Access",
        message: "Push To Talk needs microphone access. Continue to request permission from the system.",
        confirmTitle: "Continue",
        action: .requestAccess
    )

    static let openSettings = MicrophonePermissionPrompt(
        title: "Microphone Access Required",
        message: "Microphone access is currently denied. Open system settings and allow microphone access for this app.",
        confirmTitle: "Open Settings",
        action: .openSettings
    )
}

@MainActor
final class TS3AppModel: ObservableObject {
    @Published var state: UIConnectionState = .disconnected
    @Published var channels: [TS3ChannelSummary] = []
    @Published var clients: [TS3UserSummary] = []
    @Published var isTalking = false
    @Published var logs: [TS3LogEntry] = []
    @Published var isShowingDebug = false
    @Published var lastError: String?
    @Published var playbackVolume: Double = 1.0
    @Published var microphonePermissionPrompt: MicrophonePermissionPrompt?

    @Published var serverHost = ""
    @Published var serverPort = "9987"
    @Published var serverPassword = ""
    @Published var nickname = TS3PlatformSupport.defaultNickname

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

    var playbackVolumePercentText: String {
        "\(Int((playbackVolume * 100).rounded()))%"
    }

    var currentChannel: TS3ChannelSummary? {
        channels.first { $0.isCurrent }
    }

    func members(in channelId: Int) -> [TS3UserSummary] {
        clients
            .filter { $0.channelId == channelId }
            .sorted {
                if $0.isCurrentUser != $1.isCurrentUser { return $0.isCurrentUser && !$1.isCurrentUser }
                return $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending
            }
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
        newClient.setPlaybackVolume(Float(playbackVolume))
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
        client?.delegate = nil
        client?.disconnect(reason: "ui-disconnect")
        client = nil
        state = .disconnected
        channels = []
        clients = []
        isTalking = false
        microphonePermissionPrompt = nil
    }

    func updatePlaybackVolume(_ volume: Double) {
        let clamped = min(max(volume, 0), 4)
        playbackVolume = clamped
        client?.setPlaybackVolume(Float(clamped))
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

    func toggleTalking() {
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
            return
        }

        guard let client else {
            lastError = "Connect to a server before using Push To Talk."
            return
        }

        switch currentMicrophonePermissionState() {
        case .granted:
            beginTalking(with: client)
        case .notDetermined:
            appendAudioPermissionLog("prompt", status: "requestAccess")
            microphonePermissionPrompt = .requestAccess
        case .denied:
            appendAudioPermissionLog("prompt", status: "openSettings")
            microphonePermissionPrompt = .openSettings
        }
    }

    func confirmMicrophonePermissionPrompt(_ prompt: MicrophonePermissionPrompt) {
        appendAudioPermissionLog("prompt confirm", status: prompt.confirmTitle)
        microphonePermissionPrompt = nil

        switch prompt.action {
        case .requestAccess:
            guard let client else {
                lastError = "Connect to a server before using Push To Talk."
                return
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000)
                let result = await requestMicrophoneAccessIfNeeded()
                guard result.granted else {
                    self.lastError = result.failureMessage ?? "Microphone access is required for Push To Talk."
                    self.isTalking = false
                    self.microphonePermissionPrompt = .openSettings
                    return
                }

                self.beginTalking(with: client)
            }
        case .openSettings:
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                TS3PlatformSupport.openMicrophoneSettings()
            }
        }
    }

    func dismissMicrophonePermissionPrompt() {
        appendAudioPermissionLog("prompt", status: "dismissed")
        microphonePermissionPrompt = nil
    }

    private func message(for error: Error) -> String {
        if let error = error as? TS3Error {
            switch error {
            case .invalidState:
                return "Connect to the server before starting microphone capture."
            case .notImplemented:
                return "Microphone capture is not available on this device."
            default:
                return error.localizedDescription
            }
        }

        return error.localizedDescription
    }

    private func beginTalking(with client: TS3Client) {
        Task {
            do {
                try client.startMicrophone()
                await MainActor.run {
                    self.lastError = nil
                    self.isTalking = true
                }
            } catch {
                await MainActor.run {
                    self.lastError = message(for: error)
                    self.isTalking = false
                }
            }
        }
    }

    private func currentMicrophonePermissionState() -> MicrophonePermissionState {
        #if targetEnvironment(macCatalyst)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            appendAudioPermissionLog("AVCaptureDevice current", status: "authorized")
            return .granted
        case .denied, .restricted:
            appendAudioPermissionLog("AVCaptureDevice current", status: "denied/restricted")
            return .denied
        case .notDetermined:
            appendAudioPermissionLog("AVCaptureDevice current", status: "notDetermined")
            break
        @unknown default:
            appendAudioPermissionLog("AVCaptureDevice current", status: "unknown")
            return .denied
        }

        if #available(iOS 17.0, macOS 14.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                appendAudioPermissionLog("AVAudioApplication current", status: "granted")
                return .granted
            case .denied:
                appendAudioPermissionLog("AVAudioApplication current", status: "denied")
                return .denied
            case .undetermined:
                appendAudioPermissionLog("AVAudioApplication current", status: "undetermined")
                return .notDetermined
            @unknown default:
                appendAudioPermissionLog("AVAudioApplication current", status: "unknown")
                return .denied
            }
        }

        return .notDetermined
        #elseif os(iOS)
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            appendAudioPermissionLog("AVAudioSession current", status: "granted")
            return .granted
        case .undetermined:
            appendAudioPermissionLog("AVAudioSession current", status: "undetermined")
            return .notDetermined
        case .denied:
            appendAudioPermissionLog("AVAudioSession current", status: "denied")
            return .denied
        @unknown default:
            appendAudioPermissionLog("AVAudioSession current", status: "unknown")
            return .denied
        }
        #elseif os(macOS)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            appendAudioPermissionLog("AVCaptureDevice current", status: "authorized")
            return .granted
        case .notDetermined:
            appendAudioPermissionLog("AVCaptureDevice current", status: "notDetermined")
            return .notDetermined
        case .denied, .restricted:
            appendAudioPermissionLog("AVCaptureDevice current", status: "denied/restricted")
            return .denied
        @unknown default:
            appendAudioPermissionLog("AVCaptureDevice current", status: "unknown")
            return .denied
        }
        #else
        return .granted
        #endif
    }

    @MainActor
    private func requestMicrophoneAccessIfNeeded() async -> MicrophoneAccessResult {
        #if targetEnvironment(macCatalyst)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            appendAudioPermissionLog("AVCaptureDevice", status: "authorized")
            return .granted
        case .denied, .restricted:
            appendAudioPermissionLog("AVCaptureDevice", status: "denied/restricted")
            return .denied
        case .notDetermined:
            appendAudioPermissionLog("AVCaptureDevice", status: "requesting")
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
            appendAudioPermissionLog("AVCaptureDevice request", status: granted ? "granted" : "denied")
            if granted {
                return .granted
            }
        @unknown default:
            appendAudioPermissionLog("AVCaptureDevice", status: "unknown")
            return .denied
        }

        if #available(iOS 17.0, macOS 14.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                appendAudioPermissionLog("AVAudioApplication", status: "granted")
                return .granted
            case .denied:
                appendAudioPermissionLog("AVAudioApplication", status: "denied")
                return .denied
            case .undetermined:
                appendAudioPermissionLog("AVAudioApplication", status: "requesting")
                let granted = await withCheckedContinuation { continuation in
                    AVAudioApplication.requestRecordPermission { granted in
                        continuation.resume(returning: granted)
                    }
                }
                appendAudioPermissionLog("AVAudioApplication request", status: granted ? "granted" : "denied")
                return granted ? .granted : .denied
            @unknown default:
                appendAudioPermissionLog("AVAudioApplication", status: "unknown")
                return .denied
            }
        }

        return .denied
        #elseif os(iOS)
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            appendAudioPermissionLog("AVAudioSession", status: "granted")
            return .granted
        case .denied:
            appendAudioPermissionLog("AVAudioSession", status: "denied")
            return .denied
        case .undetermined:
            appendAudioPermissionLog("AVAudioSession", status: "undetermined")
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted ? .granted : .denied)
                }
            }
        @unknown default:
            appendAudioPermissionLog("AVAudioSession", status: "unknown")
            return .denied
        }
        #elseif os(macOS)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            appendAudioPermissionLog("AVCaptureDevice", status: "authorized")
            return .granted
        case .denied, .restricted:
            appendAudioPermissionLog("AVCaptureDevice", status: "denied/restricted")
            return .denied
        case .notDetermined:
            appendAudioPermissionLog("AVCaptureDevice", status: "notDetermined")
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted ? .granted : .denied)
                }
            }
        @unknown default:
            appendAudioPermissionLog("AVCaptureDevice", status: "unknown")
            return .denied
        }
        #else
        return .granted
        #endif
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

    private func appendAudioPermissionLog(_ source: String, status: String) {
        appendLog(
            TS3LogEntry(
                timestamp: Date(),
                level: .debug,
                message: "[AUDIO] microphone permission via \(source): \(status)"
            )
        )
    }
}

private struct MicrophoneAccessResult {
    let granted: Bool
    let failureMessage: String?

    static let granted = MicrophoneAccessResult(granted: true, failureMessage: nil)
    static let denied = MicrophoneAccessResult(
        granted: false,
        failureMessage: "Microphone access is denied. Enable it in System Settings > Privacy & Security > Microphone."
    )
}

private enum MicrophonePermissionState {
    case granted
    case notDetermined
    case denied
}

extension TS3AppModel: TS3ClientDelegate {
    nonisolated func ts3ClientDidConnect(_ client: TS3Client) {
        Task { @MainActor in
            self.state = .connected
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didDisconnectWith error: Error?) {
        Task { @MainActor in
            if let error {
                self.lastError = error.localizedDescription
            }
            self.isTalking = false
            self.state = .disconnected
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateChannels channels: [TS3Channel]) {
        Task { @MainActor in
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

    nonisolated func ts3Client(_ client: TS3Client, didUpdateClients clients: [TS3ServerClient]) {
        Task { @MainActor in
            self.clients = clients.map { client in
                TS3UserSummary(
                    id: client.id,
                    channelId: client.channelId,
                    nickname: client.nickname,
                    isCurrentUser: client.isCurrentUser
                )
            }
        }
    }
}
