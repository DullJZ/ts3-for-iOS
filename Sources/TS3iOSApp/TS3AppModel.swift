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

enum TS3ChannelType: String, CaseIterable, Identifiable {
    case temporary
    case semiPermanent
    case permanent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .temporary:
            return "Temporary"
        case .semiPermanent:
            return "Semi-Permanent"
        case .permanent:
            return "Permanent"
        }
    }
}

struct TS3ChannelSummary: Identifiable {
    let id: Int
    let parentId: Int?
    let order: Int?
    var name: String
    var phoneticName: String?
    var topic: String?
    var description: String?
    var isDefault: Bool
    var isPasswordProtected: Bool
    var isPermanent: Bool
    var isSemiPermanent: Bool?
    var neededTalkPower: Int?
    var neededSubscribePower: Int?
    var codec: Int?
    var codecQuality: Int?
    var deleteDelaySeconds: Int?
    var maxClients: Int?
    var maxFamilyClients: Int?
    var maxClientsUnlimited: Bool?
    var maxFamilyClientsUnlimited: Bool?
    var maxFamilyClientsInherited: Bool?
    var iconId: Int?
    var iconURL: URL?
    var isSubscribed: Bool?
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
    let isChannelCommander: Bool
    let isPrioritySpeaker: Bool
    let isTalker: Bool
    let isRequestingTalkPower: Bool
    let talkRequestMessage: String?
    let talkPower: Int?
    let channelGroupId: Int?
    let serverGroups: [Int]
    let description: String?
    let avatarHash: String?
    let avatarURL: URL?
    let iconId: Int?
    let iconURL: URL?
    let version: String?
    let platform: String?
    let country: String?
    let ipAddress: String?
    let createdAt: Date?
    let lastConnectedAt: Date?
    let totalConnections: Int?
    let idleTimeSeconds: Int?
    let connectedSeconds: Int?
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

struct TS3ComplaintSummary: Identifiable {
    let id: String
    let targetClientDatabaseId: Int
    let targetName: String?
    let sourceClientDatabaseId: Int
    let sourceName: String?
    let message: String?
    let timestamp: Date?

    init(entry: TS3ComplaintEntry) {
        self.id = entry.id
        self.targetClientDatabaseId = entry.targetClientDatabaseId
        self.targetName = entry.targetName
        self.sourceClientDatabaseId = entry.sourceClientDatabaseId
        self.sourceName = entry.sourceName
        self.message = entry.message
        self.timestamp = entry.timestamp
    }
}

struct TS3DatabaseClientSummary: Identifiable {
    let id: Int
    let uniqueIdentifier: String?
    let nickname: String
    let createdAt: Date?
    let lastConnectedAt: Date?
    let totalConnections: Int?
    let description: String?
    let lastIP: String?

    init(client: TS3DatabaseClient) {
        self.id = client.id
        self.uniqueIdentifier = client.uniqueIdentifier
        self.nickname = client.nickname
        self.createdAt = client.createdAt
        self.lastConnectedAt = client.lastConnectedAt
        self.totalConnections = client.totalConnections
        self.description = client.description
        self.lastIP = client.lastIP
    }

    func copy(description: String?) -> TS3DatabaseClientSummary {
        TS3DatabaseClientSummary(
            id: id,
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            createdAt: createdAt,
            lastConnectedAt: lastConnectedAt,
            totalConnections: totalConnections,
            description: description,
            lastIP: lastIP
        )
    }

    private init(
        id: Int,
        uniqueIdentifier: String?,
        nickname: String,
        createdAt: Date?,
        lastConnectedAt: Date?,
        totalConnections: Int?,
        description: String?,
        lastIP: String?
    ) {
        self.id = id
        self.uniqueIdentifier = uniqueIdentifier
        self.nickname = nickname
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
        self.totalConnections = totalConnections
        self.description = description
        self.lastIP = lastIP
    }
}

struct TS3ClientLocationSummary: Identifiable {
    let id: Int
    let clientId: Int
    let nickname: String?

    init(location: TS3ClientLocation) {
        self.id = location.id
        self.clientId = location.clientId
        self.nickname = location.nickname
    }
}

struct TS3GroupSummary: Identifiable {
    let id: Int
    let name: String
    let type: TS3PermissionGroupDatabaseType?
}

extension TS3GroupSummary {
    static func name(for id: Int, in groups: [TS3GroupSummary]) -> String {
        groups.first { $0.id == id }?.name ?? "Group \(id)"
    }

    var typeTitle: String {
        switch type {
        case .template:
            return "Template"
        case .regular:
            return "Regular"
        case .query:
            return "Query"
        case nil:
            return "Unknown"
        }
    }
}

struct TS3PermissionInfoSummary: Identifiable {
    let id: Int
    let name: String
    let description: String?

    init(info: TS3PermissionInfo) {
        self.id = info.id
        self.name = info.name
        self.description = info.description
    }
}

struct TS3PermissionSummary: Identifiable {
    let id: String
    let name: String
    let value: Int
    let isNegated: Bool
    let isSkipped: Bool

    init(permission: TS3Permission) {
        self.id = permission.id
        self.name = permission.name
        self.value = permission.value
        self.isNegated = permission.isNegated
        self.isSkipped = permission.isSkipped
    }
}

enum TS3PrivilegeKeyTargetType: String, CaseIterable, Identifiable {
    case serverGroup
    case channelGroup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .serverGroup: return "Server Group"
        case .channelGroup: return "Channel Group"
        }
    }

    var kitType: TS3PrivilegeKeyType {
        switch self {
        case .serverGroup: return .serverGroup
        case .channelGroup: return .channelGroup
        }
    }
}

struct TS3PrivilegeKeySummary: Identifiable {
    let id: String
    let key: String
    let type: TS3PrivilegeKeyType?
    let groupId: Int
    let channelId: Int?
    let createdAt: Date?
    let description: String?
    let customSet: String?

    init(entry: TS3PrivilegeKeyEntry) {
        self.id = entry.id
        self.key = entry.key
        self.type = entry.type
        self.groupId = entry.groupId
        self.channelId = entry.channelId
        self.createdAt = entry.createdAt
        self.description = entry.description
        self.customSet = entry.customSet
    }
}

enum TS3PermissionEditScope: String, CaseIterable, Identifiable {
    case ownClient
    case serverGroup
    case channelGroup
    case channel
    case channelClient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ownClient:
            return "Current Client"
        case .serverGroup:
            return "Server Group"
        case .channelGroup:
            return "Channel Group"
        case .channel:
            return "Channel"
        case .channelClient:
            return "Channel Client"
        }
    }
}

struct TS3FileEntrySummary: Identifiable {
    let id: String
    let channelId: Int
    let path: String
    let parentPath: String
    let name: String
    let size: Int64
    let modifiedAt: Date?
    let isDirectory: Bool
    let isStillUploading: Bool

    init(entry: TS3FileEntry) {
        self.id = entry.id
        self.channelId = entry.channelId
        self.path = entry.path
        self.parentPath = entry.parentPath
        self.name = entry.name
        self.size = entry.size
        self.modifiedAt = entry.modifiedAt
        self.isDirectory = entry.isDirectory
        self.isStillUploading = entry.isStillUploading
    }
}

struct TS3DownloadedFileSummary: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
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
    var privilegeKey: String

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: String,
        nickname: String,
        serverPassword: String,
        defaultChannel: String,
        defaultChannelPassword: String,
        privilegeKey: String
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case host
        case port
        case nickname
        case serverPassword
        case defaultChannel
        case defaultChannelPassword
        case privilegeKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(String.self, forKey: .port)
        nickname = try container.decode(String.self, forKey: .nickname)
        serverPassword = try container.decode(String.self, forKey: .serverPassword)
        defaultChannel = try container.decode(String.self, forKey: .defaultChannel)
        defaultChannelPassword = try container.decode(String.self, forKey: .defaultChannelPassword)
        privilegeKey = try container.decodeIfPresent(String.self, forKey: .privilegeKey) ?? ""
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
    var createdAt: Date?
    var clientsOnline: Int?
    var maxClients: Int?
    var clientsInQuery: Int?
    var reservedSlots: Int?
    var channelsOnline: Int?
    var uptimeSeconds: Int?
    var welcomeMessage: String?
    var passwordProtected: Bool
    var status: String?
    var machineId: String?
    var codecEncryptionMode: Int?
    var defaultServerGroupId: Int?
    var defaultChannelGroupId: Int?
    var defaultChannelAdminGroupId: Int?
    var fileBase: String?
    var fileTransferPort: Int?
    var complainAutoBanCount: Int?
    var complainAutoBanTime: Int?
    var complainRemoveTime: Int?
    var minClientsInChannelBeforeForcedSilence: Int?
    var prioritySpeakerDimmModificator: Double?
    var clientConnections: Int?
    var queryClientConnections: Int?
    var downloadQuota: Int64?
    var uploadQuota: Int64?
    var monthlyBytesDownloaded: Int64?
    var monthlyBytesUploaded: Int64?
    var totalBytesDownloaded: Int64?
    var totalBytesUploaded: Int64?
    var totalPacketLossSpeech: Double?
    var totalPacketLossKeepalive: Double?
    var totalPacketLossControl: Double?
    var totalPacketLossTotal: Double?
    var totalPing: Double?
    var hostMessage: String?
    var hostMessageMode: Int?
    var hostBannerURL: String?
    var hostBannerGraphicsURL: String?
    var hostButtonTooltip: String?
    var hostButtonURL: String?
    var hostButtonGraphicsURL: String?
    var iconId: Int?
    var iconURL: URL?

    static let empty = TS3ServerInfoSummary(
        name: "",
        uniqueIdentifier: nil,
        platform: nil,
        version: nil,
        createdAt: nil,
        clientsOnline: nil,
        maxClients: nil,
        clientsInQuery: nil,
        reservedSlots: nil,
        channelsOnline: nil,
        uptimeSeconds: nil,
        welcomeMessage: nil,
        passwordProtected: false,
        status: nil,
        machineId: nil,
        codecEncryptionMode: nil,
        defaultServerGroupId: nil,
        defaultChannelGroupId: nil,
        defaultChannelAdminGroupId: nil,
        fileBase: nil,
        fileTransferPort: nil,
        complainAutoBanCount: nil,
        complainAutoBanTime: nil,
        complainRemoveTime: nil,
        minClientsInChannelBeforeForcedSilence: nil,
        prioritySpeakerDimmModificator: nil,
        clientConnections: nil,
        queryClientConnections: nil,
        downloadQuota: nil,
        uploadQuota: nil,
        monthlyBytesDownloaded: nil,
        monthlyBytesUploaded: nil,
        totalBytesDownloaded: nil,
        totalBytesUploaded: nil,
        totalPacketLossSpeech: nil,
        totalPacketLossKeepalive: nil,
        totalPacketLossControl: nil,
        totalPacketLossTotal: nil,
        totalPing: nil,
        hostMessage: nil,
        hostMessageMode: nil,
        hostBannerURL: nil,
        hostBannerGraphicsURL: nil,
        hostButtonTooltip: nil,
        hostButtonURL: nil,
        hostButtonGraphicsURL: nil,
        iconId: nil,
        iconURL: nil
    )
}

struct TS3ServerLogSummary: Identifiable {
    let id: Int
    let timestamp: Date?
    let level: String?
    let channel: String?
    let message: String
    let rawLine: String

    init(entry: TS3ServerLogEntry) {
        self.id = entry.id
        self.timestamp = entry.timestamp
        self.level = entry.level
        self.channel = entry.channel
        self.message = entry.message
        self.rawLine = entry.rawLine
    }
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
    @Published var complaintEntries: [TS3ComplaintSummary] = []
    @Published var complaintTarget: TS3UserSummary?
    @Published var databaseClients: [TS3DatabaseClientSummary] = []
    @Published var databaseSearchResults: [TS3DatabaseClientSummary] = []
    @Published var clientLocations: [TS3ClientLocationSummary] = []
    @Published var selectedDatabaseClient: TS3DatabaseClientSummary?
    @Published var serverLogEntries: [TS3ServerLogSummary] = []
    @Published var serverGroups: [TS3GroupSummary] = []
    @Published var channelGroups: [TS3GroupSummary] = []
    @Published var permissionInfos: [TS3PermissionInfoSummary] = []
    @Published var ownClientPermissions: [TS3PermissionSummary] = []
    @Published var ownClientDatabaseId: Int?
    @Published var permissionEditScope: TS3PermissionEditScope = .ownClient
    @Published var selectedServerGroupPermissionId: Int?
    @Published var selectedChannelGroupPermissionId: Int?
    @Published var selectedChannelPermissionId: Int?
    @Published var selectedChannelClientPermissionChannelId: Int?
    @Published var selectedChannelClientPermissionClientId: Int?
    @Published var scopedPermissions: [TS3PermissionSummary] = []
    @Published var privilegeKeys: [TS3PrivilegeKeySummary] = []
    @Published var generatedPrivilegeKey: String?
    @Published var fileEntries: [TS3FileEntrySummary] = []
    @Published var fileBrowserChannelId: Int?
    @Published var fileBrowserPath = "/"
    @Published var fileTransferStatus: String?
    @Published var fileTransferProgress: Double?
    @Published var lastDownloadedFile: TS3DownloadedFileSummary?
    @Published var bookmarks: [TS3BookmarkSummary] = []
    @Published var identitySummary: TS3IdentitySummary = .empty
    @Published var serverInfo: TS3ServerInfoSummary = .empty
    @Published var isTalking = false
    @Published var isAway = false
    @Published var isInputMuted = false
    @Published var isOutputMuted = false
    @Published var isChannelCommander = false
    @Published var isRequestingTalkPower = false
    @Published var talkRequestMessage = ""
    @Published var whisperRoute: TS3WhisperRoute = .none
    @Published var logs: [TS3LogEntry] = []
    @Published var isShowingDebug = false
    @Published var lastError: String?
    @Published var avatarDownloadStatus: String?
    @Published var playbackVolume: Double = 1.0
    @Published var inputGain: Double = 1.0
    @Published var audioTransmitMode: TS3AudioTransmitMode = .pushToTalk
    @Published var voiceActivationThreshold: Double = 0.03
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
    private var iconURLs: [Int: URL] = [:]
    private var iconDownloads: Set<Int> = []
    private var failedIconIds: Set<Int> = []

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
        if isTalking {
            switch audioTransmitMode {
            case .pushToTalk:
                return "Sending microphone audio"
            case .continuous:
                return "Continuous transmission active"
            case .voiceActivation:
                return "Voice activation listening"
            }
        }
        return "Mic idle"
    }

    var playbackVolumePercentText: String {
        "\(Int((playbackVolume * 100).rounded()))%"
    }

    var transmitButtonTitle: String {
        if isTalking {
            return audioTransmitMode == .pushToTalk ? "Stop Talking" : "Stop Transmission"
        }
        switch audioTransmitMode {
        case .pushToTalk:
            return "Push To Talk"
        case .continuous:
            return "Start Continuous"
        case .voiceActivation:
            return "Start Voice Activation"
        }
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
                order: nil,
                name: name,
                phoneticName: nil,
                topic: topic,
                description: nil,
                isDefault: false,
                isPasswordProtected: false,
                isPermanent: false,
                isSemiPermanent: nil,
                neededTalkPower: nil,
                neededSubscribePower: nil,
                codec: nil,
                codecQuality: nil,
                deleteDelaySeconds: nil,
                maxClients: nil,
                maxFamilyClients: nil,
                maxClientsUnlimited: nil,
                maxFamilyClientsUnlimited: nil,
                maxFamilyClientsInherited: nil,
                iconId: nil,
                iconURL: nil,
                isSubscribed: nil,
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
        applyAudioSettings(to: newClient)
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
        privilegeKey = bookmark.privilegeKey
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
            defaultChannelPassword: defaultChannelPassword,
            privilegeKey: privilegeKey
        )
        bookmarks.removeAll { $0.host == bookmark.host && $0.port == bookmark.port }
        bookmarks.insert(bookmark, at: 0)
        saveBookmarks()
    }

    func updateBookmark(_ bookmark: TS3BookmarkSummary) {
        let trimmedName = bookmark.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHost = bookmark.host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedHost.isEmpty else { return }
        var updated = bookmark
        updated.name = trimmedName
        updated.host = trimmedHost
        updated.port = bookmark.port.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.nickname = bookmark.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[index] = updated
        } else {
            bookmarks.insert(updated, at: 0)
        }
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
        complaintEntries = []
        complaintTarget = nil
        databaseClients = []
        databaseSearchResults = []
        clientLocations = []
        selectedDatabaseClient = nil
        serverLogEntries = []
        serverGroups = []
        channelGroups = []
        permissionInfos = []
        ownClientPermissions = []
        ownClientDatabaseId = nil
        permissionEditScope = .ownClient
        selectedServerGroupPermissionId = nil
        selectedChannelGroupPermissionId = nil
        selectedChannelPermissionId = nil
        scopedPermissions = []
        privilegeKeys = []
        generatedPrivilegeKey = nil
        fileEntries = []
        fileBrowserChannelId = nil
        fileBrowserPath = "/"
        serverInfo = .empty
        isTalking = false
        isAway = false
        isInputMuted = false
        isOutputMuted = false
        isChannelCommander = false
        isRequestingTalkPower = false
        talkRequestMessage = ""
        whisperRoute = .none
        microphonePermissionPrompt = nil
        iconURLs = [:]
        iconDownloads = []
        failedIconIds = []
    }

    func updatePlaybackVolume(_ volume: Double) {
        let clamped = min(max(volume, 0), 4)
        playbackVolume = clamped
        client?.setPlaybackVolume(Float(clamped))
    }

    func updateInputGain(_ gain: Double) {
        let clamped = min(max(gain, 0), 4)
        inputGain = clamped
        client?.setInputGain(Float(clamped))
    }

    func updateVoiceActivationThreshold(_ threshold: Double) {
        let clamped = min(max(threshold, 0.001), 0.5)
        voiceActivationThreshold = clamped
        client?.setVoiceActivationThreshold(Float(clamped))
    }

    func updateAudioTransmitMode(_ mode: TS3AudioTransmitMode) {
        audioTransmitMode = mode
        client?.setAudioTransmitMode(mode)
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
        }
    }

    var inputGainPercentText: String {
        "\(Int((inputGain * 100).rounded()))%"
    }

    var voiceActivationThresholdText: String {
        String(format: "%.3f", voiceActivationThreshold)
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

    func createServerGroup(name: String, type: TS3PermissionGroupDatabaseType) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        runClientCommand { client in
            _ = try await client.createServerGroup(name: name, type: type)
        }
    }

    func copyServerGroup(_ group: TS3GroupSummary, name: String, type: TS3PermissionGroupDatabaseType) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        runClientCommand { client in
            _ = try await client.copyServerGroup(sourceGroupId: group.id, name: name, type: type)
        }
    }

    func renameServerGroup(_ group: TS3GroupSummary, name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != group.name else { return }
        runClientCommand { client in
            try await client.renameServerGroup(groupId: group.id, name: name)
        }
    }

    func deleteServerGroup(_ group: TS3GroupSummary, force: Bool) {
        runClientCommand { client in
            try await client.deleteServerGroup(groupId: group.id, force: force)
        }
    }

    func createChannelGroup(name: String, type: TS3PermissionGroupDatabaseType) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        runClientCommand { client in
            _ = try await client.createChannelGroup(name: name, type: type)
        }
    }

    func copyChannelGroup(_ group: TS3GroupSummary, name: String, type: TS3PermissionGroupDatabaseType) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        runClientCommand { client in
            _ = try await client.copyChannelGroup(sourceGroupId: group.id, name: name, type: type)
        }
    }

    func renameChannelGroup(_ group: TS3GroupSummary, name: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name != group.name else { return }
        runClientCommand { client in
            try await client.renameChannelGroup(groupId: group.id, name: name)
        }
    }

    func deleteChannelGroup(_ group: TS3GroupSummary, force: Bool) {
        runClientCommand { client in
            try await client.deleteChannelGroup(groupId: group.id, force: force)
        }
    }

    func refreshPermissionList() {
        runClientCommand { client in
            let permissions = try await client.refreshPermissionList()
            await MainActor.run {
                self.permissionInfos = permissions
                    .map { TS3PermissionInfoSummary(info: $0) }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }

    func refreshOwnClientPermissions() {
        guard let ownClient = clients.first(where: { $0.isCurrentUser }) else {
            lastError = "Current client details are not available yet."
            return
        }
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: ownClient, using: client)
            let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
            await MainActor.run {
                self.ownClientDatabaseId = databaseId
                self.ownClientPermissions = permissions
                    .map { TS3PermissionSummary(permission: $0) }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }

    func refreshSelectedPermissions() {
        switch permissionEditScope {
        case .ownClient:
            refreshOwnClientPermissions()
        case .serverGroup:
            guard let groupId = selectedServerGroupPermissionId ?? serverGroups.first?.id else {
                scopedPermissions = []
                return
            }
            selectedServerGroupPermissionId = groupId
            runClientCommand { client in
                let permissions = try await client.refreshServerGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channelGroup:
            guard let groupId = selectedChannelGroupPermissionId ?? channelGroups.first?.id else {
                scopedPermissions = []
                return
            }
            selectedChannelGroupPermissionId = groupId
            runClientCommand { client in
                let permissions = try await client.refreshChannelGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channel:
            guard let channelId = selectedChannelPermissionId ?? currentChannel?.id ?? channels.first?.id else {
                scopedPermissions = []
                return
            }
            selectedChannelPermissionId = channelId
            runClientCommand { client in
                let permissions = try await client.refreshChannelPermissions(channelId: channelId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channelClient:
            guard let selection = selectedChannelClientPermissionTarget() else {
                scopedPermissions = []
                return
            }
            selectedChannelClientPermissionChannelId = selection.channelId
            selectedChannelClientPermissionClientId = selection.clientId
            runClientCommand { client in
                let permissions = try await client.refreshChannelClientPermissions(
                    channelId: selection.channelId,
                    clientDatabaseId: selection.databaseId
                )
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        }
    }

    func selectPermissionScope(_ scope: TS3PermissionEditScope) {
        permissionEditScope = scope
        scopedPermissions = []
        refreshSelectedPermissions()
    }

    func addOwnClientPermission(name: String, value: Int, skip: Bool) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard let ownClient = clients.first(where: { $0.isCurrentUser }) else {
            lastError = "Current client details are not available yet."
            return
        }
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: ownClient, using: client)
            try await client.addClientPermission(clientDatabaseId: databaseId, permissionName: name, value: value, skip: skip)
            let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
            await MainActor.run {
                self.ownClientDatabaseId = databaseId
                self.ownClientPermissions = permissions
                    .map { TS3PermissionSummary(permission: $0) }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }

    func addSelectedPermission(name: String, value: Int, negated: Bool, skip: Bool) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        switch permissionEditScope {
        case .ownClient:
            addOwnClientPermission(name: name, value: value, skip: skip)
        case .serverGroup:
            guard let groupId = selectedServerGroupPermissionId else {
                lastError = "Select a server group first."
                return
            }
            runClientCommand { client in
                try await client.addServerGroupPermission(groupId: groupId, permissionName: name, value: value, negated: negated, skip: skip)
                let permissions = try await client.refreshServerGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channelGroup:
            guard let groupId = selectedChannelGroupPermissionId else {
                lastError = "Select a channel group first."
                return
            }
            runClientCommand { client in
                try await client.addChannelGroupPermission(groupId: groupId, permissionName: name, value: value, negated: negated, skip: skip)
                let permissions = try await client.refreshChannelGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channel:
            guard let channelId = selectedChannelPermissionId else {
                lastError = "Select a channel first."
                return
            }
            runClientCommand { client in
                try await client.addChannelPermission(channelId: channelId, permissionName: name, value: value)
                let permissions = try await client.refreshChannelPermissions(channelId: channelId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channelClient:
            guard let selection = selectedChannelClientPermissionTarget() else {
                lastError = "Select a channel client first."
                return
            }
            runClientCommand { client in
                try await client.addChannelClientPermission(
                    channelId: selection.channelId,
                    clientDatabaseId: selection.databaseId,
                    permissionName: name,
                    value: value,
                    skip: skip
                )
                let permissions = try await client.refreshChannelClientPermissions(
                    channelId: selection.channelId,
                    clientDatabaseId: selection.databaseId
                )
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        }
    }

    func deleteOwnClientPermission(_ permission: TS3PermissionSummary) {
        guard let ownClient = clients.first(where: { $0.isCurrentUser }) else {
            lastError = "Current client details are not available yet."
            return
        }
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: ownClient, using: client)
            try await client.deleteClientPermission(clientDatabaseId: databaseId, permissionName: permission.name)
            let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
            await MainActor.run {
                self.ownClientDatabaseId = databaseId
                self.ownClientPermissions = permissions
                    .map { TS3PermissionSummary(permission: $0) }
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
        }
    }

    func deleteSelectedPermission(_ permission: TS3PermissionSummary) {
        switch permissionEditScope {
        case .ownClient:
            deleteOwnClientPermission(permission)
        case .serverGroup:
            guard let groupId = selectedServerGroupPermissionId else {
                lastError = "Select a server group first."
                return
            }
            runClientCommand { client in
                try await client.deleteServerGroupPermission(groupId: groupId, permissionName: permission.name)
                let permissions = try await client.refreshServerGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channelGroup:
            guard let groupId = selectedChannelGroupPermissionId else {
                lastError = "Select a channel group first."
                return
            }
            runClientCommand { client in
                try await client.deleteChannelGroupPermission(groupId: groupId, permissionName: permission.name)
                let permissions = try await client.refreshChannelGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channel:
            guard let channelId = selectedChannelPermissionId else {
                lastError = "Select a channel first."
                return
            }
            runClientCommand { client in
                try await client.deleteChannelPermission(channelId: channelId, permissionName: permission.name)
                let permissions = try await client.refreshChannelPermissions(channelId: channelId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .channelClient:
            guard let selection = selectedChannelClientPermissionTarget() else {
                lastError = "Select a channel client first."
                return
            }
            runClientCommand { client in
                try await client.deleteChannelClientPermission(
                    channelId: selection.channelId,
                    clientDatabaseId: selection.databaseId,
                    permissionName: permission.name
                )
                let permissions = try await client.refreshChannelClientPermissions(
                    channelId: selection.channelId,
                    clientDatabaseId: selection.databaseId
                )
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        }
    }

    func channelClientPermissionMembers() -> [TS3UserSummary] {
        let channelId = selectedChannelClientPermissionChannelId ?? currentChannel?.id ?? channels.first?.id
        guard let channelId else { return [] }
        return members(in: channelId)
    }

    private func selectedChannelClientPermissionTarget() -> (channelId: Int, clientId: Int, databaseId: Int)? {
        guard let channelId = selectedChannelClientPermissionChannelId ?? currentChannel?.id ?? channels.first?.id else {
            return nil
        }
        let members = members(in: channelId)
        guard let user = members.first(where: { $0.id == selectedChannelClientPermissionClientId }) ?? members.first,
              let databaseId = user.databaseId else {
            return nil
        }
        return (channelId, user.id, databaseId)
    }

    private func permissionSummaries(from permissions: [TS3Permission]) -> [TS3PermissionSummary] {
        permissions
            .map { TS3PermissionSummary(permission: $0) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func refreshServerInfo() {
        runClientCommand { client in
            try await client.refreshServerInfo()
        }
    }

    func refreshServerLogs(limit: Int = 100, reverse: Bool = true, instance: Bool = false) {
        runClientCommand { client in
            let entries = try await client.serverLogEntries(limit: limit, reverse: reverse, instance: instance)
            await MainActor.run {
                self.serverLogEntries = entries.map { TS3ServerLogSummary(entry: $0) }
            }
        }
    }

    func addServerLogEntry(level: TS3LogLevel, message: String, limit: Int = 100, reverse: Bool = true, instance: Bool = false) {
        runClientCommand { client in
            try await client.addServerLogEntry(level: level, message: message)
            let entries = try await client.serverLogEntries(limit: limit, reverse: reverse, instance: instance)
            await MainActor.run {
                self.serverLogEntries = entries.map { TS3ServerLogSummary(entry: $0) }
            }
        }
    }

    func refreshClientDatabase(limit: Int = 100) {
        runClientCommand { client in
            let records = try await client.refreshClientDatabase(start: 0, duration: limit)
            await MainActor.run {
                self.databaseClients = records
                    .map { TS3DatabaseClientSummary(client: $0) }
                    .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
            }
        }
    }

    func searchClientDatabase(pattern: String) {
        let pattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pattern.isEmpty else {
            databaseSearchResults = []
            clientLocations = []
            return
        }
        runClientCommand { client in
            let databaseRecords = try await client.findDatabaseClients(pattern: pattern)
            let locations = try await client.onlineClientIds(forNamePattern: pattern)
            await MainActor.run {
                self.databaseSearchResults = databaseRecords
                    .map { TS3DatabaseClientSummary(client: $0) }
                    .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
                self.clientLocations = locations.map { TS3ClientLocationSummary(location: $0) }
            }
        }
    }

    func loadDatabaseClientDetails(_ record: TS3DatabaseClientSummary) {
        runClientCommand { client in
            let detailed = try await client.databaseClientInfo(clientDatabaseId: record.id)
            let locations: [TS3ClientLocation]
            if let uniqueIdentifier = detailed?.uniqueIdentifier ?? record.uniqueIdentifier {
                locations = try await client.onlineClientIds(forUniqueIdentifier: uniqueIdentifier)
            } else {
                locations = []
            }
            await MainActor.run {
                self.selectedDatabaseClient = (detailed.map { TS3DatabaseClientSummary(client: $0) } ?? record)
                self.clientLocations = locations.map { TS3ClientLocationSummary(location: $0) }
            }
        }
    }

    func resolveDatabaseIdForSelectedClient() {
        guard let uniqueIdentifier = selectedDatabaseClient?.uniqueIdentifier else {
            lastError = "Selected database client has no unique id."
            return
        }
        runClientCommand { client in
            guard let databaseId = try await client.databaseId(forUniqueIdentifier: uniqueIdentifier),
                  let detailed = try await client.databaseClientInfo(clientDatabaseId: databaseId) else {
                throw TS3Error.serverError(message: "No database id found for selected unique id.")
            }
            await MainActor.run {
                self.selectedDatabaseClient = TS3DatabaseClientSummary(client: detailed)
            }
        }
    }

    func editDatabaseClientDescription(_ record: TS3DatabaseClientSummary, description: String) {
        runClientCommand { client in
            try await client.editDatabaseClientDescription(clientDatabaseId: record.id, description: description)
            let detailed = try await client.databaseClientInfo(clientDatabaseId: record.id)
            await MainActor.run {
                let updated = detailed.map { TS3DatabaseClientSummary(client: $0) }
                    ?? record.copy(description: description.trimmingCharacters(in: .whitespacesAndNewlines))
                self.replaceDatabaseClient(updated)
                if self.selectedDatabaseClient?.id == record.id {
                    self.selectedDatabaseClient = updated
                }
            }
        }
    }

    func deleteDatabaseClient(_ record: TS3DatabaseClientSummary) {
        runClientCommand { client in
            try await client.deleteDatabaseClient(clientDatabaseId: record.id)
            await MainActor.run {
                self.databaseClients.removeAll { $0.id == record.id }
                self.databaseSearchResults.removeAll { $0.id == record.id }
                if self.selectedDatabaseClient?.id == record.id {
                    self.selectedDatabaseClient = nil
                    self.clientLocations = []
                }
            }
        }
    }

    func editServerSettings(
        name: String,
        welcomeMessage: String,
        maxClients: Int?,
        reservedSlots: Int?,
        password: String?,
        hostMessage: String,
        hostMessageMode: Int?,
        hostBannerURL: String,
        hostBannerGraphicsURL: String,
        hostButtonTooltip: String,
        hostButtonURL: String,
        hostButtonGraphicsURL: String,
        iconId: Int?
    ) {
        let edit = TS3ServerEdit(
            name: trimmedValue(name),
            welcomeMessage: welcomeMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            maxClients: maxClients,
            reservedSlots: reservedSlots,
            password: password,
            hostMessage: hostMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            hostMessageMode: hostMessageMode,
            hostBannerURL: hostBannerURL.trimmingCharacters(in: .whitespacesAndNewlines),
            hostBannerGraphicsURL: hostBannerGraphicsURL.trimmingCharacters(in: .whitespacesAndNewlines),
            hostButtonTooltip: hostButtonTooltip.trimmingCharacters(in: .whitespacesAndNewlines),
            hostButtonURL: hostButtonURL.trimmingCharacters(in: .whitespacesAndNewlines),
            hostButtonGraphicsURL: hostButtonGraphicsURL.trimmingCharacters(in: .whitespacesAndNewlines),
            iconId: iconId
        )
        runClientCommand { client in
            try await client.editServer(edit)
        }
    }

    func uploadServerIcon(from source: URL, updateDraft: ((Int) -> Void)? = nil) {
        uploadIcon(from: source) { client, iconId in
            try await client.editServer(TS3ServerEdit(iconId: iconId))
        } onSuccess: { iconId in
            updateDraft?(iconId)
            self.serverInfo.iconId = iconId
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

    func openFileBrowser(channel: TS3ChannelSummary? = nil) {
        let target = channel ?? currentChannel ?? channels.first
        guard let target else {
            lastError = "Join or select a channel before browsing files."
            return
        }
        fileBrowserChannelId = target.id
        fileBrowserPath = "/"
        refreshFileList()
    }

    func selectFileBrowserChannel(_ channel: TS3ChannelSummary) {
        fileBrowserChannelId = channel.id
        fileBrowserPath = "/"
        refreshFileList()
    }

    func refreshFileList() {
        guard let channelId = fileBrowserChannelId ?? currentChannel?.id ?? channels.first?.id else {
            lastError = "No channel is available for file browsing."
            return
        }
        fileBrowserChannelId = channelId
        let path = normalizedFileDirectoryPath(fileBrowserPath)
        fileBrowserPath = path
        runClientCommand { client in
            let entries = try await client.refreshFileList(channelId: channelId, path: path)
            await MainActor.run {
                self.fileEntries = entries
                    .map { TS3FileEntrySummary(entry: $0) }
                    .sorted {
                        if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
                        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    }
            }
        }
    }

    func enterFileDirectory(_ entry: TS3FileEntrySummary) {
        guard entry.isDirectory else { return }
        fileBrowserChannelId = entry.channelId
        fileBrowserPath = normalizedFileDirectoryPath(entry.path)
        refreshFileList()
    }

    func leaveFileDirectory() {
        guard fileBrowserPath != "/" else { return }
        let trimmed = fileBrowserPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = trimmed.split(separator: "/").dropLast()
        fileBrowserPath = components.isEmpty ? "/" : "/" + components.joined(separator: "/") + "/"
        refreshFileList()
    }

    func jumpToFileDirectory(_ path: String) {
        fileBrowserPath = normalizedFileDirectoryPath(path)
        refreshFileList()
    }

    func createFileDirectory(named name: String) {
        guard let channelId = fileBrowserChannelId else {
            lastError = "No channel is selected for file browsing."
            return
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let path = joinedFilePath(parentPath: fileBrowserPath, name: name)
        runClientCommand { client in
            try await client.createFileDirectory(channelId: channelId, path: path)
        } onSuccess: {
            self.refreshFileList()
        }
    }

    func deleteFileEntry(_ entry: TS3FileEntrySummary) {
        runClientCommand { client in
            try await client.deleteFile(channelId: entry.channelId, path: entry.path)
        } onSuccess: {
            self.refreshFileList()
        }
    }

    func renameFileEntry(_ entry: TS3FileEntrySummary, to newName: String) {
        let newName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty, newName != entry.name else { return }
        let newPath = joinedFilePath(parentPath: entry.parentPath, name: newName)
        runClientCommand { client in
            try await client.renameFile(channelId: entry.channelId, oldPath: entry.path, newPath: newPath)
        } onSuccess: {
            self.refreshFileList()
        }
    }

    func downloadFileEntry(_ entry: TS3FileEntrySummary) {
        guard !entry.isDirectory else { return }
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        Task {
            do {
                let destination = try downloadDestination(for: entry.name)
                await MainActor.run {
                    self.fileTransferStatus = "Preparing download: \(entry.name)"
                    self.fileTransferProgress = 0
                }
                let parameters = try await client.initFileDownload(channelId: entry.channelId, path: entry.path)
                try await TS3FileTransfer.download(parameters: parameters, to: destination) { received, total in
                    Task { @MainActor in
                        if let total, total > 0 {
                            self.fileTransferProgress = min(1, Double(received) / Double(total))
                        }
                        self.fileTransferStatus = "Downloading \(entry.name): \(Self.transferProgressText(received, total: total))"
                    }
                }
                await MainActor.run {
                    self.fileTransferProgress = 1
                    self.fileTransferStatus = "Downloaded \(entry.name) to \(destination.lastPathComponent)"
                    self.lastDownloadedFile = TS3DownloadedFileSummary(name: destination.lastPathComponent, url: destination)
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.fileTransferProgress = nil
                    self.fileTransferStatus = nil
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func openLastDownloadedFile() {
        guard let file = lastDownloadedFile else { return }
        TS3PlatformSupport.openURL(file.url)
    }

    func uploadFiles(_ sources: [URL], overwrite: Bool = false) {
        guard !sources.isEmpty else { return }
        for source in sources {
            uploadFile(from: source, overwrite: overwrite)
        }
    }

    func uploadFile(from source: URL, overwrite: Bool = false) {
        guard let channelId = fileBrowserChannelId else {
            lastError = "No channel is selected for file browsing."
            return
        }
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        Task {
            let didAccess = source.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    source.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
                let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
                let remoteName = source.lastPathComponent
                let remotePath = joinedFilePath(parentPath: fileBrowserPath, name: remoteName)
                await MainActor.run {
                    self.fileTransferStatus = "Preparing upload: \(remoteName)"
                    self.fileTransferProgress = 0
                }
                let parameters = try await client.initFileUpload(
                    channelId: channelId,
                    path: remotePath,
                    size: size,
                    overwrite: overwrite
                )
                try await TS3FileTransfer.upload(parameters: parameters, from: source) { sent, total in
                    Task { @MainActor in
                        if let total, total > 0 {
                            self.fileTransferProgress = min(1, Double(sent) / Double(total))
                        }
                        self.fileTransferStatus = "Uploading \(remoteName): \(Self.transferProgressText(sent, total: total))"
                    }
                }
                await MainActor.run {
                    self.fileTransferProgress = 1
                    self.fileTransferStatus = "Uploaded \(remoteName)"
                    self.lastError = nil
                    self.refreshFileList()
                }
            } catch {
                await MainActor.run {
                    self.fileTransferProgress = nil
                    self.fileTransferStatus = nil
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    private func uploadIcon(
        from source: URL,
        apply: @escaping (TS3Client, Int) async throws -> Void,
        onSuccess: @escaping @MainActor (Int) -> Void
    ) {
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        Task {
            let didAccess = source.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    source.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let data = try Data(contentsOf: source)
                let iconId = TS3IconFile.iconId(for: data)
                let fileName = source.lastPathComponent
                await MainActor.run {
                    self.fileTransferStatus = "Preparing icon upload: \(fileName)"
                    self.fileTransferProgress = 0
                }
                let parameters = try await client.initIconUpload(iconId: iconId, size: Int64(data.count))
                try await TS3FileTransfer.upload(parameters: parameters, from: source) { sent, total in
                    Task { @MainActor in
                        if let total, total > 0 {
                            self.fileTransferProgress = min(1, Double(sent) / Double(total))
                        }
                        self.fileTransferStatus = "Uploading icon \(iconId): \(Self.transferProgressText(sent, total: total))"
                    }
                }
                let destination = try iconDestination(for: iconId)
                try data.write(to: destination, options: .atomic)
                try await apply(client, iconId)
                await MainActor.run {
                    self.iconURLs[iconId] = destination
                    onSuccess(iconId)
                    self.applyIconURL(destination, for: iconId)
                    self.fileTransferProgress = 1
                    self.fileTransferStatus = "Uploaded icon \(iconId)"
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.fileTransferProgress = nil
                    self.fileTransferStatus = nil
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    private func normalizedFileDirectoryPath(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "/" }
        var result = trimmed
        if !result.hasPrefix("/") {
            result = "/" + result
        }
        if !result.hasSuffix("/") {
            result += "/"
        }
        return result
    }

    private func joinedFilePath(parentPath: String, name: String) -> String {
        let parentPath = normalizedFileDirectoryPath(parentPath)
        if name.hasPrefix("/") {
            return name
        }
        return parentPath + name
    }

    private func downloadDestination(for name: String) throws -> URL {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = documents.appendingPathComponent("TS3 Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return uniqueFileURL(in: directory, named: name)
    }

    private func avatarDestination(for hash: String) throws -> URL {
        let caches = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = caches.appendingPathComponent("TS3 Avatars", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileName = "avatar_" + (hash.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? hash)
        return directory.appendingPathComponent(fileName)
    }

    private func iconDestination(for iconId: Int) throws -> URL {
        let caches = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = caches.appendingPathComponent("TS3 Icons", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("icon_\(iconId)")
    }

    private func refreshMissingIcons() {
        guard let client else { return }
        let channelIconIds = channels.compactMap(\.iconId)
        let clientIconIds = clients.compactMap(\.iconId)
        let serverIconIds = [serverInfo.iconId].compactMap { $0 }
        let iconIds = Set((serverIconIds + channelIconIds + clientIconIds).filter { $0 != 0 })
        for iconId in iconIds where iconURLs[iconId] == nil
            && !iconDownloads.contains(iconId)
            && !failedIconIds.contains(iconId) {
            downloadIcon(iconId, using: client)
        }
    }

    private func downloadIcon(_ iconId: Int, using client: TS3Client) {
        iconDownloads.insert(iconId)
        Task {
            do {
                let destination = try iconDestination(for: iconId)
                if !FileManager.default.fileExists(atPath: destination.path) {
                    let parameters = try await client.initIconDownload(iconId: iconId)
                    try await TS3FileTransfer.download(parameters: parameters, to: destination)
                }
                await MainActor.run {
                    self.iconDownloads.remove(iconId)
                    self.iconURLs[iconId] = destination
                    self.applyIconURL(destination, for: iconId)
                }
            } catch {
                await MainActor.run {
                    self.iconDownloads.remove(iconId)
                    self.failedIconIds.insert(iconId)
                }
            }
        }
    }

    private func applyIconURL(_ url: URL, for iconId: Int) {
        channels = channels.map { channel in
            var updated = channel
            if channel.iconId == iconId {
                updated.iconURL = url
            }
            return updated
        }
        if serverInfo.iconId == iconId {
            serverInfo.iconURL = url
        }
        clients = clients.map { user in
            guard user.iconId == iconId else { return user }
            return copyUser(user, iconURL: url)
        }
    }

    private func uniqueFileURL(in directory: URL, named name: String) -> URL {
        let fallbackName = name.isEmpty ? "download" : name
        let baseURL = directory.appendingPathComponent(fallbackName)
        guard FileManager.default.fileExists(atPath: baseURL.path) else {
            return baseURL
        }

        let baseName = (fallbackName as NSString).deletingPathExtension
        let pathExtension = (fallbackName as NSString).pathExtension
        var index = 2
        while true {
            let candidateName: String
            if pathExtension.isEmpty {
                candidateName = "\(baseName) \(index)"
            } else {
                candidateName = "\(baseName) \(index).\(pathExtension)"
            }
            let candidate = directory.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }

    private static func transferProgressText(_ completed: Int64, total: Int64?) -> String {
        guard let total, total > 0 else {
            return byteCountFormatter.string(fromByteCount: completed)
        }
        return "\(byteCountFormatter.string(fromByteCount: completed)) of \(byteCountFormatter.string(fromByteCount: total))"
    }

    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    func refreshUserAvatar(_ user: TS3UserSummary) {
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        Task {
            do {
                await MainActor.run {
                    self.avatarDownloadStatus = "Preparing avatar: \(user.nickname)"
                }
                var avatarHash = user.avatarHash ?? ""
                if avatarHash.isEmpty,
                   let updated = try await client.refreshClientDetails(clientId: user.id),
                   let updatedHash = updated.avatarHash {
                    avatarHash = updatedHash
                    await MainActor.run {
                        self.updateUser(clientId: user.id) { existing in
                            self.copyUser(existing, avatarHash: updatedHash)
                        }
                    }
                }
                guard !avatarHash.isEmpty else {
                    throw TS3Error.fileTransferFailed
                }
                let destination = try avatarDestination(for: avatarHash)
                let parameters = try await client.initAvatarDownload(hash: avatarHash)
                try await TS3FileTransfer.download(parameters: parameters, to: destination)
                await MainActor.run {
                    self.updateUser(clientId: user.id) { existing in
                        self.copyUser(existing, avatarURL: destination)
                    }
                    self.avatarDownloadStatus = "Downloaded avatar: \(user.nickname)"
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.avatarDownloadStatus = nil
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func refreshUserDetails(_ user: TS3UserSummary) {
        runClientCommand { client in
            let updated = try await client.refreshClientDetails(clientId: user.id)
            if let updated {
                await MainActor.run {
                    self.updateUser(clientId: user.id) { existing in
                        self.copyUser(
                            existing,
                            avatarHash: updated.avatarHash,
                            version: updated.version,
                            platform: updated.platform,
                            country: updated.country,
                            ipAddress: updated.ipAddress,
                            createdAt: updated.createdAt,
                            lastConnectedAt: updated.lastConnectedAt,
                            totalConnections: updated.totalConnections,
                            idleTimeSeconds: updated.idleTimeSeconds,
                            connectedSeconds: updated.connectedSeconds
                        )
                    }
                }
            }
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

    private func trimmedValue(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
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
        setAway(newValue, message: message)
    }

    func setAway(_ value: Bool, message: String) {
        runClientCommand { client in
            try await client.setAway(value, message: message.isEmpty ? nil : message)
        } onSuccess: {
            self.isAway = value
            self.awayMessage = message
        }
    }

    func toggleInputMuted() {
        setInputMuted(!isInputMuted)
    }

    func setInputMuted(_ newValue: Bool) {
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
        setOutputMuted(!isOutputMuted)
    }

    func setOutputMuted(_ newValue: Bool) {
        runClientCommand { client in
            try await client.setOutputMuted(newValue)
        } onSuccess: {
            self.isOutputMuted = newValue
        }
    }

    func setChannelCommander(_ newValue: Bool) {
        runClientCommand { client in
            try await client.setChannelCommander(newValue)
        } onSuccess: {
            self.isChannelCommander = newValue
        }
    }

    func setTalkRequest(_ isRequesting: Bool, message: String) {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            try await client.setTalkRequest(isRequesting, message: trimmed)
        } onSuccess: {
            self.isRequestingTalkPower = isRequesting
            self.talkRequestMessage = isRequesting ? trimmed : ""
        }
    }

    func setSelfIcon(iconId: Int?) {
        runClientCommand { client in
            try await client.setClientIcon(iconId: iconId ?? 0)
        } onSuccess: {
            guard let ownClient = self.clients.first(where: { $0.isCurrentUser }) else { return }
            self.updateUser(clientId: ownClient.id) { existing in
                self.copyUser(existing, iconId: iconId ?? 0, resetIconURL: true)
            }
            self.refreshMissingIcons()
        }
    }

    func uploadSelfIcon(from source: URL, updateDraft: ((Int) -> Void)? = nil) {
        uploadIcon(from: source) { client, iconId in
            try await client.setClientIcon(iconId: iconId)
        } onSuccess: { iconId in
            updateDraft?(iconId)
            guard let ownClient = self.clients.first(where: { $0.isCurrentUser }) else { return }
            self.updateUser(clientId: ownClient.id) { existing in
                self.copyUser(existing, iconId: iconId, resetIconURL: true)
            }
        }
    }

    func createChannel(
        name: String,
        parentId: Int?,
        password: String?,
        channelType: TS3ChannelType,
        phoneticName: String,
        topic: String,
        description: String,
        neededTalkPower: Int?,
        neededSubscribePower: Int?,
        codec: Int?,
        codecQuality: Int?,
        deleteDelaySeconds: Int?,
        maxClients: Int?,
        maxFamilyClients: Int?,
        maxClientsUnlimited: Bool,
        maxFamilyClientsUnlimited: Bool,
        maxFamilyClientsInherited: Bool,
        iconId: Int?
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        runClientCommand { client in
            _ = try await client.createChannel(
                name: trimmed,
                parentId: parentId,
                password: password?.isEmpty == true ? nil : password,
                permanent: channelType == .permanent,
                semiPermanent: channelType == .semiPermanent,
                phoneticName: phoneticName.isEmpty ? nil : phoneticName,
                topic: topic.isEmpty ? nil : topic,
                description: description.isEmpty ? nil : description,
                codec: codec,
                codecQuality: codecQuality,
                neededTalkPower: neededTalkPower,
                neededSubscribePower: neededSubscribePower,
                deleteDelaySeconds: deleteDelaySeconds,
                maxClients: maxClientsUnlimited ? nil : maxClients,
                maxFamilyClients: maxFamilyClientsUnlimited || maxFamilyClientsInherited ? nil : maxFamilyClients,
                maxClientsUnlimited: maxClientsUnlimited,
                maxFamilyClientsUnlimited: maxFamilyClientsUnlimited,
                maxFamilyClientsInherited: maxFamilyClientsInherited,
                iconId: iconId
            )
        }
    }

    func editChannel(
        _ channel: TS3ChannelSummary,
        name: String,
        phoneticName: String,
        topic: String,
        description: String,
        password: String?,
        isDefault: Bool,
        channelType: TS3ChannelType,
        neededTalkPower: Int?,
        neededSubscribePower: Int?,
        codec: Int?,
        codecQuality: Int?,
        deleteDelaySeconds: Int?,
        maxClients: Int?,
        maxFamilyClients: Int?,
        maxClientsUnlimited: Bool,
        maxFamilyClientsUnlimited: Bool,
        maxFamilyClientsInherited: Bool,
        iconId: Int?
    ) {
        runClientCommand { client in
            try await client.editChannel(
                channelId: channel.id,
                name: name.isEmpty ? nil : name,
                phoneticName: phoneticName.isEmpty ? nil : phoneticName,
                topic: topic.isEmpty ? nil : topic,
                description: description.isEmpty ? nil : description,
                password: password?.isEmpty == true ? nil : password,
                isDefault: isDefault,
                isPermanent: channelType == .permanent,
                isSemiPermanent: channelType == .semiPermanent,
                neededTalkPower: neededTalkPower,
                neededSubscribePower: neededSubscribePower,
                codec: codec,
                codecQuality: codecQuality,
                deleteDelaySeconds: deleteDelaySeconds,
                maxClients: maxClientsUnlimited ? nil : maxClients,
                maxFamilyClients: maxFamilyClientsUnlimited || maxFamilyClientsInherited ? nil : maxFamilyClients,
                maxClientsUnlimited: maxClientsUnlimited,
                maxFamilyClientsUnlimited: maxFamilyClientsUnlimited,
                maxFamilyClientsInherited: maxFamilyClientsInherited,
                iconId: iconId
            )
        }
    }

    func uploadChannelIcon(from source: URL, for channel: TS3ChannelSummary, updateDraft: ((Int) -> Void)? = nil) {
        uploadIcon(from: source) { client, iconId in
            try await client.editChannel(
                channelId: channel.id,
                name: nil,
                phoneticName: nil,
                topic: nil,
                description: nil,
                password: nil,
                iconId: iconId
            )
        } onSuccess: { iconId in
            updateDraft?(iconId)
            self.channels = self.channels.map { existing in
                var updated = existing
                if existing.id == channel.id {
                    updated.iconId = iconId
                    updated.iconURL = self.iconURLs[iconId]
                }
                return updated
            }
            self.refreshMissingIcons()
        }
    }

    func uploadDraftChannelIcon(from source: URL, updateDraft: @escaping (Int) -> Void) {
        uploadIcon(from: source) { _, _ in
        } onSuccess: { iconId in
            updateDraft(iconId)
        }
    }

    func deleteChannel(_ channel: TS3ChannelSummary) {
        runClientCommand { client in
            try await client.deleteChannel(channelId: channel.id, force: true)
        }
    }

    func moveChannel(_ channel: TS3ChannelSummary, toParentId parentId: Int?, order: Int?) {
        runClientCommand { client in
            try await client.moveChannel(channelId: channel.id, parentId: parentId, order: order)
        }
    }

    func setChannelSubscribed(_ channel: TS3ChannelSummary, isSubscribed: Bool) {
        runClientCommand { client in
            try await client.setChannelSubscribed(channelId: channel.id, isSubscribed: isSubscribed)
        }
    }

    func setAllChannelsSubscribed(_ isSubscribed: Bool) {
        runClientCommand { client in
            try await client.setAllChannelsSubscribed(isSubscribed)
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

    func banUser(_ user: TS3UserSummary, durationSeconds: Int?, message: String?) {
        runClientCommand { client in
            try await client.banClient(clientId: user.id, durationSeconds: durationSeconds, message: message)
            let entries = try await client.refreshBanList()
            await MainActor.run {
                self.banEntries = entries.map { TS3BanEntrySummary(entry: $0) }
            }
        }
    }

    func addBan(ip: String, name: String, uniqueIdentifier: String, durationSeconds: Int?, reason: String) {
        let ip = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let uniqueIdentifier = uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ip.isEmpty || !name.isEmpty || !uniqueIdentifier.isEmpty else {
            lastError = "Enter an IP address, name, or unique id for the ban rule."
            return
        }
        runClientCommand { client in
            try await client.addBan(
                ip: ip.isEmpty ? nil : ip,
                name: name.isEmpty ? nil : name,
                uniqueIdentifier: uniqueIdentifier.isEmpty ? nil : uniqueIdentifier,
                durationSeconds: durationSeconds,
                reason: reason.isEmpty ? nil : reason
            )
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

    func complainAboutUser(_ user: TS3UserSummary, message: String) {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.addComplaint(clientDatabaseId: databaseId, message: message)
        }
    }

    func refreshComplaints(for user: TS3UserSummary) {
        complaintTarget = user
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            let entries = try await client.refreshComplaints(clientDatabaseId: databaseId)
            await MainActor.run {
                self.complaintTarget = user
                self.complaintEntries = entries
                    .map { TS3ComplaintSummary(entry: $0) }
                    .sorted {
                        switch ($0.timestamp, $1.timestamp) {
                        case let (lhs?, rhs?): return lhs > rhs
                        case (_?, nil): return true
                        case (nil, _?): return false
                        case (nil, nil): return $0.sourceClientDatabaseId < $1.sourceClientDatabaseId
                        }
                    }
            }
        }
    }

    func deleteComplaint(_ entry: TS3ComplaintSummary) {
        runClientCommand { client in
            try await client.deleteComplaint(
                targetClientDatabaseId: entry.targetClientDatabaseId,
                sourceClientDatabaseId: entry.sourceClientDatabaseId
            )
            await MainActor.run {
                self.complaintEntries.removeAll { $0.id == entry.id }
            }
        }
    }

    func deleteAllComplaintsForCurrentTarget() {
        guard let target = complaintTarget else {
            lastError = "Select a user before clearing complaints."
            return
        }
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: target, using: client)
            try await client.deleteAllComplaints(clientDatabaseId: databaseId)
            await MainActor.run {
                self.complaintEntries = []
            }
        }
    }

    func pokeUser(_ user: TS3UserSummary, message: String) {
        runClientCommand { client in
            try await client.pokeClient(clientId: user.id, message: message.isEmpty ? "Poke" : message)
        }
    }

    func editUserDescription(_ user: TS3UserSummary, description: String) {
        runClientCommand { client in
            try await client.editClientDescription(clientId: user.id, description: description)
            await MainActor.run {
                self.updateUser(clientId: user.id) { existing in
                    self.copyUser(existing, description: description)
                }
            }
        }
    }

    func usePrivilegeKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        runClientCommand { client in
            try await client.usePrivilegeKey(trimmed)
        }
    }

    func refreshPrivilegeKeys() {
        runClientCommand { client in
            let keys = try await client.refreshPrivilegeKeys()
            await MainActor.run {
                self.privilegeKeys = keys
                    .map { TS3PrivilegeKeySummary(entry: $0) }
                    .sorted {
                        switch ($0.createdAt, $1.createdAt) {
                        case let (lhs?, rhs?): return lhs > rhs
                        case (_?, nil): return true
                        case (nil, _?): return false
                        case (nil, nil): return $0.key < $1.key
                        }
                    }
            }
        }
    }

    func createPrivilegeKey(
        targetType: TS3PrivilegeKeyTargetType,
        groupId: Int,
        channelId: Int?,
        description: String,
        customSet: String
    ) {
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let customSet = customSet.trimmingCharacters(in: .whitespacesAndNewlines)
        let channelId = targetType == .channelGroup ? channelId : nil
        runClientCommand { client in
            let key = try await client.createPrivilegeKey(
                type: targetType.kitType,
                groupId: groupId,
                channelId: channelId,
                description: description.isEmpty ? nil : description,
                customSet: customSet.isEmpty ? nil : customSet
            )
            let keys = try await client.refreshPrivilegeKeys()
            await MainActor.run {
                self.generatedPrivilegeKey = key
                self.privilegeKeys = keys.map { TS3PrivilegeKeySummary(entry: $0) }
            }
        }
    }

    func deletePrivilegeKey(_ key: TS3PrivilegeKeySummary) {
        runClientCommand { client in
            try await client.deletePrivilegeKey(key.key)
            await MainActor.run {
                self.privilegeKeys.removeAll { $0.id == key.id }
                if self.generatedPrivilegeKey == key.key {
                    self.generatedPrivilegeKey = nil
                }
            }
        }
    }

    func addServerGroup(_ group: TS3GroupSummary, to user: TS3UserSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.addServerGroup(groupId: group.id, toClientDatabaseId: databaseId)
            await MainActor.run {
                self.upsertServerGroup(group.id, forClientId: user.id)
            }
        }
    }

    func removeServerGroup(_ group: TS3GroupSummary, from user: TS3UserSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.removeServerGroup(groupId: group.id, fromClientDatabaseId: databaseId)
            await MainActor.run {
                self.removeServerGroup(group.id, fromClientId: user.id)
            }
        }
    }

    func setChannelGroup(_ group: TS3GroupSummary, for user: TS3UserSummary, in channel: TS3ChannelSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.setChannelGroup(groupId: group.id, channelId: channel.id, clientDatabaseId: databaseId)
            await MainActor.run {
                self.setChannelGroup(group.id, forClientId: user.id)
            }
        }
    }

    func setPrioritySpeaker(_ isPrioritySpeaker: Bool, for user: TS3UserSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.setPrioritySpeaker(isPrioritySpeaker, channelId: user.channelId, clientDatabaseId: databaseId)
            await MainActor.run {
                self.updateUser(clientId: user.id) { existing in
                    self.copyUser(existing, isPrioritySpeaker: isPrioritySpeaker)
                }
            }
        }
    }

    func setTalker(_ isTalker: Bool, for user: TS3UserSummary) {
        runClientCommand { client in
            try await client.setClientTalker(isTalker, clientId: user.id)
            await MainActor.run {
                self.updateUser(clientId: user.id) { existing in
                    self.copyUser(
                        existing,
                        isTalker: isTalker,
                        isRequestingTalkPower: isTalker ? false : existing.isRequestingTalkPower,
                        talkRequestMessage: isTalker ? "" : existing.talkRequestMessage
                    )
                }
            }
        }
    }

    private func upsertServerGroup(_ groupId: Int, forClientId clientId: Int) {
        updateUser(clientId: clientId) { user in
            if user.serverGroups.contains(groupId) {
                return user
            }
            var groups = user.serverGroups
            groups.append(groupId)
            return copyUser(user, serverGroups: groups.sorted())
        }
    }

    private func removeServerGroup(_ groupId: Int, fromClientId clientId: Int) {
        updateUser(clientId: clientId) { user in
            copyUser(user, serverGroups: user.serverGroups.filter { $0 != groupId })
        }
    }

    private func setChannelGroup(_ groupId: Int, forClientId clientId: Int) {
        updateUser(clientId: clientId) { user in
            copyUser(user, channelGroupId: groupId)
        }
    }

    private func updateUser(clientId: Int, transform: (TS3UserSummary) -> TS3UserSummary) {
        guard let index = clients.firstIndex(where: { $0.id == clientId }) else { return }
        clients[index] = transform(clients[index])
    }

    private func replaceDatabaseClient(_ record: TS3DatabaseClientSummary) {
        func replace(in records: inout [TS3DatabaseClientSummary]) {
            guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
            records[index] = record
            records.sort { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
        }

        replace(in: &databaseClients)
        replace(in: &databaseSearchResults)
    }

    private func copyUser(
        _ user: TS3UserSummary,
        isPrioritySpeaker: Bool? = nil,
        isTalker: Bool? = nil,
        isRequestingTalkPower: Bool? = nil,
        talkRequestMessage: String? = nil,
        channelGroupId: Int? = nil,
        serverGroups: [Int]? = nil,
        description: String? = nil,
        avatarHash: String? = nil,
        avatarURL: URL? = nil,
        iconId: Int? = nil,
        iconURL: URL? = nil,
        resetIconURL: Bool = false,
        version: String? = nil,
        platform: String? = nil,
        country: String? = nil,
        ipAddress: String? = nil,
        createdAt: Date? = nil,
        lastConnectedAt: Date? = nil,
        totalConnections: Int? = nil,
        idleTimeSeconds: Int? = nil,
        connectedSeconds: Int? = nil
    ) -> TS3UserSummary {
        TS3UserSummary(
            id: user.id,
            channelId: user.channelId,
            databaseId: user.databaseId,
            uniqueIdentifier: user.uniqueIdentifier,
            nickname: user.nickname,
            isCurrentUser: user.isCurrentUser,
            isInputMuted: user.isInputMuted,
            isOutputMuted: user.isOutputMuted,
            isAway: user.isAway,
            awayMessage: user.awayMessage,
            isChannelCommander: user.isChannelCommander,
            isPrioritySpeaker: isPrioritySpeaker ?? user.isPrioritySpeaker,
            isTalker: isTalker ?? user.isTalker,
            isRequestingTalkPower: isRequestingTalkPower ?? user.isRequestingTalkPower,
            talkRequestMessage: talkRequestMessage ?? user.talkRequestMessage,
            talkPower: user.talkPower,
            channelGroupId: channelGroupId ?? user.channelGroupId,
            serverGroups: serverGroups ?? user.serverGroups,
            description: description ?? user.description,
            avatarHash: avatarHash ?? user.avatarHash,
            avatarURL: avatarURL ?? user.avatarURL,
            iconId: iconId ?? user.iconId,
            iconURL: resetIconURL ? nil : (iconURL ?? user.iconURL),
            version: version ?? user.version,
            platform: platform ?? user.platform,
            country: country ?? user.country,
            ipAddress: ipAddress ?? user.ipAddress,
            createdAt: createdAt ?? user.createdAt,
            lastConnectedAt: lastConnectedAt ?? user.lastConnectedAt,
            totalConnections: totalConnections ?? user.totalConnections,
            idleTimeSeconds: idleTimeSeconds ?? user.idleTimeSeconds,
            connectedSeconds: connectedSeconds ?? user.connectedSeconds
        )
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

        applyAudioSettings(to: client)
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
                applyAudioSettings(to: client)
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

    private func applyAudioSettings(to client: TS3Client) {
        client.setPlaybackVolume(Float(playbackVolume))
        client.setInputGain(Float(inputGain))
        client.setAudioTransmitMode(audioTransmitMode)
        client.setVoiceActivationThreshold(Float(voiceActivationThreshold))
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
                    order: channel.order,
                    name: channel.name,
                    phoneticName: channel.phoneticName,
                    topic: channel.topic,
                    description: channel.description,
                    isDefault: channel.isDefault,
                    isPasswordProtected: channel.isPasswordProtected,
                    isPermanent: channel.isPermanent,
                    isSemiPermanent: channel.isSemiPermanent,
                    neededTalkPower: channel.neededTalkPower,
                    neededSubscribePower: channel.neededSubscribePower,
                    codec: channel.codec,
                    codecQuality: channel.codecQuality,
                    deleteDelaySeconds: channel.deleteDelaySeconds,
                    maxClients: channel.maxClients,
                    maxFamilyClients: channel.maxFamilyClients,
                    maxClientsUnlimited: channel.maxClientsUnlimited,
                    maxFamilyClientsUnlimited: channel.maxFamilyClientsUnlimited,
                    maxFamilyClientsInherited: channel.maxFamilyClientsInherited,
                    iconId: channel.iconId,
                    iconURL: channel.iconId.flatMap { self.iconURLs[$0] },
                    isSubscribed: channel.isSubscribed,
                    isCurrent: channel.id == client.currentChannelId
                )
            }
            self.refreshMissingIcons()
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateServerInfo info: TS3ServerInfo) {
        Task { @MainActor in
            self.serverInfo = TS3ServerInfoSummary(
                name: info.name,
                uniqueIdentifier: info.uniqueIdentifier,
                platform: info.platform,
                version: info.version,
                createdAt: info.createdAt,
                clientsOnline: info.clientsOnline,
                maxClients: info.maxClients,
                clientsInQuery: info.clientsInQuery,
                reservedSlots: info.reservedSlots,
                channelsOnline: info.channelsOnline,
                uptimeSeconds: info.uptimeSeconds,
                welcomeMessage: info.welcomeMessage,
                passwordProtected: info.passwordProtected,
                status: info.status,
                machineId: info.machineId,
                codecEncryptionMode: info.codecEncryptionMode,
                defaultServerGroupId: info.defaultServerGroupId,
                defaultChannelGroupId: info.defaultChannelGroupId,
                defaultChannelAdminGroupId: info.defaultChannelAdminGroupId,
                fileBase: info.fileBase,
                fileTransferPort: info.fileTransferPort,
                complainAutoBanCount: info.complainAutoBanCount,
                complainAutoBanTime: info.complainAutoBanTime,
                complainRemoveTime: info.complainRemoveTime,
                minClientsInChannelBeforeForcedSilence: info.minClientsInChannelBeforeForcedSilence,
                prioritySpeakerDimmModificator: info.prioritySpeakerDimmModificator,
                clientConnections: info.clientConnections,
                queryClientConnections: info.queryClientConnections,
                downloadQuota: info.downloadQuota,
                uploadQuota: info.uploadQuota,
                monthlyBytesDownloaded: info.monthlyBytesDownloaded,
                monthlyBytesUploaded: info.monthlyBytesUploaded,
                totalBytesDownloaded: info.totalBytesDownloaded,
                totalBytesUploaded: info.totalBytesUploaded,
                totalPacketLossSpeech: info.totalPacketLossSpeech,
                totalPacketLossKeepalive: info.totalPacketLossKeepalive,
                totalPacketLossControl: info.totalPacketLossControl,
                totalPacketLossTotal: info.totalPacketLossTotal,
                totalPing: info.totalPing,
                hostMessage: info.hostMessage,
                hostMessageMode: info.hostMessageMode,
                hostBannerURL: info.hostBannerURL,
                hostBannerGraphicsURL: info.hostBannerGraphicsURL,
                hostButtonTooltip: info.hostButtonTooltip,
                hostButtonURL: info.hostButtonURL,
                hostButtonGraphicsURL: info.hostButtonGraphicsURL,
                iconId: info.iconId,
                iconURL: info.iconId.flatMap { self.iconURLs[$0] }
            )
            self.refreshMissingIcons()
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateClients clients: [TS3ServerClient]) {
        Task { @MainActor in
            let existingAvatars = Dictionary(uniqueKeysWithValues: self.clients.map {
                ($0.id, (hash: $0.avatarHash, url: $0.avatarURL))
            })
            self.clients = clients.map { client in
                let existingAvatar = existingAvatars[client.id]
                let avatarURL = existingAvatar?.hash == client.avatarHash ? existingAvatar?.url : nil
                return TS3UserSummary(
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
                    isChannelCommander: client.isChannelCommander,
                    isPrioritySpeaker: client.isPrioritySpeaker,
                    isTalker: client.isTalker,
                    isRequestingTalkPower: client.isRequestingTalkPower,
                    talkRequestMessage: client.talkRequestMessage,
                    talkPower: client.talkPower,
                    channelGroupId: client.channelGroupId,
                    serverGroups: client.serverGroups,
                    description: client.description,
                    avatarHash: client.avatarHash,
                    avatarURL: avatarURL,
                    iconId: client.iconId,
                    iconURL: client.iconId.flatMap { self.iconURLs[$0] },
                    version: client.version,
                    platform: client.platform,
                    country: client.country,
                    ipAddress: client.ipAddress,
                    createdAt: client.createdAt,
                    lastConnectedAt: client.lastConnectedAt,
                    totalConnections: client.totalConnections,
                    idleTimeSeconds: client.idleTimeSeconds,
                    connectedSeconds: client.connectedSeconds
                )
            }
            self.refreshMissingIcons()
            if let ownClient = clients.first(where: { $0.isCurrentUser }) {
                self.nickname = ownClient.nickname
                self.isInputMuted = ownClient.isInputMuted
                self.isOutputMuted = ownClient.isOutputMuted
                self.isAway = ownClient.isAway
                self.isChannelCommander = ownClient.isChannelCommander
                self.isRequestingTalkPower = ownClient.isRequestingTalkPower
                self.talkRequestMessage = ownClient.talkRequestMessage ?? self.talkRequestMessage
                self.awayMessage = ownClient.awayMessage ?? self.awayMessage
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
            self.serverGroups = groups.map { TS3GroupSummary(id: $0.id, name: $0.name, type: $0.type) }
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateChannelGroups groups: [TS3ChannelGroup]) {
        Task { @MainActor in
            self.channelGroups = groups.map { TS3GroupSummary(id: $0.id, name: $0.name, type: $0.type) }
        }
    }
}
