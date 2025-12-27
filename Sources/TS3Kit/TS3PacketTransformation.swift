import Foundation

class TS3PacketTransformation {
    private let ivStruct: [UInt8]
    private let fakeMac: [UInt8]

    init(ivStruct: [UInt8], fakeMac: [UInt8]) {
        self.ivStruct = ivStruct
        self.fakeMac = fakeMac
    }

    func computeParameters(header: TS3PacketHeader) -> (key: [UInt8], nonce: [UInt8]) {
        var buffer = TS3ByteBuffer()
        let roleByte: UInt8 = header.role == .server ? 0x30 : 0x31
        buffer.writeUInt8(roleByte)
        buffer.writeUInt8(header.type.rawValue)
        buffer.writeUInt32(UInt32(header.generation))
        buffer.writeBytes(ivStruct)

        let keyNonce = TS3Crypto.hash256([UInt8](buffer.data))
        var key = Array(keyNonce.prefix(16))
        let nonce = Array(keyNonce.suffix(16))

        key[0] = key[0] ^ UInt8((header.packetId >> 8) & 0xFF)
        key[1] = key[1] ^ UInt8(header.packetId & 0xFF)

        return (key, nonce)
    }

    func encrypt(packet: TS3Packet) throws -> Data {
        let headerWithoutMac = Array(packet.header.write(includeMac: false).dropFirst(8))
        let params = computeParameters(header: packet.header)

        var bodyBuffer = TS3ByteBuffer()
        try packet.body.write(to: &bodyBuffer, header: packet.header)
        let plaintext = [UInt8](bodyBuffer.data)

        let (ciphertext, tag) = try TS3EAX.encrypt(
            key: params.key,
            nonce: params.nonce,
            header: headerWithoutMac,
            plaintext: plaintext,
            tagSize: 8
        )

        var header = packet.header
        header.mac = tag

        var output = Data()
        output.append(contentsOf: tag)
        output.append(contentsOf: headerWithoutMac)
        output.append(contentsOf: ciphertext)
        return output
    }

    func decrypt(header: TS3PacketHeader, buffer: Data) throws -> Data {
        let headerWithoutMac = Array(buffer.dropFirst(8).prefix(header.size - 8))
        let params = computeParameters(header: header)
        let mac = [UInt8](buffer.prefix(8))
        let ciphertext = [UInt8](buffer.dropFirst(header.size))

        // Debug logging
        print("[DECRYPT DEBUG] packetId=\(header.packetId) type=\(header.type) generation=\(header.generation)")
        print("[DECRYPT DEBUG] key=\(params.key.map { String(format: "%02X", $0) }.joined())")
        print("[DECRYPT DEBUG] nonce=\(params.nonce.map { String(format: "%02X", $0) }.joined())")
        print("[DECRYPT DEBUG] mac=\(mac.map { String(format: "%02X", $0) }.joined())")
        print("[DECRYPT DEBUG] headerWithoutMac=\(headerWithoutMac.map { String(format: "%02X", $0) }.joined())")
        print("[DECRYPT DEBUG] ciphertext.len=\(ciphertext.count)")

        let plaintext = try TS3EAX.decrypt(
            key: params.key,
            nonce: params.nonce,
            header: headerWithoutMac,
            ciphertext: ciphertext,
            tag: mac
        )

        return Data(plaintext)
    }

    func fakeSignature() -> [UInt8] {
        fakeMac
    }
}

final class TS3InitPacketTransformation: TS3PacketTransformation {
    init() {
        super.init(ivStruct: TS3Crypto.initKey, fakeMac: [UInt8](repeating: 0, count: 8))
    }

    override func computeParameters(header: TS3PacketHeader) -> (key: [UInt8], nonce: [UInt8]) {
        return (TS3Crypto.initKey, TS3Crypto.initNonce)
    }
}
