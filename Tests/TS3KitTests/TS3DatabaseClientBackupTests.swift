import XCTest
@testable import TS3iOSApp

final class TS3DatabaseClientBackupTests: XCTestCase {
    func testDatabaseClientSummaryCopyAndAccessibilityText() {
        let client = TS3DatabaseClientSummary(
            id: 7,
            uniqueIdentifier: "uid-b",
            nickname: "Beta",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastConnectedAt: Date(timeIntervalSince1970: 1_700_000_100),
            totalConnections: 5,
            description: "Has note",
            lastIP: "203.0.113.7"
        )

        XCTAssertEqual(
            client.backupSummary,
            "db=7 | nickname=Beta | uid=uid-b | connections=5 | lastIP=203.0.113.7 | description=true | created=1700000000 | lastConnected=1700000100"
        )
        XCTAssertEqual(
            client.clipboardSummary,
            "db=7 | nickname=Beta | uid=uid-b | connections=5 | lastIP=203.0.113.7 | description=true | created=1700000000 | lastConnected=1700000100 | descriptionText=Has note"
        )
        XCTAssertEqual(
            client.accessibilityValue,
            "Database client 7. Nickname Beta. Unique identifier available. 5 connections. Last IP available. Description available. Created date available. Last connected date available"
        )
    }

    @MainActor
    func testDatabaseClientBackupPreviewSanitizesCountsAndSummaries() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            {
              "id": 7,
              "uniqueIdentifier": " uid-b ",
              "nickname": " Beta ",
              "createdAt": 1700000000,
              "lastConnectedAt": 1700000100,
              "totalConnections": 5,
              "description": " Has note ",
              "lastIP": " 203.0.113.7 "
            },
            {
              "id": 6,
              "uniqueIdentifier": "",
              "nickname": " Alpha ",
              "description": "   "
            },
            {
              "id": 7,
              "nickname": "Duplicate"
            },
            {
              "id": 0,
              "nickname": "Invalid"
            },
            {
              "id": 9,
              "nickname": "   "
            }
          ]
        }
        """

        let preview = try model.databaseClientBackupPreview(from: Data(backupJSON.utf8))

        XCTAssertEqual(preview.clientCount, 2)
        XCTAssertEqual(preview.skippedClientCount, 3)
        XCTAssertEqual(preview.uniqueIdentifierCount, 1)
        XCTAssertEqual(preview.descriptionCount, 1)
        XCTAssertEqual(preview.lastIPCount, 1)
        XCTAssertEqual(preview.connectionCount, 1)
        XCTAssertEqual(preview.firstNickname, "Alpha")
        XCTAssertEqual(preview.firstDatabaseId, 6)
        XCTAssertEqual(
            preview.clientSummaries,
            [
                "db=6 | nickname=Alpha",
                "db=7 | nickname=Beta | uid=uid-b | connections=5 | lastIP=203.0.113.7 | description=true | created=2678307200 | lastConnected=2678307300"
            ]
        )
        XCTAssertEqual(preview.clipboardSummary, preview.clientSummaries.joined(separator: "\n"))
        XCTAssertTrue(preview.hasClients)
    }

    @MainActor
    func testDatabaseClientBackupImportReplacesLocalCachedClients() throws {
        let model = TS3AppModel()
        model.databaseClients = [
            TS3DatabaseClientSummary(
                id: 1,
                uniqueIdentifier: "old",
                nickname: "Old",
                createdAt: nil,
                lastConnectedAt: nil,
                totalConnections: nil,
                description: nil,
                lastIP: nil
            )
        ]
        let backupJSON = """
        {
          "entries": [
            {
              "id": 12,
              "uniqueIdentifier": " uid-z ",
              "nickname": " Zed "
            },
            {
              "id": 11,
              "nickname": " Ada "
            }
          ]
        }
        """

        try model.importDatabaseClientBackup(from: Data(backupJSON.utf8))

        XCTAssertEqual(model.databaseClients.map(\.id), [11, 12])
        XCTAssertEqual(model.databaseClients.map(\.nickname), ["Ada", "Zed"])
        XCTAssertEqual(model.databaseClients.last?.uniqueIdentifier, "uid-z")
        XCTAssertEqual(model.lastError, nil)
    }
}
