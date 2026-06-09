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
        XCTAssertEqual(
            preview.entrySummaries,
            [
                "id=3 | message=Auth failed | level=warning | channel=Server | timestamp=2678307200",
                "id=2 | message=Debug entry | level=debug"
            ]
        )
        XCTAssertEqual(preview.clipboardSummary, preview.entrySummaries.joined(separator: "\n"))
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

    @MainActor
    func testServerLogArchiveExportSanitizesCachedResults() throws {
        let model = TS3AppModel()
        model.clearServerLogResults()
        defer {
            model.clearServerLogResults()
        }

        model.serverLogEntries = [
            TS3ServerLogSummary(
                id: 5,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                level: " warning ",
                channel: " Server ",
                message: " Auth failed ",
                rawLine: " raw auth "
            ),
            TS3ServerLogSummary(
                id: 5,
                timestamp: nil,
                level: "info",
                channel: nil,
                message: "Duplicate",
                rawLine: "duplicate"
            ),
            TS3ServerLogSummary(
                id: 4,
                timestamp: nil,
                level: " debug ",
                channel: nil,
                message: " Debug entry ",
                rawLine: ""
            ),
            TS3ServerLogSummary(
                id: 0,
                timestamp: nil,
                level: nil,
                channel: nil,
                message: "Invalid",
                rawLine: "invalid"
            ),
            TS3ServerLogSummary(
                id: 6,
                timestamp: nil,
                level: nil,
                channel: nil,
                message: "   ",
                rawLine: "blank"
            )
        ]

        let object = try JSONSerialization.jsonObject(with: model.serverLogArchiveData()) as? [String: Any]
        let entries = try XCTUnwrap(object?["entries"] as? [[String: Any]])

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0]["id"] as? Int, 5)
        XCTAssertEqual(entries[0]["level"] as? String, "warning")
        XCTAssertEqual(entries[0]["channel"] as? String, "Server")
        XCTAssertEqual(entries[0]["message"] as? String, "Auth failed")
        XCTAssertEqual(entries[0]["rawLine"] as? String, "raw auth")
        XCTAssertEqual(entries[1]["id"] as? Int, 4)
        XCTAssertEqual(entries[1]["level"] as? String, "debug")
        XCTAssertEqual(entries[1]["message"] as? String, "Debug entry")
        XCTAssertEqual(entries[1]["rawLine"] as? String, "Debug entry")
    }

    @MainActor
    func testClearSelectedServerLogResultsRemovesOnlyMatchingIdsAndPersists() throws {
        let model = TS3AppModel()
        model.clearServerLogResults()
        defer {
            model.clearServerLogResults()
        }

        model.serverLogEntries = [
            TS3ServerLogSummary(id: 1, timestamp: nil, level: "info", channel: "Server", message: "Keep first", rawLine: "Keep first"),
            TS3ServerLogSummary(id: 2, timestamp: nil, level: "warning", channel: "Server", message: "Remove", rawLine: "Remove"),
            TS3ServerLogSummary(id: 3, timestamp: nil, level: "error", channel: "Query", message: "Keep second", rawLine: "Keep second")
        ]

        model.clearServerLogResults([
            TS3ServerLogSummary(id: 2, timestamp: nil, level: nil, channel: nil, message: "Visible row", rawLine: "Visible row")
        ])

        XCTAssertEqual(model.serverLogEntries.map(\.id), [1, 3])

        let reloadedModel = TS3AppModel()
        XCTAssertEqual(Set(reloadedModel.serverLogEntries.map(\.id)), [1, 3])
        XCTAssertFalse(reloadedModel.serverLogEntries.contains { $0.id == 2 })
    }
}
