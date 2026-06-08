import XCTest
@testable import TS3iOSApp

final class TS3BanBackupTests: XCTestCase {
    @MainActor
    func testBanBackupPreviewCountsTargetsAndSkipsEmptyOrDuplicateRules() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            { "ip": " 192.0.2.10 ", "durationSeconds": 0, "reason": " spam " },
            { "ip": "192.0.2.10", "durationSeconds": 0, "reason": "spam" },
            { "name": "Bad Guest", "lastNickname": "Recent Guest", "durationSeconds": 600 },
            { "uniqueIdentifier": "abc/def" },
            { "reason": "missing target" },
            { "ip": "   " }
          ]
        }
        """

        let preview = try model.banBackupPreview(from: Data(backupJSON.utf8))

        XCTAssertEqual(preview.ruleCount, 3)
        XCTAssertEqual(preview.skippedRuleCount, 3)
        XCTAssertEqual(preview.ipRuleCount, 1)
        XCTAssertEqual(preview.nameRuleCount, 1)
        XCTAssertEqual(preview.uniqueIdentifierRuleCount, 1)
        XCTAssertEqual(preview.lastNicknameRuleCount, 1)
        XCTAssertEqual(preview.firstIP, "192.0.2.10")
        XCTAssertEqual(preview.firstDurationSeconds, 0)
        XCTAssertEqual(preview.firstReason, "spam")
        XCTAssertTrue(preview.hasRules)
    }

    @MainActor
    func testBanBackupPreviewReportsNoUsableRules() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            { "reason": "missing target" },
            { "ip": "   ", "name": " " }
          ]
        }
        """

        let preview = try model.banBackupPreview(from: Data(backupJSON.utf8))

        XCTAssertEqual(preview.ruleCount, 0)
        XCTAssertEqual(preview.skippedRuleCount, 2)
        XCTAssertFalse(preview.hasRules)
    }
}
