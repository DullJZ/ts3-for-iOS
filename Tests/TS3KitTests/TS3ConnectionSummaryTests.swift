import XCTest
@testable import TS3iOSApp

final class TS3ConnectionSummaryTests: XCTestCase {
    func testBookmarkSummaryIncludesAuditableConnectionFields() {
        let bookmark = TS3BookmarkSummary(
            name: "Raid Server",
            folder: "Operations",
            note: "primary ops",
            host: "voice.example.test",
            port: "9987",
            nickname: "Avery",
            phoneticNickname: "A very",
            serverPassword: "secret",
            defaultChannel: "Ops/Lobby",
            defaultChannelPassword: "channel-secret",
            privilegeKey: "token"
        )

        XCTAssertEqual(
            bookmark.clipboardSummary,
            "name=Raid Server | folder=Operations | server=voice.example.test:9987 | nickname=Avery | phonetic=A very | note=primary ops | defaultChannel=Ops/Lobby | serverPassword=Configured | channelPassword=Configured | privilegeKey=Configured"
        )
        XCTAssertEqual(
            bookmark.accessibilityValue,
            "Name Raid Server. Folder Operations. Server voice.example.test:9987. Nickname Avery. Phonetic nickname A very. Note primary ops. Default channel Ops/Lobby. Server password configured. Channel password configured. Privilege key configured"
        )
    }

    func testRecentConnectionSummaryOmitsEmptyOptionalFieldsAndReportsSecretState() {
        let snapshot = TS3ConnectionSnapshot(
            host: "voice.example.test",
            port: "9988",
            nickname: "",
            note: "",
            serverPassword: "",
            defaultChannel: "",
            defaultChannelPassword: "",
            privilegeKey: ""
        )

        XCTAssertEqual(
            snapshot.clipboardSummary,
            "server=voice.example.test:9988 | nickname=Not set | serverPassword=No | channelPassword=No | privilegeKey=No"
        )
        XCTAssertEqual(
            snapshot.accessibilityValue,
            "Server voice.example.test:9988. Nickname not set. Server password not configured. Channel password not configured. Privilege key not configured"
        )
    }
}
