import XCTest
@testable import TS3iOSApp

final class TS3ComplaintArchiveTests: XCTestCase {
    func testComplaintDraftValidatorRejectsMissingTargetEmptyAndMultilineMessage() {
        XCTAssertEqual(
            TS3ComplaintDraftValidator.validationMessages(
                targetName: " ",
                targetClientId: nil,
                targetDatabaseId: nil,
                message: " \n "
            ),
            [
                "Select a target user before submitting a complaint.",
                "Complaint message is required before submitting.",
                "Complaint message must be a single line."
            ]
        )
    }

    func testComplaintDraftValidatorBuildsAuditableSummary() {
        let messages = TS3ComplaintDraftValidator.validationMessages(
            targetName: " Target ",
            targetClientId: 12,
            targetDatabaseId: 22,
            message: " Abuse "
        )
        let summary = TS3ComplaintDraftValidator.creationSummary(
            targetName: " Target ",
            targetClientId: 12,
            targetDatabaseId: 22,
            message: " Abuse "
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(summary, "target=Target | clientId=12 | databaseId=22 | message=Abuse")
    }

    func testComplaintDraftValidatorSummarizesMissingMessage() {
        let summary = TS3ComplaintDraftValidator.creationSummary(
            targetName: "Target",
            targetClientId: 12,
            targetDatabaseId: nil,
            message: " "
        )

        XCTAssertEqual(summary, "target=Target | clientId=12 | message=Missing")
    }

    func testComplaintDraftCoverageSummaryCountsTargetAndMessageFields() {
        let validationMessages = TS3ComplaintDraftValidator.validationMessages(
            targetName: " Target ",
            targetClientId: 12,
            targetDatabaseId: 22,
            message: " Abuse "
        )
        let summary = TS3ComplaintDraftCoverageSummary(
            targetName: " Target ",
            targetClientId: 12,
            targetDatabaseId: 22,
            message: " Abuse ",
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.targetFieldCount, 3)
        XCTAssertTrue(summary.hasTargetName)
        XCTAssertTrue(summary.hasTargetClientId)
        XCTAssertTrue(summary.hasTargetDatabaseId)
        XCTAssertTrue(summary.hasMessage)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targetFields=3 | targetName=true | clientId=true | databaseId=true | message=true | validationIssues=0 | needsAttention=false"
        )
    }

    func testComplaintDraftCoverageSummaryFlagsMissingInvalidDraft() {
        let validationMessages = TS3ComplaintDraftValidator.validationMessages(
            targetName: " ",
            targetClientId: nil,
            targetDatabaseId: nil,
            message: " \n "
        )
        let summary = TS3ComplaintDraftCoverageSummary(
            targetName: " ",
            targetClientId: nil,
            targetDatabaseId: nil,
            message: " \n ",
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.targetFieldCount, 0)
        XCTAssertFalse(summary.hasTargetName)
        XCTAssertFalse(summary.hasTargetClientId)
        XCTAssertFalse(summary.hasTargetDatabaseId)
        XCTAssertFalse(summary.hasMessage)
        XCTAssertEqual(summary.validationIssueCount, 3)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targetFields=0 | targetName=false | clientId=false | databaseId=false | message=false | validationIssues=3 | needsAttention=true"
        )
    }

    func testComplaintSummaryCopyAndAccessibilityText() {
        let complaint = TS3ComplaintSummary(
            id: "complaint",
            targetClientDatabaseId: 22,
            targetName: "Target",
            sourceClientDatabaseId: 44,
            sourceName: "Reporter",
            message: "Abuse",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(complaint.sourceTitle, "Reporter")
        XCTAssertEqual(
            complaint.clipboardSummary,
            "sourceDb=44 | targetDb=22 | sourceName=Reporter | targetName=Target | timestamp=1700000000 | message=Abuse"
        )
        XCTAssertEqual(
            complaint.accessibilityValue,
            "Source database ID 44. Target database ID 22. Target Target. Created date available. Abuse"
        )
    }

    func testComplaintSummaryFallbackTextOmitsEmptyOptionalFields() {
        let complaint = TS3ComplaintSummary(
            id: "complaint",
            targetClientDatabaseId: 22,
            targetName: nil,
            sourceClientDatabaseId: 44,
            sourceName: nil,
            message: nil,
            timestamp: nil
        )

        XCTAssertEqual(complaint.sourceTitle, "Client DB 44")
        XCTAssertEqual(complaint.clipboardSummary, "sourceDb=44 | targetDb=22")
        XCTAssertEqual(complaint.accessibilityValue, "Source database ID 44. Target database ID 22")
    }

    func testComplaintListSummaryDeduplicatesAndCountsVisibleComplaints() {
        let named = TS3ComplaintSummary(
            id: "target-22-source-44",
            targetClientDatabaseId: 22,
            targetName: "Target",
            sourceClientDatabaseId: 44,
            sourceName: "Reporter",
            message: "Abuse",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let anonymous = TS3ComplaintSummary(
            id: "target-23-source-45",
            targetClientDatabaseId: 23,
            targetName: nil,
            sourceClientDatabaseId: 45,
            sourceName: nil,
            message: nil,
            timestamp: nil
        )
        let duplicate = TS3ComplaintSummary(
            id: "target-22-source-44",
            targetClientDatabaseId: 22,
            targetName: "Duplicate",
            sourceClientDatabaseId: 46,
            sourceName: "Ignored",
            message: "Ignored duplicate",
            timestamp: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let summary = TS3ComplaintListSummary(complaints: [named, anonymous, duplicate])

        XCTAssertEqual(summary.totalCount, 2)
        XCTAssertEqual(summary.targetCount, 2)
        XCTAssertEqual(summary.namedSourceCount, 1)
        XCTAssertEqual(summary.anonymousSourceCount, 1)
        XCTAssertEqual(summary.messageCount, 1)
        XCTAssertEqual(summary.datedCount, 1)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "complaints=2 | targets=2 | namedSources=1 | anonymousSources=1 | withMessages=1 | withDates=1 | latestTimestamp=2023-11-14T22:13:20Z | needsAttention=true"
        )
    }

    func testComplaintDeleteImpactSummaryCountsVisibleDeletionRisk() {
        let named = TS3ComplaintSummary(
            id: "target-22-source-44",
            targetClientDatabaseId: 22,
            targetName: "Target",
            sourceClientDatabaseId: 44,
            sourceName: "Reporter",
            message: "Abuse",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let anonymous = TS3ComplaintSummary(
            id: "target-23-source-45",
            targetClientDatabaseId: 23,
            targetName: nil,
            sourceClientDatabaseId: 45,
            sourceName: nil,
            message: nil,
            timestamp: nil
        )
        let duplicate = TS3ComplaintSummary(
            id: "target-22-source-44",
            targetClientDatabaseId: 22,
            targetName: "Duplicate",
            sourceClientDatabaseId: 46,
            sourceName: "Ignored",
            message: "Ignored duplicate",
            timestamp: Date(timeIntervalSince1970: 1_800_000_000)
        )

        let summary = TS3ComplaintDeleteImpactSummary(
            complaints: [named, anonymous, duplicate],
            scope: .visible
        )

        XCTAssertEqual(summary.complaintCount, 2)
        XCTAssertEqual(summary.listSummary.targetCount, 2)
        XCTAssertEqual(summary.listSummary.namedSourceCount, 1)
        XCTAssertEqual(summary.listSummary.anonymousSourceCount, 1)
        XCTAssertEqual(summary.listSummary.messageCount, 1)
        XCTAssertEqual(summary.missingMessageCount, 1)
        XCTAssertEqual(summary.listSummary.datedCount, 1)
        XCTAssertEqual(summary.missingDateCount, 1)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=visible | deleteComplaints=2 | targets=2 | namedSources=1 | anonymousSources=1 | withMessages=1 | missingMessages=1 | withDates=1 | missingDates=1 | latestTimestamp=2023-11-14T22:13:20Z | needsAttention=true"
        )
    }

    func testComplaintDeleteImpactSummaryFlagsEmptyAndLargeDeletion() {
        let empty = TS3ComplaintDeleteImpactSummary(complaints: [], scope: .all)

        XCTAssertEqual(empty.complaintCount, 0)
        XCTAssertEqual(empty.missingMessageCount, 0)
        XCTAssertEqual(empty.missingDateCount, 0)
        XCTAssertTrue(empty.needsAttention)
        XCTAssertEqual(
            empty.clipboardSummary,
            "scope=all | deleteComplaints=0 | targets=0 | namedSources=0 | anonymousSources=0 | withMessages=0 | missingMessages=0 | withDates=0 | missingDates=0 | latestTimestamp=none | needsAttention=true"
        )

        let largeDeletion = TS3ComplaintDeleteImpactSummary(
            complaints: (1...10).map { index in
                TS3ComplaintSummary(
                    id: "target-\(index)-source-\(index + 100)",
                    targetClientDatabaseId: index,
                    targetName: "Target \(index)",
                    sourceClientDatabaseId: index + 100,
                    sourceName: "Reporter \(index)",
                    message: "Abuse",
                    timestamp: Date(timeIntervalSince1970: 1_700_000_000 + TimeInterval(index))
                )
            },
            scope: .all
        )

        XCTAssertEqual(largeDeletion.complaintCount, 10)
        XCTAssertEqual(largeDeletion.listSummary.anonymousSourceCount, 0)
        XCTAssertEqual(largeDeletion.missingMessageCount, 0)
        XCTAssertEqual(largeDeletion.missingDateCount, 0)
        XCTAssertTrue(largeDeletion.needsAttention)
    }

    func testComplaintOfficialCoverageAuditSummaryCountsCoveredAreas() {
        let draftSummary = TS3ComplaintDraftCoverageSummary(
            targetName: " Target ",
            targetClientId: 12,
            targetDatabaseId: 22,
            message: " Abuse ",
            validationMessages: []
        )
        let visibleSummary = TS3ComplaintListSummary(complaints: [
            TS3ComplaintSummary(
                id: "target-22-source-44",
                targetClientDatabaseId: 22,
                targetName: "Target",
                sourceClientDatabaseId: 44,
                sourceName: "Reporter",
                message: "Abuse",
                timestamp: Date(timeIntervalSince1970: 1_700_000_000)
            ),
            TS3ComplaintSummary(
                id: "target-23-source-45",
                targetClientDatabaseId: 23,
                targetName: nil,
                sourceClientDatabaseId: 45,
                sourceName: nil,
                message: "Spam",
                timestamp: nil
            )
        ])

        let summary = TS3ComplaintOfficialCoverageAuditSummary(
            draftCoverageSummary: draftSummary,
            visibleComplaintSummary: visibleSummary,
            hasLocalFilters: true,
            hasFilterPresets: true,
            hasArchiveCoverage: true,
            canMutateServer: true,
            canDeleteVisible: true,
            hasSourceContactActions: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 8)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 8)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 17)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=8/8 | missingOfficialAreas=0 | officialActions=17 | draftTargets=3 | draftMessage=true | visibleComplaints=2 | targets=2 | namedSources=1 | anonymousSources=1 | withMessages=2 | withDates=1 | localFilters=true | filterPresets=true | archiveCoverage=true | serverMutation=true | deleteVisible=true | sourceContactActions=true | needsAttention=true"
        )
    }

    func testComplaintOfficialCoverageAuditSummaryFlagsMissingWorkflowAreas() {
        let summary = TS3ComplaintOfficialCoverageAuditSummary(
            draftCoverageSummary: nil,
            visibleComplaintSummary: TS3ComplaintListSummary(complaints: []),
            hasLocalFilters: false,
            hasFilterPresets: false,
            hasArchiveCoverage: false,
            canMutateServer: false,
            canDeleteVisible: false,
            hasSourceContactActions: false
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 0)
        XCTAssertEqual(summary.missingOfficialAreaCount, 8)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=0/8 | missingOfficialAreas=8 | officialActions=17 | draftTargets=0 | draftMessage=false | visibleComplaints=0 | targets=0 | namedSources=0 | anonymousSources=0 | withMessages=0 | withDates=0 | localFilters=false | filterPresets=false | archiveCoverage=false | serverMutation=false | deleteVisible=false | sourceContactActions=false | needsAttention=true"
        )
    }

    func testComplaintFilterPresetSummaryAndAccessibilityText() {
        let preset = makeComplaintFilterPreset(
            id: UUID(),
            name: "Named Sources",
            complaintFilter: "namedSource",
            sortMode: "source",
            sortAscending: true,
            searchText: "abuse"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Named Sources | complaintFilter=namedSource | sortMode=source | sortAscending=true | search=abuse"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Complaint filter namedSource. Sort by source. Ascending. Search abuse"
        )
    }

    @MainActor
    func testComplaintFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Complaint Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importComplaintFilterPresets(from: encodedComplaintFilterPresets([
            makeComplaintFilterPreset(
                id: existingId,
                name: existingName,
                complaintFilter: "namedSource",
                sortMode: "source",
                sortAscending: true,
                searchText: "keep"
            )
        ]))
        let data = try encodedComplaintFilterPresets([
            makeComplaintFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                complaintFilter: "invalid",
                sortMode: "invalidSort",
                sortAscending: false,
                searchText: "  search value  "
            ),
            makeComplaintFilterPreset(
                id: newId,
                name: " Message Complaints \(suffix) ",
                complaintFilter: "withMessage",
                sortMode: "message",
                sortAscending: true,
                searchText: String(repeating: "x", count: 140)
            ),
            makeComplaintFilterPreset(
                id: invalidId,
                name: "   ",
                complaintFilter: "anonymousSource",
                sortMode: "date",
                sortAscending: false,
                searchText: "ignored"
            )
        ])

        let preview = try model.complaintFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | complaintFilter=all | sortMode=date | sortAscending=false | search=search value",
            "name=Message Complaints \(suffix) | complaintFilter=withMessage | sortMode=message | sortAscending=true | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped complaint filter presets: 1"))
    }

    @MainActor
    func testComplaintFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Complaint Filter \(suffix)"
        let selectedName = "Selected Complaint Filter \(suffix)"
        let unselectedName = "Unselected Complaint Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importComplaintFilterPresets(from: encodedComplaintFilterPresets([
            makeComplaintFilterPreset(
                id: existingId,
                name: existingName,
                complaintFilter: "namedSource",
                sortMode: "source",
                sortAscending: true,
                searchText: "keep"
            )
        ]))
        let data = try encodedComplaintFilterPresets([
            makeComplaintFilterPreset(
                id: existingId,
                name: existingName,
                complaintFilter: "anonymousSource",
                sortMode: "date",
                sortAscending: false,
                searchText: "replace"
            ),
            makeComplaintFilterPreset(
                id: selectedId,
                name: selectedName,
                complaintFilter: "withTimestamp",
                sortMode: "sourceDatabaseId",
                sortAscending: true,
                searchText: "ops"
            ),
            makeComplaintFilterPreset(
                id: unselectedId,
                name: unselectedName,
                complaintFilter: "withoutMessage",
                sortMode: "message",
                sortAscending: false,
                searchText: "away"
            )
        ])

        let restoredCount = try model.importComplaintFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.complaintFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.complaintFilter, "namedSource")
        XCTAssertEqual(existing.sortMode, "source")
        XCTAssertEqual(existing.sortAscending, true)
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.complaintFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.complaintFilter, "withTimestamp")
        XCTAssertEqual(selected.sortMode, "sourceDatabaseId")
        XCTAssertEqual(selected.sortAscending, true)
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.complaintFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    @MainActor
    func testComplaintArchivePreviewSanitizesCountsAndFirstDetails() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": "first",
              "targetClientDatabaseId": 22,
              "targetName": " Target ",
              "sourceClientDatabaseId": 44,
              "sourceName": " Reporter ",
              "message": " Abuse ",
              "timestamp": 1700000000
            },
            {
              "id": "duplicate",
              "targetClientDatabaseId": 22,
              "targetName": "Target",
              "sourceClientDatabaseId": 44,
              "sourceName": "Reporter",
              "message": "Abuse",
              "timestamp": 1700000000
            },
            {
              "id": "second",
              "targetClientDatabaseId": 23,
              "sourceClientDatabaseId": 45,
              "message": " "
            },
            {
              "id": "invalid",
              "targetClientDatabaseId": 0,
              "sourceClientDatabaseId": 45,
              "message": "missing target"
            }
          ]
        }
        """

        let preview = try model.complaintArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.complaintCount, 2)
        XCTAssertEqual(preview.skippedComplaintCount, 2)
        XCTAssertEqual(preview.targetCount, 2)
        XCTAssertEqual(preview.namedSourceCount, 1)
        XCTAssertEqual(preview.anonymousSourceCount, 1)
        XCTAssertEqual(preview.messageCount, 1)
        XCTAssertEqual(preview.targetSummaries, [
            "target=Target db=22 count=1",
            "target=db=23 count=1"
        ])
        XCTAssertEqual(preview.sourceSummaries, [
            "source=Reporter db=44 count=1",
            "source=db=45 count=1"
        ])
        XCTAssertEqual(preview.firstTargetName, "Target")
        XCTAssertEqual(preview.firstSourceName, "Reporter")
        XCTAssertEqual(preview.firstMessage, "Abuse")
        XCTAssertEqual(
            preview.complaintSummaries,
            [
                "sourceDb=44 | targetDb=22 | sourceName=Reporter | targetName=Target | timestamp=2678307200 | message=Abuse",
                "sourceDb=45 | targetDb=23"
            ]
        )
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "sourceDb=44 | targetDb=22 | sourceName=Reporter | targetName=Target | timestamp=2678307200 | message=Abuse",
                "sourceDb=45 | targetDb=23"
            ]
        )
        XCTAssertEqual(preview.candidates.first?.targetClientDatabaseId, 22)
        XCTAssertEqual(preview.candidates.first?.targetName, "Target")
        XCTAssertEqual(preview.candidates.first?.sourceClientDatabaseId, 44)
        XCTAssertEqual(preview.candidates.first?.sourceName, "Reporter")
        XCTAssertEqual(preview.candidates.first?.message, "Abuse")
        XCTAssertNotNil(preview.candidates.first?.timestamp)
        XCTAssertEqual(Set(preview.candidates.map(\.id)).count, 2)
        XCTAssertTrue(preview.containsComplaint(id: preview.candidates[1].id))
        XCTAssertFalse(preview.containsComplaint(id: "missing-complaint"))
        XCTAssertEqual(
            preview.clipboardSummary,
            (preview.targetSummaries + preview.sourceSummaries + preview.complaintSummaries).joined(separator: "\n")
        )
        XCTAssertTrue(preview.hasComplaints)
    }

    @MainActor
    func testComplaintImportImpactSummaryCountsSelectedComplaints() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": "first",
              "targetClientDatabaseId": 22,
              "targetName": " Target ",
              "sourceClientDatabaseId": 44,
              "sourceName": " Reporter ",
              "message": " Abuse ",
              "timestamp": 1700000000
            },
            {
              "id": "second",
              "targetClientDatabaseId": 23,
              "sourceClientDatabaseId": 45,
              "message": " "
            },
            {
              "id": "invalid",
              "targetClientDatabaseId": 0,
              "sourceClientDatabaseId": 45,
              "message": "missing target"
            }
          ]
        }
        """

        let preview = try model.complaintArchivePreview(from: Data(archiveJSON.utf8))
        let summary = TS3ComplaintImportImpactSummary(
            candidates: preview.candidates,
            selectedComplaintIds: Set(preview.candidates.map(\.id)),
            skippedComplaintCount: preview.skippedComplaintCount
        )

        XCTAssertEqual(summary.selectedComplaintCount, 2)
        XCTAssertEqual(summary.targetCount, 2)
        XCTAssertEqual(summary.namedSourceCount, 1)
        XCTAssertEqual(summary.anonymousSourceCount, 1)
        XCTAssertEqual(summary.messageCount, 1)
        XCTAssertEqual(summary.missingMessageCount, 1)
        XCTAssertEqual(summary.datedCount, 1)
        XCTAssertEqual(summary.missingDateCount, 1)
        XCTAssertEqual(summary.skippedComplaintCount, 1)
        XCTAssertTrue(summary.hasSelection)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "selected=2 | targets=2 | namedSources=1 | anonymousSources=1 | withMessages=1 | missingMessages=1 | withDates=1 | missingDates=1 | skippedArchiveComplaints=1 | needsAttention=true"
        )
    }

    @MainActor
    func testComplaintArchiveImportReplacesLocalCachedComplaints() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": "",
              "targetClientDatabaseId": 22,
              "targetName": " Target ",
              "sourceClientDatabaseId": 44,
              "sourceName": " Reporter ",
              "message": " Abuse "
            }
          ]
        }
        """

        try model.importComplaintArchive(from: Data(archiveJSON.utf8))

        XCTAssertEqual(model.complaintEntries.count, 1)
        XCTAssertEqual(model.complaintEntries.first?.targetName, "Target")
        XCTAssertEqual(model.complaintEntries.first?.sourceName, "Reporter")
        XCTAssertEqual(model.complaintEntries.first?.message, "Abuse")
        XCTAssertEqual(model.lastError, nil)
    }

    @MainActor
    func testComplaintArchiveImportCanRestoreSelectedComplaints() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": "first",
              "targetClientDatabaseId": 22,
              "targetName": " Target ",
              "sourceClientDatabaseId": 44,
              "sourceName": " Reporter ",
              "message": " Abuse "
            },
            {
              "id": "second",
              "targetClientDatabaseId": 23,
              "sourceClientDatabaseId": 45,
              "message": " Noise "
            }
          ]
        }
        """
        let data = Data(archiveJSON.utf8)
        let preview = try model.complaintArchivePreview(from: data)

        try model.importComplaintArchive(from: data, selectedComplaintIds: [preview.candidates[1].id])

        XCTAssertEqual(model.complaintEntries.count, 1)
        XCTAssertEqual(model.complaintEntries.first?.targetClientDatabaseId, 23)
        XCTAssertEqual(model.complaintEntries.first?.sourceClientDatabaseId, 45)
        XCTAssertEqual(model.complaintEntries.first?.message, "Noise")
    }

    private func encodedComplaintFilterPresets(_ presets: [TS3ComplaintFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeComplaintFilterPreset(
        id: UUID,
        name: String,
        complaintFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) -> TS3ComplaintFilterPreset {
        TS3ComplaintFilterPreset(
            id: id,
            name: name,
            complaintFilter: complaintFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
