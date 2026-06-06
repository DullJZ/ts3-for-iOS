import Foundation

public struct TS3ClientConfig {
    public let host: String
    public let port: Int
    public let nickname: String
    public let serverPassword: String?
    public let defaultChannel: String?
    public let defaultChannelPassword: String?
    public let privilegeKey: String?
    public let phoneticNickname: String?

    /// Creates a TeamSpeak 3 connection configuration.
    public init(
        host: String,
        port: Int,
        nickname: String,
        serverPassword: String?,
        defaultChannel: String? = nil,
        defaultChannelPassword: String? = nil,
        privilegeKey: String? = nil,
        phoneticNickname: String? = nil
    ) {
        self.host = host
        self.port = port
        self.nickname = nickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
        self.phoneticNickname = phoneticNickname
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

public enum TS3AudioTransmitMode: String, CaseIterable, Identifiable {
    public static let allCases: [TS3AudioTransmitMode] = [.pushToTalk, .continuous, .voiceActivation]

    case pushToTalk
    case continuous
    case voiceActivation

    public var id: String { rawValue }
}

public struct TS3ServerInfo {
    public let uniqueIdentifier: String?
    public let name: String
    public let platform: String?
    public let version: String?
    /// The virtual server creation time, when reported by the server.
    public let createdAt: Date?
    public let clientsOnline: Int?
    public let maxClients: Int?
    /// The number of connected ServerQuery clients.
    public let clientsInQuery: Int?
    public let reservedSlots: Int?
    public let channelsOnline: Int?
    public let uptimeSeconds: Int?
    public let welcomeMessage: String?
    public let passwordProtected: Bool
    /// The virtual server runtime status, such as online.
    public let status: String?
    /// The machine id associated with the virtual server.
    public let machineId: String?
    /// The codec encryption mode configured on the virtual server.
    public let codecEncryptionMode: Int?
    /// Whether the virtual server is published to the TeamSpeak web server list.
    public let isWeblistEnabled: Bool?
    /// The default server group id for new clients.
    public let defaultServerGroupId: Int?
    /// The default channel group id for new clients.
    public let defaultChannelGroupId: Int?
    /// The default channel admin group id.
    public let defaultChannelAdminGroupId: Int?
    /// The server file repository base path, when exposed.
    public let fileBase: String?
    /// The file transfer TCP port.
    public let fileTransferPort: Int?
    /// The complaint count that triggers automatic bans.
    public let complainAutoBanCount: Int?
    /// The automatic ban duration after complaint threshold is reached.
    public let complainAutoBanTime: Int?
    /// The time after which complaints are removed.
    public let complainRemoveTime: Int?
    /// The client count threshold for forced channel silence.
    public let minClientsInChannelBeforeForcedSilence: Int?
    /// The volume dimming factor applied for priority speakers.
    public let prioritySpeakerDimmModificator: Double?
    /// Anti-flood points reduced on every server tick.
    public let antiFloodPointsTickReduce: Int?
    /// Anti-flood points required before command blocking starts.
    public let antiFloodPointsNeededCommandBlock: Int?
    /// Anti-flood points required before IP blocking starts.
    public let antiFloodPointsNeededIPBlock: Int?
    /// The total number of regular client connections.
    public let clientConnections: Int?
    /// The total number of ServerQuery client connections.
    public let queryClientConnections: Int?
    /// The configured monthly download quota in bytes.
    public let downloadQuota: Int64?
    /// The configured monthly upload quota in bytes.
    public let uploadQuota: Int64?
    /// The number of bytes downloaded during the current month.
    public let monthlyBytesDownloaded: Int64?
    /// The number of bytes uploaded during the current month.
    public let monthlyBytesUploaded: Int64?
    /// The total number of downloaded bytes.
    public let totalBytesDownloaded: Int64?
    /// The total number of uploaded bytes.
    public let totalBytesUploaded: Int64?
    /// The packet loss fraction for speech packets.
    public let totalPacketLossSpeech: Double?
    /// The packet loss fraction for keepalive packets.
    public let totalPacketLossKeepalive: Double?
    /// The packet loss fraction for control packets.
    public let totalPacketLossControl: Double?
    /// The total packet loss fraction.
    public let totalPacketLossTotal: Double?
    /// The current aggregate ping in milliseconds.
    public let totalPing: Double?
    public let hostMessage: String?
    public let hostMessageMode: Int?
    public let hostBannerURL: String?
    public let hostBannerGraphicsURL: String?
    public let hostButtonTooltip: String?
    public let hostButtonURL: String?
    public let hostButtonGraphicsURL: String?
    /// The virtual server icon id reported by the server.
    public let iconId: Int?

    /// Creates a virtual server information snapshot.
    public init(
        uniqueIdentifier: String?,
        name: String,
        platform: String?,
        version: String?,
        createdAt: Date? = nil,
        clientsOnline: Int?,
        maxClients: Int?,
        clientsInQuery: Int? = nil,
        reservedSlots: Int?,
        channelsOnline: Int?,
        uptimeSeconds: Int?,
        welcomeMessage: String?,
        passwordProtected: Bool = false,
        status: String? = nil,
        machineId: String? = nil,
        codecEncryptionMode: Int? = nil,
        isWeblistEnabled: Bool? = nil,
        defaultServerGroupId: Int? = nil,
        defaultChannelGroupId: Int? = nil,
        defaultChannelAdminGroupId: Int? = nil,
        fileBase: String? = nil,
        fileTransferPort: Int? = nil,
        complainAutoBanCount: Int? = nil,
        complainAutoBanTime: Int? = nil,
        complainRemoveTime: Int? = nil,
        minClientsInChannelBeforeForcedSilence: Int? = nil,
        prioritySpeakerDimmModificator: Double? = nil,
        antiFloodPointsTickReduce: Int? = nil,
        antiFloodPointsNeededCommandBlock: Int? = nil,
        antiFloodPointsNeededIPBlock: Int? = nil,
        clientConnections: Int? = nil,
        queryClientConnections: Int? = nil,
        downloadQuota: Int64? = nil,
        uploadQuota: Int64? = nil,
        monthlyBytesDownloaded: Int64? = nil,
        monthlyBytesUploaded: Int64? = nil,
        totalBytesDownloaded: Int64? = nil,
        totalBytesUploaded: Int64? = nil,
        totalPacketLossSpeech: Double? = nil,
        totalPacketLossKeepalive: Double? = nil,
        totalPacketLossControl: Double? = nil,
        totalPacketLossTotal: Double? = nil,
        totalPing: Double? = nil,
        hostMessage: String? = nil,
        hostMessageMode: Int? = nil,
        hostBannerURL: String? = nil,
        hostBannerGraphicsURL: String? = nil,
        hostButtonTooltip: String? = nil,
        hostButtonURL: String? = nil,
        hostButtonGraphicsURL: String? = nil,
        iconId: Int? = nil
    ) {
        self.uniqueIdentifier = uniqueIdentifier
        self.name = name
        self.platform = platform
        self.version = version
        self.createdAt = createdAt
        self.clientsOnline = clientsOnline
        self.maxClients = maxClients
        self.clientsInQuery = clientsInQuery
        self.reservedSlots = reservedSlots
        self.channelsOnline = channelsOnline
        self.uptimeSeconds = uptimeSeconds
        self.welcomeMessage = welcomeMessage
        self.passwordProtected = passwordProtected
        self.status = status
        self.machineId = machineId
        self.codecEncryptionMode = codecEncryptionMode
        self.isWeblistEnabled = isWeblistEnabled
        self.defaultServerGroupId = defaultServerGroupId
        self.defaultChannelGroupId = defaultChannelGroupId
        self.defaultChannelAdminGroupId = defaultChannelAdminGroupId
        self.fileBase = fileBase
        self.fileTransferPort = fileTransferPort
        self.complainAutoBanCount = complainAutoBanCount
        self.complainAutoBanTime = complainAutoBanTime
        self.complainRemoveTime = complainRemoveTime
        self.minClientsInChannelBeforeForcedSilence = minClientsInChannelBeforeForcedSilence
        self.prioritySpeakerDimmModificator = prioritySpeakerDimmModificator
        self.antiFloodPointsTickReduce = antiFloodPointsTickReduce
        self.antiFloodPointsNeededCommandBlock = antiFloodPointsNeededCommandBlock
        self.antiFloodPointsNeededIPBlock = antiFloodPointsNeededIPBlock
        self.clientConnections = clientConnections
        self.queryClientConnections = queryClientConnections
        self.downloadQuota = downloadQuota
        self.uploadQuota = uploadQuota
        self.monthlyBytesDownloaded = monthlyBytesDownloaded
        self.monthlyBytesUploaded = monthlyBytesUploaded
        self.totalBytesDownloaded = totalBytesDownloaded
        self.totalBytesUploaded = totalBytesUploaded
        self.totalPacketLossSpeech = totalPacketLossSpeech
        self.totalPacketLossKeepalive = totalPacketLossKeepalive
        self.totalPacketLossControl = totalPacketLossControl
        self.totalPacketLossTotal = totalPacketLossTotal
        self.totalPing = totalPing
        self.hostMessage = hostMessage
        self.hostMessageMode = hostMessageMode
        self.hostBannerURL = hostBannerURL
        self.hostBannerGraphicsURL = hostBannerGraphicsURL
        self.hostButtonTooltip = hostButtonTooltip
        self.hostButtonURL = hostButtonURL
        self.hostButtonGraphicsURL = hostButtonGraphicsURL
        self.iconId = iconId
    }
}

/// Per-client connection quality and traffic counters reported by the server.
public struct TS3ConnectionInfo {
    /// The measured ping for this client connection in milliseconds.
    public let ping: Double?
    /// The total packet loss fraction for this client connection.
    public let packetLossTotal: Double?
    /// The speech packet loss fraction for this client connection.
    public let packetLossSpeech: Double?
    /// The keepalive packet loss fraction for this client connection.
    public let packetLossKeepalive: Double?
    /// The control packet loss fraction for this client connection.
    public let packetLossControl: Double?
    /// Bytes received during this connection.
    public let bytesReceived: Int64?
    /// Bytes sent during this connection.
    public let bytesSent: Int64?
    /// Bytes received during the current month.
    public let monthlyBytesReceived: Int64?
    /// Bytes sent during the current month.
    public let monthlyBytesSent: Int64?
    /// Total bytes received by this client identity on the server.
    public let totalBytesReceived: Int64?
    /// Total bytes sent by this client identity on the server.
    public let totalBytesSent: Int64?
    /// Duration of the current connection in seconds.
    public let connectedSeconds: Int?
    /// Idle time of the current connection in seconds.
    public let idleSeconds: Int?

    /// Creates a connection statistics snapshot.
    public init(
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
}

public struct TS3ServerLogEntry: Identifiable {
    public let id: Int
    public let timestamp: Date?
    public let level: String?
    public let channel: String?
    public let message: String
    public let rawLine: String

    /// Creates a virtual server log entry.
    public init(id: Int, timestamp: Date?, level: String?, channel: String?, message: String, rawLine: String) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.channel = channel
        self.message = message
        self.rawLine = rawLine
    }
}

public struct TS3ServerEdit {
    public var name: String?
    public var welcomeMessage: String?
    public var maxClients: Int?
    public var reservedSlots: Int?
    public var password: String?
    public var hostMessage: String?
    public var hostMessageMode: Int?
    public var hostBannerURL: String?
    public var hostBannerGraphicsURL: String?
    public var hostButtonTooltip: String?
    public var hostButtonURL: String?
    public var hostButtonGraphicsURL: String?
    public var iconId: Int?
    public var downloadQuota: Int64?
    public var uploadQuota: Int64?
    public var complainAutoBanCount: Int?
    public var complainAutoBanTime: Int?
    public var complainRemoveTime: Int?
    public var minClientsInChannelBeforeForcedSilence: Int?
    public var prioritySpeakerDimmModificator: Double?
    public var antiFloodPointsTickReduce: Int?
    public var antiFloodPointsNeededCommandBlock: Int?
    public var antiFloodPointsNeededIPBlock: Int?
    public var isWeblistEnabled: Bool?
    public var codecEncryptionMode: Int?
    public var defaultServerGroupId: Int?
    public var defaultChannelGroupId: Int?
    public var defaultChannelAdminGroupId: Int?

    /// Creates a partial virtual server update. Nil properties are left unchanged.
    public init(
        name: String? = nil,
        welcomeMessage: String? = nil,
        maxClients: Int? = nil,
        reservedSlots: Int? = nil,
        password: String? = nil,
        hostMessage: String? = nil,
        hostMessageMode: Int? = nil,
        hostBannerURL: String? = nil,
        hostBannerGraphicsURL: String? = nil,
        hostButtonTooltip: String? = nil,
        hostButtonURL: String? = nil,
        hostButtonGraphicsURL: String? = nil,
        iconId: Int? = nil,
        downloadQuota: Int64? = nil,
        uploadQuota: Int64? = nil,
        complainAutoBanCount: Int? = nil,
        complainAutoBanTime: Int? = nil,
        complainRemoveTime: Int? = nil,
        minClientsInChannelBeforeForcedSilence: Int? = nil,
        prioritySpeakerDimmModificator: Double? = nil,
        antiFloodPointsTickReduce: Int? = nil,
        antiFloodPointsNeededCommandBlock: Int? = nil,
        antiFloodPointsNeededIPBlock: Int? = nil,
        isWeblistEnabled: Bool? = nil,
        codecEncryptionMode: Int? = nil,
        defaultServerGroupId: Int? = nil,
        defaultChannelGroupId: Int? = nil,
        defaultChannelAdminGroupId: Int? = nil
    ) {
        self.name = name
        self.welcomeMessage = welcomeMessage
        self.maxClients = maxClients
        self.reservedSlots = reservedSlots
        self.password = password
        self.hostMessage = hostMessage
        self.hostMessageMode = hostMessageMode
        self.hostBannerURL = hostBannerURL
        self.hostBannerGraphicsURL = hostBannerGraphicsURL
        self.hostButtonTooltip = hostButtonTooltip
        self.hostButtonURL = hostButtonURL
        self.hostButtonGraphicsURL = hostButtonGraphicsURL
        self.iconId = iconId
        self.downloadQuota = downloadQuota
        self.uploadQuota = uploadQuota
        self.complainAutoBanCount = complainAutoBanCount
        self.complainAutoBanTime = complainAutoBanTime
        self.complainRemoveTime = complainRemoveTime
        self.minClientsInChannelBeforeForcedSilence = minClientsInChannelBeforeForcedSilence
        self.prioritySpeakerDimmModificator = prioritySpeakerDimmModificator
        self.antiFloodPointsTickReduce = antiFloodPointsTickReduce
        self.antiFloodPointsNeededCommandBlock = antiFloodPointsNeededCommandBlock
        self.antiFloodPointsNeededIPBlock = antiFloodPointsNeededIPBlock
        self.isWeblistEnabled = isWeblistEnabled
        self.codecEncryptionMode = codecEncryptionMode
        self.defaultServerGroupId = defaultServerGroupId
        self.defaultChannelGroupId = defaultChannelGroupId
        self.defaultChannelAdminGroupId = defaultChannelAdminGroupId
    }
}

public enum TS3ChannelCodecConstraints {
    public static let qualityRange = 0...10
    public static let latencyFactorRange = 1...10

    public static func isValidQuality(_ value: Int?) -> Bool {
        guard let value else { return true }
        return qualityRange.contains(value)
    }

    public static func isValidLatencyFactor(_ value: Int?) -> Bool {
        guard let value else { return true }
        return latencyFactorRange.contains(value)
    }
}

public struct TS3Channel: Identifiable {
    public let id: Int
    public let parentId: Int?
    public let order: Int?
    public let name: String
    /// The phonetic channel name used by clients with text-to-speech support.
    public let phoneticName: String?
    public let topic: String?
    public let description: String?
    public let isDefault: Bool
    public let isPasswordProtected: Bool
    public let isPermanent: Bool
    /// Whether the channel is semi-permanent.
    public let isSemiPermanent: Bool?
    public let neededTalkPower: Int?
    /// The subscribe power required to receive channel updates.
    public let neededSubscribePower: Int?
    public let codec: Int?
    /// The configured codec quality, when reported by the server.
    public let codecQuality: Int?
    /// The configured codec latency factor, when reported by the server.
    public let codecLatencyFactor: Int?
    /// Whether channel audio packets are sent without codec encryption.
    public let isCodecUnencrypted: Bool?
    /// The channel delete delay in seconds.
    public let deleteDelaySeconds: Int?
    /// The maximum number of clients allowed in the channel.
    public let maxClients: Int?
    /// The maximum number of clients allowed in the channel family.
    public let maxFamilyClients: Int?
    /// Whether the channel has no direct client limit.
    public let maxClientsUnlimited: Bool?
    /// Whether the channel family has no client limit.
    public let maxFamilyClientsUnlimited: Bool?
    /// Whether the channel inherits its family client limit.
    public let maxFamilyClientsInherited: Bool?
    /// The channel icon id reported by the server.
    public let iconId: Int?
    /// Whether the current client is subscribed to channel events, when reported by the server.
    public let isSubscribed: Bool?

    /// Creates a channel snapshot from server-provided metadata.
    public init(
        id: Int,
        parentId: Int? = nil,
        order: Int? = nil,
        name: String,
        phoneticName: String? = nil,
        topic: String?,
        description: String? = nil,
        isDefault: Bool = false,
        isPasswordProtected: Bool = false,
        isPermanent: Bool = false,
        isSemiPermanent: Bool? = nil,
        neededTalkPower: Int? = nil,
        neededSubscribePower: Int? = nil,
        codec: Int? = nil,
        codecQuality: Int? = nil,
        codecLatencyFactor: Int? = nil,
        isCodecUnencrypted: Bool? = nil,
        deleteDelaySeconds: Int? = nil,
        maxClients: Int? = nil,
        maxFamilyClients: Int? = nil,
        maxClientsUnlimited: Bool? = nil,
        maxFamilyClientsUnlimited: Bool? = nil,
        maxFamilyClientsInherited: Bool? = nil,
        iconId: Int? = nil,
        isSubscribed: Bool? = nil
    ) {
        self.id = id
        self.parentId = parentId
        self.order = order
        self.name = name
        self.phoneticName = phoneticName
        self.topic = topic
        self.description = description
        self.isDefault = isDefault
        self.isPasswordProtected = isPasswordProtected
        self.isPermanent = isPermanent
        self.isSemiPermanent = isSemiPermanent
        self.neededTalkPower = neededTalkPower
        self.neededSubscribePower = neededSubscribePower
        self.codec = codec
        self.codecQuality = codecQuality
        self.codecLatencyFactor = codecLatencyFactor
        self.isCodecUnencrypted = isCodecUnencrypted
        self.deleteDelaySeconds = deleteDelaySeconds
        self.maxClients = maxClients
        self.maxFamilyClients = maxFamilyClients
        self.maxClientsUnlimited = maxClientsUnlimited
        self.maxFamilyClientsUnlimited = maxFamilyClientsUnlimited
        self.maxFamilyClientsInherited = maxFamilyClientsInherited
        self.iconId = iconId
        self.isSubscribed = isSubscribed
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
    /// Whether the client is marked as channel commander.
    public let isChannelCommander: Bool
    /// Whether the client is marked as a priority speaker in the current channel.
    public let isPrioritySpeaker: Bool
    /// Whether the client is currently allowed to talk in a moderated channel.
    public let isTalker: Bool
    /// Whether the client has requested talk power from channel moderators.
    public let isRequestingTalkPower: Bool
    /// The optional message supplied with the talk power request.
    public let talkRequestMessage: String?
    public let talkPower: Int?
    public let channelGroupId: Int?
    public let serverGroups: [Int]
    public let description: String?
    public let avatarHash: String?
    /// The client icon id reported by the server.
    public let iconId: Int?
    /// The client application version reported by `clientinfo`.
    public let version: String?
    /// The client platform reported by `clientinfo`.
    public let platform: String?
    /// The two-letter country code reported by `clientinfo`.
    public let country: String?
    /// The remote IP address reported by `clientinfo`, when visible.
    public let ipAddress: String?
    /// The database record creation date, when reported.
    public let createdAt: Date?
    /// The last connection date, when reported.
    public let lastConnectedAt: Date?
    /// The number of times this client has connected to the server.
    public let totalConnections: Int?
    /// The client idle time in seconds, when reported.
    public let idleTimeSeconds: Int?
    /// The current connection duration in seconds, when reported.
    public let connectedSeconds: Int?

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
        isChannelCommander: Bool = false,
        isPrioritySpeaker: Bool = false,
        isTalker: Bool = false,
        isRequestingTalkPower: Bool = false,
        talkRequestMessage: String? = nil,
        talkPower: Int? = nil,
        channelGroupId: Int? = nil,
        serverGroups: [Int] = [],
        description: String? = nil,
        avatarHash: String? = nil,
        iconId: Int? = nil,
        version: String? = nil,
        platform: String? = nil,
        country: String? = nil,
        ipAddress: String? = nil,
        createdAt: Date? = nil,
        lastConnectedAt: Date? = nil,
        totalConnections: Int? = nil,
        idleTimeSeconds: Int? = nil,
        connectedSeconds: Int? = nil
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
        self.isChannelCommander = isChannelCommander
        self.isPrioritySpeaker = isPrioritySpeaker
        self.isTalker = isTalker
        self.isRequestingTalkPower = isRequestingTalkPower
        self.talkRequestMessage = talkRequestMessage
        self.talkPower = talkPower
        self.channelGroupId = channelGroupId
        self.serverGroups = serverGroups
        self.description = description
        self.avatarHash = avatarHash
        self.iconId = iconId
        self.version = version
        self.platform = platform
        self.country = country
        self.ipAddress = ipAddress
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
        self.totalConnections = totalConnections
        self.idleTimeSeconds = idleTimeSeconds
        self.connectedSeconds = connectedSeconds
    }
}

public struct TS3DatabaseClient: Identifiable {
    public let id: Int
    public let uniqueIdentifier: String?
    public let nickname: String
    public let createdAt: Date?
    public let lastConnectedAt: Date?
    public let totalConnections: Int?
    public let description: String?
    public let lastIP: String?

    /// Creates a client database record from server-provided metadata.
    public init(
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

public struct TS3ClientLocation: Identifiable {
    public var id: Int { clientId }
    public let clientId: Int
    public let nickname: String?

    /// Creates a currently connected client location.
    public init(clientId: Int, nickname: String?) {
        self.clientId = clientId
        self.nickname = nickname
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

/// A client poke notification received from the TeamSpeak server.
public struct TS3ClientPoke: Identifiable {
    /// Stable local identifier for UI lists.
    public let id = UUID()
    /// Time when the poke notification was received locally.
    public let timestamp: Date
    /// Runtime client ID of the sender, when provided by the server.
    public let senderId: Int?
    /// Display name of the sender.
    public let senderName: String
    /// Stable TeamSpeak unique identifier of the sender, when provided by the server.
    public let senderUniqueIdentifier: String?
    /// Poke message body.
    public let message: String
    /// Indicates whether this poke was sent by the current client.
    public let isOwnPoke: Bool

    /// Creates a received client poke record.
    public init(
        timestamp: Date,
        senderId: Int?,
        senderName: String,
        senderUniqueIdentifier: String?,
        message: String,
        isOwnPoke: Bool
    ) {
        self.timestamp = timestamp
        self.senderId = senderId
        self.senderName = senderName
        self.senderUniqueIdentifier = senderUniqueIdentifier
        self.message = message
        self.isOwnPoke = isOwnPoke
    }
}

/// A server activity notification generated by client view changes.
public struct TS3ServerActivityEvent: Identifiable {
    /// The kind of activity reported by the server.
    public enum Kind {
        /// A client became visible in a channel.
        case clientEntered
        /// A client left the visible server view.
        case clientLeft
        /// A client moved between visible channels.
        case clientMoved
        /// A channel was created.
        case channelCreated
        /// A channel was edited.
        case channelEdited
        /// A channel was deleted.
        case channelDeleted
        /// A channel was moved in the channel tree.
        case channelMoved
        /// A channel password changed.
        case channelPasswordChanged
        /// A channel description changed.
        case channelDescriptionChanged
    }

    /// Stable local identifier for UI lists.
    public let id = UUID()
    /// Time when the activity was received locally.
    public let timestamp: Date
    /// Activity kind.
    public let kind: Kind
    /// Runtime client ID for the affected client.
    public let clientId: Int
    /// Display name for the affected client.
    public let clientName: String
    /// Runtime channel ID for the affected channel, when this is a channel activity.
    public let channelId: Int?
    /// Display name for the affected channel, when known.
    public let channelName: String?
    /// Source channel ID, when reported by the server.
    public let fromChannelId: Int?
    /// Destination channel ID, when reported by the server.
    public let toChannelId: Int?
    /// Runtime client ID of the invoker, when this activity was caused by another user.
    public let invokerId: Int?
    /// Display name of the invoker, when provided.
    public let invokerName: String?
    /// Server reason code, when provided.
    public let reasonId: Int?
    /// Server reason message, when provided.
    public let reasonMessage: String?
    /// Indicates whether the affected client is the current client.
    public let isOwnClient: Bool

    /// Creates a server activity notification.
    public init(
        timestamp: Date,
        kind: Kind,
        clientId: Int,
        clientName: String,
        channelId: Int? = nil,
        channelName: String? = nil,
        fromChannelId: Int?,
        toChannelId: Int?,
        invokerId: Int?,
        invokerName: String?,
        reasonId: Int?,
        reasonMessage: String?,
        isOwnClient: Bool
    ) {
        self.timestamp = timestamp
        self.kind = kind
        self.clientId = clientId
        self.clientName = clientName
        self.channelId = channelId
        self.channelName = channelName
        self.fromChannelId = fromChannelId
        self.toChannelId = toChannelId
        self.invokerId = invokerId
        self.invokerName = invokerName
        self.reasonId = reasonId
        self.reasonMessage = reasonMessage
        self.isOwnClient = isOwnClient
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

public struct TS3ComplaintEntry: Identifiable {
    public var id: String { "\(targetClientDatabaseId):\(sourceClientDatabaseId)" }
    public let targetClientDatabaseId: Int
    public let targetName: String?
    public let sourceClientDatabaseId: Int
    public let sourceName: String?
    public let message: String?
    public let timestamp: Date?

    /// Creates a complaint-list entry from server-provided metadata.
    public init(
        targetClientDatabaseId: Int,
        targetName: String?,
        sourceClientDatabaseId: Int,
        sourceName: String?,
        message: String?,
        timestamp: Date?
    ) {
        self.targetClientDatabaseId = targetClientDatabaseId
        self.targetName = targetName
        self.sourceClientDatabaseId = sourceClientDatabaseId
        self.sourceName = sourceName
        self.message = message
        self.timestamp = timestamp
    }
}

public struct TS3TemporaryServerPassword: Identifiable {
    public var id: String { password }
    public let password: String
    public let creatorUniqueIdentifier: String?
    public let creatorDatabaseId: Int?
    public let creatorName: String?
    public let targetChannelId: Int?
    public let targetChannelPassword: String?
    public let createdAt: Date?
    public let durationSeconds: Int?
    public let description: String?

    /// Creates a temporary server password entry from server-provided metadata.
    public init(
        password: String,
        creatorUniqueIdentifier: String?,
        creatorDatabaseId: Int?,
        creatorName: String?,
        targetChannelId: Int?,
        targetChannelPassword: String?,
        createdAt: Date?,
        durationSeconds: Int?,
        description: String?
    ) {
        self.password = password
        self.creatorUniqueIdentifier = creatorUniqueIdentifier
        self.creatorDatabaseId = creatorDatabaseId
        self.creatorName = creatorName
        self.targetChannelId = targetChannelId
        self.targetChannelPassword = targetChannelPassword
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.description = description
    }
}

public enum TS3PrivilegeKeyType: Int, CaseIterable, Identifiable {
    case serverGroup = 0
    case channelGroup = 1

    public var id: Int { rawValue }
}

public struct TS3PrivilegeKeyEntry: Identifiable {
    public var id: String { key }
    public let key: String
    public let type: TS3PrivilegeKeyType?
    public let groupId: Int
    public let channelId: Int?
    public let createdAt: Date?
    public let description: String?
    public let customSet: String?

    /// Creates a privilege-key entry from server-provided metadata.
    public init(
        key: String,
        type: TS3PrivilegeKeyType?,
        groupId: Int,
        channelId: Int?,
        createdAt: Date?,
        description: String?,
        customSet: String?
    ) {
        self.key = key
        self.type = type
        self.groupId = groupId
        self.channelId = channelId
        self.createdAt = createdAt
        self.description = description
        self.customSet = customSet
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

public struct TS3GroupClient: Identifiable {
    public var id: String { "\(clientDatabaseId):\(channelId ?? 0)" }
    public let clientDatabaseId: Int
    public let uniqueIdentifier: String?
    public let nickname: String?
    public let channelId: Int?

    /// Creates a client membership entry for a permission group.
    public init(
        clientDatabaseId: Int,
        uniqueIdentifier: String?,
        nickname: String?,
        channelId: Int?
    ) {
        self.clientDatabaseId = clientDatabaseId
        self.uniqueIdentifier = uniqueIdentifier
        self.nickname = nickname
        self.channelId = channelId
    }
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

/// Describes a file transfer socket negotiated through the TS3 command channel.
public struct TS3FileTransferParameters {
    /// Client-generated transfer id sent as `clientftfid`.
    public let clientTransferId: Int
    /// Server-generated transfer id returned as `serverftfid`.
    public let serverTransferId: Int
    /// File transfer key that must be sent first on the TCP socket.
    public let key: String
    /// File transfer host returned by the server.
    public let host: String
    /// File transfer TCP port returned by the server.
    public let port: Int
    /// Expected byte count when the server provides one.
    public let size: Int64?
    /// Byte offset where the socket transfer should begin.
    public let seekPosition: Int64

    /// Creates a server-negotiated file transfer descriptor.
    public init(
        clientTransferId: Int,
        serverTransferId: Int,
        key: String,
        host: String,
        port: Int,
        size: Int64?,
        seekPosition: Int64 = 0
    ) {
        self.clientTransferId = clientTransferId
        self.serverTransferId = serverTransferId
        self.key = key
        self.host = host
        self.port = port
        self.size = size
        self.seekPosition = seekPosition
    }
}

/// Utilities for TeamSpeak virtual server icon files.
public enum TS3IconFile {
    /// Returns the virtual server file path for an icon id.
    public static func path(for iconId: Int) -> String {
        "/icon_\(iconId)"
    }

    /// Calculates the TeamSpeak icon id for icon file bytes.
    public static func iconId(for data: Data) -> Int {
        Int(TS3CRC32.checksum(data))
    }
}

/// Describes whether a permission group is a template, regular, or query group.
public enum TS3PermissionGroupDatabaseType: Int, CaseIterable, Identifiable {
    /// A template group used as a basis for new groups.
    case template = 0
    /// A normal permission group used by regular clients.
    case regular = 1
    /// A server query permission group.
    case query = 2

    /// The numeric TeamSpeak database type.
    public var id: Int { rawValue }
}

public struct TS3ServerGroup: Identifiable {
    public let id: Int
    public let name: String
    /// The database type reported by the server, when available.
    public let type: TS3PermissionGroupDatabaseType?

    /// Creates a server group summary.
    public init(id: Int, name: String, type: TS3PermissionGroupDatabaseType? = nil) {
        self.id = id
        self.name = name
        self.type = type
    }
}

public struct TS3ChannelGroup: Identifiable {
    public let id: Int
    public let name: String
    /// The database type reported by the server, when available.
    public let type: TS3PermissionGroupDatabaseType?

    /// Creates a channel group summary.
    public init(id: Int, name: String, type: TS3PermissionGroupDatabaseType? = nil) {
        self.id = id
        self.name = name
        self.type = type
    }
}

public protocol TS3ClientDelegate: AnyObject {
    func ts3ClientDidConnect(_ client: TS3Client)
    func ts3Client(_ client: TS3Client, didDisconnectWith error: Error?)
    func ts3Client(_ client: TS3Client, didUpdateServerInfo info: TS3ServerInfo)
    func ts3Client(_ client: TS3Client, didUpdateChannels channels: [TS3Channel])
    func ts3Client(_ client: TS3Client, didUpdateClients clients: [TS3ServerClient])
    func ts3Client(_ client: TS3Client, didReceiveTextMessage message: TS3TextMessage)
    func ts3Client(_ client: TS3Client, didReceiveClientPoke poke: TS3ClientPoke)
    func ts3Client(_ client: TS3Client, didReceiveServerActivity event: TS3ServerActivityEvent)
    func ts3Client(_ client: TS3Client, didUpdateServerGroups groups: [TS3ServerGroup])
    func ts3Client(_ client: TS3Client, didUpdateChannelGroups groups: [TS3ChannelGroup])
}

public extension TS3ClientDelegate {
    func ts3Client(_ client: TS3Client, didUpdateServerInfo info: TS3ServerInfo) {}
    func ts3Client(_ client: TS3Client, didReceiveTextMessage message: TS3TextMessage) {}
    func ts3Client(_ client: TS3Client, didReceiveClientPoke poke: TS3ClientPoke) {}
    func ts3Client(_ client: TS3Client, didReceiveServerActivity event: TS3ServerActivityEvent) {}
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
    case serverErrorWithCode(id: Int, message: String)
    case packetTooLarge
    case invalidState
    case timeout
    case disconnected
    case compressionUnsupported
    case decompressionTooLarge
    case fileTransferFailed
}

extension TS3Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "This feature is not implemented."
        case .audioInputUnavailable:
            return "Audio input is unavailable."
        case .invalidEscape:
            return "The command contains an invalid escape sequence."
        case .ambiguousCommand:
            return "The command response is ambiguous."
        case .derDecodeFailed:
            return "Failed to decode DER data."
        case .invalidBeta:
            return "The server returned an invalid beta value."
        case .invalidInitStep:
            return "The TeamSpeak handshake step is invalid."
        case .invalidCommand:
            return "The TeamSpeak command is invalid."
        case .invalidIdentity:
            return "The TeamSpeak identity is invalid."
        case .invalidKey:
            return "The key is invalid."
        case .invalidLicense:
            return "The license data is invalid."
        case .invalidMac:
            return "The packet authentication code is invalid."
        case .cryptoFailed:
            return "A cryptographic operation failed."
        case .serverError(let message):
            return message
        case .serverErrorWithCode(let id, let message):
            return "\(message) (id \(id))"
        case .packetTooLarge:
            return "The packet is too large."
        case .invalidState:
            return "The client is in an invalid state for this operation."
        case .timeout:
            return "The connection timed out."
        case .disconnected:
            return "The client is disconnected."
        case .compressionUnsupported:
            return "The compression format is unsupported."
        case .decompressionTooLarge:
            return "The decompressed payload is too large."
        case .fileTransferFailed:
            return "The file transfer failed."
        }
    }
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
