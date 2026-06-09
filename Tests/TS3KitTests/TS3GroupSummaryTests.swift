import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3GroupSummaryTests: XCTestCase {
    func testGroupClipboardSummaryIncludesIdNameAndType() {
        let group = TS3GroupSummary(id: 6, name: "Admins", type: .regular)

        XCTAssertEqual(group.clipboardSummary, "groupId=6 | name=Admins | type=Regular")
        XCTAssertEqual(
            group.clipboardSummary(target: .server),
            "target=Server Groups | groupId=6 | name=Admins | type=Regular"
        )
        XCTAssertEqual(
            group.accessibilityValue(target: .server),
            "Server Groups group. ID 6. Type Regular."
        )
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
        XCTAssertEqual(
            client.accessibilityValue(group: group, target: .server, channelName: "Lobby"),
            "Server Groups group Admins. Database ID 42. Channel Lobby. Unique ID client-uid"
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
        XCTAssertEqual(
            client.accessibilityValue(group: group, target: .channel, channelName: nil),
            "Channel Groups group Guests. Database ID 43. Channel Channel 10"
        )
    }

    @MainActor
    func testGroupArchivePreviewSanitizesCountsAndFirstDetails() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "serverGroups": [
            { "id": 6, "name": " Admins ", "type": 1 },
            { "id": 6, "name": "Duplicate", "type": 1 },
            { "id": 7, "name": " Query ", "type": 2 },
            { "id": 0, "name": "Invalid", "type": 1 },
            { "id": 8, "name": "   ", "type": 1 }
          ],
          "channelGroups": [
            { "id": 9, "name": " Channel Admin ", "type": 1 },
            { "id": 10, "name": "Template", "type": 0 },
            { "id": 10, "name": "Duplicate", "type": 0 },
            { "id": 11, "name": "Unknown" }
          ]
        }
        """

        let preview = try model.groupArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.serverGroupCount, 2)
        XCTAssertEqual(preview.channelGroupCount, 3)
        XCTAssertEqual(preview.skippedServerGroupCount, 3)
        XCTAssertEqual(preview.skippedChannelGroupCount, 1)
        XCTAssertEqual(preview.regularCount, 2)
        XCTAssertEqual(preview.queryCount, 1)
        XCTAssertEqual(preview.templateCount, 1)
        XCTAssertEqual(preview.unknownTypeCount, 1)
        XCTAssertEqual(preview.firstServerGroupName, "Admins")
        XCTAssertEqual(preview.firstChannelGroupName, "Channel Admin")
        XCTAssertEqual(
            preview.serverGroupSummaries,
            [
                "target=Server Groups | groupId=6 | name=Admins | type=Regular",
                "target=Server Groups | groupId=7 | name=Query | type=Query"
            ]
        )
        XCTAssertEqual(
            preview.channelGroupSummaries,
            [
                "target=Channel Groups | groupId=9 | name=Channel Admin | type=Regular",
                "target=Channel Groups | groupId=10 | name=Template | type=Template",
                "target=Channel Groups | groupId=11 | name=Unknown | type=Unknown"
            ]
        )
        XCTAssertEqual(
            preview.clipboardSummary,
            (preview.serverGroupSummaries + preview.channelGroupSummaries).joined(separator: "\n")
        )
        XCTAssertTrue(preview.hasGroups)
    }

    @MainActor
    func testGroupArchiveImportReplacesLocalCachedGroups() throws {
        let model = TS3AppModel()
        model.serverGroups = [TS3GroupSummary(id: 1, name: "Old Server", type: .regular)]
        model.channelGroups = [TS3GroupSummary(id: 2, name: "Old Channel", type: .regular)]
        let archiveJSON = """
        {
          "serverGroups": [
            { "id": 12, "name": " Server Operators ", "type": 1 }
          ],
          "channelGroups": [
            { "id": 13, "name": " Channel Voice ", "type": 1 }
          ]
        }
        """

        try model.importGroupArchive(from: Data(archiveJSON.utf8))

        XCTAssertEqual(model.serverGroups.map(\.id), [12])
        XCTAssertEqual(model.serverGroups.first?.name, "Server Operators")
        XCTAssertEqual(model.channelGroups.map(\.id), [13])
        XCTAssertEqual(model.channelGroups.first?.name, "Channel Voice")
        XCTAssertEqual(model.lastError, nil)
    }
}
