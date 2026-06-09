import XCTest
@testable import TS3iOSApp
import TS3Kit

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
        XCTAssertEqual(
            preview.ruleSummaries,
            [
                "ip=192.0.2.10 | duration=permanent | reason=spam",
                "name=Bad Guest | lastNickname=Recent Guest | duration=600s",
                "uid=abc/def"
            ]
        )
        XCTAssertEqual(preview.clipboardSummary, preview.ruleSummaries.joined(separator: "\n"))
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
        XCTAssertTrue(preview.ruleSummaries.isEmpty)
        XCTAssertEqual(preview.clipboardSummary, "")
        XCTAssertFalse(preview.hasRules)
    }

    @MainActor
    func testBanBackupExportSanitizesCachedRules() throws {
        let model = TS3AppModel()
        model.banEntries = [
            makeBan(id: 1, ip: " 192.0.2.10 ", durationSeconds: 0, reason: " spam "),
            makeBan(id: 2, ip: "192.0.2.10", durationSeconds: 0, reason: "spam"),
            makeBan(id: 3, name: " Bad Guest ", lastNickname: " Recent Guest ", durationSeconds: 600),
            makeBan(id: 4, reason: "missing target")
        ]

        let preview = try model.banBackupPreview(from: model.banBackupData())

        XCTAssertEqual(preview.ruleCount, 2)
        XCTAssertEqual(preview.skippedRuleCount, 0)
        XCTAssertEqual(
            preview.ruleSummaries,
            [
                "ip=192.0.2.10 | duration=permanent | reason=spam",
                "name=Bad Guest | lastNickname=Recent Guest | duration=600s"
            ]
        )
    }

    private func makeBan(
        id: Int,
        ip: String? = nil,
        name: String? = nil,
        uniqueIdentifier: String? = nil,
        lastNickname: String? = nil,
        durationSeconds: Int? = nil,
        reason: String? = nil
    ) -> TS3BanEntrySummary {
        TS3BanEntrySummary(entry: TS3BanEntry(
            id: id,
            ip: ip,
            name: name,
            uniqueIdentifier: uniqueIdentifier,
            lastNickname: lastNickname,
            createdAt: nil,
            durationSeconds: durationSeconds,
            invokerName: nil,
            reason: reason,
            enforcements: nil
        ))
    }
}
