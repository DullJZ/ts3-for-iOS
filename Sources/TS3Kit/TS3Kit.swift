import Foundation

public struct TS3ClientConfig {
    public let host: String
    public let port: Int
    public let nickname: String
    public let serverPassword: String?
    public let defaultChannel: String?
    public let defaultChannelPassword: String?
    public let privilegeKey: String?

    /// Creates a TeamSpeak 3 connection configuration.
    public init(
        host: String,
        port: Int,
        nickname: String,
        serverPassword: String?,
        defaultChannel: String? = nil,
        defaultChannelPassword: String? = nil,
        privilegeKey: String? = nil
    ) {
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
    }
}

public struct TS3IdentitySnapshot {
    public let uid: String
    public let securityLevel: Int
    public let keyOffset: Int
    public let exportString: String

    /// Creates an identity snapshot suitable for backup and display.
    public init(uid: String, securityLevel: Int, keyOffset: Int, exportString: String) {
        self.uid = uid
        self.securityLevel = securityLevel
        self.keyOffset = keyOffset
        self.exportString = exportString
    }
}

public struct TS3ServerInfo {
    public let uniqueIdentifier: String?
    public let name: String
    public let platform: String?
    public let version: String?
    public let clientsOnline: Int?
    public let maxClients: Int?
    public let channelsOnline: Int?
    public let uptimeSeconds: Int?
    public let welcomeMessage: String?

    /// Creates a virtual server information snapshot.
    public init(
        uniqueIdentifier: String?,
        name: String,
        platform: String?,
        version: String?,
        clientsOnline: Int?,
        maxClients: Int?,
        channelsOnline: Int?,
        uptimeSeconds: Int?,
        welcomeMessage: String?
    ) {
        self.uniqueIdentifier = uniqueIdentifier
        self.name = name
        self.platform = platform
        self.version = version
        self.clientsOnline = clientsOnline
        self.maxClients = maxClients
        self.channelsOnline = channelsOnline
        self.uptimeSeconds = uptimeSeconds
        self.welcomeMessage = welcomeMessage
    }
}

public struct TS3Channel: Identifiable {
    public let id: Int
    public let parentId: Int?
    public let order: Int?
    public let name: String
    public let topic: String?
    public let description: String?
    public let isDefault: Bool
    public let isPasswordProtected: Bool
    public let isPermanent: Bool
    public let neededTalkPower: Int?
    public let codec: Int?

    /// Creates a channel snapshot from server-provided metadata.
    public init(
        id: Int,
        parentId: Int? = nil,
        order: Int? = nil,
        name: String,
        topic: String?,
        description: String? = nil,
        isDefault: Bool = false,
        isPasswordProtected: Bool = false,
        isPermanent: Bool = false,
        neededTalkPower: Int? = nil,
        codec: Int? = nil
    ) {
        self.id = id
        self.parentId = parentId
        self.order = order
        self.name = name
        self.topic = topic
        self.description = description
        self.isDefault = isDefault
        self.isPasswordProtected = isPasswordProtected
        self.isPermanent = isPermanent
        self.neededTalkPower = neededTalkPower
        self.codec = codec
    }
}

public struct TS3ServerClient: Identifiable {
    public let id: Int
    public let channelId: Int
    public let databaseId: Int?
    public let nickname: String
    public let isCurrentUser: Bool
    public let uniqueIdentifier: String?
    public let isInputMuted: Bool
    public let isOutputMuted: Bool
    public let isAway: Bool
    public let awayMessage: String?
    public let talkPower: Int?
    public let channelGroupId: Int?
    public let serverGroups: [Int]

    /// Creates a server client snapshot from server-provided metadata.
    public init(
        id: Int,
        channelId: Int,
        databaseId: Int? = nil,
        nickname: String,
        isCurrentUser: Bool,
        uniqueIdentifier: String? = nil,
        isInputMuted: Bool = false,
        isOutputMuted: Bool = false,
        isAway: Bool = false,
        awayMessage: String? = nil,
        talkPower: Int? = nil,
        channelGroupId: Int? = nil,
        serverGroups: [Int] = []
    ) {
        self.id = id
        self.channelId = channelId
        self.databaseId = databaseId
        self.nickname = nickname
        self.isCurrentUser = isCurrentUser
        self.uniqueIdentifier = uniqueIdentifier
        self.isInputMuted = isInputMuted
        self.isOutputMuted = isOutputMuted
        self.isAway = isAway
        self.awayMessage = awayMessage
        self.talkPower = talkPower
        self.channelGroupId = channelGroupId
        self.serverGroups = serverGroups
    }
}

public enum TS3TextMessageTargetMode: Int {
    case client = 1
    case channel = 2
    case server = 3
}

public enum TS3KickReason: Int {
    case channel = 4
    case server = 5
}

public struct TS3TextMessage: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let targetMode: TS3TextMessageTargetMode
    public let targetId: Int?
    public let senderId: Int?
    public let senderName: String
    public let message: String
    public let isOwnMessage: Bool

    /// Creates a received or locally sent text message record.
    public init(
        timestamp: Date,
        targetMode: TS3TextMessageTargetMode,
        targetId: Int?,
        senderId: Int?,
        senderName: String,
        message: String,
        isOwnMessage: Bool
    ) {
        self.timestamp = timestamp
        self.targetMode = targetMode
        self.targetId = targetId
        self.senderId = senderId
        self.senderName = senderName
        self.message = message
        self.isOwnMessage = isOwnMessage
    }
}

public struct TS3OfflineMessage: Identifiable {
    public let id: Int
    public let senderUniqueIdentifier: String?
    public let senderName: String?
    public let subject: String
    public let message: String?
    public let timestamp: Date?
    public let isRead: Bool

    /// Creates an offline message summary or detailed record.
    public init(
        id: Int,
        senderUniqueIdentifier: String?,
        senderName: String?,
        subject: String,
        message: String?,
        timestamp: Date?,
        isRead: Bool
    ) {
        self.id = id
        self.senderUniqueIdentifier = senderUniqueIdentifier
        self.senderName = senderName
        self.subject = subject
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

public struct TS3BanEntry: Identifiable {
    public let id: Int
    public let ip: String?
    public let name: String?
    public let uniqueIdentifier: String?
    public let lastNickname: String?
    public let createdAt: Date?
    public let durationSeconds: Int?
    public let invokerName: String?
    public let reason: String?
    public let enforcements: Int?

    /// Creates a ban-list entry from server-provided metadata.
    public init(
        id: Int,
        ip: String?,
        name: String?,
        uniqueIdentifier: String?,
        lastNickname: String?,
        createdAt: Date?,
        durationSeconds: Int?,
        invokerName: String?,
        reason: String?,
        enforcements: Int?
    ) {
        self.id = id
        self.ip = ip
        self.name = name
        self.uniqueIdentifier = uniqueIdentifier
        self.lastNickname = lastNickname
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.invokerName = invokerName
        self.reason = reason
        self.enforcements = enforcements
    }
}

public struct TS3PermissionInfo: Identifiable {
    public let id: Int
    public let name: String
    public let description: String?

    /// Creates a permission definition from server-provided metadata.
    public init(id: Int, name: String, description: String?) {
        self.id = id
        self.name = name
        self.description = description
    }
}

public struct TS3Permission: Identifiable {
    public var id: String { name }
    public let name: String
    public let value: Int
    public let isNegated: Bool
    public let isSkipped: Bool

    /// Creates a permission assignment from server-provided metadata.
    public init(name: String, value: Int, isNegated: Bool, isSkipped: Bool) {
        self.name = name
        self.value = value
        self.isNegated = isNegated
        self.isSkipped = isSkipped
    }
}

public enum TS3PermissionGroupType: Int {
    case serverGroup = 0
    case globalClient = 1
    case channel = 2
    case channelGroup = 3
    case channelClient = 4
}

public struct TS3PermissionAssignment: Identifiable {
    public let id = UUID()
    public let type: TS3PermissionGroupType?
    public let majorId: Int?
    public let minorId: Int?
    public let permissionId: Int
    public let value: Int
    public let isNegated: Bool
    public let isSkipped: Bool

    /// Creates a permission overview entry from server-provided metadata.
    public init(
        type: TS3PermissionGroupType?,
        majorId: Int?,
        minorId: Int?,
        permissionId: Int,
        value: Int,
        isNegated: Bool,
        isSkipped: Bool
    ) {
        self.type = type
        self.majorId = majorId
        self.minorId = minorId
        self.permissionId = permissionId
        self.value = value
        self.isNegated = isNegated
        self.isSkipped = isSkipped
    }
}

public struct TS3FileEntry: Identifiable {
    public var id: String { "\(channelId):\(path)" }
    public let channelId: Int
    public let path: String
    public let parentPath: String
    public let name: String
    public let size: Int64
    public let modifiedAt: Date?
    public let type: Int
    public let incompleteSize: Int64?

    public var isDirectory: Bool { type == 0 }
    public var isFile: Bool { type == 1 }
    public var isStillUploading: Bool { (incompleteSize ?? 0) > 0 }

    /// Creates a channel file browser entry from server-provided metadata.
    public init(
        channelId: Int,
        path: String,
        parentPath: String,
        name: String,
        size: Int64,
        modifiedAt: Date?,
        type: Int,
        incompleteSize: Int64?
    ) {
        self.channelId = channelId
        self.path = path
        self.parentPath = parentPath
        self.name = name
        self.size = size
        self.modifiedAt = modifiedAt
        self.type = type
        self.incompleteSize = incompleteSize
    }
}

public struct TS3ServerGroup: Identifiable {
    public let id: Int
    public let name: String

    /// Creates a server group summary.
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct TS3ChannelGroup: Identifiable {
    public let id: Int
    public let name: String

    /// Creates a channel group summary.
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public protocol TS3ClientDelegate: AnyObject {
    func ts3ClientDidConnect(_ client: TS3Client)
    func ts3Client(_ client: TS3Client, didDisconnectWith error: Error?)
    func ts3Client(_ client: TS3Client, didUpdateServerInfo info: TS3ServerInfo)
    func ts3Client(_ client: TS3Client, didUpdateChannels channels: [TS3Channel])
    func ts3Client(_ client: TS3Client, didUpdateClients clients: [TS3ServerClient])
    func ts3Client(_ client: TS3Client, didReceiveTextMessage message: TS3TextMessage)
    func ts3Client(_ client: TS3Client, didUpdateServerGroups groups: [TS3ServerGroup])
    func ts3Client(_ client: TS3Client, didUpdateChannelGroups groups: [TS3ChannelGroup])
}

public extension TS3ClientDelegate {
    func ts3Client(_ client: TS3Client, didUpdateServerInfo info: TS3ServerInfo) {}
    func ts3Client(_ client: TS3Client, didReceiveTextMessage message: TS3TextMessage) {}
    func ts3Client(_ client: TS3Client, didUpdateServerGroups groups: [TS3ServerGroup]) {}
    func ts3Client(_ client: TS3Client, didUpdateChannelGroups groups: [TS3ChannelGroup]) {}
}

public enum TS3Error: Error {
    case notImplemented
    case audioInputUnavailable
    case invalidEscape
    case ambiguousCommand
    case derDecodeFailed
    case invalidBeta
    case invalidInitStep
    case invalidCommand
    case invalidIdentity
    case invalidKey
    case invalidLicense
    case invalidMac
    case cryptoFailed
    case serverError(message: String)
    case packetTooLarge
    case invalidState
    case timeout
    case disconnected
    case compressionUnsupported
    case decompressionTooLarge
}

public enum TS3LogLevel: String {
    case debug
    case info
    case warning
    case error
}

public struct TS3LogEntry: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let level: TS3LogLevel
    public let message: String

    public init(timestamp: Date, level: TS3LogLevel, message: String) {
        self.timestamp = timestamp
        self.level = level
        self.message = message
    }
}
