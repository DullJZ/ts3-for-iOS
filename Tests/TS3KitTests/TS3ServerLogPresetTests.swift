import XCTest
@testable import TS3iOSApp

final class TS3ServerLogPresetTests: XCTestCase {
    @MainActor
    func testServerLogQueryPresetsPersistChannelFilterAndImportLegacyDefaults() throws {
        let model = TS3AppModel()
        model.deleteAllServerLogQueryPresets()

        let longChannel = "  " + String(repeating: "server", count: 20) + "  "
        model.saveServerLogQueryPreset(
            name: "Auth warnings",
            limit: 2_500,
            beginPosition: -5,
            reverse: false,
            instance: true,
            levelFilter: "WARNING",
            channelFilter: longChannel,
            searchText: String(repeating: "login", count: 40)
        )

        let saved = try XCTUnwrap(model.serverLogQueryPresets.first)
        XCTAssertEqual(saved.name, "Auth warnings")
        XCTAssertEqual(saved.limit, 1_000)
        XCTAssertEqual(saved.beginPosition, 0)
        XCTAssertEqual(saved.levelFilter, "warning")
        XCTAssertEqual(saved.channelFilter.count, 80)
        XCTAssertTrue(saved.channelFilter.hasPrefix("server"))
        XCTAssertEqual(saved.searchText.count, 120)

        let legacyJSON = """
        [{
          "name": "Legacy default",
          "limit": 25,
          "reverse": true,
          "instance": false,
          "levelFilter": "not-a-level",
          "searchText": " older logs "
        }]
        """

        XCTAssertEqual(try model.importServerLogQueryPresets(from: Data(legacyJSON.utf8)), 1)
        let legacy = try XCTUnwrap(model.serverLogQueryPresets.first { $0.name == "Legacy default" })
        XCTAssertEqual(legacy.levelFilter, "all")
        XCTAssertEqual(legacy.channelFilter, "")
        XCTAssertEqual(legacy.searchText, "older logs")

        model.deleteAllServerLogQueryPresets()
    }

    @MainActor
    func testServerLogArchivePreviewSanitizesCountsAndFirstDetails() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": 3,
              "timestamp": 1700000000,
              "level": " warning ",
              "channel": " Server ",
              "message": " Auth failed ",
              "rawLine": " raw auth "
            },
            {
              "id": 3,
              "level": "info",
              "message": "Duplicate",
              "rawLine": "duplicate"
            },
            {
              "id": 2,
              "level": "debug",
              "message": "Debug entry",
              "rawLine": ""
            },
            {
              "id": 0,
              "message": "Invalid",
              "rawLine": "invalid"
            },
            {
              "id": 4,
              "message": "   ",
              "rawLine": "blank"
            }
          ]
        }
        """

        let preview = try model.serverLogArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.entryCount, 2)
        XCTAssertEqual(preview.skippedEntryCount, 3)
        XCTAssertEqual(preview.levelCount, 2)
        XCTAssertEqual(preview.channelCount, 1)
        XCTAssertEqual(preview.timestampCount, 1)
        XCTAssertEqual(preview.firstLevel, "warning")
        XCTAssertEqual(preview.firstChannel, "Server")
        XCTAssertEqual(preview.firstMessage, "Auth failed")
        XCTAssertTrue(preview.hasEntries)
    }

    @MainActor
    func testServerLogArchiveImportReplacesLocalCachedResults() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": 9,
              "level": " info ",
              "channel": " VirtualSvrMgr ",
              "message": " Server started ",
              "rawLine": ""
            }
          ]
        }
        """

        try model.importServerLogArchive(from: Data(archiveJSON.utf8))

        XCTAssertEqual(model.serverLogEntries.count, 1)
        XCTAssertEqual(model.serverLogEntries.first?.id, 9)
        XCTAssertEqual(model.serverLogEntries.first?.level, "info")
        XCTAssertEqual(model.serverLogEntries.first?.channel, "VirtualSvrMgr")
        XCTAssertEqual(model.serverLogEntries.first?.message, "Server started")
        XCTAssertEqual(model.serverLogEntries.first?.rawLine, "Server started")
        XCTAssertEqual(model.lastError, nil)
    }
}
