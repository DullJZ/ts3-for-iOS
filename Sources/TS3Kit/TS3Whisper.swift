import Foundation

enum TS3GroupWhisperType: UInt8 {
    case serverGroup = 0
    case channelGroup = 1
    case channelCommander = 2
    case allClients = 3
}

enum TS3GroupWhisperTarget: UInt8 {
    case allChannels = 0
    case currentChannel = 1
    case parentChannel = 2
    case allParentChannels = 3
    case channelFamily = 4
    case completeChannelFamily = 5
    case subchannels = 6
}

enum TS3WhisperTarget {
    case serverToClient
    case multiple(channelIds: [UInt64], clientIds: [UInt16])
    case group(type: TS3GroupWhisperType, target: TS3GroupWhisperTarget, targetId: UInt64)

    var size: Int {
        switch self {
        case .serverToClient:
            return 0
        case let .multiple(channelIds, clientIds):
            return 2 + (channelIds.count * 8) + (clientIds.count * 2)
        case .group:
            return 1 + 1 + 8
        }
    }

    func write(to buffer: inout TS3ByteBuffer) {
        switch self {
        case .serverToClient:
            break
        case let .multiple(channelIds, clientIds):
            buffer.writeUInt8(UInt8(channelIds.count & 0xFF))
            buffer.writeUInt8(UInt8(clientIds.count & 0xFF))
            for channelId in channelIds {
                buffer.writeUInt64(channelId)
            }
            for clientId in clientIds {
                buffer.writeUInt16(clientId)
            }
        case let .group(type, target, targetId):
            buffer.writeUInt8(type.rawValue)
            buffer.writeUInt8(target.rawValue)
            buffer.writeUInt64(targetId)
        }
    }

    static func read(from buffer: inout TS3ByteBuffer, role: TS3ProtocolRole, newProtocol: Bool) -> TS3WhisperTarget {
        if role == .server {
            return .serverToClient
        }

        if newProtocol {
            let type = TS3GroupWhisperType(rawValue: buffer.readUInt8()) ?? .allClients
            let target = TS3GroupWhisperTarget(rawValue: buffer.readUInt8()) ?? .allChannels
            let targetId = buffer.readUInt64()
            return .group(type: type, target: target, targetId: targetId)
        }

        let channelCount = Int(buffer.readUInt8())
        let clientCount = Int(buffer.readUInt8())
        var channelIds: [UInt64] = []
        var clientIds: [UInt16] = []

        for _ in 0..<channelCount {
            channelIds.append(buffer.readUInt64())
        }
        for _ in 0..<clientCount {
            clientIds.append(buffer.readUInt16())
        }

        return .multiple(channelIds: channelIds, clientIds: clientIds)
    }

    static func channel(_ channelId: Int) -> TS3WhisperTarget {
        .multiple(channelIds: [UInt64(channelId)], clientIds: [])
    }

    static func client(_ clientId: Int) -> TS3WhisperTarget {
        .multiple(channelIds: [], clientIds: [UInt16(clientId)])
    }

    static func server() -> TS3WhisperTarget {
        .group(type: .allClients, target: .allChannels, targetId: 0)
    }
}
