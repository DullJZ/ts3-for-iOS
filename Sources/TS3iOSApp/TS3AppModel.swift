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
    let parentId: Int?
    var name: String
    var topic: String?
    var description: String?
    var isDefault: Bool
    var isPasswordProtected: Bool
    var isPermanent: Bool
    var neededTalkPower: Int?
    var isCurrent: Bool
}

struct TS3UserSummary: Identifiable {
    let id: Int
    let channelId: Int
    let databaseId: Int?
    let uniqueIdentifier: String?
    let nickname: String
    let isCurrentUser: Bool
    let isInputMuted: Bool
    let isOutputMuted: Bool
    let isAway: Bool
    let awayMessage: String?
    let talkPower: Int?
    let channelGroupId: Int?
    let serverGroups: [Int]
}

struct TS3ChatMessageSummary: Identifiable {
    let id: UUID
    let timestamp: Date
    let targetMode: TS3TextMessageTargetMode
    let targetId: Int?
    let senderName: String
    let message: String
    let isOwnMessage: Bool
}

struct TS3OfflineMessageSummary: Identifiable {
    let id: Int
    let senderUniqueIdentifier: String?
    let senderName: String?
    let subject: String
    let message: String?
    let timestamp: Date?
    let isRead: Bool
}

extension TS3OfflineMessageSummary {
    init(message: TS3OfflineMessage, isReadOverride: Bool? = nil) {
        self.id = message.id
        self.senderUniqueIdentifier = message.senderUniqueIdentifier
        self.senderName = message.senderName
        self.subject = message.subject
        self.message = message.message
        self.timestamp = message.timestamp
        self.isRead = isReadOverride ?? message.isRead
    }

    init(copying message: TS3OfflineMessageSummary, isRead: Bool) {
        self.id = message.id
        self.senderUniqueIdentifier = message.senderUniqueIdentifier
        self.senderName = message.senderName
        self.subject = message.subject
        self.message = message.message
        self.timestamp = message.timestamp
        self.isRead = isRead
    }
}

struct TS3BanEntrySummary: Identifiable {
    let id: Int
    let ip: String?
    let name: String?
    let uniqueIdentifier: String?
    let lastNickname: String?
    let createdAt: Date?
    let durationSeconds: Int?
    let invokerName: String?
    let reason: String?
    let enforcements: Int?
}

extension TS3BanEntrySummary {
    init(entry: TS3BanEntry) {
        self.id = entry.id
        self.ip = entry.ip
        self.name = entry.name
        self.uniqueIdentifier = entry.uniqueIdentifier
        self.lastNickname = entry.lastNickname
        self.createdAt = entry.createdAt
        self.durationSeconds = entry.durationSeconds
        self.invokerName = entry.invokerName
        self.reason = entry.reason
        self.enforcements = entry.enforcements
    }
}

struct TS3GroupSummary: Identifiable {
    let id: Int
    let name: String
}

struct TS3BookmarkSummary: Identifiable, Codable {
    let id: UUID
    var name: String
    var host: String
    var port: String
    var nickname: String
    var serverPassword: String
    var defaultChannel: String
    var defaultChannelPassword: String

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: String,
        nickname: String,
        serverPassword: String,
        defaultChannel: String,
        defaultChannelPassword: String
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
    }
}

struct TS3IdentitySummary {
    var uid: String
    var securityLevel: Int
    var keyOffset: Int
    var exportString: String

    static let empty = TS3IdentitySummary(uid: "", securityLevel: 0, keyOffset: 0, exportString: "")
}

struct TS3ServerInfoSummary {
    var name: String
    var uniqueIdentifier: String?
    var platform: String?
    var version: String?
    var clientsOnline: Int?
    var maxClients: Int?
    var channelsOnline: Int?
    var uptimeSeconds: Int?
    var welcomeMessage: String?

    static let empty = TS3ServerInfoSummary(
        name: "",
        uniqueIdentifier: nil,
        platform: nil,
        version: nil,
        clientsOnline: nil,
        maxClients: nil,
        channelsOnline: nil,
        uptimeSeconds: nil,
        welcomeMessage: nil
    )
}

enum TS3WhisperRoute: Equatable {
    case none
    case server
    case channel(Int)
    case client(Int)
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
    @Published var chatMessages: [TS3ChatMessageSummary] = []
    @Published var offlineMessages: [TS3OfflineMessageSummary] = []
    @Published var banEntries: [TS3BanEntrySummary] = []
    @Published var serverGroups: [TS3GroupSummary] = []
    @Published var channelGroups: [TS3GroupSummary] = []
    @Published var bookmarks: [TS3BookmarkSummary] = []
    @Published var identitySummary: TS3IdentitySummary = .empty
    @Published var serverInfo: TS3ServerInfoSummary = .empty
    @Published var isTalking = false
    @Published var isAway = false
    @Published var isInputMuted = false
    @Published var isOutputMuted = false
    @Published var whisperRoute: TS3WhisperRoute = .none
    @Published var logs: [TS3LogEntry] = []
    @Published var isShowingDebug = false
    @Published var lastError: String?
    @Published var playbackVolume: Double = 1.0
    @Published var microphonePermissionPrompt: MicrophonePermissionPrompt?

    @Published var serverHost = ""
    @Published var serverPort = "9987"
    @Published var serverPassword = ""
    @Published var defaultChannel = ""
    @Published var defaultChannelPassword = ""
    @Published var privilegeKey = ""
    @Published var nickname = TS3PlatformSupport.defaultNickname
    @Published var awayMessage = ""

    private var client: TS3Client?

    init() {
        loadBookmarks()
        Task { @MainActor in
            await refreshIdentitySummary()
        }
    }

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
            channels.append(TS3ChannelSummary(
                id: id,
                parentId: nil,
                name: name,
                topic: topic,
                description: nil,
                isDefault: false,
                isPasswordProtected: false,
                isPermanent: false,
                neededTalkPower: nil,
                isCurrent: true
            ))
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
            serverPassword: serverPassword.isEmpty ? nil : serverPassword,
            defaultChannel: defaultChannel.isEmpty ? nil : defaultChannel,
            defaultChannelPassword: defaultChannelPassword.isEmpty ? nil : defaultChannelPassword,
            privilegeKey: privilegeKey.isEmpty ? nil : privilegeKey
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

    func applyBookmark(_ bookmark: TS3BookmarkSummary) {
        serverHost = bookmark.host
        serverPort = bookmark.port
        nickname = bookmark.nickname
        serverPassword = bookmark.serverPassword
        defaultChannel = bookmark.defaultChannel
        defaultChannelPassword = bookmark.defaultChannelPassword
    }

    func saveCurrentBookmark(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedName.isEmpty ? serverHost : trimmedName
        guard !serverHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let bookmark = TS3BookmarkSummary(
            name: title,
            host: serverHost,
            port: serverPort,
            nickname: nickname,
            serverPassword: serverPassword,
            defaultChannel: defaultChannel,
            defaultChannelPassword: defaultChannelPassword
        )
        bookmarks.removeAll { $0.host == bookmark.host && $0.port == bookmark.port }
        bookmarks.insert(bookmark, at: 0)
        saveBookmarks()
    }

    func deleteBookmark(_ bookmark: TS3BookmarkSummary) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }

    func disconnect() {
        client?.delegate = nil
        client?.disconnect(reason: "ui-disconnect")
        client = nil
        state = .disconnected
        channels = []
        clients = []
        chatMessages = []
        offlineMessages = []
        banEntries = []
        serverGroups = []
        channelGroups = []
        serverInfo = .empty
        isTalking = false
        isAway = false
        isInputMuted = false
        isOutputMuted = false
        whisperRoute = .none
        microphonePermissionPrompt = nil
    }

    func updatePlaybackVolume(_ volume: Double) {
        let clamped = min(max(volume, 0), 4)
        playbackVolume = clamped
        client?.setPlaybackVolume(Float(clamped))
    }

    func refreshServerView() {
        runClientCommand { client in
            try await client.refreshServerView()
        }
    }

    func refreshGroups() {
        runClientCommand { client in
            try await client.refreshGroups()
        }
    }

    func refreshServerInfo() {
        runClientCommand { client in
            try await client.refreshServerInfo()
        }
    }

    func refreshBanList() {
        runClientCommand { client in
            let entries = try await client.refreshBanList()
            await MainActor.run {
                self.banEntries = entries.map { TS3BanEntrySummary(entry: $0) }
            }
        }
    }

    func refreshUserDetails(_ user: TS3UserSummary) {
        runClientCommand { client in
            _ = try await client.refreshClientDetails(clientId: user.id)
        }
    }

    func joinChannel(_ channel: TS3ChannelSummary, password: String? = nil) {
        Task {
            do {
                try await client?.joinChannel(channelId: channel.id, password: password)
                setCurrentChannel(id: channel.id, name: channel.name, topic: channel.topic)
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func sendChannelMessage(_ text: String) {
        guard let currentChannel else { return }
        sendMessage(text, targetMode: .channel, targetId: currentChannel.id)
    }

    func sendServerMessage(_ text: String) {
        sendMessage(text, targetMode: .server, targetId: 0)
    }

    func sendPrivateMessage(_ text: String, to user: TS3UserSummary) {
        sendMessage(text, targetMode: .client, targetId: user.id)
    }

    func refreshOfflineMessages() {
        runClientCommand { client in
            let messages = try await client.refreshOfflineMessages()
            await MainActor.run {
                self.offlineMessages = messages.map { TS3OfflineMessageSummary(message: $0) }
            }
        }
    }

    func openOfflineMessage(_ message: TS3OfflineMessageSummary) {
        runClientCommand { client in
            guard let detailed = try await client.offlineMessage(messageId: message.id) else { return }
            try? await client.setOfflineMessageRead(messageId: message.id, isRead: true)
            await MainActor.run {
                self.upsertOfflineMessage(TS3OfflineMessageSummary(message: detailed, isReadOverride: true))
            }
        }
    }

    func deleteOfflineMessage(_ message: TS3OfflineMessageSummary) {
        runClientCommand { client in
            try await client.deleteOfflineMessage(messageId: message.id)
            await MainActor.run {
                self.offlineMessages.removeAll { $0.id == message.id }
            }
        }
    }

    func markOfflineMessage(_ message: TS3OfflineMessageSummary, read: Bool) {
        runClientCommand { client in
            try await client.setOfflineMessageRead(messageId: message.id, isRead: read)
            await MainActor.run {
                self.upsertOfflineMessage(TS3OfflineMessageSummary(copying: message, isRead: read))
            }
        }
    }

    func sendOfflineMessage(to user: TS3UserSummary, subject: String, message: String) {
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subject.isEmpty, !message.isEmpty else { return }
        runClientCommand { client in
            let details = try await client.refreshClientDetails(clientId: user.id)
            guard let uniqueIdentifier = details?.uniqueIdentifier ?? user.uniqueIdentifier else {
                throw TS3Error.serverError(message: "The server did not provide a unique id for \(user.nickname).")
            }
            try await client.sendOfflineMessage(toUniqueIdentifier: uniqueIdentifier, subject: subject, message: message)
        }
    }

    private func upsertOfflineMessage(_ message: TS3OfflineMessageSummary) {
        if let index = offlineMessages.firstIndex(where: { $0.id == message.id }) {
            offlineMessages[index] = message
        } else {
            offlineMessages.insert(message, at: 0)
        }
    }

    private func sendMessage(_ text: String, targetMode: TS3TextMessageTargetMode, targetId: Int) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        runClientCommand { client in
            try await client.sendTextMessage(trimmed, targetMode: targetMode, targetId: targetId)
        }
    }

    func updateNickname(to value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        runClientCommand { client in
            try await client.updateNickname(trimmed)
        } onSuccess: {
            self.nickname = trimmed
        }
    }

    func toggleAway() {
        let newValue = !isAway
        let message = awayMessage
        runClientCommand { client in
            try await client.setAway(newValue, message: message.isEmpty ? nil : message)
        } onSuccess: {
            self.isAway = newValue
        }
    }

    func toggleInputMuted() {
        let newValue = !isInputMuted
        runClientCommand { client in
            try await client.setInputMuted(newValue)
        } onSuccess: {
            self.isInputMuted = newValue
            if newValue, self.isTalking {
                self.client?.stopMicrophone()
                self.isTalking = false
            }
        }
    }

    func toggleOutputMuted() {
        let newValue = !isOutputMuted
        runClientCommand { client in
            try await client.setOutputMuted(newValue)
        } onSuccess: {
            self.isOutputMuted = newValue
        }
    }

    func createChannel(name: String, parentId: Int?, password: String?, permanent: Bool) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        runClientCommand { client in
            _ = try await client.createChannel(
                name: trimmed,
                parentId: parentId,
                password: password?.isEmpty == true ? nil : password,
                permanent: permanent
            )
        }
    }

    func editChannel(_ channel: TS3ChannelSummary, name: String, topic: String, description: String, password: String?) {
        runClientCommand { client in
            try await client.editChannel(
                channelId: channel.id,
                name: name.isEmpty ? nil : name,
                topic: topic.isEmpty ? nil : topic,
                description: description.isEmpty ? nil : description,
                password: password?.isEmpty == true ? nil : password
            )
        }
    }

    func deleteChannel(_ channel: TS3ChannelSummary) {
        runClientCommand { client in
            try await client.deleteChannel(channelId: channel.id, force: true)
        }
    }

    func moveUser(_ user: TS3UserSummary, to channel: TS3ChannelSummary, password: String? = nil) {
        runClientCommand { client in
            try await client.moveClient(clientId: user.id, to: channel.id, password: password)
        }
    }

    func kickUserFromChannel(_ user: TS3UserSummary, message: String?) {
        runClientCommand { client in
            try await client.kickClient(clientId: user.id, reason: .channel, message: message)
        }
    }

    func kickUserFromServer(_ user: TS3UserSummary, message: String?) {
        runClientCommand { client in
            try await client.kickClient(clientId: user.id, reason: .server, message: message)
        }
    }

    func banUser(_ user: TS3UserSummary, message: String?) {
        runClientCommand { client in
            try await client.banClient(clientId: user.id, durationSeconds: nil, message: message)
            let entries = try await client.refreshBanList()
            await MainActor.run {
                self.banEntries = entries.map { TS3BanEntrySummary(entry: $0) }
            }
        }
    }

    func deleteBan(_ entry: TS3BanEntrySummary) {
        runClientCommand { client in
            try await client.deleteBan(banId: entry.id)
            await MainActor.run {
                self.banEntries.removeAll { $0.id == entry.id }
            }
        }
    }

    func deleteAllBans() {
        runClientCommand { client in
            try await client.deleteAllBans()
            await MainActor.run {
                self.banEntries = []
            }
        }
    }

    func pokeUser(_ user: TS3UserSummary, message: String) {
        runClientCommand { client in
            try await client.pokeClient(clientId: user.id, message: message.isEmpty ? "Poke" : message)
        }
    }

    func usePrivilegeKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        runClientCommand { client in
            try await client.usePrivilegeKey(trimmed)
        }
    }

    func addServerGroup(_ group: TS3GroupSummary, to user: TS3UserSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.addServerGroup(groupId: group.id, toClientDatabaseId: databaseId)
        }
    }

    func removeServerGroup(_ group: TS3GroupSummary, from user: TS3UserSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.removeServerGroup(groupId: group.id, fromClientDatabaseId: databaseId)
        }
    }

    func setChannelGroup(_ group: TS3GroupSummary, for user: TS3UserSummary, in channel: TS3ChannelSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.setChannelGroup(groupId: group.id, channelId: channel.id, clientDatabaseId: databaseId)
        }
    }

    func refreshIdentitySummary() async {
        do {
            let snapshot = try await TS3Client(config: TS3ClientConfig(
                host: "localhost",
                port: 9987,
                nickname: nickname,
                serverPassword: nil
            )).identitySnapshot()
            identitySummary = TS3IdentitySummary(
                uid: snapshot.uid,
                securityLevel: snapshot.securityLevel,
                keyOffset: snapshot.keyOffset,
                exportString: snapshot.exportString
            )
        } catch {
            lastError = error.localizedDescription
        }
    }

    func copyIdentityExport() {
        TS3PlatformSupport.copyToPasteboard(identitySummary.exportString)
    }

    func importIdentity(_ exportString: String) {
        Task {
            do {
                let snapshot = try await TS3Client(config: TS3ClientConfig(
                    host: "localhost",
                    port: 9987,
                    nickname: nickname,
                    serverPassword: nil
                )).importIdentity(exportString: exportString)
                await MainActor.run {
                    self.identitySummary = TS3IdentitySummary(
                        uid: snapshot.uid,
                        securityLevel: snapshot.securityLevel,
                        keyOffset: snapshot.keyOffset,
                        exportString: snapshot.exportString
                    )
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    private func runClientCommand(
        _ operation: @escaping (TS3Client) async throws -> Void,
        onSuccess: @escaping @MainActor () -> Void = {}
    ) {
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        Task {
            do {
                try await operation(client)
                await MainActor.run {
                    self.lastError = nil
                    onSuccess()
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    private func databaseId(for user: TS3UserSummary, using client: TS3Client) async throws -> Int {
        if let databaseId = user.databaseId {
            return databaseId
        }
        if let refreshed = try await client.refreshClientDetails(clientId: user.id)?.databaseId {
            return refreshed
        }
        throw TS3Error.serverError(message: "The server did not provide a database id for \(user.nickname).")
    }

    private var bookmarksURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-bookmarks.json")
    }

    private func loadBookmarks() {
        guard let data = try? Data(contentsOf: bookmarksURL),
              let decoded = try? JSONDecoder().decode([TS3BookmarkSummary].self, from: data) else {
            bookmarks = []
            return
        }
        bookmarks = decoded
    }

    private func saveBookmarks() {
        do {
            let directory = bookmarksURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(bookmarks)
            try data.write(to: bookmarksURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func toggleTalking() {
        guard !isInputMuted else {
            lastError = "Clear microphone mute before using Push To Talk."
            return
        }

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

    func enableWhisperToCurrentChannel() {
        guard let channel = currentChannel else {
            lastError = "Join a channel before enabling whisper to current channel."
            return
        }
        whisperRoute = .channel(channel.id)
        client?.startWhisperToChannel(channel.id)
    }

    func enableWhisperToClient(_ user: TS3UserSummary) {
        whisperRoute = .client(user.id)
        client?.startWhisperToClient(user.id)
    }

    func enableWhisperToServer() {
        whisperRoute = .server
        client?.startWhisperToServer()
    }

    func disableWhisper() {
        whisperRoute = .none
        client?.stopWhisper()
    }

    func enableWhisperToChannel(id: Int) {
        whisperRoute = .channel(id)
        client?.startWhisperToChannel(id)
    }

    var whisperRouteDescription: String {
        switch whisperRoute {
        case .none:
            return "Voice to current channel"
        case .server:
            return "Whisper to server"
        case let .channel(channelId):
            let channel = channels.first { $0.id == channelId }?.name ?? "Channel \(channelId)"
            return "Whisper to \(channel)"
        case let .client(clientId):
            let user = clients.first { $0.id == clientId }?.nickname ?? "Client \(clientId)"
            return "Whisper to \(user)"
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
            case .audioInputUnavailable:
                return "No usable microphone input device is available. Check microphone permission and the current system input device."
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
        #if targetEnvironment(macCatalyst) || os(iOS)
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
        #if targetEnvironment(macCatalyst) || os(iOS)
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
                    parentId: channel.parentId,
                    name: channel.name,
                    topic: channel.topic,
                    description: channel.description,
                    isDefault: channel.isDefault,
                    isPasswordProtected: channel.isPasswordProtected,
                    isPermanent: channel.isPermanent,
                    neededTalkPower: channel.neededTalkPower,
                    isCurrent: channel.id == client.currentChannelId
                )
            }
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateServerInfo info: TS3ServerInfo) {
        Task { @MainActor in
            self.serverInfo = TS3ServerInfoSummary(
                name: info.name,
                uniqueIdentifier: info.uniqueIdentifier,
                platform: info.platform,
                version: info.version,
                clientsOnline: info.clientsOnline,
                maxClients: info.maxClients,
                channelsOnline: info.channelsOnline,
                uptimeSeconds: info.uptimeSeconds,
                welcomeMessage: info.welcomeMessage
            )
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateClients clients: [TS3ServerClient]) {
        Task { @MainActor in
            self.clients = clients.map { client in
                TS3UserSummary(
                    id: client.id,
                    channelId: client.channelId,
                    databaseId: client.databaseId,
                    uniqueIdentifier: client.uniqueIdentifier,
                    nickname: client.nickname,
                    isCurrentUser: client.isCurrentUser,
                    isInputMuted: client.isInputMuted,
                    isOutputMuted: client.isOutputMuted,
                    isAway: client.isAway,
                    awayMessage: client.awayMessage,
                    talkPower: client.talkPower,
                    channelGroupId: client.channelGroupId,
                    serverGroups: client.serverGroups
                )
            }
            if let ownClient = clients.first(where: { $0.isCurrentUser }) {
                self.isInputMuted = ownClient.isInputMuted
                self.isOutputMuted = ownClient.isOutputMuted
                self.isAway = ownClient.isAway
            }
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didReceiveTextMessage message: TS3TextMessage) {
        Task { @MainActor in
            self.chatMessages.append(TS3ChatMessageSummary(
                id: message.id,
                timestamp: message.timestamp,
                targetMode: message.targetMode,
                targetId: message.targetId,
                senderName: message.senderName,
                message: message.message,
                isOwnMessage: message.isOwnMessage
            ))
            if self.chatMessages.count > 200 {
                self.chatMessages.removeFirst(self.chatMessages.count - 200)
            }
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateServerGroups groups: [TS3ServerGroup]) {
        Task { @MainActor in
            self.serverGroups = groups.map { TS3GroupSummary(id: $0.id, name: $0.name) }
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateChannelGroups groups: [TS3ChannelGroup]) {
        Task { @MainActor in
            self.channelGroups = groups.map { TS3GroupSummary(id: $0.id, name: $0.name) }
        }
    }
}
