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

    func testBanDraftCoverageSummaryCountsAdvancedFieldsAndCustomDuration() {
        let validationMessages = TS3BanDraftValidator.validationMessages(
            ip: " 192.0.2.10 ",
            name: " Bad Guest ",
            uniqueIdentifier: " uid-bad ",
            myTeamSpeakId: " myts-id ",
            lastNickname: " Recent Guest ",
            durationSeconds: 5 * 60,
            isCustomDuration: true,
            reason: " spam "
        )
        let summary = TS3BanDraftCoverageSummary(
            ip: " 192.0.2.10 ",
            name: " Bad Guest ",
            uniqueIdentifier: " uid-bad ",
            myTeamSpeakId: " myts-id ",
            lastNickname: " Recent Guest ",
            reason: " spam ",
            isPermanent: false,
            isCustomDuration: true,
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.targetFieldCount, 5)
        XCTAssertTrue(summary.hasIP)
        XCTAssertTrue(summary.hasName)
        XCTAssertTrue(summary.hasUniqueIdentifier)
        XCTAssertTrue(summary.hasMyTeamSpeakId)
        XCTAssertTrue(summary.hasLastNickname)
        XCTAssertTrue(summary.hasReason)
        XCTAssertFalse(summary.isPermanent)
        XCTAssertTrue(summary.hasCustomDuration)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targets=5 | ip=true | name=true | uid=true | mytsid=true | lastNickname=true | duration=temporary | customDuration=true | reason=true | validationIssues=0 | needsAttention=false"
        )
    }

    func testBanDraftCoverageSummaryFlagsInvalidMissingTarget() {
        let validationMessages = TS3BanDraftValidator.validationMessages(
            ip: "",
            name: "",
            uniqueIdentifier: "",
            myTeamSpeakId: "",
            lastNickname: "",
            durationSeconds: nil,
            isCustomDuration: true,
            reason: "spam\nabuse"
        )
        let summary = TS3BanDraftCoverageSummary(
            ip: "",
            name: "",
            uniqueIdentifier: "",
            myTeamSpeakId: "",
            lastNickname: "",
            reason: "spam\nabuse",
            isPermanent: true,
            isCustomDuration: true,
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.targetFieldCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 3)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targets=0 | ip=false | name=false | uid=false | mytsid=false | lastNickname=false | duration=permanent | customDuration=true | reason=true | validationIssues=3 | needsAttention=true"
        )
    }

    func testBanDurationDraftSelectionMapsOfficialDurationsAndCustomSeconds() {
        XCTAssertEqual(TS3BanDuration.draftSelection(for: nil).duration, .permanent)
        XCTAssertEqual(TS3BanDuration.draftSelection(for: 0).duration, .permanent)
        XCTAssertEqual(TS3BanDuration.draftSelection(for: 10 * 60).duration, .tenMinutes)
        XCTAssertEqual(TS3BanDuration.draftSelection(for: 60 * 60).duration, .oneHour)
        XCTAssertEqual(TS3BanDuration.draftSelection(for: 24 * 60 * 60).duration, .oneDay)
        XCTAssertEqual(TS3BanDuration.draftSelection(for: 7 * 24 * 60 * 60).duration, .oneWeek)

        let custom = TS3BanDuration.draftSelection(for: 95)
        XCTAssertEqual(custom.duration, .custom)
        XCTAssertEqual(custom.customMinutes, "2")
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

    func testBanListSummaryDeduplicatesAndCountsVisibleBans() {
        let summary = TS3BanListSummary(entries: [
            makeBan(
                id: 17,
                ip: "192.0.2.10",
                uniqueIdentifier: "uid-bad",
                createdAt: Date(timeIntervalSince1970: 1_700_000_000),
                durationSeconds: 0,
                invokerName: "Admin",
                reason: "spam",
                enforcements: 2
            ),
            makeBan(
                id: 18,
                name: "Bad Guest",
                lastNickname: "Recent Guest",
                createdAt: Date(timeIntervalSince1970: 1_700_000_100),
                durationSeconds: 600,
                reason: nil,
                enforcements: 3
            ),
            makeBan(
                id: 19,
                uniqueIdentifier: "uid-only",
                durationSeconds: nil,
                invokerName: "Moderator",
                reason: "abuse",
                enforcements: nil
            ),
            makeBan(
                id: 17,
                ip: "198.51.100.5",
                name: "Duplicate",
                createdAt: Date(timeIntervalSince1970: 1_700_000_200),
                durationSeconds: 60,
                reason: "duplicate",
                enforcements: 9
            )
        ])

        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.ipRuleCount, 1)
        XCTAssertEqual(summary.nameRuleCount, 1)
        XCTAssertEqual(summary.uniqueIdentifierRuleCount, 2)
        XCTAssertEqual(summary.lastNicknameRuleCount, 1)
        XCTAssertEqual(summary.permanentCount, 2)
        XCTAssertEqual(summary.temporaryCount, 1)
        XCTAssertEqual(summary.withReasonCount, 2)
        XCTAssertEqual(summary.withInvokerCount, 2)
        XCTAssertEqual(summary.withCreatedAtCount, 2)
        XCTAssertEqual(summary.enforcementCount, 5)
        XCTAssertEqual(summary.lowestBanId, 17)
        XCTAssertEqual(summary.highestBanId, 19)
        XCTAssertEqual(summary.earliestCreatedAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(summary.latestCreatedAt, Date(timeIntervalSince1970: 1_700_000_100))
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "bans=3 | ip=1 | name=1 | uid=2 | lastNickname=1 | permanent=2 | temporary=1 | withReason=2 | withInvoker=2 | withCreatedAt=2 | enforcements=5 | lowestBanId=17 | highestBanId=19 | earliestCreatedAt=1700000000 | latestCreatedAt=1700000100 | needsAttention=true"
        )
    }

    func testBanFilterPresetSummaryAndAccessibilityText() {
        let preset = makeBanFilterPreset(
            id: UUID(),
            name: "Permanent Bans",
            banFilter: "permanent",
            searchText: "spam"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Permanent Bans | banFilter=permanent | search=spam"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Ban filter permanent. Search spam"
        )
    }

    @MainActor
    func testBanFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Ban Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importBanFilterPresets(from: encodedBanFilterPresets([
            makeBanFilterPreset(id: existingId, name: existingName, banFilter: "ip", searchText: "keep")
        ]))
        let data = try encodedBanFilterPresets([
            makeBanFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                banFilter: "invalid",
                searchText: "  search value  "
            ),
            makeBanFilterPreset(
                id: newId,
                name: " Temporary Ban Filter \(suffix) ",
                banFilter: "temporary",
                searchText: String(repeating: "x", count: 140)
            ),
            makeBanFilterPreset(
                id: invalidId,
                name: "   ",
                banFilter: "name",
                searchText: "ignored"
            )
        ])

        let preview = try model.banFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | banFilter=all | search=search value",
            "name=Temporary Ban Filter \(suffix) | banFilter=temporary | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped ban filter presets: 1"))
    }

    @MainActor
    func testBanFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Ban Filter \(suffix)"
        let selectedName = "Selected Ban Filter \(suffix)"
        let unselectedName = "Unselected Ban Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importBanFilterPresets(from: encodedBanFilterPresets([
            makeBanFilterPreset(id: existingId, name: existingName, banFilter: "ip", searchText: "keep")
        ]))
        let data = try encodedBanFilterPresets([
            makeBanFilterPreset(id: existingId, name: existingName, banFilter: "temporary", searchText: "replace"),
            makeBanFilterPreset(id: selectedId, name: selectedName, banFilter: "permanent", searchText: "ops"),
            makeBanFilterPreset(id: unselectedId, name: unselectedName, banFilter: "uniqueIdentifier", searchText: "away")
        ])

        let restoredCount = try model.importBanFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.banFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.banFilter, "ip")
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.banFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.banFilter, "permanent")
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.banFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
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
        XCTAssertEqual(preview.targetTypeSummaries, [
            "target=ip count=1",
            "target=lastNickname count=1",
            "target=name count=1",
            "target=uid count=1"
        ])
        XCTAssertEqual(preview.durationSummaries, [
            "duration=permanent count=1",
            "duration=temporary count=1",
            "duration=unspecified count=1"
        ])
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
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "ip=192.0.2.10 | duration=permanent | reason=spam",
                "name=Bad Guest | lastNickname=Recent Guest | duration=600s",
                "uid=abc/def"
            ]
        )
        XCTAssertEqual(preview.candidates.first?.ip, "192.0.2.10")
        XCTAssertEqual(preview.candidates.first?.durationSeconds, 0)
        XCTAssertEqual(preview.candidates.first?.reason, "spam")
        XCTAssertEqual(Set(preview.candidates.map(\.id)).count, 3)
        XCTAssertTrue(preview.containsRule(id: preview.candidates[1].id))
        XCTAssertFalse(preview.containsRule(id: "missing-rule"))
        XCTAssertEqual(
            preview.clipboardSummary,
            (preview.targetTypeSummaries + preview.durationSummaries + preview.ruleSummaries).joined(separator: "\n")
        )
        XCTAssertTrue(preview.hasRules)
    }

    @MainActor
    func testBanImportImpactSummaryCountsSelectedRules() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            { "ip": "192.0.2.10", "durationSeconds": 0, "reason": "spam" },
            { "name": "Bad Guest", "lastNickname": "Recent Guest", "durationSeconds": 600 },
            { "uniqueIdentifier": "abc/def" },
            { "reason": "missing target" }
          ]
        }
        """

        let preview = try model.banBackupPreview(from: Data(backupJSON.utf8))
        let selectedRuleIds = Set(preview.candidates.map(\.id))
        let summary = TS3BanImportImpactSummary(
            candidates: preview.candidates,
            selectedRuleIds: selectedRuleIds,
            skippedRuleCount: preview.skippedRuleCount
        )

        XCTAssertEqual(summary.selectedRuleCount, 3)
        XCTAssertEqual(summary.ipRuleCount, 1)
        XCTAssertEqual(summary.nameRuleCount, 1)
        XCTAssertEqual(summary.uniqueIdentifierRuleCount, 1)
        XCTAssertEqual(summary.lastNicknameRuleCount, 1)
        XCTAssertEqual(summary.permanentRuleCount, 1)
        XCTAssertEqual(summary.temporaryRuleCount, 1)
        XCTAssertEqual(summary.unspecifiedDurationCount, 1)
        XCTAssertEqual(summary.withReasonCount, 1)
        XCTAssertEqual(summary.skippedRuleCount, 1)
        XCTAssertTrue(summary.hasSelection)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "selected=3 | ip=1 | name=1 | uid=1 | lastNickname=1 | permanent=1 | temporary=1 | unspecifiedDuration=1 | withReason=1 | skippedBackupRules=1 | needsAttention=true"
        )
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
        XCTAssertTrue(preview.targetTypeSummaries.isEmpty)
        XCTAssertTrue(preview.durationSummaries.isEmpty)
        XCTAssertTrue(preview.ruleSummaries.isEmpty)
        XCTAssertTrue(preview.candidates.isEmpty)
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

    private func encodedBanFilterPresets(_ presets: [TS3BanFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeBanFilterPreset(
        id: UUID,
        name: String,
        banFilter: String,
        searchText: String
    ) -> TS3BanFilterPreset {
        TS3BanFilterPreset(
            id: id,
            name: name,
            banFilter: banFilter,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
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
