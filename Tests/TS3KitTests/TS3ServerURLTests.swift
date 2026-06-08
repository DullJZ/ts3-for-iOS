import XCTest
@testable import TS3Kit

final class TS3ServerURLTests: XCTestCase {
    func testParsesTeamSpeakInvitationURL() throws {
        let url = try XCTUnwrap(URL(string: "ts3server://voice.example.com:9988?nickname=Alice&phoneticnickname=Aliss&password=s3cr3t&channel=Root%2FSub&channelpassword=room&token=abc123&addbookmark=Main"))

        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed.host, "voice.example.com")
        XCTAssertEqual(parsed.port, 9988)
        XCTAssertEqual(parsed.nickname, "Alice")
        XCTAssertEqual(parsed.phoneticNickname, "Aliss")
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

    func testParsesTeamspeakSchemeInvitationURL() throws {
        let url = try XCTUnwrap(URL(string: "teamspeak://voice.example.com:9987?nickname=Cat&channel=Lobby"))

        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed.host, "voice.example.com")
        XCTAssertEqual(parsed.port, 9987)
        XCTAssertEqual(parsed.nickname, "Cat")
        XCTAssertEqual(parsed.defaultChannel, "Lobby")
    }

    func testParsesOpaqueTeamSpeakURLWithPort() throws {
        let url = try XCTUnwrap(URL(string: "ts3server:voice.example.com:10011?nickname=Opaque"))

        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed.host, "voice.example.com")
        XCTAssertEqual(parsed.port, 10011)
        XCTAssertEqual(parsed.nickname, "Opaque")
    }

    func testParsesInvitationParameterAliases() throws {
        let url = try XCTUnwrap(URL(string: "ts3server://voice.example.com?serverpassword=secret&default_channel=Ops&channel_password=room&privilege_key=key&bookmark=Ops%20Server"))

        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed.serverPassword, "secret")
        XCTAssertEqual(parsed.defaultChannel, "Ops")
        XCTAssertEqual(parsed.defaultChannelPassword, "room")
        XCTAssertEqual(parsed.privilegeKey, "key")
        XCTAssertEqual(parsed.bookmarkName, "Ops Server")
    }

    func testRejectsNonTeamSpeakURL() throws {
        let url = try XCTUnwrap(URL(string: "https://voice.example.com"))

        XCTAssertThrowsError(try TS3ServerURL(url: url))
    }

    func testBuildsTeamSpeakInvitationURL() throws {
        let serverURL = TS3ServerURL(
            host: "voice.example.com",
            port: 9988,
            nickname: "Alice",
            serverPassword: "s3cr3t",
            defaultChannel: "Root/Sub",
            defaultChannelPassword: "room",
            privilegeKey: "abc123",
            phoneticNickname: "Aliss",
            bookmarkName: "Main"
        )

        let url = try XCTUnwrap(serverURL.url())
        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed, serverURL)
    }

    func testBuildsInvitationURLWithoutSecrets() throws {
        let serverURL = TS3ServerURL(
            host: "voice.example.com",
            port: 9988,
            nickname: "Alice",
            serverPassword: "s3cr3t",
            defaultChannel: "Root/Sub",
            defaultChannelPassword: "room",
            privilegeKey: "abc123",
            phoneticNickname: "Aliss",
            bookmarkName: "Main"
        )

        let url = try XCTUnwrap(serverURL.url(includingSecrets: false))
        let parsed = try TS3ServerURL(url: url)

        XCTAssertEqual(parsed.host, "voice.example.com")
        XCTAssertEqual(parsed.port, 9988)
        XCTAssertEqual(parsed.nickname, "Alice")
        XCTAssertEqual(parsed.phoneticNickname, "Aliss")
        XCTAssertEqual(parsed.defaultChannel, "Root/Sub")
        XCTAssertEqual(parsed.bookmarkName, "Main")
        XCTAssertNil(parsed.serverPassword)
        XCTAssertNil(parsed.defaultChannelPassword)
        XCTAssertNil(parsed.privilegeKey)
    }
}
