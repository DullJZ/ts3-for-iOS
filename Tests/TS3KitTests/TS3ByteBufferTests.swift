import XCTest
@testable import TS3Kit

final class TS3ByteBufferTests: XCTestCase {
    func testIntegerWritesUseBigEndianByteOrder() {
        let buffer = TS3ByteBuffer()

        buffer.writeUInt8(0x12)
        buffer.writeUInt16(0x3456)
        buffer.writeUInt32(0x789A_BCDE)
        buffer.writeUInt64(0x0102_0304_0506_0708)

        XCTAssertEqual(Array(buffer.data), [
            0x12,
            0x34, 0x56,
            0x78, 0x9A, 0xBC, 0xDE,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08
        ])
    }

    func testIntegerReadsUseBigEndianByteOrderAndAdvanceReader() {
        let buffer = TS3ByteBuffer(data: Data([
            0x12,
            0x34, 0x56,
            0x78, 0x9A, 0xBC, 0xDE,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08
        ]))

        XCTAssertEqual(buffer.readUInt8(), 0x12)
        XCTAssertEqual(buffer.readUInt16(), 0x3456)
        XCTAssertEqual(buffer.readUInt32(), 0x789A_BCDE)
        XCTAssertEqual(buffer.readUInt64(), 0x0102_0304_0506_0708)
        XCTAssertEqual(buffer.remaining, 0)
    }

    func testReaderCanResetWithoutChangingStorage() {
        let buffer = TS3ByteBuffer(data: Data([0xAB, 0xCD]))

        XCTAssertEqual(buffer.readUInt8(), 0xAB)
        XCTAssertEqual(buffer.remaining, 1)

        buffer.resetReader()

        XCTAssertEqual(buffer.remaining, 2)
        XCTAssertEqual(buffer.readUInt16(), 0xABCD)
        XCTAssertEqual(Array(buffer.data), [0xAB, 0xCD])
    }

    func testShortReadsPadMissingBytesWithZeroAndDrainBuffer() {
        let buffer = TS3ByteBuffer(data: Data([0x12, 0x34]))

        XCTAssertEqual(buffer.readUInt32(), 0x1234_0000)
        XCTAssertEqual(buffer.readerIndex, 2)
        XCTAssertEqual(buffer.remaining, 0)
        XCTAssertEqual(buffer.readUInt8(), 0)
    }

    func testReadBytesClampsToAvailableData() {
        let buffer = TS3ByteBuffer(data: Data([0x01, 0x02, 0x03]))

        XCTAssertEqual(Array(buffer.readBytes(count: 8)), [0x01, 0x02, 0x03])
        XCTAssertEqual(buffer.remaining, 0)
        XCTAssertTrue(buffer.readBytes(count: 1).isEmpty)
    }
}
