import XCTest
@testable import TS3iOSApp

final class TS3EventHistoryArchiveTests: XCTestCase {
    @MainActor
    func testEventHistoryArchivePreviewIncludesCopyableActivityAndPokeSummaries() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "activityEvents": [
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "timestamp": 1700000000,
              "kind": "clientMoved",
              "clientId": 12,
              "clientName": "Taylor",
              "channelId": 4,
              "channelName": "Lobby",
              "fromChannelId": 2,
              "toChannelId": 4,
              "invokerName": "Admin",
              "reasonId": 5,
              "reasonMessage": "Requested",
              "isOwnClient": false
            }
          ],
          "pokeEvents": [
            {
              "id": "00000000-0000-0000-0000-000000000002",
              "timestamp": 1700000100,
              "senderId": 9,
              "senderName": "Morgan",
              "senderUniqueIdentifier": "uid-m",
              "message": "Ping",
              "isOwnPoke": true
            }
          ]
        }
        """

        let preview = try model.eventHistoryArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.activityCount, 1)
        XCTAssertEqual(preview.pokeCount, 1)
        XCTAssertEqual(preview.currentActivityCount, 0)
        XCTAssertEqual(preview.currentPokeCount, 0)
        XCTAssertEqual(
            preview.activitySummaries,
            [
                "kind=clientMoved | client=Taylor | clientId=12 | timestamp=2678307200 | own=false | channel=Lobby | channelId=4 | from=2 | to=4 | invoker=Admin | reasonId=5 | reason=Requested"
            ]
        )
        XCTAssertEqual(
            preview.pokeSummaries,
            [
                "direction=out | sender=Morgan | timestamp=2678307300 | senderId=9 | senderUid=uid-m | message=Ping"
            ]
        )
        XCTAssertEqual(preview.clipboardSummary, (preview.activitySummaries + preview.pokeSummaries).joined(separator: "\n"))
        XCTAssertTrue(preview.hasEvents)
    }

    func testPokeSummaryCopyAndAccessibilityText() {
        let poke = TS3PokeSummary(
            timestamp: Date(timeIntervalSince1970: 1_700_000_100),
            senderId: 9,
            senderName: "Morgan",
            senderUniqueIdentifier: " uid-m ",
            message: " Ping ",
            isOwnPoke: false
        )

        XCTAssertEqual(poke.messageText, "Ping")
        XCTAssertEqual(poke.displayTitle, "From Morgan")
        XCTAssertEqual(
            poke.clipboardSummary,
            "direction=in | sender=Morgan | timestamp=1700000100 | senderId=9 | senderUid=uid-m | message=Ping"
        )
        XCTAssertEqual(
            poke.accessibilityValue,
            "Received from Morgan. Message Ping. Unique ID available"
        )
    }

    func testActivitySummaryCopyAndAccessibilityText() {
        let activity = TS3ActivitySummary(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            kind: .clientMoved,
            clientId: 12,
            clientName: "Taylor",
            channelId: 4,
            channelName: "Lobby",
            fromChannelId: 2,
            toChannelId: 4,
            invokerName: "Admin",
            reasonId: 5,
            reasonMessage: "Requested",
            isOwnClient: false
        )

        XCTAssertEqual(
            activity.clipboardSummary,
            "kind=clientMoved | client=Taylor | clientId=12 | timestamp=1700000000 | own=false | channel=Lobby | channelId=4 | from=2 | to=4 | invoker=Admin | reasonId=5 | reason=Requested"
        )
        XCTAssertEqual(
            activity.accessibilityValue,
            "Client moved. Client Taylor. Channel Lobby. From channel ID 2. To channel ID 4. Invoker Admin. Reason Requested"
        )
    }

    func testPokeSummaryUsesDefaultMessageForBlankPokes() {
        let poke = TS3PokeSummary(
            timestamp: Date(timeIntervalSince1970: 1_700_000_200),
            senderId: nil,
            senderName: "Avery",
            senderUniqueIdentifier: nil,
            message: " ",
            isOwnPoke: true
        )

        XCTAssertEqual(poke.messageText, "Poke")
        XCTAssertEqual(poke.displayTitle, "Sent to Avery")
        XCTAssertEqual(
            poke.clipboardSummary,
            "direction=out | sender=Avery | timestamp=1700000200 | message=Poke"
        )
        XCTAssertEqual(
            poke.accessibilityValue,
            "Sent to Avery. Message Poke"
        )
    }
}
