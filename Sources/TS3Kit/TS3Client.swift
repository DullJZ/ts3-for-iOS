import Foundation
import Network
import CryptoKit
import BigInt

public final class TS3Client {
    public weak var delegate: TS3ClientDelegate?
    public private(set) var currentChannelId: Int?
    public var logHandler: ((TS3LogEntry) -> Void)?

    private let config: TS3ClientConfig
    private let audioQueueKey = DispatchSpecificKey<Void>()
    private let audioQueue = DispatchQueue(label: "ts3.audio")
    private let connectionQueue = DispatchQueue(label: "ts3.connection")
    private var connection: NWConnection?

    private var identity: TS3Identity?
    private let initTransformation = TS3InitPacketTransformation()
    private var transformation: TS3PacketTransformation = TS3InitPacketTransformation()
    private var allowInitFallbackDecrypt = true

    private var _state: TS3ConnectionState = .disconnected
    private var state: TS3ConnectionState {
        get { _state }
        set {
            log(.debug, "State changing: \(_state.description)")
            _state = newValue
            log(.debug, "State changed: \(newValue.description)")
        }
    }
    private var clientId: UInt16 = 0
    private var serverId: Int?

    private var serverAddress: String {
        "/\(config.host):\(config.port)"
    }

    private var randomBytes: [UInt8] = []
    private var pendingInitIvAlpha: [UInt8]?
    private var pendingInitIvCommand: String?
    private var logSequence: UInt64 = 0

    private var localCounters: [TS3PacketBodyType: TS3LocalCounter] = [:]
    private var remoteCounters: [TS3PacketBodyType: TS3RemoteCounter] = [:]
    private var reassemblyQueues: [TS3PacketBodyType: TS3PacketReassembly] = [:]

    private var sendQueue: [UInt16: TS3PacketResponse] = [:]
    private var sendQueueLow: [UInt16: TS3PacketResponse] = [:]
    private var pingQueue: [UInt16: TS3PacketResponse] = [:]
    private var disconnectTimeoutWorkItem: DispatchWorkItem?
    private var isDisconnecting = false

    private var lastResponse: Date = Date()
    private var lastPing: Date = Date()

    private var pendingCommands: [Int: PendingCommand] = [:]
    private var nextCommandCode: Int = 1

    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var serverInfo: TS3ServerInfo?
    private var channelCache: [Int: TS3Channel] = [:]
    private var clientCache: [UInt16: TS3ServerClient] = [:]
    private var serverGroupCache: [Int: TS3ServerGroup] = [:]
    private var channelGroupCache: [Int: TS3ChannelGroup] = [:]
    private var defaultChannelId: Int?
    private var audioEngine: TS3AudioEngine?
    private var isSendingAudio = false
    private var voiceSessionId: UInt8 = 1
    private var voiceFlaggedPackets: Int = 5
    private var isWhispering = false
    private var whisperTarget: TS3WhisperTarget?
    private var whisperSessionId: UInt8 = 1
    private var whisperFlaggedPackets: Int = 5

    public init(config: TS3ClientConfig) {
        self.config = config
        audioQueue.setSpecific(key: audioQueueKey, value: ())
        setupCounters()
    }

    public func connect() async throws {
        if state != .disconnected { return }

        logSequence = 0
        transformation = initTransformation
        allowInitFallbackDecrypt = true
        clearPendingInitIv(reason: "connect-start")
        randomBytes = []
        clientId = 0
        serverId = nil
        currentChannelId = nil
        serverInfo = nil
        clientCache.removeAll()
        serverGroupCache.removeAll()
        channelGroupCache.removeAll()
        defaultChannelId = nil
        nextCommandCode = 1
        isDisconnecting = false
        disconnectTimeoutWorkItem?.cancel()
        disconnectTimeoutWorkItem = nil

        state = .connecting
        channelCache.removeAll()
        identity = try await loadIdentity()
        log(.debug, "Connecting to \(serverAddress)...")
        if audioEngine == nil {
            do {
                let engine = try TS3AudioEngine(config: .voice)
                engine.onEncodedPacket = { [weak self] data in
                    self?.audioQueue.async { [weak self] in
                        self?.handleEncodedAudioPacket(data)
                    }
                }
                engine.onLog = { [weak self] level, message in
                    self?.log(level, "[AUDIO] \(message)")
                }
                audioEngine = engine
            } catch {
                log(.warning, "audio engine unavailable: \(error.localizedDescription)")
            }
        }
        let host = NWEndpoint.Host(config.host)
        let port = NWEndpoint.Port(integerLiteral: UInt16(config.port))
        let connection = NWConnection(host: host, port: port, using: .udp)
        self.connection = connection

        connection.stateUpdateHandler = { [weak self] newState in
            guard let self else { return }
            if case .failed(let error) = newState {
                self.disconnectInternal(error: error)
            }
        }

        connection.start(queue: connectionQueue)
        receiveLoop()
        startTimers()

        try sendInit1Step0()

        try await withCheckedThrowingContinuation { continuation in
            self.connectContinuation = continuation
        }
    }

    public func disconnect(reason: String) {
        guard state != .disconnected else { return }
        guard !isDisconnecting else { return }

        if state == .connected {
            isDisconnecting = true
            pingQueue.removeAll()
            stopMicrophone()

            let command: TS3SingleCommand
            if reason.isEmpty {
                command = TS3SingleCommand(name: "clientdisconnect")
            } else {
                command = TS3SingleCommand(
                    name: "clientdisconnect",
                    parameters: [
                        TS3CommandSingleParameter(name: "reasonid", value: "8"),
                        TS3CommandSingleParameter(name: "reasonmsg", value: reason)
                    ]
                )
            }

            do {
                try sendCommand(command)
                log(.info, "disconnect requested")
                scheduleDisconnectFallback()
            } catch {
                log(.warning, "clientdisconnect send failed: \(error.localizedDescription)")
                disconnectInternal(error: nil)
            }
            return
        }

        disconnectInternal(error: nil)
    }

    public func joinChannel(channelId: Int, password: String?) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "clid", value: String(clientId)),
            TS3CommandSingleParameter(name: "cid", value: String(channelId))
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "cpw", value: TS3Crypto.hashPassword(password)))
        }

        let command = TS3SingleCommand(name: "clientmove", parameters: params)
        _ = try await execute(command)
        currentChannelId = channelId
        updateClientChannel(clientId: Int(clientId), channelId: channelId)
        publishClients()
        publishChannels()
    }

    public func refreshServerView() async throws {
        try await refreshServerInfo()
        _ = try await execute(TS3SingleCommand(name: "channellist", parameters: [
            TS3CommandOption(name: "topic"),
            TS3CommandOption(name: "flags"),
            TS3CommandOption(name: "voice"),
            TS3CommandOption(name: "limits"),
            TS3CommandOption(name: "icon")
        ]))
        _ = try await execute(TS3SingleCommand(name: "clientlist", parameters: [
            TS3CommandOption(name: "uid"),
            TS3CommandOption(name: "away"),
            TS3CommandOption(name: "voice"),
            TS3CommandOption(name: "groups")
        ]))
        publishChannels()
        publishClients()
    }

    public func refreshServerInfo() async throws {
        let responses = try await execute(TS3SingleCommand(name: "serverinfo"))
        for response in responses {
            if let info = serverInfo(from: response) {
                serverInfo = info
                publishServerInfo(info)
            }
        }
    }

    public func editServer(_ edit: TS3ServerEdit) async throws {
        var params: [TS3CommandParameter] = []
        appendParameter(&params, name: "virtualserver_name", value: edit.name)
        appendParameter(&params, name: "virtualserver_welcomemessage", value: edit.welcomeMessage)
        appendParameter(&params, name: "virtualserver_maxclients", value: edit.maxClients.map(String.init))
        appendParameter(&params, name: "virtualserver_reserved_slots", value: edit.reservedSlots.map(String.init))
        appendParameter(&params, name: "virtualserver_password", value: edit.password)
        appendParameter(&params, name: "virtualserver_hostmessage", value: edit.hostMessage)
        appendParameter(&params, name: "virtualserver_hostmessage_mode", value: edit.hostMessageMode.map(String.init))
        appendParameter(&params, name: "virtualserver_hostbanner_url", value: edit.hostBannerURL)
        appendParameter(&params, name: "virtualserver_hostbanner_gfx_url", value: edit.hostBannerGraphicsURL)
        appendParameter(&params, name: "virtualserver_hostbutton_tooltip", value: edit.hostButtonTooltip)
        appendParameter(&params, name: "virtualserver_hostbutton_url", value: edit.hostButtonURL)
        appendParameter(&params, name: "virtualserver_hostbutton_gfx_url", value: edit.hostButtonGraphicsURL)
        guard !params.isEmpty else { return }
        _ = try await execute(TS3SingleCommand(name: "serveredit", parameters: params))
        try await refreshServerInfo()
    }

    public func refreshClientDetails(clientId targetClientId: Int) async throws -> TS3ServerClient? {
        let responses = try await execute(TS3SingleCommand(name: "clientinfo", parameters: [
            TS3CommandSingleParameter(name: "clid", value: String(targetClientId))
        ]))
        var lastUpdated: TS3ServerClient?
        for response in responses {
            if let updated = mergeDetailedClientInfo(response, fallbackClientId: targetClientId) {
                clientCache[UInt16(updated.id)] = updated
                lastUpdated = updated
            }
        }
        publishClients()
        return lastUpdated
    }

    public func refreshClientDatabase(start: Int = 0, duration: Int = 100) async throws -> [TS3DatabaseClient] {
        let responses = try await execute(TS3SingleCommand(name: "clientdblist", parameters: [
            TS3CommandSingleParameter(name: "start", value: String(start)),
            TS3CommandSingleParameter(name: "duration", value: String(duration))
        ]))
        return responses.compactMap { databaseClient(from: $0) }
    }

    public func databaseClientInfo(clientDatabaseId: Int) async throws -> TS3DatabaseClient? {
        let responses = try await execute(TS3SingleCommand(name: "clientdbinfo", parameters: [
            TS3CommandSingleParameter(name: "cldbid", value: String(clientDatabaseId))
        ]))
        return responses.compactMap { databaseClient(from: $0, fallbackDatabaseId: clientDatabaseId) }.first
    }

    public func findDatabaseClients(pattern: String) async throws -> [TS3DatabaseClient] {
        let responses = try await execute(TS3SingleCommand(name: "clientdbfind", parameters: [
            TS3CommandSingleParameter(name: "pattern", value: pattern)
        ]))
        return responses.compactMap { databaseClient(from: $0) }
    }

    public func onlineClientIds(forNamePattern pattern: String) async throws -> [TS3ClientLocation] {
        let responses = try await execute(TS3SingleCommand(name: "clientfind", parameters: [
            TS3CommandSingleParameter(name: "pattern", value: pattern)
        ]))
        return responses.compactMap { clientLocation(from: $0) }
    }

    public func onlineClientIds(forUniqueIdentifier uniqueIdentifier: String) async throws -> [TS3ClientLocation] {
        let responses = try await execute(TS3SingleCommand(name: "clientgetids", parameters: [
            TS3CommandSingleParameter(name: "cluid", value: uniqueIdentifier)
        ]))
        return responses.compactMap { clientLocation(from: $0) }
    }

    public func databaseId(forUniqueIdentifier uniqueIdentifier: String) async throws -> Int? {
        let responses = try await execute(TS3SingleCommand(name: "clientgetdbidfromuid", parameters: [
            TS3CommandSingleParameter(name: "cluid", value: uniqueIdentifier)
        ]))
        return responses.compactMap { intValue($0, "cldbid") }.first
    }

    public func sendTextMessage(_ message: String, targetMode: TS3TextMessageTargetMode, targetId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "sendtextmessage", parameters: [
            TS3CommandSingleParameter(name: "targetmode", value: String(targetMode.rawValue)),
            TS3CommandSingleParameter(name: "target", value: String(targetId)),
            TS3CommandSingleParameter(name: "msg", value: message)
        ]))
        let local = TS3TextMessage(
            timestamp: Date(),
            targetMode: targetMode,
            targetId: targetId,
            senderId: Int(clientId),
            senderName: config.nickname,
            message: message,
            isOwnMessage: true
        )
        DispatchQueue.main.async {
            self.delegate?.ts3Client(self, didReceiveTextMessage: local)
        }
    }

    public func refreshOfflineMessages() async throws -> [TS3OfflineMessage] {
        let responses = try await execute(TS3SingleCommand(name: "messagelist"))
        return responses.compactMap { offlineMessage(from: $0, detailedMessage: nil) }
    }

    public func offlineMessage(messageId: Int) async throws -> TS3OfflineMessage? {
        let responses = try await execute(TS3SingleCommand(name: "messageget", parameters: [
            TS3CommandSingleParameter(name: "msgid", value: String(messageId))
        ]))
        return responses.compactMap { offlineMessage(from: $0, detailedMessage: $0.get("message")?.value) }.first
    }

    public func sendOfflineMessage(toUniqueIdentifier uniqueIdentifier: String, subject: String, message: String) async throws {
        _ = try await execute(TS3SingleCommand(name: "messageadd", parameters: [
            TS3CommandSingleParameter(name: "cluid", value: uniqueIdentifier),
            TS3CommandSingleParameter(name: "subject", value: subject),
            TS3CommandSingleParameter(name: "message", value: message)
        ]))
    }

    public func deleteOfflineMessage(messageId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "messagedel", parameters: [
            TS3CommandSingleParameter(name: "msgid", value: String(messageId))
        ]))
    }

    public func setOfflineMessageRead(messageId: Int, isRead: Bool) async throws {
        _ = try await execute(TS3SingleCommand(name: "messageupdateflag", parameters: [
            TS3CommandSingleParameter(name: "msgid", value: String(messageId)),
            TS3CommandSingleParameter(name: "flag", value: isRead ? "1" : "0")
        ]))
    }

    public func updateNickname(_ nickname: String) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientupdate", parameters: [
            TS3CommandSingleParameter(name: "client_nickname", value: nickname)
        ]))
        if let existing = clientCache[clientId] {
            clientCache[clientId] = copyClient(existing, nickname: nickname)
            publishClients()
        }
    }

    public func setAway(_ isAway: Bool, message: String?) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientupdate", parameters: [
            TS3CommandSingleParameter(name: "client_away", value: isAway ? "1" : "0"),
            TS3CommandSingleParameter(name: "client_away_message", value: isAway ? (message ?? "") : "")
        ]))
        if let existing = clientCache[clientId] {
            clientCache[clientId] = copyClient(existing, isAway: isAway, awayMessage: isAway ? message : nil)
            publishClients()
        }
    }

    public func setInputMuted(_ isMuted: Bool) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientupdate", parameters: [
            TS3CommandSingleParameter(name: "client_input_muted", value: isMuted ? "1" : "0")
        ]))
        if let existing = clientCache[clientId] {
            clientCache[clientId] = copyClient(existing, isInputMuted: isMuted)
            publishClients()
        }
    }

    public func setOutputMuted(_ isMuted: Bool) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientupdate", parameters: [
            TS3CommandSingleParameter(name: "client_output_muted", value: isMuted ? "1" : "0")
        ]))
        if let existing = clientCache[clientId] {
            clientCache[clientId] = copyClient(existing, isOutputMuted: isMuted)
            publishClients()
        }
    }

    public func createChannel(name: String, parentId: Int?, password: String?, permanent: Bool) async throws -> Int? {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "channel_name", value: name)
        ]
        if let parentId {
            params.append(TS3CommandSingleParameter(name: "cpid", value: String(parentId)))
        }
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "channel_password", value: password))
        }
        params.append(TS3CommandSingleParameter(name: permanent ? "channel_flag_permanent" : "channel_flag_semi_permanent", value: "1"))

        let responses = try await execute(TS3SingleCommand(name: "channelcreate", parameters: params))
        let createdId = responses.compactMap { $0.get("cid")?.value }.compactMap(Int.init).first
        try? await refreshServerView()
        return createdId
    }

    public func editChannel(channelId: Int, name: String?, topic: String?, description: String?, password: String?) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "cid", value: String(channelId))
        ]
        if let name { params.append(TS3CommandSingleParameter(name: "channel_name", value: name)) }
        if let topic { params.append(TS3CommandSingleParameter(name: "channel_topic", value: topic)) }
        if let description { params.append(TS3CommandSingleParameter(name: "channel_description", value: description)) }
        if let password { params.append(TS3CommandSingleParameter(name: "channel_password", value: password)) }
        _ = try await execute(TS3SingleCommand(name: "channeledit", parameters: params))
        try? await refreshServerView()
    }

    public func deleteChannel(channelId: Int, force: Bool) async throws {
        _ = try await execute(TS3SingleCommand(name: "channeldelete", parameters: [
            TS3CommandSingleParameter(name: "cid", value: String(channelId)),
            TS3CommandSingleParameter(name: "force", value: force ? "1" : "0")
        ]))
        channelCache.removeValue(forKey: channelId)
        publishChannels()
    }

    public func moveClient(clientId targetClientId: Int, to channelId: Int, password: String?) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "clid", value: String(targetClientId)),
            TS3CommandSingleParameter(name: "cid", value: String(channelId))
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "cpw", value: TS3Crypto.hashPassword(password)))
        }
        _ = try await execute(TS3SingleCommand(name: "clientmove", parameters: params))
        updateClientChannel(clientId: targetClientId, channelId: channelId)
        publishClients()
    }

    public func kickClient(clientId targetClientId: Int, reason: TS3KickReason, message: String?) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientkick", parameters: [
            TS3CommandSingleParameter(name: "clid", value: String(targetClientId)),
            TS3CommandSingleParameter(name: "reasonid", value: String(reason.rawValue)),
            TS3CommandSingleParameter(name: "reasonmsg", value: message ?? "")
        ]))
    }

    public func banClient(clientId targetClientId: Int, durationSeconds: Int?, message: String?) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "clid", value: String(targetClientId)),
            TS3CommandSingleParameter(name: "banreason", value: message ?? "")
        ]
        if let durationSeconds {
            params.append(TS3CommandSingleParameter(name: "time", value: String(durationSeconds)))
        }
        _ = try await execute(TS3SingleCommand(name: "banclient", parameters: params))
    }

    public func refreshBanList() async throws -> [TS3BanEntry] {
        let responses = try await execute(TS3SingleCommand(name: "banlist"))
        return responses.compactMap { banEntry(from: $0) }
    }

    public func deleteBan(banId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "deleteban", parameters: [
            TS3CommandSingleParameter(name: "banid", value: String(banId))
        ]))
    }

    public func deleteAllBans() async throws {
        _ = try await execute(TS3SingleCommand(name: "bandelall"))
    }

    public func addComplaint(clientDatabaseId: Int, message: String) async throws {
        _ = try await execute(TS3SingleCommand(name: "complainadd", parameters: [
            TS3CommandSingleParameter(name: "tcldbid", value: String(clientDatabaseId)),
            TS3CommandSingleParameter(name: "message", value: message)
        ]))
    }

    public func refreshComplaints(clientDatabaseId: Int) async throws -> [TS3ComplaintEntry] {
        let responses = try await execute(TS3SingleCommand(name: "complainlist", parameters: [
            TS3CommandSingleParameter(name: "tcldbid", value: String(clientDatabaseId))
        ]))
        return responses.compactMap { complaintEntry(from: $0, fallbackTargetClientDatabaseId: clientDatabaseId) }
    }

    public func deleteComplaint(targetClientDatabaseId: Int, sourceClientDatabaseId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "complaindel", parameters: [
            TS3CommandSingleParameter(name: "tcldbid", value: String(targetClientDatabaseId)),
            TS3CommandSingleParameter(name: "fcldbid", value: String(sourceClientDatabaseId))
        ]))
    }

    public func deleteAllComplaints(clientDatabaseId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "complaindelall", parameters: [
            TS3CommandSingleParameter(name: "tcldbid", value: String(clientDatabaseId))
        ]))
    }

    public func pokeClient(clientId targetClientId: Int, message: String) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientpoke", parameters: [
            TS3CommandSingleParameter(name: "clid", value: String(targetClientId)),
            TS3CommandSingleParameter(name: "msg", value: message)
        ]))
    }

    public func refreshGroups() async throws {
        let serverGroups = try await execute(TS3SingleCommand(name: "servergrouplist"))
        serverGroupCache = Dictionary(uniqueKeysWithValues: serverGroups.compactMap { command in
            guard let idText = command.get("sgid")?.value, let id = Int(idText),
                  let name = command.get("name")?.value else { return nil }
            return (id, TS3ServerGroup(id: id, name: name))
        })
        let channelGroups = try await execute(TS3SingleCommand(name: "channelgrouplist"))
        channelGroupCache = Dictionary(uniqueKeysWithValues: channelGroups.compactMap { command in
            guard let idText = command.get("cgid")?.value, let id = Int(idText),
                  let name = command.get("name")?.value else { return nil }
            return (id, TS3ChannelGroup(id: id, name: name))
        })
        publishGroups()
    }

    public func refreshPermissionList() async throws -> [TS3PermissionInfo] {
        let responses = try await execute(TS3SingleCommand(name: "permissionlist"))
        return responses.compactMap { permissionInfo(from: $0) }
    }

    public func refreshClientPermissions(clientDatabaseId: Int) async throws -> [TS3Permission] {
        let responses = try await execute(TS3SingleCommand(name: "clientpermlist", parameters: [
            TS3CommandSingleParameter(name: "cldbid", value: String(clientDatabaseId)),
            TS3CommandOption(name: "permsid")
        ]))
        return responses.compactMap { permission(from: $0) }
    }

    public func addClientPermission(clientDatabaseId: Int, permissionName: String, value: Int, skip: Bool = false) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientaddperm", parameters: [
            TS3CommandSingleParameter(name: "cldbid", value: String(clientDatabaseId)),
            TS3CommandSingleParameter(name: "permsid", value: permissionName),
            TS3CommandSingleParameter(name: "permvalue", value: String(value)),
            TS3CommandSingleParameter(name: "permskip", value: skip ? "1" : "0")
        ]))
    }

    public func deleteClientPermission(clientDatabaseId: Int, permissionName: String) async throws {
        _ = try await execute(TS3SingleCommand(name: "clientdelperm", parameters: [
            TS3CommandSingleParameter(name: "cldbid", value: String(clientDatabaseId)),
            TS3CommandSingleParameter(name: "permsid", value: permissionName)
        ]))
    }

    public func refreshFileList(channelId: Int, path: String, password: String? = nil) async throws -> [TS3FileEntry] {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "cid", value: String(channelId)),
            TS3CommandSingleParameter(name: "path", value: path)
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "cpw", value: TS3Crypto.hashPassword(password)))
        }
        let responses = try await execute(TS3SingleCommand(name: "ftgetfilelist", parameters: params))
        return responses.compactMap { fileEntry(from: $0, channelId: channelId, parentPath: path) }
    }

    public func createFileDirectory(channelId: Int, path: String, password: String? = nil) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "cid", value: String(channelId)),
            TS3CommandSingleParameter(name: "dirname", value: path)
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "cpw", value: TS3Crypto.hashPassword(password)))
        }
        _ = try await execute(TS3SingleCommand(name: "ftcreatedir", parameters: params))
    }

    public func deleteFile(channelId: Int, path: String, password: String? = nil) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "cid", value: String(channelId)),
            TS3CommandSingleParameter(name: "name", value: path)
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "cpw", value: TS3Crypto.hashPassword(password)))
        }
        _ = try await execute(TS3SingleCommand(name: "ftdeletefile", parameters: params))
    }

    public func renameFile(channelId: Int, oldPath: String, newPath: String, password: String? = nil) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "cid", value: String(channelId)),
            TS3CommandSingleParameter(name: "oldname", value: oldPath),
            TS3CommandSingleParameter(name: "newname", value: newPath)
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "cpw", value: TS3Crypto.hashPassword(password)))
        }
        _ = try await execute(TS3SingleCommand(name: "ftrenamefile", parameters: params))
    }

    public func addServerGroup(groupId: Int, toClientDatabaseId clientDatabaseId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "servergroupaddclient", parameters: [
            TS3CommandSingleParameter(name: "sgid", value: String(groupId)),
            TS3CommandSingleParameter(name: "cldbid", value: String(clientDatabaseId))
        ]))
    }

    public func removeServerGroup(groupId: Int, fromClientDatabaseId clientDatabaseId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "servergroupdelclient", parameters: [
            TS3CommandSingleParameter(name: "sgid", value: String(groupId)),
            TS3CommandSingleParameter(name: "cldbid", value: String(clientDatabaseId))
        ]))
    }

    public func setChannelGroup(groupId: Int, channelId: Int, clientDatabaseId: Int) async throws {
        _ = try await execute(TS3SingleCommand(name: "setclientchannelgroup", parameters: [
            TS3CommandSingleParameter(name: "cgid", value: String(groupId)),
            TS3CommandSingleParameter(name: "cid", value: String(channelId)),
            TS3CommandSingleParameter(name: "cldbid", value: String(clientDatabaseId))
        ]))
    }

    public func usePrivilegeKey(_ key: String) async throws {
        _ = try await execute(TS3SingleCommand(name: "privilegekeyuse", parameters: [
            TS3CommandSingleParameter(name: "token", value: key)
        ]))
        try? await refreshGroups()
    }

    public func identitySnapshot() async throws -> TS3IdentitySnapshot {
        let identity = try await loadIdentity()
        return TS3IdentitySnapshot(
            uid: identity.uid.toBase64(),
            securityLevel: identity.securityLevel(),
            keyOffset: identity.keyOffset,
            exportString: try identityExportString(for: identity)
        )
    }

    public func importIdentity(exportString: String) async throws -> TS3IdentitySnapshot {
        guard state == .disconnected else {
            throw TS3Error.invalidState
        }
        let identity = try identity(fromExportString: exportString)
        try saveIdentity(identity)
        self.identity = identity
        return TS3IdentitySnapshot(
            uid: identity.uid.toBase64(),
            securityLevel: identity.securityLevel(),
            keyOffset: identity.keyOffset,
            exportString: try identityExportString(for: identity)
        )
    }

    public func startMicrophone() throws {
        guard state == .connected else {
            throw TS3Error.invalidState
        }
        guard audioEngine != nil else {
            throw TS3Error.notImplemented
        }

        voiceFlaggedPackets = 5
        isSendingAudio = true
        do {
            try withAudioQueueSync {
                try audioEngine?.startCapture()
            }
            log(.info, "microphone capture started")
        } catch {
            isSendingAudio = false
            throw error
        }
    }

    public func stopMicrophone() {
        guard isSendingAudio else {
            withAudioQueueSync {
                audioEngine?.stopCapture()
            }
            return
        }

        isSendingAudio = false
        if isWhispering, let target = whisperTarget {
            let whisper = TS3PacketBodyVoiceWhisper(
                role: .client,
                packetId: 0,
                clientId: nil,
                codecType: 4,
                target: target,
                codecData: Data(),
                serverFlag0: nil
            )
            _ = try? sendPacket(body: whisper)
            whisperFlaggedPackets = 5
            whisperSessionId = whisperSessionId == 7 ? 1 : whisperSessionId + 1
        } else {
            let voice = TS3PacketBodyVoice(
                role: .client,
                packetId: 0,
                clientId: nil,
                codecType: 4,
                codecData: Data(),
                serverFlag0: nil
            )
            _ = try? sendPacket(body: voice)
            voiceFlaggedPackets = 5
            voiceSessionId = voiceSessionId == 7 ? 1 : voiceSessionId + 1
        }
        withAudioQueueSync {
            audioEngine?.stopCapture()
        }
        log(.info, "microphone capture stopped")
    }

    public func setPlaybackVolume(_ volume: Float) {
        let clamped = min(max(volume, 0), 4)
        withAudioQueueSync {
            audioEngine?.setPlaybackVolume(clamped)
        }
        log(.info, "playback volume set to \(Int((clamped * 100).rounded()))%")
    }

    public func startWhisper(target: TS3WhisperTarget) {
        whisperTarget = target
        isWhispering = true
        whisperFlaggedPackets = 5
        log(.info, "whisper enabled")
    }

    public func stopWhisper() {
        isWhispering = false
        whisperTarget = nil
        whisperFlaggedPackets = 5
        log(.info, "whisper disabled")
    }

    public func startWhisperToChannel(_ channelId: Int) {
        startWhisper(target: .channel(channelId))
    }

    public func startWhisperToClient(_ clientId: Int) {
        startWhisper(target: .client(clientId))
    }

    public func startWhisperToServer() {
        startWhisper(target: .server())
    }
}

// MARK: - Connection
private extension TS3Client {
    func withAudioQueueSync<T>(_ work: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: audioQueueKey) != nil {
            return try work()
        }

        return try audioQueue.sync(execute: work)
    }

    func handleEncodedAudioPacket(_ data: Data) {
        guard state == .connected else { return }
        guard isSendingAudio else { return }

        if isWhispering, let target = whisperTarget {
            let flag: UInt8? = whisperFlaggedPackets > 0 ? whisperSessionId : nil
            if whisperFlaggedPackets > 0 {
                whisperFlaggedPackets -= 1
            }
            let whisper = TS3PacketBodyVoiceWhisper(
                role: .client,
                packetId: 0,
                clientId: nil,
                codecType: 4,
                target: target,
                codecData: data,
                serverFlag0: flag
            )
            _ = try? sendPacket(body: whisper)
        } else {
            let flag: UInt8? = voiceFlaggedPackets > 0 ? voiceSessionId : nil
            if voiceFlaggedPackets > 0 {
                voiceFlaggedPackets -= 1
            }
            let voice = TS3PacketBodyVoice(
                role: .client,
                packetId: 0,
                clientId: nil,
                codecType: 4,
                codecData: data,
                serverFlag0: flag
            )
            _ = try? sendPacket(body: voice)
        }
    }

    func setupCounters() {
        TS3PacketBodyType.allCases.forEach { type in
            if type == .init1 {
                localCounters[type] = TS3LocalCounterZero()
                remoteCounters[type] = TS3RemoteCounterZero()
            } else {
                localCounters[type] = TS3LocalCounterFull(generationSize: 65536, counting: true)
                remoteCounters[type] = TS3RemoteCounterFull(generationSize: 65536, windowSize: 100)
            }
            if type.isSplittable {
                reassemblyQueues[type] = TS3PacketReassembly()
            }
        }
    }

    func receiveLoop() {
        connection?.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let data {
                self.handleDatagram(data)
            }
            if let error {
                self.disconnectInternal(error: error)
                return
            }
            self.receiveLoop()
        }
    }

    func startTimers() {
        Task.detached { [weak self] in
            while let self {
                try await Task.sleep(nanoseconds: 500_000_000)
                self.resendPendingPackets()
                self.sendPingIfNeeded()
            }
        }
    }

    func resendPendingPackets() {
        let now = Date()
        for id in sendQueue.keys {
            guard var response = sendQueue[id], response.shouldResend(now: now) else { continue }
            log(.debug, "[RESEND] COMMAND id=\(id) retry=\(response.retries + 1)")
            sendRaw(data: response.datagram)
            response.didResend()
            sendQueue[id] = response
        }
        for id in sendQueueLow.keys {
            guard var response = sendQueueLow[id], response.shouldResend(now: now) else { continue }
            log(.debug, "[RESEND] COMMAND_LOW id=\(id) retry=\(response.retries + 1)")
            sendRaw(data: response.datagram)
            response.didResend()
            sendQueueLow[id] = response
        }
        guard !isDisconnecting else { return }
        for id in pingQueue.keys {
            guard var response = pingQueue[id], response.shouldResend(now: now) else { continue }
            log(.debug, "[RESEND] PING id=\(id) retry=\(response.retries + 1)")
            sendRaw(data: response.datagram)
            response.didResend()
            pingQueue[id] = response
        }
    }

    func sendPingIfNeeded() {
        guard state == .connected, !isDisconnecting else { return }
        if Date().timeIntervalSince(lastResponse) > 30 {
            disconnectInternal(error: TS3Error.timeout)
            return
        }
        if Date().timeIntervalSince(lastPing) >= 1.0 {
            let ping = TS3PacketBodyPing(role: .client)
            try? sendPacket(body: ping)
            lastPing = Date()
        }
    }

    func sendRaw(data: Data) {
        connection?.send(content: data, completion: .contentProcessed { _ in })
    }

    func scheduleDisconnectFallback() {
        disconnectTimeoutWorkItem?.cancel()
        let workItem = DispatchWorkItem { [self] in
            if self.state != .disconnected {
                self.log(.warning, "disconnect fallback fired")
                self.disconnectInternal(error: nil)
            }
        }
        disconnectTimeoutWorkItem = workItem
        connectionQueue.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }

    func disconnectInternal(error: Error?) {
        disconnectTimeoutWorkItem?.cancel()
        disconnectTimeoutWorkItem = nil
        isDisconnecting = false
        connection?.cancel()
        connection = nil
        audioEngine?.stop()
        state = .disconnected
        sendQueue.removeAll()
        sendQueueLow.removeAll()
        pingQueue.removeAll()
        pendingCommands.removeAll()
        channelCache.removeAll()
        clientCache.removeAll()
        defaultChannelId = nil
        transformation = initTransformation
        allowInitFallbackDecrypt = true
        clearPendingInitIv(reason: "disconnect")
        randomBytes = []
        if let error {
            log(.error, "disconnected: \(error.localizedDescription)")
        } else {
            log(.warning, "disconnected")
        }
        connectContinuation?.resume(throwing: error ?? TS3Error.disconnected)
        connectContinuation = nil

        DispatchQueue.main.async {
            self.delegate?.ts3Client(self, didDisconnectWith: error)
        }
    }
}

// MARK: - Handshake
private extension TS3Client {
    func sendInit1Step0() throws {
        randomBytes = (0..<4).map { _ in UInt8.random(in: 0...255) }
        let timestamp = UInt32(Date().timeIntervalSince1970)
        var tsBytes = [UInt8](repeating: 0, count: 4)
        tsBytes[0] = UInt8((timestamp >> 24) & 0xFF)
        tsBytes[1] = UInt8((timestamp >> 16) & 0xFF)
        tsBytes[2] = UInt8((timestamp >> 8) & 0xFF)
        tsBytes[3] = UInt8(timestamp & 0xFF)

        let step = TS3Init1Step0(timestamp: tsBytes, random: randomBytes)
        let body = TS3PacketBodyInit1(role: .client, version: [0x0C, 0xFF, 0xD2, 0xFE], step: step)
        try sendPacket(body: body)
    }

    func handleInit1(_ body: TS3PacketBodyInit1) throws {
        switch body.step {
        case let step as TS3Init1Step1:
            log(.debug, "Handle Init1 step 1")
            let serverStuffHex = step.serverStuff.map { String(format: "%02X", $0) }.joined()
            log(.debug, "Init1 Step1 serverStuff=\(serverStuffHex)")

            for i in 0..<4 where randomBytes[3 - i] != step.a0reversed[i] {
                log(.warning, "[WARNING] random byte mismatch!")
                break
            }

            let reply = TS3Init1Step2(serverStuff: step.serverStuff, a0reversed: step.a0reversed)
            let packet = TS3PacketBodyInit1(role: .client, version: [0x0C, 0xFF, 0xD2, 0xFE], step: reply)
            try sendPacket(body: packet)

        case let step as TS3Init1Step3:
            log(.debug, "Handle Init1 step 3")
            let serverStuffHex = step.serverStuff.map { String(format: "%02X", $0) }.joined()
            log(.debug, "Init1 Step3 serverStuff=\(serverStuffHex)")
            log(.debug, "[HANDSHAKE] step3 pendingInitIv hasAlpha=\(pendingInitIvAlpha != nil) hasCommand=\(pendingInitIvCommand != nil)")

            guard step.level >= 0 && step.level <= 1_000_000 else {
                throw TS3Error.invalidInitStep
            }

            let x = BigUInt(Data(step.x))
            let n = BigUInt(Data(step.n))
            let exponent = BigUInt(2).power(step.level)
            let y = x.power(exponent, modulus: n)

            var yBytes = [UInt8](y.serialize())
            if yBytes.count < 64 {
                yBytes = [UInt8](repeating: 0, count: 64 - yBytes.count) + yBytes
            } else if yBytes.count > 64 {
                yBytes = Array(yBytes.suffix(64))
            }

            let initiv = try createInitIv()
            log(.debug, "[HANDSHAKE] step4 yLen=\(yBytes.count) y=\(hexString(yBytes))")
            log(.debug, "[HANDSHAKE] step4 clientinitiv len=\(initiv.utf8.count) text=\(initiv)")
            log(.debug, "[HANDSHAKE] step4 clientinitiv hex=\(hexString([UInt8](initiv.utf8), maxBytes: 160))")

            let reply = TS3Init1Step4(
                x: step.x,
                n: step.n,
                level: step.level,
                serverStuff: step.serverStuff,
                y: yBytes,
                clientIVCommand: [UInt8](initiv.utf8)
            )
            let packet = TS3PacketBodyInit1(role: .client, version: [0x0C, 0xFF, 0xD2, 0xFE], step: reply)
            try sendPacket(body: packet)

        case _ as TS3Init1Step127:
            log(.warning, "init1 retry requested")
            clearPendingInitIv(reason: "init1-step127")
            try sendInit1Step0()

        default:
            throw TS3Error.invalidInitStep
        }
    }

    func createInitIv() throws -> String {
        if let pendingInitIvCommand, let pendingInitIvAlpha {
            log(.debug, "[HANDSHAKE] createInitIv reusing pending alpha for repeated step3")
            log(.debug, "[HANDSHAKE] createInitIv alpha=\(base64String(pendingInitIvAlpha)) alphaHex=\(hexString(pendingInitIvAlpha)) ip=\(resolveInitIvIp() ?? "<nil>")")
            log(.debug, "[HANDSHAKE] createInitIv command len=\(pendingInitIvCommand.utf8.count) text=\(pendingInitIvCommand)")
            log(.debug, "[HANDSHAKE] createInitIv command hex=\(hexString([UInt8](pendingInitIvCommand.utf8), maxBytes: 160))")
            return pendingInitIvCommand
        }
        guard let identity else {
            throw TS3Error.invalidIdentity
        }
        let alpha = (0..<10).map { _ in UInt8.random(in: 0...255) }
        let ip = resolveInitIvIp()

        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "alpha", value: Data(alpha).base64EncodedString()),
            TS3CommandSingleParameter(name: "omega", value: identity.publicKeyString),
            TS3CommandSingleParameter(name: "ot", value: "1")
        ]

        if let ip {
            params.append(TS3CommandSingleParameter(name: "ip", value: ip))
        }

        let command = TS3SingleCommand(name: "clientinitiv", parameters: params)
        let built = command.build()
        pendingInitIvAlpha = alpha
        pendingInitIvCommand = built
        log(.debug, "[HANDSHAKE] createInitIv stored pending alpha len=\(alpha.count) commandLen=\(built.utf8.count)")
        let omegaBytes = [UInt8](Data(base64Encoded: identity.publicKeyString) ?? Data())
        log(.debug, "[HANDSHAKE] createInitIv alpha=\(base64String(alpha)) alphaHex=\(hexString(alpha)) ip=\(ip ?? "<nil>")")
        log(.debug, "[HANDSHAKE] createInitIv identity uid=\(identity.uid.toBase64()) pubkeyBase64Len=\(identity.publicKeyString.count) pubkeyDerLen=\(omegaBytes.count)")
        log(.debug, "[HANDSHAKE] createInitIv command len=\(built.utf8.count) text=\(built)")
        log(.debug, "[HANDSHAKE] createInitIv command hex=\(hexString([UInt8](built.utf8), maxBytes: 160))")
        return built
    }

    func resolveInitIvIp() -> String? {
        if let endpoint = connection?.currentPath?.remoteEndpoint,
           case let .hostPort(host, _) = endpoint {
            let hostString = String(describing: host)
            if isIpLiteral(hostString) {
                return hostString
            }
        }

        if isIpLiteral(config.host) {
            return config.host
        }

        return nil
    }

    func isIpLiteral(_ value: String) -> Bool {
        if value.range(of: #"^[0-9.]+$"#, options: .regularExpression) != nil {
            return true
        }
        return value.contains(":")
    }

    func handleInitCommand(_ command: TS3SingleCommand) throws {
        guard let identity else {
            throw TS3Error.invalidIdentity
        }

        if command.name == "initivexpand" {
            guard let alpha = command.get("alpha")?.value,
                  let beta = command.get("beta")?.value,
                  let omega = command.get("omega")?.value else {
                throw TS3Error.invalidCommand
            }

            let alphaBytes = [UInt8](Data(base64Encoded: alpha) ?? Data())
            let betaBytes = [UInt8](Data(base64Encoded: beta) ?? Data())
            let omegaBytes = [UInt8](Data(base64Encoded: omega) ?? Data())

            let params = try TS3Crypto.cryptoInit(alpha: alphaBytes, beta: betaBytes, omega: omegaBytes, identity: identity)
            transformation = TS3PacketTransformation(ivStruct: params.ivStruct, fakeMac: params.fakeMac)

            try sendClientInit()
            state = .retrieving
            log(.info, "clientinit sent")

        } else if command.name == "initivexpand2" {
            let l = command.get("l")?.value ?? ""
            let beta = command.get("beta")?.value ?? ""
            let omega = command.get("omega")?.value ?? ""
            let ot = command.get("ot")?.value ?? ""
            let proof = command.get("proof")?.value ?? ""
            let time = Int(Date().timeIntervalSince1970)
            log(.debug, "initivexpand2 l=\(l) beta=\(beta) omega=\(omega) ot=\(ot) proof=\(proof)  time=\(time)")

            guard let license = command.get("l")?.value,
                  let beta = command.get("beta")?.value,
                  let omega = command.get("omega")?.value,
                  let proof = command.get("proof")?.value,
                  command.get("ot")?.value == "1" else {
                throw TS3Error.invalidCommand
            }

            let licenseBytes = [UInt8](Data(base64Encoded: license) ?? Data())
            let betaBytes = [UInt8](Data(base64Encoded: beta) ?? Data())
            let omegaBytes = [UInt8](Data(base64Encoded: omega) ?? Data())
            let proofBytes = [UInt8](Data(base64Encoded: proof) ?? Data())

            if try !TS3Crypto.verifySignature(publicKey: omegaBytes, data: licenseBytes, signature: proofBytes) {
                throw TS3Error.cryptoFailed
            }

            let alpha = pendingInitIvAlpha ?? []
            log(.debug, "[HANDSHAKE] initivexpand2 pendingInitIv hasAlpha=\(pendingInitIvAlpha != nil) hasCommand=\(pendingInitIvCommand != nil)")
            log(.debug, "[HANDSHAKE] initivexpand2 alpha=\(base64String(alpha)) licenseLen=\(licenseBytes.count) betaLen=\(betaBytes.count) omegaLen=\(omegaBytes.count) proofLen=\(proofBytes.count)")

            var ekPrivate = (0..<32).map { _ in UInt8.random(in: 0...255) }
            TS3Ed25519.clamp(&ekPrivate)
            let ekPublic = try TS3Ed25519.scalarMultBase(privateKey: ekPrivate)

            let signature = try TS3Crypto.generateClientEkProof(key: ekPublic, beta: betaBytes, identity: identity)
            let identityPublicKey = [UInt8](Data(base64Encoded: identity.publicKeyString) ?? Data())
            let localProofValid = try TS3Crypto.verifyClientEkProof(
                key: ekPublic,
                beta: betaBytes,
                signature: signature,
                publicKey: identityPublicKey
            )

            let ekCommand = TS3SingleCommand(
                name: "clientek",
                parameters: [
                    TS3CommandSingleParameter(name: "ek", value: Data(ekPublic).base64EncodedString()),
                    TS3CommandSingleParameter(name: "proof", value: Data(signature).base64EncodedString())
                ]
            )
            let params = try TS3Crypto.cryptoInit2(license: licenseBytes, alpha: alpha, beta: betaBytes, privateKey: ekPrivate)
            log(.debug, "[HANDSHAKE] clientek ek=\(base64String(ekPublic)) proof=\(base64String(signature)) localProofValid=\(localProofValid)")
            log(.debug, "[HANDSHAKE] cryptoInit2 ivStruct=\(hexString(params.ivStruct)) fakeMac=\(hexString(params.fakeMac))")
            let secureTransformation = TS3PacketTransformation(ivStruct: params.ivStruct, fakeMac: params.fakeMac)
            _ = try sendCommandReturningPacketId(ekCommand)
            transformation = secureTransformation

            try sendClientInit()
            state = .retrieving
            log(.info, "clientinit sent")

        } else if command.name == "error" {
            let message = command.get("msg")?.value ?? "unknown"
            state = .disconnected
            throw TS3Error.serverError(message: message)
        } else {
            throw TS3Error.invalidCommand
        }
    }

    func sendClientInit() throws {
        guard let identity else {
            throw TS3Error.invalidIdentity
        }

        let params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "client_nickname", value: config.nickname),
            TS3CommandSingleParameter(name: "client_version", value: "3.?.? [Build: 5680278000]"),
            TS3CommandSingleParameter(name: "client_platform", value: "Windows"),
            TS3CommandSingleParameter(name: "client_version_sign", value: "DX5NIYLvfJEUjuIbCidnoeozxIDRRkpq3I9vVMBmE9L2qnekOoBzSenkzsg2lC9CMv8K5hkEzhr2TYUYSwUXCg=="),
            TS3CommandSingleParameter(name: "client_input_hardware", value: "1"),
            TS3CommandSingleParameter(name: "client_output_hardware", value: "1"),
            TS3CommandSingleParameter(name: "client_default_channel", value: config.defaultChannel),
            TS3CommandSingleParameter(name: "client_default_channel_password", value: config.defaultChannelPassword.map(TS3Crypto.hashPassword)),
            TS3CommandSingleParameter(name: "client_server_password", value: config.serverPassword.map(TS3Crypto.hashPassword)),
            TS3CommandSingleParameter(name: "client_nickname_phonetic", value: nil),
            TS3CommandSingleParameter(name: "client_meta_data", value: ""),
            TS3CommandSingleParameter(name: "client_default_token", value: config.privilegeKey),
            TS3CommandSingleParameter(name: "client_key_offset", value: String(identity.keyOffset)),
            TS3CommandSingleParameter(name: "hwid", value: "+LyYqbDqOvEEpN5pdAbF8/v5kZ0=")
        ]

        let command = TS3SingleCommand(name: "clientinit", parameters: params)
        log(.debug, command.build())
        try sendCommand(command)
    }
}

// MARK: - Packet Handling
private extension TS3Client {
    func handleDatagram(_ data: Data) {
        var buffer = TS3ByteBuffer(data: data)
        var header = TS3PacketHeader(role: .server, type: .command)

        do {
            try header.read(from: &buffer)
            if let counter = remoteCounters[header.type] {
                header.generation = counter.generation(for: header.packetId)
            }

            let typeName = String(describing: header.type).uppercased()
            log(.debug, "[NETWORK] READ \(typeName) id=\(header.packetId) len=\(data.count) from \(serverAddress)")

            let packet = try readPacket(header: header, buffer: data)
            sendAcknowledgementIfNeeded(for: packet)

            var shouldProcess = true
            if packet.header.type.canResend, packet.header.type != .init1,
               let counter = remoteCounters[packet.header.type] {
                shouldProcess = counter.put(packet.header.packetId)
                if !shouldProcess {
                    log(.debug, "[PROTOCOL] DUPLICATE \(typeName) id=\(packet.header.packetId) - ignoring")
                }
            }

            if shouldProcess {
                if packet.header.type.isSplittable,
                   let reassembly = reassemblyQueues[packet.header.type] {
                    reassembly.put(packet)
                    if let reassembled = try reassembly.next() {
                        let bodyTypeName = String(describing: type(of: reassembled.body))
                        log(.debug, "[PROTOCOL] REASSEMBLE \(typeName) id=\(reassembled.header.packetId) len=\(reassembled.body.size) bodyType=\(bodyTypeName)")
                        handlePacket(reassembled)
                    }
                } else {
                    handlePacket(packet)
                }
            }

            lastResponse = Date()
        } catch {
            log(.debug, "[ERROR] Packet handling failed: \(error)")
        }
    }

    func readPacket(header: TS3PacketHeader, buffer: Data) throws -> TS3Packet {
        var payload: Data
        let typeName = String(describing: header.type).uppercased()
        if !header.flags.contains(.unencrypted) {
            log(.debug, "[PROTOCOL] DECRYPT \(typeName) generation=\(header.generation)")
            do {
                payload = try transformation.decrypt(header: header, buffer: buffer)
            } catch {
                if allowInitFallbackDecrypt && (state == .connecting || state == .retrieving) {
                    log(.debug, "[PROTOCOL] DECRYPT failed with current transformation, trying init transformation...")
                    payload = try initTransformation.decrypt(header: header, buffer: buffer)
                    log(.debug, "[PROTOCOL] DECRYPT succeeded with init transformation")
                } else {
                    throw error
                }
            }
        } else {
            payload = buffer.dropFirst(header.size)
        }
        log(.debug, "[PROTOCOL] READ \(typeName)")

        var bodyBuffer = TS3ByteBuffer(data: payload)
        if header.type.isSplittable {
            if header.flags.contains(.compressed) && header.type.isCompressible {
                var compressed = TS3PacketBodyCompressed(type: header.type, role: header.role, compressed: Data())
                try compressed.read(from: &bodyBuffer, header: header)
                return TS3Packet(header: header, body: compressed)
            } else {
                var fragment = TS3PacketBodyFragment(type: header.type, role: header.role, raw: Data())
                try fragment.read(from: &bodyBuffer, header: header)
                return TS3Packet(header: header, body: fragment)
            }
        }

        var body = try TS3PacketFactory.body(for: header.type, role: header.role)
        try body.read(from: &bodyBuffer, header: header)
        return TS3Packet(header: header, body: body)
    }

    func handlePacket(_ packet: TS3Packet) {
        switch packet.header.type {
        case .ack:
            if let ack = packet.body as? TS3PacketBodyAck {
                log(.debug, "[ACK] Received ACK for packet id=\(ack.packetId)")
                sendQueue.removeValue(forKey: ack.packetId)
            }
        case .ackLow:
            if let ack = packet.body as? TS3PacketBodyAckLow {
                sendQueueLow.removeValue(forKey: ack.packetId)
            }
        case .pong:
            if let pong = packet.body as? TS3PacketBodyPong {
                pingQueue.removeValue(forKey: pong.packetId)
            }
        case .init1:
            if let init1 = packet.body as? TS3PacketBodyInit1 {
                do {
                    try handleInit1(init1)
                } catch {
                    log(.error, "init1 handling failed: \(error.localizedDescription)")
                }
            }
        case .command:
            if let command = packet.body as? TS3PacketBodyCommand {
                handleCommandText(command.text)
            }
        case .commandLow:
            if let command = packet.body as? TS3PacketBodyCommandLow {
                handleCommandText(command.text)
            }
        case .voice:
            if let voice = packet.body as? TS3PacketBodyVoice,
               voice.codecType == 4 || voice.codecType == 5 {
                let codecData = voice.codecData
                let speakerId = voice.clientId ?? 0
                let sessionMarker = voice.serverFlag0
                audioQueue.async { [weak self] in
                    self?.audioEngine?.handleIncoming(packet: codecData,
                                                      from: speakerId,
                                                      isWhisper: false,
                                                      sessionMarker: sessionMarker)
                }
            }
        case .voiceWhisper:
            if let whisper = packet.body as? TS3PacketBodyVoiceWhisper,
               whisper.codecType == 4 || whisper.codecType == 5 {
                let codecData = whisper.codecData
                let speakerId = whisper.clientId ?? 0
                let sessionMarker = whisper.serverFlag0
                audioQueue.async { [weak self] in
                    self?.audioEngine?.handleIncoming(packet: codecData,
                                                      from: speakerId,
                                                      isWhisper: true,
                                                      sessionMarker: sessionMarker)
                }
            }
        default:
            break
        }
    }
}

// MARK: - Commands
private extension TS3Client {
    @discardableResult
    func sendCommandReturningPacketId(_ command: TS3SingleCommand) throws -> UInt16 {
        let body = TS3PacketBodyCommand(role: .client, text: command.build())
        log(.info, "send cmd: \(command.name)")
        return try sendPacket(body: body)
    }

    func sendCommand(_ command: TS3SingleCommand) throws {
        _ = try sendCommandReturningPacketId(command)
    }

    func execute(_ command: TS3SingleCommand) async throws -> [TS3SingleCommand] {
        let code = nextCommandCode
        nextCommandCode += 1

        var params = command.parameters
        params.append(TS3CommandSingleParameter(name: "return_code", value: String(code)))
        let commandWithReturn = TS3SingleCommand(name: command.name, parameters: params)

        return try await withCheckedThrowingContinuation { continuation in
            pendingCommands[code] = PendingCommand(code: code, continuation: continuation, responses: [])
            do {
                try sendCommand(commandWithReturn)
            } catch {
                pendingCommands.removeValue(forKey: code)
                continuation.resume(throwing: error)
            }
        }
    }

    func finishConnectedSetup() async {
        let registrations = [
            TS3SingleCommand(name: "servernotifyregister", parameters: [
                TS3CommandSingleParameter(name: "event", value: "server")
            ]),
            TS3SingleCommand(name: "servernotifyregister", parameters: [
                TS3CommandSingleParameter(name: "event", value: "channel"),
                TS3CommandSingleParameter(name: "id", value: "0")
            ]),
            TS3SingleCommand(name: "servernotifyregister", parameters: [
                TS3CommandSingleParameter(name: "event", value: "textserver")
            ]),
            TS3SingleCommand(name: "servernotifyregister", parameters: [
                TS3CommandSingleParameter(name: "event", value: "textchannel")
            ]),
            TS3SingleCommand(name: "servernotifyregister", parameters: [
                TS3CommandSingleParameter(name: "event", value: "textprivate")
            ])
        ]

        for command in registrations {
            do {
                _ = try await execute(command)
                log(.debug, "registered notify event \(command.get("event")?.value ?? command.name)")
            } catch {
                log(.warning, "notify registration failed for \(command.get("event")?.value ?? command.name): \(error.localizedDescription)")
            }
        }

        do {
            try await refreshServerView()
        } catch {
            log(.warning, "initial client/channel refresh failed: \(error.localizedDescription)")
        }

        do {
            try await refreshGroups()
        } catch {
            log(.warning, "initial group refresh failed: \(error.localizedDescription)")
        }
    }

    func handleCommandText(_ text: String) {
        do {
            let multi = try TS3MultiCommand.parse(text)
            log(.info, "recv cmd: \(multi.name)")
            for command in multi.simplify() {
                handleCommand(command)
            }
        } catch {
            // ignore
        }
    }

    func handleCommand(_ command: TS3SingleCommand) {
        if command.name == "initivexpand" || command.name == "initivexpand2" {
            try? handleInitCommand(command)
            return
        }

        if (state == .connecting || state == .retrieving) && command.name == "error" {
            try? handleInitCommand(command)
            return
        }

        if command.name == "initserver" {
            allowInitFallbackDecrypt = false
            clearPendingInitIv(reason: "initserver")

            if let id = command.get("aclid")?.value {
                clientId = UInt16(id) ?? 0
            }
            if let sid = command.get("virtualserver_id")?.value {
                serverId = Int(sid)
            }
            return
        }

        if command.name == "channellist" {
            recordPendingResponse(command)
            if let cidValue = command.get("cid")?.value,
               let cid = Int(cidValue),
               command.get("channel_flag_default")?.value == "1" {
                defaultChannelId = cid
                log(.debug, "[CHANNEL] default channel advertised by server cid=\(cid)")
            }
            if let channel = channelFromCommand(command) {
                channelCache[channel.id] = channel
            }
            return
        }

        if command.name == "clientlist" {
            recordPendingResponse(command)
            if let serverClient = clientFromListCommand(command) {
                clientCache[UInt16(serverClient.id)] = serverClient
            }
            return
        }

        if command.name == "serverinfo" {
            recordPendingResponse(command)
            if let info = serverInfo(from: command) {
                serverInfo = info
                publishServerInfo(info)
            }
            return
        }

        if command.name == "notifychannelcreated" || command.name == "notifychanneledited" || command.name == "notifychannelsubscribed" {
            if let channel = channelFromCommand(command) {
                channelCache[channel.id] = channel
                publishChannels()
            } else {
                Task { try? await refreshServerView() }
            }
            return
        }

        if command.name == "notifychanneldeleted" {
            if let cidValue = command.get("cid")?.value, let cid = Int(cidValue) {
                channelCache.removeValue(forKey: cid)
                publishChannels()
            }
            return
        }

        if command.name == "notifychannelmoved" || command.name == "notifychannelpasswordchanged" || command.name == "notifychanneldescriptionchanged" {
            Task { try? await refreshServerView() }
            return
        }

        if command.name == "notifytextmessage" {
            if let message = textMessage(from: command) {
                DispatchQueue.main.async {
                    self.delegate?.ts3Client(self, didReceiveTextMessage: message)
                }
            }
            return
        }

        if command.name == "servergrouplist" || command.name == "notifyservergrouplist" {
            if command.name == "servergrouplist" {
                recordPendingResponse(command)
            }
            if let group = serverGroup(from: command) {
                serverGroupCache[group.id] = group
                publishGroups()
            }
            return
        }

        if command.name == "channelgrouplist" || command.name == "notifychannelgrouplist" {
            if command.name == "channelgrouplist" {
                recordPendingResponse(command)
            }
            if let group = channelGroup(from: command) {
                channelGroupCache[group.id] = group
                publishGroups()
            }
            return
        }

        if command.name == "channellistfinished" {
            if currentChannelId == nil, let defaultChannelId {
                currentChannelId = defaultChannelId
                log(.debug, "[CHANNEL] using default channel as initial current channel cid=\(defaultChannelId)")
            }
            state = .connected
            connectContinuation?.resume()
            connectContinuation = nil
            log(.info, "channel list completed")
            publishChannels()
            Task {
                await self.finishConnectedSetup()
            }
            DispatchQueue.main.async {
                self.delegate?.ts3ClientDidConnect(self)
            }
            return
        }

        if command.name == "notifycliententerview" {
            if let serverClient = clientFromEnterViewCommand(command) {
                clientCache[UInt16(serverClient.id)] = serverClient
                publishClients()
            }
            if let cid = ownClientChannelId(from: command) {
                currentChannelId = cid
                log(.debug, "[CHANNEL] current channel updated from \(command.name) cid=\(cid)")
                publishChannels()
            }
            return
        }

        if command.name == "notifyclientmoved" {
            if let clidValue = command.get("clid")?.value,
               let clid = Int(clidValue),
               let cid = targetChannelId(from: command) {
                updateClientChannel(clientId: clid, channelId: cid)
                publishClients()
            }
            if let cid = ownClientChannelId(from: command) {
                currentChannelId = cid
                log(.debug, "[CHANNEL] current channel updated from \(command.name) cid=\(cid)")
                publishChannels()
            }
            return
        }

        if command.name == "notifyclientleftview" {
            if let clidValue = command.get("clid")?.value,
               let clid = UInt16(clidValue) {
                if clid == clientId {
                    log(.info, "server acknowledged disconnect")
                    disconnectInternal(error: nil)
                    return
                }
                clientCache.removeValue(forKey: clid)
                publishClients()
            }
            return
        }

        if command.name == "notifyclientupdated" {
            if mergeClientUpdate(from: command) != nil {
                publishClients()
            }
            return
        }

        if command.name == "error" {
            let code = Int(command.get("return_code")?.value ?? "") ?? pendingCommands.keys.min()
            if let code, var pending = pendingCommands[code] {
                if let id = command.get("id")?.value, id != "0" {
                    pending.continuation.resume(throwing: TS3Error.serverError(message: command.get("msg")?.value ?? "error"))
                } else {
                    pending.continuation.resume(returning: pending.responses)
                }
                pendingCommands.removeValue(forKey: code)
            }
            return
        }

        recordPendingResponse(command)
    }

    func recordPendingResponse(_ command: TS3SingleCommand) {
        guard command.name != "error" else { return }
        let code = Int(command.get("return_code")?.value ?? "") ?? pendingCommands.keys.min()
        if let code, var pending = pendingCommands[code] {
            pending.responses.append(command)
            pendingCommands[code] = pending
        }
    }

    func channelFromCommand(_ command: TS3SingleCommand) -> TS3Channel? {
        guard let cidValue = command.get("cid")?.value,
              let cid = Int(cidValue),
              let name = command.get("channel_name")?.value else {
            return nil
        }
        let topic = command.get("channel_topic")?.value
        return TS3Channel(
            id: cid,
            parentId: intValue(command, "pid") ?? intValue(command, "cpid"),
            order: intValue(command, "channel_order"),
            name: name,
            topic: topic,
            description: command.get("channel_description")?.value,
            isDefault: command.get("channel_flag_default")?.value == "1",
            isPasswordProtected: command.get("channel_flag_password")?.value == "1",
            isPermanent: command.get("channel_flag_permanent")?.value == "1",
            neededTalkPower: intValue(command, "channel_needed_talk_power"),
            codec: intValue(command, "channel_codec")
        )
    }
}

// MARK: - Packet Sending
private extension TS3Client {
    @discardableResult
    func sendPacket(body: any TS3PacketBody) throws -> UInt16 {
        var header = TS3PacketHeader(role: .client, type: body.type)
        header.clientId = clientId
        body.applyHeaderFlags(to: &header)

        switch body.type {
        case .init1, .ping, .pong:
            header.flags.insert(.unencrypted)
        case .command, .commandLow:
            header.flags.insert(.newProtocol)
        default:
            break
        }

        let packet = TS3Packet(header: header, body: body)
        return try sendPacket(packet)
    }

    @discardableResult
    func sendPacket(body: any TS3PacketBody, generation: Int) throws -> UInt16 {
        var header = TS3PacketHeader(role: .client, type: body.type)
        header.clientId = clientId
        header.generation = generation
        body.applyHeaderFlags(to: &header)

        switch body.type {
        case .init1, .ping, .pong:
            header.flags.insert(.unencrypted)
        case .command, .commandLow:
            header.flags.insert(.newProtocol)
        default:
            break
        }

        let packet = TS3Packet(header: header, body: body)
        return try sendPacket(packet)
    }

    @discardableResult
    func sendPacket(_ packet: TS3Packet) throws -> UInt16 {
        if packet.header.type.isSplittable {
            let pieces = try TS3Fragments.split(packet: packet)
            var firstPacketId: UInt16 = 0
            for piece in pieces {
                let packetId = try sendPacketInternal(piece)
                if firstPacketId == 0 {
                    firstPacketId = packetId
                }
            }
            return firstPacketId
        } else {
            if packet.size > TS3Fragments.maximumPacketSize {
                throw TS3Error.packetTooLarge
            }
            return try sendPacketInternal(packet)
        }
    }

    @discardableResult
    func sendPacketInternal(_ packet: TS3Packet) throws -> UInt16 {
        var header = packet.header
        guard let counter = localCounters[header.type] else {
            throw TS3Error.invalidState
        }

        switch header.type {
        case .ack:
            if let ack = packet.body as? TS3PacketBodyAck, let remote = remoteCounters[.ack] {
                header.generation = remote.generation(for: ack.packetId)
                header.packetId = ack.packetId
            }
        case .ackLow:
            if let ack = packet.body as? TS3PacketBodyAckLow, let remote = remoteCounters[.ackLow] {
                header.generation = remote.generation(for: ack.packetId)
                header.packetId = ack.packetId
            }
        case .pong:
            if let pong = packet.body as? TS3PacketBodyPong, let remote = remoteCounters[.pong] {
                header.generation = remote.generation(for: pong.packetId)
                header.packetId = pong.packetId
            }
        case .init1:
            _ = counter.next()
            header.packetId = 101
            header.generation = 0
        default:
            let next = counter.next()
            header.packetId = next.0
            header.generation = next.1
        }

        var body: any TS3PacketBody = packet.body
        if var voice = body as? TS3PacketBodyVoice {
            voice.packetId = header.packetId
            body = voice
        }

        let outgoing = TS3Packet(header: header, body: body)
        let typeName = String(describing: header.type).uppercased()
        let transformType = String(describing: type(of: transformation))
        let data: Data
        if !header.flags.contains(.unencrypted) {
            log(.debug, "[PROTOCOL] ENCRYPT \(typeName) generation=\(header.generation) using=\(transformType)")
            if let label = handshakeCommandLabel(for: body) {
                var plaintextBuffer = TS3ByteBuffer()
                try body.write(to: &plaintextBuffer, header: header)
                let plaintext = [UInt8](plaintextBuffer.data)
                let headerWithoutMac = Array(header.write(includeMac: false).dropFirst(8))
                let params = transformation.computeParameters(header: header)
                log(.debug, "[HANDSHAKE] encrypt \(label) packetId=\(header.packetId) gen=\(header.generation) key=\(hexString(params.key)) nonce=\(hexString(params.nonce)) header=\(hexString(headerWithoutMac)) plaintextLen=\(plaintext.count) plaintextPreview=\(hexString(plaintext, maxBytes: 64))")
            }
            data = try transformation.encrypt(packet: outgoing)
            if let label = handshakeCommandLabel(for: body) {
                let mac = [UInt8](data.prefix(8))
                let ciphertext = [UInt8](data.dropFirst(header.size))
                log(.debug, "[HANDSHAKE] encrypted \(label) mac=\(hexString(mac)) ciphertextLen=\(ciphertext.count) ciphertextPreview=\(hexString(ciphertext, maxBytes: 64)) packetPreview=\(hexString([UInt8](data), maxBytes: 96))")
            }
        } else {
            if header.type == .init1 {
                header.mac = [0x54, 0x53, 0x33, 0x49, 0x4E, 0x49, 0x54, 0x31]
            } else {
                header.mac = transformation.fakeSignature()
            }
            var buffer = TS3ByteBuffer()
            buffer.writeBytes(header.write())
            var bodyBuffer = TS3ByteBuffer()
            try body.write(to: &bodyBuffer, header: header)
            buffer.writeBytes(bodyBuffer.data)
            data = buffer.data
            if let label = handshakeInitLabel(for: body) {
                log(.debug, "[HANDSHAKE] \(label) header=\(hexString([UInt8](header.write()))) bodyLen=\(bodyBuffer.data.count) bodyPreview=\(hexString([UInt8](bodyBuffer.data), maxBytes: 192))")
                log(.debug, "[HANDSHAKE] \(label) packetPreview=\(hexString([UInt8](data), maxBytes: 224))")
            }
        }
        log(.debug, "[PROTOCOL] WRITE \(typeName)")
        log(.debug, "[NETWORK] WRITE \(typeName) id=\(header.packetId) len=\(data.count) to \(serverAddress)")

        let response = TS3PacketResponse(datagram: data, sentAt: Date())
        if header.type.acknowledgedBy != nil {
            switch header.type {
            case .command:
                sendQueue[header.packetId] = response
            case .commandLow:
                sendQueueLow[header.packetId] = response
            case .ping:
                pingQueue[header.packetId] = response
            default:
                break
            }
        }

        sendRaw(data: data)
        return header.packetId
    }
}

// MARK: - Identity
private extension TS3Client {
    func identityFileURL() throws -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        return baseURL.appendingPathComponent("ts3-identity.key")
    }

    func loadIdentity() async throws -> TS3Identity {
        let fileURL = try identityFileURL()

        if let data = try? Data(contentsOf: fileURL), data.count >= 32 {
            let privateKeyBytes = [UInt8](data.prefix(32))
            var keyOffset = 0
            if data.count >= 36 {
                let offsetBytes = data.subdata(in: 32..<36)
                keyOffset = Int(UInt32(bigEndian: offsetBytes.withUnsafeBytes { $0.load(as: UInt32.self) }))
            }
            let identity = try TS3Identity(privateKeyBytes: privateKeyBytes, keyOffset: keyOffset)
            let level = identity.securityLevel()
            log(.debug, "Loaded existing identity, security level: \(level), keyOffset: \(identity.keyOffset)")
            return identity
        }

        log(.info, "正在生成身份标识...")
        let identity = try TS3Identity.generate(securityLevel: 8) { [weak self] oldLevel, newLevel, offset in
            self?.log(.debug, "Improved identity security level: from \(oldLevel) to \(newLevel) (\(offset))")
        }
        try saveIdentity(identity)
        return identity
    }

    func saveIdentity(_ identity: TS3Identity) throws {
        let fileURL = try identityFileURL()
        var saveData = Data(identity.privateKeyBytes)
        var offset = UInt32(identity.keyOffset).bigEndian
        saveData.append(Data(bytes: &offset, count: 4))
        try saveData.write(to: fileURL, options: .atomic)
    }

    func identityExportString(for identity: TS3Identity) throws -> String {
        var data = Data(identity.privateKeyBytes)
        var offset = UInt32(identity.keyOffset).bigEndian
        data.append(Data(bytes: &offset, count: 4))
        return "TS3IOS1:\(data.base64EncodedString())"
    }

    func identity(fromExportString raw: String) throws -> TS3Identity {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload: String
        if trimmed.hasPrefix("TS3IOS1:") {
            payload = String(trimmed.dropFirst("TS3IOS1:".count))
        } else {
            payload = trimmed
        }

        guard let data = Data(base64Encoded: payload), data.count >= 32 else {
            throw TS3Error.invalidIdentity
        }

        let privateKeyBytes = [UInt8](data.prefix(32))
        var keyOffset = 0
        if data.count >= 36 {
            let offsetBytes = data.subdata(in: 32..<36)
            keyOffset = Int(UInt32(bigEndian: offsetBytes.withUnsafeBytes { $0.load(as: UInt32.self) }))
        }
        return try TS3Identity(privateKeyBytes: privateKeyBytes, keyOffset: keyOffset)
    }
}

private extension TS3Client {
    func appendParameter(_ params: inout [TS3CommandParameter], name: String, value: String?) {
        guard let value else { return }
        params.append(TS3CommandSingleParameter(name: name, value: value))
    }

    func intValue(_ command: TS3SingleCommand, _ name: String) -> Int? {
        command.get(name)?.value.flatMap(Int.init)
    }

    func int64Value(_ command: TS3SingleCommand, _ name: String) -> Int64? {
        command.get(name)?.value.flatMap(Int64.init)
    }

    func boolValue(_ command: TS3SingleCommand, _ name: String) -> Bool {
        command.get(name)?.value == "1"
    }

    func dateValue(_ command: TS3SingleCommand, _ name: String) -> Date? {
        int64Value(command, name).map { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    func clientFromEnterViewCommand(_ command: TS3SingleCommand) -> TS3ServerClient? {
        guard let clidValue = command.get("clid")?.value,
              let clid = Int(clidValue),
              let channelId = targetChannelId(from: command) else {
            return nil
        }

        let nickname = command.get("client_nickname")?.value ?? "Client \(clid)"
        return TS3ServerClient(
            id: clid,
            channelId: channelId,
            databaseId: intValue(command, "client_database_id") ?? intValue(command, "client_dbid"),
            nickname: nickname,
            isCurrentUser: UInt16(clid) == clientId,
            uniqueIdentifier: command.get("client_unique_identifier")?.value,
            isInputMuted: boolValue(command, "client_input_muted"),
            isOutputMuted: boolValue(command, "client_output_muted"),
            isAway: boolValue(command, "client_away"),
            awayMessage: command.get("client_away_message")?.value,
            talkPower: intValue(command, "client_talk_power"),
            channelGroupId: intValue(command, "client_channel_group_id"),
            serverGroups: serverGroupIds(from: command)
        )
    }

    func clientFromListCommand(_ command: TS3SingleCommand) -> TS3ServerClient? {
        guard let clid = intValue(command, "clid"),
              let channelId = targetChannelId(from: command) else {
            return nil
        }
        let existing = clientCache[UInt16(clid)]
        return TS3ServerClient(
            id: clid,
            channelId: channelId,
            databaseId: intValue(command, "client_database_id") ?? intValue(command, "client_dbid") ?? existing?.databaseId,
            nickname: command.get("client_nickname")?.value ?? existing?.nickname ?? "Client \(clid)",
            isCurrentUser: UInt16(clid) == clientId,
            uniqueIdentifier: command.get("client_unique_identifier")?.value ?? existing?.uniqueIdentifier,
            isInputMuted: boolValue(command, "client_input_muted"),
            isOutputMuted: boolValue(command, "client_output_muted"),
            isAway: boolValue(command, "client_away"),
            awayMessage: command.get("client_away_message")?.value,
            talkPower: intValue(command, "client_talk_power"),
            channelGroupId: intValue(command, "client_channel_group_id"),
            serverGroups: serverGroupIds(from: command)
        )
    }

    func mergeClientUpdate(from command: TS3SingleCommand) -> TS3ServerClient? {
        guard let clidValue = command.get("clid")?.value,
              let clid = UInt16(clidValue),
              var existing = clientCache[clid] else {
            return nil
        }

        existing = TS3ServerClient(
            id: existing.id,
            channelId: targetChannelId(from: command) ?? existing.channelId,
            databaseId: intValue(command, "client_database_id") ?? intValue(command, "client_dbid") ?? existing.databaseId,
            nickname: command.get("client_nickname")?.value ?? existing.nickname,
            isCurrentUser: existing.isCurrentUser,
            uniqueIdentifier: command.get("client_unique_identifier")?.value ?? existing.uniqueIdentifier,
            isInputMuted: command.has("client_input_muted") ? boolValue(command, "client_input_muted") : existing.isInputMuted,
            isOutputMuted: command.has("client_output_muted") ? boolValue(command, "client_output_muted") : existing.isOutputMuted,
            isAway: command.has("client_away") ? boolValue(command, "client_away") : existing.isAway,
            awayMessage: command.get("client_away_message")?.value ?? existing.awayMessage,
            talkPower: intValue(command, "client_talk_power") ?? existing.talkPower,
            channelGroupId: intValue(command, "client_channel_group_id") ?? existing.channelGroupId,
            serverGroups: command.has("client_servergroups") ? serverGroupIds(from: command) : existing.serverGroups
        )
        clientCache[clid] = existing
        return existing
    }

    func mergeDetailedClientInfo(_ command: TS3SingleCommand, fallbackClientId: Int) -> TS3ServerClient? {
        let clid = intValue(command, "clid") ?? fallbackClientId
        let key = UInt16(clid)
        let existing = clientCache[key]
        let channelId = targetChannelId(from: command) ?? existing?.channelId ?? currentChannelId ?? 0
        let updated = TS3ServerClient(
            id: clid,
            channelId: channelId,
            databaseId: intValue(command, "client_database_id") ?? intValue(command, "client_dbid") ?? existing?.databaseId,
            nickname: command.get("client_nickname")?.value ?? existing?.nickname ?? "Client \(clid)",
            isCurrentUser: key == clientId,
            uniqueIdentifier: command.get("client_unique_identifier")?.value ?? existing?.uniqueIdentifier,
            isInputMuted: command.has("client_input_muted") ? boolValue(command, "client_input_muted") : existing?.isInputMuted ?? false,
            isOutputMuted: command.has("client_output_muted") ? boolValue(command, "client_output_muted") : existing?.isOutputMuted ?? false,
            isAway: command.has("client_away") ? boolValue(command, "client_away") : existing?.isAway ?? false,
            awayMessage: command.get("client_away_message")?.value ?? existing?.awayMessage,
            talkPower: intValue(command, "client_talk_power") ?? existing?.talkPower,
            channelGroupId: intValue(command, "client_channel_group_id") ?? existing?.channelGroupId,
            serverGroups: command.has("client_servergroups") ? serverGroupIds(from: command) : existing?.serverGroups ?? []
        )
        clientCache[key] = updated
        return updated
    }

    func copyClient(
        _ client: TS3ServerClient,
        channelId: Int? = nil,
        nickname: String? = nil,
        isInputMuted: Bool? = nil,
        isOutputMuted: Bool? = nil,
        isAway: Bool? = nil,
        awayMessage: String? = nil
    ) -> TS3ServerClient {
        TS3ServerClient(
            id: client.id,
            channelId: channelId ?? client.channelId,
            databaseId: client.databaseId,
            nickname: nickname ?? client.nickname,
            isCurrentUser: client.isCurrentUser,
            uniqueIdentifier: client.uniqueIdentifier,
            isInputMuted: isInputMuted ?? client.isInputMuted,
            isOutputMuted: isOutputMuted ?? client.isOutputMuted,
            isAway: isAway ?? client.isAway,
            awayMessage: awayMessage ?? client.awayMessage,
            talkPower: client.talkPower,
            channelGroupId: client.channelGroupId,
            serverGroups: client.serverGroups
        )
    }

    func databaseClient(from command: TS3SingleCommand, fallbackDatabaseId: Int? = nil) -> TS3DatabaseClient? {
        guard let databaseId = intValue(command, "cldbid") ?? intValue(command, "client_database_id") ?? fallbackDatabaseId else {
            return nil
        }
        let nickname = command.get("client_nickname")?.value
            ?? command.get("name")?.value
            ?? command.get("client_lastnickname")?.value
            ?? "Client DB \(databaseId)"
        return TS3DatabaseClient(
            id: databaseId,
            uniqueIdentifier: command.get("client_unique_identifier")?.value ?? command.get("cluid")?.value,
            nickname: nickname,
            createdAt: dateValue(command, "client_created"),
            lastConnectedAt: dateValue(command, "client_lastconnected"),
            totalConnections: intValue(command, "client_totalconnections"),
            description: command.get("client_description")?.value,
            lastIP: command.get("client_lastip")?.value
        )
    }

    func clientLocation(from command: TS3SingleCommand) -> TS3ClientLocation? {
        guard let clientId = intValue(command, "clid") else {
            return nil
        }
        return TS3ClientLocation(
            clientId: clientId,
            nickname: command.get("name")?.value ?? command.get("client_nickname")?.value
        )
    }

    func serverInfo(from command: TS3SingleCommand) -> TS3ServerInfo? {
        let name = command.get("virtualserver_name")?.value
            ?? command.get("name")?.value
            ?? serverAddress
        return TS3ServerInfo(
            uniqueIdentifier: command.get("virtualserver_unique_identifier")?.value,
            name: name,
            platform: command.get("virtualserver_platform")?.value,
            version: command.get("virtualserver_version")?.value,
            clientsOnline: intValue(command, "virtualserver_clientsonline"),
            maxClients: intValue(command, "virtualserver_maxclients"),
            reservedSlots: intValue(command, "virtualserver_reserved_slots"),
            channelsOnline: intValue(command, "virtualserver_channelsonline"),
            uptimeSeconds: intValue(command, "virtualserver_uptime"),
            welcomeMessage: command.get("virtualserver_welcomemessage")?.value,
            passwordProtected: boolValue(command, "virtualserver_flag_password"),
            hostMessage: command.get("virtualserver_hostmessage")?.value,
            hostMessageMode: intValue(command, "virtualserver_hostmessage_mode"),
            hostBannerURL: command.get("virtualserver_hostbanner_url")?.value,
            hostBannerGraphicsURL: command.get("virtualserver_hostbanner_gfx_url")?.value,
            hostButtonTooltip: command.get("virtualserver_hostbutton_tooltip")?.value,
            hostButtonURL: command.get("virtualserver_hostbutton_url")?.value,
            hostButtonGraphicsURL: command.get("virtualserver_hostbutton_gfx_url")?.value
        )
    }

    func serverGroupIds(from command: TS3SingleCommand) -> [Int] {
        guard let groups = command.get("client_servergroups")?.value else {
            return []
        }
        return groups.split(separator: ",").compactMap { Int($0) }
    }

    func textMessage(from command: TS3SingleCommand) -> TS3TextMessage? {
        guard let modeValue = intValue(command, "targetmode"),
              let mode = TS3TextMessageTargetMode(rawValue: modeValue),
              let message = command.get("msg")?.value else {
            return nil
        }
        let senderId = intValue(command, "invokerid")
        return TS3TextMessage(
            timestamp: Date(),
            targetMode: mode,
            targetId: intValue(command, "target"),
            senderId: senderId,
            senderName: command.get("invokername")?.value ?? "Client \(senderId ?? 0)",
            message: message,
            isOwnMessage: UInt16(senderId ?? -1) == clientId
        )
    }

    func offlineMessage(from command: TS3SingleCommand, detailedMessage: String?) -> TS3OfflineMessage? {
        guard let id = intValue(command, "msgid") else {
            return nil
        }

        let timestamp: Date?
        if let seconds = intValue(command, "timestamp") {
            timestamp = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            timestamp = nil
        }

        return TS3OfflineMessage(
            id: id,
            senderUniqueIdentifier: command.get("cluid")?.value,
            senderName: command.get("invokername")?.value ?? command.get("sender")?.value,
            subject: command.get("subject")?.value ?? "Message \(id)",
            message: detailedMessage,
            timestamp: timestamp,
            isRead: boolValue(command, "flag_read")
        )
    }

    func banEntry(from command: TS3SingleCommand) -> TS3BanEntry? {
        guard let id = intValue(command, "banid") else {
            return nil
        }

        let createdAt: Date?
        if let created = intValue(command, "created") {
            createdAt = Date(timeIntervalSince1970: TimeInterval(created))
        } else {
            createdAt = nil
        }

        return TS3BanEntry(
            id: id,
            ip: command.get("ip")?.value,
            name: command.get("name")?.value,
            uniqueIdentifier: command.get("uid")?.value,
            lastNickname: command.get("lastnickname")?.value,
            createdAt: createdAt,
            durationSeconds: intValue(command, "duration"),
            invokerName: command.get("invokername")?.value,
            reason: command.get("reason")?.value,
            enforcements: intValue(command, "enforcements")
        )
    }

    func complaintEntry(from command: TS3SingleCommand, fallbackTargetClientDatabaseId: Int) -> TS3ComplaintEntry? {
        let targetDatabaseId = intValue(command, "tcldbid") ?? fallbackTargetClientDatabaseId
        guard let sourceDatabaseId = intValue(command, "fcldbid") ?? intValue(command, "cldbid") else {
            return nil
        }

        let timestamp: Date?
        if let created = intValue(command, "timestamp") ?? intValue(command, "created") {
            timestamp = Date(timeIntervalSince1970: TimeInterval(created))
        } else {
            timestamp = nil
        }

        return TS3ComplaintEntry(
            targetClientDatabaseId: targetDatabaseId,
            targetName: command.get("tname")?.value ?? command.get("targetname")?.value,
            sourceClientDatabaseId: sourceDatabaseId,
            sourceName: command.get("fname")?.value ?? command.get("name")?.value,
            message: command.get("message")?.value,
            timestamp: timestamp
        )
    }

    func serverGroup(from command: TS3SingleCommand) -> TS3ServerGroup? {
        guard let id = intValue(command, "sgid"),
              let name = command.get("name")?.value else {
            return nil
        }
        return TS3ServerGroup(id: id, name: name)
    }

    func channelGroup(from command: TS3SingleCommand) -> TS3ChannelGroup? {
        guard let id = intValue(command, "cgid"),
              let name = command.get("name")?.value else {
            return nil
        }
        return TS3ChannelGroup(id: id, name: name)
    }

    func permissionInfo(from command: TS3SingleCommand) -> TS3PermissionInfo? {
        guard let id = intValue(command, "permid"),
              let name = command.get("permname")?.value else {
            return nil
        }
        return TS3PermissionInfo(
            id: id,
            name: name,
            description: command.get("permdesc")?.value
        )
    }

    func permission(from command: TS3SingleCommand) -> TS3Permission? {
        guard let name = command.get("permsid")?.value ?? command.get("permname")?.value,
              let value = intValue(command, "permvalue") else {
            return nil
        }
        return TS3Permission(
            name: name,
            value: value,
            isNegated: boolValue(command, "permnegated"),
            isSkipped: boolValue(command, "permskip")
        )
    }

    func fileEntry(from command: TS3SingleCommand, channelId: Int, parentPath fallbackParentPath: String) -> TS3FileEntry? {
        guard let name = command.get("name")?.value else {
            return nil
        }

        let parentPath = normalizedDirectoryPath(command.get("path")?.value ?? fallbackParentPath)
        let path = joinedFilePath(parentPath: parentPath, name: name)
        let modifiedAt: Date?
        if let seconds = int64Value(command, "datetime") {
            modifiedAt = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            modifiedAt = nil
        }

        return TS3FileEntry(
            channelId: intValue(command, "cid") ?? channelId,
            path: path,
            parentPath: parentPath,
            name: name,
            size: int64Value(command, "size") ?? 0,
            modifiedAt: modifiedAt,
            type: intValue(command, "type") ?? 1,
            incompleteSize: int64Value(command, "incompletesize")
        )
    }

    func normalizedDirectoryPath(_ path: String) -> String {
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

    func joinedFilePath(parentPath: String, name: String) -> String {
        let parent = normalizedDirectoryPath(parentPath)
        if name.hasPrefix("/") {
            return name
        }
        return parent + name
    }

    func targetChannelId(from command: TS3SingleCommand) -> Int? {
        if let ctidValue = command.get("ctid")?.value,
           let ctid = Int(ctidValue) {
            return ctid
        }

        if let cidValue = command.get("cid")?.value,
           let cid = Int(cidValue) {
            return cid
        }

        return nil
    }

    func ownClientChannelId(from command: TS3SingleCommand) -> Int? {
        guard let clid = command.get("clid")?.value,
              UInt16(clid) == clientId else {
            return nil
        }

        return targetChannelId(from: command)
    }

    func updateClientChannel(clientId: Int, channelId: Int) {
        let key = UInt16(clientId)
        if let existing = clientCache[key] {
            clientCache[key] = copyClient(existing, channelId: channelId)
        } else {
            clientCache[key] = TS3ServerClient(
                id: clientId,
                channelId: channelId,
                nickname: clientId == Int(self.clientId) ? config.nickname : "Client \(clientId)",
                isCurrentUser: clientId == Int(self.clientId)
            )
        }
    }

    func publishClients() {
        let clients = clientCache.values.sorted {
            if $0.channelId != $1.channelId { return $0.channelId < $1.channelId }
            if $0.isCurrentUser != $1.isCurrentUser { return $0.isCurrentUser && !$1.isCurrentUser }
            return $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending
        }
        DispatchQueue.main.async {
            self.delegate?.ts3Client(self, didUpdateClients: clients)
        }
    }

    func publishServerInfo(_ info: TS3ServerInfo) {
        DispatchQueue.main.async {
            self.delegate?.ts3Client(self, didUpdateServerInfo: info)
        }
    }

    func publishChannels() {
        let channels = channelCache.values.sorted { $0.id < $1.id }
        DispatchQueue.main.async {
            self.delegate?.ts3Client(self, didUpdateChannels: channels)
        }
    }

    func publishGroups() {
        let serverGroups = serverGroupCache.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let channelGroups = channelGroupCache.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        DispatchQueue.main.async {
            self.delegate?.ts3Client(self, didUpdateServerGroups: serverGroups)
            self.delegate?.ts3Client(self, didUpdateChannelGroups: channelGroups)
        }
    }

    func sendAcknowledgementIfNeeded(for packet: TS3Packet) {
        guard let ackType = packet.header.type.acknowledgedBy else {
            return
        }

        log(.debug, "[ACK] Sending ACK for packet id=\(packet.header.packetId) gen=\(packet.header.generation) type=\(packet.header.type)")
        do {
            switch ackType {
            case .ack:
                let ack = TS3PacketBodyAck(role: .client, packetId: packet.header.packetId)
                try sendPacket(body: ack, generation: packet.header.generation)
            case .ackLow:
                let ack = TS3PacketBodyAckLow(role: .client, packetId: packet.header.packetId)
                try sendPacket(body: ack, generation: packet.header.generation)
            case .pong:
                let pong = TS3PacketBodyPong(role: .client, packetId: packet.header.packetId)
                try sendPacket(body: pong, generation: packet.header.generation)
            default:
                break
            }
        } catch {
            log(.error, "[ACK] Failed to send ACK: \(error)")
        }
    }

    func log(_ level: TS3LogLevel, _ message: String) {
        logSequence += 1
        logHandler?(TS3LogEntry(timestamp: Date(), level: level, message: "#\(logSequence) \(message)"))
    }

    func clearPendingInitIv(reason: String) {
        let hadAlpha = pendingInitIvAlpha != nil
        let hadCommand = pendingInitIvCommand != nil
        pendingInitIvAlpha = nil
        pendingInitIvCommand = nil
        log(.debug, "[HANDSHAKE] clear pending initiv reason=\(reason) hadAlpha=\(hadAlpha) hadCommand=\(hadCommand)")
    }

    func handshakeCommandLabel(for body: any TS3PacketBody) -> String? {
        let text: String?
        if let command = body as? TS3PacketBodyCommand {
            text = command.text
        } else if let command = body as? TS3PacketBodyCommandLow {
            text = command.text
        } else {
            text = nil
        }

        guard let text,
              let commandName = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true).first else {
            return nil
        }

        switch commandName {
        case "clientek", "clientinit":
            return String(commandName)
        default:
            return nil
        }
    }

    func handshakeInitLabel(for body: any TS3PacketBody) -> String? {
        guard let init1 = body as? TS3PacketBodyInit1 else {
            return nil
        }

        switch init1.step {
        case _ as TS3Init1Step4:
            return "init1-step4"
        default:
            return nil
        }
    }

    func hexString(_ bytes: [UInt8], maxBytes: Int? = nil) -> String {
        let slice = maxBytes.map { Array(bytes.prefix($0)) } ?? bytes
        let hex = slice.map { String(format: "%02X", $0) }.joined()
        if let maxBytes, bytes.count > maxBytes {
            return "\(hex)...(\(bytes.count) bytes)"
        }
        return hex
    }

    func base64String(_ bytes: [UInt8]) -> String {
        Data(bytes).base64EncodedString()
    }
}

// MARK: - Supporting Types
private enum TS3ConnectionState: CustomStringConvertible {
    case disconnected
    case connecting
    case retrieving
    case connected

    var description: String {
        switch self {
        case .disconnected: return "DISCONNECTED"
        case .connecting: return "CONNECTING"
        case .retrieving: return "RETRIEVING_DATA"
        case .connected: return "CONNECTED"
        }
    }
}

private struct PendingCommand {
    let code: Int
    var continuation: CheckedContinuation<[TS3SingleCommand], Error>
    var responses: [TS3SingleCommand]
}

private struct TS3PacketResponse {
    let datagram: Data
    private(set) var sentAt: Date
    private(set) var retries: Int = 0
    let maxRetries: Int = 30

    func shouldResend(now: Date) -> Bool {
        now.timeIntervalSince(sentAt) > 0.5 && retries < maxRetries
    }

    mutating func didResend() {
        retries += 1
        sentAt = Date()
    }
}
