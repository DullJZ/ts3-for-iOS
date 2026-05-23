import Foundation

enum TS3Fragments {
    static let maximumPacketSize = 500

    static func split(packet: TS3Packet) throws -> [TS3Packet] {
        if packet.size <= maximumPacketSize {
            return [packet]
        }

        var bodyBuffer = TS3ByteBuffer()
        try packet.body.write(to: &bodyBuffer, header: packet.header)
        let raw = [UInt8](bodyBuffer.data)

        let maxFragmentSize = maximumPacketSize - packet.header.size
        var pieces: [TS3Packet] = []
        var offset = 0

        while offset < raw.count {
            let flush = min(maxFragmentSize, raw.count - offset)
            let first = offset == 0
            let hasNext = offset + flush < raw.count
            let last = !hasNext

            var header = packet.header
            if !first {
                header.flags = []
            }
            if packet.header.flags.contains(.newProtocol) {
                header.flags.insert(.newProtocol)
            }
            if first || last {
                header.flags.insert(.fragmented)
            }

            let fragment = TS3PacketBodyFragment(
                type: packet.header.type,
                role: packet.header.role,
                raw: Data(raw[offset..<(offset + flush)])
            )

            let piece = TS3Packet(header: header, body: fragment)
            pieces.append(piece)
            offset += flush
        }

        return pieces
    }
}

final class TS3PacketReassembly {
    private var queue: [UInt16: TS3Packet] = [:]
    private let counter = TS3LocalCounterFull(generationSize: 65536, counting: true)

    func put(_ packet: TS3Packet) {
        queue[packet.header.packetId] = packet
    }

    func next() throws -> TS3Packet? {
        if queue.isEmpty { return nil }
        var reassemblyList: [TS3Packet] = []
        var packetIds: [UInt16] = []

        var tempCounter = TS3LocalCounterFull(generationSize: 65536, counting: true)
        tempCounter.packetId = counter.packetId
        tempCounter.generation = counter.generation

        var state = false

        while true {
            let currentId = tempCounter.packetId
            guard let packet = queue[currentId] else {
                break
            }
            packetIds.append(currentId)
            reassemblyList.append(packet)

            if packet.header.flags.contains(.fragmented) {
                state.toggle()
                if !state {
                    break
                }
            } else if !state {
                break
            }

            _ = tempCounter.next()
        }

        if state || reassemblyList.isEmpty {
            return nil
        }

        let totalLength = reassemblyList.reduce(0) { $0 + $1.body.size }
        let firstPacket = reassemblyList[0]
        var header = firstPacket.header
        header.flags.remove(.fragmented)

        var buffer = TS3ByteBuffer()
        for packet in reassemblyList {
            var bodyBuffer = TS3ByteBuffer()
            try packet.body.write(to: &bodyBuffer, header: packet.header)
            buffer.writeBytes(bodyBuffer.data)
        }

        var combinedData = [UInt8](buffer.data)
        if firstPacket.header.flags.contains(.compressed) {
            combinedData = try TS3QuickLZ.decompress(combinedData, maximum: 1024 * 1024)
        }

        var reassembledBuffer = TS3ByteBuffer(data: Data(combinedData))
        var body = try TS3PacketFactory.body(for: header.type, role: header.role)
        try body.read(from: &reassembledBuffer, header: header)

        packetIds.forEach { queue.removeValue(forKey: $0) }
        _ = counter.next(Int(packetIds.count))

        return TS3Packet(header: header, body: body)
    }

    func reset() {
        queue.removeAll()
        counter.reset()
    }
}
