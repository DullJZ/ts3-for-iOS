import Foundation
import TS3Kit
import CryptoKit
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(AVFAudio)
import AVFAudio
#endif
#if canImport(UserNotifications)
import UserNotifications
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

struct TS3ChatMessageSummary: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let targetMode: TS3TextMessageTargetMode
    let targetId: Int?
    let senderId: Int?
    let senderName: String
    let message: String
    let isOwnMessage: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case targetMode
        case targetId
        case senderId
        case senderName
        case message
        case isOwnMessage
    }

    init(
        id: UUID,
        timestamp: Date,
        targetMode: TS3TextMessageTargetMode,
        targetId: Int?,
        senderId: Int?,
        senderName: String,
        message: String,
        isOwnMessage: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.targetMode = targetMode
        self.targetId = targetId
        self.senderId = senderId
        self.senderName = senderName
        self.message = message
        self.isOwnMessage = isOwnMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        let rawTargetMode = try container.decode(Int.self, forKey: .targetMode)
        targetMode = TS3TextMessageTargetMode(rawValue: rawTargetMode) ?? .channel
        targetId = try container.decodeIfPresent(Int.self, forKey: .targetId)
        senderId = try container.decodeIfPresent(Int.self, forKey: .senderId)
        senderName = try container.decode(String.self, forKey: .senderName)
        message = try container.decode(String.self, forKey: .message)
        isOwnMessage = try container.decode(Bool.self, forKey: .isOwnMessage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(targetMode.rawValue, forKey: .targetMode)
        try container.encodeIfPresent(targetId, forKey: .targetId)
        try container.encodeIfPresent(senderId, forKey: .senderId)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(message, forKey: .message)
        try container.encode(isOwnMessage, forKey: .isOwnMessage)
    }
}

struct TS3PokeSummary: Identifiable {
    let id: UUID
    let timestamp: Date
    let senderId: Int?
    let senderName: String
    let senderUniqueIdentifier: String?
    let message: String
    let isOwnPoke: Bool

    init(poke: TS3ClientPoke) {
        id = poke.id
        timestamp = poke.timestamp
        senderId = poke.senderId
        senderName = poke.senderName
        senderUniqueIdentifier = poke.senderUniqueIdentifier
        message = poke.message
        isOwnPoke = poke.isOwnPoke
    }
}

struct TS3ActivitySummary: Identifiable {
    let id: UUID
    let timestamp: Date
    let kind: TS3ServerActivityEvent.Kind
    let clientId: Int
    let clientName: String
    let channelId: Int?
    let channelName: String?
    let fromChannelId: Int?
    let toChannelId: Int?
    let invokerName: String?
    let reasonId: Int?
    let reasonMessage: String?
    let isOwnClient: Bool

    init(event: TS3ServerActivityEvent) {
        id = event.id
        timestamp = event.timestamp
        kind = event.kind
        clientId = event.clientId
        clientName = event.clientName
        channelId = event.channelId
        channelName = event.channelName
        fromChannelId = event.fromChannelId
        toChannelId = event.toChannelId
        invokerName = event.invokerName
        reasonId = event.reasonId
        reasonMessage = event.reasonMessage
        isOwnClient = event.isOwnClient
    }
}

enum TS3ContactStatus: String, CaseIterable, Codable, Identifiable {
    case neutral
    case friend
    case blocked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neutral:
            return "Neutral"
        case .friend:
            return "Friend"
        case .blocked:
            return "Blocked"
        }
    }
}

struct TS3ContactEntry: Identifiable, Codable {
    let uniqueIdentifier: String
    var nickname: String
    var status: TS3ContactStatus
    var note: String
    var updatedAt: Date

    var id: String { uniqueIdentifier }
}

struct TS3UserPlaybackPreference: Codable {
    var volume: Double = 1.0
    var isMuted = false
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

private struct TS3BanBackupEntry: Codable {
    var ip: String?
    var name: String?
    var uniqueIdentifier: String?
    var durationSeconds: Int?
    var reason: String?
}

private struct TS3BanBackup: Codable {
    var entries: [TS3BanBackupEntry]
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

private struct TS3SelfStatusBackup: Codable {
    var nickname: String
    var description: String
    var isAway: Bool
    var awayMessage: String
    var isInputMuted: Bool
    var isOutputMuted: Bool
    var isChannelCommander: Bool
    var talkRequestMessage: String
    var iconId: Int?
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

    init(groupClient: TS3GroupClientSummary) {
        self.id = groupClient.clientDatabaseId
        self.uniqueIdentifier = groupClient.uniqueIdentifier
        self.nickname = groupClient.displayName
        self.createdAt = nil
        self.lastConnectedAt = nil
        self.totalConnections = nil
        self.description = nil
        self.lastIP = nil
    }

    init?(user: TS3UserSummary) {
        guard let databaseId = user.databaseId else { return nil }
        self.id = databaseId
        self.uniqueIdentifier = user.uniqueIdentifier
        self.nickname = user.nickname
        self.createdAt = user.createdAt
        self.lastConnectedAt = user.lastConnectedAt
        self.totalConnections = user.totalConnections
        self.description = user.description
        self.lastIP = user.ipAddress
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

    init(
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

    var userSummary: TS3UserSummary {
        TS3UserSummary(
            id: -id,
            channelId: 0,
            databaseId: id,
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            isCurrentUser: false,
            isInputMuted: false,
            isOutputMuted: false,
            isAway: false,
            awayMessage: nil,
            isChannelCommander: false,
            isPrioritySpeaker: false,
            isTalker: false,
            isRequestingTalkPower: false,
            talkRequestMessage: nil,
            talkPower: nil,
            channelGroupId: nil,
            serverGroups: [],
            description: description,
            avatarHash: nil,
            avatarURL: nil,
            iconId: nil,
            iconURL: nil,
            version: nil,
            platform: nil,
            country: nil,
            ipAddress: lastIP,
            createdAt: createdAt,
            lastConnectedAt: lastConnectedAt,
            totalConnections: totalConnections,
            idleTimeSeconds: nil,
            connectedSeconds: nil
        )
    }
}

private struct TS3DatabaseClientBackupEntry: Codable {
    var id: Int
    var uniqueIdentifier: String?
    var nickname: String
    var createdAt: Date?
    var lastConnectedAt: Date?
    var totalConnections: Int?
    var description: String?
    var lastIP: String?
}

private struct TS3DatabaseClientBackup: Codable {
    var entries: [TS3DatabaseClientBackupEntry]
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

struct TS3GroupClientSummary: Identifiable {
    let id: String
    let clientDatabaseId: Int
    let uniqueIdentifier: String?
    let nickname: String?
    let channelId: Int?

    var displayName: String {
        nickname?.isEmpty == false ? nickname! : "Client \(clientDatabaseId)"
    }

    init(client: TS3GroupClient) {
        self.id = client.id
        self.clientDatabaseId = client.clientDatabaseId
        self.uniqueIdentifier = client.uniqueIdentifier
        self.nickname = client.nickname
        self.channelId = client.channelId
    }
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

private struct TS3PrivilegeKeyBackupEntry: Codable {
    var key: String
    var type: Int?
    var groupId: Int
    var channelId: Int?
    var createdAt: Date?
    var description: String?
    var customSet: String?
}

private struct TS3PrivilegeKeyBackup: Codable {
    var entries: [TS3PrivilegeKeyBackupEntry]
}

enum TS3PermissionEditScope: String, CaseIterable, Identifiable {
    case ownClient
    case databaseClient
    case serverGroup
    case channelGroup
    case channel
    case channelClient

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ownClient:
            return "Current Client"
        case .databaseClient:
            return "Database Client"
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
    let incompleteSize: Int64?

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
        self.incompleteSize = entry.incompleteSize
    }
}

struct TS3DownloadedFileSummary: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
}

enum TS3FileTransferDirection: String {
    case upload
    case download

    var title: String {
        switch self {
        case .upload:
            return "Upload"
        case .download:
            return "Download"
        }
    }
}

enum TS3FileTransferState: String {
    case preparing
    case transferring
    case completed
    case cancelled
    case failed

    var title: String {
        switch self {
        case .preparing:
            return "Preparing"
        case .transferring:
            return "Transferring"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        case .failed:
            return "Failed"
        }
    }
}

struct TS3FileTransferSummary: Identifiable {
    let id: UUID
    let direction: TS3FileTransferDirection
    let name: String
    let remotePath: String
    var localPath: String?
    var progress: Double?
    var state: TS3FileTransferState
    var detail: String
    let startedAt: Date
    var completedAt: Date?

    var canCancel: Bool {
        state == .preparing || state == .transferring
    }
}

private struct TS3PermissionBackupPermission: Codable {
    var name: String
    var value: Int
    var isNegated: Bool
    var isSkipped: Bool
}

private struct TS3PermissionBackup: Codable {
    var scope: String
    var ownClientDatabaseId: Int?
    var selectedDatabaseClientPermissionId: Int?
    var selectedServerGroupPermissionId: Int?
    var selectedChannelGroupPermissionId: Int?
    var selectedChannelPermissionId: Int?
    var selectedChannelClientPermissionChannelId: Int?
    var selectedChannelClientPermissionClientId: Int?
    var permissions: [TS3PermissionBackupPermission]
}

private struct TS3AudioSettings: Codable {
    var playbackVolume: Double
    var inputGain: Double
    var transmitMode: String
    var voiceActivationThreshold: Double

    static let defaults = TS3AudioSettings(
        playbackVolume: 1.0,
        inputGain: 1.0,
        transmitMode: TS3AudioTransmitMode.pushToTalk.rawValue,
        voiceActivationThreshold: 0.03
    )
}

private struct TS3NotificationSettings: Codable {
    var isEnabled: Bool

    static let defaults = TS3NotificationSettings(isEnabled: false)
}

private struct TS3ConnectionRecoverySettings: Codable {
    var autoReconnectEnabled: Bool

    static let defaults = TS3ConnectionRecoverySettings(autoReconnectEnabled: false)
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

struct TS3ConnectionSnapshot: Identifiable, Codable {
    let id: UUID
    let host: String
    let port: String
    let nickname: String
    let serverPassword: String
    let defaultChannel: String
    let defaultChannelPassword: String
    let privilegeKey: String

    var title: String {
        "\(host):\(port)"
    }

    init(
        id: UUID = UUID(),
        host: String,
        port: String,
        nickname: String,
        serverPassword: String,
        defaultChannel: String,
        defaultChannelPassword: String,
        privilegeKey: String
    ) {
        self.id = id
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
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
    case list(channelIds: [Int], clientIds: [Int])
    case group(type: TS3GroupWhisperType, target: TS3GroupWhisperTarget, targetId: Int)
}

struct TS3WhisperPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var channelIds: [Int]
    var clientIds: [Int]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        channelIds: [Int],
        clientIds: [Int],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.channelIds = channelIds
        self.clientIds = clientIds
        self.updatedAt = updatedAt
    }
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
    @Published private(set) var unreadChatMessageCount = 0
    @Published private(set) var pokeEvents: [TS3PokeSummary] = []
    @Published private(set) var unreadPokeCount = 0
    @Published private(set) var activityEvents: [TS3ActivitySummary] = []
    @Published private(set) var unreadActivityCount = 0
    @Published var offlineMessages: [TS3OfflineMessageSummary] = []
    @Published var banEntries: [TS3BanEntrySummary] = []
    @Published var complaintEntries: [TS3ComplaintSummary] = []
    @Published var complaintTarget: TS3UserSummary?
    @Published var databaseClients: [TS3DatabaseClientSummary] = []
    @Published var databaseSearchResults: [TS3DatabaseClientSummary] = []
    @Published var databaseClientBatchSize = 100
    @Published var canLoadMoreDatabaseClients = true
    @Published var clientLocations: [TS3ClientLocationSummary] = []
    @Published var selectedDatabaseClient: TS3DatabaseClientSummary?
    @Published var serverLogEntries: [TS3ServerLogSummary] = []
    @Published var serverGroups: [TS3GroupSummary] = []
    @Published var channelGroups: [TS3GroupSummary] = []
    @Published var groupClients: [TS3GroupClientSummary] = []
    @Published var groupClientListTitle = "Group Members"
    @Published var permissionInfos: [TS3PermissionInfoSummary] = []
    @Published var ownClientPermissions: [TS3PermissionSummary] = []
    @Published var ownClientDatabaseId: Int?
    @Published var permissionEditScope: TS3PermissionEditScope = .ownClient
    @Published var selectedDatabaseClientPermissionId: Int?
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
    @Published var fileBrowserPassword = ""
    @Published var fileTransferStatus: String?
    @Published var fileTransferProgress: Double?
    @Published var fileTransfers: [TS3FileTransferSummary] = []
    @Published var lastDownloadedFile: TS3DownloadedFileSummary?
    @Published var bookmarks: [TS3BookmarkSummary] = []
    @Published var contacts: [TS3ContactEntry] = []
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
    @Published private(set) var whisperPresets: [TS3WhisperPreset] = []
    @Published var logs: [TS3LogEntry] = []
    @Published var isShowingDebug = false
    @Published var lastError: String?
    @Published var avatarDownloadStatus: String?
    @Published var playbackVolume: Double = 1.0
    @Published var userPlaybackPreferences: [String: TS3UserPlaybackPreference] = [:]
    @Published var inputGain: Double = 1.0
    @Published var audioTransmitMode: TS3AudioTransmitMode = .pushToTalk
    @Published var voiceActivationThreshold: Double = 0.03
    @Published var microphonePermissionPrompt: MicrophonePermissionPrompt?
    @Published private(set) var notificationsEnabled = false
    @Published private(set) var autoReconnectEnabled = false
    @Published private(set) var autoReconnectStatus: String?

    @Published var serverHost = ""
    @Published var serverPort = "9987"
    @Published var serverPassword = ""
    @Published var defaultChannel = ""
    @Published var defaultChannelPassword = ""
    @Published var privilegeKey = ""
    @Published var nickname = TS3PlatformSupport.defaultNickname
    @Published var awayMessage = ""
    @Published private(set) var recentConnections: [TS3ConnectionSnapshot] = []
    @Published private(set) var lastConnectionSnapshot: TS3ConnectionSnapshot?
    @Published private(set) var lastDisconnectMessage: String?

    private var client: TS3Client?
    private var iconURLs: [Int: URL] = [:]
    private var iconDownloads: Set<Int> = []
    private var failedIconIds: Set<Int> = []
    private var fileTransferTasks: [UUID: Task<Void, Never>] = [:]
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private let chatHistoryLimit = 500
    private var isViewingChat = false
    private var isAppActive = true

    init() {
        loadAudioSettings()
        loadNotificationSettings()
        loadConnectionRecoverySettings()
        loadUserPlaybackPreferences()
        loadBookmarks()
        loadRecentConnections()
        loadContacts()
        loadChatHistory()
        loadWhisperPresets()
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

    func playbackVolumePercentText(for user: TS3UserSummary) -> String {
        "\(Int((userPlaybackPreference(for: user).volume * 100).rounded()))%"
    }

    func userPlaybackPreference(for user: TS3UserSummary) -> TS3UserPlaybackPreference {
        userPlaybackPreferences[userPlaybackPreferenceKey(for: user)] ?? TS3UserPlaybackPreference()
    }

    func updatePlaybackVolume(_ volume: Double, for user: TS3UserSummary) {
        let clamped = min(max(volume, 0), 4)
        let key = userPlaybackPreferenceKey(for: user)
        var preference = userPlaybackPreference(for: user)
        preference.volume = clamped
        setUserPlaybackPreference(preference, forKey: key)
        client?.setPlaybackGain(Float(clamped), forClientId: user.id)
        applyPlaybackMute(for: user)
    }

    func setPlaybackMuted(_ isMuted: Bool, for user: TS3UserSummary) {
        let key = userPlaybackPreferenceKey(for: user)
        var preference = userPlaybackPreference(for: user)
        preference.isMuted = isMuted
        setUserPlaybackPreference(preference, forKey: key)
        applyPlaybackMute(for: user)
    }

    func isPlaybackMuted(for user: TS3UserSummary) -> Bool {
        userPlaybackPreference(for: user).isMuted || contactStatus(for: user) == .blocked
    }

    private func userPlaybackPreferenceKey(for user: TS3UserSummary) -> String {
        if let uniqueIdentifier = user.uniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !uniqueIdentifier.isEmpty {
            return "uid:\(uniqueIdentifier)"
        }
        return "client:\(user.id)"
    }

    private func setUserPlaybackPreference(_ preference: TS3UserPlaybackPreference, forKey key: String) {
        let normalized = TS3UserPlaybackPreference(
            volume: min(max(preference.volume, 0), 4),
            isMuted: preference.isMuted
        )
        if normalized.volume == 1, !normalized.isMuted {
            userPlaybackPreferences.removeValue(forKey: key)
        } else {
            userPlaybackPreferences[key] = normalized
        }
        saveUserPlaybackPreferences()
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

    var friendContacts: [TS3ContactEntry] {
        contacts
            .filter { $0.status == .friend }
            .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
    }

    var blockedContacts: [TS3ContactEntry] {
        contacts
            .filter { $0.status == .blocked }
            .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
    }

    func members(in channelId: Int) -> [TS3UserSummary] {
        clients
            .filter { $0.channelId == channelId }
            .sorted {
                if $0.isCurrentUser != $1.isCurrentUser { return $0.isCurrentUser && !$1.isCurrentUser }
                return $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending
            }
    }

    func channelPath(for channel: TS3ChannelSummary) -> String {
        var path: [String] = [channel.name]
        var visited: Set<Int> = [channel.id]
        var parentId = normalizedChannelId(channel.parentId)

        while let id = parentId,
              !visited.contains(id),
              let parent = channels.first(where: { $0.id == id }) {
            visited.insert(id)
            path.insert(parent.name, at: 0)
            parentId = normalizedChannelId(parent.parentId)
        }

        return path.joined(separator: "/")
    }

    func setDefaultChannel(_ channel: TS3ChannelSummary, password: String = "") {
        defaultChannel = channelPath(for: channel)
        defaultChannelPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func contact(for user: TS3UserSummary) -> TS3ContactEntry? {
        guard let uniqueIdentifier = user.uniqueIdentifier else { return nil }
        return contacts.first { $0.uniqueIdentifier == uniqueIdentifier }
    }

    func contactStatus(for user: TS3UserSummary) -> TS3ContactStatus {
        contact(for: user)?.status ?? .neutral
    }

    func contactNote(for user: TS3UserSummary) -> String? {
        guard let note = contact(for: user)?.note, !note.isEmpty else { return nil }
        return note
    }

    func setContactStatus(_ status: TS3ContactStatus, for user: TS3UserSummary) {
        updateContact(for: user, status: status, note: contactNote(for: user) ?? "")
    }

    func setContactNote(_ note: String, for user: TS3UserSummary) {
        updateContact(for: user, status: contactStatus(for: user), note: note)
    }

    func contact(for record: TS3DatabaseClientSummary) -> TS3ContactEntry? {
        guard let uniqueIdentifier = record.uniqueIdentifier else { return nil }
        return contacts.first { $0.uniqueIdentifier == uniqueIdentifier }
    }

    func contactStatus(for record: TS3DatabaseClientSummary) -> TS3ContactStatus {
        contact(for: record)?.status ?? .neutral
    }

    func contactNote(for record: TS3DatabaseClientSummary) -> String? {
        guard let note = contact(for: record)?.note, !note.isEmpty else { return nil }
        return note
    }

    func setContactStatus(_ status: TS3ContactStatus, for record: TS3DatabaseClientSummary) {
        updateContact(for: record, status: status, note: contactNote(for: record) ?? "")
    }

    func setContactNote(_ note: String, for record: TS3DatabaseClientSummary) {
        updateContact(for: record, status: contactStatus(for: record), note: note)
    }

    func deleteContact(_ contact: TS3ContactEntry) {
        contacts.removeAll { $0.uniqueIdentifier == contact.uniqueIdentifier }
        saveContacts()
        syncBlockedContactPlayback()
    }

    func addContact(
        uniqueIdentifier: String,
        nickname: String,
        status: TS3ContactStatus,
        note: String
    ) {
        let uniqueIdentifier = uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uniqueIdentifier.isEmpty else {
            lastError = "Enter a unique id for the contact."
            return
        }
        let nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        contacts.removeAll { $0.uniqueIdentifier == uniqueIdentifier }
        contacts.insert(
            TS3ContactEntry(
                uniqueIdentifier: uniqueIdentifier,
                nickname: nickname.isEmpty ? uniqueIdentifier : nickname,
                status: status,
                note: note,
                updatedAt: Date()
            ),
            at: 0
        )
        saveContacts()
        syncBlockedContactPlayback()
        lastError = nil
    }

    func updateContact(_ contact: TS3ContactEntry, status: TS3ContactStatus, note: String) {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if status == .neutral && trimmedNote.isEmpty {
            deleteContact(contact)
            return
        }
        if let index = contacts.firstIndex(where: { $0.uniqueIdentifier == contact.uniqueIdentifier }) {
            contacts[index].status = status
            contacts[index].note = trimmedNote
            contacts[index].updatedAt = Date()
        } else {
            contacts.append(TS3ContactEntry(
                uniqueIdentifier: contact.uniqueIdentifier,
                nickname: contact.nickname,
                status: status,
                note: trimmedNote,
                updatedAt: Date()
            ))
        }
        saveContacts()
        syncBlockedContactPlayback()
    }

    private func updateContact(for user: TS3UserSummary, status: TS3ContactStatus, note: String) {
        guard let uniqueIdentifier = user.uniqueIdentifier else {
            lastError = "The server did not provide a unique id for \(user.nickname)."
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if status == .neutral && trimmedNote.isEmpty {
            contacts.removeAll { $0.uniqueIdentifier == uniqueIdentifier }
        } else if let index = contacts.firstIndex(where: { $0.uniqueIdentifier == uniqueIdentifier }) {
            contacts[index].nickname = user.nickname
            contacts[index].status = status
            contacts[index].note = trimmedNote
            contacts[index].updatedAt = Date()
        } else {
            contacts.append(TS3ContactEntry(
                uniqueIdentifier: uniqueIdentifier,
                nickname: user.nickname,
                status: status,
                note: trimmedNote,
                updatedAt: Date()
            ))
        }
        saveContacts()
        applyPlaybackMute(for: user)
    }

    private func updateContact(for record: TS3DatabaseClientSummary, status: TS3ContactStatus, note: String) {
        guard let uniqueIdentifier = record.uniqueIdentifier else {
            lastError = "The server did not provide a unique id for \(record.nickname)."
            return
        }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if status == .neutral && trimmedNote.isEmpty {
            contacts.removeAll { $0.uniqueIdentifier == uniqueIdentifier }
        } else if let index = contacts.firstIndex(where: { $0.uniqueIdentifier == uniqueIdentifier }) {
            contacts[index].nickname = record.nickname
            contacts[index].status = status
            contacts[index].note = trimmedNote
            contacts[index].updatedAt = Date()
        } else {
            contacts.append(TS3ContactEntry(
                uniqueIdentifier: uniqueIdentifier,
                nickname: record.nickname,
                status: status,
                note: trimmedNote,
                updatedAt: Date()
            ))
        }
        saveContacts()
        syncBlockedContactPlayback()
    }

    private func isBlockedMessage(_ message: TS3TextMessage) -> Bool {
        guard !message.isOwnMessage,
              let senderId = message.senderId,
              let sender = clients.first(where: { $0.id == senderId }) else {
            return false
        }
        return contactStatus(for: sender) == .blocked
    }

    private func applyPlaybackMute(for user: TS3UserSummary) {
        client?.setPlaybackMuted(isPlaybackMuted(for: user), forClientId: user.id)
    }

    private func syncBlockedContactPlayback() {
        for user in clients {
            applyPlaybackMute(for: user)
        }
    }

    private func applyOnlineUserPlaybackPreferences() {
        guard let client else { return }
        for user in clients {
            let preference = userPlaybackPreference(for: user)
            client.setPlaybackGain(Float(preference.volume), forClientId: user.id)
            client.setPlaybackMuted(preference.isMuted, forClientId: user.id)
        }
    }

    private func normalizedChannelId(_ id: Int?) -> Int? {
        guard let id, id > 0 else { return nil }
        return id
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

    func connect(cancelReconnect: Bool = true) {
        if cancelReconnect {
            cancelReconnectSchedule(resetAttempts: true)
        }
        lastError = nil
        lastDisconnectMessage = nil
        state = .connecting

        let port = Int(serverPort) ?? 9987
        let snapshot = currentConnectionSnapshot(port: port)
        lastConnectionSnapshot = snapshot
        upsertRecentConnection(snapshot)
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
                    guard self.client === newClient else { return }
                    self.lastError = error.localizedDescription
                    self.lastDisconnectMessage = error.localizedDescription
                    self.client = nil
                    self.clearConnectionState(keepLastConnection: true)
                    self.state = .disconnected
                    self.scheduleReconnectIfNeeded(reason: error.localizedDescription)
                }
            }
        }
    }

    func reconnect(cancelReconnect: Bool = true) {
        if cancelReconnect {
            cancelReconnectSchedule(resetAttempts: true)
        }
        guard let snapshot = lastConnectionSnapshot else {
            lastError = "No previous connection is available."
            return
        }
        serverHost = snapshot.host
        serverPort = snapshot.port
        nickname = snapshot.nickname
        serverPassword = snapshot.serverPassword
        defaultChannel = snapshot.defaultChannel
        defaultChannelPassword = snapshot.defaultChannelPassword
        privilegeKey = snapshot.privilegeKey
        connect(cancelReconnect: cancelReconnect)
    }

    func applyRecentConnection(_ snapshot: TS3ConnectionSnapshot) {
        serverHost = snapshot.host
        serverPort = snapshot.port
        nickname = snapshot.nickname
        serverPassword = snapshot.serverPassword
        defaultChannel = snapshot.defaultChannel
        defaultChannelPassword = snapshot.defaultChannelPassword
        privilegeKey = snapshot.privilegeKey
    }

    func deleteRecentConnection(_ snapshot: TS3ConnectionSnapshot) {
        recentConnections.removeAll { $0.id == snapshot.id }
        saveRecentConnections()
    }

    func clearRecentConnections() {
        recentConnections = []
        saveRecentConnections()
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

    func copyCurrentInviteLink() {
        guard let link = inviteLink(
            name: serverHost,
            host: serverHost,
            port: serverPort,
            nickname: nickname,
            defaultChannel: defaultChannel
        ) else {
            lastError = "Current server is not a valid TeamSpeak invite link."
            return
        }
        TS3PlatformSupport.copyToPasteboard(link)
        lastError = nil
    }

    func copyInviteLink(for channel: TS3ChannelSummary) {
        let channelPath = channelPath(for: channel)
        let name = "\(serverHost) - \(channel.name)"
        guard let link = inviteLink(
            name: name,
            host: serverHost,
            port: serverPort,
            nickname: nickname,
            defaultChannel: channelPath
        ) else {
            lastError = "Current channel is not a valid TeamSpeak invite link."
            return
        }
        TS3PlatformSupport.copyToPasteboard(link)
        lastError = nil
    }

    func copyInviteLink(for bookmark: TS3BookmarkSummary) {
        guard let link = inviteLink(
            name: bookmark.name,
            host: bookmark.host,
            port: bookmark.port,
            nickname: bookmark.nickname,
            defaultChannel: bookmark.defaultChannel
        ) else {
            lastError = "Bookmark is not a valid TeamSpeak invite link."
            return
        }
        TS3PlatformSupport.copyToPasteboard(link)
        lastError = nil
    }

    func applyServerURL(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            lastError = "Invalid TeamSpeak server URL."
            return
        }
        do {
            let serverURL = try TS3ServerURL(url: url)
            serverHost = serverURL.host
            serverPort = serverURL.port.map(String.init) ?? serverPort
            if let nickname = serverURL.nickname {
                self.nickname = nickname
            }
            serverPassword = serverURL.serverPassword ?? ""
            defaultChannel = serverURL.defaultChannel ?? ""
            defaultChannelPassword = serverURL.defaultChannelPassword ?? ""
            privilegeKey = serverURL.privilegeKey ?? ""
            if let bookmarkName = serverURL.bookmarkName {
                saveCurrentBookmark(name: bookmarkName)
            }
            lastError = nil
        } catch {
            lastError = "Invalid TeamSpeak server URL."
        }
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

    private func inviteLink(
        name: String,
        host: String,
        port: String,
        nickname: String,
        defaultChannel: String
    ) -> String? {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { return nil }
        let trimmedPort = port.trimmingCharacters(in: .whitespacesAndNewlines)
        let serverURL = TS3ServerURL(
            host: trimmedHost,
            port: Int(trimmedPort),
            nickname: nickname,
            serverPassword: nil,
            defaultChannel: defaultChannel,
            defaultChannelPassword: nil,
            privilegeKey: nil,
            bookmarkName: name
        )
        return serverURL.url(includingSecrets: false)?.absoluteString
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

    func bookmarksExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bookmarks)
    }

    @discardableResult
    func importBookmarks(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3BookmarkSummary].self, from: data)
        var merged = bookmarks
        for bookmark in imported {
            let host = bookmark.host.trimmingCharacters(in: .whitespacesAndNewlines)
            let port = bookmark.port.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !host.isEmpty, Int(port) != nil else { continue }
            var normalized = bookmark
            normalized.host = host
            normalized.port = port
            normalized.name = bookmark.name.trimmingCharacters(in: .whitespacesAndNewlines)
            normalized.nickname = bookmark.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalized.name.isEmpty {
                normalized.name = host
            }
            merged.removeAll { existing in
                existing.id == normalized.id || (
                    existing.host.caseInsensitiveCompare(normalized.host) == .orderedSame
                        && existing.port == normalized.port
                )
            }
            merged.insert(normalized, at: 0)
        }
        bookmarks = merged
        saveBookmarks()
        lastError = nil
        return imported.count
    }

    func disconnect(reason: String = "ui-disconnect") {
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        cancelReconnectSchedule(resetAttempts: true)
        client?.delegate = nil
        client?.disconnect(reason: reason.isEmpty ? "ui-disconnect" : reason)
        client = nil
        lastDisconnectMessage = nil
        clearConnectionState(keepLastConnection: true)
        state = .disconnected
    }

    private func scheduleReconnectIfNeeded(reason: String?) {
        guard autoReconnectEnabled,
              state == .disconnected,
              reconnectTask == nil,
              let snapshot = lastConnectionSnapshot,
              !snapshot.host.isEmpty,
              !snapshot.nickname.isEmpty else {
            return
        }
        reconnectAttempt += 1
        let delaySeconds = min(30, max(3, reconnectAttempt * 3))
        autoReconnectStatus = "Reconnect attempt \(reconnectAttempt) in \(delaySeconds)s"
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self,
                      !Task.isCancelled,
                      self.autoReconnectEnabled,
                      self.state == .disconnected else {
                    return
                }
                self.cancelReconnectSchedule(resetAttempts: false)
                self.autoReconnectStatus = reason.map { "Reconnecting after \($0)" } ?? "Reconnecting"
                self.reconnect(cancelReconnect: false)
            }
        }
    }

    private func cancelReconnectSchedule(resetAttempts: Bool) {
        reconnectTask?.cancel()
        reconnectTask = nil
        if resetAttempts {
            reconnectAttempt = 0
        }
        autoReconnectStatus = nil
    }

    private func currentConnectionSnapshot(port: Int? = nil) -> TS3ConnectionSnapshot {
        TS3ConnectionSnapshot(
            host: serverHost.trimmingCharacters(in: .whitespacesAndNewlines),
            port: String(port ?? (Int(serverPort) ?? 9987)),
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            serverPassword: serverPassword,
            defaultChannel: defaultChannel,
            defaultChannelPassword: defaultChannelPassword,
            privilegeKey: privilegeKey
        )
    }

    private func clearConnectionState(keepLastConnection: Bool) {
        channels = []
        clients = []
        pokeEvents = []
        unreadPokeCount = 0
        activityEvents = []
        unreadActivityCount = 0
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
        fileBrowserPassword = ""
        for task in fileTransferTasks.values {
            task.cancel()
        }
        fileTransferTasks = [:]
        fileTransfers = []
        fileTransferStatus = nil
        fileTransferProgress = nil
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
        if !keepLastConnection {
            lastConnectionSnapshot = nil
        }
    }

    private var recentConnectionsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-recent-connections.json")
    }

    private func loadRecentConnections() {
        guard let data = try? Data(contentsOf: recentConnectionsURL),
              let decoded = try? JSONDecoder().decode([TS3ConnectionSnapshot].self, from: data) else {
            recentConnections = []
            return
        }
        recentConnections = decoded
    }

    private func saveRecentConnections() {
        do {
            let directory = recentConnectionsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(recentConnections)
            try data.write(to: recentConnectionsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func upsertRecentConnection(_ snapshot: TS3ConnectionSnapshot) {
        var normalized = snapshot
        normalized = TS3ConnectionSnapshot(
            id: snapshot.id,
            host: snapshot.host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: snapshot.port.trimmingCharacters(in: .whitespacesAndNewlines),
            nickname: snapshot.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            serverPassword: snapshot.serverPassword,
            defaultChannel: snapshot.defaultChannel,
            defaultChannelPassword: snapshot.defaultChannelPassword,
            privilegeKey: snapshot.privilegeKey
        )
        recentConnections.removeAll {
            $0.host.caseInsensitiveCompare(normalized.host) == .orderedSame && $0.port == normalized.port
        }
        recentConnections.insert(normalized, at: 0)
        if recentConnections.count > 12 {
            recentConnections = Array(recentConnections.prefix(12))
        }
        saveRecentConnections()
    }

    func updatePlaybackVolume(_ volume: Double) {
        let clamped = min(max(volume, 0), 4)
        playbackVolume = clamped
        client?.setPlaybackVolume(Float(clamped))
        saveAudioSettings()
    }

    func updateInputGain(_ gain: Double) {
        let clamped = min(max(gain, 0), 4)
        inputGain = clamped
        client?.setInputGain(Float(clamped))
        saveAudioSettings()
    }

    func updateVoiceActivationThreshold(_ threshold: Double) {
        let clamped = min(max(threshold, 0.001), 0.5)
        voiceActivationThreshold = clamped
        client?.setVoiceActivationThreshold(Float(clamped))
        saveAudioSettings()
    }

    func updateAudioTransmitMode(_ mode: TS3AudioTransmitMode) {
        audioTransmitMode = mode
        client?.setAudioTransmitMode(mode)
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
        }
        saveAudioSettings()
    }

    func applyAudioPreset(mode: TS3AudioTransmitMode, inputGain: Double, threshold: Double? = nil) {
        audioTransmitMode = mode
        self.inputGain = min(max(inputGain, 0), 4)
        if let threshold {
            voiceActivationThreshold = min(max(threshold, 0.001), 0.5)
        }
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
        }
        if let client {
            applyAudioSettings(to: client)
        }
        saveAudioSettings()
    }

    func resetAudioSettings() {
        let defaults = TS3AudioSettings.defaults
        playbackVolume = defaults.playbackVolume
        inputGain = defaults.inputGain
        audioTransmitMode = TS3AudioTransmitMode(rawValue: defaults.transmitMode) ?? .pushToTalk
        voiceActivationThreshold = defaults.voiceActivationThreshold
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
        }
        if let client {
            applyAudioSettings(to: client)
        }
        saveAudioSettings()
    }

    func setAppActive(_ isActive: Bool) {
        isAppActive = isActive
    }

    func setNotificationsEnabled(_ isEnabled: Bool) {
        #if canImport(UserNotifications)
        guard isEnabled else {
            notificationsEnabled = false
            saveNotificationSettings()
            return
        }

        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    self.notificationsEnabled = granted
                    self.saveNotificationSettings()
                    if !granted {
                        self.lastError = "Notification permission was not granted."
                    }
                }
            } catch {
                await MainActor.run {
                    self.notificationsEnabled = false
                    self.saveNotificationSettings()
                    self.lastError = error.localizedDescription
                }
            }
        }
        #else
        notificationsEnabled = false
        lastError = "Notifications are not available on this platform."
        #endif
    }

    func setAutoReconnectEnabled(_ isEnabled: Bool) {
        autoReconnectEnabled = isEnabled
        saveConnectionRecoverySettings()
        if !isEnabled {
            cancelReconnectSchedule(resetAttempts: true)
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

    func refreshServerGroupClients(_ group: TS3GroupSummary) {
        groupClientListTitle = "\(group.name) Members"
        groupClients = []
        runClientCommand { client in
            let clients = try await client.refreshServerGroupClients(groupId: group.id)
            await MainActor.run {
                self.groupClients = clients
                    .map { TS3GroupClientSummary(client: $0) }
                    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            }
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

    func refreshChannelGroupClients(_ group: TS3GroupSummary) {
        groupClientListTitle = "\(group.name) Members"
        groupClients = []
        runClientCommand { client in
            let clients = try await client.refreshChannelGroupClients(groupId: group.id)
            await MainActor.run {
                self.groupClients = clients
                    .map { TS3GroupClientSummary(client: $0) }
                    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            }
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
        case .databaseClient:
            guard let databaseId = selectedDatabaseClientPermissionId ?? selectedDatabaseClient?.id else {
                scopedPermissions = []
                return
            }
            selectedDatabaseClientPermissionId = databaseId
            runClientCommand { client in
                let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
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

    func selectDatabaseClientPermissions(_ record: TS3DatabaseClientSummary) {
        permissionEditScope = .databaseClient
        selectedDatabaseClientPermissionId = record.id
        scopedPermissions = []
        refreshPermissionList()
        refreshSelectedPermissions()
    }

    func selectChannelPermissions(_ channel: TS3ChannelSummary) {
        permissionEditScope = .channel
        selectedChannelPermissionId = channel.id
        scopedPermissions = []
        refreshPermissionList()
        refreshSelectedPermissions()
    }

    func selectGroupPermissions(_ group: TS3GroupSummary, target: TS3GroupManagementTarget) {
        switch target {
        case .server:
            permissionEditScope = .serverGroup
            selectedServerGroupPermissionId = group.id
        case .channel:
            permissionEditScope = .channelGroup
            selectedChannelGroupPermissionId = group.id
        }
        scopedPermissions = []
        refreshPermissionList()
        refreshSelectedPermissions()
    }

    func selectChannelClientPermissions(_ user: TS3UserSummary) {
        guard user.databaseId != nil else {
            lastError = "Selected client has no database id yet."
            return
        }
        permissionEditScope = .channelClient
        selectedChannelClientPermissionChannelId = user.channelId
        selectedChannelClientPermissionClientId = user.id
        scopedPermissions = []
        refreshPermissionList()
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
        case .databaseClient:
            guard let databaseId = selectedDatabaseClientPermissionId else {
                lastError = "Select a database client first."
                return
            }
            runClientCommand { client in
                try await client.addClientPermission(clientDatabaseId: databaseId, permissionName: name, value: value, skip: skip)
                let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
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
        case .databaseClient:
            guard let databaseId = selectedDatabaseClientPermissionId else {
                lastError = "Select a database client first."
                return
            }
            runClientCommand { client in
                try await client.deleteClientPermission(clientDatabaseId: databaseId, permissionName: permission.name)
                let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
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

    func deleteSelectedPermissions(_ permissions: [TS3PermissionSummary]) {
        let names = Array(Set(permissions.map(\.name))).sorted()
        guard !names.isEmpty else { return }
        switch permissionEditScope {
        case .ownClient:
            guard let ownClient = clients.first(where: { $0.isCurrentUser }) else {
                lastError = "Current client details are not available yet."
                return
            }
            runClientCommand { client in
                let databaseId = try await self.databaseId(for: ownClient, using: client)
                for name in names {
                    try await client.deleteClientPermission(clientDatabaseId: databaseId, permissionName: name)
                }
                let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
                await MainActor.run {
                    self.ownClientDatabaseId = databaseId
                    self.ownClientPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .databaseClient:
            guard let databaseId = selectedDatabaseClientPermissionId else {
                lastError = "Select a database client first."
                return
            }
            runClientCommand { client in
                for name in names {
                    try await client.deleteClientPermission(clientDatabaseId: databaseId, permissionName: name)
                }
                let permissions = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: permissions)
                }
            }
        case .serverGroup:
            guard let groupId = selectedServerGroupPermissionId else {
                lastError = "Select a server group first."
                return
            }
            runClientCommand { client in
                for name in names {
                    try await client.deleteServerGroupPermission(groupId: groupId, permissionName: name)
                }
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
                for name in names {
                    try await client.deleteChannelGroupPermission(groupId: groupId, permissionName: name)
                }
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
                for name in names {
                    try await client.deleteChannelPermission(channelId: channelId, permissionName: name)
                }
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
                for name in names {
                    try await client.deleteChannelClientPermission(
                        channelId: selection.channelId,
                        clientDatabaseId: selection.databaseId,
                        permissionName: name
                    )
                }
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

    func permissionBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snapshot = TS3PermissionBackup(
            scope: permissionEditScope.rawValue,
            ownClientDatabaseId: ownClientDatabaseId,
            selectedDatabaseClientPermissionId: selectedDatabaseClientPermissionId,
            selectedServerGroupPermissionId: selectedServerGroupPermissionId,
            selectedChannelGroupPermissionId: selectedChannelGroupPermissionId,
            selectedChannelPermissionId: selectedChannelPermissionId,
            selectedChannelClientPermissionChannelId: selectedChannelClientPermissionChannelId,
            selectedChannelClientPermissionClientId: selectedChannelClientPermissionClientId,
            permissions: (permissionEditScope == .ownClient ? ownClientPermissions : scopedPermissions).map {
                TS3PermissionBackupPermission(
                    name: $0.name,
                    value: $0.value,
                    isNegated: $0.isNegated,
                    isSkipped: $0.isSkipped
                )
            }
        )
        return try encoder.encode(snapshot)
    }

    func importPermissionBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3PermissionBackup.self, from: data)
        permissionEditScope = TS3PermissionEditScope(rawValue: decoded.scope) ?? .ownClient
        ownClientDatabaseId = decoded.ownClientDatabaseId
        selectedDatabaseClientPermissionId = decoded.selectedDatabaseClientPermissionId
        selectedServerGroupPermissionId = decoded.selectedServerGroupPermissionId
        selectedChannelGroupPermissionId = decoded.selectedChannelGroupPermissionId
        selectedChannelPermissionId = decoded.selectedChannelPermissionId
        selectedChannelClientPermissionChannelId = decoded.selectedChannelClientPermissionChannelId
        selectedChannelClientPermissionClientId = decoded.selectedChannelClientPermissionClientId
        refreshSelectedPermissions()
        lastError = nil
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

    func refreshClientDatabase(limit: Int? = nil) {
        let requestedLimit = max(1, limit ?? databaseClientBatchSize)
        databaseClientBatchSize = requestedLimit
        runClientCommand { client in
            let records = try await client.refreshClientDatabase(start: 0, duration: requestedLimit)
            await MainActor.run {
                self.databaseClients = records
                    .map { TS3DatabaseClientSummary(client: $0) }
                    .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
                self.canLoadMoreDatabaseClients = records.count >= requestedLimit
                self.databaseSearchResults = []
                self.clientLocations = []
            }
        }
    }

    func loadMoreClientDatabaseRecords(limit: Int? = nil) {
        let start = databaseClients.count
        let requestedLimit = max(1, limit ?? databaseClientBatchSize)
        databaseClientBatchSize = requestedLimit
        runClientCommand { client in
            let records = try await client.refreshClientDatabase(start: start, duration: requestedLimit)
            await MainActor.run {
                let existingIds = Set(self.databaseClients.map(\.id))
                let newRecords = records
                    .map { TS3DatabaseClientSummary(client: $0) }
                    .filter { !existingIds.contains($0.id) }
                self.databaseClients = (self.databaseClients + newRecords)
                    .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
                self.canLoadMoreDatabaseClients = records.count >= requestedLimit
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

    func findDatabaseClient(uniqueIdentifier: String) {
        let uniqueIdentifier = uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uniqueIdentifier.isEmpty else {
            lastError = "Enter a unique id to search."
            return
        }
        runClientCommand { client in
            guard let databaseId = try await client.databaseId(forUniqueIdentifier: uniqueIdentifier),
                  let detailed = try await client.databaseClientInfo(clientDatabaseId: databaseId) else {
                throw TS3Error.serverError(message: "No database record found for unique id.")
            }
            let locations = try await client.onlineClientIds(forUniqueIdentifier: uniqueIdentifier)
            await MainActor.run {
                let record = TS3DatabaseClientSummary(client: detailed)
                self.selectedDatabaseClient = record
                self.replaceDatabaseClient(record)
                self.databaseSearchResults = [record]
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

    func databaseClientBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snapshot = TS3DatabaseClientBackup(
            entries: databaseClients.map {
                TS3DatabaseClientBackupEntry(
                    id: $0.id,
                    uniqueIdentifier: $0.uniqueIdentifier,
                    nickname: $0.nickname,
                    createdAt: $0.createdAt,
                    lastConnectedAt: $0.lastConnectedAt,
                    totalConnections: $0.totalConnections,
                    description: $0.description,
                    lastIP: $0.lastIP
                )
            }
        )
        return try encoder.encode(snapshot)
    }

    func importDatabaseClientBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3DatabaseClientBackup.self, from: data)
        let imported = decoded.entries.map {
            TS3DatabaseClientSummary(
                id: $0.id,
                uniqueIdentifier: $0.uniqueIdentifier,
                nickname: $0.nickname,
                createdAt: $0.createdAt,
                lastConnectedAt: $0.lastConnectedAt,
                totalConnections: $0.totalConnections,
                description: $0.description,
                lastIP: $0.lastIP
            )
        }
        databaseClients = imported.sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
        lastError = nil
    }

    func sendOfflineMessage(to record: TS3DatabaseClientSummary, subject: String, message: String) {
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !subject.isEmpty, !message.isEmpty else { return }
        guard let uniqueIdentifier = record.uniqueIdentifier else {
            lastError = "Selected database client has no unique id."
            return
        }
        runClientCommand { client in
            try await client.sendOfflineMessage(toUniqueIdentifier: uniqueIdentifier, subject: subject, message: message)
        }
    }

    func complainAboutDatabaseClient(_ record: TS3DatabaseClientSummary, message: String) {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        runClientCommand { client in
            try await client.addComplaint(clientDatabaseId: record.id, message: message)
        }
    }

    func banDatabaseClient(_ record: TS3DatabaseClientSummary, durationSeconds: Int?, reason: String?) {
        guard let uniqueIdentifier = record.uniqueIdentifier else {
            lastError = "Selected database client has no unique id."
            return
        }
        runClientCommand { client in
            try await client.addBan(
                uniqueIdentifier: uniqueIdentifier,
                durationSeconds: durationSeconds,
                reason: reason?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            let entries = try await client.refreshBanList()
            await MainActor.run {
                self.banEntries = self.banEntrySummaries(from: entries)
            }
        }
    }

    func refreshComplaints(for record: TS3DatabaseClientSummary) {
        complaintTarget = record.userSummary
        runClientCommand { client in
            let entries = try await client.refreshComplaints(clientDatabaseId: record.id)
            await MainActor.run {
                self.complaintTarget = record.userSummary
                self.complaintEntries = self.complaintSummaries(from: entries)
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
        iconId: Int?,
        downloadQuota: Int64?,
        uploadQuota: Int64?,
        complainAutoBanCount: Int?,
        complainAutoBanTime: Int?,
        complainRemoveTime: Int?,
        minClientsInChannelBeforeForcedSilence: Int?,
        prioritySpeakerDimmModificator: Double?,
        codecEncryptionMode: Int?
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
            iconId: iconId,
            downloadQuota: downloadQuota,
            uploadQuota: uploadQuota,
            complainAutoBanCount: complainAutoBanCount,
            complainAutoBanTime: complainAutoBanTime,
            complainRemoveTime: complainRemoveTime,
            minClientsInChannelBeforeForcedSilence: minClientsInChannelBeforeForcedSilence,
            prioritySpeakerDimmModificator: prioritySpeakerDimmModificator,
            codecEncryptionMode: codecEncryptionMode
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
                self.banEntries = self.banEntrySummaries(from: entries)
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
        fileBrowserPassword = ""
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
        let password = trimmedFileBrowserPassword
        runClientCommand { client in
            let entries = try await client.refreshFileList(channelId: channelId, path: path, password: password)
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
        let password = trimmedFileBrowserPassword
        runClientCommand { client in
            try await client.createFileDirectory(channelId: channelId, path: path, password: password)
        } onSuccess: {
            self.refreshFileList()
        }
    }

    func deleteFileEntry(_ entry: TS3FileEntrySummary) {
        let password = trimmedFileBrowserPassword
        runClientCommand { client in
            try await client.deleteFile(channelId: entry.channelId, path: entry.path, password: password)
        } onSuccess: {
            self.refreshFileList()
        }
    }

    func deleteFileEntries(_ entries: [TS3FileEntrySummary]) {
        let entries = entries.sorted {
            if $0.isDirectory != $1.isDirectory { return $0.isDirectory && !$1.isDirectory }
            return $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending
        }
        guard !entries.isEmpty else { return }
        let password = trimmedFileBrowserPassword
        runClientCommand { client in
            for entry in entries {
                try await client.deleteFile(channelId: entry.channelId, path: entry.path, password: password)
            }
            await MainActor.run {
                self.refreshFileList()
            }
        }
    }

    func renameFileEntry(_ entry: TS3FileEntrySummary, to newName: String) {
        let newName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty, newName != entry.name else { return }
        let newPath = joinedFilePath(parentPath: entry.parentPath, name: newName)
        let password = trimmedFileBrowserPassword
        runClientCommand { client in
            try await client.renameFile(channelId: entry.channelId, oldPath: entry.path, newPath: newPath, password: password)
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
        let transferId = addFileTransfer(
            direction: .download,
            name: entry.name,
            remotePath: entry.path,
            detail: "Waiting for server"
        )
        let task = Task {
            defer {
                Task { @MainActor in
                    self.fileTransferTasks[transferId] = nil
                }
            }
            do {
                let download = try downloadDestination(for: entry)
                let destination = download.url
                let seekPosition = download.seekPosition
                await MainActor.run {
                    let progress = entry.size > 0 ? min(1, Double(seekPosition) / Double(entry.size)) : 0
                    self.fileTransferStatus = seekPosition > 0 ? "Resuming download: \(entry.name)" : "Preparing download: \(entry.name)"
                    self.fileTransferProgress = progress
                    self.updateFileTransfer(
                        transferId,
                        progress: progress,
                        state: .preparing,
                        detail: seekPosition > 0 ? Self.transferProgressText(seekPosition, total: entry.size) : "Preparing download",
                        localPath: destination.path
                    )
                }
                let parameters = try await client.initFileDownload(
                    channelId: entry.channelId,
                    path: entry.path,
                    seekPosition: seekPosition,
                    password: self.trimmedFileBrowserPassword
                )
                try await TS3FileTransfer.download(parameters: parameters, to: destination) { received, total in
                    Task { @MainActor in
                        if let total, total > 0 {
                            self.fileTransferProgress = min(1, Double(received) / Double(total))
                        }
                        let detail = Self.transferProgressText(received, total: total)
                        self.fileTransferStatus = "Downloading \(entry.name): \(detail)"
                        self.updateFileTransfer(
                            transferId,
                            progress: total.map { $0 > 0 ? min(1, Double(received) / Double($0)) : 0 },
                            state: .transferring,
                            detail: detail
                        )
                    }
                }
                await MainActor.run {
                    self.fileTransferProgress = 1
                    self.fileTransferStatus = "Downloaded \(entry.name) to \(destination.lastPathComponent)"
                    self.lastDownloadedFile = TS3DownloadedFileSummary(name: destination.lastPathComponent, url: destination)
                    self.updateFileTransfer(
                        transferId,
                        progress: 1,
                        state: .completed,
                        detail: "Saved to \(destination.lastPathComponent)",
                        localPath: destination.path,
                        completedAt: Date()
                    )
                    self.lastError = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.fileTransferProgress = nil
                    self.fileTransferStatus = "Cancelled download: \(entry.name)"
                    self.updateFileTransfer(
                        transferId,
                        state: .cancelled,
                        detail: "Cancelled",
                        completedAt: Date()
                    )
                }
            } catch {
                await MainActor.run {
                    self.fileTransferProgress = nil
                    self.fileTransferStatus = nil
                    if self.fileTransfers.first(where: { $0.id == transferId })?.state == .cancelled {
                        self.updateFileTransfer(
                            transferId,
                            detail: "Cancelled",
                            completedAt: Date()
                        )
                    } else {
                        self.updateFileTransfer(
                            transferId,
                            progress: nil,
                            state: .failed,
                            detail: error.localizedDescription,
                            completedAt: Date()
                        )
                        self.lastError = error.localizedDescription
                    }
                }
            }
        }
        fileTransferTasks[transferId] = task
    }

    func downloadFileEntries(_ entries: [TS3FileEntrySummary]) {
        let files = entries.filter { !$0.isDirectory }
        guard !files.isEmpty else { return }
        for entry in files.sorted(by: fileEntryDownloadSort) {
            downloadFileEntry(entry)
        }
    }

    func openLastDownloadedFile() {
        guard let file = lastDownloadedFile else { return }
        TS3PlatformSupport.openURL(file.url)
    }

    func cancelFileTransfer(_ transfer: TS3FileTransferSummary) {
        guard transfer.canCancel else { return }
        fileTransferTasks[transfer.id]?.cancel()
        updateFileTransfer(
            transfer.id,
            state: .cancelled,
            detail: "Cancelling...",
            completedAt: Date()
        )
    }

    func clearCompletedFileTransfers() {
        fileTransfers.removeAll { !$0.canCancel }
        let activeIds = Set(fileTransfers.map(\.id))
        fileTransferTasks = fileTransferTasks.filter { activeIds.contains($0.key) }
    }

    func uploadFiles(_ sources: [URL], overwrite: Bool = false, resume: Bool = false) {
        guard !sources.isEmpty else { return }
        for source in sources {
            uploadFile(from: source, overwrite: overwrite, resume: resume)
        }
    }

    func uploadFile(from source: URL, overwrite: Bool = false, resume: Bool = false) {
        guard let channelId = fileBrowserChannelId else {
            lastError = "No channel is selected for file browsing."
            return
        }
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        let remoteName = source.lastPathComponent
        let remotePath = joinedFilePath(parentPath: fileBrowserPath, name: remoteName)
        let transferId = addFileTransfer(
            direction: .upload,
            name: remoteName,
            remotePath: remotePath,
            localPath: source.path,
            detail: "Waiting for server"
        )
        let task = Task {
            defer {
                Task { @MainActor in
                    self.fileTransferTasks[transferId] = nil
                }
            }
            let didAccess = source.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    source.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
                let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
                await MainActor.run {
                    self.fileTransferStatus = "Preparing upload: \(remoteName)"
                    self.fileTransferProgress = 0
                    self.updateFileTransfer(
                        transferId,
                        progress: 0,
                        state: .preparing,
                        detail: "Preparing upload"
                    )
                }
                let parameters = try await client.initFileUpload(
                    channelId: channelId,
                    path: remotePath,
                    size: size,
                    overwrite: overwrite,
                    resume: resume,
                    password: self.trimmedFileBrowserPassword
                )
                try await TS3FileTransfer.upload(parameters: parameters, from: source) { sent, total in
                    Task { @MainActor in
                        if let total, total > 0 {
                            self.fileTransferProgress = min(1, Double(sent) / Double(total))
                        }
                        let detail = Self.transferProgressText(sent, total: total)
                        self.fileTransferStatus = "Uploading \(remoteName): \(detail)"
                        self.updateFileTransfer(
                            transferId,
                            progress: total.map { $0 > 0 ? min(1, Double(sent) / Double($0)) : 0 },
                            state: .transferring,
                            detail: detail
                        )
                    }
                }
                await MainActor.run {
                    self.fileTransferProgress = 1
                    self.fileTransferStatus = "Uploaded \(remoteName)"
                    self.updateFileTransfer(
                        transferId,
                        progress: 1,
                        state: .completed,
                        detail: "Uploaded to \(remotePath)",
                        completedAt: Date()
                    )
                    self.lastError = nil
                    self.refreshFileList()
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.fileTransferProgress = nil
                    self.fileTransferStatus = "Cancelled upload: \(remoteName)"
                    self.updateFileTransfer(
                        transferId,
                        state: .cancelled,
                        detail: "Cancelled",
                        completedAt: Date()
                    )
                }
            } catch {
                await MainActor.run {
                    self.fileTransferProgress = nil
                    self.fileTransferStatus = nil
                    if self.fileTransfers.first(where: { $0.id == transferId })?.state == .cancelled {
                        self.updateFileTransfer(
                            transferId,
                            detail: "Cancelled",
                            completedAt: Date()
                        )
                    } else {
                        self.updateFileTransfer(
                            transferId,
                            progress: nil,
                            state: .failed,
                            detail: error.localizedDescription,
                            completedAt: Date()
                        )
                        self.lastError = error.localizedDescription
                    }
                }
            }
        }
        fileTransferTasks[transferId] = task
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

    private var trimmedFileBrowserPassword: String? {
        let password = fileBrowserPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return password.isEmpty ? nil : password
    }

    private func addFileTransfer(
        direction: TS3FileTransferDirection,
        name: String,
        remotePath: String,
        localPath: String? = nil,
        detail: String
    ) -> UUID {
        let id = UUID()
        fileTransfers.insert(
            TS3FileTransferSummary(
                id: id,
                direction: direction,
                name: name,
                remotePath: remotePath,
                localPath: localPath,
                progress: nil,
                state: .preparing,
                detail: detail,
                startedAt: Date(),
                completedAt: nil
            ),
            at: 0
        )
        if fileTransfers.count > 25 {
            let removed = fileTransfers.suffix(fileTransfers.count - 25).map(\.id)
            fileTransfers.removeLast(fileTransfers.count - 25)
            for id in removed {
                fileTransferTasks[id]?.cancel()
                fileTransferTasks[id] = nil
            }
        }
        return id
    }

    private func updateFileTransfer(
        _ id: UUID,
        progress: Double? = nil,
        state: TS3FileTransferState? = nil,
        detail: String? = nil,
        localPath: String? = nil,
        completedAt: Date? = nil
    ) {
        guard let index = fileTransfers.firstIndex(where: { $0.id == id }) else { return }
        if let progress {
            fileTransfers[index].progress = progress
        }
        if let state {
            fileTransfers[index].state = state
        }
        if let detail {
            fileTransfers[index].detail = detail
        }
        if let localPath {
            fileTransfers[index].localPath = localPath
        }
        if let completedAt {
            fileTransfers[index].completedAt = completedAt
        }
    }

    private func fileEntryDownloadSort(_ lhs: TS3FileEntrySummary, _ rhs: TS3FileEntrySummary) -> Bool {
        lhs.path.localizedCaseInsensitiveCompare(rhs.path) == .orderedAscending
    }

    private func downloadDestination(for entry: TS3FileEntrySummary) throws -> (url: URL, seekPosition: Int64) {
        let documents = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = documents.appendingPathComponent("TS3 Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fallbackName = entry.name.isEmpty ? "download" : entry.name
        let baseURL = directory.appendingPathComponent(fallbackName)
        guard FileManager.default.fileExists(atPath: baseURL.path) else {
            return (baseURL, 0)
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: baseURL.path)
        let localSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        if localSize > 0, localSize < entry.size {
            return (baseURL, localSize)
        }
        return (uniqueFileURL(in: directory, named: fallbackName), 0)
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

    func deleteOfflineMessages(_ messages: [TS3OfflineMessageSummary]) {
        let messageIds = Array(Set(messages.map(\.id))).sorted()
        guard !messageIds.isEmpty else { return }
        runClientCommand { client in
            for messageId in messageIds {
                try await client.deleteOfflineMessage(messageId: messageId)
            }
            let refreshedMessages = try await client.refreshOfflineMessages()
            await MainActor.run {
                self.offlineMessages = refreshedMessages.map { TS3OfflineMessageSummary(message: $0) }
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

    func markAllOfflineMessagesRead() {
        let unreadMessages = offlineMessages.filter { !$0.isRead }
        guard !unreadMessages.isEmpty else { return }
        runClientCommand { client in
            for message in unreadMessages {
                try await client.setOfflineMessageRead(messageId: message.id, isRead: true)
            }
            let refreshedMessages = try await client.refreshOfflineMessages()
            await MainActor.run {
                self.offlineMessages = refreshedMessages.map { TS3OfflineMessageSummary(message: $0) }
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

    func sendOfflineMessage(toUniqueIdentifier uniqueIdentifier: String, subject: String, message: String) {
        let uniqueIdentifier = uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uniqueIdentifier.isEmpty, !subject.isEmpty, !message.isEmpty else { return }
        runClientCommand { client in
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

    func clearSelfIcon() {
        runClientCommand { client in
            try await client.setClientIcon(iconId: 0)
        } onSuccess: {
            guard let ownClient = self.clients.first(where: { $0.isCurrentUser }) else { return }
            self.updateUser(clientId: ownClient.id) { existing in
                self.copyUser(existing, iconId: 0, resetIconURL: true)
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

    func uploadSelfAvatar(from source: URL) {
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        guard let ownClient = clients.first(where: { $0.isCurrentUser }) else {
            lastError = "Current client is not available."
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
                var avatarHash = ownClient.avatarHash ?? ""
                if avatarHash.isEmpty,
                   let updated = try await client.refreshClientDetails(clientId: ownClient.id),
                   let updatedHash = updated.avatarHash {
                    avatarHash = updatedHash
                    await MainActor.run {
                        self.updateUser(clientId: ownClient.id) { existing in
                            self.copyUser(existing, avatarHash: updatedHash)
                        }
                    }
                }
                guard !avatarHash.isEmpty else {
                    throw TS3Error.fileTransferFailed
                }

                let data = try Data(contentsOf: source)
                let avatarFlag = Insecure.MD5.hash(data: data)
                    .map { String(format: "%02x", $0) }
                    .joined()
                await MainActor.run {
                    self.fileTransferStatus = "Preparing avatar upload: \(source.lastPathComponent)"
                    self.fileTransferProgress = 0
                }
                let parameters = try await client.initAvatarUpload(hash: avatarHash, size: Int64(data.count))
                try await TS3FileTransfer.upload(parameters: parameters, from: source) { sent, total in
                    Task { @MainActor in
                        if let total, total > 0 {
                            self.fileTransferProgress = min(1, Double(sent) / Double(total))
                        }
                        self.fileTransferStatus = "Uploading avatar: \(Self.transferProgressText(sent, total: total))"
                    }
                }
                try await client.setClientAvatarFlag(avatarFlag)
                let destination = try avatarDestination(for: avatarHash)
                try data.write(to: destination, options: .atomic)
                await MainActor.run {
                    self.updateUser(clientId: ownClient.id) { existing in
                        self.copyUser(existing, avatarHash: avatarHash, avatarURL: destination)
                    }
                    self.fileTransferProgress = 1
                    self.fileTransferStatus = "Uploaded avatar"
                    self.avatarDownloadStatus = nil
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

    func clearSelfAvatar() {
        guard let ownClient = clients.first(where: { $0.isCurrentUser }) else {
            lastError = "Current client is not available."
            return
        }
        runClientCommand { client in
            try await client.setClientAvatarFlag("")
            await MainActor.run {
                self.updateUser(clientId: ownClient.id) { existing in
                    self.copyUser(existing, resetAvatar: true)
                }
                self.avatarDownloadStatus = nil
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

    func deleteChannel(_ channel: TS3ChannelSummary, force: Bool) {
        runClientCommand { client in
            try await client.deleteChannel(channelId: channel.id, force: force)
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
                self.banEntries = self.banEntrySummaries(from: entries)
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
                self.banEntries = self.banEntrySummaries(from: entries)
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

    func deleteBans(_ entries: [TS3BanEntrySummary]) {
        let banIds = Array(Set(entries.map(\.id))).sorted()
        guard !banIds.isEmpty else { return }
        runClientCommand { client in
            for banId in banIds {
                try await client.deleteBan(banId: banId)
            }
            let refreshedEntries = try await client.refreshBanList()
            await MainActor.run {
                self.banEntries = self.banEntrySummaries(from: refreshedEntries)
            }
        }
    }

    private func banEntrySummaries(from entries: [TS3BanEntry]) -> [TS3BanEntrySummary] {
        entries
            .map { TS3BanEntrySummary(entry: $0) }
            .sorted {
                switch ($0.createdAt, $1.createdAt) {
                case let (lhs?, rhs?): return lhs > rhs
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return $0.id > $1.id
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
                self.complaintEntries = self.complaintSummaries(from: entries)
            }
        }
    }

    func banBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snapshot = TS3BanBackup(
            entries: banEntries.map {
                TS3BanBackupEntry(
                    ip: $0.ip,
                    name: $0.name,
                    uniqueIdentifier: $0.uniqueIdentifier,
                    durationSeconds: $0.durationSeconds,
                    reason: $0.reason
                )
            }
        )
        return try encoder.encode(snapshot)
    }

    func importBanBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3BanBackup.self, from: data)
        for entry in decoded.entries {
            addBan(
                ip: entry.ip ?? "",
                name: entry.name ?? "",
                uniqueIdentifier: entry.uniqueIdentifier ?? "",
                durationSeconds: entry.durationSeconds,
                reason: entry.reason ?? ""
            )
        }
        lastError = nil
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

    func deleteComplaints(_ entries: [TS3ComplaintSummary]) {
        let uniqueEntries = Dictionary(grouping: entries, by: \.id).compactMap { $0.value.first }
        guard !uniqueEntries.isEmpty else { return }
        runClientCommand { client in
            for entry in uniqueEntries {
                try await client.deleteComplaint(
                    targetClientDatabaseId: entry.targetClientDatabaseId,
                    sourceClientDatabaseId: entry.sourceClientDatabaseId
                )
            }
            if let target = self.complaintTarget {
                let databaseId = try await self.databaseId(for: target, using: client)
                let refreshedEntries = try await client.refreshComplaints(clientDatabaseId: databaseId)
                await MainActor.run {
                    self.complaintEntries = self.complaintSummaries(from: refreshedEntries)
                }
            } else {
                await MainActor.run {
                    self.complaintEntries = []
                }
            }
        }
    }

    private func complaintSummaries(from entries: [TS3ComplaintEntry]) -> [TS3ComplaintSummary] {
        entries
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
                self.privilegeKeys = self.privilegeKeySummaries(from: keys)
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
                self.privilegeKeys = self.privilegeKeySummaries(from: keys)
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

    func deletePrivilegeKeys(_ keys: [TS3PrivilegeKeySummary]) {
        let rawKeys = Array(Set(keys.map(\.key))).sorted()
        guard !rawKeys.isEmpty else { return }
        runClientCommand { client in
            for key in rawKeys {
                try await client.deletePrivilegeKey(key)
            }
            let refreshedKeys = try await client.refreshPrivilegeKeys()
            await MainActor.run {
                self.privilegeKeys = self.privilegeKeySummaries(from: refreshedKeys)
                if let generatedPrivilegeKey = self.generatedPrivilegeKey, rawKeys.contains(generatedPrivilegeKey) {
                    self.generatedPrivilegeKey = nil
                }
            }
        }
    }

    func privilegeKeyBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snapshot = TS3PrivilegeKeyBackup(
            entries: privilegeKeys.map {
                TS3PrivilegeKeyBackupEntry(
                    key: $0.key,
                    type: $0.type?.rawValue,
                    groupId: $0.groupId,
                    channelId: $0.channelId,
                    createdAt: $0.createdAt,
                    description: $0.description,
                    customSet: $0.customSet
                )
            }
        )
        return try encoder.encode(snapshot)
    }

    func importPrivilegeKeyBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3PrivilegeKeyBackup.self, from: data)
        generatedPrivilegeKey = decoded.entries.first?.key
        lastError = nil
    }

    private func privilegeKeySummaries(from keys: [TS3PrivilegeKeyEntry]) -> [TS3PrivilegeKeySummary] {
        keys
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

    func addServerGroup(_ group: TS3GroupSummary, to user: TS3UserSummary) {
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.addServerGroup(groupId: group.id, toClientDatabaseId: databaseId)
            await MainActor.run {
                self.upsertServerGroup(group.id, forClientId: user.id)
            }
        }
    }

    func addServerGroup(_ group: TS3GroupSummary, to record: TS3DatabaseClientSummary) {
        runClientCommand { client in
            try await client.addServerGroup(groupId: group.id, toClientDatabaseId: record.id)
            await MainActor.run {
                if let onlineClient = self.clients.first(where: { $0.databaseId == record.id }) {
                    self.upsertServerGroup(group.id, forClientId: onlineClient.id)
                }
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

    func removeServerGroup(_ group: TS3GroupSummary, from member: TS3GroupClientSummary) {
        runClientCommand { client in
            try await client.removeServerGroup(groupId: group.id, fromClientDatabaseId: member.clientDatabaseId)
            await MainActor.run {
                self.groupClients.removeAll { $0.id == member.id }
                for onlineClient in self.clients where onlineClient.databaseId == member.clientDatabaseId {
                    self.removeServerGroup(group.id, fromClientId: onlineClient.id)
                }
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

    func setChannelGroup(_ group: TS3GroupSummary, for member: TS3GroupClientSummary) {
        guard let channelId = member.channelId else {
            lastError = "Selected group member has no channel id."
            return
        }
        runClientCommand { client in
            try await client.setChannelGroup(groupId: group.id, channelId: channelId, clientDatabaseId: member.clientDatabaseId)
            await MainActor.run {
                self.groupClients.removeAll { $0.id == member.id }
                for onlineClient in self.clients where onlineClient.databaseId == member.clientDatabaseId && onlineClient.channelId == channelId {
                    self.setChannelGroup(group.id, forClientId: onlineClient.id)
                }
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
        resetAvatar: Bool = false,
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
            avatarHash: resetAvatar ? nil : (avatarHash ?? user.avatarHash),
            avatarURL: resetAvatar ? nil : (avatarURL ?? user.avatarURL),
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

    func regenerateIdentity() {
        guard state == .disconnected else {
            lastError = "Disconnect before replacing your identity."
            return
        }
        Task {
            do {
                let snapshot = try await TS3Client(config: TS3ClientConfig(
                    host: "localhost",
                    port: 9987,
                    nickname: nickname,
                    serverPassword: nil
                )).regenerateIdentity()
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

    private var contactsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-contacts.json")
    }

    private var chatHistoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-chat-history.json")
    }

    private var whisperPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-whisper-presets.json")
    }

    private var audioSettingsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-audio-settings.json")
    }

    private var userPlaybackPreferencesURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-user-playback-preferences.json")
    }

    private var notificationSettingsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-notification-settings.json")
    }

    private var connectionRecoverySettingsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-connection-recovery-settings.json")
    }

    private func loadAudioSettings() {
        guard let data = try? Data(contentsOf: audioSettingsURL),
              let decoded = try? JSONDecoder().decode(TS3AudioSettings.self, from: data) else {
            applyAudioSettingsSnapshot(.defaults)
            return
        }
        applyAudioSettingsSnapshot(decoded)
    }

    private func saveAudioSettings() {
        do {
            let directory = audioSettingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let snapshot = TS3AudioSettings(
                playbackVolume: playbackVolume,
                inputGain: inputGain,
                transmitMode: audioTransmitMode.rawValue,
                voiceActivationThreshold: voiceActivationThreshold
            )
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: audioSettingsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func audioSettingsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snapshot = TS3AudioSettings(
            playbackVolume: playbackVolume,
            inputGain: inputGain,
            transmitMode: audioTransmitMode.rawValue,
            voiceActivationThreshold: voiceActivationThreshold
        )
        return try encoder.encode(snapshot)
    }

    func importAudioSettings(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3AudioSettings.self, from: data)
        applyAudioSettingsSnapshot(decoded)
        saveAudioSettings()
        if let client {
            applyAudioSettings(to: client)
        }
        lastError = nil
    }

    private func applyAudioSettingsSnapshot(_ settings: TS3AudioSettings) {
        playbackVolume = min(max(settings.playbackVolume, 0), 4)
        inputGain = min(max(settings.inputGain, 0), 4)
        audioTransmitMode = TS3AudioTransmitMode(rawValue: settings.transmitMode) ?? .pushToTalk
        voiceActivationThreshold = min(max(settings.voiceActivationThreshold, 0.001), 0.5)
    }

    private func loadUserPlaybackPreferences() {
        guard let data = try? Data(contentsOf: userPlaybackPreferencesURL),
              let decoded = try? JSONDecoder().decode([String: TS3UserPlaybackPreference].self, from: data) else {
            userPlaybackPreferences = [:]
            return
        }
        userPlaybackPreferences = decoded.reduce(into: [:]) { result, item in
            let key = item.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { return }
            let preference = TS3UserPlaybackPreference(
                volume: min(max(item.value.volume, 0), 4),
                isMuted: item.value.isMuted
            )
            if preference.volume != 1 || preference.isMuted {
                result[key] = preference
            }
        }
    }

    private func saveUserPlaybackPreferences() {
        do {
            let directory = userPlaybackPreferencesURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(userPlaybackPreferences)
            try data.write(to: userPlaybackPreferencesURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func loadNotificationSettings() {
        guard let data = try? Data(contentsOf: notificationSettingsURL),
              let decoded = try? JSONDecoder().decode(TS3NotificationSettings.self, from: data) else {
            notificationsEnabled = TS3NotificationSettings.defaults.isEnabled
            return
        }
        notificationsEnabled = decoded.isEnabled
    }

    private func saveNotificationSettings() {
        do {
            let directory = notificationSettingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(TS3NotificationSettings(isEnabled: notificationsEnabled))
            try data.write(to: notificationSettingsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func notificationSettingsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(TS3NotificationSettings(isEnabled: notificationsEnabled))
    }

    func importNotificationSettings(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3NotificationSettings.self, from: data)
        notificationsEnabled = decoded.isEnabled
        saveNotificationSettings()
        lastError = nil
    }

    private func loadConnectionRecoverySettings() {
        guard let data = try? Data(contentsOf: connectionRecoverySettingsURL),
              let decoded = try? JSONDecoder().decode(TS3ConnectionRecoverySettings.self, from: data) else {
            autoReconnectEnabled = TS3ConnectionRecoverySettings.defaults.autoReconnectEnabled
            return
        }
        autoReconnectEnabled = decoded.autoReconnectEnabled
    }

    private func saveConnectionRecoverySettings() {
        do {
            let directory = connectionRecoverySettingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(TS3ConnectionRecoverySettings(autoReconnectEnabled: autoReconnectEnabled))
            try data.write(to: connectionRecoverySettingsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func notifyIfInactive(title: String, body: String, identifier: String) {
        #if canImport(UserNotifications)
        guard notificationsEnabled, !isAppActive else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        ))
        #endif
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

    private func loadContacts() {
        guard let data = try? Data(contentsOf: contactsURL),
              let decoded = try? JSONDecoder().decode([TS3ContactEntry].self, from: data) else {
            contacts = []
            return
        }
        contacts = decoded
    }

    private func saveContacts() {
        do {
            let directory = contactsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(contacts)
            try data.write(to: contactsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func loadWhisperPresets() {
        guard let data = try? Data(contentsOf: whisperPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3WhisperPreset].self, from: data) else {
            whisperPresets = []
            return
        }
        whisperPresets = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func saveWhisperPresets() {
        do {
            let directory = whisperPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(whisperPresets)
            try data.write(to: whisperPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func contactsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(contacts)
    }

    @discardableResult
    func importContacts(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ContactEntry].self, from: data)
        var merged = contacts
        for contact in imported {
            let uniqueIdentifier = contact.uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !uniqueIdentifier.isEmpty else { continue }
            let nickname = contact.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let note = contact.note.trimmingCharacters(in: .whitespacesAndNewlines)
            merged.removeAll { $0.uniqueIdentifier == uniqueIdentifier }
            merged.insert(
                TS3ContactEntry(
                    uniqueIdentifier: uniqueIdentifier,
                    nickname: nickname.isEmpty ? uniqueIdentifier : nickname,
                    status: contact.status,
                    note: note,
                    updatedAt: contact.updatedAt
                ),
                at: 0
            )
        }
        contacts = merged
        saveContacts()
        syncBlockedContactPlayback()
        lastError = nil
        return imported.count
    }

    private func loadChatHistory() {
        guard let data = try? Data(contentsOf: chatHistoryURL),
              let decoded = try? JSONDecoder().decode([TS3ChatMessageSummary].self, from: data) else {
            chatMessages = []
            return
        }
        chatMessages = Array(decoded.suffix(chatHistoryLimit))
    }

    private func saveChatHistory() {
        do {
            let directory = chatHistoryURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(chatMessages.suffix(chatHistoryLimit)))
            try data.write(to: chatHistoryURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearChatHistory() {
        chatMessages = []
        unreadChatMessageCount = 0
        saveChatHistory()
    }

    func chatTranscriptData(messages: [TS3ChatMessageSummary]) -> Data {
        let lines = messages.map { message in
            let mode: String
            switch message.targetMode {
            case .server:
                mode = "Server"
            case .channel:
                mode = "Channel"
            case .client:
                mode = "Private"
            }
            let direction = message.isOwnMessage ? "out" : "in"
            return "\(Self.transcriptDateFormatter.string(from: message.timestamp)) [\(mode)] [\(direction)] \(message.senderName): \(message.message)"
        }
        return Data(lines.joined(separator: "\n").utf8)
    }

    func beginViewingChat() {
        isViewingChat = true
        unreadChatMessageCount = 0
    }

    func endViewingChat() {
        isViewingChat = false
    }

    func markPokesRead() {
        unreadPokeCount = 0
        unreadActivityCount = 0
    }

    func clearEventHistory() {
        pokeEvents = []
        activityEvents = []
        unreadPokeCount = 0
        unreadActivityCount = 0
    }

    func selfStatusBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let snapshot = TS3SelfStatusBackup(
            nickname: nickname,
            description: clients.first(where: { $0.isCurrentUser })?.description ?? "",
            isAway: isAway,
            awayMessage: awayMessage,
            isInputMuted: isInputMuted,
            isOutputMuted: isOutputMuted,
            isChannelCommander: isChannelCommander,
            talkRequestMessage: talkRequestMessage,
            iconId: clients.first(where: { $0.isCurrentUser })?.iconId
        )
        return try encoder.encode(snapshot)
    }

    func importSelfStatusBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3SelfStatusBackup.self, from: data)
        nickname = decoded.nickname
        awayMessage = decoded.awayMessage
        isAway = decoded.isAway
        isInputMuted = decoded.isInputMuted
        isOutputMuted = decoded.isOutputMuted
        isChannelCommander = decoded.isChannelCommander
        talkRequestMessage = decoded.talkRequestMessage
        if let client = clients.first(where: { $0.isCurrentUser }) {
            updateUser(clientId: client.id) { existing in
                self.copyUser(existing, description: decoded.description, iconId: decoded.iconId)
            }
        }
        saveAudioSettings()
        lastError = nil
    }

    func channelName(for id: Int?) -> String? {
        guard let id else { return nil }
        return channels.first { $0.id == id }?.name ?? "Channel \(id)"
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

    func enableWhisperList(channelIds: Set<Int>, clientIds: Set<Int>) {
        let channels = channelIds.sorted()
        let clients = clientIds.sorted()
        guard !channels.isEmpty || !clients.isEmpty else {
            lastError = "Select at least one whisper target."
            return
        }
        whisperRoute = .list(channelIds: channels, clientIds: clients)
        client?.startWhisper(target: .multiple(
            channelIds: channels.map { UInt64(max($0, 0)) },
            clientIds: clients.map { UInt16(max(0, min($0, Int(UInt16.max)))) }
        ))
    }

    func saveWhisperPreset(name: String, channelIds: Set<Int>, clientIds: Set<Int>) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let channels = channelIds.sorted()
        let clients = clientIds.sorted()
        guard !trimmedName.isEmpty else {
            lastError = "Enter a name for the whisper preset."
            return
        }
        guard !channels.isEmpty || !clients.isEmpty else {
            lastError = "Select at least one whisper target."
            return
        }
        whisperPresets.removeAll { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
        whisperPresets.insert(TS3WhisperPreset(
            name: trimmedName,
            channelIds: channels,
            clientIds: clients
        ), at: 0)
        saveWhisperPresets()
        lastError = nil
    }

    func enableWhisperPreset(_ preset: TS3WhisperPreset) {
        enableWhisperList(channelIds: Set(preset.channelIds), clientIds: Set(preset.clientIds))
    }

    func deleteWhisperPreset(_ preset: TS3WhisperPreset) {
        whisperPresets.removeAll { $0.id == preset.id }
        saveWhisperPresets()
    }

    func whisperPresetBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(whisperPresets)
    }

    @discardableResult
    func importWhisperPresetBackup(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3WhisperPreset].self, from: data)
        var merged = whisperPresets
        for preset in imported {
            let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let channelIds = Array(Set(preset.channelIds.filter { $0 > 0 })).sorted()
            let clientIds = Array(Set(preset.clientIds.filter { $0 > 0 })).sorted()
            guard !name.isEmpty, !channelIds.isEmpty || !clientIds.isEmpty else { continue }
            merged.removeAll { $0.name.caseInsensitiveCompare(name) == .orderedSame }
            merged.insert(TS3WhisperPreset(
                id: preset.id,
                name: name,
                channelIds: channelIds,
                clientIds: clientIds,
                updatedAt: preset.updatedAt
            ), at: 0)
        }
        whisperPresets = merged.sorted { $0.updatedAt > $1.updatedAt }
        saveWhisperPresets()
        lastError = nil
        return imported.count
    }

    func enableGroupWhisper(type: TS3GroupWhisperType, target: TS3GroupWhisperTarget, targetId: Int) {
        whisperRoute = .group(type: type, target: target, targetId: targetId)
        client?.startWhisper(target: .group(type: type, target: target, targetId: UInt64(max(targetId, 0))))
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
        case let .list(channelIds, clientIds):
            let channelText = channelIds.count == 1 ? "1 channel" : "\(channelIds.count) channels"
            let clientText = clientIds.count == 1 ? "1 user" : "\(clientIds.count) users"
            if channelIds.isEmpty {
                return "Whisper list: \(clientText)"
            }
            if clientIds.isEmpty {
                return "Whisper list: \(channelText)"
            }
            return "Whisper list: \(channelText), \(clientText)"
        case let .group(type, target, targetId):
            let group = whisperGroupName(type: type, targetId: targetId)
            return "Whisper to \(group) in \(target.title.lowercased())"
        }
    }

    private func whisperGroupName(type: TS3GroupWhisperType, targetId: Int) -> String {
        switch type {
        case .serverGroup:
            return TS3GroupSummary.name(for: targetId, in: serverGroups)
        case .channelGroup:
            return TS3GroupSummary.name(for: targetId, in: channelGroups)
        case .channelCommander:
            return "channel commanders"
        case .allClients:
            return "all clients"
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
        for user in clients {
            let preference = userPlaybackPreference(for: user)
            client.setPlaybackGain(Float(preference.volume), forClientId: user.id)
            client.setPlaybackMuted(preference.isMuted, forClientId: user.id)
        }
        for user in clients where contactStatus(for: user) == .blocked {
            client.setPlaybackMuted(true, forClientId: user.id)
        }
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

    func debugLogData() -> Data {
        let lines = logs.map { entry in
            "\(Self.transcriptDateFormatter.string(from: entry.timestamp)) [\(entry.level.rawValue)] \(entry.message)"
        }
        return Data(lines.joined(separator: "\n").utf8)
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

    private static let transcriptDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
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
            self.cancelReconnectSchedule(resetAttempts: true)
            self.lastDisconnectMessage = nil
            self.state = .connected
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didDisconnectWith error: Error?) {
        Task { @MainActor in
            var reconnectReason: String?
            if let error {
                let message = error.localizedDescription
                self.lastError = message
                self.lastDisconnectMessage = message
                reconnectReason = message
            }
            if self.client === client {
                self.client = nil
            }
            self.clearConnectionState(keepLastConnection: true)
            self.state = .disconnected
            self.scheduleReconnectIfNeeded(reason: reconnectReason)
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
            self.applyOnlineUserPlaybackPreferences()
            self.syncBlockedContactPlayback()
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
            guard !self.isBlockedMessage(message) else { return }
            self.chatMessages.append(TS3ChatMessageSummary(
                id: message.id,
                timestamp: message.timestamp,
                targetMode: message.targetMode,
                targetId: message.targetId,
                senderId: message.senderId,
                senderName: message.senderName,
                message: message.message,
                isOwnMessage: message.isOwnMessage
            ))
            if self.chatMessages.count > self.chatHistoryLimit {
                self.chatMessages.removeFirst(self.chatMessages.count - self.chatHistoryLimit)
            }
            if !message.isOwnMessage && !self.isViewingChat {
                self.unreadChatMessageCount += 1
            }
            if !message.isOwnMessage && message.targetMode == .client {
                self.notifyIfInactive(
                    title: "Private message from \(message.senderName)",
                    body: message.message,
                    identifier: "ts3-private-message-\(message.id.uuidString)"
                )
            }
            self.saveChatHistory()
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didReceiveClientPoke poke: TS3ClientPoke) {
        Task { @MainActor in
            guard !poke.isOwnPoke else { return }
            self.pokeEvents.insert(TS3PokeSummary(poke: poke), at: 0)
            if self.pokeEvents.count > 50 {
                self.pokeEvents.removeLast(self.pokeEvents.count - 50)
            }
            self.unreadPokeCount += 1
            self.notifyIfInactive(
                title: "Poke from \(poke.senderName)",
                body: poke.message,
                identifier: "ts3-poke-\(poke.id.uuidString)"
            )
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didReceiveServerActivity event: TS3ServerActivityEvent) {
        Task { @MainActor in
            guard !event.isOwnClient else { return }
            self.activityEvents.insert(TS3ActivitySummary(event: event), at: 0)
            if self.activityEvents.count > 100 {
                self.activityEvents.removeLast(self.activityEvents.count - 100)
            }
            self.unreadActivityCount += 1
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
