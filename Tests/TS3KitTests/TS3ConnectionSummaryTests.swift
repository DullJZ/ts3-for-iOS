import XCTest
@testable import TS3iOSApp

final class TS3ConnectionSummaryTests: XCTestCase {
    func testBookmarkSummaryIncludesAuditableConnectionFields() {
        let bookmark = TS3BookmarkSummary(
            name: "Raid Server",
            folder: "Operations",
            note: "primary ops",
            host: "voice.example.test",
            port: "9987",
            nickname: "Avery",
            phoneticNickname: "A very",
            serverPassword: "secret",
            defaultChannel: "Ops/Lobby",
            defaultChannelPassword: "channel-secret",
            privilegeKey: "token"
        )

        XCTAssertEqual(
            bookmark.clipboardSummary,
            "name=Raid Server | folder=Operations | server=voice.example.test:9987 | nickname=Avery | phonetic=A very | note=primary ops | defaultChannel=Ops/Lobby | serverPassword=Configured | channelPassword=Configured | privilegeKey=Configured"
        )
        XCTAssertEqual(
            bookmark.accessibilityValue,
            "Name Raid Server. Folder Operations. Server voice.example.test:9987. Nickname Avery. Phonetic nickname A very. Note primary ops. Default channel Ops/Lobby. Server password configured. Channel password configured. Privilege key configured"
        )
    }

    func testRecentConnectionSummaryOmitsEmptyOptionalFieldsAndReportsSecretState() {
        let snapshot = TS3ConnectionSnapshot(
            host: "voice.example.test",
            port: "9988",
            nickname: "",
            note: "",
            serverPassword: "",
            defaultChannel: "",
            defaultChannelPassword: "",
            privilegeKey: ""
        )

        XCTAssertEqual(
            snapshot.clipboardSummary,
            "server=voice.example.test:9988 | nickname=Not set | serverPassword=No | channelPassword=No | privilegeKey=No"
        )
        XCTAssertEqual(
            snapshot.accessibilityValue,
            "Server voice.example.test:9988. Nickname not set. Server password not configured. Channel password not configured. Privilege key not configured"
        )
    }

    @MainActor
    func testSavingContactBookmarkCarriesContactAuditNote() throws {
        let model = TS3AppModel()
        model.serverHost = "voice.example.test"
        model.serverPort = ""
        model.nickname = "Avery"
        model.defaultChannel = "Ops/Lobby"
        let contact = TS3ContactEntry(
            uniqueIdentifier: "uid-contact",
            nickname: "Riley",
            status: .friend,
            note: "raid lead",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        model.saveContactBookmark(for: contact)

        let bookmark = try XCTUnwrap(model.bookmarks.first)
        XCTAssertEqual(bookmark.name, "Riley @ voice.example.test")
        XCTAssertEqual(bookmark.folder, "Contacts")
        XCTAssertEqual(bookmark.host, "voice.example.test")
        XCTAssertEqual(bookmark.port, "9987")
        XCTAssertEqual(bookmark.nickname, "Avery")
        XCTAssertEqual(bookmark.defaultChannel, "Ops/Lobby")
        XCTAssertEqual(bookmark.note, "contactUid=uid-contact | contactStatus=Friend | contactNote=raid lead")
        XCTAssertEqual(
            model.contactBookmarkSummary(for: contact),
            "contact=Riley | uid=uid-contact | status=Friend | canSave=true | contactNote=true | name=Riley @ voice.example.test | folder=Contacts | server=voice.example.test:9987 | nickname=Avery | note=contactUid=uid-contact | contactStatus=Friend | contactNote=raid lead | defaultChannel=Ops/Lobby | serverPassword=No | channelPassword=No | privilegeKey=No"
        )
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testContactBookmarkDraftSummaryReportsMissingServer() {
        let model = TS3AppModel()
        model.serverHost = " "
        let contact = TS3ContactEntry(
            uniqueIdentifier: "uid-contact",
            nickname: "Riley",
            status: .blocked,
            note: "",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let summary = model.contactBookmarkDraftSummary(for: contact)

        XCTAssertFalse(summary.canSave)
        XCTAssertFalse(summary.hasContactNote)
        XCTAssertEqual(
            summary.clipboardSummary,
            "contact=Riley | uid=uid-contact | status=Blocked | canSave=false | server=missing"
        )
    }

    func testConnectionFilterPresetSummaryAndAccessibilityText() {
        let preset = makeConnectionFilterPreset(
            id: UUID(),
            name: "Ops Servers",
            connectionFilter: "withPrivilegeKey",
            sortMode: "host",
            sortAscending: false,
            bookmarkFolderFilter: "Operations",
            searchText: "raid"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Ops Servers | filter=withPrivilegeKey | sort=host | sortAscending=false | folder=Operations | search=raid"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Filter withPrivilegeKey. Sort host. Descending. Folder Operations. Search raid"
        )
    }

    @MainActor
    func testConnectionFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Connection Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importConnectionFilterPresets(from: encodedConnectionFilterPresets([
            makeConnectionFilterPreset(
                id: existingId,
                name: existingName,
                connectionFilter: "withPassword",
                sortMode: "host",
                bookmarkFolderFilter: "Ops",
                searchText: "keep"
            )
        ]))
        let data = try encodedConnectionFilterPresets([
            makeConnectionFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                connectionFilter: "invalidFilter",
                sortMode: "invalidSort",
                bookmarkFolderFilter: "  __unfiled__  ",
                searchText: "  search value  "
            ),
            makeConnectionFilterPreset(
                id: newId,
                name: " Raid Connections \(suffix) ",
                connectionFilter: "withDefaultChannel",
                sortMode: "note",
                sortAscending: false,
                bookmarkFolderFilter: String(repeating: "f", count: 140),
                searchText: String(repeating: "x", count: 140)
            ),
            makeConnectionFilterPreset(
                id: invalidId,
                name: "   ",
                connectionFilter: "withPassword",
                sortMode: "name",
                bookmarkFolderFilter: "Ignored",
                searchText: "ignored"
            )
        ])

        let preview = try model.connectionFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | filter=all | sort=savedOrder | sortAscending=true | folder=__unfiled__ | search=search value",
            "name=Raid Connections \(suffix) | filter=withDefaultChannel | sort=note | sortAscending=false | folder=\(String(repeating: "f", count: 120)) | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped connection filter presets: 1"))
    }

    @MainActor
    func testConnectionFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Connection Filter \(suffix)"
        let selectedName = "Selected Connection Filter \(suffix)"
        let unselectedName = "Unselected Connection Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importConnectionFilterPresets(from: encodedConnectionFilterPresets([
            makeConnectionFilterPreset(
                id: existingId,
                name: existingName,
                connectionFilter: "withPassword",
                sortMode: "host",
                bookmarkFolderFilter: "Ops",
                searchText: "keep"
            )
        ]))
        let data = try encodedConnectionFilterPresets([
            makeConnectionFilterPreset(
                id: existingId,
                name: existingName,
                connectionFilter: "withPrivilegeKey",
                sortMode: "note",
                bookmarkFolderFilter: "Replace",
                searchText: "replace"
            ),
            makeConnectionFilterPreset(
                id: selectedId,
                name: selectedName,
                connectionFilter: "withDefaultChannel",
                sortMode: "nickname",
                sortAscending: false,
                bookmarkFolderFilter: "__unfiled__",
                searchText: "ops"
            ),
            makeConnectionFilterPreset(
                id: unselectedId,
                name: unselectedName,
                connectionFilter: "withPassword",
                sortMode: "name",
                bookmarkFolderFilter: "Away",
                searchText: "away"
            )
        ])

        let restoredCount = try model.importConnectionFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.connectionFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.connectionFilter, "withPassword")
        XCTAssertEqual(existing.sortMode, "host")
        XCTAssertEqual(existing.bookmarkFolderFilter, "Ops")
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.connectionFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.connectionFilter, "withDefaultChannel")
        XCTAssertEqual(selected.sortMode, "nickname")
        XCTAssertEqual(selected.sortAscending, false)
        XCTAssertEqual(selected.bookmarkFolderFilter, "__unfiled__")
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.connectionFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func encodedConnectionFilterPresets(_ presets: [TS3ConnectionFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeConnectionFilterPreset(
        id: UUID,
        name: String,
        connectionFilter: String,
        sortMode: String,
        sortAscending: Bool = true,
        bookmarkFolderFilter: String,
        searchText: String
    ) -> TS3ConnectionFilterPreset {
        TS3ConnectionFilterPreset(
            id: id,
            name: name,
            connectionFilter: connectionFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            bookmarkFolderFilter: bookmarkFolderFilter,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
