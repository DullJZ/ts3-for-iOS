import Foundation

enum TS3PacketFactory {
    static func body(for type: TS3PacketBodyType, role: TS3ProtocolRole) throws -> any TS3PacketBody {
        switch type {
        case .command:
            return TS3PacketBodyCommand(role: role, text: "")
        case .commandLow:
            return TS3PacketBodyCommandLow(role: role, text: "")
        case .ping:
            return TS3PacketBodyPing(role: role)
        case .pong:
            return TS3PacketBodyPong(role: role, packetId: 0)
        case .ack:
            return TS3PacketBodyAck(role: role, packetId: 0)
        case .ackLow:
            return TS3PacketBodyAckLow(role: role, packetId: 0)
        case .voice:
            return TS3PacketBodyVoice(role: role, packetId: 0, clientId: nil, codecType: 0, codecData: Data(), serverFlag0: nil)
        case .voiceWhisper:
            return TS3PacketBodyVoiceWhisper(role: role, packetId: 0, clientId: nil, codecType: 0, target: .serverToClient, codecData: Data(), serverFlag0: nil)
        case .init1:
            return TS3PacketBodyInit1(role: role, version: [0, 0, 0, 0], step: TS3Init1Step0(timestamp: [UInt8](repeating: 0, count: 4), random: [UInt8](repeating: 0, count: 4)))
        }
    }
}
