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

    var title: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        }
    }
}

extension TS3AudioTransmitMode {
    var title: String {
        switch self {
        case .pushToTalk:
            return "Push To Talk"
        case .continuous:
            return "Continuous"
        case .voiceActivation:
            return "Voice Activation"
        }
    }

    static func title(for rawValue: String) -> String {
        TS3AudioTransmitMode(rawValue: rawValue)?.title ?? rawValue
    }
}

enum TS3WhisperActivationMode: String, CaseIterable, Identifiable, Codable {
    case holdToWhisper
    case tapToToggle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .holdToWhisper:
            return "Hold to Whisper"
        case .tapToToggle:
            return "Tap to Toggle"
        }
    }

    var detail: String {
        switch self {
        case .holdToWhisper:
            return "Press and hold the on-screen control, or use separate start and stop shortcuts on Catalyst."
        case .tapToToggle:
            return "Tap once to start temporary whisper and tap again to stop it."
        }
    }
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

enum TS3ChannelCodec: Int, CaseIterable, Identifiable {
    case speexNarrowband = 0
    case speexWideband = 1
    case speexUltraWideband = 2
    case celtMono = 3
    case opusVoice = 4
    case opusMusic = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .speexNarrowband:
            return "Speex Narrowband"
        case .speexWideband:
            return "Speex Wideband"
        case .speexUltraWideband:
            return "Speex Ultra-Wideband"
        case .celtMono:
            return "CELT Mono"
        case .opusVoice:
            return "Opus Voice"
        case .opusMusic:
            return "Opus Music"
        }
    }

    static func title(for rawValue: Int?) -> String? {
        guard let rawValue else { return nil }
        if let codec = TS3ChannelCodec(rawValue: rawValue) {
            return "\(codec.title) (\(rawValue))"
        }
        return "Unknown (\(rawValue))"
    }
}

struct TS3ChannelCodecQuality: Identifiable {
    let value: Int

    var id: Int { value }

    var title: String {
        "Quality \(value)"
    }

    static let allCases = (0...10).map(TS3ChannelCodecQuality.init)

    static func title(for value: Int?) -> String? {
        guard let value else { return nil }
        if TS3ChannelCodecConstraints.qualityRange.contains(value) {
            return "Quality \(value)"
        }
        return "Unknown (\(value))"
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
    var neededJoinPower: Int?
    var neededSubscribePower: Int?
    var neededDescriptionViewPower: Int?
    var codec: Int?
    var codecQuality: Int?
    var codecLatencyFactor: Int?
    var isCodecUnencrypted: Bool?
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

enum TS3ChannelDraftValidator {
    static func validationMessages(
        name: String,
        neededTalkPower: String,
        neededJoinPower: String,
        neededSubscribePower: String,
        neededDescriptionViewPower: String,
        codecQuality: String,
        codecLatencyFactor: String,
        order: String,
        deleteDelaySeconds: String,
        iconId: String,
        maxClients: String,
        maxClientsUnlimited: Bool,
        maxFamilyClients: String,
        maxFamilyClientsUnlimited: Bool,
        maxFamilyClientsInherited: Bool
    ) -> [String] {
        var messages: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Name is required before saving.")
        }
        if !isOptionalInt(neededTalkPower) {
            messages.append("Needed talk power must be numeric.")
        }
        if !isOptionalInt(neededJoinPower) {
            messages.append("Needed join power must be numeric.")
        }
        if !isOptionalInt(neededSubscribePower) {
            messages.append("Needed subscribe power must be numeric.")
        }
        if !isOptionalInt(neededDescriptionViewPower) {
            messages.append("Needed description view power must be numeric.")
        }
        if !isOptionalInt(codecQuality) ||
            !TS3ChannelCodecConstraints.isValidQuality(parsedOptionalInt(codecQuality)) {
            messages.append("Codec quality must be between \(TS3ChannelCodecConstraints.qualityRange.lowerBound) and \(TS3ChannelCodecConstraints.qualityRange.upperBound).")
        }
        if !isOptionalInt(codecLatencyFactor) ||
            !TS3ChannelCodecConstraints.isValidLatencyFactor(parsedOptionalInt(codecLatencyFactor)) {
            messages.append("Codec latency factor must be between \(TS3ChannelCodecConstraints.latencyFactorRange.lowerBound) and \(TS3ChannelCodecConstraints.latencyFactorRange.upperBound).")
        }
        if !isOptionalInt(order) {
            messages.append("Position must be numeric.")
        }
        if !isOptionalInt(deleteDelaySeconds) {
            messages.append("Delete delay must be numeric.")
        }
        if !isOptionalInt(iconId) {
            messages.append("Icon ID must be numeric.")
        }
        if !maxClientsUnlimited && !isRequiredInt(maxClients) {
            messages.append("Max clients is required when the client limit is not unlimited.")
        }
        if !maxFamilyClientsInherited && !maxFamilyClientsUnlimited && !isRequiredInt(maxFamilyClients) {
            messages.append("Max family clients is required when the family limit is not inherited or unlimited.")
        }
        return messages
    }

    static func parsedOptionalInt(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Int(trimmed)
    }

    static func isOptionalInt(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Int(trimmed) != nil
    }

    static func isRequiredInt(_ text: String) -> Bool {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
}

enum TS3ServerSettingsDraftValidator {
    static func validationMessages(
        name: String,
        port: String,
        autostart: String?,
        maxClients: String,
        reservedSlots: String,
        hostMessageMode: String,
        hostBannerMode: String,
        hostBannerGraphicsInterval: String,
        iconId: String,
        downloadQuota: String,
        uploadQuota: String,
        maxDownloadTotalBandwidth: String,
        maxUploadTotalBandwidth: String,
        complainAutoBanCount: String,
        complainAutoBanTime: String,
        complainRemoveTime: String,
        minClientsInChannelBeforeForcedSilence: String,
        prioritySpeakerDimmModificator: String,
        antiFloodPointsTickReduce: String,
        antiFloodPointsNeededCommandBlock: String,
        antiFloodPointsNeededIPBlock: String,
        antiFloodPointsNeededPluginBlock: String,
        logClient: String?,
        logQuery: String?,
        logChannel: String?,
        logPermissions: String?,
        logServer: String?,
        logFileTransfer: String?,
        weblistEnabled: String?,
        codecEncryptionMode: String,
        defaultServerGroupId: String,
        defaultChannelGroupId: String,
        defaultChannelAdminGroupId: String,
        neededIdentitySecurityLevel: String,
        minClientVersion: String,
        minAndroidVersion: String,
        minIOSVersion: String
    ) -> [String] {
        var messages: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Server name is required before saving.")
        }
        if !isOptionalInt(maxClients) {
            messages.append("Max clients must be numeric.")
        }
        if !isOptionalInt(port) {
            messages.append("Server port must be numeric.")
        }
        if !isOptionalInt(reservedSlots) {
            messages.append("Reserved slots must be numeric.")
        }
        if !isOptionalBoolDraft(autostart) {
            messages.append("Autostart must be enabled, disabled, true, false, 1, or 0.")
        }
        if !isOptionalInt(hostMessageMode) {
            messages.append("Host message mode must be numeric.")
        }
        if !isOptionalInt(hostBannerMode) {
            messages.append("Host banner mode must be numeric.")
        }
        if !isOptionalInt(hostBannerGraphicsInterval) {
            messages.append("Banner refresh seconds must be numeric.")
        }
        if !isOptionalInt(iconId) {
            messages.append("Icon ID must be numeric.")
        }
        if !isOptionalInt64(downloadQuota) {
            messages.append("Download quota must be numeric.")
        }
        if !isOptionalInt64(uploadQuota) {
            messages.append("Upload quota must be numeric.")
        }
        if !isOptionalInt64(maxDownloadTotalBandwidth) {
            messages.append("Max download bandwidth must be numeric.")
        }
        if !isOptionalInt64(maxUploadTotalBandwidth) {
            messages.append("Max upload bandwidth must be numeric.")
        }
        if !isOptionalInt(neededIdentitySecurityLevel) {
            messages.append("Needed identity security level must be numeric.")
        }
        if !isOptionalInt(minClientVersion) {
            messages.append("Minimum client version must be numeric.")
        }
        if !isOptionalInt(minAndroidVersion) {
            messages.append("Minimum Android version must be numeric.")
        }
        if !isOptionalInt(minIOSVersion) {
            messages.append("Minimum iOS version must be numeric.")
        }
        if !isOptionalInt(complainAutoBanCount) {
            messages.append("Auto-ban complaint count must be numeric.")
        }
        if !isOptionalInt(complainAutoBanTime) {
            messages.append("Auto-ban seconds must be numeric.")
        }
        if !isOptionalInt(complainRemoveTime) {
            messages.append("Complaint remove seconds must be numeric.")
        }
        if !isOptionalInt(minClientsInChannelBeforeForcedSilence) {
            messages.append("Forced silence client count must be numeric.")
        }
        if !isOptionalDouble(prioritySpeakerDimmModificator) {
            messages.append("Priority speaker dimming must be numeric.")
        }
        if !isOptionalInt(antiFloodPointsTickReduce) {
            messages.append("Anti-flood tick reduce must be numeric.")
        }
        if !isOptionalInt(antiFloodPointsNeededCommandBlock) {
            messages.append("Anti-flood command block must be numeric.")
        }
        if !isOptionalInt(antiFloodPointsNeededIPBlock) {
            messages.append("Anti-flood IP block must be numeric.")
        }
        if !isOptionalInt(antiFloodPointsNeededPluginBlock) {
            messages.append("Anti-flood plugin block must be numeric.")
        }
        if !isOptionalBoolDraft(logClient) {
            messages.append("Client log must be enabled, disabled, true, false, 1, or 0.")
        }
        if !isOptionalBoolDraft(logQuery) {
            messages.append("Query log must be enabled, disabled, true, false, 1, or 0.")
        }
        if !isOptionalBoolDraft(logChannel) {
            messages.append("Channel log must be enabled, disabled, true, false, 1, or 0.")
        }
        if !isOptionalBoolDraft(logPermissions) {
            messages.append("Permission log must be enabled, disabled, true, false, 1, or 0.")
        }
        if !isOptionalBoolDraft(logServer) {
            messages.append("Server log must be enabled, disabled, true, false, 1, or 0.")
        }
        if !isOptionalBoolDraft(logFileTransfer) {
            messages.append("File transfer log must be enabled, disabled, true, false, 1, or 0.")
        }
        if !isOptionalBoolDraft(weblistEnabled) {
            messages.append("Server list must be listed, hidden, true, false, 1, or 0.")
        }
        if !isOptionalInt(codecEncryptionMode) {
            messages.append("Codec encryption mode must be numeric.")
        }
        if !isOptionalInt(defaultServerGroupId) {
            messages.append("Default server group ID must be numeric.")
        }
        if !isOptionalInt(defaultChannelGroupId) {
            messages.append("Default channel group ID must be numeric.")
        }
        if !isOptionalInt(defaultChannelAdminGroupId) {
            messages.append("Default channel admin group ID must be numeric.")
        }
        return messages
    }

    static func boolDraftValue(_ value: String?) -> Bool? {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "listed", "enabled":
            return true
        case "0", "false", "no", "hidden", "disabled":
            return false
        default:
            return nil
        }
    }

    static func isOptionalBoolDraft(_ value: String?) -> Bool {
        guard let value else { return true }
        return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || boolDraftValue(value) != nil
    }

    private static func isOptionalInt(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Int(trimmed) != nil
    }

    private static func isOptionalInt64(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Int64(trimmed) != nil
    }

    private static func isOptionalDouble(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Double(trimmed) != nil
    }
}

enum TS3PermissionDraftValidator {
    static func validationMessages(
        scope: TS3PermissionEditScope,
        name: String,
        value: String
    ) -> [String] {
        var messages: [String] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Permission name is required before saving.")
        }
        if Int(value.trimmingCharacters(in: .whitespacesAndNewlines)) == nil {
            messages.append("Permission value must be numeric.")
        }
        return messages
    }
}

struct TS3SavedChannelPassword: Identifiable, Codable, Equatable {
    var id: UUID
    var serverKey: String
    var channelPath: String
    var password: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        serverKey: String,
        channelPath: String,
        password: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.serverKey = serverKey
        self.channelPath = channelPath
        self.password = password
        self.updatedAt = updatedAt
    }
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

struct TS3PokeSummary: Identifiable, Codable {
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

    var messageText: String {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Poke" : trimmed
    }

    var directionTitle: String {
        isOwnPoke ? "Sent to" : "Received from"
    }

    var displayTitle: String {
        "\(isOwnPoke ? "Sent to" : "From") \(senderName)"
    }

    var clipboardSummary: String {
        var parts = [
            "direction=\(isOwnPoke ? "out" : "in")",
            "sender=\(senderName)",
            "timestamp=\(Int(timestamp.timeIntervalSince1970))"
        ]
        if let senderId {
            parts.append("senderId=\(senderId)")
        }
        if let senderUniqueIdentifier = senderUniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !senderUniqueIdentifier.isEmpty {
            parts.append("senderUid=\(senderUniqueIdentifier)")
        }
        parts.append("message=\(messageText)")
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            "\(directionTitle) \(senderName)",
            "Message \(messageText)"
        ]
        if let senderUniqueIdentifier = senderUniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !senderUniqueIdentifier.isEmpty {
            parts.append("Unique ID available")
        }
        return parts.joined(separator: ". ")
    }
}

enum TS3PokeDraftValidator {
    static func validationMessages(
        targetName: String?,
        targetClientId: Int?,
        message: String
    ) -> [String] {
        var messages: [String] = []
        let targetName = targetName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if targetName?.isEmpty != false && targetClientId == nil {
            messages.append("Select a client before sending a poke.")
        }
        if let targetClientId, targetClientId <= 0 {
            messages.append("Target client id must be positive before sending a poke.")
        }
        if message.rangeOfCharacter(from: .newlines) != nil {
            messages.append("Poke message must be a single line.")
        }
        return messages
    }

    static func creationSummary(
        targetName: String?,
        targetClientId: Int?,
        message: String
    ) -> String {
        var parts: [String] = []
        if let targetName = targetName?.trimmingCharacters(in: .whitespacesAndNewlines), !targetName.isEmpty {
            parts.append("target=\(targetName)")
        } else {
            parts.append("target=Missing")
        }
        if let targetClientId {
            parts.append("clientId=\(targetClientId)")
        } else {
            parts.append("clientId=Missing")
        }
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        parts.append("message=\(message.isEmpty ? "Poke" : message)")
        return parts.joined(separator: " | ")
    }
}

struct TS3ActivitySummary: Identifiable, Codable {
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

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        kind: TS3ServerActivityEvent.Kind,
        clientId: Int,
        clientName: String,
        channelId: Int?,
        channelName: String?,
        fromChannelId: Int?,
        toChannelId: Int?,
        invokerName: String?,
        reasonId: Int?,
        reasonMessage: String?,
        isOwnClient: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.clientId = clientId
        self.clientName = clientName
        self.channelId = channelId
        self.channelName = channelName
        self.fromChannelId = fromChannelId
        self.toChannelId = toChannelId
        self.invokerName = invokerName
        self.reasonId = reasonId
        self.reasonMessage = reasonMessage
        self.isOwnClient = isOwnClient
    }

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

    var clipboardSummary: String {
        var parts = [
            "kind=\(kind.encodedValueForSummary)",
            "client=\(clientName)",
            "clientId=\(clientId)",
            "timestamp=\(Int(timestamp.timeIntervalSince1970))",
            "own=\(isOwnClient ? "true" : "false")"
        ]
        if let channelName, !channelName.isEmpty {
            parts.append("channel=\(channelName)")
        }
        if let channelId {
            parts.append("channelId=\(channelId)")
        }
        if let fromChannelId {
            parts.append("from=\(fromChannelId)")
        }
        if let toChannelId {
            parts.append("to=\(toChannelId)")
        }
        if let invokerName, !invokerName.isEmpty {
            parts.append("invoker=\(invokerName)")
        }
        if let reasonId {
            parts.append("reasonId=\(reasonId)")
        }
        if let reasonMessage, !reasonMessage.isEmpty {
            parts.append("reason=\(reasonMessage)")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            kind.accessibilityTitle,
            "Client \(clientName)"
        ]
        if isOwnClient {
            parts.append("Current client")
        }
        if let channelName, !channelName.isEmpty {
            parts.append("Channel \(channelName)")
        } else if let channelId {
            parts.append("Channel ID \(channelId)")
        }
        if let fromChannelId {
            parts.append("From channel ID \(fromChannelId)")
        }
        if let toChannelId {
            parts.append("To channel ID \(toChannelId)")
        }
        if let invokerName, !invokerName.isEmpty {
            parts.append("Invoker \(invokerName)")
        }
        if let reasonMessage, !reasonMessage.isEmpty {
            parts.append("Reason \(reasonMessage)")
        }
        return parts.joined(separator: ". ")
    }

    func rowAccessibilityValue(messageText: String, detailText: String?) -> String {
        var parts = [accessibilityValue, messageText]
        if let detailText, !detailText.isEmpty {
            parts.append(detailText)
        }
        return parts.joined(separator: ". ")
    }
}

extension TS3ServerActivityEvent.Kind: Codable {
    fileprivate var encodedValueForSummary: String {
        encodedValue
    }

    private var encodedValue: String {
        switch self {
        case .clientEntered:
            return "clientEntered"
        case .clientLeft:
            return "clientLeft"
        case .clientMoved:
            return "clientMoved"
        case .channelCreated:
            return "channelCreated"
        case .channelEdited:
            return "channelEdited"
        case .channelDeleted:
            return "channelDeleted"
        case .channelMoved:
            return "channelMoved"
        case .channelPasswordChanged:
            return "channelPasswordChanged"
        case .channelDescriptionChanged:
            return "channelDescriptionChanged"
        }
    }

    fileprivate var accessibilityTitle: String {
        switch self {
        case .clientEntered:
            return "Client joined"
        case .clientLeft:
            return "Client left"
        case .clientMoved:
            return "Client moved"
        case .channelCreated:
            return "Channel created"
        case .channelEdited:
            return "Channel edited"
        case .channelDeleted:
            return "Channel deleted"
        case .channelMoved:
            return "Channel moved"
        case .channelPasswordChanged:
            return "Channel password changed"
        case .channelDescriptionChanged:
            return "Channel description changed"
        }
    }

    public init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        switch value {
        case "clientEntered":
            self = .clientEntered
        case "clientLeft":
            self = .clientLeft
        case "clientMoved":
            self = .clientMoved
        case "channelCreated":
            self = .channelCreated
        case "channelEdited":
            self = .channelEdited
        case "channelDeleted":
            self = .channelDeleted
        case "channelMoved":
            self = .channelMoved
        case "channelPasswordChanged":
            self = .channelPasswordChanged
        case "channelDescriptionChanged":
            self = .channelDescriptionChanged
        default:
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Unknown activity event kind: \(value)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encodedValue)
    }
}

private struct TS3EventHistoryArchive: Codable {
    var activityEvents: [TS3ActivitySummary]
    var pokeEvents: [TS3PokeSummary]

    static let empty = TS3EventHistoryArchive(activityEvents: [], pokeEvents: [])
}

struct TS3EventHistoryArchivePreview {
    let activityCount: Int
    let pokeCount: Int
    let currentActivityCount: Int
    let currentPokeCount: Int
    let activitySummaries: [String]
    let pokeSummaries: [String]

    var totalCount: Int {
        activityCount + pokeCount
    }

    var currentTotalCount: Int {
        currentActivityCount + currentPokeCount
    }

    var hasEvents: Bool {
        totalCount > 0
    }

    var clipboardSummary: String {
        (activitySummaries + pokeSummaries).joined(separator: "\n")
    }
}

enum TS3ContactStatus: String, CaseIterable, Codable, Identifiable {
    case neutral
    case friend
    case ignored
    case blocked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neutral:
            return "Neutral"
        case .friend:
            return "Friend"
        case .ignored:
            return "Ignored"
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

extension TS3ContactEntry {
    func clipboardSummary(onlineNickname: String? = nil) -> String {
        var parts = [
            "nickname=\(nickname)",
            "uid=\(uniqueIdentifier)",
            "status=\(status.title)"
        ]
        if let onlineNickname, !onlineNickname.isEmpty {
            parts.append("onlineAs=\(onlineNickname)")
        }
        if !note.isEmpty {
            parts.append("note=\(note)")
        }
        parts.append("updated=\(Self.dateText(updatedAt))")
        return parts.joined(separator: " | ")
    }

    func accessibilityValue(onlineNickname: String? = nil) -> String {
        var parts = [
            "Status \(status.title)",
            "Unique ID \(uniqueIdentifier)"
        ]
        if let onlineNickname, !onlineNickname.isEmpty {
            parts.append("Online as \(onlineNickname)")
        }
        if !note.isEmpty {
            parts.append("Note \(note)")
        }
        parts.append("Updated \(Self.dateText(updatedAt))")
        return parts.joined(separator: ". ")
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TS3ContactImportPreview {
    let importedCount: Int
    let validCount: Int
    let invalidCount: Int
    let duplicateCount: Int
    let newCount: Int
    let updatedCount: Int
    let unchangedCount: Int
    let newContactNames: [String]
    let updatedContactNames: [String]
    let unchangedContactNames: [String]
}

struct TS3ContactImportOptions: Equatable {
    var newContacts: Bool
    var updatedContacts: Bool

    static let all = TS3ContactImportOptions(
        newContacts: true,
        updatedContacts: true
    )

    var hasSelectedEntries: Bool {
        newContacts || updatedContacts
    }
}

struct TS3ContactNoteDraft {
    let contacts: [TS3ContactEntry]
    let note: String

    var uniqueContacts: [TS3ContactEntry] {
        var seen = Set<String>()
        return contacts.filter { contact in
            seen.insert(contact.uniqueIdentifier).inserted
        }
    }

    var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var validationMessages: [String] {
        var messages: [String] = []
        if uniqueContacts.isEmpty {
            messages.append("Select contacts before applying a note.")
        }
        if trimmedNote.isEmpty {
            messages.append("Enter a note to apply to the selected contacts.")
        }
        return messages
    }

    var clipboardSummary: String {
        var parts = [
            "contacts=\(uniqueContacts.count)",
            "targets=\(targetSummary)",
            "note=\(trimmedNote.isEmpty ? "Missing" : trimmedNote)"
        ]
        let existingNoteCount = uniqueContacts.filter { !$0.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
        if existingNoteCount > 0 {
            parts.append("appendToExisting=\(existingNoteCount)")
        }
        return parts.joined(separator: " | ")
    }

    private var targetSummary: String {
        let names = uniqueContacts.map(\.nickname)
        let visible = names.prefix(6).joined(separator: ", ")
        let remainingCount = names.count - min(names.count, 6)
        guard remainingCount > 0 else {
            return visible.isEmpty ? "None" : visible
        }
        return "\(visible), +\(remainingCount) more"
    }
}

struct TS3ContactStatusDraft {
    let contacts: [TS3ContactEntry]
    let status: TS3ContactStatus

    var uniqueContacts: [TS3ContactEntry] {
        var seen = Set<String>()
        return contacts.filter { contact in
            seen.insert(contact.uniqueIdentifier).inserted
        }
    }

    var validationMessages: [String] {
        uniqueContacts.isEmpty ? ["Select contacts before changing their status."] : []
    }

    var clipboardSummary: String {
        [
            "contacts=\(uniqueContacts.count)",
            "targets=\(targetSummary)",
            "status=\(status.title)",
            "changed=\(changedCount)",
            "unchanged=\(unchangedCount)"
        ].joined(separator: " | ")
    }

    var accessibilityValue: String {
        "Set \(uniqueContacts.count) contacts to \(status.title). \(changedCount) changed. \(unchangedCount) unchanged. Targets \(targetSummary)"
    }

    private var changedCount: Int {
        uniqueContacts.filter { $0.status != status }.count
    }

    private var unchangedCount: Int {
        uniqueContacts.count - changedCount
    }

    private var targetSummary: String {
        let names = uniqueContacts.map(\.nickname)
        let visible = names.prefix(6).joined(separator: ", ")
        let remainingCount = names.count - min(names.count, 6)
        guard remainingCount > 0 else {
            return visible.isEmpty ? "None" : visible
        }
        return "\(visible), +\(remainingCount) more"
    }
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

    var displayName: String {
        nickname ?? key
    }

    var displaySummary: String {
        "\(Self.percentText(volume)), \(isMuted ? "muted" : "unmuted"), key \(key)"
    }

    var clipboardSummary: String {
        [
            "name=\(displayName)",
            "key=\(key)",
            "volume=\(Self.percentText(volume))",
            "muted=\(isMuted ? "true" : "false")",
            "state=\(isOnline ? "online" : "saved")"
        ].joined(separator: " | ")
    }

    var accessibilityValue: String {
        "\(isOnline ? "Online" : "Saved"). Playback volume \(Self.percentText(volume)). \(isMuted ? "Muted" : "Unmuted"). Key \(key)"
    }

    private static func percentText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }
}

struct TS3OfflineMessageSummary: Identifiable, Codable {
    let id: Int
    let senderUniqueIdentifier: String?
    let senderName: String?
    let subject: String
    let message: String?
    let timestamp: Date?
    let isRead: Bool
}

private struct TS3OfflineMessageArchive: Codable {
    var messages: [TS3OfflineMessageSummary]
}

struct TS3OfflineMessageArchivePreview {
    let messageCount: Int
    let skippedMessageCount: Int
    let unreadCount: Int
    let withBodyCount: Int
    let replyableCount: Int
    let unknownSenderCount: Int
    let messageSummaries: [String]
    let firstSenderName: String?
    let firstSenderUniqueIdentifier: String?
    let firstSubject: String?
    let firstTimestamp: Date?

    var hasMessages: Bool {
        messageCount > 0
    }

    var clipboardSummary: String {
        messageSummaries.joined(separator: "\n")
    }
}

extension TS3OfflineMessageSummary {
    init(message: TS3OfflineMessage, messageOverride: String? = nil, isReadOverride: Bool? = nil) {
        self.id = message.id
        self.senderUniqueIdentifier = message.senderUniqueIdentifier
        self.senderName = message.senderName
        self.subject = message.subject
        self.message = message.message ?? messageOverride
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

    var senderDisplayName: String {
        if let senderName = senderName?.trimmingCharacters(in: .whitespacesAndNewlines), !senderName.isEmpty {
            return senderName
        }
        if let senderUniqueIdentifier = senderUniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !senderUniqueIdentifier.isEmpty {
            return senderUniqueIdentifier
        }
        return "Unknown sender"
    }

    var clipboardSummary: String {
        var parts = [
            "messageId=\(id)",
            "read=\(isRead)",
            "subject=\(subject)"
        ]
        parts.append("sender=\(senderDisplayName)")
        if let senderUniqueIdentifier = senderUniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !senderUniqueIdentifier.isEmpty,
           senderUniqueIdentifier != senderDisplayName {
            parts.append("senderUid=\(senderUniqueIdentifier)")
        }
        if let timestamp {
            parts.append("timestamp=\(Int(timestamp.timeIntervalSince1970))")
        }
        if let message = message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            parts.append("body=\(message)")
        } else {
            parts.append("body=not loaded")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            isRead ? "Read" : "Unread",
            "From \(senderDisplayName)",
            "Subject \(subject)"
        ]
        if let message = message?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            parts.append("Message body available")
        } else {
            parts.append("Message body not loaded")
        }
        return parts.joined(separator: ". ")
    }
}

struct TS3OfflineMessageDraft: Identifiable, Codable {
    let id: String
    var recipientName: String
    var subject: String
    var message: String
    var updatedAt: Date
}

enum TS3OfflineMessageDraftValidator {
    static func validationMessages(
        recipientName: String?,
        recipientUniqueIdentifier: String?,
        subject: String,
        message: String,
        allowsRecipientLookup: Bool = false
    ) -> [String] {
        var messages: [String] = []
        let recipientName = recipientName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipientUniqueIdentifier = recipientUniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        if recipientUniqueIdentifier?.isEmpty != false && !allowsRecipientLookup {
            messages.append("Recipient unique id is required before sending an offline message.")
        }
        if recipientName?.isEmpty != false && recipientUniqueIdentifier?.isEmpty != false && !allowsRecipientLookup {
            messages.append("Select a recipient before sending an offline message.")
        }
        if subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Subject is required before sending an offline message.")
        }
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Message is required before sending an offline message.")
        }
        if subject.rangeOfCharacter(from: .newlines) != nil {
            messages.append("Subject must be a single line.")
        }
        return messages
    }

    static func creationSummary(
        recipientName: String?,
        recipientUniqueIdentifier: String?,
        subject: String,
        message: String,
        allowsRecipientLookup: Bool = false
    ) -> String {
        var parts: [String] = []
        if let recipientName = recipientName?.trimmingCharacters(in: .whitespacesAndNewlines), !recipientName.isEmpty {
            parts.append("recipient=\(recipientName)")
        }
        if let recipientUniqueIdentifier = recipientUniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines), !recipientUniqueIdentifier.isEmpty {
            parts.append("recipientUid=\(recipientUniqueIdentifier)")
        } else if allowsRecipientLookup {
            parts.append("recipientUid=lookup")
        } else {
            parts.append("recipientUid=Missing")
        }
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        parts.append("subject=\(subject.isEmpty ? "Missing" : subject)")
        parts.append("body=\(message.isEmpty ? "Missing" : "\(message.count) chars")")
        return parts.joined(separator: " | ")
    }
}

struct TS3BanEntrySummary: Identifiable, Codable {
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
    var lastNickname: String?
    var durationSeconds: Int?
    var reason: String?
}

private struct TS3BanBackup: Codable {
    var entries: [TS3BanBackupEntry]
}

struct TS3BanBackupPreview {
    let ruleCount: Int
    let skippedRuleCount: Int
    let ipRuleCount: Int
    let nameRuleCount: Int
    let uniqueIdentifierRuleCount: Int
    let lastNicknameRuleCount: Int
    let ruleSummaries: [String]
    let firstIP: String?
    let firstName: String?
    let firstUniqueIdentifier: String?
    let firstLastNickname: String?
    let firstDurationSeconds: Int?
    let firstReason: String?

    var hasRules: Bool {
        ruleCount > 0
    }

    var clipboardSummary: String {
        ruleSummaries.joined(separator: "\n")
    }
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

    var displayTitle: String {
        if let name, !name.isEmpty {
            return name
        }
        if let lastNickname, !lastNickname.isEmpty {
            return lastNickname
        }
        if let ip, !ip.isEmpty {
            return ip
        }
        return "Ban \(id)"
    }

    var subtitle: String {
        [ip, uniqueIdentifier]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " | ")
    }

    var clipboardSummary: String {
        var parts = ["banId=\(id)"]
        if let name, !name.isEmpty {
            parts.append("name=\(name)")
        }
        if let lastNickname, !lastNickname.isEmpty {
            parts.append("lastNickname=\(lastNickname)")
        }
        if let ip, !ip.isEmpty {
            parts.append("ip=\(ip)")
        }
        if let uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("uid=\(uniqueIdentifier)")
        }
        if let createdAt {
            parts.append("createdAt=\(Self.dateText(createdAt))")
        }
        if let durationSeconds {
            parts.append("duration=\(Self.durationText(durationSeconds))")
        }
        if let invokerName, !invokerName.isEmpty {
            parts.append("invoker=\(invokerName)")
        }
        if let enforcements {
            parts.append("enforcements=\(enforcements)")
        }
        if let reason, !reason.isEmpty {
            parts.append("reason=\(reason)")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts: [String] = []
        if let ip, !ip.isEmpty {
            parts.append("IP \(ip)")
        }
        if let uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("Unique ID \(uniqueIdentifier)")
        }
        if let createdAt {
            parts.append("Created \(Self.dateText(createdAt))")
        }
        if let durationSeconds {
            parts.append("Duration \(Self.durationText(durationSeconds))")
        }
        if let invokerName, !invokerName.isEmpty {
            parts.append("Invoker \(invokerName)")
        }
        if let enforcements {
            parts.append("Enforcements \(enforcements)")
        }
        if let reason, !reason.isEmpty {
            parts.append("Reason \(reason)")
        }
        return parts.isEmpty ? "No additional ban details" : parts.joined(separator: ". ")
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func durationText(_ seconds: Int) -> String {
        if seconds == 0 {
            return "Permanent"
        }
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

enum TS3BanDraftValidator {
    static func validationMessages(
        ip: String,
        name: String,
        uniqueIdentifier: String,
        myTeamSpeakId: String,
        lastNickname: String,
        durationSeconds: Int?,
        isCustomDuration: Bool,
        reason: String
    ) -> [String] {
        var messages: [String] = []
        if targetParts(
            ip: ip,
            name: name,
            uniqueIdentifier: uniqueIdentifier,
            myTeamSpeakId: myTeamSpeakId,
            lastNickname: lastNickname
        ).isEmpty {
            messages.append("Enter an IP address, name, unique id, myTeamSpeak id, or last nickname for the ban rule.")
        }
        if isCustomDuration && (durationSeconds ?? 0) <= 0 {
            messages.append("Custom ban duration must be a positive number of seconds.")
        }
        if containsNewline(reason) {
            messages.append("Ban reason must be a single line.")
        }
        return messages
    }

    static func creationSummary(
        ip: String,
        name: String,
        uniqueIdentifier: String,
        myTeamSpeakId: String,
        lastNickname: String,
        durationSeconds: Int?,
        isPermanent: Bool,
        reason: String
    ) -> String {
        var parts = targetParts(
            ip: ip,
            name: name,
            uniqueIdentifier: uniqueIdentifier,
            myTeamSpeakId: myTeamSpeakId,
            lastNickname: lastNickname
        )
        parts.append("duration=\(isPermanent ? "Permanent" : durationSeconds.map(TS3BanEntrySummary.durationText) ?? "Invalid")")
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        if !reason.isEmpty {
            parts.append("reason=\(reason)")
        }
        return parts.joined(separator: " | ")
    }

    private static func targetParts(
        ip: String,
        name: String,
        uniqueIdentifier: String,
        myTeamSpeakId: String,
        lastNickname: String
    ) -> [String] {
        [
            ("ip", ip),
            ("name", name),
            ("uid", uniqueIdentifier),
            ("mytsid", myTeamSpeakId),
            ("lastNickname", lastNickname)
        ].compactMap { key, value -> String? in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : "\(key)=\(trimmed)"
        }
    }

    private static func containsNewline(_ text: String) -> Bool {
        text.rangeOfCharacter(from: .newlines) != nil
    }
}

struct TS3ComplaintSummary: Identifiable, Codable {
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

    init(
        id: String,
        targetClientDatabaseId: Int,
        targetName: String?,
        sourceClientDatabaseId: Int,
        sourceName: String?,
        message: String?,
        timestamp: Date?
    ) {
        self.id = id
        self.targetClientDatabaseId = targetClientDatabaseId
        self.targetName = targetName
        self.sourceClientDatabaseId = sourceClientDatabaseId
        self.sourceName = sourceName
        self.message = message
        self.timestamp = timestamp
    }

    var sourceTitle: String {
        sourceName?.isEmpty == false ? sourceName! : "Client DB \(sourceClientDatabaseId)"
    }

    var clipboardSummary: String {
        var parts = [
            "sourceDb=\(sourceClientDatabaseId)",
            "targetDb=\(targetClientDatabaseId)"
        ]
        if let sourceName, !sourceName.isEmpty {
            parts.append("sourceName=\(sourceName)")
        }
        if let targetName, !targetName.isEmpty {
            parts.append("targetName=\(targetName)")
        }
        if let timestamp {
            parts.append("timestamp=\(Int(timestamp.timeIntervalSince1970))")
        }
        if let message, !message.isEmpty {
            parts.append("message=\(message)")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            "Source database ID \(sourceClientDatabaseId)",
            "Target database ID \(targetClientDatabaseId)"
        ]
        if let targetName, !targetName.isEmpty {
            parts.append("Target \(targetName)")
        }
        if timestamp != nil {
            parts.append("Created date available")
        }
        if let message, !message.isEmpty {
            parts.append(message)
        }
        return parts.joined(separator: ". ")
    }
}

enum TS3ComplaintDraftValidator {
    static func validationMessages(
        targetName: String?,
        targetClientId: Int?,
        targetDatabaseId: Int?,
        message: String
    ) -> [String] {
        var messages: [String] = []
        if targetName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false &&
            targetClientId == nil &&
            targetDatabaseId == nil {
            messages.append("Select a target user before submitting a complaint.")
        }
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Complaint message is required before submitting.")
        }
        if containsNewline(message) {
            messages.append("Complaint message must be a single line.")
        }
        return messages
    }

    static func creationSummary(
        targetName: String?,
        targetClientId: Int?,
        targetDatabaseId: Int?,
        message: String
    ) -> String {
        var parts: [String] = []
        if let targetName = targetName?.trimmingCharacters(in: .whitespacesAndNewlines), !targetName.isEmpty {
            parts.append("target=\(targetName)")
        }
        if let targetClientId {
            parts.append("clientId=\(targetClientId)")
        }
        if let targetDatabaseId {
            parts.append("databaseId=\(targetDatabaseId)")
        }
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        parts.append("message=\(message.isEmpty ? "Missing" : message)")
        return parts.joined(separator: " | ")
    }

    private static func containsNewline(_ text: String) -> Bool {
        text.rangeOfCharacter(from: .newlines) != nil
    }
}

private struct TS3ComplaintArchive: Codable {
    var entries: [TS3ComplaintSummary]
}

struct TS3ComplaintArchivePreview {
    let complaintCount: Int
    let skippedComplaintCount: Int
    let targetCount: Int
    let namedSourceCount: Int
    let anonymousSourceCount: Int
    let messageCount: Int
    let complaintSummaries: [String]
    let firstTargetName: String?
    let firstTargetDatabaseId: Int?
    let firstSourceName: String?
    let firstSourceDatabaseId: Int?
    let firstMessage: String?
    let firstTimestamp: Date?

    var hasComplaints: Bool {
        complaintCount > 0
    }

    var clipboardSummary: String {
        complaintSummaries.joined(separator: "\n")
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

    var displaySummary: String {
        statusSummaryParts.joined(separator: ", ")
    }

    var clipboardSummary: String {
        [
            "name=\(name)",
            "nickname=\(status.nickname.isEmpty ? "unchanged" : status.nickname)",
            "presence=\(status.isAway ? "away" : "available")",
            "micMuted=\(status.isInputMuted ? "true" : "false")",
            "soundMuted=\(status.isOutputMuted ? "true" : "false")",
            "commander=\(status.isChannelCommander ? "true" : "false")",
            "talkRequest=\(status.talkRequestMessage.isEmpty ? "false" : "true")"
        ].joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            status.isAway ? "Away" : "Available",
            status.nickname.isEmpty ? "Nickname unchanged" : "Nickname \(status.nickname)",
            status.isInputMuted ? "Microphone muted" : "Microphone active",
            status.isOutputMuted ? "Sound muted" : "Sound active"
        ]
        if status.isChannelCommander {
            parts.append("Channel commander")
        }
        if !status.talkRequestMessage.isEmpty {
            parts.append("Talk request enabled")
        }
        return parts.joined(separator: ". ")
    }

    private var statusSummaryParts: [String] {
        var parts: [String] = []
        if !status.nickname.isEmpty {
            parts.append(status.nickname)
        }
        parts.append(status.isAway ? "away" : "available")
        if status.isInputMuted {
            parts.append("mic muted")
        }
        if status.isOutputMuted {
            parts.append("sound muted")
        }
        if status.isChannelCommander {
            parts.append("commander")
        }
        if !status.talkRequestMessage.isEmpty {
            parts.append("talk request")
        }
        return parts
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

    var backupSummary: String {
        var parts = [
            "db=\(id)",
            "nickname=\(nickname)"
        ]
        if let uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("uid=\(uniqueIdentifier)")
        }
        if let totalConnections {
            parts.append("connections=\(totalConnections)")
        }
        if let lastIP, !lastIP.isEmpty {
            parts.append("lastIP=\(lastIP)")
        }
        if description?.isEmpty == false {
            parts.append("description=true")
        }
        if let createdAt {
            parts.append("created=\(Int(createdAt.timeIntervalSince1970))")
        }
        if let lastConnectedAt {
            parts.append("lastConnected=\(Int(lastConnectedAt.timeIntervalSince1970))")
        }
        return parts.joined(separator: " | ")
    }

    var clipboardSummary: String {
        var parts = [backupSummary]
        if let description, !description.isEmpty {
            parts.append("descriptionText=\(description)")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            "Database client \(id)",
            "Nickname \(nickname)"
        ]
        if uniqueIdentifier?.isEmpty == false {
            parts.append("Unique identifier available")
        }
        if let totalConnections {
            parts.append("\(totalConnections) connections")
        }
        if lastIP?.isEmpty == false {
            parts.append("Last IP available")
        }
        if description?.isEmpty == false {
            parts.append("Description available")
        }
        if createdAt != nil {
            parts.append("Created date available")
        }
        if lastConnectedAt != nil {
            parts.append("Last connected date available")
        }
        return parts.joined(separator: ". ")
    }
}

struct TS3DatabaseClientBackupPreview {
    let clientCount: Int
    let skippedClientCount: Int
    let uniqueIdentifierCount: Int
    let descriptionCount: Int
    let lastIPCount: Int
    let connectionCount: Int
    let clientSummaries: [String]
    let firstNickname: String?
    let firstUniqueIdentifier: String?
    let firstDatabaseId: Int?

    var hasClients: Bool {
        clientCount > 0
    }

    var clipboardSummary: String {
        clientSummaries.joined(separator: "\n")
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

struct TS3GroupSummary: Identifiable, Codable {
    let id: Int
    let name: String
    let type: TS3PermissionGroupDatabaseType?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
    }

    init(id: Int, name: String, type: TS3PermissionGroupDatabaseType?) {
        self.id = id
        self.name = name
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decodeIfPresent(Int.self, forKey: .type).flatMap(TS3PermissionGroupDatabaseType.init(rawValue:))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(type?.rawValue, forKey: .type)
    }
}

private struct TS3GroupArchive: Codable {
    var serverGroups: [TS3GroupSummary]
    var channelGroups: [TS3GroupSummary]
}

struct TS3GroupArchivePreview {
    let serverGroupCount: Int
    let channelGroupCount: Int
    let skippedServerGroupCount: Int
    let skippedChannelGroupCount: Int
    let templateCount: Int
    let regularCount: Int
    let queryCount: Int
    let unknownTypeCount: Int
    let serverGroupSummaries: [String]
    let channelGroupSummaries: [String]
    let firstServerGroupName: String?
    let firstChannelGroupName: String?

    var totalGroupCount: Int {
        serverGroupCount + channelGroupCount
    }

    var skippedGroupCount: Int {
        skippedServerGroupCount + skippedChannelGroupCount
    }

    var hasGroups: Bool {
        totalGroupCount > 0
    }

    var clipboardSummary: String {
        (serverGroupSummaries + channelGroupSummaries).joined(separator: "\n")
    }
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
        type?.title ?? "Unknown"
    }

    var clipboardSummary: String {
        "groupId=\(id) | name=\(name) | type=\(typeTitle)"
    }

    func clipboardSummary(target: TS3GroupManagementTarget) -> String {
        [
            "target=\(target.title)",
            "groupId=\(id)",
            "name=\(name)",
            "type=\(typeTitle)"
        ].joined(separator: " | ")
    }

    func accessibilityValue(target: TS3GroupManagementTarget) -> String {
        "\(target.title) group. ID \(id). Type \(typeTitle)."
    }
}

enum TS3GroupDraftValidator {
    enum Operation: String {
        case create = "Create"
        case copy = "Copy"
        case rename = "Rename"
    }

    static func validationMessages(
        operation: Operation,
        name: String,
        target: TS3GroupManagementTarget,
        type: TS3PermissionGroupDatabaseType,
        sourceGroup: TS3GroupSummary?,
        existingGroups: [TS3GroupSummary]
    ) -> [String] {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        var messages: [String] = []
        if trimmedName.isEmpty {
            messages.append("Group name is required before \(operation.rawValue.lowercased()).")
        }
        if containsNewline(name) {
            messages.append("Group name must be a single line.")
        }
        if operation != .create && sourceGroup == nil {
            messages.append("Select a source group before \(operation.rawValue.lowercased()).")
        }
        if operation == .rename,
           let sourceGroup,
           trimmedName.caseInsensitiveCompare(sourceGroup.name) == .orderedSame {
            messages.append("Enter a different group name before renaming.")
        }
        if !trimmedName.isEmpty && containsGroup(named: trimmedName, in: existingGroups, excluding: operation == .rename ? sourceGroup?.id : nil) {
            messages.append("\(target.singularTitle) named \(trimmedName) already exists.")
        }
        return messages
    }

    static func creationSummary(
        operation: Operation,
        name: String,
        target: TS3GroupManagementTarget,
        type: TS3PermissionGroupDatabaseType,
        sourceGroup: TS3GroupSummary?
    ) -> String {
        var parts = [
            "operation=\(operation.rawValue)",
            "target=\(target.title)"
        ]
        if let sourceGroup {
            parts.append("source=\(sourceGroup.name) (\(sourceGroup.id))")
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        parts.append("\(operation == .rename ? "newName" : "name")=\(name.isEmpty ? "Missing" : name)")
        if operation != .rename {
            parts.append("type=\(type.title)")
        }
        return parts.joined(separator: " | ")
    }

    private static func containsGroup(named name: String, in groups: [TS3GroupSummary], excluding excludedId: Int?) -> Bool {
        groups.contains { group in
            group.id != excludedId && group.name.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private static func containsNewline(_ text: String) -> Bool {
        text.rangeOfCharacter(from: .newlines) != nil
    }
}

enum TS3GroupMemberDraftValidator {
    enum Operation: String {
        case addServerMember = "Add Member"
        case setChannelGroup = "Set Channel Group"
    }

    static func validationMessages(
        operation: Operation,
        target: TS3GroupManagementTarget,
        group: TS3GroupSummary,
        clientDatabaseId: String,
        channelId: Int?
    ) -> [String] {
        var messages: [String] = []
        let trimmedDatabaseId = clientDatabaseId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDatabaseId.isEmpty {
            messages.append("Client database ID is required before \(operation == .addServerMember ? "adding a group member" : "setting a channel group").")
        } else if Int(trimmedDatabaseId).map({ $0 > 0 }) != true {
            messages.append("Client database ID must be a positive number.")
        }
        if operation == .addServerMember && target != .server {
            messages.append("Select Server Groups before adding a server group member.")
        }
        if operation == .setChannelGroup {
            if target != .channel {
                messages.append("Select Channel Groups before setting a channel group.")
            }
            if channelId == nil {
                messages.append("Select a channel before setting a channel group.")
            }
        }
        if group.id <= 0 {
            messages.append("Select a valid group before changing membership.")
        }
        return messages
    }

    static func changeSummary(
        operation: Operation,
        target: TS3GroupManagementTarget,
        group: TS3GroupSummary,
        clientDatabaseId: String,
        channelId: Int?,
        channelName: String?
    ) -> String {
        var parts = [
            "operation=\(operation.rawValue)",
            "target=\(target.title)",
            "group=\(group.name) (\(group.id))"
        ]
        let databaseId = clientDatabaseId.trimmingCharacters(in: .whitespacesAndNewlines)
        parts.append("clientDb=\(databaseId.isEmpty ? "Missing" : databaseId)")
        if operation == .setChannelGroup {
            if let channelId {
                parts.append("channel=\(channelName ?? "Channel \(channelId)") (\(channelId))")
            } else {
                parts.append("channel=Missing")
            }
        }
        return parts.joined(separator: " | ")
    }
}

extension TS3GroupClientSummary {
    func clipboardSummary(group: TS3GroupSummary, target: TS3GroupManagementTarget, channelName: String?) -> String {
        var parts = [
            "group=\(group.name) (\(group.id))",
            "target=\(target.title)",
            "clientDb=\(clientDatabaseId)",
            "nickname=\(displayName)"
        ]
        if let uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("uid=\(uniqueIdentifier)")
        }
        if let channelId {
            parts.append("channel=\(channelName ?? "Channel \(channelId)") (\(channelId))")
        }
        return parts.joined(separator: " | ")
    }

    func accessibilityValue(group: TS3GroupSummary, target: TS3GroupManagementTarget, channelName: String?) -> String {
        var parts = [
            "\(target.title) group \(group.name)",
            "Database ID \(clientDatabaseId)"
        ]
        if let channelId {
            parts.append("Channel \(channelName ?? "Channel \(channelId)")")
        } else {
            parts.append("Offline or no channel")
        }
        if let uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("Unique ID \(uniqueIdentifier)")
        }
        return parts.joined(separator: ". ")
    }
}

extension TS3PermissionGroupDatabaseType {
    var title: String {
        switch self {
        case .template:
            return "Template"
        case .regular:
            return "Regular"
        case .query:
            return "Query"
        }
    }
}

struct TS3PermissionInfoSummary: Identifiable {
    let id: Int
    let name: String
    let description: String?

    var clipboardSummary: String {
        var parts = [
            "permissionId=\(id)",
            "name=\(name)"
        ]
        if let description, !description.isEmpty {
            parts.append("description=\(description)")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = ["Permission ID \(id)"]
        if let description, !description.isEmpty {
            parts.append(description)
        }
        return parts.joined(separator: ". ")
    }

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

    var statusLabels: [String] {
        var labels: [String] = []
        if isNegated {
            labels.append("Negated")
        }
        if isSkipped {
            labels.append("Skips inherited")
        }
        return labels.isEmpty ? ["Direct"] : labels
    }

    var inheritanceEffectDescription: String {
        Self.inheritanceEffectDescription(isNegated: isNegated, isSkipped: isSkipped)
    }

    static func inheritanceEffectDescription(isNegated: Bool, isSkipped: Bool) -> String {
        switch (isNegated, isSkipped) {
        case (true, true):
            return "Negates earlier grants and blocks lower inherited permissions."
        case (true, false):
            return "Negates earlier grants while later channel or client entries can still override it."
        case (false, true):
            return "Allows this value and stops lower inherited permissions from overriding it."
        case (false, false):
            return "Direct value; inherited permissions may still apply around this entry."
        }
    }

    var clipboardSummary: String {
        var parts = [
            "name=\(name)",
            "value=\(value)",
            "status=\(statusLabels.joined(separator: "+"))"
        ]
        if isNegated {
            parts.append("negated=true")
        }
        if isSkipped {
            parts.append("skip=true")
        }
        parts.append("effect=\(inheritanceEffectDescription)")
        return parts.joined(separator: " ")
    }

    var accessibilityValue: String {
        [
            "Value \(value)",
            statusLabels.joined(separator: ", "),
            inheritanceEffectDescription
        ].joined(separator: ". ")
    }

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

enum TS3PrivilegeKeyDraftValidator {
    static func validationMessages(
        targetType: TS3PrivilegeKeyTargetType,
        groupId: Int,
        channelId: Int?,
        description: String,
        customSet: String
    ) -> [String] {
        var messages: [String] = []
        if groupId <= 0 {
            switch targetType {
            case .serverGroup:
                messages.append("Server group is required before creating a privilege key.")
            case .channelGroup:
                messages.append("Channel group is required before creating a privilege key.")
            }
        }
        if targetType == .channelGroup && (channelId ?? 0) <= 0 {
            messages.append("Channel is required before creating a channel-group privilege key.")
        }
        if containsNewline(description) {
            messages.append("Description must be a single line.")
        }
        if containsNewline(customSet) {
            messages.append("Custom set must be a single line.")
        }
        return messages
    }

    static func creationSummary(
        targetType: TS3PrivilegeKeyTargetType,
        groupId: Int,
        groupName: String,
        channelId: Int?,
        channelName: String?,
        description: String,
        customSet: String
    ) -> String {
        var parts = [
            "type=\(targetType.title)",
            "group=\(groupName) (\(groupId))"
        ]
        if targetType == .channelGroup {
            let resolvedChannelId = channelId ?? 0
            parts.append("channel=\(channelName ?? "Channel \(resolvedChannelId)") (\(resolvedChannelId))")
        }
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty {
            parts.append("description=\(description)")
        }
        let customSet = customSet.trimmingCharacters(in: .whitespacesAndNewlines)
        if !customSet.isEmpty {
            parts.append("customSet=\(customSet)")
        }
        return parts.joined(separator: " | ")
    }

    private static func containsNewline(_ text: String) -> Bool {
        text.rangeOfCharacter(from: .newlines) != nil
    }
}

extension TS3PrivilegeKeyType {
    var title: String {
        switch self {
        case .serverGroup:
            return "Server Group"
        case .channelGroup:
            return "Channel Group"
        }
    }
}

struct TS3PrivilegeKeySummary: Identifiable, Codable {
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

    enum CodingKeys: String, CodingKey {
        case id
        case key
        case type
        case groupId
        case channelId
        case createdAt
        case description
        case customSet
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .key)
        key = try container.decode(String.self, forKey: .key)
        type = try container.decodeIfPresent(Int.self, forKey: .type).flatMap(TS3PrivilegeKeyType.init(rawValue:))
        groupId = try container.decode(Int.self, forKey: .groupId)
        channelId = try container.decodeIfPresent(Int.self, forKey: .channelId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        customSet = try container.decodeIfPresent(String.self, forKey: .customSet)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(key, forKey: .key)
        try container.encodeIfPresent(type?.rawValue, forKey: .type)
        try container.encode(groupId, forKey: .groupId)
        try container.encodeIfPresent(channelId, forKey: .channelId)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(customSet, forKey: .customSet)
    }
}

extension TS3PrivilegeKeySummary {
    func targetSummary(
        serverGroups: [TS3GroupSummary],
        channelGroups: [TS3GroupSummary],
        channels: [TS3ChannelSummary]
    ) -> String {
        switch type {
        case .serverGroup:
            return "\(TS3PrivilegeKeyType.serverGroup.title): \(TS3GroupSummary.name(for: groupId, in: serverGroups))"
        case .channelGroup:
            let group = TS3GroupSummary.name(for: groupId, in: channelGroups)
            let channel = channelId.flatMap { id in channels.first { $0.id == id }?.name } ?? "Any Channel"
            return "\(TS3PrivilegeKeyType.channelGroup.title): \(group) in \(channel)"
        case nil:
            return "Unknown Type: Group \(groupId)"
        }
    }

    func accessibilityValue(
        serverGroups: [TS3GroupSummary],
        channelGroups: [TS3GroupSummary],
        channels: [TS3ChannelSummary]
    ) -> String {
        var parts = [
            targetSummary(
                serverGroups: serverGroups,
                channelGroups: channelGroups,
                channels: channels
            )
        ]
        if let channelId {
            let channel = channels.first { $0.id == channelId }?.name ?? "Channel \(channelId)"
            parts.append("Channel \(channel), ID \(channelId)")
        }
        if let createdAt {
            parts.append("Created \(Self.dateText(createdAt))")
        }
        if let description, !description.isEmpty {
            parts.append("Description \(description)")
        }
        if let customSet, !customSet.isEmpty {
            parts.append("Custom set \(customSet)")
        }
        return parts.joined(separator: ". ")
    }

    func clipboardSummary(
        serverGroups: [TS3GroupSummary],
        channelGroups: [TS3GroupSummary],
        channels: [TS3ChannelSummary]
    ) -> String {
        var parts = ["key=\(key)"]
        if let type {
            parts.append("type=\(type.title) (\(type.rawValue))")
        }
        switch type {
        case .serverGroup:
            parts.append("group=\(TS3GroupSummary.name(for: groupId, in: serverGroups)) (\(groupId))")
        case .channelGroup:
            parts.append("group=\(TS3GroupSummary.name(for: groupId, in: channelGroups)) (\(groupId))")
        case nil:
            parts.append("groupId=\(groupId)")
        }
        if let channelId {
            let channel = channels.first { $0.id == channelId }?.name ?? "Channel \(channelId)"
            parts.append("channel=\(channel) (\(channelId))")
        }
        if let createdAt {
            parts.append("createdAt=\(Self.dateText(createdAt))")
        }
        if let description, !description.isEmpty {
            parts.append("description=\(description)")
        }
        if let customSet, !customSet.isEmpty {
            parts.append("customSet=\(customSet)")
        }
        return parts.joined(separator: " | ")
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TS3TemporaryServerPasswordSummary: Identifiable, Codable {
    let id: String
    let password: String
    let creatorUniqueIdentifier: String?
    let creatorDatabaseId: Int?
    let creatorName: String?
    let targetChannelId: Int?
    let targetChannelPassword: String?
    let createdAt: Date?
    let durationSeconds: Int?
    let description: String?

    init(
        id: String,
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
        self.id = id
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

    init(entry: TS3TemporaryServerPassword) {
        self.init(
            id: entry.id,
            password: entry.password,
            creatorUniqueIdentifier: entry.creatorUniqueIdentifier,
            creatorDatabaseId: entry.creatorDatabaseId,
            creatorName: entry.creatorName,
            targetChannelId: entry.targetChannelId,
            targetChannelPassword: entry.targetChannelPassword,
            createdAt: entry.createdAt,
            durationSeconds: entry.durationSeconds,
            description: entry.description
        )
    }

    func targetText(channels: [TS3ChannelSummary]) -> String {
        guard let targetChannelId, targetChannelId > 0 else {
            return "Server Default"
        }
        return channels.first { $0.id == targetChannelId }?.name ?? "Channel \(targetChannelId)"
    }

    var creatorText: String? {
        if let creatorName, !creatorName.isEmpty {
            return creatorName
        }
        if let creatorDatabaseId {
            return "Database ID \(creatorDatabaseId)"
        }
        return nil
    }

    func clipboardSummary(channels: [TS3ChannelSummary]) -> String {
        var parts = ["password=\(password)"]
        if let durationSeconds {
            parts.append("duration=\(Self.durationText(durationSeconds))")
        }
        if let createdAt {
            parts.append("createdAt=\(Self.dateText(createdAt))")
        }
        if let description, !description.isEmpty {
            parts.append("description=\(description)")
        }
        if let targetChannelId {
            parts.append("target=\(targetText(channels: channels)) (\(targetChannelId))")
        }
        if let creatorName, !creatorName.isEmpty {
            parts.append("creator=\(creatorName)")
        } else if let creatorDatabaseId {
            parts.append("creatorDb=\(creatorDatabaseId)")
        }
        return parts.joined(separator: " | ")
    }

    func accessibilityValue(channels: [TS3ChannelSummary]) -> String {
        var parts = [
            "Temporary server password",
            "Target \(targetText(channels: channels))"
        ]
        if let durationSeconds {
            parts.append("Duration \(Self.durationText(durationSeconds))")
        }
        if createdAt != nil {
            parts.append("Created date available")
        }
        if let description, !description.isEmpty {
            parts.append("Description \(description)")
        }
        if let creatorText {
            parts.append("Creator \(creatorText)")
        }
        return parts.joined(separator: ". ")
    }

    static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func durationText(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h"
        }
        let days = hours / 24
        return "\(days)d"
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

struct TS3PrivilegeKeyBackupPreview {
    let keyCount: Int
    let serverGroupCount: Int
    let channelGroupCount: Int
    let unknownTypeCount: Int
    let keySummaries: [String]
    let firstKey: String?
    let firstType: TS3PrivilegeKeyType?
    let firstGroupId: Int?
    let firstChannelId: Int?
    let firstDescription: String?
    let firstCustomSet: String?

    var hasKeys: Bool {
        keyCount > 0
    }

    var clipboardSummary: String {
        keySummaries.joined(separator: "\n")
    }
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

struct TS3PermissionEditDraft {
    let scope: TS3PermissionEditScope
    let target: String
    let name: String
    let value: String
    let negated: Bool
    let skip: Bool

    var parsedValue: Int? {
        Int(value.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var effectiveNegated: Bool {
        switch scope {
        case .serverGroup, .channelGroup:
            return negated
        case .ownClient, .databaseClient, .channel, .channelClient:
            return false
        }
    }

    var effectiveSkip: Bool {
        scope == .channel ? false : skip
    }

    var validationMessages: [String] {
        TS3PermissionDraftValidator.validationMessages(scope: scope, name: name, value: value)
    }

    var clipboardSummary: String {
        var parts = [
            "scope=\(scope.title)",
            "target=\(target)",
            "name=\(name.trimmingCharacters(in: .whitespacesAndNewlines))",
            "value=\(value.trimmingCharacters(in: .whitespacesAndNewlines))"
        ]
        if effectiveNegated {
            parts.append("negated=true")
        }
        if effectiveSkip {
            parts.append("skip=true")
        }
        parts.append("effect=\(inheritanceEffectDescription)")
        return parts.joined(separator: " | ")
    }

    var inheritanceEffectDescription: String {
        TS3PermissionSummary.inheritanceEffectDescription(isNegated: effectiveNegated, isSkipped: effectiveSkip)
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

    var sizeText: String {
        Self.sizeText(size)
    }

    var clipboardSummary: String {
        var parts = [
            "name=\(name)",
            "type=\(isDirectory ? "directory" : "file")",
            "path=\(path)",
            "parent=\(parentPath)",
            "channelId=\(channelId)"
        ]
        if !isDirectory {
            parts.append("size=\(sizeText)")
        }
        if isStillUploading {
            parts.append("status=uploading")
            if let incompleteSize {
                parts.append("partial=\(Self.sizeText(incompleteSize))")
            }
        }
        if let modifiedAt {
            parts.append("modifiedAt=\(Int(modifiedAt.timeIntervalSince1970))")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            isDirectory ? "Directory" : "File",
            "Remote path \(path)"
        ]
        if !isDirectory {
            parts.append("Size \(sizeText)")
        }
        if isStillUploading {
            parts.append("Still uploading")
        }
        if modifiedAt != nil {
            parts.append("Modified date available")
        }
        return parts.joined(separator: ". ")
    }

    static func sizeText(_ bytes: Int64) -> String {
        if bytes < 1_024 {
            return "\(bytes) B"
        }
        let kb = Double(bytes) / 1_024
        if kb < 1_024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1_024
        if mb < 1_024 {
            return String(format: "%.1f MB", mb)
        }
        return String(format: "%.1f GB", mb / 1_024)
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

enum TS3TemporaryServerPasswordDraftValidator {
    static func validationMessages(
        password: String,
        durationSeconds: Int?,
        description: String,
        targetChannelId: Int?,
        targetChannelPassword: String
    ) -> [String] {
        var messages: [String] = []
        if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Temporary password is required before creating.")
        }
        if (durationSeconds ?? 0) <= 0 {
            messages.append("Duration must be a positive number of seconds.")
        }
        if containsNewline(description) {
            messages.append("Description must be a single line.")
        }
        if containsNewline(targetChannelPassword) {
            messages.append("Target channel password must be a single line.")
        }
        if (targetChannelId ?? 0) <= 0 && !targetChannelPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("Select a target channel before setting a target channel password.")
        }
        return messages
    }

    static func creationSummary(
        password: String,
        durationSeconds: Int?,
        description: String,
        targetChannelId: Int?,
        targetChannelName: String?,
        targetChannelPassword: String
    ) -> String {
        var parts = [
            "password=\(password.trimmingCharacters(in: .whitespacesAndNewlines))",
            "duration=\(durationSeconds.map(TS3TemporaryServerPasswordSummary.durationText) ?? "Invalid")"
        ]
        let targetChannelId = targetChannelId ?? 0
        if targetChannelId > 0 {
            parts.append("target=\(targetChannelName ?? "Channel \(targetChannelId)") (\(targetChannelId))")
        } else {
            parts.append("target=Server Default")
        }
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty {
            parts.append("description=\(description)")
        }
        if !targetChannelPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("targetChannelPassword=set")
        }
        return parts.joined(separator: " | ")
    }

    private static func containsNewline(_ text: String) -> Bool {
        text.rangeOfCharacter(from: .newlines) != nil
    }
}

struct TS3TemporaryServerPasswordFilterPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var passwordFilter: String
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        passwordFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.passwordFilter = passwordFilter
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
    var channelFilter: String
    var channelId: Int?
    var sortMode: String
    var sortAscending: Bool
    var searchText: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        memberFilter: String,
        channelFilter: String = "allChannels",
        channelId: Int? = nil,
        sortMode: String,
        sortAscending: Bool,
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.memberFilter = memberFilter
        self.channelFilter = channelFilter
        self.channelId = channelId
        self.sortMode = sortMode
        self.sortAscending = sortAscending
        self.searchText = searchText
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case memberFilter
        case channelFilter
        case channelId
        case sortMode
        case sortAscending
        case searchText
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        memberFilter = try container.decodeIfPresent(String.self, forKey: .memberFilter) ?? "all"
        channelFilter = try container.decodeIfPresent(String.self, forKey: .channelFilter) ?? "allChannels"
        channelId = try container.decodeIfPresent(Int.self, forKey: .channelId)
        sortMode = try container.decodeIfPresent(String.self, forKey: .sortMode) ?? "nickname"
        sortAscending = try container.decodeIfPresent(Bool.self, forKey: .sortAscending) ?? true
        searchText = try container.decodeIfPresent(String.self, forKey: .searchText) ?? ""
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

extension TS3GroupFilterPreset {
    var clipboardSummary: String {
        summaryLines.joined(separator: "\n")
    }

    var inlineSummary: String {
        summaryLines.joined(separator: " · ")
    }

    var accessibilityValue: String {
        "\(name). \(summaryLines.joined(separator: ". "))"
    }

    private var summaryLines: [String] {
        var lines = [
            "Target: \(targetTitle)",
            "Type filter: \(groupTypeFilterTitle)",
            "Sort: \(sortModeTitle) \(sortAscending ? "Ascending" : "Descending")"
        ]
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !search.isEmpty {
            lines.append("Search: \(search)")
        }
        return lines
    }

    private var targetTitle: String {
        switch target {
        case "channel": return "Channel Groups"
        default: return "Server Groups"
        }
    }

    private var groupTypeFilterTitle: String {
        switch groupTypeFilter {
        case "template": return "Template"
        case "regular": return "Regular"
        case "query": return "Query"
        case "unknown": return "Unknown"
        default: return "All Types"
        }
    }

    private var sortModeTitle: String {
        switch sortMode {
        case "id": return "ID"
        case "type": return "Type"
        default: return "Name"
        }
    }
}

extension TS3GroupClientFilterPreset {
    func clipboardSummary(channelName: String? = nil) -> String {
        summaryLines(channelName: channelName).joined(separator: "\n")
    }

    func inlineSummary(channelName: String? = nil) -> String {
        summaryLines(channelName: channelName).joined(separator: " · ")
    }

    func accessibilityValue(channelName: String? = nil) -> String {
        "\(name). \(summaryLines(channelName: channelName).joined(separator: ". "))"
    }

    private func summaryLines(channelName: String?) -> [String] {
        var lines = [
            "Status filter: \(memberFilterTitle)",
            "Channel filter: \(channelFilterTitle(channelName: channelName))",
            "Sort: \(sortModeTitle) \(sortAscending ? "Ascending" : "Descending")"
        ]
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !search.isEmpty {
            lines.append("Search: \(search)")
        }
        return lines
    }

    private var memberFilterTitle: String {
        switch memberFilter {
        case "online": return "Online"
        case "offline": return "Offline"
        case "withUniqueId": return "With Unique ID"
        case "withoutUniqueId": return "Without Unique ID"
        default: return "All Members"
        }
    }

    private func channelFilterTitle(channelName: String?) -> String {
        switch channelFilter {
        case "currentChannel":
            return "Current Channel"
        case "selectedChannel":
            if let channelId {
                return "\(channelName ?? "Channel \(channelId)") (\(channelId))"
            }
            return "Selected Channel"
        case "withoutChannel":
            return "No Channel"
        default:
            return "All Channels"
        }
    }

    private var sortModeTitle: String {
        switch sortMode {
        case "databaseId": return "Database ID"
        case "channel": return "Channel"
        case "uniqueId": return "Unique ID"
        default: return "Nickname"
        }
    }
}

struct TS3DownloadedFileSummary: Identifiable, Codable {
    let id: UUID
    let name: String
    let url: URL
    let downloadedAt: Date

    init(id: UUID = UUID(), name: String, url: URL, downloadedAt: Date) {
        self.id = id
        self.name = name
        self.url = url
        self.downloadedAt = downloadedAt
    }
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

    var clipboardSummary: String {
        var parts = [
            "\(direction.title) \(state.title)",
            name,
            remotePath,
            detail
        ]
        if let progress {
            parts.append("progress=\(Int((progress * 100).rounded()))%")
        }
        if let localPath, !localPath.isEmpty {
            parts.append(localPath)
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = [
            "\(direction.title). \(state.title)",
            detail,
            "Remote path \(remotePath)"
        ]
        if let progress, state != .completed {
            parts.append("Progress \(Int((progress * 100).rounded())) percent")
        }
        if let localPath, !localPath.isEmpty {
            parts.append("Local path available")
        }
        return parts.joined(separator: ". ")
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

struct TS3PermissionBackupPreview {
    let scope: TS3PermissionEditScope
    let targetDescription: String
    let permissionCount: Int
    let currentPermissionCount: Int?
    let overwriteCount: Int?
    let changedCount: Int?
    let unchangedCount: Int?
    let newPermissionCount: Int?
    let overwritePermissionNames: [String]
    let changedPermissionNames: [String]
    let changedPermissionDetails: [String]
    let unchangedPermissionNames: [String]
    let newPermissionNames: [String]

    var targetMatchesCurrentSelection: Bool {
        currentPermissionCount != nil
    }
}

struct TS3PermissionBackupRestoreOptions: Equatable {
    var changedExisting: Bool
    var newPermissions: Bool
    var restoreWhenTargetCannotBeCompared: Bool

    static let all = TS3PermissionBackupRestoreOptions(
        changedExisting: true,
        newPermissions: true,
        restoreWhenTargetCannotBeCompared: true
    )

    var hasSelectedComparableEntries: Bool {
        changedExisting || newPermissions
    }
}

struct TS3PermissionBackupRestoreEntry: Equatable {
    let name: String
    let value: Int
    let isNegated: Bool
    let isSkipped: Bool
    let restoreReason: String
    let changeSummary: String?

    init(
        name: String,
        value: Int,
        isNegated: Bool,
        isSkipped: Bool,
        restoreReason: String = "selected",
        changeSummary: String? = nil
    ) {
        self.name = name
        self.value = value
        self.isNegated = isNegated
        self.isSkipped = isSkipped
        self.restoreReason = restoreReason
        self.changeSummary = changeSummary
    }

    var clipboardSummary: String {
        var parts = [
            "name=\(name)",
            "value=\(value)",
            "negated=\(isNegated ? "true" : "false")",
            "skip=\(isSkipped ? "true" : "false")",
            "reason=\(restoreReason)"
        ]
        if let changeSummary, !changeSummary.isEmpty {
            parts.append("change=\(changeSummary)")
        }
        return parts.joined(separator: " ")
    }
}

struct TS3PermissionBackupRestorePlan {
    let entries: [TS3PermissionBackupRestoreEntry]
    let targetDescription: String
    let scope: TS3PermissionEditScope
    let targetMatchesCurrentSelection: Bool
    let options: TS3PermissionBackupRestoreOptions
    let changedCount: Int?
    let newPermissionCount: Int?
    let unchangedCount: Int?

    var permissionNames: [String] {
        entries.map(\.name)
    }

    var permissionCount: Int {
        entries.count
    }

    var clipboardSummary: String {
        auditSummary
    }

    var auditSummary: String {
        var lines = [
            "Target: \(scope.title) - \(targetDescription)",
            "Target comparison: \(targetMatchesCurrentSelection ? "Matched current selection" : "Not comparable with current selection")",
            "Restore changed existing: \(options.changedExisting ? "Yes" : "No")",
            "Restore new permissions: \(options.newPermissions ? "Yes" : "No")",
            "Restore without comparison: \(options.restoreWhenTargetCannotBeCompared ? "Yes" : "No")",
            "Selected restore entries: \(permissionCount)"
        ]
        if let changedCount {
            lines.append("Changed existing available: \(changedCount)")
        }
        if let newPermissionCount {
            lines.append("New permissions available: \(newPermissionCount)")
        }
        if let unchangedCount {
            lines.append("Unchanged skipped: \(unchangedCount)")
        }
        if !entries.isEmpty {
            lines.append("")
            lines.append(contentsOf: entries.map(\.clipboardSummary))
        }
        return lines.joined(separator: "\n")
    }
}

private struct TS3AudioSettings: Codable {
    var playbackVolume: Double
    var inputGain: Double
    var transmitMode: String
    var voiceActivationThreshold: Double
    var prefersSpeakerOutput: Bool
    var whisperActivationMode: String

    static let defaults = TS3AudioSettings(
        playbackVolume: 1.0,
        inputGain: 1.0,
        transmitMode: TS3AudioTransmitMode.pushToTalk.rawValue,
        voiceActivationThreshold: 0.03,
        prefersSpeakerOutput: true,
        whisperActivationMode: TS3WhisperActivationMode.holdToWhisper.rawValue
    )

    enum CodingKeys: String, CodingKey {
        case playbackVolume
        case inputGain
        case transmitMode
        case voiceActivationThreshold
        case prefersSpeakerOutput
        case whisperActivationMode
    }

    init(
        playbackVolume: Double,
        inputGain: Double,
        transmitMode: String,
        voiceActivationThreshold: Double,
        prefersSpeakerOutput: Bool,
        whisperActivationMode: String = TS3WhisperActivationMode.holdToWhisper.rawValue
    ) {
        self.playbackVolume = playbackVolume
        self.inputGain = inputGain
        self.transmitMode = transmitMode
        self.voiceActivationThreshold = voiceActivationThreshold
        self.prefersSpeakerOutput = prefersSpeakerOutput
        self.whisperActivationMode = whisperActivationMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playbackVolume = try container.decodeIfPresent(Double.self, forKey: .playbackVolume) ?? Self.defaults.playbackVolume
        inputGain = try container.decodeIfPresent(Double.self, forKey: .inputGain) ?? Self.defaults.inputGain
        transmitMode = try container.decodeIfPresent(String.self, forKey: .transmitMode) ?? Self.defaults.transmitMode
        voiceActivationThreshold = try container.decodeIfPresent(Double.self, forKey: .voiceActivationThreshold) ?? Self.defaults.voiceActivationThreshold
        prefersSpeakerOutput = try container.decodeIfPresent(Bool.self, forKey: .prefersSpeakerOutput) ?? Self.defaults.prefersSpeakerOutput
        whisperActivationMode = try container.decodeIfPresent(String.self, forKey: .whisperActivationMode) ?? Self.defaults.whisperActivationMode
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

    var displaySummary: String {
        "\(displayName), \(stateTitle)"
    }

    var clipboardSummary: String {
        [
            "name=\(name)",
            "type=\(type.isEmpty ? "Unknown" : type)",
            "id=\(id)",
            "state=\(isSelected ? "selected" : "available")"
        ].joined(separator: " | ")
    }

    var accessibilityValue: String {
        "\(stateTitle). Type \(type.isEmpty ? "Unknown" : type). Identifier \(id)"
    }

    private var stateTitle: String {
        isSelected ? "selected" : "available"
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

    var displaySummary: String {
        let mode = TS3AudioTransmitMode.title(for: transmitMode)
        let input = Self.percentText(inputGain)
        let playback = Self.percentText(playbackVolume)
        let threshold = String(format: "%.3f", voiceActivationThreshold)
        return "\(mode), input \(input), playback \(playback), threshold \(threshold)"
    }

    var clipboardSummary: String {
        [
            "name=\(name)",
            "mode=\(TS3AudioTransmitMode.title(for: transmitMode))",
            "input=\(Self.percentText(inputGain))",
            "playback=\(Self.percentText(playbackVolume))",
            "threshold=\(String(format: "%.3f", voiceActivationThreshold))"
        ].joined(separator: " | ")
    }

    var accessibilityValue: String {
        "\(TS3AudioTransmitMode.title(for: transmitMode)). Input gain \(Self.percentText(inputGain)). Playback volume \(Self.percentText(playbackVolume)). Voice activation threshold \(String(format: "%.3f", voiceActivationThreshold))"
    }

    private static func percentText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
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

    var stateTitle: String {
        isEnabled ? "Enabled" : "Disabled"
    }

    var displaySummary: String {
        "\(keys) · \(stateTitle)"
    }

    var clipboardSummary: String {
        [
            "group=\(group)",
            "action=\(action)",
            "keys=\(keys)",
            "default=\(defaultKeys)",
            "enabled=\(isEnabled ? "true" : "false")"
        ].joined(separator: " | ")
    }

    var accessibilityValue: String {
        "\(group). Keys \(keys). \(stateTitle). Default \(defaultKeys)."
    }

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
    var mutedServerKeys: [String]
    var mutedContactUniqueIdentifiers: [String]
    var quietHoursEnabled: Bool
    var quietHoursStartMinute: Int
    var quietHoursEndMinute: Int

    static let defaults = TS3NotificationSettings(
        isEnabled: false,
        soundEnabled: true,
        privateMessagesEnabled: true,
        pokesEnabled: true,
        activityEnabled: false,
        mutedServerKeys: [],
        mutedContactUniqueIdentifiers: [],
        quietHoursEnabled: false,
        quietHoursStartMinute: 22 * 60,
        quietHoursEndMinute: 7 * 60
    )

    init(
        isEnabled: Bool,
        soundEnabled: Bool = true,
        privateMessagesEnabled: Bool = true,
        pokesEnabled: Bool = true,
        activityEnabled: Bool = false,
        mutedServerKeys: [String] = [],
        mutedContactUniqueIdentifiers: [String] = [],
        quietHoursEnabled: Bool = false,
        quietHoursStartMinute: Int = 22 * 60,
        quietHoursEndMinute: Int = 7 * 60
    ) {
        self.isEnabled = isEnabled
        self.soundEnabled = soundEnabled
        self.privateMessagesEnabled = privateMessagesEnabled
        self.pokesEnabled = pokesEnabled
        self.activityEnabled = activityEnabled
        self.mutedServerKeys = mutedServerKeys
        self.mutedContactUniqueIdentifiers = mutedContactUniqueIdentifiers
        self.quietHoursEnabled = quietHoursEnabled
        self.quietHoursStartMinute = quietHoursStartMinute
        self.quietHoursEndMinute = quietHoursEndMinute
    }

    enum CodingKeys: String, CodingKey {
        case isEnabled
        case soundEnabled
        case privateMessagesEnabled
        case pokesEnabled
        case activityEnabled
        case mutedServerKeys
        case mutedContactUniqueIdentifiers
        case quietHoursEnabled
        case quietHoursStartMinute
        case quietHoursEndMinute
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        privateMessagesEnabled = try container.decodeIfPresent(Bool.self, forKey: .privateMessagesEnabled) ?? true
        pokesEnabled = try container.decodeIfPresent(Bool.self, forKey: .pokesEnabled) ?? true
        activityEnabled = try container.decodeIfPresent(Bool.self, forKey: .activityEnabled) ?? false
        mutedServerKeys = try container.decodeIfPresent([String].self, forKey: .mutedServerKeys) ?? []
        mutedContactUniqueIdentifiers = try container.decodeIfPresent([String].self, forKey: .mutedContactUniqueIdentifiers) ?? []
        quietHoursEnabled = try container.decodeIfPresent(Bool.self, forKey: .quietHoursEnabled) ?? false
        quietHoursStartMinute = try container.decodeIfPresent(Int.self, forKey: .quietHoursStartMinute) ?? 22 * 60
        quietHoursEndMinute = try container.decodeIfPresent(Int.self, forKey: .quietHoursEndMinute) ?? 7 * 60
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

private struct TS3ChatHistorySettings: Codable {
    var messageLimit: Int

    static let minimumMessageLimit = 50
    static let maximumMessageLimit = 5000
    static let defaults = TS3ChatHistorySettings(messageLimit: 500)

    init(messageLimit: Int = 500) {
        self.messageLimit = messageLimit
    }

    enum CodingKeys: String, CodingKey {
        case messageLimit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messageLimit = try container.decodeIfPresent(Int.self, forKey: .messageLimit)
            ?? Self.defaults.messageLimit
    }
}

private struct TS3ClientMigrationPackage: Codable {
    var schemaVersion: Int
    var exportedAt: Date
    var bookmarks: [TS3BookmarkSummary]
    var recentConnections: [TS3ConnectionSnapshot]
    var connectionFilterPresets: [TS3ConnectionFilterPreset]
    var savedChannelPasswords: [TS3SavedChannelPassword]
    var identityProfiles: [TS3IdentityProfile]
    var contacts: [TS3ContactEntry]
    var contactFilterPresets: [TS3ContactFilterPreset]
    var notificationSettings: TS3NotificationSettings
    var connectionRecoverySettings: TS3ConnectionRecoverySettings
    var chatHistorySettings: TS3ChatHistorySettings
    var serverLogQueryPresets: [TS3ServerLogQueryPreset]
    var keyboardShortcuts: [TS3KeyboardShortcutBinding]
    var channelSubscriptionPresets: [TS3ChannelSubscriptionPreset]
    var channelTreeFilterPresets: [TS3ChannelTreeFilterPreset]
    var collapsedChannelIds: [Int]
    var eventFilterPresets: [TS3EventFilterPreset]
    var chatFilterPresets: [TS3ChatFilterPreset]
    var fileBrowserBookmarks: [TS3FileBrowserBookmark]
    var fileBrowserFilterPresets: [TS3FileBrowserFilterPreset]
    var offlineMessageFilterPresets: [TS3OfflineMessageFilterPreset]
    var banFilterPresets: [TS3BanFilterPreset]
    var complaintFilterPresets: [TS3ComplaintFilterPreset]
    var temporaryServerPasswordFilterPresets: [TS3TemporaryServerPasswordFilterPreset]
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
        savedChannelPasswords: [TS3SavedChannelPassword],
        identityProfiles: [TS3IdentityProfile],
        contacts: [TS3ContactEntry],
        contactFilterPresets: [TS3ContactFilterPreset],
        notificationSettings: TS3NotificationSettings,
        connectionRecoverySettings: TS3ConnectionRecoverySettings,
        chatHistorySettings: TS3ChatHistorySettings,
        serverLogQueryPresets: [TS3ServerLogQueryPreset],
        keyboardShortcuts: [TS3KeyboardShortcutBinding],
        channelSubscriptionPresets: [TS3ChannelSubscriptionPreset],
        channelTreeFilterPresets: [TS3ChannelTreeFilterPreset],
        collapsedChannelIds: [Int] = [],
        eventFilterPresets: [TS3EventFilterPreset],
        chatFilterPresets: [TS3ChatFilterPreset],
        fileBrowserBookmarks: [TS3FileBrowserBookmark],
        fileBrowserFilterPresets: [TS3FileBrowserFilterPreset],
        offlineMessageFilterPresets: [TS3OfflineMessageFilterPreset],
        banFilterPresets: [TS3BanFilterPreset],
        complaintFilterPresets: [TS3ComplaintFilterPreset],
        temporaryServerPasswordFilterPresets: [TS3TemporaryServerPasswordFilterPreset],
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
        self.savedChannelPasswords = savedChannelPasswords
        self.identityProfiles = identityProfiles
        self.contacts = contacts
        self.contactFilterPresets = contactFilterPresets
        self.notificationSettings = notificationSettings
        self.connectionRecoverySettings = connectionRecoverySettings
        self.chatHistorySettings = chatHistorySettings
        self.serverLogQueryPresets = serverLogQueryPresets
        self.keyboardShortcuts = keyboardShortcuts
        self.channelSubscriptionPresets = channelSubscriptionPresets
        self.channelTreeFilterPresets = channelTreeFilterPresets
        self.collapsedChannelIds = collapsedChannelIds
        self.eventFilterPresets = eventFilterPresets
        self.chatFilterPresets = chatFilterPresets
        self.fileBrowserBookmarks = fileBrowserBookmarks
        self.fileBrowserFilterPresets = fileBrowserFilterPresets
        self.offlineMessageFilterPresets = offlineMessageFilterPresets
        self.banFilterPresets = banFilterPresets
        self.complaintFilterPresets = complaintFilterPresets
        self.temporaryServerPasswordFilterPresets = temporaryServerPasswordFilterPresets
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
        case savedChannelPasswords
        case identityProfiles
        case contacts
        case contactFilterPresets
        case notificationSettings
        case connectionRecoverySettings
        case chatHistorySettings
        case serverLogQueryPresets
        case keyboardShortcuts
        case channelSubscriptionPresets
        case channelTreeFilterPresets
        case collapsedChannelIds
        case eventFilterPresets
        case chatFilterPresets
        case fileBrowserBookmarks
        case fileBrowserFilterPresets
        case offlineMessageFilterPresets
        case banFilterPresets
        case complaintFilterPresets
        case temporaryServerPasswordFilterPresets
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
        savedChannelPasswords = try container.decodeIfPresent(
            [TS3SavedChannelPassword].self,
            forKey: .savedChannelPasswords
        ) ?? []
        identityProfiles = try container.decodeIfPresent(
            [TS3IdentityProfile].self,
            forKey: .identityProfiles
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
        chatHistorySettings = try container.decodeIfPresent(
            TS3ChatHistorySettings.self,
            forKey: .chatHistorySettings
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
        collapsedChannelIds = try container.decodeIfPresent([Int].self, forKey: .collapsedChannelIds) ?? []
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
        temporaryServerPasswordFilterPresets = try container.decodeIfPresent(
            [TS3TemporaryServerPasswordFilterPreset].self,
            forKey: .temporaryServerPasswordFilterPresets
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

struct TS3ClientMigrationPackagePreview {
    let schemaVersion: Int
    let exportedAt: Date
    let itemCounts: [(String, Int)]
    let settingsGroups: [String]
    let settingsDetails: [String]

    var totalItemCount: Int {
        itemCounts.reduce(0) { $0 + $1.1 }
    }
}

struct TS3ClientMigrationRestoreOptions: Codable, Equatable {
    var connections: Bool
    var identities: Bool
    var contacts: Bool
    var notifications: Bool
    var chat: Bool
    var serverAdministration: Bool
    var channelLayout: Bool
    var files: Bool
    var audio: Bool
    var selfStatus: Bool
    var whisper: Bool

    static let all = TS3ClientMigrationRestoreOptions(
        connections: true,
        identities: true,
        contacts: true,
        notifications: true,
        chat: true,
        serverAdministration: true,
        channelLayout: true,
        files: true,
        audio: true,
        selfStatus: true,
        whisper: true
    )

    var selectedSectionTitles: [String] {
        var titles: [String] = []
        if connections { titles.append("Connections") }
        if identities { titles.append("Identities") }
        if contacts { titles.append("Contacts") }
        if notifications { titles.append("Notifications") }
        if chat { titles.append("Chat") }
        if serverAdministration { titles.append("Server Administration") }
        if channelLayout { titles.append("Channel Layout") }
        if files { titles.append("Files") }
        if audio { titles.append("Audio") }
        if selfStatus { titles.append("Self Status") }
        if whisper { titles.append("Whisper") }
        return titles
    }

    var hasSelectedSections: Bool {
        !selectedSectionTitles.isEmpty
    }
}

struct TS3NotificationSettingsPreview {
    let lines: [String]
}

struct TS3BookmarkSummary: Identifiable, Codable {
    let id: UUID
    var name: String
    var folder: String
    var note: String
    var host: String
    var port: String
    var nickname: String
    var phoneticNickname: String
    var serverPassword: String
    var defaultChannel: String
    var defaultChannelPassword: String
    var privilegeKey: String

    init(
        id: UUID = UUID(),
        name: String,
        folder: String = "",
        note: String = "",
        host: String,
        port: String,
        nickname: String,
        phoneticNickname: String = "",
        serverPassword: String,
        defaultChannel: String,
        defaultChannelPassword: String,
        privilegeKey: String
    ) {
        self.id = id
        self.name = name
        self.folder = folder
        self.note = note
        self.host = host
        self.port = port
        self.nickname = nickname
        self.phoneticNickname = phoneticNickname
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case folder
        case note
        case host
        case port
        case nickname
        case phoneticNickname
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
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(String.self, forKey: .port)
        nickname = try container.decode(String.self, forKey: .nickname)
        phoneticNickname = try container.decodeIfPresent(String.self, forKey: .phoneticNickname) ?? ""
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
    let phoneticNickname: String
    let note: String
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
        phoneticNickname: String = "",
        note: String = "",
        serverPassword: String,
        defaultChannel: String,
        defaultChannelPassword: String,
        privilegeKey: String
    ) {
        self.id = id
        self.host = host
        self.port = port
        self.nickname = nickname
        self.phoneticNickname = phoneticNickname
        self.note = note
        self.serverPassword = serverPassword
        self.defaultChannel = defaultChannel
        self.defaultChannelPassword = defaultChannelPassword
        self.privilegeKey = privilegeKey
    }

    enum CodingKeys: String, CodingKey {
        case id
        case host
        case port
        case nickname
        case phoneticNickname
        case note
        case serverPassword
        case defaultChannel
        case defaultChannelPassword
        case privilegeKey
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        host = try container.decode(String.self, forKey: .host)
        port = try container.decode(String.self, forKey: .port)
        nickname = try container.decode(String.self, forKey: .nickname)
        phoneticNickname = try container.decodeIfPresent(String.self, forKey: .phoneticNickname) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
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

struct TS3IdentityProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var uid: String
    var securityLevel: Int
    var keyOffset: Int
    var exportString: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        uid: String,
        securityLevel: Int,
        keyOffset: Int,
        exportString: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.uid = uid
        self.securityLevel = securityLevel
        self.keyOffset = keyOffset
        self.exportString = exportString
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case uid
        case securityLevel
        case keyOffset
        case exportString
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Identity"
        uid = try container.decode(String.self, forKey: .uid)
        securityLevel = try container.decodeIfPresent(Int.self, forKey: .securityLevel) ?? 0
        keyOffset = try container.decodeIfPresent(Int.self, forKey: .keyOffset) ?? 0
        exportString = try container.decode(String.self, forKey: .exportString)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }

    var clipboardSummary: String {
        [
            "name=\(name)",
            "uid=\(uid)",
            "security=\(securityLevel)",
            "keyOffset=\(keyOffset)",
            "backupLength=\(exportString.count)"
        ].joined(separator: " | ")
    }

    func accessibilityValue(isActive: Bool, canSwitch: Bool) -> String {
        var parts = [
            isActive ? "Active" : "Saved",
            "Security level \(securityLevel)",
            "Key offset \(keyOffset)",
            "UID \(uid)"
        ]
        if !canSwitch {
            parts.append("Disconnect before switching identities")
        }
        return parts.joined(separator: ". ")
    }
}

struct TS3ServerInfoSummary {
    var name: String
    var uniqueIdentifier: String?
    var platform: String?
    var version: String?
    var createdAt: Date?
    var clientsOnline: Int?
    var maxClients: Int?
    var port: Int?
    var clientsInQuery: Int?
    var reservedSlots: Int?
    var channelsOnline: Int?
    var uptimeSeconds: Int?
    var welcomeMessage: String?
    var passwordProtected: Bool
    var phoneticName: String?
    var status: String?
    var machineId: String?
    var isAutoStartEnabled: Bool?
    var codecEncryptionMode: Int?
    var isWeblistEnabled: Bool?
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
    var antiFloodPointsTickReduce: Int?
    var antiFloodPointsNeededCommandBlock: Int?
    var antiFloodPointsNeededIPBlock: Int?
    var antiFloodPointsNeededPluginBlock: Int?
    var isClientLoggingEnabled: Bool?
    var isQueryLoggingEnabled: Bool?
    var isChannelLoggingEnabled: Bool?
    var isPermissionLoggingEnabled: Bool?
    var isServerLoggingEnabled: Bool?
    var isFileTransferLoggingEnabled: Bool?
    var clientConnections: Int?
    var queryClientConnections: Int?
    var downloadQuota: Int64?
    var uploadQuota: Int64?
    var maxDownloadTotalBandwidth: Int64?
    var maxUploadTotalBandwidth: Int64?
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
    var hostBannerMode: Int?
    var hostBannerGraphicsInterval: Int?
    var hostButtonTooltip: String?
    var hostButtonURL: String?
    var hostButtonGraphicsURL: String?
    var iconId: Int?
    var iconURL: URL?
    var neededIdentitySecurityLevel: Int?
    var minClientVersion: Int?
    var minAndroidVersion: Int?
    var minIOSVersion: Int?

    static let empty = TS3ServerInfoSummary(
        name: "",
        uniqueIdentifier: nil,
        platform: nil,
        version: nil,
        createdAt: nil,
        clientsOnline: nil,
        maxClients: nil,
        port: nil,
        clientsInQuery: nil,
        reservedSlots: nil,
        channelsOnline: nil,
        uptimeSeconds: nil,
        welcomeMessage: nil,
        passwordProtected: false,
        phoneticName: nil,
        status: nil,
        machineId: nil,
        isAutoStartEnabled: nil,
        codecEncryptionMode: nil,
        isWeblistEnabled: nil,
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
        antiFloodPointsTickReduce: nil,
        antiFloodPointsNeededCommandBlock: nil,
        antiFloodPointsNeededIPBlock: nil,
        antiFloodPointsNeededPluginBlock: nil,
        isClientLoggingEnabled: nil,
        isQueryLoggingEnabled: nil,
        isChannelLoggingEnabled: nil,
        isPermissionLoggingEnabled: nil,
        isServerLoggingEnabled: nil,
        isFileTransferLoggingEnabled: nil,
        clientConnections: nil,
        queryClientConnections: nil,
        downloadQuota: nil,
        uploadQuota: nil,
        maxDownloadTotalBandwidth: nil,
        maxUploadTotalBandwidth: nil,
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
        hostBannerMode: nil,
        hostBannerGraphicsInterval: nil,
        hostButtonTooltip: nil,
        hostButtonURL: nil,
        hostButtonGraphicsURL: nil,
        iconId: nil,
        iconURL: nil,
        neededIdentitySecurityLevel: nil,
        minClientVersion: nil,
        minAndroidVersion: nil,
        minIOSVersion: nil
    )
}

enum TS3CodecEncryptionMode: Int, CaseIterable, Identifiable {
    case individual = 0
    case disabled = 1
    case enabled = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .individual:
            return "Per Channel"
        case .disabled:
            return "Disabled"
        case .enabled:
            return "Enabled"
        }
    }

    static func title(for value: Int) -> String {
        if let mode = TS3CodecEncryptionMode(rawValue: value) {
            return "\(mode.title) (\(value))"
        }
        return "Unknown (\(value))"
    }
}

enum TS3HostMessageMode: Int, CaseIterable, Identifiable {
    case none = 0
    case log = 1
    case modal = 2
    case modalQuit = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .none:
            return "None"
        case .log:
            return "Log"
        case .modal:
            return "Modal"
        case .modalQuit:
            return "Modal Quit"
        }
    }

    static func title(for value: Int) -> String {
        if let mode = TS3HostMessageMode(rawValue: value) {
            return "\(mode.title) (\(value))"
        }
        return "Unknown (\(value))"
    }
}

enum TS3HostBannerMode: Int, CaseIterable, Identifiable {
    case noAdjust = 0
    case ignoreAspect = 1
    case keepAspect = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .noAdjust:
            return "No Adjustment"
        case .ignoreAspect:
            return "Ignore Aspect Ratio"
        case .keepAspect:
            return "Keep Aspect Ratio"
        }
    }

    static func title(for value: Int) -> String {
        if let mode = TS3HostBannerMode(rawValue: value) {
            return "\(mode.title) (\(value))"
        }
        return "Unknown (\(value))"
    }
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

struct TS3ServerLogSummary: Identifiable, Codable {
    let id: Int
    let timestamp: Date?
    let level: String?
    let channel: String?
    let message: String
    let rawLine: String

    init(
        id: Int,
        timestamp: Date?,
        level: String?,
        channel: String?,
        message: String,
        rawLine: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.channel = channel
        self.message = message
        self.rawLine = rawLine
    }

    init(entry: TS3ServerLogEntry) {
        self.id = entry.id
        self.timestamp = entry.timestamp
        self.level = entry.level
        self.channel = entry.channel
        self.message = entry.message
        self.rawLine = entry.rawLine
    }

    var archiveSummary: String {
        var parts = [
            "id=\(id)",
            "message=\(message)"
        ]
        if let level, !level.isEmpty {
            parts.append("level=\(level)")
        }
        if let channel, !channel.isEmpty {
            parts.append("channel=\(channel)")
        }
        if let timestamp {
            parts.append("timestamp=\(Int(timestamp.timeIntervalSince1970))")
        }
        return parts.joined(separator: " | ")
    }

    var clipboardSummary: String {
        var parts = [archiveSummary]
        if !rawLine.isEmpty, rawLine != message {
            parts.append("raw=\(rawLine)")
        }
        return parts.joined(separator: " | ")
    }

    var accessibilityValue: String {
        var parts = ["Log entry \(id)"]
        if let level, !level.isEmpty {
            parts.append("Level \(level)")
        }
        if let channel, !channel.isEmpty {
            parts.append("Channel \(channel)")
        }
        if timestamp != nil {
            parts.append("Timestamp available")
        }
        parts.append(message)
        return parts.joined(separator: ". ")
    }
}

private struct TS3ServerLogArchive: Codable {
    var entries: [TS3ServerLogSummary]
}

struct TS3ServerLogArchivePreview {
    let entryCount: Int
    let skippedEntryCount: Int
    let levelCount: Int
    let channelCount: Int
    let timestampCount: Int
    let entrySummaries: [String]
    let firstLevel: String?
    let firstChannel: String?
    let firstMessage: String?
    let firstTimestamp: Date?

    var hasEntries: Bool {
        entryCount > 0
    }

    var clipboardSummary: String {
        entrySummaries.joined(separator: "\n")
    }
}

struct TS3ServerLogQueryPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var limit: Int
    var beginPosition: Int
    var reverse: Bool
    var instance: Bool
    var levelFilter: String
    var channelFilter: String
    var searchText: String
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case limit
        case beginPosition
        case reverse
        case instance
        case levelFilter
        case channelFilter
        case searchText
        case updatedAt
    }

    init(
        id: UUID = UUID(),
        name: String,
        limit: Int,
        beginPosition: Int = 0,
        reverse: Bool,
        instance: Bool,
        levelFilter: String,
        channelFilter: String = "",
        searchText: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.limit = limit
        self.beginPosition = beginPosition
        self.reverse = reverse
        self.instance = instance
        self.levelFilter = levelFilter
        self.channelFilter = channelFilter
        self.searchText = searchText
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        limit = try container.decode(Int.self, forKey: .limit)
        beginPosition = try container.decodeIfPresent(Int.self, forKey: .beginPosition) ?? 0
        reverse = try container.decode(Bool.self, forKey: .reverse)
        instance = try container.decode(Bool.self, forKey: .instance)
        levelFilter = try container.decode(String.self, forKey: .levelFilter)
        channelFilter = try container.decodeIfPresent(String.self, forKey: .channelFilter) ?? ""
        searchText = try container.decode(String.self, forKey: .searchText)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct TS3ServerLogQueryDraft {
    var limitText: String
    var beginPositionText: String
    var reverse: Bool
    var instance: Bool
    var levelFilter: String
    var channelFilter: String
    var searchText: String

    var limit: Int? {
        Self.parseBoundedInteger(limitText, range: 1...1_000)
    }

    var beginPosition: Int? {
        Self.parseBoundedInteger(beginPositionText, range: 0...1_000_000)
    }

    var validationMessages: [String] {
        var messages: [String] = []
        if limit == nil {
            messages.append("Lines must be between 1 and 1000.")
        }
        if beginPosition == nil {
            messages.append("Begin position must be between 0 and 1000000.")
        }
        return messages
    }

    var clipboardSummary: String {
        querySummaryLines(includeFilters: true).joined(separator: "\n")
    }

    var inlineSummary: String {
        querySummaryLines(includeFilters: false).joined(separator: " · ")
    }

    var accessibilityValue: String {
        querySummaryLines(includeFilters: true).joined(separator: ". ")
    }

    private var normalizedLevelFilter: String {
        let level = levelFilter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ["all", "info", "warning", "error", "debug"].contains(level) ? level : "all"
    }

    private var levelTitle: String {
        switch normalizedLevelFilter {
        case "info": return "Info"
        case "warning": return "Warning"
        case "error": return "Error"
        case "debug": return "Debug"
        default: return "All Levels"
        }
    }

    private func querySummaryLines(includeFilters: Bool) -> [String] {
        var lines = [
            "Scope: \(instance ? "Instance" : "Server") logs",
            "Lines: \(limit.map(String.init) ?? limitText.trimmingCharacters(in: .whitespacesAndNewlines))",
            "Begin position: \(beginPosition.map(String.init) ?? beginPositionText.trimmingCharacters(in: .whitespacesAndNewlines))",
            "Order: \(reverse ? "Reverse" : "Forward")"
        ]
        if includeFilters || normalizedLevelFilter != "all" {
            lines.append("Level filter: \(levelTitle)")
        }
        let channel = channelFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !channel.isEmpty {
            lines.append("Channel filter: \(channel)")
        }
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !search.isEmpty {
            lines.append("Search: \(search)")
        }
        return lines
    }

    private static func parseBoundedInteger(_ value: String, range: ClosedRange<Int>) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Int(trimmed), range.contains(parsed) else { return nil }
        return parsed
    }
}

extension TS3ServerLogQueryPreset {
    var queryDraft: TS3ServerLogQueryDraft {
        TS3ServerLogQueryDraft(
            limitText: String(limit),
            beginPositionText: String(beginPosition),
            reverse: reverse,
            instance: instance,
            levelFilter: levelFilter,
            channelFilter: channelFilter,
            searchText: searchText
        )
    }

    var clipboardSummary: String {
        queryDraft.clipboardSummary
    }

    var accessibilityValue: String {
        "\(name). \(queryDraft.accessibilityValue)"
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

struct TS3WhisperActivationLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let action: String
    let routeDescription: String
    let activationStatus: String
    let isTalking: Bool

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        action: String,
        routeDescription: String,
        activationStatus: String,
        isTalking: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.routeDescription = routeDescription
        self.activationStatus = activationStatus
        self.isTalking = isTalking
    }
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
        TS3KeyboardShortcutBinding(actionId: "manage-identity", group: "Global", action: "Manage Identity", defaultKeys: "Command-Option-Y"),
        TS3KeyboardShortcutBinding(actionId: "connection-manager", group: "Global", action: "Connection Manager", defaultKeys: "Command-Option-O"),
        TS3KeyboardShortcutBinding(actionId: "client-migration", group: "Global", action: "Client Migration", defaultKeys: "Command-Option-M"),
        TS3KeyboardShortcutBinding(actionId: "notification-settings", group: "Global", action: "Notification Settings", defaultKeys: "Command-Option-N"),
        TS3KeyboardShortcutBinding(actionId: "toggle-talk", group: "Voice", action: "Talk / Stop Talking", defaultKeys: "Command-T"),
        TS3KeyboardShortcutBinding(actionId: "toggle-input-muted", group: "Voice", action: "Mute / Unmute Microphone", defaultKeys: "Command-Shift-M"),
        TS3KeyboardShortcutBinding(actionId: "toggle-output-muted", group: "Voice", action: "Mute / Unmute Sound", defaultKeys: "Command-Shift-S"),
        TS3KeyboardShortcutBinding(actionId: "self-status", group: "Voice", action: "Self Status", defaultKeys: "Command-Option-A"),
        TS3KeyboardShortcutBinding(actionId: "audio-settings", group: "Voice", action: "Audio Settings", defaultKeys: "Command-Option-D"),
        TS3KeyboardShortcutBinding(actionId: "toggle-away", group: "Profile", action: "Set / Clear Away", defaultKeys: "Command-Shift-A"),
        TS3KeyboardShortcutBinding(actionId: "apply-nickname", group: "Profile", action: "Apply Nickname", defaultKeys: "Command-Return"),
        TS3KeyboardShortcutBinding(actionId: "open-chat", group: "Messaging", action: "Open Chat", defaultKeys: "Command-Shift-T"),
        TS3KeyboardShortcutBinding(actionId: "open-offline-messages", group: "Messaging", action: "Open Offline Messages", defaultKeys: "Command-Shift-I"),
        TS3KeyboardShortcutBinding(actionId: "open-events", group: "Messaging", action: "Open Events", defaultKeys: "Command-Shift-E"),
        TS3KeyboardShortcutBinding(actionId: "open-whisper", group: "Messaging", action: "Open Whisper", defaultKeys: "Command-Shift-W"),
        TS3KeyboardShortcutBinding(actionId: "toggle-whisper-activation", group: "Voice", action: "Start / Stop Temporary Whisper", defaultKeys: "Command-Option-W"),
        TS3KeyboardShortcutBinding(actionId: "start-whisper-activation", group: "Voice", action: "Start Temporary Whisper", defaultKeys: "Command-Option-H"),
        TS3KeyboardShortcutBinding(actionId: "stop-whisper-activation", group: "Voice", action: "Stop Temporary Whisper", defaultKeys: "Command-Option-Shift-H"),
        TS3KeyboardShortcutBinding(actionId: "refresh-server", group: "Server", action: "Refresh Channels and Clients", defaultKeys: "Command-Shift-R"),
        TS3KeyboardShortcutBinding(actionId: "save-bookmark", group: "Server", action: "Save Current Server as Bookmark", defaultKeys: "Command-Option-B"),
        TS3KeyboardShortcutBinding(actionId: "copy-invite", group: "Server", action: "Copy Invite Link", defaultKeys: "Command-Option-U"),
        TS3KeyboardShortcutBinding(actionId: "copy-full-invite", group: "Server", action: "Copy Full Invite Link", defaultKeys: "Command-Option-Shift-U"),
        TS3KeyboardShortcutBinding(actionId: "view-server-logs", group: "Server", action: "View Server Logs", defaultKeys: "Command-Shift-G"),
        TS3KeyboardShortcutBinding(actionId: "view-server-info", group: "Server", action: "View Server Information", defaultKeys: "Command-Option-I"),
        TS3KeyboardShortcutBinding(actionId: "edit-server-settings", group: "Server", action: "Edit Server Settings", defaultKeys: "Command-Option-S"),
        TS3KeyboardShortcutBinding(actionId: "manage-contacts", group: "Server", action: "Manage Contacts", defaultKeys: "Command-Shift-C"),
        TS3KeyboardShortcutBinding(actionId: "browse-client-database", group: "Server", action: "Browse Client Database", defaultKeys: "Command-Shift-D"),
        TS3KeyboardShortcutBinding(actionId: "manage-bans", group: "Server", action: "Manage Bans", defaultKeys: "Command-Shift-B"),
        TS3KeyboardShortcutBinding(actionId: "browse-files", group: "Server", action: "Browse Channel Files", defaultKeys: "Command-Shift-F"),
        TS3KeyboardShortcutBinding(actionId: "manage-subscription-presets", group: "Server", action: "Channel Subscription Presets", defaultKeys: "Command-Option-C"),
        TS3KeyboardShortcutBinding(actionId: "manage-permissions", group: "Server", action: "View Permissions", defaultKeys: "Command-Shift-P"),
        TS3KeyboardShortcutBinding(actionId: "manage-permission-groups", group: "Server", action: "Manage Permission Groups", defaultKeys: "Command-Option-G"),
        TS3KeyboardShortcutBinding(actionId: "manage-privilege-keys", group: "Server", action: "Manage Privilege Keys", defaultKeys: "Command-Shift-K"),
        TS3KeyboardShortcutBinding(actionId: "manage-complaints", group: "Server", action: "Manage Complaints", defaultKeys: "Command-Option-L"),
        TS3KeyboardShortcutBinding(actionId: "manage-temporary-passwords", group: "Server", action: "Manage Temporary Passwords", defaultKeys: "Command-Option-P")
    ]

    @Published var state: UIConnectionState = .disconnected
    @Published var isShowingKeyboardShortcuts = false
    @Published var isShowingConnectionManager = false
    @Published var isShowingIdentity = false
    @Published var isShowingClientMigration = false
    @Published var isShowingNotificationSettings = false
    @Published var isShowingChat = false
    @Published var isShowingOfflineMessages = false
    @Published var isShowingEvents = false
    @Published var isShowingWhisper = false
    @Published var isShowingServerLogs = false
    @Published var isShowingServerInfo = false
    @Published var isShowingServerEditor = false
    @Published var isShowingGroupManagement = false
    @Published var isShowingSubscriptionPresets = false
    @Published var isShowingContacts = false
    @Published var isShowingClientDatabase = false
    @Published var isShowingBans = false
    @Published var isShowingFiles = false
    @Published var isShowingPermissions = false
    @Published var isShowingPrivilegeKeys = false
    @Published var isShowingComplaints = false
    @Published var isShowingTemporaryPasswords = false
    @Published var isShowingAudioSettings = false
    @Published var isShowingSelfStatus = false
    @Published var channels: [TS3ChannelSummary] = []
    @Published var clients: [TS3UserSummary] = []
    @Published var chatMessages: [TS3ChatMessageSummary] = []
    @Published private(set) var unreadChatMessageCount = 0
    @Published private(set) var pokeEvents: [TS3PokeSummary] = []
    @Published private(set) var unreadPokeCount = 0
    @Published private(set) var activityEvents: [TS3ActivitySummary] = []
    @Published private(set) var unreadActivityCount = 0
    @Published var offlineMessages: [TS3OfflineMessageSummary] = []
    @Published private(set) var offlineMessageDrafts: [TS3OfflineMessageDraft] = []
    @Published var banEntries: [TS3BanEntrySummary] = []
    @Published var complaintEntries: [TS3ComplaintSummary] = []
    @Published var complaintTarget: TS3UserSummary?
    @Published var temporaryServerPasswords: [TS3TemporaryServerPasswordSummary] = []
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
    @Published private(set) var collapsedChannelIds: Set<Int> = []
    @Published private(set) var eventFilterPresets: [TS3EventFilterPreset] = []
    @Published private(set) var chatFilterPresets: [TS3ChatFilterPreset] = []
    @Published private(set) var banFilterPresets: [TS3BanFilterPreset] = []
    @Published private(set) var complaintFilterPresets: [TS3ComplaintFilterPreset] = []
    @Published private(set) var temporaryServerPasswordFilterPresets: [TS3TemporaryServerPasswordFilterPreset] = []
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
    @Published private(set) var downloadedFiles: [TS3DownloadedFileSummary] = []
    @Published var bookmarks: [TS3BookmarkSummary] = []
    @Published var contacts: [TS3ContactEntry] = []
    @Published private(set) var contactFilterPresets: [TS3ContactFilterPreset] = []
    @Published var identitySummary: TS3IdentitySummary = .empty
    @Published private(set) var identityProfiles: [TS3IdentityProfile] = []
    @Published private(set) var activeIdentityProfileId: UUID?
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
    @Published var isWhisperActivationActive = false
    @Published private(set) var whisperActivationLog: [TS3WhisperActivationLogEntry] = []
    @Published private(set) var whisperPresets: [TS3WhisperPreset] = []
    @Published private(set) var whisperFilterPresets: [TS3WhisperFilterPreset] = []
    @Published var whisperActivationMode: TS3WhisperActivationMode = .holdToWhisper
    @Published var logs: [TS3LogEntry] = []
    @Published var isShowingDebug = false
    @Published var lastError: String?
    @Published var avatarDownloadStatus: String?
    @Published var playbackVolume: Double = 1.0
    @Published var userPlaybackPreferences: [String: TS3UserPlaybackPreference] = [:]
    @Published var inputGain: Double = 1.0
    @Published var audioTransmitMode: TS3AudioTransmitMode = .pushToTalk
    @Published var voiceActivationThreshold: Double = 0.03
    @Published private(set) var inputLevel: Double = 0
    @Published private(set) var isVoiceActivationTriggered = false
    @Published var prefersSpeakerOutput = true
    @Published private(set) var audioInputDevices: [TS3AudioRouteDeviceSummary] = []
    @Published private(set) var audioInputRoute = "System Default"
    @Published private(set) var audioOutputRoute = "System Default"
    @Published private(set) var audioRouteAvailabilityNotes: [String] = []
    @Published private(set) var audioProfiles: [TS3AudioProfile] = []
    @Published private(set) var keyboardShortcuts: [TS3KeyboardShortcutBinding] = TS3AppModel.defaultKeyboardShortcuts
    @Published var microphonePermissionPrompt: MicrophonePermissionPrompt?
    @Published private(set) var notificationsEnabled = false
    @Published var notificationSoundEnabled = TS3NotificationSettings.defaults.soundEnabled
    @Published var privateMessageNotificationsEnabled = TS3NotificationSettings.defaults.privateMessagesEnabled
    @Published var pokeNotificationsEnabled = TS3NotificationSettings.defaults.pokesEnabled
    @Published var activityNotificationsEnabled = TS3NotificationSettings.defaults.activityEnabled
    @Published private(set) var mutedNotificationServerKeys: [String] = []
    @Published private(set) var mutedNotificationContactUniqueIdentifiers: [String] = []
    @Published var notificationQuietHoursEnabled = TS3NotificationSettings.defaults.quietHoursEnabled
    @Published var notificationQuietHoursStartMinute = TS3NotificationSettings.defaults.quietHoursStartMinute
    @Published var notificationQuietHoursEndMinute = TS3NotificationSettings.defaults.quietHoursEndMinute
    @Published private(set) var autoReconnectEnabled = false
    @Published var autoReconnectInitialDelaySeconds = TS3ConnectionRecoverySettings.defaults.initialDelaySeconds
    @Published var autoReconnectMaxDelaySeconds = TS3ConnectionRecoverySettings.defaults.maxDelaySeconds
    @Published var autoReconnectMaxAttempts = TS3ConnectionRecoverySettings.defaults.maxAttempts
    @Published private(set) var autoReconnectIsScheduled = false
    @Published private(set) var autoReconnectStatus: String?
    @Published var chatHistoryMessageLimit = TS3ChatHistorySettings.defaults.messageLimit

    @Published var serverHost = ""
    @Published var serverPort = "9987"
    @Published var serverPassword = ""
    @Published var defaultChannel = ""
    @Published var defaultChannelPassword = ""
    @Published var privilegeKey = ""
    @Published var nickname = TS3PlatformSupport.defaultNickname
    @Published var phoneticNickname = ""
    @Published var connectionNote = ""
    @Published var awayMessage = ""
    @Published private(set) var selfStatusProfiles: [TS3SelfStatusProfile] = []
    @Published private(set) var recentConnections: [TS3ConnectionSnapshot] = []
    @Published private(set) var connectionFilterPresets: [TS3ConnectionFilterPreset] = []
    @Published private(set) var savedChannelPasswords: [TS3SavedChannelPassword] = []
    @Published private(set) var lastConnectionSnapshot: TS3ConnectionSnapshot?
    @Published private(set) var lastDisconnectMessage: String?

    private var client: TS3Client?
    private var iconURLs: [Int: URL] = [:]
    private var iconDownloads: Set<Int> = []
    private var failedIconIds: Set<Int> = []
    private var fileTransferTasks: [UUID: Task<Void, Never>] = [:]
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private var isViewingChat = false
    private var isAppActive = true
    private var whisperActivationPreviousRoute: TS3WhisperRoute?
    private var whisperActivationStartedTalking = false

    init() {
        loadAudioSettings()
        loadAudioProfiles()
        loadKeyboardShortcuts()
        loadNotificationSettings()
        loadConnectionRecoverySettings()
        loadChatHistorySettings()
        loadUserPlaybackPreferences()
        loadBookmarks()
        loadRecentConnections()
        loadConnectionFilterPresets()
        loadSavedChannelPasswords()
        loadServerLogResults()
        loadServerLogQueryPresets()
        loadChannelSubscriptionPresets()
        loadChannelTreeFilterPresets()
        loadCollapsedChannelIds()
        loadEventHistory()
        loadEventFilterPresets()
        loadChatFilterPresets()
        loadBanResults()
        loadBanFilterPresets()
        loadComplaintResults()
        loadComplaintFilterPresets()
        loadTemporaryServerPasswordFilterPresets()
        loadDatabaseClientFilterPresets()
        loadTemporaryServerPasswordResults()
        loadPrivilegeKeyResults()
        loadPrivilegeKeyFilterPresets()
        loadPermissionFilterPresets()
        loadGroupResults()
        loadGroupFilterPresets()
        loadGroupClientFilterPresets()
        loadContacts()
        loadContactFilterPresets()
        loadChatHistory()
        loadFileBrowserBookmarks()
        loadFileBrowserFilterPresets()
        loadDownloadedFiles()
        loadOfflineMessageHistory()
        loadOfflineMessageDrafts()
        loadOfflineMessageFilterPresets()
        loadWhisperPresets()
        loadWhisperFilterPresets()
        loadSelfStatusProfiles()
        loadIdentityProfiles()
        Task { @MainActor in
            await refreshIdentitySummary()
        }
    }

    var connectedStatus: String {
        state.title
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

    var ignoredContacts: [TS3ContactEntry] {
        contacts
            .filter { $0.status == .ignored }
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

    func setDefaultChannel(
        _ channel: TS3ChannelSummary,
        password: String,
        rememberPassword: Bool
    ) {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        setDefaultChannel(channel, password: trimmedPassword)
        if rememberPassword {
            saveChannelPassword(trimmedPassword, for: channel)
        }
    }

    func savedChannelPassword(for channel: TS3ChannelSummary) -> String? {
        let key = savedChannelPasswordKey(for: channel)
        return savedChannelPasswords.first {
            $0.serverKey.caseInsensitiveCompare(key.serverKey) == .orderedSame
                && $0.channelPath.caseInsensitiveCompare(key.channelPath) == .orderedSame
        }?.password
    }

    func hasSavedChannelPassword(for channel: TS3ChannelSummary) -> Bool {
        savedChannelPassword(for: channel) != nil
    }

    func saveChannelPassword(_ password: String, for channel: TS3ChannelSummary) {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPassword.isEmpty else {
            forgetSavedChannelPassword(for: channel)
            return
        }
        let key = savedChannelPasswordKey(for: channel)
        savedChannelPasswords.removeAll {
            $0.serverKey.caseInsensitiveCompare(key.serverKey) == .orderedSame
                && $0.channelPath.caseInsensitiveCompare(key.channelPath) == .orderedSame
        }
        savedChannelPasswords.insert(TS3SavedChannelPassword(
            serverKey: key.serverKey,
            channelPath: key.channelPath,
            password: trimmedPassword
        ), at: 0)
        savedChannelPasswords = sanitizedSavedChannelPasswords(savedChannelPasswords)
        saveSavedChannelPasswords()
        lastError = nil
    }

    func forgetSavedChannelPassword(for channel: TS3ChannelSummary) {
        let key = savedChannelPasswordKey(for: channel)
        let originalCount = savedChannelPasswords.count
        savedChannelPasswords.removeAll {
            $0.serverKey.caseInsensitiveCompare(key.serverKey) == .orderedSame
                && $0.channelPath.caseInsensitiveCompare(key.channelPath) == .orderedSame
        }
        if savedChannelPasswords.count != originalCount {
            saveSavedChannelPasswords()
        }
        lastError = nil
    }

    private func savedChannelPasswordKey(for channel: TS3ChannelSummary) -> (serverKey: String, channelPath: String) {
        let host = serverHost.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let port = serverPort.trimmingCharacters(in: .whitespacesAndNewlines)
        return (
            serverKey: "\(host):\(port.isEmpty ? "9987" : port)",
            channelPath: channelPath(for: channel).trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func resolvedChannelPassword(for channel: TS3ChannelSummary, password: String?) -> String? {
        if let password {
            let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return savedChannelPassword(for: channel)
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

    func onlineUser(for contact: TS3ContactEntry) -> TS3UserSummary? {
        clients.first { $0.uniqueIdentifier == contact.uniqueIdentifier }
    }

    func onlineUser(for record: TS3DatabaseClientSummary) -> TS3UserSummary? {
        guard let uniqueIdentifier = record.uniqueIdentifier, !uniqueIdentifier.isEmpty else { return nil }
        return clients.first { $0.uniqueIdentifier == uniqueIdentifier }
    }

    func onlineUser(for poke: TS3PokeSummary) -> TS3UserSummary? {
        if let senderId = poke.senderId,
           let user = clients.first(where: { $0.id == senderId }) {
            return user
        }
        guard let uniqueIdentifier = poke.senderUniqueIdentifier, !uniqueIdentifier.isEmpty else {
            return nil
        }
        return clients.first { $0.uniqueIdentifier == uniqueIdentifier }
    }

    func setContactStatus(_ status: TS3ContactStatus, for record: TS3DatabaseClientSummary) {
        updateContact(for: record, status: status, note: contactNote(for: record) ?? "")
    }

    func setContactNote(_ note: String, for record: TS3DatabaseClientSummary) {
        updateContact(for: record, status: contactStatus(for: record), note: note)
    }

    func databaseClient(forComplaintSource entry: TS3ComplaintSummary) -> TS3DatabaseClientSummary? {
        if let record = databaseClients.first(where: { $0.id == entry.sourceClientDatabaseId }) {
            return record
        }
        return clients.compactMap(TS3DatabaseClientSummary.init(user:))
            .first { $0.id == entry.sourceClientDatabaseId }
    }

    func setComplaintSourceContactStatus(_ status: TS3ContactStatus, for entry: TS3ComplaintSummary) {
        guard let record = databaseClient(forComplaintSource: entry) else {
            lastError = "Load the source database client before changing contact status."
            return
        }
        setContactStatus(status, for: record)
    }

    func deleteContact(_ contact: TS3ContactEntry) {
        contacts.removeAll { $0.uniqueIdentifier == contact.uniqueIdentifier }
        saveContacts()
        syncBlockedContactPlayback()
    }

    func deleteContacts(_ entries: [TS3ContactEntry]) {
        let identifiers = Set(entries.map(\.uniqueIdentifier))
        guard !identifiers.isEmpty else { return }
        contacts.removeAll { identifiers.contains($0.uniqueIdentifier) }
        saveContacts()
        syncBlockedContactPlayback()
        lastError = nil
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
                contacts[index].nickname = entry.nickname
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

    func appendNote(_ note: String, toContacts entries: [TS3ContactEntry]) {
        appendNote(TS3ContactNoteDraft(contacts: entries, note: note))
    }

    func appendNote(_ draft: TS3ContactNoteDraft) {
        let validationMessages = draft.validationMessages
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let note = draft.trimmedNote
        let uniqueIdentifiers = Set(draft.uniqueContacts.map(\.uniqueIdentifier))
        guard !uniqueIdentifiers.isEmpty else { return }
        let now = Date()
        contacts = contacts.map { contact in
            guard uniqueIdentifiers.contains(contact.uniqueIdentifier) else { return contact }
            var updated = contact
            let currentNote = updated.note.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.note = currentNote.isEmpty ? note : "\(currentNote)\n\(note)"
            updated.updatedAt = now
            return updated
        }
        saveContacts()
        lastError = nil
    }

    var onlineContactCandidates: [TS3ContactEntry] {
        clients
            .filter { !$0.isCurrentUser }
            .compactMap { user in
                guard let uniqueIdentifier = user.uniqueIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !uniqueIdentifier.isEmpty else {
                    return nil
                }
                if var existing = contacts.first(where: { $0.uniqueIdentifier == uniqueIdentifier }) {
                    existing.nickname = user.nickname
                    return existing
                }
                return TS3ContactEntry(
                    uniqueIdentifier: uniqueIdentifier,
                    nickname: user.nickname,
                    status: .neutral,
                    note: "",
                    updatedAt: Date()
                )
            }
            .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
    }

    func updateOnlineContacts(status: TS3ContactStatus) {
        updateContacts(onlineContactCandidates, status: status)
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

    private func isSuppressedMessage(_ message: TS3TextMessage) -> Bool {
        guard !message.isOwnMessage,
              let senderId = message.senderId,
              let sender = clients.first(where: { $0.id == senderId }) else {
            return false
        }
        return isSuppressedContactStatus(contactStatus(for: sender))
    }

    private func isSuppressedPoke(_ poke: TS3ClientPoke) -> Bool {
        guard !poke.isOwnPoke else { return false }
        if let uniqueIdentifier = poke.senderUniqueIdentifier,
           let status = contacts.first(where: { $0.uniqueIdentifier == uniqueIdentifier })?.status,
           isSuppressedContactStatus(status) {
            return true
        }
        guard let senderId = poke.senderId,
              let sender = clients.first(where: { $0.id == senderId }) else {
            return false
        }
        return isSuppressedContactStatus(contactStatus(for: sender))
    }

    private func isSuppressedContactStatus(_ status: TS3ContactStatus) -> Bool {
        status == .ignored || status == .blocked
    }

    private func isNotificationMuted(senderId: Int?, uniqueIdentifier: String?) -> Bool {
        if isCurrentServerNotificationsMuted() {
            return true
        }
        if let uniqueIdentifier,
           mutedNotificationContactUniqueIdentifiers.contains(normalizedNotificationKey(uniqueIdentifier)) {
            return true
        }
        guard let senderId,
              let sender = clients.first(where: { $0.id == senderId }),
              let uniqueIdentifier = sender.uniqueIdentifier else {
            return false
        }
        return mutedNotificationContactUniqueIdentifiers.contains(normalizedNotificationKey(uniqueIdentifier))
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
                neededJoinPower: nil,
                neededSubscribePower: nil,
                neededDescriptionViewPower: nil,
                codec: nil,
                codecQuality: nil,
                codecLatencyFactor: nil,
                isCodecUnencrypted: nil,
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
            privilegeKey: privilegeKey.isEmpty ? nil : privilegeKey,
            phoneticNickname: phoneticNickname.isEmpty ? nil : phoneticNickname
        )

        let newClient = TS3Client(config: config)
        newClient.delegate = self
        newClient.logHandler = { [weak self] entry in
            DispatchQueue.main.async {
                self?.appendLog(entry)
            }
        }
        newClient.inputLevelHandler = { [weak self, weak newClient] level, isVoiceActive in
            DispatchQueue.main.async {
                guard let self, self.client === newClient else { return }
                self.inputLevel = Double(level)
                self.isVoiceActivationTriggered = isVoiceActive
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
        phoneticNickname = snapshot.phoneticNickname
        connectionNote = snapshot.note
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
        phoneticNickname = snapshot.phoneticNickname
        connectionNote = snapshot.note
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

    @discardableResult
    func removeDuplicateRecentConnections() -> Int {
        let originalCount = recentConnections.count
        recentConnections = uniqueConnectionEntries(recentConnections) { snapshot in
            (snapshot.host, snapshot.port)
        }
        let removed = originalCount - recentConnections.count
        if removed > 0 {
            saveRecentConnections()
        }
        lastError = removed == 0
            ? "No duplicate recent servers found."
            : "Removed \(removed) duplicate recent server\(removed == 1 ? "" : "s")."
        return removed
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
                phoneticNickname: snapshot.phoneticNickname.trimmingCharacters(in: .whitespacesAndNewlines),
                note: snapshot.note.trimmingCharacters(in: .whitespacesAndNewlines),
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
        phoneticNickname = bookmark.phoneticNickname
        connectionNote = bookmark.note
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
            phoneticNickname: phoneticNickname,
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
            phoneticNickname: phoneticNickname,
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

    func saveCurrentConnectionPrivilegeKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        privilegeKey = trimmed
        lastError = nil
    }

    func copyCurrentFullInviteLink(privilegeKey key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let link = inviteLink(
            name: serverHost,
            host: serverHost,
            port: serverPort,
            nickname: nickname,
            phoneticNickname: phoneticNickname,
            serverPassword: serverPassword,
            defaultChannel: defaultChannel,
            defaultChannelPassword: defaultChannelPassword,
            privilegeKey: trimmed,
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
            "Phonetic Nickname: \(snapshot.phoneticNickname.isEmpty ? "None" : snapshot.phoneticNickname)",
            "Note: \(snapshot.note.isEmpty ? "None" : snapshot.note)",
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
            phoneticNickname: phoneticNickname,
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
            phoneticNickname: phoneticNickname,
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
            phoneticNickname: bookmark.phoneticNickname,
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
            phoneticNickname: bookmark.phoneticNickname,
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
            phoneticNickname = serverURL.phoneticNickname ?? ""
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
            note: connectionNote.trimmingCharacters(in: .whitespacesAndNewlines),
            host: serverHost,
            port: serverPort,
            nickname: nickname,
            phoneticNickname: phoneticNickname,
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
                note: snapshot.note.trimmingCharacters(in: .whitespacesAndNewlines),
                host: host,
                port: port,
                nickname: snapshot.nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneticNickname: snapshot.phoneticNickname.trimmingCharacters(in: .whitespacesAndNewlines),
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
        phoneticNickname: String,
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
            phoneticNickname: phoneticNickname,
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
        updated.note = bookmark.note.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.host = trimmedHost
        updated.port = bookmark.port.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.nickname = bookmark.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.phoneticNickname = bookmark.phoneticNickname.trimmingCharacters(in: .whitespacesAndNewlines)
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

    @discardableResult
    func removeDuplicateBookmarks() -> Int {
        let originalCount = bookmarks.count
        bookmarks = uniqueConnectionEntries(bookmarks) { bookmark in
            (bookmark.host, bookmark.port)
        }
        let removed = originalCount - bookmarks.count
        if removed > 0 {
            saveBookmarks()
        }
        lastError = removed == 0
            ? "No duplicate bookmarks found."
            : "Removed \(removed) duplicate bookmark\(removed == 1 ? "" : "s")."
        return removed
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

    func deleteAllConnectionFilterPresets() {
        guard !connectionFilterPresets.isEmpty else { return }
        connectionFilterPresets = []
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
            normalized.note = bookmark.note.trimmingCharacters(in: .whitespacesAndNewlines)
            normalized.nickname = bookmark.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            normalized.phoneticNickname = bookmark.phoneticNickname.trimmingCharacters(in: .whitespacesAndNewlines)
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
        resetInputMeter()
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
            phoneticNickname: phoneticNickname.trimmingCharacters(in: .whitespacesAndNewlines),
            note: connectionNote.trimmingCharacters(in: .whitespacesAndNewlines),
            serverPassword: serverPassword,
            defaultChannel: defaultChannel,
            defaultChannelPassword: defaultChannelPassword,
            privilegeKey: privilegeKey
        )
    }

    private func clearConnectionState(keepLastConnection: Bool) {
        channels = []
        clients = []
        unreadPokeCount = 0
        unreadActivityCount = 0
        complaintTarget = nil
        databaseClients = []
        databaseSearchResults = []
        clientLocations = []
        selectedDatabaseClient = nil
        connectionInfo = .empty
        permissionInfos = []
        ownClientPermissions = []
        ownClientDatabaseId = nil
        permissionEditScope = .ownClient
        selectedServerGroupPermissionId = nil
        selectedChannelGroupPermissionId = nil
        selectedChannelPermissionId = nil
        scopedPermissions = []
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
        resetInputMeter()
        isAway = false
        isInputMuted = false
        isOutputMuted = false
        isChannelCommander = false
        isRequestingTalkPower = false
        talkRequestMessage = ""
        whisperRoute = .none
        isWhisperActivationActive = false
        whisperActivationPreviousRoute = nil
        whisperActivationStartedTalking = false
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
            phoneticNickname: snapshot.phoneticNickname.trimmingCharacters(in: .whitespacesAndNewlines),
            note: snapshot.note.trimmingCharacters(in: .whitespacesAndNewlines),
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

    private func uniqueConnectionEntries<Entry>(
        _ entries: [Entry],
        key: (Entry) -> (host: String, port: String)
    ) -> [Entry] {
        var seen: Set<String> = []
        var unique: [Entry] = []
        for entry in entries {
            let parts = key(entry)
            let normalizedHost = parts.host.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedPort = parts.port.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedHost.isEmpty, !normalizedPort.isEmpty else {
                unique.append(entry)
                continue
            }
            let normalizedKey = "\(normalizedHost):\(normalizedPort)"
            guard seen.insert(normalizedKey).inserted else { continue }
            unique.append(entry)
        }
        return unique
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

    func calibrateVoiceActivationThresholdFromInput() {
        let calibrated = min(max(inputLevel * 1.35, 0.001), 0.5)
        updateVoiceActivationThreshold(calibrated)
    }

    func updatePrefersSpeakerOutput(_ prefersSpeaker: Bool) {
        prefersSpeakerOutput = prefersSpeaker
        client?.setPrefersSpeakerOutput(prefersSpeaker)
        applyAudioRoutePreference()
        saveAudioSettings()
    }

    func updateWhisperActivationMode(_ mode: TS3WhisperActivationMode) {
        whisperActivationMode = mode
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
        audioRouteAvailabilityNotes = audioRouteNotes(
            inputDevices: audioInputDevices,
            inputRoute: audioInputRoute,
            outputRoute: audioOutputRoute
        )
        #else
        audioInputDevices = []
        audioInputRoute = "System Default"
        audioOutputRoute = "System Default"
        audioRouteAvailabilityNotes = [
            "Audio route selection is controlled by the operating system on this platform."
        ]
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
            resetInputMeter()
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
            resetInputMeter()
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
        whisperActivationMode = TS3WhisperActivationMode(rawValue: defaults.whisperActivationMode) ?? .holdToWhisper
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
            resetInputMeter()
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

    func setNotificationQuietHoursEnabled(_ isEnabled: Bool) {
        notificationQuietHoursEnabled = isEnabled
        saveNotificationSettings()
    }

    func setNotificationQuietHours(startMinute: Int, endMinute: Int) {
        notificationQuietHoursStartMinute = sanitizedMinuteOfDay(startMinute)
        notificationQuietHoursEndMinute = sanitizedMinuteOfDay(endMinute)
        saveNotificationSettings()
    }

    func setCurrentServerNotificationsMuted(_ isMuted: Bool) {
        let key = currentNotificationServerKey
        guard !key.isEmpty else { return }
        setNotificationServerMuted(isMuted, key: key)
    }

    func isCurrentServerNotificationsMuted() -> Bool {
        let key = currentNotificationServerKey
        guard !key.isEmpty else { return false }
        return mutedNotificationServerKeys.contains(key)
    }

    func setNotificationServerMuted(_ isMuted: Bool, key: String) {
        let key = normalizedNotificationKey(key)
        guard !key.isEmpty else { return }
        var keys = Set(mutedNotificationServerKeys.map(normalizedNotificationKey))
        if isMuted {
            keys.insert(key)
        } else {
            keys.remove(key)
        }
        mutedNotificationServerKeys = keys.sorted()
        saveNotificationSettings()
    }

    func isContactNotificationsMuted(_ contact: TS3ContactEntry) -> Bool {
        mutedNotificationContactUniqueIdentifiers.contains(normalizedNotificationKey(contact.uniqueIdentifier))
    }

    func setContactNotificationsMuted(_ isMuted: Bool, contact: TS3ContactEntry) {
        let uniqueIdentifier = normalizedNotificationKey(contact.uniqueIdentifier)
        guard !uniqueIdentifier.isEmpty else { return }
        var identifiers = Set(mutedNotificationContactUniqueIdentifiers.map(normalizedNotificationKey))
        if isMuted {
            identifiers.insert(uniqueIdentifier)
        } else {
            identifiers.remove(uniqueIdentifier)
        }
        mutedNotificationContactUniqueIdentifiers = identifiers.sorted()
        saveNotificationSettings()
    }

    func clearNotificationRules() {
        mutedNotificationServerKeys = []
        mutedNotificationContactUniqueIdentifiers = []
        saveNotificationSettings()
        lastError = nil
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
        mutedNotificationServerKeys = TS3NotificationSettings.defaults.mutedServerKeys
        mutedNotificationContactUniqueIdentifiers = TS3NotificationSettings.defaults.mutedContactUniqueIdentifiers
        notificationQuietHoursEnabled = TS3NotificationSettings.defaults.quietHoursEnabled
        notificationQuietHoursStartMinute = TS3NotificationSettings.defaults.quietHoursStartMinute
        notificationQuietHoursEndMinute = TS3NotificationSettings.defaults.quietHoursEndMinute
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

    var inputLevelText: String {
        String(format: "%.3f", inputLevel)
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
        let validationMessages = TS3GroupDraftValidator.validationMessages(
            operation: .create,
            name: name,
            target: .server,
            type: type,
            sourceGroup: nil,
            existingGroups: serverGroups
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            _ = try await client.createServerGroup(name: name, type: type)
        }
    }

    func copyServerGroup(_ group: TS3GroupSummary, name: String, type: TS3PermissionGroupDatabaseType) {
        let validationMessages = TS3GroupDraftValidator.validationMessages(
            operation: .copy,
            name: name,
            target: .server,
            type: type,
            sourceGroup: group,
            existingGroups: serverGroups
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            _ = try await client.copyServerGroup(sourceGroupId: group.id, name: name, type: type)
        }
    }

    func renameServerGroup(_ group: TS3GroupSummary, name: String) {
        let validationMessages = TS3GroupDraftValidator.validationMessages(
            operation: .rename,
            name: name,
            target: .server,
            type: group.type ?? .regular,
            sourceGroup: group,
            existingGroups: serverGroups
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
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
        let validationMessages = TS3GroupDraftValidator.validationMessages(
            operation: .create,
            name: name,
            target: .channel,
            type: type,
            sourceGroup: nil,
            existingGroups: channelGroups
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            _ = try await client.createChannelGroup(name: name, type: type)
        }
    }

    func copyChannelGroup(_ group: TS3GroupSummary, name: String, type: TS3PermissionGroupDatabaseType) {
        let validationMessages = TS3GroupDraftValidator.validationMessages(
            operation: .copy,
            name: name,
            target: .channel,
            type: type,
            sourceGroup: group,
            existingGroups: channelGroups
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            _ = try await client.copyChannelGroup(sourceGroupId: group.id, name: name, type: type)
        }
    }

    func renameChannelGroup(_ group: TS3GroupSummary, name: String) {
        let validationMessages = TS3GroupDraftValidator.validationMessages(
            operation: .rename,
            name: name,
            target: .channel,
            type: group.type ?? .regular,
            sourceGroup: group,
            existingGroups: channelGroups
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
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

    func permissionEditTargetSummary(for scope: TS3PermissionEditScope? = nil) -> String {
        let scope = scope ?? permissionEditScope
        switch scope {
        case .ownClient:
            if let databaseId = ownClientDatabaseId {
                return "Current Client #\(databaseId)"
            }
            return clients.first(where: { $0.isCurrentUser }).map { "\($0.nickname) (#\($0.id))" } ?? "Current Client"
        case .databaseClient:
            guard let databaseId = selectedDatabaseClientPermissionId ?? selectedDatabaseClient?.id else {
                return "Database Client"
            }
            let nickname = databaseClients.first(where: { $0.id == databaseId })?.nickname
            return nickname.map { "\($0) (#\(databaseId))" } ?? "Database Client #\(databaseId)"
        case .serverGroup:
            guard let groupId = selectedServerGroupPermissionId ?? serverGroups.first?.id else {
                return "Server Group"
            }
            let name = serverGroups.first(where: { $0.id == groupId })?.name
            return name.map { "\($0) (#\(groupId))" } ?? "Server Group #\(groupId)"
        case .channelGroup:
            guard let groupId = selectedChannelGroupPermissionId ?? channelGroups.first?.id else {
                return "Channel Group"
            }
            let name = channelGroups.first(where: { $0.id == groupId })?.name
            return name.map { "\($0) (#\(groupId))" } ?? "Channel Group #\(groupId)"
        case .channel:
            guard let channelId = selectedChannelPermissionId ?? currentChannel?.id ?? channels.first?.id else {
                return "Channel"
            }
            let name = channels.first(where: { $0.id == channelId })?.name
            return name.map { "\($0) (#\(channelId))" } ?? "Channel #\(channelId)"
        case .channelClient:
            guard let selection = selectedChannelClientPermissionTarget() else {
                return "Channel Client"
            }
            let channelName = channels.first(where: { $0.id == selection.channelId })?.name ?? "Channel \(selection.channelId)"
            let clientName = clients.first(where: { $0.id == selection.clientId })?.nickname ?? "Client \(selection.clientId)"
            return "\(clientName) (#\(selection.databaseId)) in \(channelName)"
        }
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
        let draft = TS3PermissionEditDraft(
            scope: permissionEditScope,
            target: permissionEditTargetSummary(),
            name: name,
            value: String(value),
            negated: negated,
            skip: skip
        )
        addSelectedPermission(draft)
    }

    func addSelectedPermission(_ draft: TS3PermissionEditDraft) {
        let validationMessages = draft.validationMessages
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = draft.parsedValue else { return }
        let negated = draft.effectiveNegated
        let skip = draft.effectiveSkip
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
        let permissions = (permissionEditScope == .ownClient ? ownClientPermissions : scopedPermissions).map {
            TS3PermissionBackupPermission(
                name: $0.name,
                value: $0.value,
                isNegated: $0.isNegated,
                isSkipped: $0.isSkipped
            )
        }
        let snapshot = TS3PermissionBackup(
            scope: permissionEditScope.rawValue,
            ownClientDatabaseId: ownClientDatabaseId,
            selectedDatabaseClientPermissionId: selectedDatabaseClientPermissionId,
            selectedServerGroupPermissionId: selectedServerGroupPermissionId,
            selectedChannelGroupPermissionId: selectedChannelGroupPermissionId,
            selectedChannelPermissionId: selectedChannelPermissionId,
            selectedChannelClientPermissionChannelId: selectedChannelClientPermissionChannelId,
            selectedChannelClientPermissionClientId: selectedChannelClientPermissionClientId,
            permissions: sanitizedPermissionBackupPermissions(permissions)
        )
        return try encoder.encode(snapshot)
    }

    func importPermissionBackup(
        from data: Data,
        options: TS3PermissionBackupRestoreOptions = .all
    ) throws {
        let decoded = try JSONDecoder().decode(TS3PermissionBackup.self, from: data)
        applyPermissionBackupSelection(decoded)
        restorePermissionBackup(decoded, options: options)
    }

    func permissionBackupPreview(from data: Data) throws -> TS3PermissionBackupPreview {
        let decoded = try JSONDecoder().decode(TS3PermissionBackup.self, from: data)
        let scope = TS3PermissionEditScope(rawValue: decoded.scope) ?? .ownClient
        let permissions = sanitizedPermissionBackupPermissions(decoded.permissions)
        let currentPermissions = currentPermissionsForBackup(decoded, scope: scope)
        let currentByName = Dictionary((currentPermissions ?? []).map { ($0.name, $0) }, uniquingKeysWith: { _, latest in latest })
        let backupByName = Dictionary(permissions.map { ($0.name, $0) }, uniquingKeysWith: { _, latest in latest })
        let currentNames = Set(currentByName.keys)
        let backupNames = Set(backupByName.keys)
        let overwritePermissionNames = currentPermissions.map { _ in backupNames.intersection(currentNames).sorted() } ?? []
        let changedPermissionNames = currentPermissions.map { _ in
            overwritePermissionNames.filter { name in
                guard let current = currentByName[name], let backup = backupByName[name] else { return false }
                return !Self.permissionBackupPermission(backup, matches: current)
            }
        } ?? []
        let changedPermissionDetails: [String] = currentPermissions.map { _ in
            changedPermissionNames.compactMap { name in
                guard let current = currentByName[name], let backup = backupByName[name] else { return nil }
                return Self.permissionBackupChangeDescription(name: name, backup: backup, current: current)
            }
        } ?? []
        let unchangedPermissionNames = currentPermissions.map { _ in
            overwritePermissionNames.filter { name in
                guard let current = currentByName[name], let backup = backupByName[name] else { return false }
                return Self.permissionBackupPermission(backup, matches: current)
            }
        } ?? []
        let newPermissionNames = currentPermissions.map { _ in backupNames.subtracting(currentNames).sorted() } ?? []
        return TS3PermissionBackupPreview(
            scope: scope,
            targetDescription: permissionBackupTargetDescription(decoded, scope: scope),
            permissionCount: permissions.count,
            currentPermissionCount: currentPermissions?.count,
            overwriteCount: currentPermissions.map { _ in overwritePermissionNames.count },
            changedCount: currentPermissions.map { _ in changedPermissionNames.count },
            unchangedCount: currentPermissions.map { _ in unchangedPermissionNames.count },
            newPermissionCount: currentPermissions.map { _ in newPermissionNames.count },
            overwritePermissionNames: overwritePermissionNames,
            changedPermissionNames: changedPermissionNames,
            changedPermissionDetails: changedPermissionDetails,
            unchangedPermissionNames: unchangedPermissionNames,
            newPermissionNames: newPermissionNames
        )
    }

    func permissionBackupRestorePlan(
        from data: Data,
        options: TS3PermissionBackupRestoreOptions
    ) throws -> TS3PermissionBackupRestorePlan {
        let decoded = try JSONDecoder().decode(TS3PermissionBackup.self, from: data)
        let scope = TS3PermissionEditScope(rawValue: decoded.scope) ?? .ownClient
        let permissions = sanitizedPermissionBackupPermissions(decoded.permissions)
        let currentPermissions = currentPermissionsForBackup(decoded, scope: scope)
        let currentByName = currentPermissions.map {
            Dictionary($0.map { ($0.name, $0) }, uniquingKeysWith: { _, latest in latest })
        }
        let changedCount = currentByName.map { currentByName in
            permissions.filter { permission in
                guard let current = currentByName[permission.name] else { return false }
                return !Self.permissionBackupPermission(permission, matches: current)
            }.count
        }
        let newPermissionCount = currentByName.map { currentByName in
            permissions.filter { currentByName[$0.name] == nil }.count
        }
        let unchangedCount = currentByName.map { currentByName in
            permissions.filter { permission in
                guard let current = currentByName[permission.name] else { return false }
                return Self.permissionBackupPermission(permission, matches: current)
            }.count
        }
        let plannedNames = permissionsToRestore(
            permissions,
            currentByName: currentByName,
            options: options
        ).map { permission in
            Self.permissionBackupRestoreEntry(from: permission, currentByName: currentByName)
        }
        return TS3PermissionBackupRestorePlan(
            entries: plannedNames,
            targetDescription: permissionBackupTargetDescription(decoded, scope: scope),
            scope: scope,
            targetMatchesCurrentSelection: currentPermissions != nil,
            options: options,
            changedCount: changedCount,
            newPermissionCount: newPermissionCount,
            unchangedCount: unchangedCount
        )
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

    private func applyPermissionBackupSelection(_ backup: TS3PermissionBackup) {
        permissionEditScope = TS3PermissionEditScope(rawValue: backup.scope) ?? .ownClient
        ownClientDatabaseId = backup.ownClientDatabaseId
        selectedDatabaseClientPermissionId = backup.selectedDatabaseClientPermissionId
        selectedServerGroupPermissionId = backup.selectedServerGroupPermissionId
        selectedChannelGroupPermissionId = backup.selectedChannelGroupPermissionId
        selectedChannelPermissionId = backup.selectedChannelPermissionId
        selectedChannelClientPermissionChannelId = backup.selectedChannelClientPermissionChannelId
        selectedChannelClientPermissionClientId = backup.selectedChannelClientPermissionClientId
    }

    private func restorePermissionBackup(
        _ backup: TS3PermissionBackup,
        options: TS3PermissionBackupRestoreOptions = .all
    ) {
        let permissions = sanitizedPermissionBackupPermissions(backup.permissions)
        let currentByName = currentPermissionsForBackup(backup, scope: permissionEditScope).map {
            Dictionary($0.map { ($0.name, $0) }, uniquingKeysWith: { _, latest in latest })
        }
        let permissionsToRestore = permissionsToRestore(
            permissions,
            currentByName: currentByName,
            options: options
        )
        guard !permissionsToRestore.isEmpty else {
            refreshSelectedPermissions()
            lastError = nil
            return
        }

        switch permissionEditScope {
        case .ownClient, .databaseClient:
            guard let databaseId = permissionEditScope == .ownClient ? ownClientDatabaseId : selectedDatabaseClientPermissionId else {
                lastError = "Select a database client first."
                return
            }
            runClientCommand { client in
                for permission in permissionsToRestore {
                    try await client.addClientPermission(
                        clientDatabaseId: databaseId,
                        permissionName: permission.name,
                        value: permission.value,
                        skip: permission.isSkipped
                    )
                }
                let refreshed = try await client.refreshClientPermissions(clientDatabaseId: databaseId)
                await MainActor.run {
                    if self.permissionEditScope == .ownClient {
                        self.ownClientPermissions = self.permissionSummaries(from: refreshed)
                    } else {
                        self.scopedPermissions = self.permissionSummaries(from: refreshed)
                    }
                    self.lastError = nil
                }
            }
        case .serverGroup:
            guard let groupId = selectedServerGroupPermissionId else {
                lastError = "Select a server group first."
                return
            }
            runClientCommand { client in
                for permission in permissionsToRestore {
                    try await client.addServerGroupPermission(
                        groupId: groupId,
                        permissionName: permission.name,
                        value: permission.value,
                        negated: permission.isNegated,
                        skip: permission.isSkipped
                    )
                }
                let refreshed = try await client.refreshServerGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: refreshed)
                    self.lastError = nil
                }
            }
        case .channelGroup:
            guard let groupId = selectedChannelGroupPermissionId else {
                lastError = "Select a channel group first."
                return
            }
            runClientCommand { client in
                for permission in permissionsToRestore {
                    try await client.addChannelGroupPermission(
                        groupId: groupId,
                        permissionName: permission.name,
                        value: permission.value,
                        negated: permission.isNegated,
                        skip: permission.isSkipped
                    )
                }
                let refreshed = try await client.refreshChannelGroupPermissions(groupId: groupId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: refreshed)
                    self.lastError = nil
                }
            }
        case .channel:
            guard let channelId = selectedChannelPermissionId else {
                lastError = "Select a channel first."
                return
            }
            runClientCommand { client in
                for permission in permissionsToRestore {
                    try await client.addChannelPermission(
                        channelId: channelId,
                        permissionName: permission.name,
                        value: permission.value
                    )
                }
                let refreshed = try await client.refreshChannelPermissions(channelId: channelId)
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: refreshed)
                    self.lastError = nil
                }
            }
        case .channelClient:
            guard let selection = selectedChannelClientPermissionTarget() else {
                lastError = "Select a channel client first."
                return
            }
            runClientCommand { client in
                for permission in permissionsToRestore {
                    try await client.addChannelClientPermission(
                        channelId: selection.channelId,
                        clientDatabaseId: selection.databaseId,
                        permissionName: permission.name,
                        value: permission.value,
                        skip: permission.isSkipped
                    )
                }
                let refreshed = try await client.refreshChannelClientPermissions(
                    channelId: selection.channelId,
                    clientDatabaseId: selection.databaseId
                )
                await MainActor.run {
                    self.scopedPermissions = self.permissionSummaries(from: refreshed)
                    self.lastError = nil
                }
            }
        }
    }

    private func sanitizedPermissionBackupPermissions(
        _ permissions: [TS3PermissionBackupPermission]
    ) -> [TS3PermissionBackupPermission] {
        var seen: Set<String> = []
        return Array(permissions
            .reversed()
            .compactMap { permission -> TS3PermissionBackupPermission? in
                let name = permission.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, seen.insert(name).inserted else { return nil }
                return TS3PermissionBackupPermission(
                    name: name,
                    value: permission.value,
                    isNegated: permission.isNegated,
                    isSkipped: permission.isSkipped
                )
            }
            .reversed())
    }

    private func permissionsToRestore(
        _ permissions: [TS3PermissionBackupPermission],
        currentByName: [String: TS3PermissionSummary]?,
        options: TS3PermissionBackupRestoreOptions
    ) -> [TS3PermissionBackupPermission] {
        permissions.filter { permission in
            guard let currentByName else {
                return options.restoreWhenTargetCannotBeCompared
            }
            guard let current = currentByName[permission.name] else {
                return options.newPermissions
            }
            return options.changedExisting && !Self.permissionBackupPermission(permission, matches: current)
        }
    }

    private func currentPermissionsForBackup(_ backup: TS3PermissionBackup, scope: TS3PermissionEditScope) -> [TS3PermissionSummary]? {
        switch scope {
        case .ownClient:
            guard backup.ownClientDatabaseId == ownClientDatabaseId else { return nil }
            return ownClientPermissions
        case .databaseClient:
            guard backup.selectedDatabaseClientPermissionId == selectedDatabaseClientPermissionId else { return nil }
            return scopedPermissions
        case .serverGroup:
            guard backup.selectedServerGroupPermissionId == selectedServerGroupPermissionId else { return nil }
            return scopedPermissions
        case .channelGroup:
            guard backup.selectedChannelGroupPermissionId == selectedChannelGroupPermissionId else { return nil }
            return scopedPermissions
        case .channel:
            guard backup.selectedChannelPermissionId == selectedChannelPermissionId else { return nil }
            return scopedPermissions
        case .channelClient:
            guard backup.selectedChannelClientPermissionChannelId == selectedChannelClientPermissionChannelId,
                  backup.selectedChannelClientPermissionClientId == selectedChannelClientPermissionClientId else { return nil }
            return scopedPermissions
        }
    }

    private func permissionBackupTargetDescription(_ backup: TS3PermissionBackup, scope: TS3PermissionEditScope) -> String {
        switch scope {
        case .ownClient:
            return backup.ownClientDatabaseId.map { "Own Client DB \($0)" } ?? "Own Client"
        case .databaseClient:
            return backup.selectedDatabaseClientPermissionId.map { "Database Client \($0)" } ?? "Database Client"
        case .serverGroup:
            return backup.selectedServerGroupPermissionId.map { TS3GroupSummary.name(for: $0, in: serverGroups) } ?? "Server Group"
        case .channelGroup:
            return backup.selectedChannelGroupPermissionId.map { TS3GroupSummary.name(for: $0, in: channelGroups) } ?? "Channel Group"
        case .channel:
            return backup.selectedChannelPermissionId.flatMap { channelName(for: $0) } ?? "Channel"
        case .channelClient:
            let channel = backup.selectedChannelClientPermissionChannelId.flatMap { channelName(for: $0) } ?? "Channel"
            let client = backup.selectedChannelClientPermissionClientId.map { "Client \($0)" } ?? "Client"
            return "\(client) in \(channel)"
        }
    }

    private static func permissionBackupPermission(
        _ backupPermission: TS3PermissionBackupPermission,
        matches current: TS3PermissionSummary
    ) -> Bool {
        backupPermission.name == current.name
            && backupPermission.value == current.value
            && backupPermission.isNegated == current.isNegated
            && backupPermission.isSkipped == current.isSkipped
    }

    private static func permissionBackupChangeSummary(
        name: String,
        backup: TS3PermissionBackupPermission,
        current: TS3PermissionSummary
    ) -> String {
        var changes: [String] = []
        if backup.value != current.value {
            changes.append("value \(current.value) -> \(backup.value)")
        }
        if backup.isNegated != current.isNegated {
            changes.append("negated \(permissionBackupFlagDescription(current.isNegated)) -> \(permissionBackupFlagDescription(backup.isNegated))")
        }
        if backup.isSkipped != current.isSkipped {
            changes.append("skip \(permissionBackupFlagDescription(current.isSkipped)) -> \(permissionBackupFlagDescription(backup.isSkipped))")
        }
        return changes.joined(separator: ", ")
    }

    private static func permissionBackupChangeDescription(
        name: String,
        backup: TS3PermissionBackupPermission,
        current: TS3PermissionSummary
    ) -> String {
        "\(name): \(permissionBackupChangeSummary(name: name, backup: backup, current: current))"
    }

    private static func permissionBackupFlagDescription(_ value: Bool) -> String {
        value ? "on" : "off"
    }

    private static func permissionBackupRestoreEntry(
        from permission: TS3PermissionBackupPermission,
        currentByName: [String: TS3PermissionSummary]?
    ) -> TS3PermissionBackupRestoreEntry {
        let current = currentByName?[permission.name]
        let reason: String
        let changeSummary: String?
        if let current {
            reason = "changed existing"
            changeSummary = permissionBackupChangeSummary(name: permission.name, backup: permission, current: current)
        } else if currentByName == nil {
            reason = "not comparable"
            changeSummary = nil
        } else {
            reason = "new permission"
            changeSummary = nil
        }
        return TS3PermissionBackupRestoreEntry(
            name: permission.name,
            value: permission.value,
            isNegated: permission.isNegated,
            isSkipped: permission.isSkipped,
            restoreReason: reason,
            changeSummary: changeSummary
        )
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

    func refreshServerLogs(limit: Int = 100, reverse: Bool = true, instance: Bool = false, beginPosition: Int = 0) {
        runClientCommand { client in
            let entries = try await client.serverLogEntries(
                limit: limit,
                reverse: reverse,
                instance: instance,
                beginPosition: beginPosition
            )
            await MainActor.run {
                self.serverLogEntries = entries.map { TS3ServerLogSummary(entry: $0) }
                self.saveServerLogResults()
            }
        }
    }

    func showServerLogs() {
        refreshServerLogs()
        isShowingServerLogs = true
    }

    func showServerInformation() {
        refreshServerInfo()
        refreshGroups()
        isShowingServerInfo = true
    }

    func showServerSettings() {
        refreshServerInfo()
        isShowingServerEditor = true
    }

    func showTemporaryServerPasswords() {
        refreshTemporaryServerPasswords()
        isShowingTemporaryPasswords = true
    }

    func showGroupManagement() {
        refreshGroups()
        isShowingGroupManagement = true
    }

    func showChat() {
        isShowingChat = true
    }

    func showOfflineMessages() {
        if state == .connected {
            refreshOfflineMessages()
        }
        isShowingOfflineMessages = true
    }

    func showEvents() {
        markEventsRead()
        isShowingEvents = true
    }

    func showWhisper() {
        isShowingWhisper = true
    }

    func showContacts() {
        isShowingContacts = true
    }

    func showClientDatabase() {
        refreshClientDatabase()
        isShowingClientDatabase = true
    }

    func showBanList() {
        refreshBanList()
        isShowingBans = true
    }

    func showFileBrowser() {
        openFileBrowser()
        isShowingFiles = true
    }

    func showPermissions() {
        refreshPermissionList()
        refreshOwnClientPermissions()
        isShowingPermissions = true
    }

    func showPrivilegeKeys() {
        refreshPrivilegeKeys()
        isShowingPrivilegeKeys = true
    }

    func showComplaints() {
        if let user = clients.first(where: { !$0.isCurrentUser }) {
            refreshComplaints(for: user)
        }
        isShowingComplaints = true
    }

    func showComplaints(for user: TS3UserSummary) {
        refreshComplaints(for: user)
        isShowingComplaints = true
    }

    func showContacts(for user: TS3UserSummary) {
        guard user.uniqueIdentifier != nil else {
            lastError = "The server did not provide a unique id for \(user.nickname)."
            return
        }
        isShowingContacts = true
    }

    func addServerLogEntry(
        level: TS3LogLevel,
        message: String,
        limit: Int = 100,
        reverse: Bool = true,
        instance: Bool = false,
        beginPosition: Int = 0
    ) {
        runClientCommand { client in
            try await client.addServerLogEntry(level: level, message: message)
            let entries = try await client.serverLogEntries(
                limit: limit,
                reverse: reverse,
                instance: instance,
                beginPosition: beginPosition
            )
            await MainActor.run {
                self.serverLogEntries = entries.map { TS3ServerLogSummary(entry: $0) }
                self.saveServerLogResults()
            }
        }
    }

    func clearServerLogResults() {
        serverLogEntries = []
        saveServerLogResults()
    }

    func clearServerLogResults(_ entries: [TS3ServerLogSummary]) {
        let ids = Set(entries.map(\.id))
        guard !ids.isEmpty else { return }
        serverLogEntries.removeAll { ids.contains($0.id) }
        saveServerLogResults()
    }

    func serverLogArchiveData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(TS3ServerLogArchive(entries: sanitizedServerLogArchiveEntries(serverLogEntries).entries))
    }

    func serverLogArchivePreview(from data: Data) throws -> TS3ServerLogArchivePreview {
        let decoded = try JSONDecoder().decode(TS3ServerLogArchive.self, from: data)
        let sanitized = sanitizedServerLogArchiveEntries(decoded.entries)
        let entries = sanitized.entries
        let first = entries.first
        return TS3ServerLogArchivePreview(
            entryCount: entries.count,
            skippedEntryCount: sanitized.skippedCount,
            levelCount: entries.filter { $0.level?.isEmpty == false }.count,
            channelCount: entries.filter { $0.channel?.isEmpty == false }.count,
            timestampCount: entries.filter { $0.timestamp != nil }.count,
            entrySummaries: entries.prefix(10).map(\.archiveSummary),
            firstLevel: first?.level,
            firstChannel: first?.channel,
            firstMessage: first?.message,
            firstTimestamp: first?.timestamp
        )
    }

    func importServerLogArchive(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3ServerLogArchive.self, from: data)
        serverLogEntries = Array(sanitizedServerLogArchiveEntries(decoded.entries).entries.prefix(500))
        saveServerLogResults()
        lastError = nil
    }

    func saveServerLogQueryPreset(
        name: String,
        limit: Int,
        beginPosition: Int,
        reverse: Bool,
        instance: Bool,
        levelFilter: String,
        channelFilter: String,
        searchText: String
    ) {
        let preset = sanitizedServerLogQueryPreset(TS3ServerLogQueryPreset(
            name: name,
            limit: limit,
            beginPosition: beginPosition,
            reverse: reverse,
            instance: instance,
            levelFilter: levelFilter,
            channelFilter: channelFilter,
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

    func refreshOnlineLocations(for record: TS3DatabaseClientSummary) {
        guard let uniqueIdentifier = record.uniqueIdentifier else {
            lastError = "Selected database client has no unique id."
            return
        }
        runClientCommand { client in
            let locations = try await client.onlineClientIds(forUniqueIdentifier: uniqueIdentifier)
            await MainActor.run {
                self.selectedDatabaseClient = record
                self.clientLocations = locations.map { TS3ClientLocationSummary(location: $0) }
                if locations.isEmpty {
                    self.lastError = "\(record.nickname) is not online."
                } else {
                    self.lastError = nil
                }
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

    func databaseClientBackupPreview(from data: Data) throws -> TS3DatabaseClientBackupPreview {
        let decoded = try JSONDecoder().decode(TS3DatabaseClientBackup.self, from: data)
        let sanitized = sanitizedDatabaseClientBackupEntries(decoded.entries)
        let clients = sanitized.clients
        let first = clients.first
        return TS3DatabaseClientBackupPreview(
            clientCount: clients.count,
            skippedClientCount: sanitized.skippedCount,
            uniqueIdentifierCount: clients.filter { $0.uniqueIdentifier?.isEmpty == false }.count,
            descriptionCount: clients.filter { $0.description?.isEmpty == false }.count,
            lastIPCount: clients.filter { $0.lastIP?.isEmpty == false }.count,
            connectionCount: clients.filter { $0.totalConnections != nil }.count,
            clientSummaries: clients.prefix(10).map(\.backupSummary),
            firstNickname: first?.nickname,
            firstUniqueIdentifier: first?.uniqueIdentifier,
            firstDatabaseId: first?.id
        )
    }

    func importDatabaseClientBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3DatabaseClientBackup.self, from: data)
        databaseClients = sanitizedDatabaseClientBackupEntries(decoded.entries).clients
        lastError = nil
    }

    func sendOfflineMessage(to record: TS3DatabaseClientSummary, subject: String, message: String, onSent: (() -> Void)? = nil) {
        let validationMessages = TS3OfflineMessageDraftValidator.validationMessages(
            recipientName: record.nickname,
            recipientUniqueIdentifier: record.uniqueIdentifier,
            subject: subject,
            message: message
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let uniqueIdentifier = record.uniqueIdentifier else {
            lastError = "Selected database client has no unique id."
            return
        }
        runClientCommand { client in
            try await client.sendOfflineMessage(toUniqueIdentifier: uniqueIdentifier, subject: subject, message: message)
            await MainActor.run {
                onSent?()
            }
        }
    }

    func complainAboutDatabaseClient(_ record: TS3DatabaseClientSummary, message: String) {
        let validationMessages = TS3ComplaintDraftValidator.validationMessages(
            targetName: record.nickname,
            targetClientId: nil,
            targetDatabaseId: record.id,
            message: message
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            try await client.addComplaint(clientDatabaseId: record.id, message: message)
            let entries = try await client.refreshComplaints(clientDatabaseId: record.id)
            await MainActor.run {
                self.complaintTarget = record.userSummary
                self.complaintEntries = self.complaintSummaries(from: entries)
            }
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
                self.saveBanResults()
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
        phoneticName: String,
        port: Int?,
        machineId: String,
        isAutoStartEnabled: Bool?,
        welcomeMessage: String,
        maxClients: Int?,
        reservedSlots: Int?,
        password: String?,
        hostMessage: String,
        hostMessageMode: Int?,
        hostBannerURL: String,
        hostBannerGraphicsURL: String,
        hostBannerMode: Int?,
        hostBannerGraphicsInterval: Int?,
        hostButtonTooltip: String,
        hostButtonURL: String,
        hostButtonGraphicsURL: String,
        iconId: Int?,
        downloadQuota: Int64?,
        uploadQuota: Int64?,
        maxDownloadTotalBandwidth: Int64?,
        maxUploadTotalBandwidth: Int64?,
        complainAutoBanCount: Int?,
        complainAutoBanTime: Int?,
        complainRemoveTime: Int?,
        minClientsInChannelBeforeForcedSilence: Int?,
        prioritySpeakerDimmModificator: Double?,
        antiFloodPointsTickReduce: Int?,
        antiFloodPointsNeededCommandBlock: Int?,
        antiFloodPointsNeededIPBlock: Int?,
        antiFloodPointsNeededPluginBlock: Int?,
        isClientLoggingEnabled: Bool?,
        isQueryLoggingEnabled: Bool?,
        isChannelLoggingEnabled: Bool?,
        isPermissionLoggingEnabled: Bool?,
        isServerLoggingEnabled: Bool?,
        isFileTransferLoggingEnabled: Bool?,
        isWeblistEnabled: Bool?,
        codecEncryptionMode: Int?,
        defaultServerGroupId: Int?,
        defaultChannelGroupId: Int?,
        defaultChannelAdminGroupId: Int?,
        neededIdentitySecurityLevel: Int?,
        minClientVersion: Int?,
        minAndroidVersion: Int?,
        minIOSVersion: Int?
    ) {
        let edit = TS3ServerEdit(
            name: trimmedValue(name),
            phoneticName: trimmedValue(phoneticName),
            port: port,
            machineId: trimmedValue(machineId),
            isAutoStartEnabled: isAutoStartEnabled,
            welcomeMessage: welcomeMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            maxClients: maxClients,
            reservedSlots: reservedSlots,
            password: password,
            hostMessage: hostMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            hostMessageMode: hostMessageMode,
            hostBannerURL: hostBannerURL.trimmingCharacters(in: .whitespacesAndNewlines),
            hostBannerGraphicsURL: hostBannerGraphicsURL.trimmingCharacters(in: .whitespacesAndNewlines),
            hostBannerMode: hostBannerMode,
            hostBannerGraphicsInterval: hostBannerGraphicsInterval,
            hostButtonTooltip: hostButtonTooltip.trimmingCharacters(in: .whitespacesAndNewlines),
            hostButtonURL: hostButtonURL.trimmingCharacters(in: .whitespacesAndNewlines),
            hostButtonGraphicsURL: hostButtonGraphicsURL.trimmingCharacters(in: .whitespacesAndNewlines),
            iconId: iconId,
            downloadQuota: downloadQuota,
            uploadQuota: uploadQuota,
            maxDownloadTotalBandwidth: maxDownloadTotalBandwidth,
            maxUploadTotalBandwidth: maxUploadTotalBandwidth,
            complainAutoBanCount: complainAutoBanCount,
            complainAutoBanTime: complainAutoBanTime,
            complainRemoveTime: complainRemoveTime,
            minClientsInChannelBeforeForcedSilence: minClientsInChannelBeforeForcedSilence,
            prioritySpeakerDimmModificator: prioritySpeakerDimmModificator,
            antiFloodPointsTickReduce: antiFloodPointsTickReduce,
            antiFloodPointsNeededCommandBlock: antiFloodPointsNeededCommandBlock,
            antiFloodPointsNeededIPBlock: antiFloodPointsNeededIPBlock,
            antiFloodPointsNeededPluginBlock: antiFloodPointsNeededPluginBlock,
            isClientLoggingEnabled: isClientLoggingEnabled,
            isQueryLoggingEnabled: isQueryLoggingEnabled,
            isChannelLoggingEnabled: isChannelLoggingEnabled,
            isPermissionLoggingEnabled: isPermissionLoggingEnabled,
            isServerLoggingEnabled: isServerLoggingEnabled,
            isFileTransferLoggingEnabled: isFileTransferLoggingEnabled,
            isWeblistEnabled: isWeblistEnabled,
            codecEncryptionMode: codecEncryptionMode,
            defaultServerGroupId: defaultServerGroupId,
            defaultChannelGroupId: defaultChannelGroupId,
            defaultChannelAdminGroupId: defaultChannelAdminGroupId,
            neededIdentitySecurityLevel: neededIdentitySecurityLevel,
            minClientVersion: minClientVersion,
            minAndroidVersion: minAndroidVersion,
            minIOSVersion: minIOSVersion
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
                self.saveBanResults()
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

    func moveFileEntry(_ entry: TS3FileEntrySummary, toDirectory directoryPath: String) {
        let directoryPath = normalizedFileDirectoryPath(directoryPath)
        let newPath = joinedFilePath(parentPath: directoryPath, name: entry.name)
        guard newPath != entry.path else { return }
        if isMovingDirectoryIntoItself(entry, destinationDirectory: directoryPath) {
            lastError = "Cannot move a directory into itself."
            return
        }
        let password = trimmedFileBrowserPassword
        runClientCommand { client in
            try await client.renameFile(channelId: entry.channelId, oldPath: entry.path, newPath: newPath, password: password)
        } onSuccess: {
            self.refreshFileList()
        }
    }

    func moveFileEntries(_ entries: [TS3FileEntrySummary], toDirectory directoryPath: String) {
        let directoryPath = normalizedFileDirectoryPath(directoryPath)
        let moves = entries.compactMap { entry -> (entry: TS3FileEntrySummary, newPath: String)? in
            let newPath = joinedFilePath(parentPath: directoryPath, name: entry.name)
            return newPath == entry.path ? nil : (entry, newPath)
        }
        guard !moves.isEmpty else { return }
        if moves.contains(where: { isMovingDirectoryIntoItself($0.entry, destinationDirectory: directoryPath) }) {
            lastError = "Cannot move a directory into itself."
            return
        }
        let password = trimmedFileBrowserPassword
        runClientCommand { client in
            for move in moves {
                try await client.renameFile(
                    channelId: move.entry.channelId,
                    oldPath: move.entry.path,
                    newPath: move.newPath,
                    password: password
                )
            }
            await MainActor.run {
                self.refreshFileList()
            }
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
                    self.recordDownloadedFile(name: destination.lastPathComponent, url: destination)
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
        openDownloadedFile(file)
    }

    func openDownloadedFile(_ file: TS3DownloadedFileSummary) {
        TS3PlatformSupport.openURL(file.url)
    }

    func openDownloadsDirectory() {
        do {
            TS3PlatformSupport.openURL(try ensureDownloadsDirectory())
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearDownloadedFileHistory() {
        downloadedFiles = []
        lastDownloadedFile = nil
        saveDownloadedFiles()
    }

    func removeDownloadedFileHistory(_ file: TS3DownloadedFileSummary) {
        downloadedFiles.removeAll { $0.id == file.id }
        if lastDownloadedFile?.id == file.id {
            lastDownloadedFile = downloadedFiles.first
        }
        saveDownloadedFiles()
    }

    func pruneMissingDownloadedFiles() {
        downloadedFiles.removeAll { !FileManager.default.fileExists(atPath: $0.url.path) }
        lastDownloadedFile = downloadedFiles.first
        saveDownloadedFiles()
    }

    var downloadsDirectoryURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("TS3 Downloads", isDirectory: true)
    }

    var downloadedFilesExistingCount: Int {
        downloadedFiles.filter { FileManager.default.fileExists(atPath: $0.url.path) }.count
    }

    var downloadedFilesMissingCount: Int {
        downloadedFiles.count - downloadedFilesExistingCount
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

    private func isMovingDirectoryIntoItself(_ entry: TS3FileEntrySummary, destinationDirectory: String) -> Bool {
        guard entry.isDirectory else { return false }
        let sourceDirectory = normalizedFileDirectoryPath(entry.path)
        let destinationDirectory = normalizedFileDirectoryPath(destinationDirectory)
        return destinationDirectory == sourceDirectory || destinationDirectory.hasPrefix(sourceDirectory)
    }

    private var trimmedFileBrowserPassword: String? {
        let password = fileBrowserPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        return password.isEmpty ? nil : password
    }

    private func recordDownloadedFile(name: String, url: URL) {
        let record = TS3DownloadedFileSummary(name: name, url: url, downloadedAt: Date())
        lastDownloadedFile = record
        downloadedFiles.removeAll { $0.url == url }
        downloadedFiles.insert(record, at: 0)
        if downloadedFiles.count > 25 {
            downloadedFiles.removeLast(downloadedFiles.count - 25)
        }
        saveDownloadedFiles()
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
        let directory = try ensureDownloadsDirectory()
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

    private func ensureDownloadsDirectory() throws -> URL {
        let directory = downloadsDirectoryURL
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
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

    func joinChannel(
        _ channel: TS3ChannelSummary,
        password: String? = nil,
        rememberPassword: Bool = false
    ) {
        let resolvedPassword = resolvedChannelPassword(for: channel, password: password)
        if rememberPassword, let resolvedPassword {
            saveChannelPassword(resolvedPassword, for: channel)
        }
        Task {
            do {
                try await client?.joinChannel(channelId: channel.id, password: resolvedPassword)
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
                self.offlineMessages = messages.map { message in
                    let existing = self.offlineMessages.first { $0.id == message.id }
                    return TS3OfflineMessageSummary(
                        message: message,
                        messageOverride: existing?.message,
                        isReadOverride: nil
                    )
                }
                self.saveOfflineMessageHistory()
            }
        }
    }

    func openOfflineMessage(_ message: TS3OfflineMessageSummary) {
        runClientCommand { client in
            guard let detailed = try await client.offlineMessage(messageId: message.id) else { return }
            try? await client.setOfflineMessageRead(messageId: message.id, isRead: true)
            await MainActor.run {
                self.upsertOfflineMessage(TS3OfflineMessageSummary(message: detailed, isReadOverride: true))
                self.saveOfflineMessageHistory()
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
                self.saveOfflineMessageHistory()
            }
        }
    }

    func deleteOfflineMessage(_ message: TS3OfflineMessageSummary) {
        runClientCommand { client in
            try await client.deleteOfflineMessage(messageId: message.id)
            await MainActor.run {
                self.offlineMessages.removeAll { $0.id == message.id }
                self.saveOfflineMessageHistory()
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
                self.offlineMessages = refreshedMessages.map { message in
                    TS3OfflineMessageSummary(
                        message: message,
                        messageOverride: self.offlineMessages.first { $0.id == message.id }?.message,
                        isReadOverride: nil
                    )
                }
                self.saveOfflineMessageHistory()
            }
        }
    }

    func markOfflineMessage(_ message: TS3OfflineMessageSummary, read: Bool) {
        runClientCommand { client in
            try await client.setOfflineMessageRead(messageId: message.id, isRead: read)
            await MainActor.run {
                self.upsertOfflineMessage(TS3OfflineMessageSummary(copying: message, isRead: read))
                self.saveOfflineMessageHistory()
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
                self.offlineMessages = refreshedMessages.map { message in
                    TS3OfflineMessageSummary(
                        message: message,
                        messageOverride: self.offlineMessages.first { $0.id == message.id }?.message,
                        isReadOverride: nil
                    )
                }
                self.saveOfflineMessageHistory()
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
                self.offlineMessages = refreshedMessages.map { message in
                    TS3OfflineMessageSummary(
                        message: message,
                        messageOverride: self.offlineMessages.first { $0.id == message.id }?.message,
                        isReadOverride: nil
                    )
                }
                self.saveOfflineMessageHistory()
            }
        }
    }

    func sendOfflineMessage(to user: TS3UserSummary, subject: String, message: String, onSent: (() -> Void)? = nil) {
        let validationMessages = TS3OfflineMessageDraftValidator.validationMessages(
            recipientName: user.nickname,
            recipientUniqueIdentifier: user.uniqueIdentifier,
            subject: subject,
            message: message,
            allowsRecipientLookup: true
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            let details = try await client.refreshClientDetails(clientId: user.id)
            guard let uniqueIdentifier = details?.uniqueIdentifier ?? user.uniqueIdentifier else {
                throw TS3Error.serverError(message: "The server did not provide a unique id for \(user.nickname).")
            }
            try await client.sendOfflineMessage(toUniqueIdentifier: uniqueIdentifier, subject: subject, message: message)
            await MainActor.run {
                onSent?()
            }
        }
    }

    func sendOfflineMessage(toUniqueIdentifier uniqueIdentifier: String, subject: String, message: String, onSent: (() -> Void)? = nil) {
        let validationMessages = TS3OfflineMessageDraftValidator.validationMessages(
            recipientName: nil,
            recipientUniqueIdentifier: uniqueIdentifier,
            subject: subject,
            message: message
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let uniqueIdentifier = uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            try await client.sendOfflineMessage(toUniqueIdentifier: uniqueIdentifier, subject: subject, message: message)
            await MainActor.run {
                onSent?()
            }
        }
    }

    func offlineMessageDraft(for key: String) -> TS3OfflineMessageDraft? {
        offlineMessageDrafts.first { $0.id == key }
    }

    func saveOfflineMessageDraft(id: String, recipientName: String, subject: String, message: String) {
        let id = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        let recipientName = recipientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        if subject.isEmpty && message.isEmpty {
            clearOfflineMessageDraft(id: id)
            return
        }
        let draft = TS3OfflineMessageDraft(
            id: id,
            recipientName: recipientName.isEmpty ? id : recipientName,
            subject: subject,
            message: message,
            updatedAt: Date()
        )
        if let index = offlineMessageDrafts.firstIndex(where: { $0.id == id }) {
            offlineMessageDrafts[index] = draft
        } else {
            offlineMessageDrafts.insert(draft, at: 0)
        }
        saveOfflineMessageDrafts()
    }

    func clearOfflineMessageDraft(id: String) {
        offlineMessageDrafts.removeAll { $0.id == id }
        saveOfflineMessageDrafts()
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

    func updatePhoneticNickname(to value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            try await client.updatePhoneticNickname(trimmed.isEmpty ? nil : trimmed)
        } onSuccess: {
            self.phoneticNickname = trimmed
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
                self.resetInputMeter()
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
        neededJoinPower: Int?,
        neededSubscribePower: Int?,
        neededDescriptionViewPower: Int?,
        order: Int?,
        codec: Int?,
        codecQuality: Int?,
        codecLatencyFactor: Int?,
        isCodecUnencrypted: Bool?,
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
                codecLatencyFactor: codecLatencyFactor,
                isCodecUnencrypted: isCodecUnencrypted,
                neededTalkPower: neededTalkPower,
                neededJoinPower: neededJoinPower,
                neededSubscribePower: neededSubscribePower,
                neededDescriptionViewPower: neededDescriptionViewPower,
                order: order,
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
        neededJoinPower: Int?,
        neededSubscribePower: Int?,
        neededDescriptionViewPower: Int?,
        order: Int?,
        codec: Int?,
        codecQuality: Int?,
        codecLatencyFactor: Int?,
        isCodecUnencrypted: Bool?,
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
                neededJoinPower: neededJoinPower,
                neededSubscribePower: neededSubscribePower,
                neededDescriptionViewPower: neededDescriptionViewPower,
                codec: codec,
                codecQuality: codecQuality,
                codecLatencyFactor: codecLatencyFactor,
                isCodecUnencrypted: isCodecUnencrypted,
                order: order,
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
        } onSuccess: {
            self.refreshServerView()
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

    func deleteAllChannelSubscriptionPresets() {
        guard !channelSubscriptionPresets.isEmpty else { return }
        channelSubscriptionPresets = []
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

    func deleteAllChannelTreeFilterPresets() {
        guard !channelTreeFilterPresets.isEmpty else { return }
        channelTreeFilterPresets = []
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

    func isChannelCollapsed(_ channelId: Int) -> Bool {
        collapsedChannelIds.contains(channelId)
    }

    func setChannelCollapsed(_ channelId: Int, isCollapsed: Bool) {
        guard channelId > 0 else { return }
        if isCollapsed {
            collapsedChannelIds.insert(channelId)
        } else {
            collapsedChannelIds.remove(channelId)
        }
        saveCollapsedChannelIds()
    }

    func collapseChannels(_ channels: [TS3ChannelSummary]) {
        let ids = Set(channels.map(\.id).filter { $0 > 0 })
        guard !ids.isEmpty else { return }
        collapsedChannelIds.formUnion(ids)
        saveCollapsedChannelIds()
    }

    func expandChannels(_ channels: [TS3ChannelSummary]) {
        let ids = Set(channels.map(\.id).filter { $0 > 0 })
        guard !ids.isEmpty else { return }
        collapsedChannelIds.subtract(ids)
        saveCollapsedChannelIds()
    }

    func resetCollapsedChannels() {
        guard !collapsedChannelIds.isEmpty else { return }
        collapsedChannelIds = []
        saveCollapsedChannelIds()
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

    func deleteAllEventFilterPresets() {
        guard !eventFilterPresets.isEmpty else { return }
        eventFilterPresets = []
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

    func eventHistoryArchiveData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(TS3EventHistoryArchive(
            activityEvents: Array(activityEvents.prefix(100)),
            pokeEvents: Array(pokeEvents.prefix(50))
        ))
    }

    func eventHistoryArchivePreview(from data: Data) throws -> TS3EventHistoryArchivePreview {
        let archive = try JSONDecoder().decode(TS3EventHistoryArchive.self, from: data)
        return TS3EventHistoryArchivePreview(
            activityCount: archive.activityEvents.count,
            pokeCount: archive.pokeEvents.count,
            currentActivityCount: activityEvents.count,
            currentPokeCount: pokeEvents.count,
            activitySummaries: archive.activityEvents.prefix(10).map(\.clipboardSummary),
            pokeSummaries: archive.pokeEvents.prefix(10).map(\.clipboardSummary)
        )
    }

    func restoreEventHistoryArchive(from data: Data) throws {
        let archive = try JSONDecoder().decode(TS3EventHistoryArchive.self, from: data)
        activityEvents = Array(archive.activityEvents.prefix(100))
        pokeEvents = Array(archive.pokeEvents.prefix(50))
        unreadActivityCount = 0
        unreadPokeCount = 0
        saveEventHistory()
        lastError = nil
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

    func deleteAllChatFilterPresets() {
        guard !chatFilterPresets.isEmpty else { return }
        chatFilterPresets = []
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

    func deleteAllFileBrowserBookmarks() {
        guard !fileBrowserBookmarks.isEmpty else { return }
        fileBrowserBookmarks = []
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

    func deleteAllFileBrowserFilterPresets() {
        guard !fileBrowserFilterPresets.isEmpty else { return }
        fileBrowserFilterPresets = []
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

    func deleteAllOfflineMessageFilterPresets() {
        guard !offlineMessageFilterPresets.isEmpty else { return }
        offlineMessageFilterPresets = []
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

    func deleteAllBanFilterPresets() {
        guard !banFilterPresets.isEmpty else { return }
        banFilterPresets = []
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

    func offlineMessageArchiveData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(TS3OfflineMessageArchive(messages: sanitizedOfflineMessageArchiveMessages(offlineMessages).messages))
    }

    func offlineMessageArchivePreview(from data: Data) throws -> TS3OfflineMessageArchivePreview {
        let decoded = try JSONDecoder().decode(TS3OfflineMessageArchive.self, from: data)
        let sanitized = sanitizedOfflineMessageArchiveMessages(decoded.messages)
        let messages = sanitized.messages
        let first = messages.first
        return TS3OfflineMessageArchivePreview(
            messageCount: messages.count,
            skippedMessageCount: sanitized.skippedCount,
            unreadCount: messages.filter { !$0.isRead }.count,
            withBodyCount: messages.filter { $0.message?.isEmpty == false }.count,
            replyableCount: messages.filter { $0.senderUniqueIdentifier?.isEmpty == false }.count,
            unknownSenderCount: messages.filter { $0.senderName?.isEmpty != false && $0.senderUniqueIdentifier?.isEmpty != false }.count,
            messageSummaries: messages.prefix(10).map(Self.offlineMessageArchiveSummary),
            firstSenderName: first?.senderName,
            firstSenderUniqueIdentifier: first?.senderUniqueIdentifier,
            firstSubject: first?.subject,
            firstTimestamp: first?.timestamp
        )
    }

    func importOfflineMessageArchive(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3OfflineMessageArchive.self, from: data)
        offlineMessages = Array(sanitizedOfflineMessageArchiveMessages(decoded.messages).messages.prefix(500))
        saveOfflineMessageHistory()
        lastError = nil
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

    func deleteAllComplaintFilterPresets() {
        guard !complaintFilterPresets.isEmpty else { return }
        complaintFilterPresets = []
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

    func complaintArchiveData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(TS3ComplaintArchive(entries: sanitizedComplaintArchiveEntries(complaintEntries).entries))
    }

    func complaintArchivePreview(from data: Data) throws -> TS3ComplaintArchivePreview {
        let decoded = try JSONDecoder().decode(TS3ComplaintArchive.self, from: data)
        let sanitized = sanitizedComplaintArchiveEntries(decoded.entries)
        let entries = sanitized.entries
        let first = entries.first
        return TS3ComplaintArchivePreview(
            complaintCount: entries.count,
            skippedComplaintCount: sanitized.skippedCount,
            targetCount: Set(entries.map(\.targetClientDatabaseId)).count,
            namedSourceCount: entries.filter { $0.sourceName?.isEmpty == false }.count,
            anonymousSourceCount: entries.filter { $0.sourceName?.isEmpty != false }.count,
            messageCount: entries.filter { $0.message?.isEmpty == false }.count,
            complaintSummaries: entries.prefix(10).map(\.clipboardSummary),
            firstTargetName: first?.targetName,
            firstTargetDatabaseId: first?.targetClientDatabaseId,
            firstSourceName: first?.sourceName,
            firstSourceDatabaseId: first?.sourceClientDatabaseId,
            firstMessage: first?.message,
            firstTimestamp: first?.timestamp
        )
    }

    func importComplaintArchive(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3ComplaintArchive.self, from: data)
        let entries = sanitizedComplaintArchiveEntries(decoded.entries).entries
        complaintEntries = Array(entries.prefix(500))
        saveComplaintResults()
        lastError = nil
    }

    func saveTemporaryServerPasswordFilterPreset(
        name: String,
        passwordFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedTemporaryServerPasswordFilterPreset(TS3TemporaryServerPasswordFilterPreset(
            name: name,
            passwordFilter: passwordFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText
        ))
        guard let preset else {
            lastError = "Enter a name for the temporary password filter preset."
            return
        }
        temporaryServerPasswordFilterPresets.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
        temporaryServerPasswordFilterPresets.insert(preset, at: 0)
        temporaryServerPasswordFilterPresets = sanitizedTemporaryServerPasswordFilterPresets(temporaryServerPasswordFilterPresets)
        saveTemporaryServerPasswordFilterPresets()
        lastError = nil
    }

    func deleteTemporaryServerPasswordFilterPreset(_ preset: TS3TemporaryServerPasswordFilterPreset) {
        temporaryServerPasswordFilterPresets.removeAll { $0.id == preset.id }
        saveTemporaryServerPasswordFilterPresets()
    }

    func deleteAllTemporaryServerPasswordFilterPresets() {
        guard !temporaryServerPasswordFilterPresets.isEmpty else { return }
        temporaryServerPasswordFilterPresets = []
        saveTemporaryServerPasswordFilterPresets()
    }

    func temporaryServerPasswordFilterPresetsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(temporaryServerPasswordFilterPresets)
    }

    @discardableResult
    func importTemporaryServerPasswordFilterPresets(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3TemporaryServerPasswordFilterPreset].self, from: data)
        var merged = temporaryServerPasswordFilterPresets
        for preset in sanitizedTemporaryServerPasswordFilterPresets(imported) {
            merged.removeAll { $0.name.caseInsensitiveCompare(preset.name) == .orderedSame }
            merged.insert(preset, at: 0)
        }
        temporaryServerPasswordFilterPresets = sanitizedTemporaryServerPasswordFilterPresets(merged)
        saveTemporaryServerPasswordFilterPresets()
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

    func deleteAllDatabaseClientFilterPresets() {
        guard !databaseClientFilterPresets.isEmpty else { return }
        databaseClientFilterPresets = []
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

    func deleteAllPrivilegeKeyFilterPresets() {
        guard !privilegeKeyFilterPresets.isEmpty else { return }
        privilegeKeyFilterPresets = []
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

    func deleteAllPermissionFilterPresets() {
        guard !permissionFilterPresets.isEmpty else { return }
        permissionFilterPresets = []
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

    func deleteAllGroupFilterPresets() {
        guard !groupFilterPresets.isEmpty else { return }
        groupFilterPresets = []
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
        channelFilter: String,
        channelId: Int?,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) {
        let preset = sanitizedGroupClientFilterPreset(TS3GroupClientFilterPreset(
            name: name,
            memberFilter: memberFilter,
            channelFilter: channelFilter,
            channelId: channelId,
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

    func deleteAllGroupClientFilterPresets() {
        guard !groupClientFilterPresets.isEmpty else { return }
        groupClientFilterPresets = []
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

    func groupArchiveData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let sanitized = sanitizedGroupArchive(serverGroups: serverGroups, channelGroups: channelGroups)
        return try encoder.encode(TS3GroupArchive(
            serverGroups: sanitized.serverGroups,
            channelGroups: sanitized.channelGroups
        ))
    }

    func groupArchivePreview(from data: Data) throws -> TS3GroupArchivePreview {
        let decoded = try JSONDecoder().decode(TS3GroupArchive.self, from: data)
        let sanitized = sanitizedGroupArchive(serverGroups: decoded.serverGroups, channelGroups: decoded.channelGroups)
        let allGroups = sanitized.serverGroups + sanitized.channelGroups
        return TS3GroupArchivePreview(
            serverGroupCount: sanitized.serverGroups.count,
            channelGroupCount: sanitized.channelGroups.count,
            skippedServerGroupCount: sanitized.skippedServerGroupCount,
            skippedChannelGroupCount: sanitized.skippedChannelGroupCount,
            templateCount: allGroups.filter { $0.type == .template }.count,
            regularCount: allGroups.filter { $0.type == .regular }.count,
            queryCount: allGroups.filter { $0.type == .query }.count,
            unknownTypeCount: allGroups.filter { $0.type == nil }.count,
            serverGroupSummaries: sanitized.serverGroups.prefix(10).map {
                $0.clipboardSummary(target: .server)
            },
            channelGroupSummaries: sanitized.channelGroups.prefix(10).map {
                $0.clipboardSummary(target: .channel)
            },
            firstServerGroupName: sanitized.serverGroups.first?.name,
            firstChannelGroupName: sanitized.channelGroups.first?.name
        )
    }

    func importGroupArchive(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3GroupArchive.self, from: data)
        let sanitized = sanitizedGroupArchive(serverGroups: decoded.serverGroups, channelGroups: decoded.channelGroups)
        serverGroups = Array(sanitized.serverGroups.prefix(500))
        channelGroups = Array(sanitized.channelGroups.prefix(500))
        saveGroupResults()
        lastError = nil
    }

    func moveUser(
        _ user: TS3UserSummary,
        to channel: TS3ChannelSummary,
        password: String? = nil,
        rememberPassword: Bool = false
    ) {
        let resolvedPassword = resolvedChannelPassword(for: channel, password: password)
        if rememberPassword, let resolvedPassword {
            saveChannelPassword(resolvedPassword, for: channel)
        }
        runClientCommand { client in
            try await client.moveClient(clientId: user.id, to: channel.id, password: resolvedPassword)
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
                self.saveBanResults()
            }
        }
    }

    func addBan(
        ip: String,
        name: String,
        uniqueIdentifier: String,
        myTeamSpeakId: String,
        lastNickname: String,
        durationSeconds: Int?,
        reason: String,
        isCustomDuration: Bool = false
    ) {
        let validationMessages = TS3BanDraftValidator.validationMessages(
            ip: ip,
            name: name,
            uniqueIdentifier: uniqueIdentifier,
            myTeamSpeakId: myTeamSpeakId,
            lastNickname: lastNickname,
            durationSeconds: durationSeconds,
            isCustomDuration: isCustomDuration,
            reason: reason
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let ip = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let uniqueIdentifier = uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let myTeamSpeakId = myTeamSpeakId.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastNickname = lastNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            try await client.addBan(
                ip: ip.isEmpty ? nil : ip,
                name: name.isEmpty ? nil : name,
                uniqueIdentifier: uniqueIdentifier.isEmpty ? nil : uniqueIdentifier,
                myTeamSpeakId: myTeamSpeakId.isEmpty ? nil : myTeamSpeakId,
                lastNickname: lastNickname.isEmpty ? nil : lastNickname,
                durationSeconds: durationSeconds,
                reason: reason.isEmpty ? nil : reason
            )
            let entries = try await client.refreshBanList()
            await MainActor.run {
                self.banEntries = self.banEntrySummaries(from: entries)
                self.saveBanResults()
            }
        }
    }

    func deleteBan(_ entry: TS3BanEntrySummary) {
        runClientCommand { client in
            try await client.deleteBan(banId: entry.id)
            await MainActor.run {
                self.banEntries.removeAll { $0.id == entry.id }
                self.saveBanResults()
            }
        }
    }

    func deleteAllBans() {
        runClientCommand { client in
            try await client.deleteAllBans()
            await MainActor.run {
                self.banEntries = []
                self.saveBanResults()
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
                self.saveBanResults()
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
        let validationMessages = TS3ComplaintDraftValidator.validationMessages(
            targetName: user.nickname,
            targetClientId: user.id,
            targetDatabaseId: user.databaseId,
            message: message
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        runClientCommand { client in
            let databaseId = try await self.databaseId(for: user, using: client)
            try await client.addComplaint(clientDatabaseId: databaseId, message: message)
            let entries = try await client.refreshComplaints(clientDatabaseId: databaseId)
            await MainActor.run {
                self.complaintTarget = user
                self.complaintEntries = self.complaintSummaries(from: entries)
                self.saveComplaintResults()
            }
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
                self.saveComplaintResults()
            }
        }
    }

    func banBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let rawEntries = banEntries.map {
            TS3BanBackupEntry(
                ip: $0.ip,
                name: $0.name,
                uniqueIdentifier: $0.uniqueIdentifier,
                lastNickname: $0.lastNickname,
                durationSeconds: $0.durationSeconds,
                reason: $0.reason
            )
        }
        let snapshot = TS3BanBackup(entries: sanitizedBanBackupEntries(rawEntries).entries)
        return try encoder.encode(snapshot)
    }

    func importBanBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3BanBackup.self, from: data)
        for entry in sanitizedBanBackupEntries(decoded.entries).entries {
            addBan(
                ip: entry.ip ?? "",
                name: entry.name ?? "",
                uniqueIdentifier: entry.uniqueIdentifier ?? "",
                myTeamSpeakId: "",
                lastNickname: entry.lastNickname ?? "",
                durationSeconds: entry.durationSeconds,
                reason: entry.reason ?? ""
            )
        }
        lastError = nil
    }

    func banBackupPreview(from data: Data) throws -> TS3BanBackupPreview {
        let decoded = try JSONDecoder().decode(TS3BanBackup.self, from: data)
        let sanitized = sanitizedBanBackupEntries(decoded.entries)
        let entries = sanitized.entries
        let first = entries.first
        return TS3BanBackupPreview(
            ruleCount: entries.count,
            skippedRuleCount: sanitized.skippedCount,
            ipRuleCount: entries.filter { $0.ip?.isEmpty == false }.count,
            nameRuleCount: entries.filter { $0.name?.isEmpty == false }.count,
            uniqueIdentifierRuleCount: entries.filter { $0.uniqueIdentifier?.isEmpty == false }.count,
            lastNicknameRuleCount: entries.filter { $0.lastNickname?.isEmpty == false }.count,
            ruleSummaries: entries.prefix(10).map(Self.banBackupRuleSummary),
            firstIP: first?.ip,
            firstName: first?.name,
            firstUniqueIdentifier: first?.uniqueIdentifier,
            firstLastNickname: first?.lastNickname,
            firstDurationSeconds: first?.durationSeconds,
            firstReason: first?.reason
        )
    }

    private func sanitizedBanBackupEntries(
        _ entries: [TS3BanBackupEntry]
    ) -> (entries: [TS3BanBackupEntry], skippedCount: Int) {
        var skippedCount = 0
        var seen: Set<String> = []
        let sanitizedEntries = entries.compactMap { entry -> TS3BanBackupEntry? in
            let ip = trimmedBackupValue(entry.ip)
            let name = trimmedBackupValue(entry.name)
            let uniqueIdentifier = trimmedBackupValue(entry.uniqueIdentifier)
            let lastNickname = trimmedBackupValue(entry.lastNickname)
            let reason = trimmedBackupValue(entry.reason)
            guard ip != nil || name != nil || uniqueIdentifier != nil || lastNickname != nil else {
                skippedCount += 1
                return nil
            }
            let duplicateKey = [
                ip ?? "",
                name ?? "",
                uniqueIdentifier ?? "",
                lastNickname ?? "",
                entry.durationSeconds.map(String.init) ?? "",
                reason ?? ""
            ].joined(separator: "\u{1F}")
            guard seen.insert(duplicateKey).inserted else {
                skippedCount += 1
                return nil
            }
            return TS3BanBackupEntry(
                ip: ip,
                name: name,
                uniqueIdentifier: uniqueIdentifier,
                lastNickname: lastNickname,
                durationSeconds: entry.durationSeconds,
                reason: reason
            )
        }
        return (sanitizedEntries, skippedCount)
    }

    private func trimmedBackupValue(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func banBackupRuleSummary(_ entry: TS3BanBackupEntry) -> String {
        var parts: [String] = []
        if let ip = entry.ip, !ip.isEmpty {
            parts.append("ip=\(ip)")
        }
        if let name = entry.name, !name.isEmpty {
            parts.append("name=\(name)")
        }
        if let uniqueIdentifier = entry.uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("uid=\(uniqueIdentifier)")
        }
        if let lastNickname = entry.lastNickname, !lastNickname.isEmpty {
            parts.append("lastNickname=\(lastNickname)")
        }
        if let durationSeconds = entry.durationSeconds {
            parts.append("duration=\(durationSeconds == 0 ? "permanent" : "\(durationSeconds)s")")
        }
        if let reason = entry.reason, !reason.isEmpty {
            parts.append("reason=\(reason)")
        }
        return parts.joined(separator: " | ")
    }

    func deleteComplaint(_ entry: TS3ComplaintSummary) {
        runClientCommand { client in
            try await client.deleteComplaint(
                targetClientDatabaseId: entry.targetClientDatabaseId,
                sourceClientDatabaseId: entry.sourceClientDatabaseId
            )
            await MainActor.run {
                self.complaintEntries.removeAll { $0.id == entry.id }
                self.saveComplaintResults()
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
                self.saveComplaintResults()
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
                    self.saveComplaintResults()
                }
            } else {
                await MainActor.run {
                    self.complaintEntries = []
                    self.saveComplaintResults()
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

    func refreshTemporaryServerPasswords() {
        runClientCommand { client in
            let passwords = try await client.refreshTemporaryServerPasswords()
            await MainActor.run {
                self.temporaryServerPasswords = self.temporaryServerPasswordSummaries(from: passwords)
                self.saveTemporaryServerPasswordResults()
            }
        }
    }

    func addTemporaryServerPassword(
        password: String,
        durationSeconds: Int?,
        description: String,
        targetChannelId: Int?,
        targetChannelPassword: String
    ) {
        let validationMessages = TS3TemporaryServerPasswordDraftValidator.validationMessages(
            password: password,
            durationSeconds: durationSeconds,
            description: description,
            targetChannelId: targetChannelId,
            targetChannelPassword: targetChannelPassword
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetChannelPassword = targetChannelPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let durationSeconds else { return }
        runClientCommand { client in
            try await client.addTemporaryServerPassword(
                password: password,
                durationSeconds: durationSeconds,
                description: description.isEmpty ? nil : description,
                targetChannelId: targetChannelId,
                targetChannelPassword: targetChannelPassword.isEmpty ? nil : targetChannelPassword
            )
            let passwords = try await client.refreshTemporaryServerPasswords()
            await MainActor.run {
                self.temporaryServerPasswords = self.temporaryServerPasswordSummaries(from: passwords)
                self.saveTemporaryServerPasswordResults()
            }
        }
    }

    func deleteTemporaryServerPassword(_ entry: TS3TemporaryServerPasswordSummary) {
        runClientCommand { client in
            try await client.deleteTemporaryServerPassword(entry.password)
            await MainActor.run {
                self.temporaryServerPasswords.removeAll { $0.id == entry.id }
                self.saveTemporaryServerPasswordResults()
            }
        }
    }

    func deleteTemporaryServerPasswords(_ entries: [TS3TemporaryServerPasswordSummary]) {
        let passwords = Array(Set(entries.map(\.password))).sorted()
        guard !passwords.isEmpty else { return }
        runClientCommand { client in
            for password in passwords {
                try await client.deleteTemporaryServerPassword(password)
            }
            let refreshedPasswords = try await client.refreshTemporaryServerPasswords()
            await MainActor.run {
                self.temporaryServerPasswords = self.temporaryServerPasswordSummaries(from: refreshedPasswords)
                self.saveTemporaryServerPasswordResults()
            }
        }
    }

    private func temporaryServerPasswordSummaries(from entries: [TS3TemporaryServerPassword]) -> [TS3TemporaryServerPasswordSummary] {
        entries
            .map { TS3TemporaryServerPasswordSummary(entry: $0) }
            .sorted {
                switch ($0.createdAt, $1.createdAt) {
                case let (lhs?, rhs?): return lhs > rhs
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return $0.password < $1.password
                }
            }
    }

    func pokeUser(_ user: TS3UserSummary, message: String) {
        let validationMessages = TS3PokeDraftValidator.validationMessages(
            targetName: user.nickname,
            targetClientId: user.id,
            message: message
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
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
                self.savePrivilegeKeyResults()
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
        let validationMessages = TS3PrivilegeKeyDraftValidator.validationMessages(
            targetType: targetType,
            groupId: groupId,
            channelId: channelId,
            description: description,
            customSet: customSet
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
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
                self.savePrivilegeKeyResults()
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
                self.savePrivilegeKeyResults()
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
                self.savePrivilegeKeyResults()
            }
        }
    }

    func privilegeKeyBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let rawEntries = privilegeKeys.map {
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
        let snapshot = TS3PrivilegeKeyBackup(entries: sanitizedPrivilegeKeyBackupEntries(rawEntries))
        return try encoder.encode(snapshot)
    }

    func privilegeKeyBackupPreview(from data: Data) throws -> TS3PrivilegeKeyBackupPreview {
        let decoded = try JSONDecoder().decode(TS3PrivilegeKeyBackup.self, from: data)
        let entries = sanitizedPrivilegeKeyBackupEntries(decoded.entries)
        let first = entries.first
        return TS3PrivilegeKeyBackupPreview(
            keyCount: entries.count,
            serverGroupCount: entries.filter { TS3PrivilegeKeyType(rawValue: $0.type ?? -1) == .serverGroup }.count,
            channelGroupCount: entries.filter { TS3PrivilegeKeyType(rawValue: $0.type ?? -1) == .channelGroup }.count,
            unknownTypeCount: entries.filter { $0.type.flatMap(TS3PrivilegeKeyType.init(rawValue:)) == nil }.count,
            keySummaries: entries.prefix(10).map(Self.privilegeKeyBackupSummary),
            firstKey: first?.key,
            firstType: first?.type.flatMap(TS3PrivilegeKeyType.init(rawValue:)),
            firstGroupId: first?.groupId,
            firstChannelId: first?.channelId,
            firstDescription: first?.description,
            firstCustomSet: first?.customSet
        )
    }

    func importPrivilegeKeyBackup(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3PrivilegeKeyBackup.self, from: data)
        generatedPrivilegeKey = sanitizedPrivilegeKeyBackupEntries(decoded.entries).first?.key
        lastError = nil
    }

    private func sanitizedPrivilegeKeyBackupEntries(
        _ entries: [TS3PrivilegeKeyBackupEntry]
    ) -> [TS3PrivilegeKeyBackupEntry] {
        var seen: Set<String> = []
        return entries.compactMap { entry in
            let key = entry.key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, seen.insert(key).inserted else { return nil }
            return TS3PrivilegeKeyBackupEntry(
                key: key,
                type: entry.type,
                groupId: entry.groupId,
                channelId: entry.channelId,
                createdAt: entry.createdAt,
                description: trimmedBackupValue(entry.description),
                customSet: trimmedBackupValue(entry.customSet)
            )
        }
    }

    private static func privilegeKeyBackupSummary(_ entry: TS3PrivilegeKeyBackupEntry) -> String {
        let type = entry.type.flatMap(TS3PrivilegeKeyType.init(rawValue:))?.title ?? "Unknown"
        var parts = [
            "key=\(entry.key)",
            "type=\(type)",
            "group=\(entry.groupId)"
        ]
        if let channelId = entry.channelId {
            parts.append("channel=\(channelId)")
        }
        if let description = entry.description, !description.isEmpty {
            parts.append("description=\(description)")
        }
        if let customSet = entry.customSet, !customSet.isEmpty {
            parts.append("customSet=\(customSet)")
        }
        return parts.joined(separator: " | ")
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

    func addServerGroup(_ group: TS3GroupSummary, toClientDatabaseId databaseId: Int) {
        let validationMessages = TS3GroupMemberDraftValidator.validationMessages(
            operation: .addServerMember,
            target: .server,
            group: group,
            clientDatabaseId: String(databaseId),
            channelId: nil
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        runClientCommand { client in
            try await client.addServerGroup(groupId: group.id, toClientDatabaseId: databaseId)
            let clients = try await client.refreshServerGroupClients(groupId: group.id)
            await MainActor.run {
                self.groupClients = clients
                    .map { TS3GroupClientSummary(client: $0) }
                    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                if let onlineClient = self.clients.first(where: { $0.databaseId == databaseId }) {
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

    func setChannelGroup(_ group: TS3GroupSummary, channelId: Int, clientDatabaseId: Int) {
        let validationMessages = TS3GroupMemberDraftValidator.validationMessages(
            operation: .setChannelGroup,
            target: .channel,
            group: group,
            clientDatabaseId: String(clientDatabaseId),
            channelId: channelId > 0 ? channelId : nil
        )
        guard validationMessages.isEmpty else {
            lastError = validationMessages.joined(separator: "\n")
            return
        }
        runClientCommand { client in
            try await client.setChannelGroup(groupId: group.id, channelId: channelId, clientDatabaseId: clientDatabaseId)
            let clients = try await client.refreshChannelGroupClients(groupId: group.id)
            await MainActor.run {
                self.groupClients = clients
                    .map { TS3GroupClientSummary(client: $0) }
                    .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
                for onlineClient in self.clients where onlineClient.databaseId == clientDatabaseId && onlineClient.channelId == channelId {
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

    private func sanitizedDatabaseClientBackupEntries(
        _ entries: [TS3DatabaseClientBackupEntry]
    ) -> (clients: [TS3DatabaseClientSummary], skippedCount: Int) {
        var skippedCount = 0
        var seenIds: Set<Int> = []
        let clients = entries.compactMap { entry -> TS3DatabaseClientSummary? in
            guard entry.id > 0, seenIds.insert(entry.id).inserted else {
                skippedCount += 1
                return nil
            }
            let nickname = entry.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !nickname.isEmpty else {
                skippedCount += 1
                return nil
            }
            return TS3DatabaseClientSummary(
                id: entry.id,
                uniqueIdentifier: trimmedArchiveValue(entry.uniqueIdentifier),
                nickname: nickname,
                createdAt: entry.createdAt,
                lastConnectedAt: entry.lastConnectedAt,
                totalConnections: entry.totalConnections,
                description: trimmedArchiveValue(entry.description),
                lastIP: trimmedArchiveValue(entry.lastIP)
            )
        }
        .sorted { lhs, rhs in
            let comparison = lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname)
            if comparison == .orderedSame {
                return lhs.id < rhs.id
            }
            return comparison == .orderedAscending
        }
        return (clients, skippedCount)
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
            applyIdentitySnapshot(snapshot)
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
                    self.applyIdentitySnapshot(snapshot)
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
                    self.applyIdentitySnapshot(snapshot)
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func saveCurrentIdentityProfile(name: String) {
        do {
            guard !identitySummary.exportString.isEmpty else {
                lastError = "Refresh identity before saving it as a profile."
                return
            }
            let profile = try identityProfile(
                name: name,
                exportString: identitySummary.exportString,
                replacing: identityProfiles.first { $0.uid == identitySummary.uid }
            )
            upsertIdentityProfile(profile)
            activeIdentityProfileId = profile.id
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func importIdentityProfile(name: String, exportString: String) {
        do {
            let profile = try identityProfile(name: name, exportString: exportString)
            upsertIdentityProfile(profile)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func activateIdentityProfile(_ profile: TS3IdentityProfile) {
        guard state == .disconnected else {
            lastError = "Disconnect before switching identities."
            return
        }
        Task {
            do {
                let snapshot = try await TS3Client(config: TS3ClientConfig(
                    host: "localhost",
                    port: 9987,
                    nickname: nickname,
                    serverPassword: nil
                )).importIdentity(exportString: profile.exportString)
                await MainActor.run {
                    self.applyIdentitySnapshot(snapshot)
                    self.activeIdentityProfileId = profile.id
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func renameIdentityProfile(_ profile: TS3IdentityProfile, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = identityProfiles.firstIndex(where: { $0.id == profile.id }), !trimmed.isEmpty else { return }
        identityProfiles[index].name = trimmed
        identityProfiles[index].updatedAt = Date()
        saveIdentityProfiles()
        lastError = nil
    }

    func deleteIdentityProfile(_ profile: TS3IdentityProfile) {
        identityProfiles.removeAll { $0.id == profile.id }
        if activeIdentityProfileId == profile.id {
            activeIdentityProfileId = nil
        }
        saveIdentityProfiles()
        lastError = nil
    }

    @discardableResult
    func importIdentityProfiles(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3IdentityProfile].self, from: data)
        for profile in try sanitizedIdentityProfiles(imported) {
            upsertIdentityProfile(profile, shouldSave: false)
        }
        saveIdentityProfiles()
        updateActiveIdentityProfile()
        lastError = nil
        return imported.count
    }

    private func applyIdentitySnapshot(_ snapshot: TS3IdentitySnapshot) {
        identitySummary = TS3IdentitySummary(
            uid: snapshot.uid,
            securityLevel: snapshot.securityLevel,
            keyOffset: snapshot.keyOffset,
            exportString: snapshot.exportString
        )
        updateActiveIdentityProfile()
    }

    private func identityProfile(
        name: String,
        exportString: String,
        replacing existingProfile: TS3IdentityProfile? = nil
    ) throws -> TS3IdentityProfile {
        let snapshot = try TS3Client.identitySnapshot(fromExportString: exportString)
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        return TS3IdentityProfile(
            id: existingProfile?.id ?? UUID(),
            name: trimmedName.isEmpty ? defaultIdentityProfileName(uid: snapshot.uid) : trimmedName,
            uid: snapshot.uid,
            securityLevel: snapshot.securityLevel,
            keyOffset: snapshot.keyOffset,
            exportString: snapshot.exportString,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: now
        )
    }

    private func upsertIdentityProfile(_ profile: TS3IdentityProfile, shouldSave: Bool = true) {
        identityProfiles.removeAll { $0.id == profile.id || $0.uid == profile.uid }
        identityProfiles.insert(profile, at: 0)
        identityProfiles = (try? sanitizedIdentityProfiles(identityProfiles)) ?? identityProfiles
        if shouldSave {
            saveIdentityProfiles()
        }
        updateActiveIdentityProfile()
    }

    private func defaultIdentityProfileName(uid: String) -> String {
        let suffix = uid.isEmpty ? "Unknown" : String(uid.prefix(8))
        return "Identity \(suffix)"
    }

    private func updateActiveIdentityProfile() {
        guard !identitySummary.uid.isEmpty else {
            activeIdentityProfileId = nil
            return
        }
        activeIdentityProfileId = identityProfiles.first { $0.uid == identitySummary.uid }?.id
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

    private var savedChannelPasswordsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-channel-passwords.json")
    }

    private var identityProfilesURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-identity-profiles.json")
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

    private var chatHistorySettingsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-chat-history-settings.json")
    }

    private var offlineMessageHistoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-offline-message-history.json")
    }

    private var offlineMessageDraftsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-offline-message-drafts.json")
    }

    private var fileBrowserBookmarksURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-file-browser-bookmarks.json")
    }

    private var fileBrowserFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-file-browser-filter-presets.json")
    }

    private var downloadedFilesURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-downloaded-files.json")
    }

    private var offlineMessageFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-offline-message-filter-presets.json")
    }

    private var banFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-ban-filter-presets.json")
    }

    private var banResultsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-ban-results.json")
    }

    private var complaintFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-complaint-filter-presets.json")
    }

    private var complaintResultsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-complaint-results.json")
    }

    private var databaseClientFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-database-client-filter-presets.json")
    }

    private var privilegeKeyFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-privilege-key-filter-presets.json")
    }

    private var temporaryServerPasswordResultsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-temporary-server-password-results.json")
    }

    private var temporaryServerPasswordFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-temporary-server-password-filter-presets.json")
    }

    private var privilegeKeyResultsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-privilege-key-results.json")
    }

    private var permissionFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-permission-filter-presets.json")
    }

    private var groupFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-group-filter-presets.json")
    }

    private var groupResultsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-group-results.json")
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

    private var serverLogResultsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-server-log-results.json")
    }

    private var channelSubscriptionPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-channel-subscription-presets.json")
    }

    private var channelTreeFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-channel-tree-filter-presets.json")
    }

    private var collapsedChannelIdsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-collapsed-channel-ids.json")
    }

    private var eventFilterPresetsURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-event-filter-presets.json")
    }

    private var eventHistoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("ts3-event-history.json")
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

    private func loadSavedChannelPasswords() {
        guard let data = try? Data(contentsOf: savedChannelPasswordsURL),
              let decoded = try? JSONDecoder().decode([TS3SavedChannelPassword].self, from: data) else {
            savedChannelPasswords = []
            return
        }
        savedChannelPasswords = sanitizedSavedChannelPasswords(decoded)
    }

    private func saveSavedChannelPasswords() {
        do {
            let directory = savedChannelPasswordsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(savedChannelPasswords)
            try data.write(to: savedChannelPasswordsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func loadIdentityProfiles() {
        guard let data = try? Data(contentsOf: identityProfilesURL),
              let decoded = try? JSONDecoder().decode([TS3IdentityProfile].self, from: data),
              let sanitized = try? sanitizedIdentityProfiles(decoded) else {
            identityProfiles = []
            activeIdentityProfileId = nil
            return
        }
        identityProfiles = sanitized
        updateActiveIdentityProfile()
    }

    private func saveIdentityProfiles() {
        do {
            let directory = identityProfilesURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(identityProfiles)
            try data.write(to: identityProfilesURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedIdentityProfiles(_ profiles: [TS3IdentityProfile]) throws -> [TS3IdentityProfile] {
        var seen: Set<String> = []
        var sanitized: [TS3IdentityProfile] = []
        for profile in profiles {
            let snapshot = try TS3Client.identitySnapshot(fromExportString: profile.exportString)
            guard seen.insert(snapshot.uid.lowercased()).inserted else { continue }
            let name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            sanitized.append(TS3IdentityProfile(
                id: profile.id,
                name: name.isEmpty ? defaultIdentityProfileName(uid: snapshot.uid) : name,
                uid: snapshot.uid,
                securityLevel: snapshot.securityLevel,
                keyOffset: snapshot.keyOffset,
                exportString: snapshot.exportString,
                createdAt: profile.createdAt,
                updatedAt: profile.updatedAt
            ))
        }
        return sanitized
    }

    @discardableResult
    func importSavedChannelPasswords(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3SavedChannelPassword].self, from: data)
        var merged = savedChannelPasswords
        for entry in sanitizedSavedChannelPasswords(imported) {
            merged.removeAll {
                $0.serverKey.caseInsensitiveCompare(entry.serverKey) == .orderedSame
                    && $0.channelPath.caseInsensitiveCompare(entry.channelPath) == .orderedSame
            }
            merged.insert(entry, at: 0)
        }
        savedChannelPasswords = sanitizedSavedChannelPasswords(merged)
        saveSavedChannelPasswords()
        lastError = nil
        return imported.count
    }

    private func sanitizedSavedChannelPasswords(
        _ passwords: [TS3SavedChannelPassword]
    ) -> [TS3SavedChannelPassword] {
        var seen: Set<String> = []
        return passwords.compactMap { entry in
            let serverKey = entry.serverKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let channelPath = entry.channelPath.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = entry.password.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !serverKey.isEmpty, !channelPath.isEmpty, !password.isEmpty else { return nil }
            let key = "\(serverKey)\n\(channelPath.lowercased())"
            guard seen.insert(key).inserted else { return nil }
            return TS3SavedChannelPassword(
                id: entry.id,
                serverKey: serverKey,
                channelPath: channelPath,
                password: password,
                updatedAt: entry.updatedAt
            )
        }
        .sorted { lhs, rhs in
            if lhs.updatedAt == rhs.updatedAt {
                return lhs.channelPath.localizedCaseInsensitiveCompare(rhs.channelPath) == .orderedAscending
            }
            return lhs.updatedAt > rhs.updatedAt
        }
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
            prefersSpeakerOutput: prefersSpeakerOutput,
            whisperActivationMode: whisperActivationMode.rawValue
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
            prefersSpeakerOutput: prefersSpeakerOutput,
            whisperActivationMode: whisperActivationMode.rawValue
        ))
        if isTalking {
            client?.stopMicrophone()
            isTalking = false
            resetInputMeter()
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
        whisperActivationMode = TS3WhisperActivationMode(rawValue: settings.whisperActivationMode) ?? .holdToWhisper
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
            mutedNotificationServerKeys = TS3NotificationSettings.defaults.mutedServerKeys
            mutedNotificationContactUniqueIdentifiers = TS3NotificationSettings.defaults.mutedContactUniqueIdentifiers
            notificationQuietHoursEnabled = TS3NotificationSettings.defaults.quietHoursEnabled
            notificationQuietHoursStartMinute = TS3NotificationSettings.defaults.quietHoursStartMinute
            notificationQuietHoursEndMinute = TS3NotificationSettings.defaults.quietHoursEndMinute
            return
        }
        notificationsEnabled = decoded.isEnabled
        notificationSoundEnabled = decoded.soundEnabled
        privateMessageNotificationsEnabled = decoded.privateMessagesEnabled
        pokeNotificationsEnabled = decoded.pokesEnabled
        activityNotificationsEnabled = decoded.activityEnabled
        mutedNotificationServerKeys = sanitizedNotificationKeys(decoded.mutedServerKeys)
        mutedNotificationContactUniqueIdentifiers = sanitizedNotificationKeys(decoded.mutedContactUniqueIdentifiers)
        notificationQuietHoursEnabled = decoded.quietHoursEnabled
        notificationQuietHoursStartMinute = sanitizedMinuteOfDay(decoded.quietHoursStartMinute)
        notificationQuietHoursEndMinute = sanitizedMinuteOfDay(decoded.quietHoursEndMinute)
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

    func notificationSettingsPreview(from data: Data) throws -> TS3NotificationSettingsPreview {
        let decoded = try JSONDecoder().decode(TS3NotificationSettings.self, from: data)
        let sanitized = TS3NotificationSettings(
            isEnabled: decoded.isEnabled,
            soundEnabled: decoded.soundEnabled,
            privateMessagesEnabled: decoded.privateMessagesEnabled,
            pokesEnabled: decoded.pokesEnabled,
            activityEnabled: decoded.activityEnabled,
            mutedServerKeys: sanitizedNotificationKeys(decoded.mutedServerKeys),
            mutedContactUniqueIdentifiers: sanitizedNotificationKeys(decoded.mutedContactUniqueIdentifiers),
            quietHoursEnabled: decoded.quietHoursEnabled,
            quietHoursStartMinute: sanitizedMinuteOfDay(decoded.quietHoursStartMinute),
            quietHoursEndMinute: sanitizedMinuteOfDay(decoded.quietHoursEndMinute)
        )
        return TS3NotificationSettingsPreview(lines: [
            "Notifications: \(sanitized.isEnabled ? "Enabled" : "Disabled")",
            "Notification sounds: \(sanitized.soundEnabled ? "On" : "Off")",
            "Notification event types: \(notificationEventTypesText(sanitized))",
            "Quiet hours: \(quietHoursPreviewText(sanitized))",
            "Muted notification servers: \(sanitized.mutedServerKeys.count)",
            "Muted notification contacts: \(sanitized.mutedContactUniqueIdentifiers.count)"
        ])
    }

    func importNotificationSettings(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3NotificationSettings.self, from: data)
        notificationsEnabled = decoded.isEnabled
        notificationSoundEnabled = decoded.soundEnabled
        privateMessageNotificationsEnabled = decoded.privateMessagesEnabled
        pokeNotificationsEnabled = decoded.pokesEnabled
        activityNotificationsEnabled = decoded.activityEnabled
        mutedNotificationServerKeys = sanitizedNotificationKeys(decoded.mutedServerKeys)
        mutedNotificationContactUniqueIdentifiers = sanitizedNotificationKeys(decoded.mutedContactUniqueIdentifiers)
        notificationQuietHoursEnabled = decoded.quietHoursEnabled
        notificationQuietHoursStartMinute = sanitizedMinuteOfDay(decoded.quietHoursStartMinute)
        notificationQuietHoursEndMinute = sanitizedMinuteOfDay(decoded.quietHoursEndMinute)
        saveNotificationSettings()
        lastError = nil
    }

    private var notificationSettingsSnapshot: TS3NotificationSettings {
        TS3NotificationSettings(
            isEnabled: notificationsEnabled,
            soundEnabled: notificationSoundEnabled,
            privateMessagesEnabled: privateMessageNotificationsEnabled,
            pokesEnabled: pokeNotificationsEnabled,
            activityEnabled: activityNotificationsEnabled,
            mutedServerKeys: mutedNotificationServerKeys,
            mutedContactUniqueIdentifiers: mutedNotificationContactUniqueIdentifiers,
            quietHoursEnabled: notificationQuietHoursEnabled,
            quietHoursStartMinute: notificationQuietHoursStartMinute,
            quietHoursEndMinute: notificationQuietHoursEndMinute
        )
    }

    private var currentNotificationServerKey: String {
        let host = serverHost.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !host.isEmpty else { return "" }
        return normalizedNotificationKey("\(host):\(serverPort)")
    }

    private func normalizedNotificationKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func sanitizedNotificationKeys(_ keys: [String]) -> [String] {
        Array(Set(keys.map(normalizedNotificationKey).filter { !$0.isEmpty })).sorted()
    }

    private func sanitizedMinuteOfDay(_ minute: Int) -> Int {
        min(max(minute, 0), 23 * 60 + 59)
    }

    private func loadServerLogQueryPresets() {
        guard let data = try? Data(contentsOf: serverLogQueryPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3ServerLogQueryPreset].self, from: data) else {
            serverLogQueryPresets = []
            return
        }
        serverLogQueryPresets = sanitizedServerLogQueryPresets(decoded)
    }

    private func loadServerLogResults() {
        guard let data = try? Data(contentsOf: serverLogResultsURL),
              let decoded = try? JSONDecoder().decode([TS3ServerLogSummary].self, from: data) else {
            serverLogEntries = []
            return
        }
        serverLogEntries = Array(sanitizedServerLogArchiveEntries(decoded).entries.prefix(500))
    }

    private func saveServerLogResults() {
        do {
            let directory = serverLogResultsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(sanitizedServerLogArchiveEntries(serverLogEntries).entries.prefix(500)))
            try data.write(to: serverLogResultsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
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
            beginPosition: min(max(preset.beginPosition, 0), 1_000_000),
            reverse: preset.reverse,
            instance: preset.instance,
            levelFilter: normalizedLevel,
            channelFilter: String(preset.channelFilter.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80)),
            searchText: String(preset.searchText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)),
            updatedAt: preset.updatedAt
        )
    }

    private func sanitizedServerLogArchiveEntries(
        _ entries: [TS3ServerLogSummary]
    ) -> (entries: [TS3ServerLogSummary], skippedCount: Int) {
        var skippedCount = 0
        var seen: Set<Int> = []
        let sanitizedEntries = entries.compactMap { entry -> TS3ServerLogSummary? in
            guard entry.id > 0, seen.insert(entry.id).inserted else {
                skippedCount += 1
                return nil
            }
            let message = entry.message.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !message.isEmpty else {
                skippedCount += 1
                return nil
            }
            let rawLine = entry.rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            return TS3ServerLogSummary(
                id: entry.id,
                timestamp: entry.timestamp,
                level: trimmedArchiveValue(entry.level),
                channel: trimmedArchiveValue(entry.channel),
                message: String(message.prefix(1_000)),
                rawLine: String((rawLine.isEmpty ? message : rawLine).prefix(2_000))
            )
        }
        .sorted { lhsEntry, rhsEntry in
            switch (lhsEntry.timestamp, rhsEntry.timestamp) {
            case let (lhs?, rhs?):
                if lhs == rhs {
                    return lhsEntry.id > rhsEntry.id
                }
                return lhs > rhs
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhsEntry.id > rhsEntry.id
            }
        }
        return (sanitizedEntries, skippedCount)
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

    private func loadCollapsedChannelIds() {
        guard let data = try? Data(contentsOf: collapsedChannelIdsURL),
              let decoded = try? JSONDecoder().decode([Int].self, from: data) else {
            collapsedChannelIds = []
            return
        }
        collapsedChannelIds = Set(decoded.filter { $0 > 0 })
    }

    private func saveCollapsedChannelIds() {
        do {
            let directory = collapsedChannelIdsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(collapsedChannelIds.sorted())
            try data.write(to: collapsedChannelIdsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func importCollapsedChannelIds(_ channelIds: [Int]) {
        collapsedChannelIds = Set(channelIds.filter { $0 > 0 })
        saveCollapsedChannelIds()
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

    private func loadEventHistory() {
        guard let data = try? Data(contentsOf: eventHistoryURL),
              let decoded = try? JSONDecoder().decode(TS3EventHistoryArchive.self, from: data) else {
            activityEvents = TS3EventHistoryArchive.empty.activityEvents
            pokeEvents = TS3EventHistoryArchive.empty.pokeEvents
            return
        }
        activityEvents = Array(decoded.activityEvents.prefix(100))
        pokeEvents = Array(decoded.pokeEvents.prefix(50))
    }

    private func saveEventHistory() {
        do {
            let directory = eventHistoryURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let archive = TS3EventHistoryArchive(
                activityEvents: Array(activityEvents.prefix(100)),
                pokeEvents: Array(pokeEvents.prefix(50))
            )
            let data = try JSONEncoder().encode(archive)
            try data.write(to: eventHistoryURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
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

    private func loadBanResults() {
        guard let data = try? Data(contentsOf: banResultsURL),
              let decoded = try? JSONDecoder().decode([TS3BanEntrySummary].self, from: data) else {
            banEntries = []
            return
        }
        banEntries = Array(decoded.prefix(500))
    }

    private func saveBanResults() {
        do {
            let directory = banResultsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(banEntries.prefix(500)))
            try data.write(to: banResultsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
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

    private func loadComplaintResults() {
        guard let data = try? Data(contentsOf: complaintResultsURL),
              let decoded = try? JSONDecoder().decode([TS3ComplaintSummary].self, from: data) else {
            complaintEntries = []
            return
        }
        complaintEntries = Array(sanitizedComplaintArchiveEntries(decoded).entries.prefix(500))
    }

    private func saveComplaintResults() {
        do {
            let directory = complaintResultsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(complaintEntries.prefix(500)))
            try data.write(to: complaintResultsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
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

    private func sanitizedComplaintArchiveEntries(
        _ entries: [TS3ComplaintSummary]
    ) -> (entries: [TS3ComplaintSummary], skippedCount: Int) {
        var skippedCount = 0
        var seen: Set<String> = []
        let sanitizedEntries = entries.compactMap { entry -> TS3ComplaintSummary? in
            guard entry.targetClientDatabaseId > 0, entry.sourceClientDatabaseId > 0 else {
                skippedCount += 1
                return nil
            }
            let targetName = trimmedArchiveValue(entry.targetName)
            let sourceName = trimmedArchiveValue(entry.sourceName)
            let message = trimmedArchiveValue(entry.message)
            let stableId = "complaint-\(entry.targetClientDatabaseId)-\(entry.sourceClientDatabaseId)-\(entry.timestamp?.timeIntervalSince1970 ?? 0)-\(message ?? "")"
            let id = entry.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? stableId : entry.id
            let duplicateKey = [
                String(entry.targetClientDatabaseId),
                String(entry.sourceClientDatabaseId),
                entry.timestamp?.timeIntervalSince1970.description ?? "",
                message ?? ""
            ].joined(separator: "\u{1F}")
            guard seen.insert(duplicateKey).inserted else {
                skippedCount += 1
                return nil
            }
            return TS3ComplaintSummary(
                id: id,
                targetClientDatabaseId: entry.targetClientDatabaseId,
                targetName: targetName,
                sourceClientDatabaseId: entry.sourceClientDatabaseId,
                sourceName: sourceName,
                message: message,
                timestamp: entry.timestamp
            )
        }
        .sorted {
            switch ($0.timestamp, $1.timestamp) {
            case let (lhs?, rhs?): return lhs > rhs
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return $0.sourceClientDatabaseId < $1.sourceClientDatabaseId
            }
        }
        return (sanitizedEntries, skippedCount)
    }

    private func trimmedArchiveValue(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func loadTemporaryServerPasswordFilterPresets() {
        guard let data = try? Data(contentsOf: temporaryServerPasswordFilterPresetsURL),
              let decoded = try? JSONDecoder().decode([TS3TemporaryServerPasswordFilterPreset].self, from: data) else {
            temporaryServerPasswordFilterPresets = []
            return
        }
        temporaryServerPasswordFilterPresets = sanitizedTemporaryServerPasswordFilterPresets(decoded)
    }

    private func saveTemporaryServerPasswordFilterPresets() {
        do {
            let directory = temporaryServerPasswordFilterPresetsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(temporaryServerPasswordFilterPresets)
            try data.write(to: temporaryServerPasswordFilterPresetsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedTemporaryServerPasswordFilterPresets(
        _ presets: [TS3TemporaryServerPasswordFilterPreset]
    ) -> [TS3TemporaryServerPasswordFilterPreset] {
        presets.compactMap(sanitizedTemporaryServerPasswordFilterPreset)
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    private func sanitizedTemporaryServerPasswordFilterPreset(
        _ preset: TS3TemporaryServerPasswordFilterPreset
    ) -> TS3TemporaryServerPasswordFilterPreset? {
        let name = preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let passwordFilter = [
            "all",
            "serverDefault",
            "channelTarget",
            "withDescription",
            "withCreator",
            "withExpiration"
        ].contains(preset.passwordFilter) ? preset.passwordFilter : "all"
        let sortMode = [
            "created",
            "password",
            "target",
            "duration",
            "creator",
            "description"
        ].contains(preset.sortMode) ? preset.sortMode : "created"
        return TS3TemporaryServerPasswordFilterPreset(
            id: preset.id,
            name: name,
            passwordFilter: passwordFilter,
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

    private func loadTemporaryServerPasswordResults() {
        guard let data = try? Data(contentsOf: temporaryServerPasswordResultsURL),
              let decoded = try? JSONDecoder().decode([TS3TemporaryServerPasswordSummary].self, from: data) else {
            temporaryServerPasswords = []
            return
        }
        temporaryServerPasswords = Array(decoded.prefix(500))
    }

    private func saveTemporaryServerPasswordResults() {
        do {
            let directory = temporaryServerPasswordResultsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(temporaryServerPasswords.prefix(500)))
            try data.write(to: temporaryServerPasswordResultsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func loadPrivilegeKeyResults() {
        guard let data = try? Data(contentsOf: privilegeKeyResultsURL),
              let decoded = try? JSONDecoder().decode([TS3PrivilegeKeySummary].self, from: data) else {
            privilegeKeys = []
            return
        }
        privilegeKeys = Array(decoded.prefix(500))
    }

    private func savePrivilegeKeyResults() {
        do {
            let directory = privilegeKeyResultsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(privilegeKeys.prefix(500)))
            try data.write(to: privilegeKeyResultsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
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

    private struct TS3GroupResults: Codable {
        var serverGroups: [TS3GroupSummary]
        var channelGroups: [TS3GroupSummary]
    }

    private func loadGroupResults() {
        guard let data = try? Data(contentsOf: groupResultsURL),
              let decoded = try? JSONDecoder().decode(TS3GroupResults.self, from: data) else {
            serverGroups = []
            channelGroups = []
            return
        }
        let sanitized = sanitizedGroupArchive(serverGroups: decoded.serverGroups, channelGroups: decoded.channelGroups)
        serverGroups = Array(sanitized.serverGroups.prefix(500))
        channelGroups = Array(sanitized.channelGroups.prefix(500))
    }

    private func saveGroupResults() {
        do {
            let directory = groupResultsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let sanitized = sanitizedGroupArchive(serverGroups: serverGroups, channelGroups: channelGroups)
            let data = try JSONEncoder().encode(TS3GroupResults(
                serverGroups: Array(sanitized.serverGroups.prefix(500)),
                channelGroups: Array(sanitized.channelGroups.prefix(500))
            ))
            try data.write(to: groupResultsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sanitizedGroupArchive(
        serverGroups: [TS3GroupSummary],
        channelGroups: [TS3GroupSummary]
    ) -> (
        serverGroups: [TS3GroupSummary],
        channelGroups: [TS3GroupSummary],
        skippedServerGroupCount: Int,
        skippedChannelGroupCount: Int
    ) {
        let sanitizedServerGroups = sanitizedGroupSummaries(serverGroups)
        let sanitizedChannelGroups = sanitizedGroupSummaries(channelGroups)
        return (
            sanitizedServerGroups.groups,
            sanitizedChannelGroups.groups,
            sanitizedServerGroups.skippedCount,
            sanitizedChannelGroups.skippedCount
        )
    }

    private func sanitizedGroupSummaries(
        _ groups: [TS3GroupSummary]
    ) -> (groups: [TS3GroupSummary], skippedCount: Int) {
        var skippedCount = 0
        var seen: Set<Int> = []
        let sanitizedGroups = groups.compactMap { group -> TS3GroupSummary? in
            guard group.id > 0, seen.insert(group.id).inserted else {
                skippedCount += 1
                return nil
            }
            let name = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                skippedCount += 1
                return nil
            }
            return TS3GroupSummary(
                id: group.id,
                name: String(name.prefix(120)),
                type: group.type
            )
        }
        .sorted {
            if $0.id == $1.id {
                return false
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedSame
                ? $0.id < $1.id
                : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        return (sanitizedGroups, skippedCount)
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
        let channelFilter = ["allChannels", "currentChannel", "selectedChannel", "withoutChannel"].contains(preset.channelFilter)
            ? preset.channelFilter
            : "allChannels"
        let channelId = preset.channelId.flatMap { $0 > 0 ? $0 : nil }
        let sortMode = ["nickname", "databaseId", "channel", "uniqueId"].contains(preset.sortMode)
            ? preset.sortMode
            : "nickname"
        return TS3GroupClientFilterPreset(
            id: preset.id,
            name: name,
            memberFilter: memberFilter,
            channelFilter: channelFilter == "selectedChannel" && channelId == nil ? "allChannels" : channelFilter,
            channelId: channelFilter == "selectedChannel" ? channelId : nil,
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
            savedChannelPasswords: savedChannelPasswords,
            identityProfiles: identityProfiles,
            contacts: contacts,
            contactFilterPresets: contactFilterPresets,
            notificationSettings: notificationSettingsSnapshot,
            connectionRecoverySettings: currentConnectionRecoverySettings,
            chatHistorySettings: currentChatHistorySettings,
            serverLogQueryPresets: serverLogQueryPresets,
            keyboardShortcuts: keyboardShortcuts,
            channelSubscriptionPresets: channelSubscriptionPresets,
            channelTreeFilterPresets: channelTreeFilterPresets,
            collapsedChannelIds: collapsedChannelIds.sorted(),
            eventFilterPresets: eventFilterPresets,
            chatFilterPresets: chatFilterPresets,
            fileBrowserBookmarks: fileBrowserBookmarks,
            fileBrowserFilterPresets: fileBrowserFilterPresets,
            offlineMessageFilterPresets: offlineMessageFilterPresets,
            banFilterPresets: banFilterPresets,
            complaintFilterPresets: complaintFilterPresets,
            temporaryServerPasswordFilterPresets: temporaryServerPasswordFilterPresets,
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

    func importClientMigrationPackage(
        from data: Data,
        options: TS3ClientMigrationRestoreOptions = .all
    ) throws {
        let package = try JSONDecoder().decode(TS3ClientMigrationPackage.self, from: data)
        if options.connections {
            try importBookmarks(from: encodedPackageSection(package.bookmarks))
            try importRecentConnections(from: encodedPackageSection(package.recentConnections))
            try importConnectionFilterPresets(from: encodedPackageSection(package.connectionFilterPresets))
            try importSavedChannelPasswords(from: encodedPackageSection(package.savedChannelPasswords))
            try importConnectionRecoverySettings(from: encodedPackageSection(package.connectionRecoverySettings))
        }
        if options.identities {
            try importIdentityProfiles(from: encodedPackageSection(package.identityProfiles))
        }
        if options.contacts {
            try importContacts(from: encodedPackageSection(package.contacts))
            try importContactFilterPresets(from: encodedPackageSection(package.contactFilterPresets))
        }
        if options.notifications {
            try importNotificationSettings(from: encodedPackageSection(package.notificationSettings))
        }
        if options.chat {
            try importChatHistorySettings(from: encodedPackageSection(package.chatHistorySettings))
            try importEventFilterPresets(from: encodedPackageSection(package.eventFilterPresets))
            try importChatFilterPresets(from: encodedPackageSection(package.chatFilterPresets))
            try importOfflineMessageFilterPresets(from: encodedPackageSection(package.offlineMessageFilterPresets))
        }
        if options.serverAdministration {
            try importServerLogQueryPresets(from: encodedPackageSection(package.serverLogQueryPresets))
            try importBanFilterPresets(from: encodedPackageSection(package.banFilterPresets))
            try importComplaintFilterPresets(from: encodedPackageSection(package.complaintFilterPresets))
            try importTemporaryServerPasswordFilterPresets(from: encodedPackageSection(package.temporaryServerPasswordFilterPresets))
            try importDatabaseClientFilterPresets(from: encodedPackageSection(package.databaseClientFilterPresets))
            try importPrivilegeKeyFilterPresets(from: encodedPackageSection(package.privilegeKeyFilterPresets))
            try importPermissionFilterPresets(from: encodedPackageSection(package.permissionFilterPresets))
            try importGroupFilterPresets(from: encodedPackageSection(package.groupFilterPresets))
            try importGroupClientFilterPresets(from: encodedPackageSection(package.groupClientFilterPresets))
        }
        if options.channelLayout {
            try importChannelSubscriptionPresets(from: encodedPackageSection(package.channelSubscriptionPresets))
            try importChannelTreeFilterPresets(from: encodedPackageSection(package.channelTreeFilterPresets))
            importCollapsedChannelIds(package.collapsedChannelIds)
        }
        if options.files {
            try importFileBrowserBookmarks(from: encodedPackageSection(package.fileBrowserBookmarks))
            try importFileBrowserFilterPresets(from: encodedPackageSection(package.fileBrowserFilterPresets))
        }
        if options.audio {
            try importAudioSettings(from: encodedPackageSection(package.audioSettings))
            try importAudioProfiles(from: encodedPackageSection(package.audioProfiles))
            try importUserPlaybackPreferences(from: encodedPackageSection(package.userPlaybackPreferences))
        }
        if options.selfStatus {
            try importSelfStatusBackup(from: encodedPackageSection(package.selfStatus))
            try importSelfStatusProfiles(from: encodedPackageSection(package.selfStatusProfiles))
        }
        if options.whisper {
            try importWhisperPresetBackup(from: encodedPackageSection(package.whisperPresets))
            try importWhisperFilterPresets(from: encodedPackageSection(package.whisperFilterPresets))
        }
        lastError = nil
    }

    func clientMigrationPackagePreview(from data: Data) throws -> TS3ClientMigrationPackagePreview {
        let package = try JSONDecoder().decode(TS3ClientMigrationPackage.self, from: data)
        let itemCounts: [(String, Int)] = [
            ("Bookmarks", package.bookmarks.count),
            ("Recent Connections", package.recentConnections.count),
            ("Saved Channel Passwords", package.savedChannelPasswords.count),
            ("Identity Profiles", package.identityProfiles.count),
            ("Contacts", package.contacts.count),
            ("Server Log Presets", package.serverLogQueryPresets.count),
            ("Keyboard Shortcuts", package.keyboardShortcuts.count),
            ("Channel Subscription Presets", package.channelSubscriptionPresets.count),
            ("Channel Tree Filters", package.channelTreeFilterPresets.count),
            ("Collapsed Channels", package.collapsedChannelIds.count),
            ("Event Filters", package.eventFilterPresets.count),
            ("Chat Filters", package.chatFilterPresets.count),
            ("File Bookmarks", package.fileBrowserBookmarks.count),
            ("File Filters", package.fileBrowserFilterPresets.count),
            ("Offline Message Filters", package.offlineMessageFilterPresets.count),
            ("Ban Filters", package.banFilterPresets.count),
            ("Complaint Filters", package.complaintFilterPresets.count),
            ("Temporary Password Filters", package.temporaryServerPasswordFilterPresets.count),
            ("Database Client Filters", package.databaseClientFilterPresets.count),
            ("Privilege Key Filters", package.privilegeKeyFilterPresets.count),
            ("Permission Filters", package.permissionFilterPresets.count),
            ("Group Filters", package.groupFilterPresets.count),
            ("Group Client Filters", package.groupClientFilterPresets.count),
            ("Audio Profiles", package.audioProfiles.count),
            ("Playback Preferences", package.userPlaybackPreferences.count),
            ("Self Status Profiles", package.selfStatusProfiles.count),
            ("Whisper Presets", package.whisperPresets.count),
            ("Whisper Filters", package.whisperFilterPresets.count)
        ]
        return TS3ClientMigrationPackagePreview(
            schemaVersion: package.schemaVersion,
            exportedAt: package.exportedAt,
            itemCounts: itemCounts.filter { $0.1 > 0 },
            settingsGroups: [
                "Notification settings",
                "Connection recovery settings",
                "Chat history settings",
                "Audio settings",
                "Self status"
            ],
            settingsDetails: clientMigrationSettingsDetails(for: package)
        )
    }

    private func clientMigrationSettingsDetails(for package: TS3ClientMigrationPackage) -> [String] {
        let notificationSettings = package.notificationSettings
        let enabledShortcuts = package.keyboardShortcuts.filter(\.isEnabled).count
        let audioMode = TS3AudioTransmitMode(rawValue: package.audioSettings.transmitMode)?.rawValue
            ?? package.audioSettings.transmitMode
        return [
            "Notifications: \(notificationSettings.isEnabled ? "Enabled" : "Disabled")",
            "Notification sounds: \(notificationSettings.soundEnabled ? "On" : "Off")",
            "Notification event types: \(notificationEventTypesText(notificationSettings))",
            "Muted notification servers: \(notificationSettings.mutedServerKeys.count)",
            "Muted notification contacts: \(notificationSettings.mutedContactUniqueIdentifiers.count)",
            "Quiet hours: \(quietHoursPreviewText(notificationSettings))",
            "Auto reconnect: \(package.connectionRecoverySettings.autoReconnectEnabled ? "Enabled" : "Disabled")",
            "Chat history limit: \(package.chatHistorySettings.messageLimit)",
            "Keyboard shortcuts: \(enabledShortcuts) enabled / \(package.keyboardShortcuts.count) total",
            "Audio transmit mode: \(audioMode)",
            "Self status: \(package.selfStatus.isAway ? "Away" : "Available")"
        ]
    }

    private func notificationEventTypesText(_ settings: TS3NotificationSettings) -> String {
        var eventTypes: [String] = []
        if settings.privateMessagesEnabled {
            eventTypes.append("private messages")
        }
        if settings.pokesEnabled {
            eventTypes.append("pokes")
        }
        if settings.activityEnabled {
            eventTypes.append("activity")
        }
        return eventTypes.isEmpty ? "none" : eventTypes.joined(separator: ", ")
    }

    private func quietHoursPreviewText(_ settings: TS3NotificationSettings) -> String {
        guard settings.quietHoursEnabled else { return "Off" }
        let start = sanitizedMinuteOfDay(settings.quietHoursStartMinute)
        let end = sanitizedMinuteOfDay(settings.quietHoursEndMinute)
        return "\(minuteOfDayPreviewText(start))-\(minuteOfDayPreviewText(end))"
    }

    private func minuteOfDayPreviewText(_ minute: Int) -> String {
        let hour = minute / 60
        let minute = minute % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func encodedPackageSection<T: Encodable>(_ value: T) throws -> Data {
        try JSONEncoder().encode(value)
    }

    private func notifyIfInactive(title: String, body: String, identifier: String) {
        #if canImport(UserNotifications)
        guard notificationsEnabled, !isAppActive else { return }
        guard !isNotificationQuietHoursActive() else { return }
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

    private func isNotificationQuietHoursActive(date: Date = Date()) -> Bool {
        guard notificationQuietHoursEnabled else { return false }
        let start = sanitizedMinuteOfDay(notificationQuietHoursStartMinute)
        let end = sanitizedMinuteOfDay(notificationQuietHoursEndMinute)
        guard start != end else { return true }

        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let minute = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        if start < end {
            return minute >= start && minute < end
        }
        return minute >= start || minute < end
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
        let sortMode = ["savedOrder", "name", "host", "nickname", "note", "port"].contains(preset.sortMode)
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
        try contactsExportData(contacts)
    }

    func contactsExportData(_ entries: [TS3ContactEntry]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(sanitizedImportedContacts(entries).contacts)
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

    func deleteAllContactFilterPresets() {
        guard !contactFilterPresets.isEmpty else { return }
        contactFilterPresets = []
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
    func importContacts(
        from data: Data,
        options: TS3ContactImportOptions = .all
    ) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ContactEntry].self, from: data)
        var merged = contacts
        let currentByUniqueIdentifier = Dictionary(contacts.map { ($0.uniqueIdentifier, $0) }, uniquingKeysWith: { _, latest in latest })
        let contactsToImport = sanitizedImportedContacts(imported).contacts.filter { contact in
            guard let current = currentByUniqueIdentifier[contact.uniqueIdentifier] else {
                return options.newContacts
            }
            return options.updatedContacts && !contactImportContact(contact, matches: current)
        }
        for contact in contactsToImport {
            merged.removeAll { $0.uniqueIdentifier == contact.uniqueIdentifier }
            merged.insert(
                contact,
                at: 0
            )
        }
        contacts = merged
        saveContacts()
        syncBlockedContactPlayback()
        lastError = nil
        return imported.count
    }

    func contactImportPreview(from data: Data) throws -> TS3ContactImportPreview {
        let imported = try JSONDecoder().decode([TS3ContactEntry].self, from: data)
        let sanitized = sanitizedImportedContacts(imported)
        let currentByUniqueIdentifier = Dictionary(contacts.map { ($0.uniqueIdentifier, $0) }, uniquingKeysWith: { _, latest in latest })
        var newContactNames: [String] = []
        var updatedContactNames: [String] = []
        var unchangedContactNames: [String] = []
        for contact in sanitized.contacts {
            if let current = currentByUniqueIdentifier[contact.uniqueIdentifier] {
                if contactImportContact(contact, matches: current) {
                    unchangedContactNames.append(contact.nickname)
                } else {
                    updatedContactNames.append(contact.nickname)
                }
            } else {
                newContactNames.append(contact.nickname)
            }
        }
        return TS3ContactImportPreview(
            importedCount: imported.count,
            validCount: sanitized.contacts.count,
            invalidCount: sanitized.invalidCount,
            duplicateCount: sanitized.duplicateCount,
            newCount: newContactNames.count,
            updatedCount: updatedContactNames.count,
            unchangedCount: unchangedContactNames.count,
            newContactNames: newContactNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending },
            updatedContactNames: updatedContactNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending },
            unchangedContactNames: unchangedContactNames.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        )
    }

    private func sanitizedImportedContacts(_ imported: [TS3ContactEntry]) -> (contacts: [TS3ContactEntry], invalidCount: Int, duplicateCount: Int) {
        var contacts: [TS3ContactEntry] = []
        var seenUniqueIdentifiers = Set<String>()
        var duplicateCount = 0
        var invalidCount = 0
        for contact in imported {
            let uniqueIdentifier = contact.uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !uniqueIdentifier.isEmpty else {
                invalidCount += 1
                continue
            }
            if seenUniqueIdentifiers.contains(uniqueIdentifier) {
                duplicateCount += 1
                contacts.removeAll { $0.uniqueIdentifier == uniqueIdentifier }
            }
            seenUniqueIdentifiers.insert(uniqueIdentifier)
            let nickname = contact.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let note = contact.note.trimmingCharacters(in: .whitespacesAndNewlines)
            contacts.append(TS3ContactEntry(
                uniqueIdentifier: uniqueIdentifier,
                nickname: nickname.isEmpty ? uniqueIdentifier : nickname,
                status: contact.status,
                note: note,
                updatedAt: contact.updatedAt
            ))
        }
        return (contacts, invalidCount, duplicateCount)
    }

    private func contactImportContact(_ imported: TS3ContactEntry, matches current: TS3ContactEntry) -> Bool {
        imported.uniqueIdentifier == current.uniqueIdentifier
            && imported.nickname == current.nickname
            && imported.status == current.status
            && imported.note == current.note
    }

    private func loadChatHistory() {
        guard let data = try? Data(contentsOf: chatHistoryURL),
              let decoded = try? JSONDecoder().decode([TS3ChatMessageSummary].self, from: data) else {
            chatMessages = []
            return
        }
        chatMessages = Array(decoded.suffix(chatHistoryMessageLimit))
    }

    private func saveChatHistory() {
        do {
            let directory = chatHistoryURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Array(chatMessages.suffix(chatHistoryMessageLimit)))
            try data.write(to: chatHistoryURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func loadChatHistorySettings() {
        guard let data = try? Data(contentsOf: chatHistorySettingsURL),
              let decoded = try? JSONDecoder().decode(TS3ChatHistorySettings.self, from: data) else {
            applyChatHistorySettings(.defaults)
            return
        }
        applyChatHistorySettings(decoded)
    }

    private func saveChatHistorySettings() {
        do {
            let directory = chatHistorySettingsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(currentChatHistorySettings)
            try data.write(to: chatHistorySettingsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateChatHistoryMessageLimit(_ limit: Int) {
        applyChatHistorySettings(TS3ChatHistorySettings(messageLimit: limit))
        trimChatHistoryToLimit()
        saveChatHistorySettings()
        saveChatHistory()
    }

    func resetChatHistorySettings() {
        applyChatHistorySettings(.defaults)
        trimChatHistoryToLimit()
        saveChatHistorySettings()
        saveChatHistory()
    }

    func chatHistorySettingsExportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(currentChatHistorySettings)
    }

    func importChatHistorySettings(from data: Data) throws {
        let decoded = try JSONDecoder().decode(TS3ChatHistorySettings.self, from: data)
        applyChatHistorySettings(decoded)
        trimChatHistoryToLimit()
        saveChatHistorySettings()
        saveChatHistory()
    }

    private var currentChatHistorySettings: TS3ChatHistorySettings {
        sanitizedChatHistorySettings(TS3ChatHistorySettings(messageLimit: chatHistoryMessageLimit))
    }

    private func applyChatHistorySettings(_ settings: TS3ChatHistorySettings) {
        chatHistoryMessageLimit = sanitizedChatHistorySettings(settings).messageLimit
    }

    private func sanitizedChatHistorySettings(_ settings: TS3ChatHistorySettings) -> TS3ChatHistorySettings {
        TS3ChatHistorySettings(messageLimit: min(
            TS3ChatHistorySettings.maximumMessageLimit,
            max(TS3ChatHistorySettings.minimumMessageLimit, settings.messageLimit)
        ))
    }

    private func trimChatHistoryToLimit() {
        if chatMessages.count > chatHistoryMessageLimit {
            chatMessages.removeFirst(chatMessages.count - chatHistoryMessageLimit)
        }
        unreadChatMessageCount = min(unreadChatMessageCount, chatMessages.count)
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

    private func loadOfflineMessageHistory() {
        guard let data = try? Data(contentsOf: offlineMessageHistoryURL),
              let decoded = try? JSONDecoder().decode([TS3OfflineMessageSummary].self, from: data) else {
            offlineMessages = []
            return
        }
        offlineMessages = sanitizedOfflineMessageArchiveMessages(decoded).messages
    }

    private func sanitizedOfflineMessageArchiveMessages(
        _ messages: [TS3OfflineMessageSummary]
    ) -> (messages: [TS3OfflineMessageSummary], skippedCount: Int) {
        var skippedCount = 0
        var seen: Set<Int> = []
        let sanitizedMessages = messages.compactMap { message -> TS3OfflineMessageSummary? in
            guard message.id > 0, seen.insert(message.id).inserted else {
                skippedCount += 1
                return nil
            }
            let subject = message.subject.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !subject.isEmpty else {
                skippedCount += 1
                return nil
            }
            return TS3OfflineMessageSummary(
                id: message.id,
                senderUniqueIdentifier: trimmedArchiveValue(message.senderUniqueIdentifier),
                senderName: trimmedArchiveValue(message.senderName),
                subject: String(subject.prefix(200)),
                message: trimmedArchiveValue(message.message),
                timestamp: message.timestamp,
                isRead: message.isRead
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.timestamp, rhs.timestamp) {
            case let (lhs?, rhs?):
                return lhs > rhs
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.id > rhs.id
            }
        }
        return (sanitizedMessages, skippedCount)
    }

    private static func offlineMessageArchiveSummary(_ message: TS3OfflineMessageSummary) -> String {
        var parts = [
            "id=\(message.id)",
            "read=\(message.isRead ? "true" : "false")",
            "subject=\(message.subject)"
        ]
        if let senderName = message.senderName, !senderName.isEmpty {
            parts.append("sender=\(senderName)")
        }
        if let senderUniqueIdentifier = message.senderUniqueIdentifier, !senderUniqueIdentifier.isEmpty {
            parts.append("senderUid=\(senderUniqueIdentifier)")
        }
        if let timestamp = message.timestamp {
            parts.append("timestamp=\(Int(timestamp.timeIntervalSince1970))")
        }
        if message.message?.isEmpty == false {
            parts.append("body=true")
        }
        return parts.joined(separator: " | ")
    }

    private func saveOfflineMessageHistory() {
        do {
            let directory = offlineMessageHistoryURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(offlineMessages)
            try data.write(to: offlineMessageHistoryURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearOfflineMessageHistory() {
        offlineMessages = []
        saveOfflineMessageHistory()
    }

    private func loadOfflineMessageDrafts() {
        guard let data = try? Data(contentsOf: offlineMessageDraftsURL),
              let decoded = try? JSONDecoder().decode([TS3OfflineMessageDraft].self, from: data) else {
            offlineMessageDrafts = []
            return
        }
        offlineMessageDrafts = decoded.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func saveOfflineMessageDrafts() {
        do {
            let directory = offlineMessageDraftsURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(offlineMessageDrafts)
            try data.write(to: offlineMessageDraftsURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func loadDownloadedFiles() {
        guard let data = try? Data(contentsOf: downloadedFilesURL),
              let decoded = try? JSONDecoder().decode([TS3DownloadedFileSummary].self, from: data) else {
            downloadedFiles = []
            lastDownloadedFile = nil
            return
        }
        downloadedFiles = Array(decoded.sorted { $0.downloadedAt > $1.downloadedAt }.prefix(25))
        lastDownloadedFile = downloadedFiles.first
    }

    private func saveDownloadedFiles() {
        do {
            let directory = downloadedFilesURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(downloadedFiles)
            try data.write(to: downloadedFilesURL, options: .atomic)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func chatHistoryBackupData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(Array(chatMessages.suffix(chatHistoryMessageLimit)))
    }

    @discardableResult
    func importChatHistoryBackup(from data: Data) throws -> Int {
        let imported = try JSONDecoder().decode([TS3ChatMessageSummary].self, from: data)
        var merged = chatMessages
        for message in imported {
            merged.removeAll { $0.id == message.id }
            merged.append(message)
        }
        chatMessages = Array(merged.sorted { $0.timestamp < $1.timestamp }.suffix(chatHistoryMessageLimit))
        unreadChatMessageCount = isViewingChat ? 0 : chatMessages.count
        saveChatHistory()
        lastError = nil
        return imported.count
    }

    func chatTranscriptData(
        messages: [TS3ChatMessageSummary],
        title: String = "All Conversations",
        filterSummary: String = "All messages",
        generatedAt: Date = Date()
    ) -> Data {
        Data(chatTranscriptText(
            messages: messages,
            title: title,
            filterSummary: filterSummary,
            generatedAt: generatedAt
        ).utf8)
    }

    func chatTranscriptText(
        messages: [TS3ChatMessageSummary],
        title: String = "All Conversations",
        filterSummary: String = "All messages",
        generatedAt: Date = Date()
    ) -> String {
        let sortedMessages = messages.sorted {
            if $0.timestamp == $1.timestamp {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.timestamp < $1.timestamp
        }
        var lines = [
            "TeamSpeak 3 Chat Transcript",
            "Generated: \(Self.transcriptDateFormatter.string(from: generatedAt))",
            "Scope: \(title)",
            "Filters: \(filterSummary)",
            "Messages: \(sortedMessages.count)"
        ]
        guard !sortedMessages.isEmpty else {
            return lines.joined(separator: "\n")
        }

        var currentConversation = ""
        for message in sortedMessages {
            let conversation = chatTranscriptConversationTitle(for: message)
            if conversation != currentConversation {
                lines.append("")
                lines.append("## \(conversation)")
                currentConversation = conversation
            }
            lines.append(contentsOf: chatTranscriptLines(for: message))
        }
        return lines.joined(separator: "\n")
    }

    private func chatTranscriptConversationTitle(for message: TS3ChatMessageSummary) -> String {
        switch message.targetMode {
        case .server:
            return "Server Chat"
        case .channel:
            guard let targetId = message.targetId else { return "Channel Chat: Unknown Channel" }
            return "Channel Chat: \(channelName(for: targetId) ?? "Channel \(targetId)") (\(targetId))"
        case .client:
            let peerId = message.isOwnMessage ? message.targetId : message.senderId
            let peerName = peerId.flatMap { clientName(for: $0) } ?? message.senderName
            if let peerId {
                return "Private Chat: \(peerName) (\(peerId))"
            }
            return "Private Chat: \(peerName)"
        }
    }

    private func chatTranscriptLines(for message: TS3ChatMessageSummary) -> [String] {
        let direction = message.isOwnMessage ? "out" : "in"
        let sender = message.senderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown" : message.senderName
        let prefix = "\(Self.transcriptDateFormatter.string(from: message.timestamp)) [\(direction)] \(sender):"
        let bodyLines = message.message.components(separatedBy: .newlines)
        guard let firstLine = bodyLines.first else {
            return ["\(prefix)"]
        }
        var lines = ["\(prefix) \(firstLine)"]
        lines += bodyLines.dropFirst().map { "    \($0)" }
        return lines
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
        saveEventHistory()
    }

    func clearPokeEvents() {
        pokeEvents = []
        unreadPokeCount = 0
        saveEventHistory()
    }

    func clearEventHistory() {
        pokeEvents = []
        activityEvents = []
        unreadPokeCount = 0
        unreadActivityCount = 0
        saveEventHistory()
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

    private func clientName(for id: Int) -> String? {
        clients.first { $0.id == id }?.nickname
    }

    func toggleTalking() {
        guard !isInputMuted else {
            lastError = "Clear microphone mute before using Push To Talk."
            return
        }

        if isTalking {
            client?.stopMicrophone()
            isTalking = false
            resetInputMeter()
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
        applyWhisperRoute(.channel(channel.id))
    }

    func enableWhisperToClient(_ user: TS3UserSummary) {
        applyWhisperRoute(.client(user.id))
    }

    func enableWhisperToServer() {
        applyWhisperRoute(.server)
    }

    func disableWhisper() {
        if isWhisperActivationActive {
            endWhisperActivation()
        }
        applyWhisperRoute(.none)
    }

    func enableWhisperToChannel(id: Int) {
        applyWhisperRoute(.channel(id))
    }

    func enableWhisperList(channelIds: Set<Int>, clientIds: Set<Int>) {
        let channels = channelIds.sorted()
        let clients = clientIds.sorted()
        guard !channels.isEmpty || !clients.isEmpty else {
            lastError = "Select at least one whisper target."
            return
        }
        applyWhisperRoute(.list(channelIds: channels, clientIds: clients))
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
        applyWhisperRoute(.list(channelIds: preset.channelIds, clientIds: preset.clientIds))
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
        applyWhisperRoute(.group(type: type, target: target, targetId: targetId))
    }

    func beginWhisperActivation(route: TS3WhisperRoute) {
        guard route != .none else {
            lastError = "Select a whisper target before starting temporary whisper."
            appendWhisperActivationLog(action: "Start failed: no whisper target")
            return
        }
        guard !isInputMuted else {
            lastError = "Clear microphone mute before starting temporary whisper."
            appendWhisperActivationLog(action: "Start failed: microphone muted")
            return
        }
        guard client != nil else {
            lastError = "Connect to a server before starting temporary whisper."
            appendWhisperActivationLog(action: "Start failed: disconnected")
            return
        }
        if !isWhisperActivationActive {
            whisperActivationPreviousRoute = whisperRoute
            whisperActivationStartedTalking = !isTalking
        }
        isWhisperActivationActive = true
        applyWhisperRoute(route)
        if !isTalking {
            toggleTalking()
        }
        appendWhisperActivationLog(action: "Started temporary whisper")
    }

    func beginCurrentWhisperActivation() {
        beginWhisperActivation(route: whisperRoute)
    }

    func endWhisperActivation() {
        guard isWhisperActivationActive else {
            appendWhisperActivationLog(action: "Stop ignored: inactive")
            return
        }
        let shouldStopTalking = whisperActivationStartedTalking
        let restoreRoute = whisperActivationPreviousRoute ?? .none
        isWhisperActivationActive = false
        whisperActivationPreviousRoute = nil
        whisperActivationStartedTalking = false
        if shouldStopTalking, isTalking {
            client?.stopMicrophone()
            isTalking = false
            resetInputMeter()
        }
        applyWhisperRoute(restoreRoute)
        appendWhisperActivationLog(action: "Stopped temporary whisper")
    }

    func toggleCurrentWhisperActivation() {
        if isWhisperActivationActive {
            endWhisperActivation()
        } else {
            beginCurrentWhisperActivation()
        }
    }

    private func applyWhisperRoute(_ route: TS3WhisperRoute) {
        whisperRoute = route
        switch route {
        case .none:
            client?.stopWhisper()
        case .server:
            client?.startWhisperToServer()
        case let .channel(channelId):
            client?.startWhisperToChannel(channelId)
        case let .client(clientId):
            client?.startWhisperToClient(clientId)
        case let .list(channelIds, clientIds):
            client?.startWhisper(target: .multiple(
                channelIds: channelIds.map { UInt64(max($0, 0)) },
                clientIds: clientIds.map { UInt16(max(0, min($0, Int(UInt16.max)))) }
            ))
        case let .group(type, target, targetId):
            client?.startWhisper(target: .group(type: type, target: target, targetId: UInt64(max(targetId, 0))))
        }
        appendWhisperActivationLog(action: "Route changed")
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

    var whisperActivationStatus: String {
        guard isWhisperActivationActive else {
            return whisperRoute == .none ? "Inactive" : "Ready"
        }
        if whisperActivationStartedTalking {
            return "Active, started microphone"
        }
        return "Active, microphone was already live"
    }

    func clearWhisperActivationLog() {
        whisperActivationLog.removeAll()
    }

    func whisperActivationLogData() -> Data {
        let lines = whisperActivationLog.map { entry in
            let talking = entry.isTalking ? "talking" : "idle"
            return "\(Self.transcriptDateFormatter.string(from: entry.timestamp)) [\(talking)] \(entry.action) | \(entry.routeDescription) | \(entry.activationStatus)"
        }
        return Data(lines.joined(separator: "\n").utf8)
    }

    private func appendWhisperActivationLog(action: String) {
        whisperActivationLog.insert(TS3WhisperActivationLogEntry(
            action: action,
            routeDescription: whisperRouteDescription,
            activationStatus: whisperActivationStatus,
            isTalking: isTalking
        ), at: 0)
        if whisperActivationLog.count > 20 {
            whisperActivationLog.removeLast(whisperActivationLog.count - 20)
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
                    self.resetInputMeter()
                    self.endWhisperActivation()
                    self.microphonePermissionPrompt = .openSettings
                    return
                }

                self.beginTalking(with: client)
            }
        case .openSettings:
            endWhisperActivation()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                TS3PlatformSupport.openMicrophoneSettings()
            }
        }
    }

    func dismissMicrophonePermissionPrompt() {
        appendAudioPermissionLog("prompt", status: "dismissed")
        microphonePermissionPrompt = nil
        endWhisperActivation()
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
                    self.resetInputMeter()
                    self.endWhisperActivation()
                }
            }
        }
    }

    private func resetInputMeter() {
        inputLevel = 0
        isVoiceActivationTriggered = false
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

    private func audioRouteNotes(
        inputDevices: [TS3AudioRouteDeviceSummary],
        inputRoute: String,
        outputRoute: String
    ) -> [String] {
        var notes: [String] = []
        if inputDevices.isEmpty {
            notes.append("No selectable input devices are currently reported; the system default microphone will be used when available.")
        }
        if inputRoute == "System Default" {
            notes.append("Input route is controlled by the current system audio device and microphone permission.")
        }
        if outputRoute == "System Default" {
            notes.append("Output route is controlled by the current system audio device.")
        }
        #if targetEnvironment(macCatalyst)
        notes.append("On Mac Catalyst, detailed input and output device switching may be limited by macOS audio routing.")
        #elseif os(iOS)
        notes.append("On iOS, Bluetooth, receiver, speaker, and accessory availability can change when devices connect or disconnect.")
        #endif
        return notes
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

    func diagnosticReportData() -> Data {
        var sections: [String] = []
        sections.append([
            "TS3 Diagnostic Report",
            "Generated: \(Self.transcriptDateFormatter.string(from: Date()))",
            "State: \(state.title)",
            "Host: \(serverHost.isEmpty ? "Not set" : serverHost)",
            "Port: \(serverPort.isEmpty ? "Not set" : serverPort)",
            "Nickname: \(nickname.isEmpty ? "Not set" : nickname)",
            "Last Error: \(lastError ?? "None")",
            "Last Disconnect: \(lastDisconnectMessage ?? "None")"
        ].joined(separator: "\n"))

        sections.append([
            "Audio",
            "Transmit Mode: \(audioTransmitMode.title)",
            "Talk Status: \(talkStatus)",
            "Input Muted: \(isInputMuted ? "Yes" : "No")",
            "Output Muted: \(isOutputMuted ? "Yes" : "No")",
            "Input Gain: \(inputGainPercentText)",
            "Input Level: \(inputLevelText)",
            "Voice Activation Threshold: \(voiceActivationThresholdText)",
            "Playback Volume: \(playbackVolumePercentText)",
            "Input Route: \(audioInputRoute)",
            "Output Route: \(audioOutputRoute)",
            "Default To Speaker: \(prefersSpeakerOutput ? "Yes" : "No")",
            "Whisper Route: \(whisperRouteDescription)",
            "Whisper Activation Mode: \(whisperActivationMode.title)",
            "Whisper Activation: \(whisperActivationStatus)",
            "Whisper Activation Events: \(whisperActivationLog.count)",
            "Route Availability: \(audioRouteAvailabilityNotes.isEmpty ? "No route limitations reported" : audioRouteAvailabilityNotes.joined(separator: " | "))"
        ].joined(separator: "\n"))

        sections.append([
            "Connection Metrics",
            "Ping: \(connectionInfo.ping.map { "\(Self.decimalText($0)) ms" } ?? "Unknown")",
            "Packet Loss: \(connectionInfo.packetLossTotal.map(Self.percentText) ?? "Unknown")",
            "Speech Loss: \(connectionInfo.packetLossSpeech.map(Self.percentText) ?? "Unknown")",
            "Keepalive Loss: \(connectionInfo.packetLossKeepalive.map(Self.percentText) ?? "Unknown")",
            "Control Loss: \(connectionInfo.packetLossControl.map(Self.percentText) ?? "Unknown")",
            "Session Downloaded: \(connectionInfo.bytesReceived.map(Self.byteText) ?? "Unknown")",
            "Session Uploaded: \(connectionInfo.bytesSent.map(Self.byteText) ?? "Unknown")",
            "Connected Seconds: \(connectionInfo.connectedSeconds.map(String.init) ?? "Unknown")",
            "Idle Seconds: \(connectionInfo.idleSeconds.map(String.init) ?? "Unknown")"
        ].joined(separator: "\n"))

        sections.append([
            "Local State",
            "Channels: \(channels.count)",
            "Clients: \(clients.count)",
            "Bookmarks: \(bookmarks.count)",
            "Contacts: \(contacts.count)",
            "Activity Events: \(activityEvents.count)",
            "Pokes: \(pokeEvents.count)",
            "File Transfers: \(fileTransfers.count)",
            "Debug Log Entries: \(logs.count)"
        ].joined(separator: "\n"))

        sections.append(String(data: debugLogData(), encoding: .utf8).map { "Debug Log\n\($0)" } ?? "Debug Log\n")
        sections.append(String(data: whisperActivationLogData(), encoding: .utf8).map { "Whisper Activation Log\n\($0)" } ?? "Whisper Activation Log\n")
        return Data(sections.joined(separator: "\n\n").utf8)
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

    private static func decimalText(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static func percentText(_ value: Double) -> String {
        String(format: "%.2f%%", value * 100)
    }

    private static func byteText(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
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
                    neededJoinPower: channel.neededJoinPower,
                    neededSubscribePower: channel.neededSubscribePower,
                    neededDescriptionViewPower: channel.neededDescriptionViewPower,
                    codec: channel.codec,
                    codecQuality: channel.codecQuality,
                    codecLatencyFactor: channel.codecLatencyFactor,
                    isCodecUnencrypted: channel.isCodecUnencrypted,
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
                port: info.port,
                clientsInQuery: info.clientsInQuery,
                reservedSlots: info.reservedSlots,
                channelsOnline: info.channelsOnline,
                uptimeSeconds: info.uptimeSeconds,
                welcomeMessage: info.welcomeMessage,
                passwordProtected: info.passwordProtected,
                phoneticName: info.phoneticName,
                status: info.status,
                machineId: info.machineId,
                isAutoStartEnabled: info.isAutoStartEnabled,
                codecEncryptionMode: info.codecEncryptionMode,
                isWeblistEnabled: info.isWeblistEnabled,
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
                antiFloodPointsTickReduce: info.antiFloodPointsTickReduce,
                antiFloodPointsNeededCommandBlock: info.antiFloodPointsNeededCommandBlock,
                antiFloodPointsNeededIPBlock: info.antiFloodPointsNeededIPBlock,
                antiFloodPointsNeededPluginBlock: info.antiFloodPointsNeededPluginBlock,
                isClientLoggingEnabled: info.isClientLoggingEnabled,
                isQueryLoggingEnabled: info.isQueryLoggingEnabled,
                isChannelLoggingEnabled: info.isChannelLoggingEnabled,
                isPermissionLoggingEnabled: info.isPermissionLoggingEnabled,
                isServerLoggingEnabled: info.isServerLoggingEnabled,
                isFileTransferLoggingEnabled: info.isFileTransferLoggingEnabled,
                clientConnections: info.clientConnections,
                queryClientConnections: info.queryClientConnections,
                downloadQuota: info.downloadQuota,
                uploadQuota: info.uploadQuota,
                maxDownloadTotalBandwidth: info.maxDownloadTotalBandwidth,
                maxUploadTotalBandwidth: info.maxUploadTotalBandwidth,
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
                hostBannerMode: info.hostBannerMode,
                hostBannerGraphicsInterval: info.hostBannerGraphicsInterval,
                hostButtonTooltip: info.hostButtonTooltip,
                hostButtonURL: info.hostButtonURL,
                hostButtonGraphicsURL: info.hostButtonGraphicsURL,
                iconId: info.iconId,
                iconURL: info.iconId.flatMap { self.iconURLs[$0] },
                neededIdentitySecurityLevel: info.neededIdentitySecurityLevel,
                minClientVersion: info.minClientVersion,
                minAndroidVersion: info.minAndroidVersion,
                minIOSVersion: info.minIOSVersion
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
            guard !self.isSuppressedMessage(message) else { return }
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
            self.trimChatHistoryToLimit()
            if !message.isOwnMessage && !self.isViewingChat {
                self.unreadChatMessageCount += 1
            }
            if self.privateMessageNotificationsEnabled,
               !message.isOwnMessage,
               message.targetMode == .client,
               !self.isNotificationMuted(senderId: message.senderId, uniqueIdentifier: nil) {
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
            guard !self.isSuppressedPoke(poke) else { return }
            self.pokeEvents.insert(TS3PokeSummary(poke: poke), at: 0)
            if self.pokeEvents.count > 50 {
                self.pokeEvents.removeLast(self.pokeEvents.count - 50)
            }
            self.saveEventHistory()
            self.unreadPokeCount += 1
            if self.pokeNotificationsEnabled,
               !self.isNotificationMuted(senderId: poke.senderId, uniqueIdentifier: poke.senderUniqueIdentifier) {
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
            self.saveEventHistory()
            self.unreadActivityCount += 1
            if self.activityNotificationsEnabled,
               !self.isNotificationMuted(senderId: event.invokerId ?? event.clientId, uniqueIdentifier: nil) {
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
            self.saveGroupResults()
        }
    }

    nonisolated func ts3Client(_ client: TS3Client, didUpdateChannelGroups groups: [TS3ChannelGroup]) {
        Task { @MainActor in
            self.channelGroups = groups.map { TS3GroupSummary(id: $0.id, name: $0.name, type: $0.type) }
            self.saveGroupResults()
        }
    }
}
