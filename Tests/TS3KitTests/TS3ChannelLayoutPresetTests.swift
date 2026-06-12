import XCTest
@testable import TS3iOSApp

final class TS3ChannelLayoutPresetTests: XCTestCase {
    func testChannelSubscriptionPresetSummaryAndAccessibilityText() {
        let preset = TS3ChannelSubscriptionPreset(
            name: "Raid Subs",
            channelIds: [41, 42, 43]
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Raid Subs | channels=3 | channelIds=41,42,43"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "3 subscribed channels. Channel IDs 41, 42, 43"
        )
    }

    @MainActor
    func testChannelSubscriptionPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Subs \(suffix)"
        let model = TS3AppModel()
        _ = try model.importChannelSubscriptionPresets(from: encodedPresets([
            makePreset(id: existingId, name: existingName, channelIds: [1, 2])
        ]))
        let data = try encodedPresets([
            makePreset(id: existingId, name: " \(existingName) ", channelIds: [5, 5, 0, -1]),
            makePreset(id: newId, name: " Raid Subs \(suffix) ", channelIds: [9, 7, 9]),
            makePreset(id: invalidId, name: "   ", channelIds: [12])
        ])

        let preview = try model.channelSubscriptionPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | channels=1 | channelIds=5",
            "name=Raid Subs \(suffix) | channels=2 | channelIds=7,9"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped subscription presets: 1"))
    }

    @MainActor
    func testChannelSubscriptionPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Subs \(suffix)"
        let selectedName = "Selected Subs \(suffix)"
        let unselectedName = "Unselected Subs \(suffix)"
        let model = TS3AppModel()
        _ = try model.importChannelSubscriptionPresets(from: encodedPresets([
            makePreset(id: existingId, name: existingName, channelIds: [1, 2])
        ]))
        let data = try encodedPresets([
            makePreset(id: existingId, name: existingName, channelIds: [5]),
            makePreset(id: selectedId, name: selectedName, channelIds: [8, 8, 9]),
            makePreset(id: unselectedId, name: unselectedName, channelIds: [11])
        ])

        let restoredCount = try model.importChannelSubscriptionPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.channelSubscriptionPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.channelIds, [1, 2])
        let selected = try XCTUnwrap(model.channelSubscriptionPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.channelIds, [8, 9])
        XCTAssertFalse(model.channelSubscriptionPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func encodedPresets(_ presets: [TS3ChannelSubscriptionPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makePreset(id: UUID, name: String, channelIds: [Int]) -> TS3ChannelSubscriptionPreset {
        TS3ChannelSubscriptionPreset(
            id: id,
            name: name,
            channelIds: channelIds,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
