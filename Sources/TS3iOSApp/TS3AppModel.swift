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

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        senderId: Int?,
        senderName: String,
        senderUniqueIdentifier: String?,
        message: String,
        isOwnPoke: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.senderId = senderId
        self.senderName = senderName
        self.senderUniqueIdentifier = senderUniqueIdentifier
        self.message = message
        self.isOwnPoke = isOwnPoke
    }

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

struct TS3ContactFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3UserPlaybackPreference: Codable {
    var volume: Double = 1.0
    var isMuted = false
}

struct TS3UserPlaybackPreferenceSummary: Identifiable {
    let key: String
    let nickname: String?
    let volume: Double
    let isMuted: Bool
    let isOnline: Bool

    var id: String { key }
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

struct TS3SelfStatusBackup: Codable {
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

struct TS3SelfStatusProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var status: TS3SelfStatusBackup
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        status: TS3SelfStatusBackup,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.updatedAt = updatedAt
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

struct TS3FileBrowserBookmark: Identifiable, Codable {
    let id: UUID
    var name: String
    var channelId: Int
    var channelName: String
    var path: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        channelId: Int,
        channelName: String,
        path: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.channelId = channelId
        self.channelName = channelName
        self.path = path
        self.updatedAt = updatedAt
    }
}

struct TS3FileBrowserFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3OfflineMessageFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var readFilter: String
    var contentFilter: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        readFilter: String,
        contentFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.readFilter = readFilter
        self.contentFilter = contentFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3BanFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var banFilter: String
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        banFilter: String,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.banFilter = banFilter
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3ComplaintFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var complaintFilter: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        complaintFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.complaintFilter = complaintFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3DatabaseClientFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var recordFilter: String
    var sortMode: String
    var sortAscending: Bool
    var localFilterText: String
    var batchSize: Int
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        recordFilter: String,
        sortMode: String,
        sortAscending: Bool,
        localFilterText: String,
        batchSize: Int,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.recordFilter = recordFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.localFilterText = localFilterText
        self.batchSize = batchSize
        self.updatedAt = updatedAt
    }
}

struct TS3PrivilegeKeyFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var keyFilter: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        keyFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.keyFilter = keyFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3PermissionFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var scope: String
    var assignedFilter: String
    var assignedSortMode: String
    var assignedSortAscending: Bool
    var assignedSearchText: String
    var permissionSearchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        scope: String,
        assignedFilter: String,
        assignedSortMode: String,
        assignedSortAscending: Bool,
        assignedSearchText: String,
        permissionSearchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.scope = scope
        self.assignedFilter = assignedFilter
        self.assignedSortMode = assignedSortMode
        self.assignedSortAscending = assignedSortAscending
        self.assignedSearchText = assignedSearchText
        self.permissionSearchText = permissionSearchText
        self.updatedAt = updatedAt
    }
}

struct TS3GroupFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var target: String
    var groupTypeFilter: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        target: String,
        groupTypeFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.target = target
        self.groupTypeFilter = groupTypeFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3GroupClientFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var memberFilter: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        memberFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.memberFilter = memberFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
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
    let channelId: Int
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

    var canRetry: Bool {
        state == .cancelled || state == .failed
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
    var prefersSpeakerOutput: Bool

    static let defaults = TS3AudioSettings(
        playbackVolume: 1.0,
        inputGain: 1.0,
        transmitMode: TS3AudioTransmitMode.pushToTalk.rawValue,
        voiceActivationThreshold: 0.03,
        prefersSpeakerOutput: true
    )

    enum CodingKeys: String, CodingKey {
        case playbackVolume
        case inputGain
        case transmitMode
        case voiceActivationThreshold
        case prefersSpeakerOutput
    }

    init(
        playbackVolume: Double,
        inputGain: Double,
        transmitMode: String,
        voiceActivationThreshold: Double,
        prefersSpeakerOutput: Bool
    ) {
        self.playbackVolume = playbackVolume
        self.inputGain = inputGain
        self.transmitMode = transmitMode
        self.voiceActivationThreshold = voiceActivationThreshold
        self.prefersSpeakerOutput = prefersSpeakerOutput
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playbackVolume = try container.decodeIfPresent(Double.self, forKey: .playbackVolume) ?? Self.defaults.playbackVolume
        inputGain = try container.decodeIfPresent(Double.self, forKey: .inputGain) ?? Self.defaults.inputGain
        transmitMode = try container.decodeIfPresent(String.self, forKey: .transmitMode) ?? Self.defaults.transmitMode
        voiceActivationThreshold = try container.decodeIfPresent(Double.self, forKey: .voiceActivationThreshold) ?? Self.defaults.voiceActivationThreshold
        prefersSpeakerOutput = try container.decodeIfPresent(Bool.self, forKey: .prefersSpeakerOutput) ?? Self.defaults.prefersSpeakerOutput
    }
}

struct TS3AudioRouteDeviceSummary: Identifiable, Equatable {
    let id: String
    let name: String
    let type: String
    let isSelected: Bool

    var displayName: String {
        type.isEmpty ? name : "\(name) (\(type))"
    }
}

struct TS3AudioProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var playbackVolume: Double
    var inputGain: Double
    var transmitMode: String
    var voiceActivationThreshold: Double
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        playbackVolume: Double,
        inputGain: Double,
        transmitMode: String,
        voiceActivationThreshold: Double,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.playbackVolume = playbackVolume
        self.inputGain = inputGain
        self.transmitMode = transmitMode
        self.voiceActivationThreshold = voiceActivationThreshold
        self.updatedAt = updatedAt
    }
}

struct TS3KeyboardShortcutBinding: Identifiable, Codable {
    var actionId: String
    var group: String
    var action: String
    var defaultKeys: String
    var keys: String
    var isEnabled: Bool

    var id: String { actionId }

    init(
        actionId: String,
        group: String,
        action: String,
        defaultKeys: String,
        keys: String? = nil,
        isEnabled: Bool = true
    ) {
        self.actionId = actionId
        self.group = group
        self.action = action
        self.defaultKeys = defaultKeys
        self.keys = keys ?? defaultKeys
        self.isEnabled = isEnabled
    }
}

private struct TS3NotificationSettings: Codable {
    var isEnabled: Bool
    var soundEnabled: Bool
    var privateMessagesEnabled: Bool
    var pokesEnabled: Bool
    var activityEnabled: Bool

    static let defaults = TS3NotificationSettings(
        isEnabled: false,
        soundEnabled: true,
        privateMessagesEnabled: true,
        pokesEnabled: true,
        activityEnabled: false
    )

    init(
        isEnabled: Bool,
        soundEnabled: Bool = true,
        privateMessagesEnabled: Bool = true,
        pokesEnabled: Bool = true,
        activityEnabled: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.soundEnabled = soundEnabled
        self.privateMessagesEnabled = privateMessagesEnabled
        self.pokesEnabled = pokesEnabled
        self.activityEnabled = activityEnabled
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case soundEnabled
        case privateMessagesEnabled
        case pokesEnabled
        case activityEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        privateMessagesEnabled = try container.decodeIfPresent(Bool.self, forKey: .privateMessagesEnabled) ?? true
        pokesEnabled = try container.decodeIfPresent(Bool.self, forKey: .pokesEnabled) ?? true
        activityEnabled = try container.decodeIfPresent(Bool.self, forKey: .activityEnabled) ?? false
    }
}

private struct TS3ConnectionRecoverySettings: Codable {
    var autoReconnectEnabled: Bool
    var initialDelaySeconds: Int
    var maxDelaySeconds: Int
    var maxAttempts: Int

    static let defaults = TS3ConnectionRecoverySettings(
        autoReconnectEnabled: false,
        initialDelaySeconds: 3,
        maxDelaySeconds: 30,
        maxAttempts: 0
    )

    init(
        autoReconnectEnabled: Bool,
        initialDelaySeconds: Int = 3,
        maxDelaySeconds: Int = 30,
        maxAttempts: Int = 0
    ) {
        self.autoReconnectEnabled = autoReconnectEnabled
        self.initialDelaySeconds = initialDelaySeconds
        self.maxDelaySeconds = maxDelaySeconds
        self.maxAttempts = maxAttempts
    }

    enum CodingKeys: String, CodingKey {
        case autoReconnectEnabled
        case initialDelaySeconds
        case maxDelaySeconds
        case maxAttempts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        autoReconnectEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoReconnectEnabled) ?? false
        initialDelaySeconds = try container.decodeIfPresent(Int.self, forKey: .initialDelaySeconds) ?? Self.defaults.initialDelaySeconds
        maxDelaySeconds = try container.decodeIfPresent(Int.self, forKey: .maxDelaySeconds) ?? Self.defaults.maxDelaySeconds
        maxAttempts = try container.decodeIfPresent(Int.self, forKey: .maxAttempts) ?? Self.defaults.maxAttempts
    }
}

private struct TS3ClientMigrationPackage: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var bookmarks: [TS3BookmarkSummary]
    var recentConnections: [TS3ConnectionSnapshot]
    var connectionFilterPresets: [TS3ConnectionFilterPreset]
    var contacts: [TS3ContactEntry]
    var contactFilterPresets: [TS3ContactFilterPreset]
    var notificationSettings: TS3NotificationSettings
    var connectionRecoverySettings: TS3ConnectionRecoverySettings
    var serverLogQueryPresets: [TS3ServerLogQueryPreset]
    var keyboardShortcuts: [TS3KeyboardShortcutBinding]
    var channelSubscriptionPresets: [TS3ChannelSubscriptionPreset]
    var channelTreeFilterPresets: [TS3ChannelTreeFilterPreset]
    var eventFilterPresets: [TS3EventFilterPreset]
    var chatFilterPresets: [TS3ChatFilterPreset]
    var fileBrowserBookmarks: [TS3FileBrowserBookmark]
    var fileBrowserFilterPresets: [TS3FileBrowserFilterPreset]
    var offlineMessageFilterPresets: [TS3OfflineMessageFilterPreset]
    var banFilterPresets: [TS3BanFilterPreset]
    var complaintFilterPresets: [TS3ComplaintFilterPreset]
    var databaseClientFilterPresets: [TS3DatabaseClientFilterPreset]
    var privilegeKeyFilterPresets: [TS3PrivilegeKeyFilterPreset]
    var permissionFilterPresets: [TS3PermissionFilterPreset]
    var groupFilterPresets: [TS3GroupFilterPreset]
    var groupClientFilterPresets: [TS3GroupClientFilterPreset]
    var audioSettings: TS3AudioSettings
    var audioProfiles: [TS3AudioProfile]
    var userPlaybackPreferences: [String: TS3UserPlaybackPreference]
    var selfStatus: TS3SelfStatusBackup
    var selfStatusProfiles: [TS3SelfStatusProfile]
    var whisperPresets: [TS3WhisperPreset]
    var whisperFilterPresets: [TS3WhisperFilterPreset]

    init(
        schemaVersion: Int = 1,
        exportedAt: Date = Date(),
        bookmarks: [TS3BookmarkSummary],
        recentConnections: [TS3ConnectionSnapshot],
        connectionFilterPresets: [TS3ConnectionFilterPreset],
        contacts: [TS3ContactEntry],
        contactFilterPresets: [TS3ContactFilterPreset],
        notificationSettings: TS3NotificationSettings,
        connectionRecoverySettings: TS3ConnectionRecoverySettings,
        serverLogQueryPresets: [TS3ServerLogQueryPreset],
        keyboardShortcuts: [TS3KeyboardShortcutBinding],
        channelSubscriptionPresets: [TS3ChannelSubscriptionPreset],
        channelTreeFilterPresets: [TS3ChannelTreeFilterPreset],
        eventFilterPresets: [TS3EventFilterPreset],
        chatFilterPresets: [TS3ChatFilterPreset],
        fileBrowserBookmarks: [TS3FileBrowserBookmark],
        fileBrowserFilterPresets: [TS3FileBrowserFilterPreset],
        offlineMessageFilterPresets: [TS3OfflineMessageFilterPreset],
        banFilterPresets: [TS3BanFilterPreset],
        complaintFilterPresets: [TS3ComplaintFilterPreset],
        databaseClientFilterPresets: [TS3DatabaseClientFilterPreset],
        privilegeKeyFilterPresets: [TS3PrivilegeKeyFilterPreset],
        permissionFilterPresets: [TS3PermissionFilterPreset],
        groupFilterPresets: [TS3GroupFilterPreset],
        groupClientFilterPresets: [TS3GroupClientFilterPreset],
        audioSettings: TS3AudioSettings,
        audioProfiles: [TS3AudioProfile],
        userPlaybackPreferences: [String: TS3UserPlaybackPreference],
        selfStatus: TS3SelfStatusBackup,
        selfStatusProfiles: [TS3SelfStatusProfile],
        whisperPresets: [TS3WhisperPreset],
        whisperFilterPresets: [TS3WhisperFilterPreset]
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.bookmarks = bookmarks
        self.recentConnections = recentConnections
        self.connectionFilterPresets = connectionFilterPresets
        self.contacts = contacts
        self.contactFilterPresets = contactFilterPresets
        self.notificationSettings = notificationSettings
        self.connectionRecoverySettings = connectionRecoverySettings
        self.serverLogQueryPresets = serverLogQueryPresets
        self.keyboardShortcuts = keyboardShortcuts
        self.channelSubscriptionPresets = channelSubscriptionPresets
        self.channelTreeFilterPresets = channelTreeFilterPresets
        self.eventFilterPresets = eventFilterPresets
        self.chatFilterPresets = chatFilterPresets
        self.fileBrowserBookmarks = fileBrowserBookmarks
        self.fileBrowserFilterPresets = fileBrowserFilterPresets
        self.offlineMessageFilterPresets = offlineMessageFilterPresets
        self.banFilterPresets = banFilterPresets
        self.complaintFilterPresets = complaintFilterPresets
        self.databaseClientFilterPresets = databaseClientFilterPresets
        self.privilegeKeyFilterPresets = privilegeKeyFilterPresets
        self.permissionFilterPresets = permissionFilterPresets
        self.groupFilterPresets = groupFilterPresets
        self.groupClientFilterPresets = groupClientFilterPresets
        self.audioSettings = audioSettings
        self.audioProfiles = audioProfiles
        self.userPlaybackPreferences = userPlaybackPreferences
        self.selfStatus = selfStatus
        self.selfStatusProfiles = selfStatusProfiles
        self.whisperPresets = whisperPresets
        self.whisperFilterPresets = whisperFilterPresets
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case exportedAt
        case bookmarks
        case recentConnections
        case connectionFilterPresets
        case contacts
        case contactFilterPresets
        case notificationSettings
        case connectionRecoverySettings
        case serverLogQueryPresets
        case keyboardShortcuts
        case channelSubscriptionPresets
        case channelTreeFilterPresets
        case eventFilterPresets
        case chatFilterPresets
        case fileBrowserBookmarks
        case fileBrowserFilterPresets
        case offlineMessageFilterPresets
        case banFilterPresets
        case complaintFilterPresets
        case databaseClientFilterPresets
        case privilegeKeyFilterPresets
        case permissionFilterPresets
        case groupFilterPresets
        case groupClientFilterPresets
        case audioSettings
        case audioProfiles
        case userPlaybackPreferences
        case selfStatus
        case selfStatusProfiles
        case whisperPresets
        case whisperFilterPresets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        exportedAt = try container.decodeIfPresent(Date.self, forKey: .exportedAt) ?? Date()
        bookmarks = try container.decodeIfPresent([TS3BookmarkSummary].self, forKey: .bookmarks) ?? []
        recentConnections = try container.decodeIfPresent([TS3ConnectionSnapshot].self, forKey: .recentConnections) ?? []
        connectionFilterPresets = try container.decodeIfPresent(
            [TS3ConnectionFilterPreset].self,
            forKey: .connectionFilterPresets
        ) ?? []
        contacts = try container.decodeIfPresent([TS3ContactEntry].self, forKey: .contacts) ?? []
        contactFilterPresets = try container.decodeIfPresent(
            [TS3ContactFilterPreset].self,
            forKey: .contactFilterPresets
        ) ?? []
        notificationSettings = try container.decodeIfPresent(TS3NotificationSettings.self, forKey: .notificationSettings) ?? .defaults
        connectionRecoverySettings = try container.decodeIfPresent(
            TS3ConnectionRecoverySettings.self,
            forKey: .connectionRecoverySettings
        ) ?? .defaults
        serverLogQueryPresets = try container.decodeIfPresent(
            [TS3ServerLogQueryPreset].self,
            forKey: .serverLogQueryPresets
        ) ?? []
        keyboardShortcuts = try container.decodeIfPresent(
            [TS3KeyboardShortcutBinding].self,
            forKey: .keyboardShortcuts
        ) ?? []
        channelSubscriptionPresets = try container.decodeIfPresent(
            [TS3ChannelSubscriptionPreset].self,
            forKey: .channelSubscriptionPresets
        ) ?? []
        channelTreeFilterPresets = try container.decodeIfPresent(
            [TS3ChannelTreeFilterPreset].self,
            forKey: .channelTreeFilterPresets
        ) ?? []
        eventFilterPresets = try container.decodeIfPresent(
            [TS3EventFilterPreset].self,
            forKey: .eventFilterPresets
        ) ?? []
        chatFilterPresets = try container.decodeIfPresent(
            [TS3ChatFilterPreset].self,
            forKey: .chatFilterPresets
        ) ?? []
        fileBrowserBookmarks = try container.decodeIfPresent(
            [TS3FileBrowserBookmark].self,
            forKey: .fileBrowserBookmarks
        ) ?? []
        fileBrowserFilterPresets = try container.decodeIfPresent(
            [TS3FileBrowserFilterPreset].self,
            forKey: .fileBrowserFilterPresets
        ) ?? []
        offlineMessageFilterPresets = try container.decodeIfPresent(
            [TS3OfflineMessageFilterPreset].self,
            forKey: .offlineMessageFilterPresets
        ) ?? []
        banFilterPresets = try container.decodeIfPresent(
            [TS3BanFilterPreset].self,
            forKey: .banFilterPresets
        ) ?? []
        complaintFilterPresets = try container.decodeIfPresent(
            [TS3ComplaintFilterPreset].self,
            forKey: .complaintFilterPresets
        ) ?? []
        databaseClientFilterPresets = try container.decodeIfPresent(
            [TS3DatabaseClientFilterPreset].self,
            forKey: .databaseClientFilterPresets
        ) ?? []
        privilegeKeyFilterPresets = try container.decodeIfPresent(
            [TS3PrivilegeKeyFilterPreset].self,
            forKey: .privilegeKeyFilterPresets
        ) ?? []
        permissionFilterPresets = try container.decodeIfPresent(
            [TS3PermissionFilterPreset].self,
            forKey: .permissionFilterPresets
        ) ?? []
        groupFilterPresets = try container.decodeIfPresent(
            [TS3GroupFilterPreset].self,
            forKey: .groupFilterPresets
        ) ?? []
        groupClientFilterPresets = try container.decodeIfPresent(
            [TS3GroupClientFilterPreset].self,
            forKey: .groupClientFilterPresets
        ) ?? []
        audioSettings = try container.decodeIfPresent(TS3AudioSettings.self, forKey: .audioSettings) ?? .defaults
        audioProfiles = try container.decodeIfPresent([TS3AudioProfile].self, forKey: .audioProfiles) ?? []
        userPlaybackPreferences = try container.decodeIfPresent(
            [String: TS3UserPlaybackPreference].self,
            forKey: .userPlaybackPreferences
        ) ?? [:]
        selfStatus = try container.decodeIfPresent(TS3SelfStatusBackup.self, forKey: .selfStatus) ?? TS3SelfStatusBackup(
            nickname: "",
            description: "",
            isAway: false,
            awayMessage: "",
            isInputMuted: false,
            isOutputMuted: false,
            isChannelCommander: false,
            talkRequestMessage: "",
            iconId: nil
        )
        selfStatusProfiles = try container.decodeIfPresent([TS3SelfStatusProfile].self, forKey: .selfStatusProfiles) ?? []
        whisperPresets = try container.decodeIfPresent([TS3WhisperPreset].self, forKey: .whisperPresets) ?? []
        whisperFilterPresets = try container.decodeIfPresent(
            [TS3WhisperFilterPreset].self,
            forKey: .whisperFilterPresets
        ) ?? []
    }
}

struct TS3BookmarkSummary: Identifiable, Codable {
    let id: UUID
    var name: String
    var folder: String
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
        folder: String = "",
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
        self.folder = folder
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
        case folder
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
        folder = try container.decodeIfPresent(String.self, forKey: .folder) ?? ""
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(String.self, forKey: .port)
        nickname = try container.decode(String.self, forKey: .nickname)
        serverPassword = try container.decode(String.self, forKey: .serverPassword)
        defaultChannel = try container.decode(String.self, forKey: .defaultChannel)
        defaultChannelPassword = try container.decode(String.self, forKey: .defaultChannelPassword)
        privilegeKey = try container.decodeIfPresent(String.self, forKey: .privilegeKey) ?? ""
    }
}

struct TS3ConnectionFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var connectionFilter: String
    var sortMode: String
    var sortAscending: Bool
    var bookmarkFolderFilter: String
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        connectionFilter: String,
        sortMode: String,
        sortAscending: Bool,
        bookmarkFolderFilter: String,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.connectionFilter = connectionFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.bookmarkFolderFilter = bookmarkFolderFilter
        self.searchText = searchText
        self.updatedAt = updatedAt
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

    var snapshotText: String {
        [
            "Identity UID: \(uid.isEmpty ? "Unavailable" : uid)",
            "Security Level: \(securityLevel)",
            "Key Offset: \(keyOffset)",
            "Backup Available: \(exportString.isEmpty ? "No" : "Yes")",
            "Backup Length: \(exportString.count)"
        ].joined(separator: "\n")
    }

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

struct TS3ConnectionInfoSummary {
    var ping: Double?
    var packetLossTotal: Double?
    var packetLossSpeech: Double?
    var packetLossKeepalive: Double?
    var packetLossControl: Double?
    var bytesReceived: Int64?
    var bytesSent: Int64?
    var monthlyBytesReceived: Int64?
    var monthlyBytesSent: Int64?
    var totalBytesReceived: Int64?
    var totalBytesSent: Int64?
    var connectedSeconds: Int?
    var idleSeconds: Int?

    static let empty = TS3ConnectionInfoSummary()

    init(
        ping: Double? = nil,
        packetLossTotal: Double? = nil,
        packetLossSpeech: Double? = nil,
        packetLossKeepalive: Double? = nil,
        packetLossControl: Double? = nil,
        bytesReceived: Int64? = nil,
        bytesSent: Int64? = nil,
        monthlyBytesReceived: Int64? = nil,
        monthlyBytesSent: Int64? = nil,
        totalBytesReceived: Int64? = nil,
        totalBytesSent: Int64? = nil,
        connectedSeconds: Int? = nil,
        idleSeconds: Int? = nil
    ) {
        self.ping = ping
        self.packetLossTotal = packetLossTotal
        self.packetLossSpeech = packetLossSpeech
        self.packetLossKeepalive = packetLossKeepalive
        self.packetLossControl = packetLossControl
        self.bytesReceived = bytesReceived
        self.bytesSent = bytesSent
        self.monthlyBytesReceived = monthlyBytesReceived
        self.monthlyBytesSent = monthlyBytesSent
        self.totalBytesReceived = totalBytesReceived
        self.totalBytesSent = totalBytesSent
        self.connectedSeconds = connectedSeconds
        self.idleSeconds = idleSeconds
    }

    init(info: TS3ConnectionInfo) {
        self.init(
            ping: info.ping,
            packetLossTotal: info.packetLossTotal,
            packetLossSpeech: info.packetLossSpeech,
            packetLossKeepalive: info.packetLossKeepalive,
            packetLossControl: info.packetLossControl,
            bytesReceived: info.bytesReceived,
            bytesSent: info.bytesSent,
            monthlyBytesReceived: info.monthlyBytesReceived,
            monthlyBytesSent: info.monthlyBytesSent,
            totalBytesReceived: info.totalBytesReceived,
            totalBytesSent: info.totalBytesSent,
            connectedSeconds: info.connectedSeconds,
            idleSeconds: info.idleSeconds
        )
    }
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

struct TS3ServerLogQueryPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var limit: Int
    var reverse: Bool
    var instance: Bool
    var levelFilter: String
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        limit: Int,
        reverse: Bool,
        instance: Bool,
        levelFilter: String,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.limit = limit
        self.reverse = reverse
        self.instance = instance
        self.levelFilter = levelFilter
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3ChannelSubscriptionPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var channelIds: [Int]
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        channelIds: [Int],
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.channelIds = channelIds
        self.updatedAt = updatedAt
    }
}

struct TS3ChannelTreeFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var treeFilter: String
    var sortMode: String
    var sortAscending: Bool
    var memberSortMode: String
    var memberSortAscending: Bool
    var currentUserFirst: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        treeFilter: String,
        sortMode: String = "serverOrder",
        sortAscending: Bool = true,
        memberSortMode: String = "nickname",
        memberSortAscending: Bool = true,
        currentUserFirst: Bool = true,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.treeFilter = treeFilter
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.memberSortMode = memberSortMode
        self.memberSortAscending = memberSortAscending
        self.currentUserFirst = currentUserFirst
        self.searchText = searchText
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case treeFilter
        case sortMode
        case sortAscending
        case memberSortMode
        case memberSortAscending
        case currentUserFirst
        case searchText
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        treeFilter = try container.decode(String.self, forKey: .treeFilter)
        sortMode = try container.decodeIfPresent(String.self, forKey: .sortMode) ?? "serverOrder"
        sortAscending = try container.decodeIfPresent(Bool.self, forKey: .sortAscending) ?? true
        memberSortMode = try container.decodeIfPresent(String.self, forKey: .memberSortMode) ?? "nickname"
        memberSortAscending = try container.decodeIfPresent(Bool.self, forKey: .memberSortAscending) ?? true
        currentUserFirst = try container.decodeIfPresent(Bool.self, forKey: .currentUserFirst) ?? true
        searchText = try container.decodeIfPresent(String.self, forKey: .searchText) ?? ""
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct TS3EventFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var eventFilter: String
    var sourceFilter: String
    var newestFirst: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        eventFilter: String,
        sourceFilter: String,
        newestFirst: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.eventFilter = eventFilter
        self.sourceFilter = sourceFilter
        self.newestFirst = newestFirst
        self.searchText = searchText
        self.updatedAt = updatedAt
    }
}

struct TS3ChatFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var messageFilter: String
    var senderFilter: String
    var newestFirst: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        messageFilter: String,
        senderFilter: String,
        newestFirst: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.messageFilter = messageFilter
        self.senderFilter = senderFilter
        self.newestFirst = newestFirst
        self.searchText = searchText
        self.updatedAt = updatedAt
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

struct TS3WhisperFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var presetFilter: String
    var presetSort: String
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        presetFilter: String,
        presetSort: String,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.presetFilter = presetFilter
        self.presetSort = presetSort
        self.searchText = searchText
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
    static let defaultKeyboardShortcuts: [TS3KeyboardShortcutBinding] = [
        TS3KeyboardShortcutBinding(actionId: "show-shortcuts", group: "Global", action: "Show Keyboard Shortcuts", defaultKeys: "Command-/"),
        TS3KeyboardShortcutBinding(actionId: "show-debug-log", group: "Global", action: "Show Debug Log", defaultKeys: "Command-Shift-L"),
        TS3KeyboardShortcutBinding(actionId: "toggle-talk", group: "Voice", action: "Talk / Stop Talking", defaultKeys: "Command-T"),
        TS3KeyboardShortcutBinding(actionId: "toggle-input-muted", group: "Voice", action: "Mute / Unmute Microphone", defaultKeys: "Command-Shift-M"),
        TS3KeyboardShortcutBinding(actionId: "toggle-output-muted", group: "Voice", action: "Mute / Unmute Sound", defaultKeys: "Command-Shift-S"),
        TS3KeyboardShortcutBinding(actionId: "toggle-away", group: "Profile", action: "Set / Clear Away", defaultKeys: "Command-Shift-A"),
        TS3KeyboardShortcutBinding(actionId: "apply-nickname", group: "Profile", action: "Apply Nickname", defaultKeys: "Command-Return"),
        TS3KeyboardShortcutBinding(actionId: "refresh-server", group: "Server", action: "Refresh Channels and Clients", defaultKeys: "Command-Shift-R"),
        TS3KeyboardShortcutBinding(actionId: "view-server-logs", group: "Server", action: "View Server Logs", defaultKeys: "Command-Shift-G"),
        TS3KeyboardShortcutBinding(actionId: "manage-contacts", group: "Server", action: "Manage Contacts", defaultKeys: "Command-Shift-C")
    ]

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
    @Published private(set) var serverLogQueryPresets: [TS3ServerLogQueryPreset] = []
    @Published private(set) var channelSubscriptionPresets: [TS3ChannelSubscriptionPreset] = []
    @Published private(set) var channelTreeFilterPresets: [TS3ChannelTreeFilterPreset] = []
    @Published private(set) var eventFilterPresets: [TS3EventFilterPreset] = []
    @Published private(set) var chatFilterPresets: [TS3ChatFilterPreset] = []
    @Published private(set) var banFilterPresets: [TS3BanFilterPreset] = []
    @Published private(set) var complaintFilterPresets: [TS3ComplaintFilterPreset] = []
    @Published private(set) var databaseClientFilterPresets: [TS3DatabaseClientFilterPreset] = []
    @Published private(set) var privilegeKeyFilterPresets: [TS3PrivilegeKeyFilterPreset] = []
    @Published private(set) var permissionFilterPresets: [TS3PermissionFilterPreset] = []
    @Published private(set) var groupFilterPresets: [TS3GroupFilterPreset] = []
    @Published private(set) var groupClientFilterPresets: [TS3GroupClientFilterPreset] = []
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
    @Published private(set) var fileBrowserBookmarks: [TS3FileBrowserBookmark] = []
    @Published private(set) var fileBrowserFilterPresets: [TS3FileBrowserFilterPreset] = []
    @Published private(set) var offlineMessageFilterPresets: [TS3OfflineMessageFilterPreset] = []
    @Published var lastDownloadedFile: TS3DownloadedFileSummary?
    @Published var bookmarks: [TS3BookmarkSummary] = []
    @Published var contacts: [TS3ContactEntry] = []
    @Published private(set) var contactFilterPresets: [TS3ContactFilterPreset] = []
    @Published var identitySummary: TS3IdentitySummary = .empty
    @Published var serverInfo: TS3ServerInfoSummary = .empty
    @Published var connectionInfo: TS3ConnectionInfoSummary = .empty
    @Published var isTalking = false
    @Published var isAway = false
    @Published var isInputMuted = false
    @Published var isOutputMuted = false
    @Published var isChannelCommander = false
    @Published var isRequestingTalkPower = false
    @Published var talkRequestMessage = ""
    @Published var whisperRoute: TS3WhisperRoute = .none
    @Published private(set) var whisperPresets: [TS3WhisperPreset] = []
    @Published private(set) var whisperFilterPresets: [TS3WhisperFilterPreset] = []
    @Published var logs: [TS3LogEntry] = []
    @Published var isShowingDebug = false
    @Published var lastError: String?
    @Published var avatarDownloadStatus: String?
    @Published var playbackVolume: Double = 1.0
    @Published var userPlaybackPreferences: [String: TS3UserPlaybackPreference] = [:]
    @Published var inputGain: Double = 1.0
    @Published var audioTransmitMode: TS3AudioTransmitMode = .pushToTalk
    @Published var voiceActivationThreshold: Double = 0.03
    @Published var prefersSpeakerOutput = true
    @Published private(set) var audioInputDevices: [TS3AudioRouteDeviceSummary] = []
    @Published private(set) var audioInputRoute = "System Default"
    @Published private(set) var audioOutputRoute = "System Default"
    @Published private(set) var audioProfiles: [TS3AudioProfile] = []
    @Published private(set) var keyboardShortcuts: [TS3KeyboardShortcutBinding] = TS3AppModel.defaultKeyboardShortcuts
    @Published var microphonePermissionPrompt: MicrophonePermissionPrompt?
    @Published private(set) var notificationsEnabled = false
    @Published var notificationSoundEnabled = TS3NotificationSettings.defaults.soundEnabled
    @Published var privateMessageNotificationsEnabled = TS3NotificationSettings.defaults.privateMessagesEnabled
    @Published var pokeNotificationsEnabled = TS3NotificationSettings.defaults.pokesEnabled
    @Published var activityNotificationsEnabled = TS3NotificationSettings.defaults.activityEnabled
    @Published private(set) var autoReconnectEnabled = false
    @Published var autoReconnectInitialDelaySeconds = TS3ConnectionRecoverySettings.defaults.initialDelaySeconds
    @Published var autoReconnectMaxDelaySeconds = TS3ConnectionRecoverySettings.defaults.maxDelaySeconds
    @Published var autoReconnectMaxAttempts = TS3ConnectionRecoverySettings.defaults.maxAttempts
    @Published private(set) var autoReconnectIsScheduled = false
    @Published private(set) var autoReconnectStatus: String?

    @Published var serverHost = ""
    @Published var serverPort = "9987"
    @Published var serverPassword = ""
    @Published var defaultChannel = ""
    @Published var defaultChannelPassword = ""
    @Published var privilegeKey = ""
    @Published var nickname = TS3PlatformSupport.defaultNickname
    @Published var awayMessage = ""
    @Published private(set) var selfStatusProfiles: [TS3SelfStatusProfile] = []
    @Published private(set) var recentConnections: [TS3ConnectionSnapshot] = []
    @Published private(set) var connectionFilterPresets: [TS3ConnectionFilterPreset] = []
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
        loadAudioProfiles()
        loadKeyboardShortcuts()
        loadNotificationSettings()
        loadConnectionRecoverySettings()
        loadUserPlaybackPreferences()
        loadBookmarks()
        loadRecentConnections()
        loadConnectionFilterPresets()
        loadServerLogQueryPresets()
        loadChannelSubscriptionPresets()
        loadChannelTreeFilterPresets()
        loadEventFilterPresets()
        loadChatFilterPresets()
        loadBanFilterPresets()
        loadComplaintFilterPresets()
        loadDatabaseClientFilterPresets()
        loadPrivilegeKeyFilterPresets()
        loadPermissionFilterPresets()
        loadGroupFilterPresets()
        loadGroupClientFilterPresets()
        loadContacts()
        loadContactFilterPresets()
        loadChatHistory()
        loadFileBrowserBookmarks()
        loadFileBrowserFilterPresets()
        loadOfflineMessageFilterPresets()
        loadWhisperPresets()
        loadWhisperFilterPresets()
        loadSelfStatusProfiles()
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

    var userPlaybackPreferenceSummaries: [TS3UserPlaybackPreferenceSummary] {
        userPlaybackPreferences.map { key, preference in
            let user = clients.first { userPlaybackPreferenceKey(for: $0) == key }
            return TS3UserPlaybackPreferenceSummary(
                key: key,
                nickname: user?.nickname,
                volume: preference.volume,
                isMuted: preference.isMuted,
                isOnline: user != nil
            )
        }
        .sorted { lhs, rhs in
            if lhs.isOnline != rhs.isOnline {
                return lhs.isOnline && !rhs.isOnline
            }
            let lhsName = lhs.nickname ?? lhs.key
            let rhsName = rhs.nickname ?? rhs.key
            return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
        }
    }

    func resetUserPlaybackPreferences() {
        userPlaybackPreferences = [:]
        saveUserPlaybackPreferences()
        applyOnlineUserPlaybackPreferences()
        syncBlockedContactPlayback()
    }

    func userPlaybackPreferencesExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(userPlaybackPreferences)
    }

    func importUserPlaybackPreferences(from data: Data) throws {
        let decoded = try JSONDecoder().decode([String: TS3UserPlaybackPreference].self, from: data)
        userPlaybackPreferences = sanitizedUserPlaybackPreferences(decoded)
        saveUserPlaybackPreferences()
        applyOnlineUserPlaybackPreferences()
        syncBlockedContactPlayback()
        lastError = nil
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

    func updateContacts(_ entries: [TS3ContactEntry], status: TS3ContactStatus) {
        let uniqueEntries = Dictionary(grouping: entries, by: \.uniqueIdentifier).compactMap { $0.value.first }
        guard !uniqueEntries.isEmpty else { return }
        let now = Date()
        for entry in uniqueEntries {
            let note = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
            if status == .neutral && note.isEmpty {
                contacts.removeAll { $0.uniqueIdentifier == entry.uniqueIdentifier }
            } else if let index = contacts.firstIndex(where: { $0.uniqueIdentifier == entry.uniqueIdentifier }) {
                contacts[index].status = status
                contacts[index].note = note
                contacts[index].updatedAt = now
            } else {
                contacts.append(TS3ContactEntry(
                    uniqueIdentifier: entry.uniqueIdentifier,
                    nickname: entry.nickname,
                    status: status,
                    note: note,
                    updatedAt: now
                ))
            }
        }
        saveContacts()
        syncBlockedContactPlayback()
        lastError = nil
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

    private func isBlockedPoke(_ poke: TS3ClientPoke) -> Bool {
        guard !poke.isOwnPoke else { return false }
        if let uniqueIdentifier = poke.senderUniqueIdentifier,
           contacts.first(where: { $0.uniqueIdentifier == uniqueIdentifier })?.status == .blocked {
            return true
        }
        guard let senderId = poke.senderId,
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

    func deleteRecentConnections(_ snapshots: [TS3ConnectionSnapshot]) {
        let ids = Set(snapshots.map(\.id))
        guard !ids.isEmpty else { return }
        recentConnections.removeAll { ids.contains($0.id) }
        saveRecentConnections()
    }

    func clearRecentConnections() {
        recentConnections = []
        saveRecentConnections()
    }

    func recentConnectionsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(recentConnections)
    }

    @discardableResult
    func importRecentConnections(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ConnectionSnapshot].self, from: data)
        var merged = recentConnections
        for snapshot in imported.reversed() {
            let host = snapshot.host.trimmingCharacters(in: .whitespacesAndNewlines)
            let port = snapshot.port.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !host.isEmpty, !port.isEmpty else { continue }
            let normalized = TS3ConnectionSnapshot(
                id: snapshot.id,
                host: host,
                port: port,
                nickname: snapshot.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                serverPassword: snapshot.serverPassword,
                defaultChannel: snapshot.defaultChannel,
                defaultChannelPassword: snapshot.defaultChannelPassword,
                privilegeKey: snapshot.privilegeKey
            )
            merged.removeAll {
                $0.host.caseInsensitiveCompare(host) == .orderedSame && $0.port == port
            }
            merged.insert(normalized, at: 0)
        }
        recentConnections = Array(merged.prefix(12))
        saveRecentConnections()
        lastError = nil
        return imported.count
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
            serverPassword: nil,
            defaultChannel: defaultChannel,
            defaultChannelPassword: nil,
            privilegeKey: nil,
            includingSecrets: false
        ) else {
            lastError = "Current server is not a valid TeamSpeak invite link."
            return
        }
        TS3PlatformSupport.copyToPasteboard(link)
        lastError = nil
    }

    func copyCurrentFullInviteLink() {
        guard let link = inviteLink(
            name: serverHost,
            host: serverHost,
            port: serverPort,
            nickname: nickname,
            serverPassword: serverPassword,
            defaultChannel: defaultChannel,
            defaultChannelPassword: defaultChannelPassword,
            privilegeKey: privilegeKey,
            includingSecrets: true
        ) else {
            lastError = "Current server is not a valid TeamSpeak invite link."
            return
        }
        TS3PlatformSupport.copyToPasteboard(link)
        lastError = nil
    }

    func copyCurrentConnectionSummary() {
        let snapshot = currentConnectionSnapshot()
        let rows = [
            "Server: \(snapshot.host.isEmpty ? "Not set" : snapshot.host)",
            "Port: \(snapshot.port.isEmpty ? "9987" : snapshot.port)",
            "Nickname: \(snapshot.nickname.isEmpty ? "Not set" : snapshot.nickname)",
            "Default Channel: \(snapshot.defaultChannel.isEmpty ? "None" : snapshot.defaultChannel)",
            "Server Password: \(snapshot.serverPassword.isEmpty ? "No" : "Configured")",
            "Channel Password: \(snapshot.defaultChannelPassword.isEmpty ? "No" : "Configured")",
            "Privilege Key: \(snapshot.privilegeKey.isEmpty ? "No" : "Configured")"
        ]
        TS3PlatformSupport.copyToPasteboard(rows.joined(separator: "\n"))
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
            serverPassword: nil,
            defaultChannel: channelPath,
            defaultChannelPassword: nil,
            privilegeKey: nil,
            includingSecrets: false
        ) else {
            lastError = "Current channel is not a valid TeamSpeak invite link."
            return
        }
        TS3PlatformSupport.copyToPasteboard(link)
        lastError = nil
    }

    func copyFullInviteLink(for channel: TS3ChannelSummary, channelPassword: String = "") {
        let channelPath = channelPath(for: channel)
        let name = "\(serverHost) - \(channel.name)"
        guard let link = inviteLink(
            name: name,
            host: serverHost,
            port: serverPort,
            nickname: nickname,
            serverPassword: serverPassword,
            defaultChannel: channelPath,
            defaultChannelPassword: channelPassword,
            privilegeKey: privilegeKey,
            includingSecrets: true
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
            serverPassword: nil,
            defaultChannel: bookmark.defaultChannel,
            defaultChannelPassword: nil,
            privilegeKey: nil,
            includingSecrets: false
        ) else {
            lastError = "Bookmark is not a valid TeamSpeak invite link."
            return
        }
        TS3PlatformSupport.copyToPasteboard(link)
        lastError = nil
    }

    func copyFullInviteLink(for bookmark: TS3BookmarkSummary) {
        guard let link = inviteLink(
            name: bookmark.name,
            host: bookmark.host,
            port: bookmark.port,
            nickname: bookmark.nickname,
            serverPassword: bookmark.serverPassword,
            defaultChannel: bookmark.defaultChannel,
            defaultChannelPassword: bookmark.defaultChannelPassword,
            privilegeKey: bookmark.privilegeKey,
            includingSecrets: true
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

    func saveCurrentBookmark(name: String, folder: String = "") {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedName.isEmpty ? serverHost : trimmedName
        let folder = folder.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !serverHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let bookmark = TS3BookmarkSummary(
            name: title,
            folder: folder,
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

    func saveBookmarks(from snapshots: [TS3ConnectionSnapshot], folder: String = "") {
        let folder = folder.trimmingCharacters(in: .whitespacesAndNewlines)
        var merged = bookmarks
        for snapshot in snapshots.reversed() {
            let host = snapshot.host.trimmingCharacters(in: .whitespacesAndNewlines)
            let port = snapshot.port.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !host.isEmpty, !port.isEmpty else { continue }
            let bookmark = TS3BookmarkSummary(
                name: host,
                folder: folder,
                host: host,
                port: port,
                nickname: snapshot.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                serverPassword: snapshot.serverPassword,
                defaultChannel: snapshot.defaultChannel,
                defaultChannelPassword: snapshot.defaultChannelPassword,
                privilegeKey: snapshot.privilegeKey
            )
            merged.removeAll {
                $0.host.caseInsensitiveCompare(bookmark.host) == .orderedSame && $0.port == bookmark.port
            }
            merged.insert(bookmark, at: 0)
        }
        bookmarks = merged
        saveBookmarks()
    }

    private func inviteLink(
        name: String,
        host: String,
        port: String,
        nickname: String,
        serverPassword: String?,
        defaultChannel: String,
        defaultChannelPassword: String?,
        privilegeKey: String?,
        includingSecrets: Bool
    ) -> String? {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { return nil }
        let trimmedPort = port.trimmingCharacters(in: .whitespacesAndNewlines)
        let serverURL = TS3ServerURL(
            host: trimmedHost,
            port: Int(trimmedPort),
            nickname: nickname,
            serverPassword: serverPassword,
            defaultChannel: defaultChannel,
            defaultChannelPassword: defaultChannelPassword,
            privilegeKey: privilegeKey,
            bookmarkName: name
        )
        return serverURL.url(includingSecrets: includingSecrets)?.absoluteString
    }

    func updateBookmark(_ bookmark: TS3BookmarkSummary) {
        let trimmedName = bookmark.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHost = bookmark.host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedHost.isEmpty else { return }
        var updated = bookmark
        updated.name = trimmedName
        updated.folder = bookmark.folder.trimmingCharacters(in: .whitespacesAndNewlines)
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

    func deleteBookmarks(_ entries: [TS3BookmarkSummary]) {
        let ids = Set(entries.map(\.id))
        guard !ids.isEmpty else { return }
        bookmarks.removeAll { ids.contains($0.id) }
        saveBookmarks()
    }

    func moveBookmarks(_ entries: [TS3BookmarkSummary], toFolder folder: String) {
        let ids = Set(entries.map(\.id))
        guard !ids.isEmpty else { return }
        let folder = folder.trimmingCharacters(in: .whitespacesAndNewlines)
        for index in bookmarks.indices where ids.contains(bookmarks[index].id) {
            bookmarks[index].folder = folder
        }
        saveBookmarks()
    }

    func bookmarksExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(bookmarks)
    }

    func saveConnectionFilterPreset(
        name: String,
        connectionFilter: String,
        sortMode: String,
        sortAscending: Bool,
        bookmarkFolderFilter: String,
        searchText: String
    ) {
        let preset = sanitizedConnectionFilterPreset(TS3ConnectionFilterPreset(
            name: name,
            connectionFilter: connectionFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            bookmarkFolderFilter: bookmarkFolderFilter,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the connection filter preset."
            return
        }
        connectionFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        connectionFilterPresets.insert(preset, at: 0)
        connectionFilterPresets = sanitizedConnectionFilterPresets(connectionFilterPresets)
        saveConnectionFilterPresets()
        lastError = nil
    }

    func deleteConnectionFilterPreset(_ preset: TS3ConnectionFilterPreset) {
        connectionFilterPresets.removeAll { $0.id == preset.id }
        saveConnectionFilterPresets()
    }

    func connectionFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(connectionFilterPresets)
    }

    @discardableResult
    func importConnectionFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ConnectionFilterPreset].self, from: data)
        var merged = connectionFilterPresets
        for preset in sanitizedConnectionFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        connectionFilterPresets = sanitizedConnectionFilterPresets(merged)
        saveConnectionFilterPresets()
        lastError = nil
        return imported.count
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
            normalized.folder = bookmark.folder.trimmingCharacters(in: .whitespacesAndNewlines)
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
        if autoReconnectMaxAttempts > 0, reconnectAttempt >= autoReconnectMaxAttempts {
            autoReconnectStatus = "Reconnect stopped after \(autoReconnectMaxAttempts) attempt\(autoReconnectMaxAttempts == 1 ? "" : "s")"
            return
        }
        reconnectAttempt += 1
        let delaySeconds = min(
            autoReconnectMaxDelaySeconds,
            max(autoReconnectInitialDelaySeconds, reconnectAttempt * autoReconnectInitialDelaySeconds)
        )
        let attemptText = autoReconnectMaxAttempts > 0
            ? "\(reconnectAttempt)/\(autoReconnectMaxAttempts)"
            : "\(reconnectAttempt)"
        autoReconnectStatus = "Reconnect attempt \(attemptText) in \(delaySeconds)s"
        autoReconnectIsScheduled = true
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
        autoReconnectIsScheduled = false
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
        connectionInfo = .empty
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

    func updatePrefersSpeakerOutput(_ prefersSpeaker: Bool) {
        prefersSpeakerOutput = prefersSpeaker
        client?.setPrefersSpeakerOutput(prefersSpeaker)
        applyAudioRoutePreference()
        saveAudioSettings()
    }

    func refreshAudioRoutes() {
        #if targetEnvironment(macCatalyst) || os(iOS)
        let session = AVAudioSession.sharedInstance()
        let inputs = session.availableInputs ?? []
        let selectedInputId = session.preferredInput?.uid ?? session.currentRoute.inputs.first?.uid
        audioInputDevices = inputs.map { input in
            TS3AudioRouteDeviceSummary(
                id: input.uid,
                name: input.portName,
                type: input.portType.rawValue,
                isSelected: input.uid == selectedInputId
            )
        }
        audioInputRoute = routeText(for: session.currentRoute.inputs)
        audioOutputRoute = routeText(for: session.currentRoute.outputs)
        #else
        audioInputDevices = []
        audioInputRoute = "System Default"
        audioOutputRoute = "System Default"
        #endif
    }

    func selectAudioInputDevice(id: String?) {
        #if targetEnvironment(macCatalyst) || os(iOS)
        let session = AVAudioSession.sharedInstance()
        let input = session.availableInputs?.first { $0.uid == id }
        do {
            try session.setPreferredInput(input)
            refreshAudioRoutes()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
            refreshAudioRoutes()
        }
        #else
        _ = id
        #endif
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
        applyAudioRoutePreference()
        saveAudioSettings()
    }

    func resetAudioSettings() {
        let defaults = TS3AudioSettings.defaults
        playbackVolume = defaults.playbackVolume
        inputGain = defaults.inputGain
        audioTransmitMode = TS3AudioTransmitMode(rawValue: defaults.transmitMode) ?? .pushToTalk
        voiceActivationThreshold = defaults.voiceActivationThreshold
        prefersSpeakerOutput = defaults.prefersSpeakerOutput
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
        }
        if let client {
            applyAudioSettings(to: client)
        }
        applyAudioRoutePreference()
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

    func setPrivateMessageNotificationsEnabled(_ isEnabled: Bool) {
        privateMessageNotificationsEnabled = isEnabled
        saveNotificationSettings()
    }

    func setNotificationSoundEnabled(_ isEnabled: Bool) {
        notificationSoundEnabled = isEnabled
        saveNotificationSettings()
    }

    func setPokeNotificationsEnabled(_ isEnabled: Bool) {
        pokeNotificationsEnabled = isEnabled
        saveNotificationSettings()
    }

    func setActivityNotificationsEnabled(_ isEnabled: Bool) {
        activityNotificationsEnabled = isEnabled
        saveNotificationSettings()
    }

    func applyDirectNotificationPreset(soundEnabled: Bool = true) {
        notificationSoundEnabled = soundEnabled
        privateMessageNotificationsEnabled = true
        pokeNotificationsEnabled = true
        activityNotificationsEnabled = false
        saveNotificationSettings()
        lastError = nil
    }

    func applyAllEventsNotificationPreset() {
        notificationSoundEnabled = true
        privateMessageNotificationsEnabled = true
        pokeNotificationsEnabled = true
        activityNotificationsEnabled = true
        saveNotificationSettings()
        lastError = nil
    }

    func resetNotificationSettings() {
        notificationsEnabled = TS3NotificationSettings.defaults.isEnabled
        notificationSoundEnabled = TS3NotificationSettings.defaults.soundEnabled
        privateMessageNotificationsEnabled = TS3NotificationSettings.defaults.privateMessagesEnabled
        pokeNotificationsEnabled = TS3NotificationSettings.defaults.pokesEnabled
        activityNotificationsEnabled = TS3NotificationSettings.defaults.activityEnabled
        saveNotificationSettings()
        lastError = nil
    }

    func setAutoReconnectEnabled(_ isEnabled: Bool) {
        autoReconnectEnabled = isEnabled
        saveConnectionRecoverySettings()
        if !isEnabled {
            cancelReconnectSchedule(resetAttempts: true)
        }
    }

    func cancelScheduledReconnect() {
        cancelReconnectSchedule(resetAttempts: true)
        autoReconnectStatus = "Scheduled reconnect canceled"
    }

    func updateConnectionRecoveryPolicy(
        initialDelaySeconds: Int,
        maxDelaySeconds: Int,
        maxAttempts: Int
    ) {
        let sanitized = sanitizedConnectionRecoverySettings(TS3ConnectionRecoverySettings(
            autoReconnectEnabled: autoReconnectEnabled,
            initialDelaySeconds: initialDelaySeconds,
            maxDelaySeconds: maxDelaySeconds,
            maxAttempts: maxAttempts
        ))
        autoReconnectInitialDelaySeconds = sanitized.initialDelaySeconds
        autoReconnectMaxDelaySeconds = sanitized.maxDelaySeconds
        autoReconnectMaxAttempts = sanitized.maxAttempts
        saveConnectionRecoverySettings()
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

    func refreshConnectionInfo() {
        runClientCommand { client in
            let info = try await client.requestConnectionInfo()
            await MainActor.run {
                self.connectionInfo = info.map(TS3ConnectionInfoSummary.init(info:)) ?? .empty
            }
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
        refreshConnectionInfo()
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

    func clearServerLogResults() {
        serverLogEntries = []
    }

    func clearServerLogResults(_ entries: [TS3ServerLogSummary]) {
        let ids = Set(entries.map(\.id))
        guard !ids.isEmpty else { return }
        serverLogEntries.removeAll { ids.contains($0.id) }
    }

    func saveServerLogQueryPreset(
        name: String,
        limit: Int,
        reverse: Bool,
        instance: Bool,
        levelFilter: String,
        searchText: String
    ) {
        let preset = sanitizedServerLogQueryPreset(TS3ServerLogQueryPreset(
            name: name,
            limit: limit,
            reverse: reverse,
            instance: instance,
            levelFilter: levelFilter,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the log query preset."
            return
        }
        serverLogQueryPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        serverLogQueryPresets.insert(preset, at: 0)
        serverLogQueryPresets = sanitizedServerLogQueryPresets(serverLogQueryPresets)
        saveServerLogQueryPresets()
        lastError = nil
    }

    func deleteServerLogQueryPreset(_ preset: TS3ServerLogQueryPreset) {
        serverLogQueryPresets.removeAll { $0.id == preset.id }
        saveServerLogQueryPresets()
    }

    func deleteAllServerLogQueryPresets() {
        guard !serverLogQueryPresets.isEmpty else { return }
        serverLogQueryPresets = []
        saveServerLogQueryPresets()
    }

    func serverLogQueryPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(serverLogQueryPresets)
    }

    @discardableResult
    func importServerLogQueryPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ServerLogQueryPreset].self, from: data)
        var merged = serverLogQueryPresets
        for preset in sanitizedServerLogQueryPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        serverLogQueryPresets = sanitizedServerLogQueryPresets(merged)
        saveServerLogQueryPresets()
        lastError = nil
        return imported.count
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
            channelId: entry.channelId,
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

    func cancelActiveFileTransfers() {
        let activeTransfers = fileTransfers.filter(\.canCancel)
        guard !activeTransfers.isEmpty else { return }
        for transfer in activeTransfers {
            fileTransferTasks[transfer.id]?.cancel()
            updateFileTransfer(
                transfer.id,
                state: .cancelled,
                detail: "Cancelling...",
                completedAt: Date()
            )
        }
    }

    func clearCompletedFileTransfers() {
        clearInactiveFileTransfers()
    }

    func clearSuccessfulFileTransfers() {
        removeInactiveFileTransfers { $0.state == .completed }
    }

    func clearFailedFileTransfers() {
        removeInactiveFileTransfers { $0.state == .failed || $0.state == .cancelled }
    }

    func clearInactiveFileTransfers() {
        removeInactiveFileTransfers { !$0.canCancel }
    }

    private func removeInactiveFileTransfers(where shouldRemove: (TS3FileTransferSummary) -> Bool) {
        fileTransfers.removeAll { transfer in
            !transfer.canCancel && shouldRemove(transfer)
        }
        let activeIds = Set(fileTransfers.map(\.id))
        fileTransferTasks = fileTransferTasks.filter { activeIds.contains($0.key) }
    }

    func removeFileTransfer(_ transfer: TS3FileTransferSummary) {
        guard !transfer.canCancel else { return }
        fileTransfers.removeAll { $0.id == transfer.id }
        fileTransferTasks[transfer.id] = nil
    }

    func retryFailedFileTransfers() {
        let retryableTransfers = fileTransfers.filter(\.canRetry)
        guard !retryableTransfers.isEmpty else { return }
        for transfer in retryableTransfers {
            retryFileTransfer(transfer)
        }
    }

    func retryFileTransfer(_ transfer: TS3FileTransferSummary) {
        guard transfer.canRetry else { return }
        switch transfer.direction {
        case .download:
            guard let entry = fileEntries.first(where: {
                $0.channelId == transfer.channelId && $0.path == transfer.remotePath && !$0.isDirectory
            }) else {
                lastError = "Refresh the file list before retrying this download."
                return
            }
            downloadFileEntry(entry)
        case .upload:
            guard let localPath = transfer.localPath, !localPath.isEmpty else {
                lastError = "This upload has no local file path to retry."
                return
            }
            uploadFile(
                from: URL(fileURLWithPath: localPath),
                resume: true,
                channelId: transfer.channelId,
                remotePath: transfer.remotePath
            )
        }
    }

    func uploadFiles(_ sources: [URL], overwrite: Bool = false, resume: Bool = false) {
        guard !sources.isEmpty else { return }
        for source in sources {
            uploadFile(from: source, overwrite: overwrite, resume: resume)
        }
    }

    func uploadFile(
        from source: URL,
        overwrite: Bool = false,
        resume: Bool = false,
        channelId targetChannelId: Int? = nil,
        remotePath targetRemotePath: String? = nil
    ) {
        guard let channelId = targetChannelId ?? fileBrowserChannelId else {
            lastError = "No channel is selected for file browsing."
            return
        }
        guard let client else {
            lastError = "Connect to a server first."
            return
        }
        let remoteName = source.lastPathComponent
        let remotePath = targetRemotePath ?? joinedFilePath(parentPath: fileBrowserPath, name: remoteName)
        let transferId = addFileTransfer(
            direction: .upload,
            channelId: channelId,
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
        channelId: Int,
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
                channelId: channelId,
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

    func sendChannelMessage(_ text: String, to channel: TS3ChannelSummary) {
        sendMessage(text, targetMode: .channel, targetId: channel.id)
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

    func loadOfflineMessageBodies(_ messages: [TS3OfflineMessageSummary]) {
        let messageIds = Array(Set(messages
            .filter { $0.message?.isEmpty != false }
            .map(\.id)
        )).sorted()
        guard !messageIds.isEmpty else { return }
        runClientCommand { client in
            var detailedMessages: [TS3OfflineMessage] = []
            for messageId in messageIds {
                if let detailed = try await client.offlineMessage(messageId: messageId) {
                    detailedMessages.append(detailed)
                }
            }
            await MainActor.run {
                for detailed in detailedMessages {
                    let existing = self.offlineMessages.first { $0.id == detailed.id }
                    self.upsertOfflineMessage(TS3OfflineMessageSummary(
                        message: detailed,
                        isReadOverride: existing?.isRead
                    ))
                }
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

    func markOfflineMessages(_ messages: [TS3OfflineMessageSummary], read: Bool) {
        let targets = messages.filter { $0.isRead != read }
        guard !targets.isEmpty else { return }
        runClientCommand { client in
            for message in targets {
                try await client.setOfflineMessageRead(messageId: message.id, isRead: read)
            }
            let refreshedMessages = try await client.refreshOfflineMessages()
            await MainActor.run {
                self.offlineMessages = refreshedMessages.map { TS3OfflineMessageSummary(message: $0) }
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

    func setChannelsSubscribed(_ channels: [TS3ChannelSummary], isSubscribed: Bool) {
        let channelIds = Array(Set(channels.map(\.id))).sorted()
        guard !channelIds.isEmpty else { return }
        runClientCommand { client in
            for channelId in channelIds {
                try await client.setChannelSubscribed(channelId: channelId, isSubscribed: isSubscribed)
            }
        }
    }

    func saveCurrentChannelSubscriptionPreset(name: String) {
        let preset = sanitizedChannelSubscriptionPreset(TS3ChannelSubscriptionPreset(
            name: name,
            channelIds: channels.filter { $0.isSubscribed == true }.map(\.id)
        ))
        guard let preset else {
            lastError = "Enter a name for the subscription preset."
            return
        }
        channelSubscriptionPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        channelSubscriptionPresets.insert(preset, at: 0)
        channelSubscriptionPresets = sanitizedChannelSubscriptionPresets(channelSubscriptionPresets)
        saveChannelSubscriptionPresets()
        lastError = nil
    }

    func applyChannelSubscriptionPreset(_ preset: TS3ChannelSubscriptionPreset) {
        let channelIds = Array(Set(preset.channelIds.filter { id in
            channels.contains { $0.id == id }
        })).sorted()
        runClientCommand { client in
            try await client.setAllChannelsSubscribed(false)
            for channelId in channelIds {
                try await client.setChannelSubscribed(channelId: channelId, isSubscribed: true)
            }
        }
    }

    func deleteChannelSubscriptionPreset(_ preset: TS3ChannelSubscriptionPreset) {
        channelSubscriptionPresets.removeAll { $0.id == preset.id }
        saveChannelSubscriptionPresets()
    }

    func channelSubscriptionPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(channelSubscriptionPresets)
    }

    @discardableResult
    func importChannelSubscriptionPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ChannelSubscriptionPreset].self, from: data)
        var merged = channelSubscriptionPresets
        for preset in sanitizedChannelSubscriptionPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        channelSubscriptionPresets = sanitizedChannelSubscriptionPresets(merged)
        saveChannelSubscriptionPresets()
        lastError = nil
        return imported.count
    }

    func saveChannelTreeFilterPreset(
        name: String,
        treeFilter: String,
        sortMode: String,
        sortAscending: Bool,
        memberSortMode: String,
        memberSortAscending: Bool,
        currentUserFirst: Bool,
        searchText: String
    ) {
        let preset = sanitizedChannelTreeFilterPreset(TS3ChannelTreeFilterPreset(
            name: name,
            treeFilter: treeFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            memberSortMode: memberSortMode,
            memberSortAscending: memberSortAscending,
            currentUserFirst: currentUserFirst,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the channel tree filter preset."
            return
        }
        channelTreeFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        channelTreeFilterPresets.insert(preset, at: 0)
        channelTreeFilterPresets = sanitizedChannelTreeFilterPresets(channelTreeFilterPresets)
        saveChannelTreeFilterPresets()
        lastError = nil
    }

    func deleteChannelTreeFilterPreset(_ preset: TS3ChannelTreeFilterPreset) {
        channelTreeFilterPresets.removeAll { $0.id == preset.id }
        saveChannelTreeFilterPresets()
    }

    func channelTreeFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(channelTreeFilterPresets)
    }

    @discardableResult
    func importChannelTreeFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ChannelTreeFilterPreset].self, from: data)
        var merged = channelTreeFilterPresets
        for preset in sanitizedChannelTreeFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        channelTreeFilterPresets = sanitizedChannelTreeFilterPresets(merged)
        saveChannelTreeFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveEventFilterPreset(name: String, eventFilter: String, sourceFilter: String, newestFirst: Bool, searchText: String) {
        let preset = sanitizedEventFilterPreset(TS3EventFilterPreset(
            name: name,
            eventFilter: eventFilter,
            sourceFilter: sourceFilter,
            newestFirst: newestFirst,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the event filter preset."
            return
        }
        eventFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        eventFilterPresets.insert(preset, at: 0)
        eventFilterPresets = sanitizedEventFilterPresets(eventFilterPresets)
        saveEventFilterPresets()
        lastError = nil
    }

    func deleteEventFilterPreset(_ preset: TS3EventFilterPreset) {
        eventFilterPresets.removeAll { $0.id == preset.id }
        saveEventFilterPresets()
    }

    func eventFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(eventFilterPresets)
    }

    @discardableResult
    func importEventFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3EventFilterPreset].self, from: data)
        var merged = eventFilterPresets
        for preset in sanitizedEventFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        eventFilterPresets = sanitizedEventFilterPresets(merged)
        saveEventFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveChatFilterPreset(name: String, messageFilter: String, senderFilter: String, newestFirst: Bool, searchText: String) {
        let preset = sanitizedChatFilterPreset(TS3ChatFilterPreset(
            name: name,
            messageFilter: messageFilter,
            senderFilter: senderFilter,
            newestFirst: newestFirst,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the chat filter preset."
            return
        }
        chatFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        chatFilterPresets.insert(preset, at: 0)
        chatFilterPresets = sanitizedChatFilterPresets(chatFilterPresets)
        saveChatFilterPresets()
        lastError = nil
    }

    func deleteChatFilterPreset(_ preset: TS3ChatFilterPreset) {
        chatFilterPresets.removeAll { $0.id == preset.id }
        saveChatFilterPresets()
    }

    func chatFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(chatFilterPresets)
    }

    @discardableResult
    func importChatFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ChatFilterPreset].self, from: data)
        var merged = chatFilterPresets
        for preset in sanitizedChatFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        chatFilterPresets = sanitizedChatFilterPresets(merged)
        saveChatFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveCurrentFileBrowserBookmark(name: String) {
        guard let channelId = fileBrowserChannelId else {
            lastError = "No channel is selected for file browsing."
            return
        }
        let channelName = channels.first { $0.id == channelId }?.name ?? "Channel \(channelId)"
        let bookmark = sanitizedFileBrowserBookmark(TS3FileBrowserBookmark(
            name: name,
            channelId: channelId,
            channelName: channelName,
            path: fileBrowserPath
        ))
        guard let bookmark else {
            lastError = "Enter a name for the file bookmark."
            return
        }
        fileBrowserBookmarks.removeAll { $0.name.caseInsensitiveCompare(bookmark.name) == .orderedSame }
        fileBrowserBookmarks.insert(bookmark, at: 0)
        fileBrowserBookmarks = sanitizedFileBrowserBookmarks(fileBrowserBookmarks)
        saveFileBrowserBookmarks()
        lastError = nil
    }

    func applyFileBrowserBookmark(_ bookmark: TS3FileBrowserBookmark) {
        let sanitized = sanitizedFileBrowserBookmark(bookmark) ?? bookmark
        fileBrowserChannelId = sanitized.channelId
        fileBrowserPath = sanitized.path
        refreshFileList()
    }

    func deleteFileBrowserBookmark(_ bookmark: TS3FileBrowserBookmark) {
        fileBrowserBookmarks.removeAll { $0.id == bookmark.id }
        saveFileBrowserBookmarks()
    }

    func fileBrowserBookmarksExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(fileBrowserBookmarks)
    }

    @discardableResult
    func importFileBrowserBookmarks(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3FileBrowserBookmark].self, from: data)
        var merged = fileBrowserBookmarks
        for bookmark in sanitizedFileBrowserBookmarks(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(bookmark.name) == .orderedSame }
            merged.insert(bookmark, at: 0)
        }
        fileBrowserBookmarks = sanitizedFileBrowserBookmarks(merged)
        saveFileBrowserBookmarks()
        lastError = nil
        return imported.count
    }

    func saveFileBrowserFilterPreset(
        name: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedFileBrowserFilterPreset(TS3FileBrowserFilterPreset(
            name: name,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the file filter preset."
            return
        }
        fileBrowserFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        fileBrowserFilterPresets.insert(preset, at: 0)
        fileBrowserFilterPresets = sanitizedFileBrowserFilterPresets(fileBrowserFilterPresets)
        saveFileBrowserFilterPresets()
        lastError = nil
    }

    func deleteFileBrowserFilterPreset(_ preset: TS3FileBrowserFilterPreset) {
        fileBrowserFilterPresets.removeAll { $0.id == preset.id }
        saveFileBrowserFilterPresets()
    }

    func fileBrowserFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(fileBrowserFilterPresets)
    }

    @discardableResult
    func importFileBrowserFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3FileBrowserFilterPreset].self, from: data)
        var merged = fileBrowserFilterPresets
        for preset in sanitizedFileBrowserFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        fileBrowserFilterPresets = sanitizedFileBrowserFilterPresets(merged)
        saveFileBrowserFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveOfflineMessageFilterPreset(
        name: String,
        readFilter: String,
        contentFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedOfflineMessageFilterPreset(TS3OfflineMessageFilterPreset(
            name: name,
            readFilter: readFilter,
            contentFilter: contentFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the offline message filter preset."
            return
        }
        offlineMessageFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        offlineMessageFilterPresets.insert(preset, at: 0)
        offlineMessageFilterPresets = sanitizedOfflineMessageFilterPresets(offlineMessageFilterPresets)
        saveOfflineMessageFilterPresets()
        lastError = nil
    }

    func deleteOfflineMessageFilterPreset(_ preset: TS3OfflineMessageFilterPreset) {
        offlineMessageFilterPresets.removeAll { $0.id == preset.id }
        saveOfflineMessageFilterPresets()
    }

    func offlineMessageFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(offlineMessageFilterPresets)
    }

    @discardableResult
    func importOfflineMessageFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3OfflineMessageFilterPreset].self, from: data)
        var merged = offlineMessageFilterPresets
        for preset in sanitizedOfflineMessageFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        offlineMessageFilterPresets = sanitizedOfflineMessageFilterPresets(merged)
        saveOfflineMessageFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveBanFilterPreset(name: String, banFilter: String, searchText: String) {
        let preset = sanitizedBanFilterPreset(TS3BanFilterPreset(
            name: name,
            banFilter: banFilter,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the ban filter preset."
            return
        }
        banFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        banFilterPresets.insert(preset, at: 0)
        banFilterPresets = sanitizedBanFilterPresets(banFilterPresets)
        saveBanFilterPresets()
        lastError = nil
    }

    func deleteBanFilterPreset(_ preset: TS3BanFilterPreset) {
        banFilterPresets.removeAll { $0.id == preset.id }
        saveBanFilterPresets()
    }

    func banFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(banFilterPresets)
    }

    @discardableResult
    func importBanFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3BanFilterPreset].self, from: data)
        var merged = banFilterPresets
        for preset in sanitizedBanFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        banFilterPresets = sanitizedBanFilterPresets(merged)
        saveBanFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveComplaintFilterPreset(
        name: String,
        complaintFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedComplaintFilterPreset(TS3ComplaintFilterPreset(
            name: name,
            complaintFilter: complaintFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the complaint filter preset."
            return
        }
        complaintFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        complaintFilterPresets.insert(preset, at: 0)
        complaintFilterPresets = sanitizedComplaintFilterPresets(complaintFilterPresets)
        saveComplaintFilterPresets()
        lastError = nil
    }

    func deleteComplaintFilterPreset(_ preset: TS3ComplaintFilterPreset) {
        complaintFilterPresets.removeAll { $0.id == preset.id }
        saveComplaintFilterPresets()
    }

    func complaintFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(complaintFilterPresets)
    }

    @discardableResult
    func importComplaintFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ComplaintFilterPreset].self, from: data)
        var merged = complaintFilterPresets
        for preset in sanitizedComplaintFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        complaintFilterPresets = sanitizedComplaintFilterPresets(merged)
        saveComplaintFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveDatabaseClientFilterPreset(
        name: String,
        recordFilter: String,
        sortMode: String,
        sortAscending: Bool,
        localFilterText: String,
        batchSize: Int
    ) {
        let preset = sanitizedDatabaseClientFilterPreset(TS3DatabaseClientFilterPreset(
            name: name,
            recordFilter: recordFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            localFilterText: localFilterText,
            batchSize: batchSize
        ))
        guard let preset else {
            lastError = "Enter a name for the database filter preset."
            return
        }
        databaseClientFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        databaseClientFilterPresets.insert(preset, at: 0)
        databaseClientFilterPresets = sanitizedDatabaseClientFilterPresets(databaseClientFilterPresets)
        saveDatabaseClientFilterPresets()
        lastError = nil
    }

    func deleteDatabaseClientFilterPreset(_ preset: TS3DatabaseClientFilterPreset) {
        databaseClientFilterPresets.removeAll { $0.id == preset.id }
        saveDatabaseClientFilterPresets()
    }

    func databaseClientFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(databaseClientFilterPresets)
    }

    @discardableResult
    func importDatabaseClientFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3DatabaseClientFilterPreset].self, from: data)
        var merged = databaseClientFilterPresets
        for preset in sanitizedDatabaseClientFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        databaseClientFilterPresets = sanitizedDatabaseClientFilterPresets(merged)
        saveDatabaseClientFilterPresets()
        lastError = nil
        return imported.count
    }

    func savePrivilegeKeyFilterPreset(
        name: String,
        keyFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedPrivilegeKeyFilterPreset(TS3PrivilegeKeyFilterPreset(
            name: name,
            keyFilter: keyFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the privilege key filter preset."
            return
        }
        privilegeKeyFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        privilegeKeyFilterPresets.insert(preset, at: 0)
        privilegeKeyFilterPresets = sanitizedPrivilegeKeyFilterPresets(privilegeKeyFilterPresets)
        savePrivilegeKeyFilterPresets()
        lastError = nil
    }

    func deletePrivilegeKeyFilterPreset(_ preset: TS3PrivilegeKeyFilterPreset) {
        privilegeKeyFilterPresets.removeAll { $0.id == preset.id }
        savePrivilegeKeyFilterPresets()
    }

    func privilegeKeyFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(privilegeKeyFilterPresets)
    }

    @discardableResult
    func importPrivilegeKeyFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3PrivilegeKeyFilterPreset].self, from: data)
        var merged = privilegeKeyFilterPresets
        for preset in sanitizedPrivilegeKeyFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        privilegeKeyFilterPresets = sanitizedPrivilegeKeyFilterPresets(merged)
        savePrivilegeKeyFilterPresets()
        lastError = nil
        return imported.count
    }

    func savePermissionFilterPreset(
        name: String,
        scope: String,
        assignedFilter: String,
        assignedSortMode: String,
        assignedSortAscending: Bool,
        assignedSearchText: String,
        permissionSearchText: String
    ) {
        let preset = sanitizedPermissionFilterPreset(TS3PermissionFilterPreset(
            name: name,
            scope: scope,
            assignedFilter: assignedFilter,
            assignedSortMode: assignedSortMode,
            assignedSortAscending: assignedSortAscending,
            assignedSearchText: assignedSearchText,
            permissionSearchText: permissionSearchText
        ))
        guard let preset else {
            lastError = "Enter a name for the permission filter preset."
            return
        }
        permissionFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        permissionFilterPresets.insert(preset, at: 0)
        permissionFilterPresets = sanitizedPermissionFilterPresets(permissionFilterPresets)
        savePermissionFilterPresets()
        lastError = nil
    }

    func deletePermissionFilterPreset(_ preset: TS3PermissionFilterPreset) {
        permissionFilterPresets.removeAll { $0.id == preset.id }
        savePermissionFilterPresets()
    }

    func permissionFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(permissionFilterPresets)
    }

    @discardableResult
    func importPermissionFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3PermissionFilterPreset].self, from: data)
        var merged = permissionFilterPresets
        for preset in sanitizedPermissionFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        permissionFilterPresets = sanitizedPermissionFilterPresets(merged)
        savePermissionFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveGroupFilterPreset(
        name: String,
        target: String,
        groupTypeFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedGroupFilterPreset(TS3GroupFilterPreset(
            name: name,
            target: target,
            groupTypeFilter: groupTypeFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the group filter preset."
            return
        }
        groupFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        groupFilterPresets.insert(preset, at: 0)
        groupFilterPresets = sanitizedGroupFilterPresets(groupFilterPresets)
        saveGroupFilterPresets()
        lastError = nil
    }

    func deleteGroupFilterPreset(_ preset: TS3GroupFilterPreset) {
        groupFilterPresets.removeAll { $0.id == preset.id }
        saveGroupFilterPresets()
    }

    func groupFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(groupFilterPresets)
    }

    @discardableResult
    func importGroupFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3GroupFilterPreset].self, from: data)
        var merged = groupFilterPresets
        for preset in sanitizedGroupFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        groupFilterPresets = sanitizedGroupFilterPresets(merged)
        saveGroupFilterPresets()
        lastError = nil
        return imported.count
    }

    func saveGroupClientFilterPreset(
        name: String,
        memberFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedGroupClientFilterPreset(TS3GroupClientFilterPreset(
            name: name,
            memberFilter: memberFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the group member filter preset."
            return
        }
        groupClientFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        groupClientFilterPresets.insert(preset, at: 0)
        groupClientFilterPresets = sanitizedGroupClientFilterPresets(groupClientFilterPresets)
        saveGroupClientFilterPresets()
        lastError = nil
    }

    func deleteGroupClientFilterPreset(_ preset: TS3GroupClientFilterPreset) {
        groupClientFilterPresets.removeAll { $0.id == preset.id }
        saveGroupClientFilterPresets()
    }

    func groupClientFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(groupClientFilterPresets)
    }

    @discardableResult
    func importGroupClientFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3GroupClientFilterPreset].self, from: data)
        var merged = groupClientFilterPresets
        for preset in sanitizedGroupClientFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        groupClientFilterPresets = sanitizedGroupClientFilterPresets(merged)
        saveGroupClientFilterPresets()
        lastError = nil
        return imported.count
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
        let pokeMessage = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Poke" : message
        runClientCommand { client in
            try await client.pokeClient(clientId: user.id, message: pokeMessage)
            await MainActor.run {
                self.pokeEvents.insert(TS3PokeSummary(
                    senderId: user.id,
                    senderName: user.nickname,
                    senderUniqueIdentifier: user.uniqueIdentifier,
                    message: pokeMessage,
                    isOwnPoke: true
                ), at: 0)
                if self.pokeEvents.count > 50 {
                    self.pokeEvents.removeLast(self.pokeEvents.count - 50)
                }
            }
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

    func removeServerGroup(_ group: TS3GroupSummary, from members: [TS3GroupClientSummary]) {
        let uniqueMembers = Dictionary(members.map { ($0.clientDatabaseId, $0) }, uniquingKeysWith: { first, _ in first })
            .values
            .sorted { $0.clientDatabaseId < $1.clientDatabaseId }
        guard !uniqueMembers.isEmpty else { return }

        runClientCommand { client in
            for member in uniqueMembers {
                try await client.removeServerGroup(groupId: group.id, fromClientDatabaseId: member.clientDatabaseId)
            }
            await MainActor.run {
                let removedDatabaseIds = Set(uniqueMembers.map(\.clientDatabaseId))
                self.groupClients.removeAll { removedDatabaseIds.contains($0.clientDatabaseId) }
                for onlineClient in self.clients where onlineClient.databaseId.map({ removedDatabaseIds.contains($0) }) == true {
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

    func denyTalkRequest(for user: TS3UserSummary) {
        runClientCommand { client in
            try await client.setClientTalker(false, clientId: user.id)
            await MainActor.run {
                self.updateUser(clientId: user.id) { existing in
                    self.copyUser(
                        existing,
                        isTalker: false,
                        isRequestingTalkPower: false,
                        talkRequestMessage: ""
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

    func copyIdentitySnapshot() {
        TS3PlatformSupport.copyToPasteboard(identitySummary.snapshotText)
    }

    func identitySnapshotData() -> Data {
        Data(identitySummary.snapshotText.utf8)
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

    func regenerateIdentity(securityLevel: Int = 8) {
        guard state == .disconnected else {
            lastError = "Disconnect before replacing your identity."
            return
        }
        guard securityLevel >= 0 && securityLevel <= 32 else {
            lastError = "Identity security level must be between 0 and 32."
            return
        }
        Task {
            do {
                let snapshot = try await TS3Client(config: TS3ClientConfig(
                    host: "localhost",
                    port: 9987,
                    nickname: nickname,
                    serverPassword: nil
                )).regenerateIdentity(securityLevel: securityLevel)
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

    private var connectionFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-connection-filter-presets.json")
    }

    private var contactsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-contacts.json")
    }

    private var contactFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-contact-filter-presets.json")
    }

    private var chatHistoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-chat-history.json")
    }

    private var fileBrowserBookmarksURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-file-browser-bookmarks.json")
    }

    private var fileBrowserFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-file-browser-filter-presets.json")
    }

    private var offlineMessageFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-offline-message-filter-presets.json")
    }

    private var banFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-ban-filter-presets.json")
    }

    private var complaintFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-complaint-filter-presets.json")
    }

    private var databaseClientFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-database-client-filter-presets.json")
    }

    private var privilegeKeyFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-privilege-key-filter-presets.json")
    }

    private var permissionFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-permission-filter-presets.json")
    }

    private var groupFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-group-filter-presets.json")
    }

    private var groupClientFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-group-client-filter-presets.json")
    }

    private var whisperPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-whisper-presets.json")
    }

    private var whisperFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-whisper-filter-presets.json")
    }

    private var audioSettingsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-audio-settings.json")
    }

    private var selfStatusProfilesURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-self-status-profiles.json")
    }

    private var audioProfilesURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-audio-profiles.json")
    }

    private var keyboardShortcutsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-keyboard-shortcuts.json")
    }

    private var userPlaybackPreferencesURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-user-playback-preferences.json")
    }

    private var notificationSettingsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-notification-settings.json")
    }

    private var serverLogQueryPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-server-log-query-presets.json")
    }

    private var channelSubscriptionPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-channel-subscription-presets.json")
    }

    private var channelTreeFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-channel-tree-filter-presets.json")
    }

    private var eventFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-event-filter-presets.json")
    }

    private var chatFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-chat-filter-presets.json")
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
            let data = try JSONEncoder().encode(currentAudioSettingsSnapshot)
            try data.write(to: audioSettingsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func audioSettingsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(currentAudioSettingsSnapshot)
    }

    private var currentAudioSettingsSnapshot: TS3AudioSettings {
        TS3AudioSettings(
            playbackVolume: playbackVolume,
            inputGain: inputGain,
            transmitMode: audioTransmitMode.rawValue,
            voiceActivationThreshold: voiceActivationThreshold,
            prefersSpeakerOutput: prefersSpeakerOutput
        )
    }

    private func loadAudioProfiles() {
        guard let data = try? Data(contentsOf: audioProfilesURL),
              let decoded = try? JSONDecoder().decode([TS3AudioProfile].self, from: data) else {
            audioProfiles = []
            return
        }
        audioProfiles = sanitizedAudioProfiles(decoded)
    }

    private func saveAudioProfiles() {
        do {
            let directory = audioProfilesURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(audioProfiles)
            try data.write(to: audioProfilesURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func saveCurrentAudioProfile(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            lastError = "Enter a name for the audio profile."
            return
        }
        audioProfiles.removeAll { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
        audioProfiles.insert(TS3AudioProfile(
            name: trimmedName,
            playbackVolume: playbackVolume,
            inputGain: inputGain,
            transmitMode: audioTransmitMode.rawValue,
            voiceActivationThreshold: voiceActivationThreshold
        ), at: 0)
        saveAudioProfiles()
        lastError = nil
    }

    func applyAudioProfile(_ profile: TS3AudioProfile) {
        applyAudioSettingsSnapshot(TS3AudioSettings(
            playbackVolume: profile.playbackVolume,
            inputGain: profile.inputGain,
            transmitMode: profile.transmitMode,
            voiceActivationThreshold: profile.voiceActivationThreshold,
            prefersSpeakerOutput: prefersSpeakerOutput
        ))
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
        }
        if let client {
            applyAudioSettings(to: client)
        }
        saveAudioSettings()
        lastError = nil
    }

    func deleteAudioProfile(_ profile: TS3AudioProfile) {
        audioProfiles.removeAll { $0.id == profile.id }
        saveAudioProfiles()
    }

    func deleteAudioProfiles(_ profiles: [TS3AudioProfile]) {
        let ids = Set(profiles.map(\.id))
        guard !ids.isEmpty else { return }
        audioProfiles.removeAll { ids.contains($0.id) }
        saveAudioProfiles()
    }

    func audioProfilesExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(audioProfiles)
    }

    @discardableResult
    func importAudioProfiles(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3AudioProfile].self, from: data)
        var merged = audioProfiles
        for profile in sanitizedAudioProfiles(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(profile.name) == .orderedSame }
            merged.insert(profile, at: 0)
        }
        audioProfiles = sanitizedAudioProfiles(merged)
        saveAudioProfiles()
        lastError = nil
        return imported.count
    }

    private func loadKeyboardShortcuts() {
        guard let data = try? Data(contentsOf: keyboardShortcutsURL),
              let decoded = try? JSONDecoder().decode([TS3KeyboardShortcutBinding].self, from: data) else {
            keyboardShortcuts = Self.defaultKeyboardShortcuts
            return
        }
        keyboardShortcuts = sanitizedKeyboardShortcuts(decoded)
    }

    private func saveKeyboardShortcuts() {
        do {
            let directory = keyboardShortcutsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(keyboardShortcuts)
            try data.write(to: keyboardShortcutsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateKeyboardShortcut(_ shortcut: TS3KeyboardShortcutBinding, keys: String, isEnabled: Bool) {
        let trimmedKeys = String(keys.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
        guard let index = keyboardShortcuts.firstIndex(where: { $0.actionId == shortcut.actionId }) else { return }
        keyboardShortcuts[index].keys = trimmedKeys.isEmpty ? keyboardShortcuts[index].defaultKeys : trimmedKeys
        keyboardShortcuts[index].isEnabled = isEnabled
        keyboardShortcuts = sanitizedKeyboardShortcuts(keyboardShortcuts)
        saveKeyboardShortcuts()
        lastError = nil
    }

    func resetKeyboardShortcuts() {
        keyboardShortcuts = Self.defaultKeyboardShortcuts
        saveKeyboardShortcuts()
        lastError = nil
    }

    func setAllKeyboardShortcutsEnabled(_ isEnabled: Bool) {
        keyboardShortcuts = keyboardShortcuts.map { shortcut in
            TS3KeyboardShortcutBinding(
                actionId: shortcut.actionId,
                group: shortcut.group,
                action: shortcut.action,
                defaultKeys: shortcut.defaultKeys,
                keys: shortcut.keys,
                isEnabled: isEnabled
            )
        }
        saveKeyboardShortcuts()
        lastError = nil
    }

    func resetDisabledKeyboardShortcuts() {
        let disabledIds = Set(keyboardShortcuts.filter { !$0.isEnabled }.map(\.actionId))
        guard !disabledIds.isEmpty else { return }
        keyboardShortcuts = keyboardShortcuts.map { shortcut in
            guard disabledIds.contains(shortcut.actionId),
                  let defaultShortcut = Self.defaultKeyboardShortcuts.first(where: { $0.actionId == shortcut.actionId }) else {
                return shortcut
            }
            return defaultShortcut
        }
        saveKeyboardShortcuts()
        lastError = nil
    }

    func keyboardShortcutsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(keyboardShortcuts)
    }

    func importKeyboardShortcuts(from data: Data) throws {
        let decoded = try JSONDecoder().decode([TS3KeyboardShortcutBinding].self, from: data)
        keyboardShortcuts = sanitizedKeyboardShortcuts(decoded)
        saveKeyboardShortcuts()
        lastError = nil
    }

    private func sanitizedKeyboardShortcuts(_ shortcuts: [TS3KeyboardShortcutBinding]) -> [TS3KeyboardShortcutBinding] {
        let importedById = Dictionary(shortcuts.map { ($0.actionId, $0) }, uniquingKeysWith: { first, _ in first })
        return Self.defaultKeyboardShortcuts.map { defaultShortcut in
            guard let imported = importedById[defaultShortcut.actionId] else {
                return defaultShortcut
            }
            let keys = String(imported.keys.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
            return TS3KeyboardShortcutBinding(
                actionId: defaultShortcut.actionId,
                group: defaultShortcut.group,
                action: defaultShortcut.action,
                defaultKeys: defaultShortcut.defaultKeys,
                keys: keys.isEmpty ? defaultShortcut.defaultKeys : keys,
                isEnabled: imported.isEnabled
            )
        }
    }

    func importAudioSettings(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3AudioSettings.self, from: data)
        applyAudioSettingsSnapshot(decoded)
        saveAudioSettings()
        if let client {
            applyAudioSettings(to: client)
        }
        applyAudioRoutePreference()
        lastError = nil
    }

    private func applyAudioSettingsSnapshot(_ settings: TS3AudioSettings) {
        playbackVolume = min(max(settings.playbackVolume, 0), 4)
        inputGain = min(max(settings.inputGain, 0), 4)
        audioTransmitMode = TS3AudioTransmitMode(rawValue: settings.transmitMode) ?? .pushToTalk
        voiceActivationThreshold = min(max(settings.voiceActivationThreshold, 0.001), 0.5)
        prefersSpeakerOutput = settings.prefersSpeakerOutput
    }

    private func sanitizedAudioProfiles(_ profiles: [TS3AudioProfile]) -> [TS3AudioProfile] {
        profiles.compactMap { profile in
            let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return TS3AudioProfile(
                id: profile.id,
                name: name,
                playbackVolume: min(max(profile.playbackVolume, 0), 4),
                inputGain: min(max(profile.inputGain, 0), 4),
                transmitMode: TS3AudioTransmitMode(rawValue: profile.transmitMode)?.rawValue ?? TS3AudioTransmitMode.pushToTalk.rawValue,
                voiceActivationThreshold: min(max(profile.voiceActivationThreshold, 0.001), 0.5),
                updatedAt: profile.updatedAt
            )
        }
        .sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func loadUserPlaybackPreferences() {
        guard let data = try? Data(contentsOf: userPlaybackPreferencesURL),
              let decoded = try? JSONDecoder().decode([String: TS3UserPlaybackPreference].self, from: data) else {
            userPlaybackPreferences = [:]
            return
        }
        userPlaybackPreferences = sanitizedUserPlaybackPreferences(decoded)
    }

    private func sanitizedUserPlaybackPreferences(_ preferences: [String: TS3UserPlaybackPreference]) -> [String: TS3UserPlaybackPreference] {
        preferences.reduce(into: [:]) { result, item in
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
            notificationSoundEnabled = TS3NotificationSettings.defaults.soundEnabled
            privateMessageNotificationsEnabled = TS3NotificationSettings.defaults.privateMessagesEnabled
            pokeNotificationsEnabled = TS3NotificationSettings.defaults.pokesEnabled
            activityNotificationsEnabled = TS3NotificationSettings.defaults.activityEnabled
            return
        }
        notificationsEnabled = decoded.isEnabled
        notificationSoundEnabled = decoded.soundEnabled
        privateMessageNotificationsEnabled = decoded.privateMessagesEnabled
        pokeNotificationsEnabled = decoded.pokesEnabled
        activityNotificationsEnabled = decoded.activityEnabled
    }

    private func saveNotificationSettings() {
        do {
            let directory = notificationSettingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(notificationSettingsSnapshot)
            try data.write(to: notificationSettingsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func notificationSettingsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(notificationSettingsSnapshot)
    }

    func importNotificationSettings(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3NotificationSettings.self, from: data)
        notificationsEnabled = decoded.isEnabled
        notificationSoundEnabled = decoded.soundEnabled
        privateMessageNotificationsEnabled = decoded.privateMessagesEnabled
        pokeNotificationsEnabled = decoded.pokesEnabled
        activityNotificationsEnabled = decoded.activityEnabled
        saveNotificationSettings()
        lastError = nil
    }

    private var notificationSettingsSnapshot: TS3NotificationSettings {
        TS3NotificationSettings(
            isEnabled: notificationsEnabled,
            soundEnabled: notificationSoundEnabled,
            privateMessagesEnabled: privateMessageNotificationsEnabled,
            pokesEnabled: pokeNotificationsEnabled,
            activityEnabled: activityNotificationsEnabled
        )
    }

    private func loadServerLogQueryPresets() {
        guard let data = try? Data(contentsOf: serverLogQueryPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ServerLogQueryPreset].self, from: data) else {
            serverLogQueryPresets = []
            return
        }
        serverLogQueryPresets = sanitizedServerLogQueryPresets(decoded)
    }

    private func saveServerLogQueryPresets() {
        do {
            let directory = serverLogQueryPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(serverLogQueryPresets)
            try data.write(to: serverLogQueryPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedServerLogQueryPresets(_ presets: [TS3ServerLogQueryPreset]) -> [TS3ServerLogQueryPreset] {
        presets.compactMap(sanitizedServerLogQueryPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedServerLogQueryPreset(_ preset: TS3ServerLogQueryPreset) -> TS3ServerLogQueryPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let normalizedLevel = ["all", "info", "warning", "error", "debug"].contains(preset.levelFilter.lowercased())
            ? preset.levelFilter.lowercased()
            : "all"
        return TS3ServerLogQueryPreset(
            id: preset.id,
            name: name,
            limit: min(max(preset.limit, 1), 1_000),
            reverse: preset.reverse,
            instance: preset.instance,
            levelFilter: normalizedLevel,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadChannelSubscriptionPresets() {
        guard let data = try? Data(contentsOf: channelSubscriptionPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ChannelSubscriptionPreset].self, from: data) else {
            channelSubscriptionPresets = []
            return
        }
        channelSubscriptionPresets = sanitizedChannelSubscriptionPresets(decoded)
    }

    private func saveChannelSubscriptionPresets() {
        do {
            let directory = channelSubscriptionPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(channelSubscriptionPresets)
            try data.write(to: channelSubscriptionPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedChannelSubscriptionPresets(_ presets: [TS3ChannelSubscriptionPreset]) -> [TS3ChannelSubscriptionPreset] {
        presets.compactMap(sanitizedChannelSubscriptionPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedChannelSubscriptionPreset(_ preset: TS3ChannelSubscriptionPreset) -> TS3ChannelSubscriptionPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let channelIds = Array(Set(preset.channelIds.filter { $0 > 0 })).sorted()
        guard !name.isEmpty else { return nil }
        return TS3ChannelSubscriptionPreset(
            id: preset.id,
            name: name,
            channelIds: channelIds,
            updatedAt: preset.updatedAt
        )
    }

    private func loadChannelTreeFilterPresets() {
        guard let data = try? Data(contentsOf: channelTreeFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ChannelTreeFilterPreset].self, from: data) else {
            channelTreeFilterPresets = []
            return
        }
        channelTreeFilterPresets = sanitizedChannelTreeFilterPresets(decoded)
    }

    private func saveChannelTreeFilterPresets() {
        do {
            let directory = channelTreeFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(channelTreeFilterPresets)
            try data.write(to: channelTreeFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedChannelTreeFilterPresets(
        _ presets: [TS3ChannelTreeFilterPreset]
    ) -> [TS3ChannelTreeFilterPreset] {
        presets.compactMap(sanitizedChannelTreeFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedChannelTreeFilterPreset(
        _ preset: TS3ChannelTreeFilterPreset
    ) -> TS3ChannelTreeFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let validFilters: Set<String> = [
            "all",
            "current",
            "default",
            "passwordProtected",
            "unsubscribed",
            "populated",
            "empty",
            "mutedUsers",
            "awayUsers",
            "talkRequests"
        ]
        let treeFilter = validFilters.contains(preset.treeFilter) ? preset.treeFilter : "all"
        let validSortModes: Set<String> = ["serverOrder", "name", "channelId"]
        let sortMode = validSortModes.contains(preset.sortMode) ? preset.sortMode : "serverOrder"
        let validMemberSortModes: Set<String> = ["nickname", "clientId", "talkPower", "status"]
        let memberSortMode = validMemberSortModes.contains(preset.memberSortMode) ? preset.memberSortMode : "nickname"
        return TS3ChannelTreeFilterPreset(
            id: preset.id,
            name: name,
            treeFilter: treeFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            memberSortMode: memberSortMode,
            memberSortAscending: preset.memberSortAscending,
            currentUserFirst: preset.currentUserFirst,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadEventFilterPresets() {
        guard let data = try? Data(contentsOf: eventFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3EventFilterPreset].self, from: data) else {
            eventFilterPresets = []
            return
        }
        eventFilterPresets = sanitizedEventFilterPresets(decoded)
    }

    private func saveEventFilterPresets() {
        do {
            let directory = eventFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(eventFilterPresets)
            try data.write(to: eventFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedEventFilterPresets(_ presets: [TS3EventFilterPreset]) -> [TS3EventFilterPreset] {
        presets.compactMap(sanitizedEventFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedEventFilterPreset(_ preset: TS3EventFilterPreset) -> TS3EventFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let eventFilter = ["all", "activity", "pokes", "clientMovement", "channelChanges"].contains(preset.eventFilter)
            ? preset.eventFilter
            : "all"
        let sourceFilter = ["all", "own", "others"].contains(preset.sourceFilter)
            ? preset.sourceFilter
            : "all"
        return TS3EventFilterPreset(
            id: preset.id,
            name: name,
            eventFilter: eventFilter,
            sourceFilter: sourceFilter,
            newestFirst: preset.newestFirst,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadChatFilterPresets() {
        guard let data = try? Data(contentsOf: chatFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ChatFilterPreset].self, from: data) else {
            chatFilterPresets = []
            return
        }
        chatFilterPresets = sanitizedChatFilterPresets(decoded)
    }

    private func saveChatFilterPresets() {
        do {
            let directory = chatFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(chatFilterPresets)
            try data.write(to: chatFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedChatFilterPresets(_ presets: [TS3ChatFilterPreset]) -> [TS3ChatFilterPreset] {
        presets.compactMap(sanitizedChatFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedChatFilterPreset(_ preset: TS3ChatFilterPreset) -> TS3ChatFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let messageFilter = ["all", "channel", "server", "privateMessage"].contains(preset.messageFilter)
            ? preset.messageFilter
            : "all"
        let senderFilter = ["all", "own", "others"].contains(preset.senderFilter)
            ? preset.senderFilter
            : "all"
        return TS3ChatFilterPreset(
            id: preset.id,
            name: name,
            messageFilter: messageFilter,
            senderFilter: senderFilter,
            newestFirst: preset.newestFirst,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadFileBrowserBookmarks() {
        guard let data = try? Data(contentsOf: fileBrowserBookmarksURL),
              let decoded = try? JSONDecoder().decode([TS3FileBrowserBookmark].self, from: data) else {
            fileBrowserBookmarks = []
            return
        }
        fileBrowserBookmarks = sanitizedFileBrowserBookmarks(decoded)
    }

    private func saveFileBrowserBookmarks() {
        do {
            let directory = fileBrowserBookmarksURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(fileBrowserBookmarks)
            try data.write(to: fileBrowserBookmarksURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedFileBrowserBookmarks(_ bookmarks: [TS3FileBrowserBookmark]) -> [TS3FileBrowserBookmark] {
        bookmarks.compactMap(sanitizedFileBrowserBookmark)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedFileBrowserBookmark(_ bookmark: TS3FileBrowserBookmark) -> TS3FileBrowserBookmark? {
        let name = bookmark.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, bookmark.channelId > 0 else { return nil }
        let channelName = bookmark.channelName.trimmingCharacters(in: .whitespacesAndNewlines)
        return TS3FileBrowserBookmark(
            id: bookmark.id,
            name: name,
            channelId: bookmark.channelId,
            channelName: channelName.isEmpty ? "Channel \(bookmark.channelId)" : String(channelName.prefix(120)),
            path: normalizedFileDirectoryPath(bookmark.path),
            updatedAt: bookmark.updatedAt
        )
    }

    private func loadFileBrowserFilterPresets() {
        guard let data = try? Data(contentsOf: fileBrowserFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3FileBrowserFilterPreset].self, from: data) else {
            fileBrowserFilterPresets = []
            return
        }
        fileBrowserFilterPresets = sanitizedFileBrowserFilterPresets(decoded)
    }

    private func saveFileBrowserFilterPresets() {
        do {
            let directory = fileBrowserFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(fileBrowserFilterPresets)
            try data.write(to: fileBrowserFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedFileBrowserFilterPresets(
        _ presets: [TS3FileBrowserFilterPreset]
    ) -> [TS3FileBrowserFilterPreset] {
        presets.compactMap(sanitizedFileBrowserFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedFileBrowserFilterPreset(
        _ preset: TS3FileBrowserFilterPreset
    ) -> TS3FileBrowserFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let sortMode = ["name", "type", "size", "modified"].contains(preset.sortMode)
            ? preset.sortMode
            : "name"
        return TS3FileBrowserFilterPreset(
            id: preset.id,
            name: name,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadOfflineMessageFilterPresets() {
        guard let data = try? Data(contentsOf: offlineMessageFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3OfflineMessageFilterPreset].self, from: data) else {
            offlineMessageFilterPresets = []
            return
        }
        offlineMessageFilterPresets = sanitizedOfflineMessageFilterPresets(decoded)
    }

    private func saveOfflineMessageFilterPresets() {
        do {
            let directory = offlineMessageFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(offlineMessageFilterPresets)
            try data.write(to: offlineMessageFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedOfflineMessageFilterPresets(_ presets: [TS3OfflineMessageFilterPreset]) -> [TS3OfflineMessageFilterPreset] {
        presets.compactMap(sanitizedOfflineMessageFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedOfflineMessageFilterPreset(_ preset: TS3OfflineMessageFilterPreset) -> TS3OfflineMessageFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let readFilter = ["all", "unread", "read"].contains(preset.readFilter)
            ? preset.readFilter
            : "all"
        let contentFilter = ["all", "withBody", "bodyNotLoaded", "canReply", "unknownSender"].contains(preset.contentFilter)
            ? preset.contentFilter
            : "all"
        let sortMode = ["timestamp", "sender", "subject", "id"].contains(preset.sortMode)
            ? preset.sortMode
            : "timestamp"
        return TS3OfflineMessageFilterPreset(
            id: preset.id,
            name: name,
            readFilter: readFilter,
            contentFilter: contentFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadBanFilterPresets() {
        guard let data = try? Data(contentsOf: banFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3BanFilterPreset].self, from: data) else {
            banFilterPresets = []
            return
        }
        banFilterPresets = sanitizedBanFilterPresets(decoded)
    }

    private func saveBanFilterPresets() {
        do {
            let directory = banFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(banFilterPresets)
            try data.write(to: banFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedBanFilterPresets(_ presets: [TS3BanFilterPreset]) -> [TS3BanFilterPreset] {
        presets.compactMap(sanitizedBanFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedBanFilterPreset(_ preset: TS3BanFilterPreset) -> TS3BanFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let banFilter = ["all", "ip", "name", "uniqueIdentifier", "permanent", "temporary"].contains(preset.banFilter)
            ? preset.banFilter
            : "all"
        return TS3BanFilterPreset(
            id: preset.id,
            name: name,
            banFilter: banFilter,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadComplaintFilterPresets() {
        guard let data = try? Data(contentsOf: complaintFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ComplaintFilterPreset].self, from: data) else {
            complaintFilterPresets = []
            return
        }
        complaintFilterPresets = sanitizedComplaintFilterPresets(decoded)
    }

    private func saveComplaintFilterPresets() {
        do {
            let directory = complaintFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(complaintFilterPresets)
            try data.write(to: complaintFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedComplaintFilterPresets(_ presets: [TS3ComplaintFilterPreset]) -> [TS3ComplaintFilterPreset] {
        presets.compactMap(sanitizedComplaintFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedComplaintFilterPreset(_ preset: TS3ComplaintFilterPreset) -> TS3ComplaintFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let complaintFilter = [
            "all",
            "namedSource",
            "anonymousSource",
            "withMessage",
            "withoutMessage",
            "withTimestamp"
        ].contains(preset.complaintFilter) ? preset.complaintFilter : "all"
        let sortMode = ["date", "source", "sourceDatabaseId", "message"].contains(preset.sortMode)
            ? preset.sortMode
            : "date"
        return TS3ComplaintFilterPreset(
            id: preset.id,
            name: name,
            complaintFilter: complaintFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadDatabaseClientFilterPresets() {
        guard let data = try? Data(contentsOf: databaseClientFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3DatabaseClientFilterPreset].self, from: data) else {
            databaseClientFilterPresets = []
            return
        }
        databaseClientFilterPresets = sanitizedDatabaseClientFilterPresets(decoded)
    }

    private func saveDatabaseClientFilterPresets() {
        do {
            let directory = databaseClientFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(databaseClientFilterPresets)
            try data.write(to: databaseClientFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedDatabaseClientFilterPresets(_ presets: [TS3DatabaseClientFilterPreset]) -> [TS3DatabaseClientFilterPreset] {
        presets.compactMap(sanitizedDatabaseClientFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedDatabaseClientFilterPreset(_ preset: TS3DatabaseClientFilterPreset) -> TS3DatabaseClientFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let recordFilter = [
            "all",
            "withUniqueId",
            "withoutUniqueId",
            "withDescription",
            "withLastIP",
            "withConnections"
        ].contains(preset.recordFilter) ? preset.recordFilter : "all"
        let sortMode = [
            "nickname",
            "databaseId",
            "created",
            "lastConnected",
            "connections",
            "lastIP"
        ].contains(preset.sortMode) ? preset.sortMode : "nickname"
        let batchSize = min(max(preset.batchSize, 1), 1_000)
        return TS3DatabaseClientFilterPreset(
            id: preset.id,
            name: name,
            recordFilter: recordFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            localFilterText: String(preset.localFilterText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            batchSize: batchSize,
            updatedAt: preset.updatedAt
        )
    }

    private func loadPrivilegeKeyFilterPresets() {
        guard let data = try? Data(contentsOf: privilegeKeyFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3PrivilegeKeyFilterPreset].self, from: data) else {
            privilegeKeyFilterPresets = []
            return
        }
        privilegeKeyFilterPresets = sanitizedPrivilegeKeyFilterPresets(decoded)
    }

    private func savePrivilegeKeyFilterPresets() {
        do {
            let directory = privilegeKeyFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(privilegeKeyFilterPresets)
            try data.write(to: privilegeKeyFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedPrivilegeKeyFilterPresets(_ presets: [TS3PrivilegeKeyFilterPreset]) -> [TS3PrivilegeKeyFilterPreset] {
        presets.compactMap(sanitizedPrivilegeKeyFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedPrivilegeKeyFilterPreset(_ preset: TS3PrivilegeKeyFilterPreset) -> TS3PrivilegeKeyFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let keyFilter = [
            "all",
            "serverGroup",
            "channelGroup",
            "unknown",
            "withDescription",
            "withCustomSet"
        ].contains(preset.keyFilter) ? preset.keyFilter : "all"
        let sortMode = ["created", "type", "group", "channel", "description"].contains(preset.sortMode)
            ? preset.sortMode
            : "created"
        return TS3PrivilegeKeyFilterPreset(
            id: preset.id,
            name: name,
            keyFilter: keyFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadPermissionFilterPresets() {
        guard let data = try? Data(contentsOf: permissionFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3PermissionFilterPreset].self, from: data) else {
            permissionFilterPresets = []
            return
        }
        permissionFilterPresets = sanitizedPermissionFilterPresets(decoded)
    }

    private func savePermissionFilterPresets() {
        do {
            let directory = permissionFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(permissionFilterPresets)
            try data.write(to: permissionFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedPermissionFilterPresets(_ presets: [TS3PermissionFilterPreset]) -> [TS3PermissionFilterPreset] {
        presets.compactMap(sanitizedPermissionFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedPermissionFilterPreset(_ preset: TS3PermissionFilterPreset) -> TS3PermissionFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let scope = [
            "ownClient",
            "databaseClient",
            "serverGroup",
            "channelGroup",
            "channel",
            "channelClient"
        ].contains(preset.scope) ? preset.scope : "ownClient"
        let assignedFilter = [
            "all",
            "negated",
            "skipped",
            "inherited",
            "positiveValue",
            "zeroValue",
            "negativeValue"
        ].contains(preset.assignedFilter) ? preset.assignedFilter : "all"
        let assignedSortMode = ["name", "value", "flags"].contains(preset.assignedSortMode)
            ? preset.assignedSortMode
            : "name"
        return TS3PermissionFilterPreset(
            id: preset.id,
            name: name,
            scope: scope,
            assignedFilter: assignedFilter,
            assignedSortMode: assignedSortMode,
            assignedSortAscending: preset.assignedSortAscending,
            assignedSearchText: String(preset.assignedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            permissionSearchText: String(preset.permissionSearchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadGroupFilterPresets() {
        guard let data = try? Data(contentsOf: groupFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3GroupFilterPreset].self, from: data) else {
            groupFilterPresets = []
            return
        }
        groupFilterPresets = sanitizedGroupFilterPresets(decoded)
    }

    private func saveGroupFilterPresets() {
        do {
            let directory = groupFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(groupFilterPresets)
            try data.write(to: groupFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedGroupFilterPresets(_ presets: [TS3GroupFilterPreset]) -> [TS3GroupFilterPreset] {
        presets.compactMap(sanitizedGroupFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedGroupFilterPreset(_ preset: TS3GroupFilterPreset) -> TS3GroupFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let target = ["server", "channel"].contains(preset.target) ? preset.target : "server"
        let groupTypeFilter = ["all", "template", "regular", "query", "unknown"].contains(preset.groupTypeFilter)
            ? preset.groupTypeFilter
            : "all"
        let sortMode = ["name", "id", "type"].contains(preset.sortMode) ? preset.sortMode : "name"
        return TS3GroupFilterPreset(
            id: preset.id,
            name: name,
            target: target,
            groupTypeFilter: groupTypeFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadGroupClientFilterPresets() {
        guard let data = try? Data(contentsOf: groupClientFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3GroupClientFilterPreset].self, from: data) else {
            groupClientFilterPresets = []
            return
        }
        groupClientFilterPresets = sanitizedGroupClientFilterPresets(decoded)
    }

    private func saveGroupClientFilterPresets() {
        do {
            let directory = groupClientFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(groupClientFilterPresets)
            try data.write(to: groupClientFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedGroupClientFilterPresets(
        _ presets: [TS3GroupClientFilterPreset]
    ) -> [TS3GroupClientFilterPreset] {
        presets.compactMap(sanitizedGroupClientFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedGroupClientFilterPreset(
        _ preset: TS3GroupClientFilterPreset
    ) -> TS3GroupClientFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let memberFilter = ["all", "online", "offline", "withUniqueId", "withoutUniqueId"].contains(preset.memberFilter)
            ? preset.memberFilter
            : "all"
        let sortMode = ["nickname", "databaseId", "channel", "uniqueId"].contains(preset.sortMode)
            ? preset.sortMode
            : "nickname"
        return TS3GroupClientFilterPreset(
            id: preset.id,
            name: name,
            memberFilter: memberFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func activityNotificationTitle(for event: TS3ActivitySummary) -> String {
        switch event.kind {
        case .clientEntered, .clientLeft, .clientMoved:
            return event.clientName
        case .channelCreated, .channelEdited, .channelDeleted, .channelMoved, .channelPasswordChanged, .channelDescriptionChanged:
            return event.invokerName?.isEmpty == false ? event.invokerName! : "Server activity"
        }
    }

    private func activityNotificationBody(for event: TS3ActivitySummary) -> String {
        switch event.kind {
        case .clientEntered:
            return "Joined \(channelName(for: event.toChannelId) ?? "the server")"
        case .clientLeft:
            return "Left \(channelName(for: event.fromChannelId) ?? "the server")"
        case .clientMoved:
            return "Moved from \(channelName(for: event.fromChannelId) ?? "the server") to \(channelName(for: event.toChannelId) ?? "the server")"
        case .channelCreated:
            return "Created \(event.channelName ?? channelName(for: event.channelId) ?? "a channel")"
        case .channelEdited:
            return "Edited \(event.channelName ?? channelName(for: event.channelId) ?? "a channel")"
        case .channelDeleted:
            return "Deleted \(event.channelName ?? channelName(for: event.channelId) ?? "a channel")"
        case .channelMoved:
            return "Moved \(event.channelName ?? channelName(for: event.channelId) ?? "a channel") to \(channelName(for: event.toChannelId) ?? "the server")"
        case .channelPasswordChanged:
            return "Changed the password for \(event.channelName ?? channelName(for: event.channelId) ?? "a channel")"
        case .channelDescriptionChanged:
            return "Changed the description for \(event.channelName ?? channelName(for: event.channelId) ?? "a channel")"
        }
    }

    private func loadConnectionRecoverySettings() {
        guard let data = try? Data(contentsOf: connectionRecoverySettingsURL),
              let decoded = try? JSONDecoder().decode(TS3ConnectionRecoverySettings.self, from: data) else {
            applyConnectionRecoverySettings(.defaults)
            return
        }
        applyConnectionRecoverySettings(decoded)
    }

    private func saveConnectionRecoverySettings() {
        do {
            let directory = connectionRecoverySettingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(currentConnectionRecoverySettings)
            try data.write(to: connectionRecoverySettingsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func connectionRecoverySettingsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(currentConnectionRecoverySettings)
    }

    func importConnectionRecoverySettings(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3ConnectionRecoverySettings.self, from: data)
        applyConnectionRecoverySettings(decoded)
        saveConnectionRecoverySettings()
        if !autoReconnectEnabled {
            cancelReconnectSchedule(resetAttempts: true)
        }
        lastError = nil
    }

    private var currentConnectionRecoverySettings: TS3ConnectionRecoverySettings {
        sanitizedConnectionRecoverySettings(TS3ConnectionRecoverySettings(
            autoReconnectEnabled: autoReconnectEnabled,
            initialDelaySeconds: autoReconnectInitialDelaySeconds,
            maxDelaySeconds: autoReconnectMaxDelaySeconds,
            maxAttempts: autoReconnectMaxAttempts
        ))
    }

    private func applyConnectionRecoverySettings(_ settings: TS3ConnectionRecoverySettings) {
        let sanitized = sanitizedConnectionRecoverySettings(settings)
        autoReconnectEnabled = sanitized.autoReconnectEnabled
        autoReconnectInitialDelaySeconds = sanitized.initialDelaySeconds
        autoReconnectMaxDelaySeconds = sanitized.maxDelaySeconds
        autoReconnectMaxAttempts = sanitized.maxAttempts
    }

    private func sanitizedConnectionRecoverySettings(
        _ settings: TS3ConnectionRecoverySettings
    ) -> TS3ConnectionRecoverySettings {
        let initialDelay = min(max(settings.initialDelaySeconds, 1), 300)
        let maxDelay = min(max(settings.maxDelaySeconds, initialDelay), 600)
        let maxAttempts = min(max(settings.maxAttempts, 0), 100)
        return TS3ConnectionRecoverySettings(
            autoReconnectEnabled: settings.autoReconnectEnabled,
            initialDelaySeconds: initialDelay,
            maxDelaySeconds: maxDelay,
            maxAttempts: maxAttempts
        )
    }

    func clientMigrationPackageExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let package = TS3ClientMigrationPackage(
            bookmarks: bookmarks,
            recentConnections: recentConnections,
            connectionFilterPresets: connectionFilterPresets,
            contacts: contacts,
            contactFilterPresets: contactFilterPresets,
            notificationSettings: notificationSettingsSnapshot,
            connectionRecoverySettings: currentConnectionRecoverySettings,
            serverLogQueryPresets: serverLogQueryPresets,
            keyboardShortcuts: keyboardShortcuts,
            channelSubscriptionPresets: channelSubscriptionPresets,
            channelTreeFilterPresets: channelTreeFilterPresets,
            eventFilterPresets: eventFilterPresets,
            chatFilterPresets: chatFilterPresets,
            fileBrowserBookmarks: fileBrowserBookmarks,
            fileBrowserFilterPresets: fileBrowserFilterPresets,
            offlineMessageFilterPresets: offlineMessageFilterPresets,
            banFilterPresets: banFilterPresets,
            complaintFilterPresets: complaintFilterPresets,
            databaseClientFilterPresets: databaseClientFilterPresets,
            privilegeKeyFilterPresets: privilegeKeyFilterPresets,
            permissionFilterPresets: permissionFilterPresets,
            groupFilterPresets: groupFilterPresets,
            groupClientFilterPresets: groupClientFilterPresets,
            audioSettings: currentAudioSettingsSnapshot,
            audioProfiles: audioProfiles,
            userPlaybackPreferences: userPlaybackPreferences,
            selfStatus: currentSelfStatusBackup(),
            selfStatusProfiles: selfStatusProfiles,
            whisperPresets: whisperPresets,
            whisperFilterPresets: whisperFilterPresets
        )
        return try encoder.encode(package)
    }

    func importClientMigrationPackage(from data: Data) throws {
        let package = try JSONDecoder().decode(TS3ClientMigrationPackage.self, from: data)
        try importBookmarks(from: encodedPackageSection(package.bookmarks))
        try importRecentConnections(from: encodedPackageSection(package.recentConnections))
        try importConnectionFilterPresets(from: encodedPackageSection(package.connectionFilterPresets))
        try importContacts(from: encodedPackageSection(package.contacts))
        try importContactFilterPresets(from: encodedPackageSection(package.contactFilterPresets))
        try importNotificationSettings(from: encodedPackageSection(package.notificationSettings))
        try importConnectionRecoverySettings(from: encodedPackageSection(package.connectionRecoverySettings))
        try importServerLogQueryPresets(from: encodedPackageSection(package.serverLogQueryPresets))
        try importKeyboardShortcuts(from: encodedPackageSection(package.keyboardShortcuts))
        try importChannelSubscriptionPresets(from: encodedPackageSection(package.channelSubscriptionPresets))
        try importChannelTreeFilterPresets(from: encodedPackageSection(package.channelTreeFilterPresets))
        try importEventFilterPresets(from: encodedPackageSection(package.eventFilterPresets))
        try importChatFilterPresets(from: encodedPackageSection(package.chatFilterPresets))
        try importFileBrowserBookmarks(from: encodedPackageSection(package.fileBrowserBookmarks))
        try importFileBrowserFilterPresets(from: encodedPackageSection(package.fileBrowserFilterPresets))
        try importOfflineMessageFilterPresets(from: encodedPackageSection(package.offlineMessageFilterPresets))
        try importBanFilterPresets(from: encodedPackageSection(package.banFilterPresets))
        try importComplaintFilterPresets(from: encodedPackageSection(package.complaintFilterPresets))
        try importDatabaseClientFilterPresets(from: encodedPackageSection(package.databaseClientFilterPresets))
        try importPrivilegeKeyFilterPresets(from: encodedPackageSection(package.privilegeKeyFilterPresets))
        try importPermissionFilterPresets(from: encodedPackageSection(package.permissionFilterPresets))
        try importGroupFilterPresets(from: encodedPackageSection(package.groupFilterPresets))
        try importGroupClientFilterPresets(from: encodedPackageSection(package.groupClientFilterPresets))
        try importAudioSettings(from: encodedPackageSection(package.audioSettings))
        try importAudioProfiles(from: encodedPackageSection(package.audioProfiles))
        try importUserPlaybackPreferences(from: encodedPackageSection(package.userPlaybackPreferences))
        try importSelfStatusBackup(from: encodedPackageSection(package.selfStatus))
        try importSelfStatusProfiles(from: encodedPackageSection(package.selfStatusProfiles))
        try importWhisperPresetBackup(from: encodedPackageSection(package.whisperPresets))
        try importWhisperFilterPresets(from: encodedPackageSection(package.whisperFilterPresets))
        lastError = nil
    }

    private func encodedPackageSection<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    private func notifyIfInactive(title: String, body: String, identifier: String) {
        #if canImport(UserNotifications)
        guard notificationsEnabled, !isAppActive else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if notificationSoundEnabled {
            content.sound = .default
        }
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

    private func loadConnectionFilterPresets() {
        guard let data = try? Data(contentsOf: connectionFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ConnectionFilterPreset].self, from: data) else {
            connectionFilterPresets = []
            return
        }
        connectionFilterPresets = sanitizedConnectionFilterPresets(decoded)
    }

    private func saveConnectionFilterPresets() {
        do {
            let directory = connectionFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(connectionFilterPresets)
            try data.write(to: connectionFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedConnectionFilterPresets(
        _ presets: [TS3ConnectionFilterPreset]
    ) -> [TS3ConnectionFilterPreset] {
        presets.compactMap(sanitizedConnectionFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedConnectionFilterPreset(
        _ preset: TS3ConnectionFilterPreset
    ) -> TS3ConnectionFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let connectionFilter = ["all", "withPassword", "withDefaultChannel", "withPrivilegeKey"].contains(preset.connectionFilter)
            ? preset.connectionFilter
            : "all"
        let sortMode = ["savedOrder", "name", "host", "nickname", "port"].contains(preset.sortMode)
            ? preset.sortMode
            : "savedOrder"
        let folder = preset.bookmarkFolderFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        let bookmarkFolderFilter = folder == "__unfiled__" ? folder : String(folder.prefix(120))
        return TS3ConnectionFilterPreset(
            id: preset.id,
            name: name,
            connectionFilter: connectionFilter,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            bookmarkFolderFilter: bookmarkFolderFilter,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func loadContactFilterPresets() {
        guard let data = try? Data(contentsOf: contactFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ContactFilterPreset].self, from: data) else {
            contactFilterPresets = []
            return
        }
        contactFilterPresets = sanitizedContactFilterPresets(decoded)
    }

    private func saveContactFilterPresets() {
        do {
            let directory = contactFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(contactFilterPresets)
            try data.write(to: contactFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedContactFilterPresets(_ presets: [TS3ContactFilterPreset]) -> [TS3ContactFilterPreset] {
        presets.compactMap(sanitizedContactFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedContactFilterPreset(_ preset: TS3ContactFilterPreset) -> TS3ContactFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let sortMode = ["nickname", "status", "updated", "note"].contains(preset.sortMode)
            ? preset.sortMode
            : "nickname"
        return TS3ContactFilterPreset(
            id: preset.id,
            name: name,
            sortMode: sortMode,
            sortAscending: preset.sortAscending,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
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

    private func loadWhisperFilterPresets() {
        guard let data = try? Data(contentsOf: whisperFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3WhisperFilterPreset].self, from: data) else {
            whisperFilterPresets = []
            return
        }
        whisperFilterPresets = sanitizedWhisperFilterPresets(decoded)
    }

    private func saveWhisperFilterPresets() {
        do {
            let directory = whisperFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(whisperFilterPresets)
            try data.write(to: whisperFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedWhisperFilterPresets(_ presets: [TS3WhisperFilterPreset]) -> [TS3WhisperFilterPreset] {
        presets.compactMap(sanitizedWhisperFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedWhisperFilterPreset(_ preset: TS3WhisperFilterPreset) -> TS3WhisperFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let presetFilter = ["all", "channels", "users", "mixed"].contains(preset.presetFilter)
            ? preset.presetFilter
            : "all"
        let presetSort = ["updated", "name", "targets"].contains(preset.presetSort)
            ? preset.presetSort
            : "updated"
        return TS3WhisperFilterPreset(
            id: preset.id,
            name: name,
            presetFilter: presetFilter,
            presetSort: presetSort,
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    func contactsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(contacts)
    }

    func saveContactFilterPreset(
        name: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedContactFilterPreset(TS3ContactFilterPreset(
            name: name,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the contact filter preset."
            return
        }
        contactFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        contactFilterPresets.insert(preset, at: 0)
        contactFilterPresets = sanitizedContactFilterPresets(contactFilterPresets)
        saveContactFilterPresets()
        lastError = nil
    }

    func deleteContactFilterPreset(_ preset: TS3ContactFilterPreset) {
        contactFilterPresets.removeAll { $0.id == preset.id }
        saveContactFilterPresets()
    }

    func contactFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(contactFilterPresets)
    }

    @discardableResult
    func importContactFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ContactFilterPreset].self, from: data)
        var merged = contactFilterPresets
        for preset in sanitizedContactFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        contactFilterPresets = sanitizedContactFilterPresets(merged)
        saveContactFilterPresets()
        lastError = nil
        return imported.count
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

    func clearChatMessages(_ messages: [TS3ChatMessageSummary]) {
        let ids = Set(messages.map(\.id))
        guard !ids.isEmpty else { return }
        chatMessages.removeAll { ids.contains($0.id) }
        if isViewingChat {
            unreadChatMessageCount = 0
        } else {
            unreadChatMessageCount = min(unreadChatMessageCount, chatMessages.count)
        }
        saveChatHistory()
    }

    func chatHistoryBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(Array(chatMessages.suffix(chatHistoryLimit)))
    }

    @discardableResult
    func importChatHistoryBackup(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ChatMessageSummary].self, from: data)
        var merged = chatMessages
        for message in imported {
            merged.removeAll { $0.id == message.id }
            merged.append(message)
        }
        chatMessages = Array(merged.sorted { $0.timestamp < $1.timestamp }.suffix(chatHistoryLimit))
        unreadChatMessageCount = isViewingChat ? 0 : chatMessages.count
        saveChatHistory()
        lastError = nil
        return imported.count
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

    func markEventsRead() {
        unreadPokeCount = 0
        unreadActivityCount = 0
    }

    func clearActivityEvents() {
        activityEvents = []
        unreadActivityCount = 0
    }

    func clearPokeEvents() {
        pokeEvents = []
        unreadPokeCount = 0
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
        return try encoder.encode(currentSelfStatusBackup())
    }

    private func currentSelfStatusBackup() -> TS3SelfStatusBackup {
        TS3SelfStatusBackup(
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
    }

    func importSelfStatusBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3SelfStatusBackup.self, from: data)
        applySelfStatusBackup(decoded, sendCommands: false)
        lastError = nil
    }

    func importAndApplySelfStatusBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3SelfStatusBackup.self, from: data)
        applySelfStatusBackup(decoded, sendCommands: true)
        lastError = nil
    }

    private func applySelfStatusBackup(_ backup: TS3SelfStatusBackup, sendCommands: Bool) {
        let decoded = sanitizedSelfStatusBackup(backup)
        nickname = decoded.nickname
        awayMessage = decoded.awayMessage
        isAway = decoded.isAway
        isInputMuted = decoded.isInputMuted
        isOutputMuted = decoded.isOutputMuted
        isChannelCommander = decoded.isChannelCommander
        talkRequestMessage = decoded.talkRequestMessage
        if sendCommands {
            updateNickname(to: decoded.nickname)
            setAway(decoded.isAway, message: decoded.awayMessage)
            setInputMuted(decoded.isInputMuted)
            setOutputMuted(decoded.isOutputMuted)
            setChannelCommander(decoded.isChannelCommander)
            if decoded.talkRequestMessage.isEmpty {
                setTalkRequest(false, message: "")
            } else {
                setTalkRequest(true, message: decoded.talkRequestMessage)
            }
        }
        if let client = clients.first(where: { $0.isCurrentUser }) {
            updateUser(clientId: client.id) { existing in
                self.copyUser(existing, description: decoded.description, iconId: decoded.iconId)
            }
        }
        saveAudioSettings()
    }

    private func loadSelfStatusProfiles() {
        guard let data = try? Data(contentsOf: selfStatusProfilesURL),
              let decoded = try? JSONDecoder().decode([TS3SelfStatusProfile].self, from: data) else {
            selfStatusProfiles = []
            return
        }
        selfStatusProfiles = sanitizedSelfStatusProfiles(decoded)
    }

    private func saveSelfStatusProfiles() {
        do {
            let directory = selfStatusProfilesURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(selfStatusProfiles)
            try data.write(to: selfStatusProfilesURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func saveCurrentSelfStatusProfile(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            lastError = "Enter a name for the status profile."
            return
        }
        selfStatusProfiles.removeAll { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
        selfStatusProfiles.insert(TS3SelfStatusProfile(
            name: trimmedName,
            status: currentSelfStatusBackup()
        ), at: 0)
        saveSelfStatusProfiles()
        lastError = nil
    }

    func applySelfStatusProfile(_ profile: TS3SelfStatusProfile) {
        applySelfStatusBackup(profile.status, sendCommands: true)
        lastError = nil
    }

    func deleteSelfStatusProfile(_ profile: TS3SelfStatusProfile) {
        selfStatusProfiles.removeAll { $0.id == profile.id }
        saveSelfStatusProfiles()
    }

    func deleteSelfStatusProfiles(_ profiles: [TS3SelfStatusProfile]) {
        let ids = Set(profiles.map(\.id))
        guard !ids.isEmpty else { return }
        selfStatusProfiles.removeAll { ids.contains($0.id) }
        saveSelfStatusProfiles()
    }

    func selfStatusProfilesExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(selfStatusProfiles)
    }

    @discardableResult
    func importSelfStatusProfiles(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3SelfStatusProfile].self, from: data)
        var merged = selfStatusProfiles
        for profile in sanitizedSelfStatusProfiles(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(profile.name) == .orderedSame }
            merged.insert(profile, at: 0)
        }
        selfStatusProfiles = sanitizedSelfStatusProfiles(merged)
        saveSelfStatusProfiles()
        lastError = nil
        return imported.count
    }

    private func sanitizedSelfStatusProfiles(_ profiles: [TS3SelfStatusProfile]) -> [TS3SelfStatusProfile] {
        profiles.compactMap { profile in
            let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            return TS3SelfStatusProfile(
                id: profile.id,
                name: name,
                status: sanitizedSelfStatusBackup(profile.status),
                updatedAt: profile.updatedAt
            )
        }
        .sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func sanitizedSelfStatusBackup(_ backup: TS3SelfStatusBackup) -> TS3SelfStatusBackup {
        TS3SelfStatusBackup(
            nickname: backup.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            description: backup.description.trimmingCharacters(in: .whitespacesAndNewlines),
            isAway: backup.isAway,
            awayMessage: backup.awayMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            isInputMuted: backup.isInputMuted,
            isOutputMuted: backup.isOutputMuted,
            isChannelCommander: backup.isChannelCommander,
            talkRequestMessage: String(backup.talkRequestMessage.trimmingCharacters(in: .whitespacesAndNewlines).prefix(50)),
            iconId: backup.iconId
        )
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

    func deleteWhisperPresets(_ presets: [TS3WhisperPreset]) {
        let presetIds = Set(presets.map(\.id))
        guard !presetIds.isEmpty else { return }
        whisperPresets.removeAll { presetIds.contains($0.id) }
        saveWhisperPresets()
    }

    func saveWhisperFilterPreset(
        name: String,
        presetFilter: String,
        presetSort: String,
        searchText: String
    ) {
        let preset = sanitizedWhisperFilterPreset(TS3WhisperFilterPreset(
            name: name,
            presetFilter: presetFilter,
            presetSort: presetSort,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the whisper filter preset."
            return
        }
        whisperFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        whisperFilterPresets.insert(preset, at: 0)
        whisperFilterPresets = sanitizedWhisperFilterPresets(whisperFilterPresets)
        saveWhisperFilterPresets()
        lastError = nil
    }

    func deleteWhisperFilterPreset(_ preset: TS3WhisperFilterPreset) {
        whisperFilterPresets.removeAll { $0.id == preset.id }
        saveWhisperFilterPresets()
    }

    func deleteAllWhisperFilterPresets() {
        guard !whisperFilterPresets.isEmpty else { return }
        whisperFilterPresets = []
        saveWhisperFilterPresets()
    }

    func whisperFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(whisperFilterPresets)
    }

    @discardableResult
    func importWhisperFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3WhisperFilterPreset].self, from: data)
        var merged = whisperFilterPresets
        for preset in sanitizedWhisperFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        whisperFilterPresets = sanitizedWhisperFilterPresets(merged)
        saveWhisperFilterPresets()
        lastError = nil
        return imported.count
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
        client.setPrefersSpeakerOutput(prefersSpeakerOutput)
        applyAudioRoutePreference()
    }

    private func applyAudioRoutePreference() {
        #if targetEnvironment(macCatalyst) || os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.overrideOutputAudioPort(prefersSpeakerOutput ? .speaker : .none)
        } catch {
            appendLog(TS3LogEntry(
                timestamp: Date(),
                level: .warning,
                message: "[AUDIO] failed to apply output route preference: \(error.localizedDescription)"
            ))
        }
        refreshAudioRoutes()
        #endif
    }

    #if targetEnvironment(macCatalyst) || os(iOS)
    private func routeText(for ports: [AVAudioSessionPortDescription]) -> String {
        guard !ports.isEmpty else { return "System Default" }
        return ports.map { port in
            "\(port.portName) (\(port.portType.rawValue))"
        }
        .joined(separator: ", ")
    }
    #endif

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
            if self.privateMessageNotificationsEnabled && !message.isOwnMessage && message.targetMode == .client {
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
            guard !self.isBlockedPoke(poke) else { return }
            self.pokeEvents.insert(TS3PokeSummary(poke: poke), at: 0)
            if self.pokeEvents.count > 50 {
                self.pokeEvents.removeLast(self.pokeEvents.count - 50)
            }
            self.unreadPokeCount += 1
            if self.pokeNotificationsEnabled {
                self.notifyIfInactive(
                    title: "Poke from \(poke.senderName)",
                    body: poke.message,
                    identifier: "ts3-poke-\(poke.id.uuidString)"
                )
            }
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didReceiveServerActivity event: TS3ServerActivityEvent) {
        Task { @MainActor in
            guard !event.isOwnClient else { return }
            let summary = TS3ActivitySummary(event: event)
            self.activityEvents.insert(summary, at: 0)
            if self.activityEvents.count > 100 {
                self.activityEvents.removeLast(self.activityEvents.count - 100)
            }
            self.unreadActivityCount += 1
            if self.activityNotificationsEnabled {
                self.notifyIfInactive(
                    title: self.activityNotificationTitle(for: summary),
                    body: self.activityNotificationBody(for: summary),
                    identifier: "ts3-activity-\(summary.id.uuidString)"
                )
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
