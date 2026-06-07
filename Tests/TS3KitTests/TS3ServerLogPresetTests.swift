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
}
