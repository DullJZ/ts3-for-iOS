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

    func testChannelTreeFilterPresetSummaryAndAccessibilityText() {
        let preset = makeTreeFilterPreset(
            id: UUID(),
            name: "Ops Filter",
            treeFilter: "talkRequests",
            sortMode: "name",
            sortAscending: false,
            memberSortMode: "talkPower",
            memberSortAscending: false,
            currentUserFirst: false,
            searchText: "ops"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Ops Filter | filter=talkRequests | sort=name | sortAscending=false | memberSort=talkPower | memberSortAscending=false | currentUserFirst=false | search=ops"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Filter talkRequests. Channel sort name. Channels descending. Member sort talkPower. Members descending. Current user not pinned. Search ops"
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

    @MainActor
    func testChannelTreeFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importChannelTreeFilterPresets(from: encodedTreeFilterPresets([
            makeTreeFilterPreset(id: existingId, name: existingName, treeFilter: "default", searchText: "root")
        ]))
        let data = try encodedTreeFilterPresets([
            makeTreeFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                treeFilter: "unknown",
                sortMode: "badSort",
                memberSortMode: "badMembers",
                searchText: "  search value  "
            ),
            makeTreeFilterPreset(
                id: newId,
                name: " Raid Filter \(suffix) ",
                treeFilter: "talkRequests",
                sortMode: "name",
                sortAscending: false,
                memberSortMode: "status",
                memberSortAscending: false,
                currentUserFirst: false,
                searchText: String(repeating: "x", count: 140)
            ),
            makeTreeFilterPreset(id: invalidId, name: "   ", treeFilter: "all", searchText: "ignored")
        ])

        let preview = try model.channelTreeFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | filter=all | sort=serverOrder | sortAscending=true | memberSort=nickname | memberSortAscending=true | currentUserFirst=true | search=search value",
            "name=Raid Filter \(suffix) | filter=talkRequests | sort=name | sortAscending=false | memberSort=status | memberSortAscending=false | currentUserFirst=false | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped channel tree filter presets: 1"))
    }

    @MainActor
    func testChannelTreeFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Filter \(suffix)"
        let selectedName = "Selected Filter \(suffix)"
        let unselectedName = "Unselected Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importChannelTreeFilterPresets(from: encodedTreeFilterPresets([
            makeTreeFilterPreset(id: existingId, name: existingName, treeFilter: "default", searchText: "keep")
        ]))
        let data = try encodedTreeFilterPresets([
            makeTreeFilterPreset(id: existingId, name: existingName, treeFilter: "empty", searchText: "replace"),
            makeTreeFilterPreset(
                id: selectedId,
                name: selectedName,
                treeFilter: "talkRequests",
                sortMode: "name",
                sortAscending: false,
                memberSortMode: "status",
                memberSortAscending: false,
                currentUserFirst: false,
                searchText: "ops"
            ),
            makeTreeFilterPreset(id: unselectedId, name: unselectedName, treeFilter: "awayUsers", searchText: "away")
        ])

        let restoredCount = try model.importChannelTreeFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.channelTreeFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.treeFilter, "default")
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.channelTreeFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.treeFilter, "talkRequests")
        XCTAssertEqual(selected.sortMode, "name")
        XCTAssertEqual(selected.sortAscending, false)
        XCTAssertEqual(selected.memberSortMode, "status")
        XCTAssertEqual(selected.memberSortAscending, false)
        XCTAssertEqual(selected.currentUserFirst, false)
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.channelTreeFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func encodedPresets(_ presets: [TS3ChannelSubscriptionPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func encodedTreeFilterPresets(_ presets: [TS3ChannelTreeFilterPreset]) throws -> Data {
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

    private func makeTreeFilterPreset(
        id: UUID,
        name: String,
        treeFilter: String,
        sortMode: String = "serverOrder",
        sortAscending: Bool = true,
        memberSortMode: String = "nickname",
        memberSortAscending: Bool = true,
        currentUserFirst: Bool = true,
        searchText: String
    ) -> TS3ChannelTreeFilterPreset {
        TS3ChannelTreeFilterPreset(
            id: id,
            name: name,
            treeFilter: treeFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            memberSortMode: memberSortMode,
            memberSortAscending: memberSortAscending,
            currentUserFirst: currentUserFirst,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
