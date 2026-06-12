import XCTest
@testable import TS3iOSApp

final class TS3FileBrowserPresetTests: XCTestCase {
    func testFileBrowserFilterPresetSummaryAndAccessibilityText() {
        let preset = makeFileBrowserFilterPreset(
            id: UUID(),
            name: "Maps",
            sortMode: "modified",
            sortAscending: false,
            searchText: ".bsp"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Maps | sortMode=modified | sortAscending=false | search=.bsp"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Sort by modified. Descending. Search .bsp"
        )
    }

    @MainActor
    func testFileBrowserFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing File Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importFileBrowserFilterPresets(from: encodedFileBrowserFilterPresets([
            makeFileBrowserFilterPreset(
                id: existingId,
                name: existingName,
                sortMode: "size",
                sortAscending: false,
                searchText: "keep"
            )
        ]))
        let data = try encodedFileBrowserFilterPresets([
            makeFileBrowserFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                sortMode: "invalidSort",
                sortAscending: true,
                searchText: "  search value  "
            ),
            makeFileBrowserFilterPreset(
                id: newId,
                name: " Uploads \(suffix) ",
                sortMode: "modified",
                sortAscending: false,
                searchText: String(repeating: "x", count: 140)
            ),
            makeFileBrowserFilterPreset(
                id: invalidId,
                name: "   ",
                sortMode: "type",
                sortAscending: true,
                searchText: "ignored"
            )
        ])

        let preview = try model.fileBrowserFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | sortMode=name | sortAscending=true | search=search value",
            "name=Uploads \(suffix) | sortMode=modified | sortAscending=false | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped file filter presets: 1"))
    }

    @MainActor
    func testFileBrowserFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing File Filter \(suffix)"
        let selectedName = "Selected File Filter \(suffix)"
        let unselectedName = "Unselected File Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importFileBrowserFilterPresets(from: encodedFileBrowserFilterPresets([
            makeFileBrowserFilterPreset(
                id: existingId,
                name: existingName,
                sortMode: "size",
                sortAscending: false,
                searchText: "keep"
            )
        ]))
        let data = try encodedFileBrowserFilterPresets([
            makeFileBrowserFilterPreset(
                id: existingId,
                name: existingName,
                sortMode: "modified",
                sortAscending: true,
                searchText: "replace"
            ),
            makeFileBrowserFilterPreset(
                id: selectedId,
                name: selectedName,
                sortMode: "type",
                sortAscending: false,
                searchText: ".wav"
            ),
            makeFileBrowserFilterPreset(
                id: unselectedId,
                name: unselectedName,
                sortMode: "name",
                sortAscending: true,
                searchText: ".tmp"
            )
        ])

        let restoredCount = try model.importFileBrowserFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.fileBrowserFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.sortMode, "size")
        XCTAssertEqual(existing.sortAscending, false)
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.fileBrowserFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.sortMode, "type")
        XCTAssertEqual(selected.sortAscending, false)
        XCTAssertEqual(selected.searchText, ".wav")
        XCTAssertFalse(model.fileBrowserFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func encodedFileBrowserFilterPresets(_ presets: [TS3FileBrowserFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeFileBrowserFilterPreset(
        id: UUID,
        name: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) -> TS3FileBrowserFilterPreset {
        TS3FileBrowserFilterPreset(
            id: id,
            name: name,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
