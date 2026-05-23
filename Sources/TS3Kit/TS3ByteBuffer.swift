import Foundation

final class TS3ByteBuffer {
    private var storage: Data
    private(set) var readerIndex: Int

    init(data: Data = Data()) {
        self.storage = data
        self.readerIndex = 0
    }

    var data: Data {
        storage
    }

    var remaining: Int {
        max(0, storage.count - readerIndex)
    }

    func resetReader() {
        readerIndex = 0
    }

    func readUInt8() -> UInt8 {
        let value = storage[readerIndex]
        readerIndex += 1
        return value
    }

    func readUInt16() -> UInt16 {
        let b0 = UInt16(readUInt8())
        let b1 = UInt16(readUInt8())
        return (b0 << 8) | b1
    }

    func readUInt32() -> UInt32 {
        let b0 = UInt32(readUInt8())
        let b1 = UInt32(readUInt8())
        let b2 = UInt32(readUInt8())
        let b3 = UInt32(readUInt8())
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }

    func readBytes(count: Int) -> Data {
        let end = readerIndex + count
        let slice = storage[readerIndex..<end]
        readerIndex = end
        return slice
    }

    func readString(encoding: String.Encoding = .utf8) -> String {
        let slice = storage[readerIndex..<storage.count]
        readerIndex = storage.count
        return String(data: slice, encoding: encoding) ?? ""
    }

    func writeUInt8(_ value: UInt8) {
        storage.append(value)
    }

    func writeUInt16(_ value: UInt16) {
        storage.append(UInt8((value >> 8) & 0xFF))
        storage.append(UInt8(value & 0xFF))
    }

    func writeUInt32(_ value: UInt32) {
        storage.append(UInt8((value >> 24) & 0xFF))
        storage.append(UInt8((value >> 16) & 0xFF))
        storage.append(UInt8((value >> 8) & 0xFF))
        storage.append(UInt8(value & 0xFF))
    }

    func writeBytes(_ bytes: Data) {
        storage.append(bytes)
    }

    func writeBytes(_ bytes: [UInt8]) {
        storage.append(contentsOf: bytes)
    }
}
