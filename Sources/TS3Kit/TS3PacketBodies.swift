import Foundation

struct TS3PacketBodyCommand: TS3PacketBody {
    let type: TS3PacketBodyType = .command
    let role: TS3ProtocolRole
    var text: String

    var size: Int {
        text.data(using: .utf8)?.count ?? 0
    }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        text = buffer.readString()
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        if let data = text.data(using: .utf8) {
            buffer.writeBytes(data)
        }
    }

    init(role: TS3ProtocolRole, text: String = "") {
        self.role = role
        self.text = text
    }
}

struct TS3PacketBodyCommandLow: TS3PacketBody {
    let type: TS3PacketBodyType = .commandLow
    let role: TS3ProtocolRole
    var text: String

    var size: Int {
        text.data(using: .utf8)?.count ?? 0
    }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        text = buffer.readString()
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        if let data = text.data(using: .utf8) {
            buffer.writeBytes(data)
        }
    }
}

struct TS3PacketBodyPing: TS3PacketBody {
    let type: TS3PacketBodyType = .ping
    let role: TS3ProtocolRole

    var size: Int { 0 }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {}
    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {}

    func applyHeaderFlags(to header: inout TS3PacketHeader) {
        header.flags.insert(.unencrypted)
    }

    init(role: TS3ProtocolRole) {
        self.role = role
    }
}

struct TS3PacketBodyPong: TS3PacketBody {
    let type: TS3PacketBodyType = .pong
    let role: TS3ProtocolRole
    var packetId: UInt16

    var size: Int { 2 }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        packetId = buffer.readUInt16()
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        buffer.writeUInt16(packetId)
    }

    func applyHeaderFlags(to header: inout TS3PacketHeader) {
        header.flags.insert(.unencrypted)
    }
}

struct TS3PacketBodyAck: TS3PacketBody {
    let type: TS3PacketBodyType = .ack
    let role: TS3ProtocolRole
    var packetId: UInt16

    var size: Int { 2 }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        packetId = buffer.readUInt16()
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        buffer.writeUInt16(packetId)
    }
}

struct TS3PacketBodyAckLow: TS3PacketBody {
    let type: TS3PacketBodyType = .ackLow
    let role: TS3ProtocolRole
    var packetId: UInt16

    var size: Int { 2 }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        packetId = buffer.readUInt16()
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        buffer.writeUInt16(packetId)
    }
}

struct TS3PacketBodyVoice: TS3PacketBody {
    let type: TS3PacketBodyType = .voice
    let role: TS3ProtocolRole
    var packetId: UInt16
    var clientId: UInt16?
    var codecType: UInt8
    var codecData: Data
    var serverFlag0: UInt8?

    var size: Int {
        2 + (role == .server ? 2 : 0) + 1 + codecData.count + (serverFlag0 != nil ? 1 : 0)
    }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        packetId = buffer.readUInt16()
        if role == .server {
            clientId = buffer.readUInt16()
        }
        codecType = buffer.readUInt8()

        var padding = 0
        if header.flags.contains(.compressed) {
            padding += 1
        }

        let dataLen = max(0, buffer.remaining - padding)
        codecData = buffer.readBytes(count: dataLen)

        if header.flags.contains(.compressed) {
            serverFlag0 = buffer.readUInt8()
        }
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        buffer.writeUInt16(packetId)
        if role == .server, let clientId {
            buffer.writeUInt16(clientId)
        }
        buffer.writeUInt8(codecType)
        buffer.writeBytes(codecData)
        if let serverFlag0 {
            buffer.writeUInt8(serverFlag0)
        }
    }

    func applyHeaderFlags(to header: inout TS3PacketHeader) {
        if serverFlag0 != nil {
            header.flags.insert(.compressed)
        }
    }
}

struct TS3PacketBodyVoiceWhisper: TS3PacketBody {
    let type: TS3PacketBodyType = .voiceWhisper
    let role: TS3ProtocolRole
    var packetId: UInt16
    var clientId: UInt16?
    var codecType: UInt8
    var target: TS3WhisperTarget
    var codecData: Data
    var serverFlag0: UInt8?

    var size: Int {
        switch role {
        case .client:
            return 2 + 1 + target.size + codecData.count + (serverFlag0 != nil ? 1 : 0)
        case .server:
            return 2 + 2 + 1 + codecData.count + (serverFlag0 != nil ? 1 : 0)
        }
    }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        var padding = 0
        if header.flags.contains(.compressed) {
            padding += 1
        }

        packetId = buffer.readUInt16()
        if role == .server {
            clientId = buffer.readUInt16()
        }
        codecType = buffer.readUInt8()

        if role == .client {
            target = TS3WhisperTarget.read(from: &buffer, role: role, newProtocol: header.flags.contains(.newProtocol))
        } else {
            target = .serverToClient
        }

        let dataLen = max(0, buffer.remaining - padding)
        codecData = buffer.readBytes(count: dataLen)

        if padding > 0 {
            serverFlag0 = buffer.readUInt8()
        }
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        buffer.writeUInt16(packetId)
        if role == .server, let clientId {
            buffer.writeUInt16(clientId)
        }
        buffer.writeUInt8(codecType)
        if role == .client {
            target.write(to: &buffer)
        }
        buffer.writeBytes(codecData)
        if let serverFlag0 {
            buffer.writeUInt8(serverFlag0)
        }
    }

    func applyHeaderFlags(to header: inout TS3PacketHeader) {
        if case .group = target {
            header.flags.insert(.newProtocol)
        } else {
            header.flags.remove(.newProtocol)
        }
        if serverFlag0 != nil {
            header.flags.insert(.compressed)
        }
    }
}

struct TS3PacketBodyCompressed: TS3PacketBody {
    let type: TS3PacketBodyType
    let role: TS3ProtocolRole
    var compressed: Data

    var size: Int { compressed.count }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        compressed = buffer.readBytes(count: buffer.remaining)
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        buffer.writeBytes(compressed)
    }
}

struct TS3PacketBodyFragment: TS3PacketBody {
    let type: TS3PacketBodyType
    let role: TS3ProtocolRole
    var raw: Data

    var size: Int { raw.count }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        raw = buffer.readBytes(count: buffer.remaining)
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        buffer.writeBytes(raw)
    }
}

struct TS3PacketBodyInit1: TS3PacketBody {
    let type: TS3PacketBodyType = .init1
    let role: TS3ProtocolRole
    var version: [UInt8]
    var step: TS3Init1Step

    init(role: TS3ProtocolRole, version: [UInt8] = [0, 0, 0, 0], step: TS3Init1Step) {
        self.role = role
        self.version = version
        self.step = step
    }

    var size: Int {
        (role == .client ? 4 : 0) + 1 + step.size
    }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        if role == .client {
            version = Array(buffer.readBytes(count: 4))
        }
        let stepNumber = buffer.readUInt8()
        guard let parsed = TS3Init1Step.decode(stepNumber: stepNumber, role: role, buffer: &buffer) else {
            throw TS3Error.invalidInitStep
        }
        step = parsed
    }

    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws {
        if role == .client {
            buffer.writeBytes(version)
        }
        buffer.writeUInt8(step.stepNumber)
        step.write(to: &buffer)
    }
}

protocol TS3Init1Step {
    var stepNumber: UInt8 { get }
    var role: TS3ProtocolRole { get }
    var size: Int { get }
    func write(to buffer: inout TS3ByteBuffer)
    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step?
}

struct TS3Init1Step0: TS3Init1Step {
    let stepNumber: UInt8 = 0
    let role: TS3ProtocolRole = .client
    var timestamp: [UInt8]
    var random: [UInt8]
    private let reserved = [UInt8](repeating: 0, count: 8)

    var size: Int { 4 + 4 + 8 }

    func write(to buffer: inout TS3ByteBuffer) {
        buffer.writeBytes(timestamp)
        buffer.writeBytes(random)
        buffer.writeBytes(reserved)
    }

    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step? {
        guard stepNumber == 0, role == .client else { return nil }
        let timestamp = Array(buffer.readBytes(count: 4))
        let random = Array(buffer.readBytes(count: 4))
        _ = buffer.readBytes(count: 8)
        return TS3Init1Step0(timestamp: timestamp, random: random)
    }
}

struct TS3Init1Step1: TS3Init1Step {
    let stepNumber: UInt8 = 1
    let role: TS3ProtocolRole = .server
    var serverStuff: [UInt8]
    var a0reversed: [UInt8]

    var size: Int { 16 + 4 }

    func write(to buffer: inout TS3ByteBuffer) {
        buffer.writeBytes(serverStuff)
        buffer.writeBytes(a0reversed)
    }

    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step? {
        guard stepNumber == 1, role == .server else { return nil }
        let serverStuff = Array(buffer.readBytes(count: 16))
        let a0reversed = Array(buffer.readBytes(count: 4))
        return TS3Init1Step1(serverStuff: serverStuff, a0reversed: a0reversed)
    }
}

struct TS3Init1Step2: TS3Init1Step {
    let stepNumber: UInt8 = 2
    let role: TS3ProtocolRole = .client
    var serverStuff: [UInt8]
    var a0reversed: [UInt8]

    var size: Int { 16 + 4 }

    func write(to buffer: inout TS3ByteBuffer) {
        buffer.writeBytes(serverStuff)
        buffer.writeBytes(a0reversed)
    }

    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step? {
        guard stepNumber == 2, role == .client else { return nil }
        let serverStuff = Array(buffer.readBytes(count: 16))
        let a0reversed = Array(buffer.readBytes(count: 4))
        return TS3Init1Step2(serverStuff: serverStuff, a0reversed: a0reversed)
    }
}

struct TS3Init1Step3: TS3Init1Step {
    let stepNumber: UInt8 = 3
    let role: TS3ProtocolRole = .server
    var x: [UInt8]
    var n: [UInt8]
    var level: Int
    var serverStuff: [UInt8]

    var size: Int { 64 + 64 + 4 + 100 }

    func write(to buffer: inout TS3ByteBuffer) {
        buffer.writeBytes(x)
        buffer.writeBytes(n)
        buffer.writeUInt32(UInt32(level))
        buffer.writeBytes(serverStuff)
    }

    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step? {
        guard stepNumber == 3, role == .server else { return nil }
        let x = Array(buffer.readBytes(count: 64))
        let n = Array(buffer.readBytes(count: 64))
        let level = Int(buffer.readUInt32())
        let serverStuff = Array(buffer.readBytes(count: 100))
        return TS3Init1Step3(x: x, n: n, level: level, serverStuff: serverStuff)
    }
}

struct TS3Init1Step4: TS3Init1Step {
    let stepNumber: UInt8 = 4
    let role: TS3ProtocolRole = .client
    var x: [UInt8]
    var n: [UInt8]
    var level: Int
    var serverStuff: [UInt8]
    var y: [UInt8]
    var clientIVCommand: [UInt8]

    var size: Int { 64 + 64 + 4 + 100 + 64 + clientIVCommand.count }

    func write(to buffer: inout TS3ByteBuffer) {
        buffer.writeBytes(x)
        buffer.writeBytes(n)
        buffer.writeUInt32(UInt32(level))
        buffer.writeBytes(serverStuff)
        buffer.writeBytes(y)
        buffer.writeBytes(clientIVCommand)
    }

    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step? {
        guard stepNumber == 4, role == .client else { return nil }
        let x = Array(buffer.readBytes(count: 64))
        let n = Array(buffer.readBytes(count: 64))
        let level = Int(buffer.readUInt32())
        let serverStuff = Array(buffer.readBytes(count: 100))
        let y = Array(buffer.readBytes(count: 64))
        let rest = Array(buffer.readBytes(count: buffer.remaining))
        return TS3Init1Step4(x: x, n: n, level: level, serverStuff: serverStuff, y: y, clientIVCommand: rest)
    }
}

struct TS3Init1Step127: TS3Init1Step {
    let stepNumber: UInt8 = 127
    let role: TS3ProtocolRole = .server
    var size: Int { 0 }

    func write(to buffer: inout TS3ByteBuffer) {}

    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step? {
        guard stepNumber == 127, role == .server else { return nil }
        return TS3Init1Step127()
    }
}

extension TS3Init1Step {
    static func decode(stepNumber: UInt8, role: TS3ProtocolRole, buffer: inout TS3ByteBuffer) -> TS3Init1Step? {
        switch stepNumber {
        case 0: return TS3Init1Step0.decode(stepNumber: stepNumber, role: role, buffer: &buffer)
        case 1: return TS3Init1Step1.decode(stepNumber: stepNumber, role: role, buffer: &buffer)
        case 2: return TS3Init1Step2.decode(stepNumber: stepNumber, role: role, buffer: &buffer)
        case 3: return TS3Init1Step3.decode(stepNumber: stepNumber, role: role, buffer: &buffer)
        case 4: return TS3Init1Step4.decode(stepNumber: stepNumber, role: role, buffer: &buffer)
        case 127: return TS3Init1Step127.decode(stepNumber: stepNumber, role: role, buffer: &buffer)
        default: return nil
        }
    }
}
