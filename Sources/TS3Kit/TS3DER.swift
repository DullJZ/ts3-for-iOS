import Foundation

enum TS3DER {
    enum Tag: UInt8 {
        case sequence = 0x30
        case integer = 0x02
        case bitString = 0x03
    }

    struct Element {
        let tag: Tag
        let content: [UInt8]
    }

    struct Reader {
        var bytes: [UInt8]
        var offset: Int = 0

        mutating func readByte() throws -> UInt8 {
            guard offset < bytes.count else {
                throw TS3Error.derDecodeFailed
            }
            let value = bytes[offset]
            offset += 1
            return value
        }

        mutating func readLength() throws -> Int {
            let first = try readByte()
            if first & 0x80 == 0 {
                return Int(first)
            }
            let count = Int(first & 0x7F)
            if count == 0 || count > 4 {
                throw TS3Error.derDecodeFailed
            }
            var length = 0
            for _ in 0..<count {
                length = (length << 8) | Int(try readByte())
            }
            return length
        }

        mutating func readElement() throws -> Element {
            let tagRaw = try readByte()
            guard let tag = Tag(rawValue: tagRaw) else {
                throw TS3Error.derDecodeFailed
            }
            let length = try readLength()
            guard offset + length <= bytes.count else {
                throw TS3Error.derDecodeFailed
            }
            let content = Array(bytes[offset..<offset + length])
            offset += length
            return Element(tag: tag, content: content)
        }
    }

    static func decodeSequence(_ data: [UInt8]) throws -> [Element] {
        var reader = Reader(bytes: data)
        let element = try reader.readElement()
        guard element.tag == .sequence else {
            throw TS3Error.derDecodeFailed
        }
        var innerReader = Reader(bytes: element.content)
        var elements: [Element] = []
        while innerReader.offset < innerReader.bytes.count {
            elements.append(try innerReader.readElement())
        }
        return elements
    }

    static func encodeLength(_ length: Int) -> [UInt8] {
        if length < 0x80 {
            return [UInt8(length)]
        }
        var bytes: [UInt8] = []
        var value = length
        while value > 0 {
            bytes.insert(UInt8(value & 0xFF), at: 0)
            value >>= 8
        }
        return [0x80 | UInt8(bytes.count)] + bytes
    }

    static func encodeInteger(_ bytes: [UInt8]) -> [UInt8] {
        var content = bytes.drop { $0 == 0x00 }
        if content.isEmpty {
            content = [0x00][...]
        }
        var encoded = Array(content)
        if let first = encoded.first, first & 0x80 != 0 {
            encoded.insert(0x00, at: 0)
        }
        return [Tag.integer.rawValue] + encodeLength(encoded.count) + encoded
    }

    static func encodeBitString(unusedBits: UInt8, bytes: [UInt8]) -> [UInt8] {
        let content: [UInt8] = [unusedBits] + bytes
        return [Tag.bitString.rawValue] + encodeLength(content.count) + content
    }

    static func encodeSequence(_ elements: [[UInt8]]) -> [UInt8] {
        let content = elements.flatMap { $0 }
        return [Tag.sequence.rawValue] + encodeLength(content.count) + content
    }
}
