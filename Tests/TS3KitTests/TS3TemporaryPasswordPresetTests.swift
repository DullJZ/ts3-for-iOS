import XCTest
@testable import TS3iOSApp

final class TS3TemporaryPasswordPresetTests: XCTestCase {
    func testTemporaryPasswordDraftValidatorRejectsInvalidDrafts() {
        XCTAssertEqual(
            TS3TemporaryServerPasswordDraftValidator.validationMessages(
                password: "  ",
                durationSeconds: nil,
                description: "Guest\naccess",
                targetChannelId: nil,
                targetChannelPassword: "secret\nagain"
            ),
            [
                "Temporary password is required before creating.",
                "Duration must be a positive number of seconds.",
                "Description must be a single line.",
                "Target channel password must be a single line.",
                "Select a target channel before setting a target channel password."
            ]
        )
    }

    func testTemporaryPasswordDraftValidatorBuildsAuditableCreationSummary() {
        let messages = TS3TemporaryServerPasswordDraftValidator.validationMessages(
            password: " guest-pass ",
            durationSeconds: 3_600,
            description: " Guest access ",
            targetChannelId: 12,
            targetChannelPassword: " secret "
        )
        let summary = TS3TemporaryServerPasswordDraftValidator.creationSummary(
            password: " guest-pass ",
            durationSeconds: 3_600,
            description: " Guest access ",
            targetChannelId: 12,
            targetChannelName: "Lobby",
            targetChannelPassword: " secret "
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(
            summary,
            "password=guest-pass | duration=1h | target=Lobby (12) | description=Guest access | targetChannelPassword=set"
        )
    }

    func testTemporaryPasswordDraftValidatorSummarizesServerDefaultTarget() {
        let summary = TS3TemporaryServerPasswordDraftValidator.creationSummary(
            password: "server-pass",
            durationSeconds: 600,
            description: "",
            targetChannelId: nil,
            targetChannelName: nil,
            targetChannelPassword: ""
        )

        XCTAssertEqual(summary, "password=server-pass | duration=10m | target=Server Default")
    }

    func testTemporaryPasswordSummaryCopyAndAccessibilityText() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = TS3TemporaryServerPasswordSummary(
            id: "join-123",
            password: "join-123",
            creatorUniqueIdentifier: "creator-uid",
            creatorDatabaseId: 77,
            creatorName: "Admin",
            targetChannelId: 12,
            targetChannelPassword: "secret",
            createdAt: createdAt,
            durationSeconds: 3_600,
            description: "Guest access"
        )
        let channels = [
            TS3ChannelSummary(
                id: 12,
                parentId: nil,
                order: 0,
                name: "Lobby",
                isDefault: false,
                isPasswordProtected: false,
                isPermanent: true,
                isCurrent: false
            )
        ]

        XCTAssertEqual(entry.targetText(channels: channels), "Lobby")
        XCTAssertEqual(entry.creatorText, "Admin")
        XCTAssertEqual(
            entry.clipboardSummary(channels: channels),
            "password=join-123 | duration=1h | createdAt=\(TS3TemporaryServerPasswordSummary.dateText(createdAt)) | description=Guest access | target=Lobby (12) | creator=Admin"
        )
        XCTAssertEqual(
            entry.accessibilityValue(channels: channels),
            "Temporary server password. Target Lobby. Duration 1h. Created date available. Description Guest access. Creator Admin"
        )
    }

    func testTemporaryPasswordSummaryFallsBackToServerDefaultAndCreatorDatabaseId() {
        let entry = TS3TemporaryServerPasswordSummary(
            id: "server-default",
            password: "server-default",
            creatorUniqueIdentifier: nil,
            creatorDatabaseId: 91,
            creatorName: nil,
            targetChannelId: nil,
            targetChannelPassword: nil,
            createdAt: nil,
            durationSeconds: nil,
            description: nil
        )

        XCTAssertEqual(entry.targetText(channels: []), "Server Default")
        XCTAssertEqual(entry.creatorText, "Database ID 91")
        XCTAssertEqual(entry.clipboardSummary(channels: []), "password=server-default | creatorDb=91")
        XCTAssertEqual(
            entry.accessibilityValue(channels: []),
            "Temporary server password. Target Server Default. Creator Database ID 91"
        )
    }

    @MainActor
    func testTemporaryPasswordPresetSummaryAndAccessibilityText() {
        let preset = TS3TemporaryServerPasswordFilterPreset(
            name: "Guest Passwords",
            passwordFilter: "channelTarget",
            sortMode: "duration",
            sortAscending: true,
            searchText: "ops"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Guest Passwords | passwordFilter=channelTarget | sortMode=duration | sortAscending=true | search=ops"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Temporary password filter channelTarget. Sort by duration. Ascending. Search ops"
        )
    }

    @MainActor
    func testTemporaryPasswordPresetImportPreviewSanitizesCandidates() throws {
        let model = TS3AppModel()
        let existingName = "Temp Password Existing Preview Preset"
        let importedName = "Temp Password Sanitized Preview Preset"
        deletePresets(named: existingName, in: model)
        deletePresets(named: importedName, in: model)
        defer {
            deletePresets(named: existingName, in: model)
            deletePresets(named: importedName, in: model)
        }
        model.saveTemporaryServerPasswordFilterPreset(
            name: existingName,
            passwordFilter: "serverDefault",
            sortMode: "target",
            sortAscending: false,
            searchText: "old"
        )
        let longSearch = String(repeating: "x", count: 140)
        let data = Data("""
        [
          {
            "id": "11111111-1111-1111-1111-111111111111",
            "name": "  \(importedName)  ",
            "passwordFilter": "bad-filter",
            "sortMode": "bad-sort",
            "sortAscending": true,
            "searchText": "  \(longSearch)  ",
            "updatedAt": 0
          },
          {
            "id": "22222222-2222-2222-2222-222222222222",
            "name": "   ",
            "passwordFilter": "withCreator",
            "sortMode": "creator",
            "sortAscending": false,
            "searchText": "ignored",
            "updatedAt": 1
          },
          {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "\(existingName.lowercased())",
            "passwordFilter": "withExpiration",
            "sortMode": "duration",
            "sortAscending": false,
            "searchText": "replace",
            "updatedAt": 2
          }
        ]
        """.utf8)

        let preview = try model.temporaryServerPasswordFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertTrue(preview.hasPresets)
        XCTAssertEqual(preview.candidates.count, 2)
        XCTAssertTrue(preview.containsPreset(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!))
        XCTAssertFalse(preview.containsPreset(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!))
        XCTAssertTrue(preview.clipboardSummary.contains("Imported temporary password filter presets: 3"))
        XCTAssertTrue(preview.presetSummaries.contains { summary in
            summary.contains("name=\(importedName)")
                && summary.contains("passwordFilter=all")
                && summary.contains("sortMode=created")
                && summary.contains("search=\(String(longSearch.prefix(120)))")
        })
    }

    @MainActor
    func testTemporaryPasswordPresetImportRestoresOnlySelectedPresets() throws {
        let model = TS3AppModel()
        let unchangedName = "Temp Password Unchanged Preset"
        let replacedName = "Temp Password Replace Preset"
        let skippedName = "Temp Password Skipped Preset"
        deletePresets(named: unchangedName, in: model)
        deletePresets(named: replacedName, in: model)
        deletePresets(named: skippedName, in: model)
        defer {
            deletePresets(named: unchangedName, in: model)
            deletePresets(named: replacedName, in: model)
            deletePresets(named: skippedName, in: model)
        }
        model.saveTemporaryServerPasswordFilterPreset(
            name: unchangedName,
            passwordFilter: "serverDefault",
            sortMode: "target",
            sortAscending: false,
            searchText: "old"
        )
        model.saveTemporaryServerPasswordFilterPreset(
            name: replacedName,
            passwordFilter: "serverDefault",
            sortMode: "target",
            sortAscending: false,
            searchText: "old"
        )

        let data = Data("""
        [
          {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "\(replacedName.lowercased())",
            "passwordFilter": "channelTarget",
            "sortMode": "duration",
            "sortAscending": true,
            "searchText": "new",
            "updatedAt": 2
          },
          {
            "id": "44444444-4444-4444-4444-444444444444",
            "name": "\(skippedName)",
            "passwordFilter": "withCreator",
            "sortMode": "creator",
            "sortAscending": false,
            "searchText": "skip",
            "updatedAt": 3
          }
        ]
        """.utf8)

        XCTAssertEqual(
            try model.importTemporaryServerPasswordFilterPresets(
                from: data,
                selectedPresetIds: [UUID(uuidString: "33333333-3333-3333-3333-333333333333")!]
            ),
            1
        )

        let matchingPresets = model.temporaryServerPasswordFilterPresets.filter {
            $0.name.caseInsensitiveCompare(replacedName) == .orderedSame
        }
        let preset = try XCTUnwrap(matchingPresets.first)
        XCTAssertEqual(matchingPresets.count, 1)
        XCTAssertEqual(preset.name, replacedName.lowercased())
        XCTAssertEqual(preset.passwordFilter, "channelTarget")
        XCTAssertEqual(preset.sortMode, "duration")
        XCTAssertTrue(preset.sortAscending)
        XCTAssertEqual(preset.searchText, "new")
        XCTAssertTrue(model.temporaryServerPasswordFilterPresets.contains { preset in
            preset.name == unchangedName
                && preset.passwordFilter == "serverDefault"
                && preset.searchText == "old"
        })
        XCTAssertFalse(model.temporaryServerPasswordFilterPresets.contains { preset in
            preset.name == skippedName
        })
        XCTAssertFalse(try model.temporaryServerPasswordFilterPresetsExportData().isEmpty)
    }

    @MainActor
    func testMigrationPreviewIncludesTemporaryPasswordFilterCount() throws {
        let model = TS3AppModel()
        let presetName = "Temp Password Migration Preset"
        deletePresets(named: presetName, in: model)
        defer { deletePresets(named: presetName, in: model) }
        model.saveTemporaryServerPasswordFilterPreset(
            name: presetName,
            passwordFilter: "channelTarget",
            sortMode: "duration",
            sortAscending: true,
            searchText: "ops"
        )

        let exported = try model.clientMigrationPackageExportData()
        let preview = try model.clientMigrationPackagePreview(from: exported)

        XCTAssertTrue(preview.itemCounts.contains { item in
            item.0 == "Temporary Password Filters"
                && item.1 == model.temporaryServerPasswordFilterPresets.count
        })
    }

    @MainActor
    private func deletePresets(named name: String, in model: TS3AppModel) {
        for preset in model.temporaryServerPasswordFilterPresets
            where preset.name.caseInsensitiveCompare(name) == .orderedSame {
            model.deleteTemporaryServerPasswordFilterPreset(preset)
        }
    }
}
