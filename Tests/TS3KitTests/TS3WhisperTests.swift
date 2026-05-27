import XCTest
@testable import TS3Kit

final class TS3WhisperTests: XCTestCase {
    func testMultipleTargetSerializesLegacyChannelAndClientIds() {
        var buffer = TS3ByteBuffer()
        let target = TS3WhisperTarget.multiple(channelIds: [0x0102_0304_0506_0708], clientIds: [0x1122])

        target.write(to: &buffer)

        XCTAssertEqual(target.size, 12)
        XCTAssertEqual(Array(buffer.data), [
            0x01, 0x01,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x11, 0x22
        ])
    }

    func testMultipleTargetReadsLegacyChannelAndClientIds() {
        var buffer = TS3ByteBuffer(data: Data([
            0x01, 0x02,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0xD2,
            0x00, 0x2A,
            0x00, 0x2B
        ]))

        let target = TS3WhisperTarget.read(from: &buffer, role: .client, newProtocol: false)

        guard case let .multiple(channelIds, clientIds) = target else {
            return XCTFail("Expected multiple whisper target")
        }
        XCTAssertEqual(channelIds, [1234])
        XCTAssertEqual(clientIds, [42, 43])
        XCTAssertEqual(buffer.remaining, 0)
    }

    func testGroupTargetSerializesNewProtocolTypeScopeAndId() {
        var buffer = TS3ByteBuffer()
        let target = TS3WhisperTarget.group(type: .serverGroup, target: .channelFamily, targetId: 0x0102_0304_0506_0708)

        target.write(to: &buffer)

        XCTAssertEqual(target.size, 10)
        XCTAssertEqual(Array(buffer.data), [
            0x00, 0x04,
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08
        ])
    }

    func testGroupTargetReadsNewProtocolTypeScopeAndId() {
        var buffer = TS3ByteBuffer(data: Data([
            0x01, 0x06,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00
        ]))

        let target = TS3WhisperTarget.read(from: &buffer, role: .client, newProtocol: true)

        guard case let .group(type, targetScope, targetId) = target else {
            return XCTFail("Expected group whisper target")
        }
        XCTAssertEqual(type, .channelGroup)
        XCTAssertEqual(targetScope, .subchannels)
        XCTAssertEqual(targetId, 4096)
        XCTAssertEqual(buffer.remaining, 0)
    }

    func testServerRoleReadsServerToClientWithoutConsumingPayload() {
        var buffer = TS3ByteBuffer(data: Data([0x01, 0x02, 0x03]))

        let target = TS3WhisperTarget.read(from: &buffer, role: .server, newProtocol: true)

        guard case .serverToClient = target else {
            return XCTFail("Expected server-to-client whisper target")
        }
        XCTAssertEqual(buffer.remaining, 3)
    }
}
