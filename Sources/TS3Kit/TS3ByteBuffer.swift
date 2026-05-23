import Foundation

final class TS3ByteBuffer {
    private var storage: [UInt8]
    private(set) var readerIndex: Int

    init(data: Data = Data()) {
        self.storage = [UInt8](data)
        self.readerIndex = 0
    }

    var data: Data {
        Data(storage)
    }

    var remaining: Int {
        max(0, storage.count - readerIndex)
    }

    func resetReader() {
        readerIndex = 0
    }

    func readUInt8() -> UInt8 {
        guard readerIndex >= 0, readerIndex < storage.count else {
            readerIndex = storage.count
            return 0
        }
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

    func readUInt64() -> UInt64 {
        let b0 = UInt64(readUInt8())
        let b1 = UInt64(readUInt8())
        let b2 = UInt64(readUInt8())
        let b3 = UInt64(readUInt8())
        let b4 = UInt64(readUInt8())
        let b5 = UInt64(readUInt8())
        let b6 = UInt64(readUInt8())
        let b7 = UInt64(readUInt8())
        return (b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) | (b4 << 24) | (b5 << 16) | (b6 << 8) | b7
    }

    func readBytes(count: Int) -> Data {
        guard count > 0, readerIndex >= 0, readerIndex < storage.count else {
            readerIndex = storage.count
            return Data()
        }
        let end = min(storage.count, readerIndex + count)
        let slice = storage[readerIndex..<end]
        readerIndex = end
        return Data(slice)
    }

    func readString(encoding: String.Encoding = .utf8) -> String {
        guard readerIndex >= 0, readerIndex < storage.count else {
            readerIndex = storage.count
            return ""
        }
        let slice = storage[readerIndex..<storage.count]
        readerIndex = storage.count
        return String(data: Data(slice), encoding: encoding) ?? ""
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

    func writeUInt64(_ value: UInt64) {
        storage.append(UInt8((value >> 56) & 0xFF))
        storage.append(UInt8((value >> 48) & 0xFF))
        storage.append(UInt8((value >> 40) & 0xFF))
        storage.append(UInt8((value >> 32) & 0xFF))
        storage.append(UInt8((value >> 24) & 0xFF))
        storage.append(UInt8((value >> 16) & 0xFF))
        storage.append(UInt8((value >> 8) & 0xFF))
        storage.append(UInt8(value & 0xFF))
    }

    func writeBytes(_ bytes: Data) {
        storage.append(contentsOf: bytes)
    }

    func writeBytes(_ bytes: [UInt8]) {
        storage.append(contentsOf: bytes)
    }
}
