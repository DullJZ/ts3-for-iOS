import Foundation

enum TS3ProtocolRole {
    case client
    case server

    var outbound: TS3ProtocolRole {
        self == .client ? .client : .server
    }

    var inbound: TS3ProtocolRole {
        self == .client ? .server : .client
    }
}

enum TS3PacketKind {
    case speech
    case keepalive
    case control
}

enum TS3PacketBodyType: UInt8, CaseIterable {
    case voice = 0x0
    case voiceWhisper = 0x1
    case command = 0x2
    case commandLow = 0x3
    case ping = 0x4
    case pong = 0x5
    case ack = 0x6
    case ackLow = 0x7
    case init1 = 0x8

    var kind: TS3PacketKind {
        switch self {
        case .voice, .voiceWhisper:
            return .speech
        case .ping, .pong:
            return .keepalive
        case .ack, .ackLow, .init1, .command, .commandLow:
            return .control
        }
    }

    var acknowledgedBy: TS3PacketBodyType? {
        switch self {
        case .ping:
            return .pong
        case .command:
            return .ack
        case .commandLow:
            return .ackLow
        default:
            return nil
        }
    }

    var canEncrypt: Bool {
        switch self {
        case .command, .commandLow, .ack, .ackLow, .voice, .voiceWhisper:
            return true
        case .ping, .pong, .init1:
            return false
        }
    }

    var canResend: Bool {
        switch self {
        case .command, .commandLow, .ack, .ackLow, .init1:
            return true
        default:
            return false
        }
    }

    var isSplittable: Bool {
        switch self {
        case .command, .commandLow:
            return true
        default:
            return false
        }
    }

    var isCompressible: Bool {
        switch self {
        case .command, .commandLow:
            return true
        default:
            return false
        }
    }

    var mustEncrypt: Bool {
        switch self {
        case .command, .commandLow:
            return true
        default:
            return false
        }
    }
}

struct TS3HeaderFlags: OptionSet {
    let rawValue: UInt8

    static let none = TS3HeaderFlags([])
    static let fragmented = TS3HeaderFlags(rawValue: 0x10)
    static let newProtocol = TS3HeaderFlags(rawValue: 0x20)
    static let compressed = TS3HeaderFlags(rawValue: 0x40)
    static let unencrypted = TS3HeaderFlags(rawValue: 0x80)
}

struct TS3PacketHeader {
    var role: TS3ProtocolRole
    var mac: [UInt8]
    var packetId: UInt16
    var clientId: UInt16?
    var type: TS3PacketBodyType
    var flags: TS3HeaderFlags
    var generation: Int

    init(role: TS3ProtocolRole,
         mac: [UInt8] = Array(repeating: 0, count: 8),
         packetId: UInt16 = 0,
         clientId: UInt16? = nil,
         type: TS3PacketBodyType,
         flags: TS3HeaderFlags = [],
         generation: Int = 0) {
        self.role = role
        self.mac = mac
        self.packetId = packetId
        self.clientId = clientId
        self.type = type
        self.flags = flags
        self.generation = generation
    }

    var size: Int {
        switch role {
        case .client:
            return 8 + 2 + 2 + 1
        case .server:
            return 8 + 2 + 1
        }
    }

    mutating func read(from buffer: inout TS3ByteBuffer) throws {
        mac = Array(buffer.readBytes(count: 8))
        packetId = buffer.readUInt16()

        switch role {
        case .client:
            clientId = buffer.readUInt16()
            let typeAndFlags = buffer.readUInt8()
            type = TS3PacketBodyType(rawValue: typeAndFlags & 0x0F) ?? .command
            flags = TS3HeaderFlags(rawValue: typeAndFlags & 0xF0)
        case .server:
            let typeAndFlags = buffer.readUInt8()
            type = TS3PacketBodyType(rawValue: typeAndFlags & 0x0F) ?? .command
            flags = TS3HeaderFlags(rawValue: typeAndFlags & 0xF0)
        }
    }

    func write(includeMac: Bool = true) -> Data {
        var buffer = TS3ByteBuffer()
        if includeMac {
            buffer.writeBytes(mac)
        } else {
            buffer.writeBytes(Array(repeating: 0, count: 8))
        }
        buffer.writeUInt16(packetId)

        switch role {
        case .client:
            buffer.writeUInt16(clientId ?? 0)
            let typeAndFlags = (type.rawValue & 0x0F) | flags.rawValue
            buffer.writeUInt8(typeAndFlags)
        case .server:
            let typeAndFlags = (type.rawValue & 0x0F) | flags.rawValue
            buffer.writeUInt8(typeAndFlags)
        }

        return buffer.data
    }
}

protocol TS3PacketBody {
    var type: TS3PacketBodyType { get }
    var role: TS3ProtocolRole { get }
    var size: Int { get }

    mutating func read(from buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws
    func write(to buffer: inout TS3ByteBuffer, header: TS3PacketHeader) throws
    func applyHeaderFlags(to header: inout TS3PacketHeader)
}

extension TS3PacketBody {
    func applyHeaderFlags(to header: inout TS3PacketHeader) {
        // default no-op
    }
}

struct TS3Packet {
    var header: TS3PacketHeader
    var body: any TS3PacketBody

    var size: Int {
        header.size + body.size
    }
}
