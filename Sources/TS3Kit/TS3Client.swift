import Foundation
import Network
import CryptoKit
import BigInt

public final class TS3Client {
    public weak var delegate: TS3ClientDelegate?
    public private(set) var currentChannelId: Int?
    public var logHandler: ((TS3LogEntry) -> Void)?

    private let config: TS3ClientConfig
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

    private var lastResponse: Date = Date()
    private var lastPing: Date = Date()

    private var pendingCommands: [Int: PendingCommand] = [:]
    private var nextCommandCode: Int = 1

    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var channelCache: [Int: TS3Channel] = [:]
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
        nextCommandCode = 1

        state = .connecting
        channelCache.removeAll()
        identity = try await loadIdentity()
        log(.debug, "Connecting to \(serverAddress)...")
        if audioEngine == nil {
            audioEngine = try? TS3AudioEngine(config: .voice)
            audioEngine?.onEncodedPacket = { [weak self] data in
                guard let self else { return }
                guard self.state == .connected else { return }
                guard self.isSendingAudio else { return }
                if self.isWhispering, let target = self.whisperTarget {
                    let flag: UInt8? = self.whisperFlaggedPackets > 0 ? self.whisperSessionId : nil
                    if self.whisperFlaggedPackets > 0 {
                        self.whisperFlaggedPackets -= 1
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
                    try? self.sendPacket(body: whisper)
                } else {
                    let flag: UInt8? = self.voiceFlaggedPackets > 0 ? self.voiceSessionId : nil
                    if self.voiceFlaggedPackets > 0 {
                        self.voiceFlaggedPackets -= 1
                    }
                    let voice = TS3PacketBodyVoice(
                        role: .client,
                        packetId: 0,
                        clientId: nil,
                        codecType: 4,
                        codecData: data,
                        serverFlag0: flag
                    )
                    try? self.sendPacket(body: voice)
                }
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
        disconnectInternal(error: nil)
    }

    public func joinChannel(channelId: Int, password: String?) async throws {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "clid", value: String(clientId)),
            TS3CommandSingleParameter(name: "cid", value: String(channelId))
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "cpw", value: password))
        }

        let command = TS3SingleCommand(name: "clientmove", parameters: params)
        _ = try await execute(command)
        currentChannelId = channelId
    }

    public func createChannel(name: String, password: String?) async throws -> Int {
        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "channel_name", value: name)
        ]
        if let password, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "channel_password", value: password))
        }
        let command = TS3SingleCommand(name: "channelcreate", parameters: params)
        let responses = try await execute(command)
        let cid = responses.first?.get("cid")?.value ?? "0"
        return Int(cid) ?? 0
    }

    public func startMicrophone() {
        voiceFlaggedPackets = 5
        isSendingAudio = true
        try? audioEngine?.start()
    }

    public func stopMicrophone() {
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
            try? sendPacket(body: whisper)
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
            try? sendPacket(body: voice)
            voiceFlaggedPackets = 5
            voiceSessionId = voiceSessionId == 7 ? 1 : voiceSessionId + 1
        }
        audioEngine?.stop()
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
        for id in pingQueue.keys {
            guard var response = pingQueue[id], response.shouldResend(now: now) else { continue }
            log(.debug, "[RESEND] PING id=\(id) retry=\(response.retries + 1)")
            sendRaw(data: response.datagram)
            response.didResend()
            pingQueue[id] = response
        }
    }

    func sendPingIfNeeded() {
        guard state == .connected else { return }
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

    func disconnectInternal(error: Error?) {
        connection?.cancel()
        connection = nil
        audioEngine?.stop()
        state = .disconnected
        sendQueue.removeAll()
        sendQueueLow.removeAll()
        pingQueue.removeAll()
        pendingCommands.removeAll()
        channelCache.removeAll()
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
            TS3CommandSingleParameter(name: "client_default_channel", value: nil),
            TS3CommandSingleParameter(name: "client_default_channel_password", value: nil),
            TS3CommandSingleParameter(name: "client_server_password", value: config.serverPassword),
            TS3CommandSingleParameter(name: "client_nickname_phonetic", value: nil),
            TS3CommandSingleParameter(name: "client_meta_data", value: ""),
            TS3CommandSingleParameter(name: "client_default_token", value: nil),
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
                audioEngine?.handleIncoming(packet: voice.codecData)
            }
        case .voiceWhisper:
            if let whisper = packet.body as? TS3PacketBodyVoiceWhisper,
               whisper.codecType == 4 || whisper.codecType == 5 {
                audioEngine?.handleIncoming(packet: whisper.codecData)
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
            if let channel = channelFromCommand(command) {
                channelCache[channel.id] = channel
            }
            return
        }

        if command.name == "channellistfinished" {
            state = .connected
            connectContinuation?.resume()
            connectContinuation = nil
            log(.info, "channel list completed")
            let channels = channelCache.values.sorted { $0.id < $1.id }
            DispatchQueue.main.async {
                self.delegate?.ts3Client(self, didUpdateChannels: channels)
            }
            DispatchQueue.main.async {
                self.delegate?.ts3ClientDidConnect(self)
            }
            return
        }

        if command.name == "notifyclientmoved" {
            if let clid = command.get("clid")?.value,
               UInt16(clid) == clientId,
               let cidValue = command.get("cid")?.value,
               let cid = Int(cidValue) {
                currentChannelId = cid
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
        return TS3Channel(id: cid, name: name, topic: topic)
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
    func loadIdentity() async throws -> TS3Identity {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let fileURL = baseURL.appendingPathComponent("ts3-identity.key")

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
        var saveData = Data(identity.privateKeyBytes)
        var offset = UInt32(identity.keyOffset).bigEndian
        saveData.append(Data(bytes: &offset, count: 4))
        try saveData.write(to: fileURL, options: .atomic)
        return identity
    }
}

private extension TS3Client {
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
