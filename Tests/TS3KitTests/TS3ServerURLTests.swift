import XCTest
@testable import TS3Kit

final class TS3ServerURLTests: XCTestCase {
    func testParsesTeamSpeakInvitationURL() throws {
        let url = try XCTUnwrap(URL(string: "ts3server://voice.example.com:9988?nickname=Alice&password=s3cr3t&channel=Root%2FSub&channelpassword=room&token=abc123&addbookmark=Main"))

        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed.host, "voice.example.com")
        XCTAssertEqual(parsed.port, 9988)
        XCTAssertEqual(parsed.nickname, "Alice")
        XCTAssertEqual(parsed.serverPassword, "s3cr3t")
        XCTAssertEqual(parsed.defaultChannel, "Root/Sub")
        XCTAssertEqual(parsed.defaultChannelPassword, "room")
        XCTAssertEqual(parsed.privilegeKey, "abc123")
        XCTAssertEqual(parsed.bookmarkName, "Main")
    }

    func testParsesPortQueryWhenHostHasNoPort() throws {
        let url = try XCTUnwrap(URL(string: "ts3server://voice.example.com?port=9999&nickname=Bob"))

        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed.host, "voice.example.com")
        XCTAssertEqual(parsed.port, 9999)
        XCTAssertEqual(parsed.nickname, "Bob")
    }

    func testRejectsNonTeamSpeakURL() throws {
        let url = try XCTUnwrap(URL(string: "https://voice.example.com"))

        XCTAssertThrowsError(try TS3ServerURL(url: url))
    }
}
