import XCTest
@testable import TS3iOSApp

final class TS3TemporaryPasswordPresetTests: XCTestCase {
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
    func testTemporaryPasswordPresetImportSanitizesInvalidFields() throws {
        let model = TS3AppModel()
        let presetName = "Temp Password Sanitized Preset"
        deletePresets(named: presetName, in: model)
        defer { deletePresets(named: presetName, in: model) }
        let longSearch = String(repeating: "x", count: 140)
        let data = Data("""
        [
          {
            "id": "11111111-1111-1111-1111-111111111111",
            "name": "  \(presetName)  ",
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
          }
        ]
        """.utf8)

        XCTAssertEqual(try model.importTemporaryServerPasswordFilterPresets(from: data), 2)

        let preset = try XCTUnwrap(model.temporaryServerPasswordFilterPresets.first { $0.name == presetName })
        XCTAssertEqual(preset.passwordFilter, "all")
        XCTAssertEqual(preset.sortMode, "created")
        XCTAssertTrue(preset.sortAscending)
        XCTAssertEqual(preset.searchText.count, 120)
    }

    @MainActor
    func testTemporaryPasswordPresetImportMergesByNameAndExports() throws {
        let model = TS3AppModel()
        let presetName = "Temp Password Merge Preset"
        deletePresets(named: presetName, in: model)
        defer { deletePresets(named: presetName, in: model) }
        model.saveTemporaryServerPasswordFilterPreset(
            name: presetName,
            passwordFilter: "serverDefault",
            sortMode: "target",
            sortAscending: false,
            searchText: "old"
        )

        let data = Data("""
        [
          {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "\(presetName.lowercased())",
            "passwordFilter": "channelTarget",
            "sortMode": "duration",
            "sortAscending": true,
            "searchText": "new",
            "updatedAt": 2
          }
        ]
        """.utf8)

        XCTAssertEqual(try model.importTemporaryServerPasswordFilterPresets(from: data), 1)

        let matchingPresets = model.temporaryServerPasswordFilterPresets.filter {
            $0.name.caseInsensitiveCompare(presetName) == .orderedSame
        }
        let preset = try XCTUnwrap(matchingPresets.first)
        XCTAssertEqual(matchingPresets.count, 1)
        XCTAssertEqual(preset.name, presetName.lowercased())
        XCTAssertEqual(preset.passwordFilter, "channelTarget")
        XCTAssertEqual(preset.sortMode, "duration")
        XCTAssertTrue(preset.sortAscending)
        XCTAssertEqual(preset.searchText, "new")
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
