import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3GroupSummaryTests: XCTestCase {
    func testGroupClipboardSummaryIncludesIdNameAndType() {
        let group = TS3GroupSummary(id: 6, name: "Admins", type: .regular)

        XCTAssertEqual(group.clipboardSummary, "groupId=6 | name=Admins | type=Regular")
    }

    func testGroupClientClipboardSummaryIncludesGroupTargetAndChannel() {
        let group = TS3GroupSummary(id: 6, name: "Admins", type: .regular)
        let client = TS3GroupClientSummary(client: TS3GroupClient(
            clientDatabaseId: 42,
            uniqueIdentifier: "client-uid",
            nickname: "Taylor",
            channelId: 9
        ))

        XCTAssertEqual(
            client.clipboardSummary(group: group, target: .server, channelName: "Lobby"),
            "group=Admins (6) | target=Server Groups | clientDb=42 | nickname=Taylor | uid=client-uid | channel=Lobby (9)"
        )
    }

    func testGroupClientClipboardSummaryFallsBackWhenNicknameAndChannelNameAreMissing() {
        let group = TS3GroupSummary(id: 7, name: "Guests", type: nil)
        let client = TS3GroupClientSummary(client: TS3GroupClient(
            clientDatabaseId: 43,
            uniqueIdentifier: nil,
            nickname: nil,
            channelId: 10
        ))

        XCTAssertEqual(
            client.clipboardSummary(group: group, target: .channel, channelName: nil),
            "group=Guests (7) | target=Channel Groups | clientDb=43 | nickname=Client 43 | channel=Channel 10 (10)"
        )
    }
}
