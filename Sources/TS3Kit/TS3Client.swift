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
    private var transformation: TS3PacketTransformation = TS3InitPacketTransformation()

    private var state: TS3ConnectionState = .disconnected
    private var clientId: UInt16 = 0
    private var serverId: Int?

    private var randomBytes: [UInt8] = []
    private var alphaBytes: [UInt8]?

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

        state = .connecting
        channelCache.removeAll()
        identity = try await loadIdentity()
        log(.info, "connecting to \(config.host):\(config.port)")
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
            sendRaw(data: response.datagram)
            response.didResend()
            sendQueue[id] = response
        }
        for id in sendQueueLow.keys {
            guard var response = sendQueueLow[id], response.shouldResend(now: now) else { continue }
            sendRaw(data: response.datagram)
            response.didResend()
            sendQueueLow[id] = response
        }
        for id in pingQueue.keys {
            guard var response = pingQueue[id], response.shouldResend(now: now) else { continue }
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
            log(.info, "init1 step1 received")
            let reply = TS3Init1Step2(serverStuff: step.serverStuff, a0reversed: step.a0reversed)
            let packet = TS3PacketBodyInit1(role: .client, version: [0x0C, 0xFF, 0xD2, 0xFE], step: reply)
            try sendPacket(body: packet)

        case let step as TS3Init1Step3:
            log(.info, "init1 step3 received, level \(step.level)")
            guard step.level >= 0 && step.level <= 1_000_000 else {
                throw TS3Error.invalidInitStep
            }

            let x = BigUInt(step.x)
            let n = BigUInt(step.n)
            var y = x
            for _ in 0..<step.level {
                y = (y * y) % n
            }

            var yBytes = [UInt8](y.serialize())
            if yBytes.count < 64 {
                let pad = [UInt8](repeating: 0, count: 64 - yBytes.count)
                yBytes = pad + yBytes
            } else if yBytes.count > 64 {
                yBytes = Array(yBytes.suffix(64))
            }
            let initiv = try createInitIv()

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
            try sendInit1Step0()
        default:
            throw TS3Error.invalidInitStep
        }
    }

    func createInitIv() throws -> String {
        alphaBytes = (0..<10).map { _ in UInt8.random(in: 0...255) }
        guard let identity else {
            throw TS3Error.invalidIdentity
        }

        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "alpha", value: Data(alphaBytes ?? []).base64EncodedString()),
            TS3CommandSingleParameter(name: "omega", value: identity.publicKeyString),
            TS3CommandSingleParameter(name: "ot", value: "1")
        ]

        if let endpoint = connection?.endpoint, case .hostPort(let host, _) = endpoint {
            params.append(TS3CommandSingleParameter(name: "ip", value: host.debugDescription))
        }

        let command = TS3SingleCommand(name: "clientinitiv", parameters: params)
        return command.build()
    }

    func handleInitCommand(_ command: TS3SingleCommand) throws {
        guard let identity else {
            throw TS3Error.invalidIdentity
        }

        if command.name == "initivexpand" {
            log(.info, "initivexpand received")
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
            log(.info, "initivexpand2 received")
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

            var ekPrivate = (0..<32).map { _ in UInt8.random(in: 0...255) }
            TS3Ed25519.clamp(&ekPrivate)
            let ekPublic = try TS3Ed25519.scalarMultBase(privateKey: ekPrivate)

            let signature = try TS3Crypto.generateClientEkProof(key: ekPublic, beta: betaBytes, identity: identity)
            let ekCommand = TS3SingleCommand(
                name: "clientek",
                parameters: [
                    TS3CommandSingleParameter(name: "ek", value: Data(ekPublic).base64EncodedString()),
                    TS3CommandSingleParameter(name: "proof", value: Data(signature).base64EncodedString())
                ]
            )
            try sendCommand(ekCommand)

            let alpha = alphaBytes ?? []
            let params = try TS3Crypto.cryptoInit2(license: licenseBytes, alpha: alpha, beta: betaBytes, privateKey: ekPrivate)
            transformation = TS3PacketTransformation(ivStruct: params.ivStruct, fakeMac: params.fakeMac)
            self.alphaBytes = nil

            try sendClientInit()
            state = .retrieving
            log(.info, "clientinit sent")
        } else if command.name == "error" {
            log(.error, "init error: \(command.get(\"msg\")?.value ?? \"unknown\")")
            throw TS3Error.serverError(message: command.get("msg")?.value ?? "unknown")
        } else {
            throw TS3Error.invalidCommand
        }
    }

    func sendClientInit() throws {
        guard let identity else {
            throw TS3Error.invalidIdentity
        }

        var params: [TS3CommandParameter] = [
            TS3CommandSingleParameter(name: "client_nickname", value: config.nickname),
            TS3CommandSingleParameter(name: "client_version", value: "3.?.? [Build: 5680278000]"),
            TS3CommandSingleParameter(name: "client_platform", value: "iOS"),
            TS3CommandSingleParameter(name: "client_version_sign", value: "DX5NIYLvfJEUjuIbCidnoeozxIDRRkpq3I9vVMBmE9L2qnekOoBzSenkzsg2lC9CMv8K5hkEzhr2TYUYSwUXCg=="),
            TS3CommandSingleParameter(name: "client_input_hardware", value: "1"),
            TS3CommandSingleParameter(name: "client_output_hardware", value: "1"),
            TS3CommandSingleParameter(name: "client_key_offset", value: String(identity.keyOffset)),
            TS3CommandSingleParameter(name: "hwid", value: "+LyYqbDqOvEEpN5pdAbF8/v5kZ0=")
        ]

        if let password = config.serverPassword, !password.isEmpty {
            params.append(TS3CommandSingleParameter(name: "client_server_password", value: password))
        }

        let command = TS3SingleCommand(name: "clientinit", parameters: params)
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

            let packet = try readPacket(header: header, buffer: data)
            if packet.header.type.isSplittable,
               let reassembly = reassemblyQueues[packet.header.type] {
                reassembly.put(packet)
                if let reassembled = try reassembly.next() {
                    handlePacket(reassembled)
                }
            } else {
                handlePacket(packet)
            }

            lastResponse = Date()
        } catch {
            // swallow parse errors for now
        }
    }

    func readPacket(header: TS3PacketHeader, buffer: Data) throws -> TS3Packet {
        var payload: Data
        if !header.flags.contains(.unencrypted) {
            payload = try transformation.decrypt(header: header, buffer: buffer)
        } else {
            payload = buffer.dropFirst(header.size)
        }

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
        if let ackType = packet.header.type.acknowledgedBy {
            switch ackType {
            case .ack:
                let ack = TS3PacketBodyAck(role: .client, packetId: packet.header.packetId)
                try? sendPacket(body: ack)
            case .ackLow:
                let ack = TS3PacketBodyAckLow(role: .client, packetId: packet.header.packetId)
                try? sendPacket(body: ack)
            case .pong:
                let pong = TS3PacketBodyPong(role: .client, packetId: packet.header.packetId)
                try? sendPacket(body: pong)
            default:
                break
            }
        }

        switch packet.header.type {
        case .ack:
            if let ack = packet.body as? TS3PacketBodyAck {
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
            if var init1 = packet.body as? TS3PacketBodyInit1 {
                try? handleInit1(init1)
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
            break
        case .voiceWhisper:
            if let whisper = packet.body as? TS3PacketBodyVoiceWhisper,
               whisper.codecType == 4 || whisper.codecType == 5 {
                audioEngine?.handleIncoming(packet: whisper.codecData)
            }
            break
        default:
            break
        }
    }
}

// MARK: - Commands
private extension TS3Client {
    func sendCommand(_ command: TS3SingleCommand) throws {
        var body = TS3PacketBodyCommand(role: .client, text: command.build())
        log(.info, "send cmd: \(command.name)")
        try sendPacket(body: body)
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

        if state == .connecting && command.name == "error" {
            try? handleInitCommand(command)
            return
        }

        if command.name == "initserver" {
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
    func sendPacket(body: any TS3PacketBody) throws {
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
        try sendPacket(packet)
    }

    func sendPacket(_ packet: TS3Packet) throws {
        if packet.header.type.isSplittable {
            let pieces = try TS3Fragments.split(packet: packet)
            for piece in pieces {
                try sendPacketInternal(piece)
            }
        } else {
            if packet.size > TS3Fragments.maximumPacketSize {
                throw TS3Error.packetTooLarge
            }
            try sendPacketInternal(packet)
        }
    }

    func sendPacketInternal(_ packet: TS3Packet) throws {
        var header = packet.header
        guard let counter = localCounters[header.type] else {
            throw TS3Error.invalidState
        }

        switch header.type {
        case .ack:
            if let ack = packet.body as? TS3PacketBodyAck, let remote = remoteCounters[.ack] {
                header.generation = remote.generation(for: ack.packetId)
            }
            let next = counter.next()
            header.packetId = next.0
        case .ackLow:
            if let ack = packet.body as? TS3PacketBodyAckLow, let remote = remoteCounters[.ackLow] {
                header.generation = remote.generation(for: ack.packetId)
            }
            let next = counter.next()
            header.packetId = next.0
        case .pong:
            if let pong = packet.body as? TS3PacketBodyPong, let remote = remoteCounters[.pong] {
                header.generation = remote.generation(for: pong.packetId)
            }
            let next = counter.next()
            header.packetId = next.0
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
        let data: Data
        if !header.flags.contains(.unencrypted) {
            data = try transformation.encrypt(packet: outgoing)
        } else {
            var buffer = TS3ByteBuffer()
            buffer.writeBytes(header.write())
            var bodyBuffer = TS3ByteBuffer()
            try body.write(to: &bodyBuffer, header: header)
            buffer.writeBytes(bodyBuffer.data)
            data = buffer.data
        }

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
    }
}

// MARK: - Identity
private extension TS3Client {
    func loadIdentity() async throws -> TS3Identity {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let fileURL = baseURL.appendingPathComponent("ts3-identity.key")

        if let data = try? Data(contentsOf: fileURL), data.count == 32 {
            return try TS3Identity(privateKeyBytes: [UInt8](data))
        }

        let identity = try TS3Identity.generate(securityLevel: 8)
        try Data(identity.privateKeyBytes).write(to: fileURL, options: .atomic)
        return identity
    }
}

private extension TS3Client {
    func log(_ level: TS3LogLevel, _ message: String) {
        logHandler?(TS3LogEntry(timestamp: Date(), level: level, message: message))
    }
}

// MARK: - Supporting Types
private enum TS3ConnectionState {
    case disconnected
    case connecting
    case retrieving
    case connected
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
