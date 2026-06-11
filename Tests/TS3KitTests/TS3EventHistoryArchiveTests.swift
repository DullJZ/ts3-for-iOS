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
            },
            {
              "id": "00000000-0000-0000-0000-000000000003",
              "timestamp": 1700000200,
              "kind": "clientMoved",
              "clientId": 13,
              "clientName": "Riley",
              "channelId": 5,
              "channelName": "Ops",
              "fromChannelId": 4,
              "toChannelId": 5,
              "isOwnClient": true
            },
            {
              "id": "00000000-0000-0000-0000-000000000004",
              "timestamp": 1700000300,
              "kind": "clientEntered",
              "clientId": 14,
              "clientName": "Quinn",
              "channelId": 4,
              "channelName": "Lobby",
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
            },
            {
              "id": "00000000-0000-0000-0000-000000000005",
              "timestamp": 1700000400,
              "senderId": 10,
              "senderName": "Alex",
              "senderUniqueIdentifier": "uid-a",
              "message": "Hello",
              "isOwnPoke": false
            }
          ]
        }
        """

        let preview = try model.eventHistoryArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.activityCount, 3)
        XCTAssertEqual(preview.pokeCount, 2)
        XCTAssertEqual(preview.currentActivityCount, 0)
        XCTAssertEqual(preview.currentPokeCount, 0)
        XCTAssertEqual(
            preview.activityKindSummaries,
            [
                "activityKind=clientMoved count=2",
                "activityKind=clientEntered count=1"
            ]
        )
        XCTAssertEqual(
            preview.pokeDirectionSummaries,
            [
                "pokeDirection=in count=1",
                "pokeDirection=out count=1"
            ]
        )
        XCTAssertEqual(
            preview.activitySummaries,
            [
                "kind=clientMoved | client=Taylor | clientId=12 | timestamp=2678307200 | own=false | channel=Lobby | channelId=4 | from=2 | to=4 | invoker=Admin | reasonId=5 | reason=Requested",
                "kind=clientMoved | client=Riley | clientId=13 | timestamp=2678307400 | own=true | channel=Ops | channelId=5 | from=4 | to=5",
                "kind=clientEntered | client=Quinn | clientId=14 | timestamp=2678307500 | own=false | channel=Lobby | channelId=4"
            ]
        )
        XCTAssertEqual(
            preview.pokeSummaries,
            [
                "direction=out | sender=Morgan | timestamp=2678307300 | senderId=9 | senderUid=uid-m | message=Ping",
                "direction=in | sender=Alex | timestamp=2678307600 | senderId=10 | senderUid=uid-a | message=Hello"
            ]
        )
        XCTAssertEqual(
            preview.clipboardSummary,
            (
                preview.activityKindSummaries
                + preview.pokeDirectionSummaries
                + preview.activitySummaries
                + preview.pokeSummaries
            ).joined(separator: "\n")
        )
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
        XCTAssertEqual(
            activity.rowAccessibilityValue(messageText: "moved from Lobby to Support", detailText: "by Admin"),
            "Client moved. Client Taylor. Channel Lobby. From channel ID 2. To channel ID 4. Invoker Admin. Reason Requested. moved from Lobby to Support. by Admin"
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

    func testPokeDraftValidatorRejectsMissingTargetAndMultilineMessage() {
        XCTAssertEqual(
            TS3PokeDraftValidator.validationMessages(
                targetName: " ",
                targetClientId: nil,
                message: "Wake\nup"
            ),
            [
                "Select a client before sending a poke.",
                "Poke message must be a single line."
            ]
        )
        XCTAssertEqual(
            TS3PokeDraftValidator.validationMessages(
                targetName: "Taylor",
                targetClientId: 0,
                message: "Wake up"
            ),
            [
                "Target client id must be positive before sending a poke."
            ]
        )
    }

    func testPokeDraftValidatorSummariesUseDefaultAndCustomMessage() {
        XCTAssertEqual(
            TS3PokeDraftValidator.creationSummary(
                targetName: " Taylor ",
                targetClientId: 12,
                message: " "
            ),
            "target=Taylor | clientId=12 | message=Poke"
        )
        XCTAssertEqual(
            TS3PokeDraftValidator.creationSummary(
                targetName: "Taylor",
                targetClientId: 12,
                message: "Wake up"
            ),
            "target=Taylor | clientId=12 | message=Wake up"
        )
    }
}
