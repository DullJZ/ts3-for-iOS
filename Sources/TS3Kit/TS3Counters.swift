import Foundation

protocol TS3RemoteCounter {
    func generation(for packetId: UInt16) -> Int
    func currentGeneration() -> Int
    func currentPacketId() -> UInt16
    func put(_ packetId: UInt16) -> Bool
    func reset()
}

final class TS3RemoteCounterZero: TS3RemoteCounter {
    func generation(for packetId: UInt16) -> Int { 0 }
    func currentGeneration() -> Int { 0 }
    func currentPacketId() -> UInt16 { 0 }
    func put(_ packetId: UInt16) -> Bool { true }
    func reset() {}
}

final class TS3RemoteCounterFull: TS3RemoteCounter {
    private var buffer: [Int?]
    private let bufferSize: Int
    private let generationSize: Int

    private var bufferStart: (gen: Int, pos: Int) = (0, 0)
    private var bufferEnd: (gen: Int, pos: Int)
    private var latestPacketId: UInt16 = 0

    init(generationSize: Int, windowSize: Int) {
        precondition(windowSize < generationSize)
        self.bufferSize = windowSize
        self.generationSize = generationSize
        self.buffer = Array(repeating: nil, count: windowSize)
        self.bufferEnd = (0, windowSize - 1)
    }

    func generation(for packetId: UInt16) -> Int {
        let packet = Int(packetId) % generationSize
        let start = bufferStart
        let end = bufferEnd

        if packet >= start.pos && packet < start.pos + bufferSize && packet < generationSize {
            return start.gen
        }

        if packet <= end.pos && packet > 0 && packet > end.pos - bufferSize && packet < generationSize {
            return end.gen
        }

        if packet > end.pos {
            return end.gen
        }

        if packet < start.pos {
            return end.gen + 1
        }

        return end.gen
    }

    func currentGeneration() -> Int {
        bufferEnd.gen
    }

    func currentPacketId() -> UInt16 {
        latestPacketId
    }

    func put(_ packetId: UInt16) -> Bool {
        let packet = Int(packetId)
        if packet >= bufferStart.pos && packet < bufferStart.pos + bufferSize && packet < generationSize {
            latestPacketId = max(latestPacketId, packetId)
            return putRelative(index: packet - bufferStart.pos, generation: bufferStart.gen)
        }

        if packet <= bufferEnd.pos && packet >= 0 && packet > bufferEnd.pos - bufferSize && packet < generationSize {
            latestPacketId = max(latestPacketId, packetId)
            let index = bufferSize - (bufferEnd.pos - packet) - 1
            return putRelative(index: index, generation: bufferEnd.gen)
        }

        var amountMoved = 0
        if packet > bufferEnd.pos {
            amountMoved = packet - bufferEnd.pos
        }

        if packet < bufferStart.pos {
            amountMoved = (generationSize - bufferStart.pos) + packet + 1
            amountMoved -= bufferSize
        }

        if amountMoved > 0 {
            let toMove = max(0, bufferSize - amountMoved)
            if toMove > 0 && toMove < bufferSize {
                for i in 0..<toMove {
                    buffer[i] = buffer[i + amountMoved]
                }
            }
            let toNullify = max(0, min(bufferSize, amountMoved))
            if toNullify > 0 {
                for i in (bufferSize - toNullify)..<bufferSize {
                    buffer[i] = nil
                }
            }

            var startPos = bufferStart.pos + amountMoved
            var startGen = bufferStart.gen
            if startPos >= generationSize {
                startPos %= generationSize
                startGen += 1
            }

            let endPos = (startPos + bufferSize - 1) % generationSize
            let endGen = endPos < startPos ? startGen + 1 : startGen

            bufferStart = (startGen, startPos)
            bufferEnd = (endGen, endPos)

            latestPacketId = packetId
            return put(packetId)
        }

        return false
    }

    func reset() {
        buffer = Array(repeating: nil, count: bufferSize)
        bufferStart = (0, 0)
        bufferEnd = (0, bufferSize - 1)
        latestPacketId = 0
    }

    private func putRelative(index: Int, generation: Int) -> Bool {
        if buffer[index] == nil || buffer[index] != generation {
            buffer[index] = generation
            return true
        }
        return false
    }
}

protocol TS3LocalCounter {
    var packetId: UInt16 { get set }
    var generation: Int { get set }
    func next() -> (UInt16, Int)
    func next(_ count: Int) -> (UInt16, Int)
    func reset()
}

final class TS3LocalCounterZero: TS3LocalCounter {
    var packetId: UInt16 = 0
    var generation: Int = 0

    func next() -> (UInt16, Int) { (0, 0) }
    func next(_ count: Int) -> (UInt16, Int) { (0, 0) }
    func reset() {}
}

final class TS3LocalCounterFull: TS3LocalCounter {
    let generationSize: Int
    let counting: Bool
    private let lock = NSLock()

    var packetId: UInt16 = 0
    var generation: Int = 0

    init(generationSize: Int, counting: Bool) {
        self.generationSize = generationSize
        self.counting = counting
    }

    func next() -> (UInt16, Int) {
        lock.lock(); defer { lock.unlock() }
        setPacketId(Int(packetId) + 1)
        return (packetId, generation)
    }

    func next(_ count: Int) -> (UInt16, Int) {
        var current = (packetId, generation)
        for _ in 0..<count {
            current = next()
        }
        return current
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        packetId = 0
        generation = 0
    }

    private func setPacketId(_ value: Int) {
        if value >= generationSize {
            packetId = 0
            if counting { generation += 1 }
        } else {
            packetId = UInt16(value)
        }
    }
}
