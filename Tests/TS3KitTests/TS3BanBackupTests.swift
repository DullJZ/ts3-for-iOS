import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3BanBackupTests: XCTestCase {
    func testBanDraftValidatorRejectsMissingTargetInvalidCustomDurationAndMultilineReason() {
        XCTAssertEqual(
            TS3BanDraftValidator.validationMessages(
                ip: " ",
                name: "",
                uniqueIdentifier: "",
                myTeamSpeakId: "",
                lastNickname: "",
                durationSeconds: nil,
                isCustomDuration: true,
                reason: "spam\nabuse"
            ),
            [
                "Enter an IP address, name, unique id, myTeamSpeak id, or last nickname for the ban rule.",
                "Custom ban duration must be a positive number of seconds.",
                "Ban reason must be a single line."
            ]
        )
    }

    func testBanDraftValidatorBuildsAuditableSummary() {
        let messages = TS3BanDraftValidator.validationMessages(
            ip: " 192.0.2.10 ",
            name: " Bad Guest ",
            uniqueIdentifier: " uid-bad ",
            myTeamSpeakId: " myts-id ",
            lastNickname: " Recent Guest ",
            durationSeconds: 7_200,
            isCustomDuration: false,
            reason: " spam "
        )
        let summary = TS3BanDraftValidator.creationSummary(
            ip: " 192.0.2.10 ",
            name: " Bad Guest ",
            uniqueIdentifier: " uid-bad ",
            myTeamSpeakId: " myts-id ",
            lastNickname: " Recent Guest ",
            durationSeconds: 7_200,
            isPermanent: false,
            reason: " spam "
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(
            summary,
            "ip=192.0.2.10 | name=Bad Guest | uid=uid-bad | mytsid=myts-id | lastNickname=Recent Guest | duration=2h 0m | reason=spam"
        )
    }

    func testBanDraftValidatorSummarizesPermanentBan() {
        let summary = TS3BanDraftValidator.creationSummary(
            ip: "",
            name: "",
            uniqueIdentifier: "uid-bad",
            myTeamSpeakId: "",
            lastNickname: "",
            durationSeconds: nil,
            isPermanent: true,
            reason: ""
        )

        XCTAssertEqual(summary, "uid=uid-bad | duration=Permanent")
    }

    func testBanEntrySummaryCopyAndAccessibilityText() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = makeBan(
            id: 17,
            ip: "192.0.2.10",
            name: "Bad Guest",
            uniqueIdentifier: "uid-bad",
            lastNickname: "Recent Guest",
            createdAt: createdAt,
            durationSeconds: 7_200,
            invokerName: "Admin",
            reason: "spam",
            enforcements: 2
        )

        XCTAssertEqual(entry.displayTitle, "Bad Guest")
        XCTAssertEqual(entry.subtitle, "192.0.2.10 | uid-bad")
        XCTAssertEqual(
            entry.clipboardSummary,
            "banId=17 | name=Bad Guest | lastNickname=Recent Guest | ip=192.0.2.10 | uid=uid-bad | createdAt=\(TS3BanEntrySummary.dateText(createdAt)) | duration=2h 0m | invoker=Admin | enforcements=2 | reason=spam"
        )
        XCTAssertEqual(
            entry.accessibilityValue,
            "IP 192.0.2.10. Unique ID uid-bad. Created \(TS3BanEntrySummary.dateText(createdAt)). Duration 2h 0m. Invoker Admin. Enforcements 2. Reason spam"
        )
    }

    func testBanEntrySummaryFallsBackToTargetAndPermanentDuration() {
        let entry = makeBan(id: 18, ip: "203.0.113.9", durationSeconds: 0)

        XCTAssertEqual(entry.displayTitle, "203.0.113.9")
        XCTAssertEqual(entry.subtitle, "203.0.113.9")
        XCTAssertEqual(entry.clipboardSummary, "banId=18 | ip=203.0.113.9 | duration=Permanent")
        XCTAssertEqual(entry.accessibilityValue, "IP 203.0.113.9. Duration Permanent")
    }

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
        createdAt: Date? = nil,
        durationSeconds: Int? = nil,
        invokerName: String? = nil,
        reason: String? = nil,
        enforcements: Int? = nil
    ) -> TS3BanEntrySummary {
        TS3BanEntrySummary(entry: TS3BanEntry(
            id: id,
            ip: ip,
            name: name,
            uniqueIdentifier: uniqueIdentifier,
            lastNickname: lastNickname,
            createdAt: createdAt,
            durationSeconds: durationSeconds,
            invokerName: invokerName,
            reason: reason,
            enforcements: enforcements
        ))
    }
}
