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

    @MainActor
    func testSavingDatabaseClientBookmarkCarriesClientAuditNote() throws {
        let model = TS3AppModel()
        model.serverHost = "voice.example.test"
        model.serverPort = "9990"
        model.nickname = "Avery"
        model.defaultChannel = "Ops/Lobby"
        let record = TS3DatabaseClientSummary(
            id: 42,
            uniqueIdentifier: "uid-db",
            nickname: "Riley",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )
        model.setContactStatus(.friend, for: record)
        model.setContactNote("raid lead", for: record)

        model.saveDatabaseClientBookmark(for: record)

        let bookmark = try XCTUnwrap(model.bookmarks.first)
        XCTAssertEqual(bookmark.name, "Riley @ voice.example.test")
        XCTAssertEqual(bookmark.folder, "Database Clients")
        XCTAssertEqual(bookmark.host, "voice.example.test")
        XCTAssertEqual(bookmark.port, "9990")
        XCTAssertEqual(bookmark.nickname, "Avery")
        XCTAssertEqual(bookmark.defaultChannel, "Ops/Lobby")
        XCTAssertEqual(bookmark.note, "clientDb=42 | contactStatus=Friend | clientUid=uid-db | contactNote=raid lead")
        XCTAssertEqual(
            model.databaseClientBookmarkSummary(for: record),
            "db=42 | nickname=Riley | uid=true | status=Friend | canSave=true | contactNote=true | name=Riley @ voice.example.test | folder=Database Clients | server=voice.example.test:9990 | nickname=Avery | note=clientDb=42 | contactStatus=Friend | clientUid=uid-db | contactNote=raid lead | defaultChannel=Ops/Lobby | serverPassword=No | channelPassword=No | privilegeKey=No"
        )
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testDatabaseClientBookmarkDraftSummaryReportsMissingServer() {
        let model = TS3AppModel()
        model.serverHost = " "
        let record = TS3DatabaseClientSummary(
            id: 42,
            uniqueIdentifier: nil,
            nickname: "Riley",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )

        let summary = model.databaseClientBookmarkDraftSummary(for: record)

        XCTAssertFalse(summary.canSave)
        XCTAssertFalse(summary.hasUniqueIdentifier)
        XCTAssertFalse(summary.hasContactNote)
        XCTAssertEqual(
            summary.clipboardSummary,
            "db=42 | nickname=Riley | uid=false | status=Neutral | canSave=false | server=missing"
        )
    }

    @MainActor
    func testSavingOnlineClientBookmarkUsesCurrentServerAndUserChannel() throws {
        let model = TS3AppModel()
        model.serverHost = "voice.example.test"
        model.serverPort = ""
        model.nickname = "Avery"
        model.serverPassword = "server-secret"
        model.channels = [
            makeChannel(id: 10, parentId: nil, name: "Ops"),
            makeChannel(id: 12, parentId: 10, name: "Lobby")
        ]
        let user = makeOnlineUser(
            id: 7,
            channelId: 12,
            databaseId: 42,
            uniqueIdentifier: "uid-online",
            nickname: "Riley"
        )
        model.setContactStatus(.friend, for: user)
        model.setContactNote("raid lead", for: user)

        model.saveOnlineClientBookmark(for: user)

        let bookmark = try XCTUnwrap(model.bookmarks.first)
        XCTAssertEqual(bookmark.name, "Riley @ voice.example.test")
        XCTAssertEqual(bookmark.folder, "Online Clients")
        XCTAssertEqual(bookmark.host, "voice.example.test")
        XCTAssertEqual(bookmark.port, "9987")
        XCTAssertEqual(bookmark.nickname, "Avery")
        XCTAssertEqual(bookmark.defaultChannel, "Ops/Lobby")
        XCTAssertEqual(bookmark.serverPassword, "server-secret")
        XCTAssertEqual(
            bookmark.note,
            "source=onlineClient | onlineClient=7 | contactStatus=Friend | channelId=12 | clientDb=42 | clientUid=uid-online | channelPath=Ops/Lobby | contactNote=raid lead"
        )
        XCTAssertEqual(
            model.onlineClientBookmarkSummary(for: user),
            "client=7 | nickname=Riley | db=42 | uid=true | status=Friend | channelId=12 | channelPath=true | canSave=true | contactNote=true | name=Riley @ voice.example.test | folder=Online Clients | server=voice.example.test:9987 | nickname=Avery | note=source=onlineClient | onlineClient=7 | contactStatus=Friend | channelId=12 | clientDb=42 | clientUid=uid-online | channelPath=Ops/Lobby | contactNote=raid lead | defaultChannel=Ops/Lobby | serverPassword=Configured | channelPassword=No | privilegeKey=No"
        )
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testOnlineClientBookmarkDraftSummaryReportsMissingServer() {
        let model = TS3AppModel()
        model.serverHost = " "
        let user = makeOnlineUser(
            id: 7,
            channelId: 12,
            databaseId: nil,
            uniqueIdentifier: nil,
            nickname: "Riley"
        )

        let summary = model.onlineClientBookmarkDraftSummary(for: user)

        XCTAssertFalse(summary.canSave)
        XCTAssertFalse(summary.hasUniqueIdentifier)
        XCTAssertFalse(summary.hasDatabaseId)
        XCTAssertFalse(summary.hasContactNote)
        XCTAssertEqual(
            summary.clipboardSummary,
            "client=7 | nickname=Riley | db=none | uid=false | status=Neutral | channelId=12 | channelPath=false | canSave=false | server=missing"
        )
    }

    @MainActor
    func testOnlineClientBookmarkReplacementDoesNotRemoveDatabaseBookmark() throws {
        let model = TS3AppModel()
        model.bookmarks = []
        model.serverHost = "voice.example.test"
        model.serverPort = "9988"
        let user = makeOnlineUser(
            id: 7,
            channelId: 12,
            databaseId: 42,
            uniqueIdentifier: "uid-online",
            nickname: "Riley"
        )
        let record = TS3DatabaseClientSummary(
            id: 42,
            uniqueIdentifier: "uid-online",
            nickname: "Riley",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )

        model.saveDatabaseClientBookmark(for: record)
        model.saveOnlineClientBookmark(for: user)
        model.saveOnlineClientBookmark(for: user)

        XCTAssertEqual(model.bookmarks.count, 2)
        XCTAssertEqual(model.bookmarks.filter { $0.folder == "Database Clients" }.count, 1)
        XCTAssertEqual(model.bookmarks.filter { $0.folder == "Online Clients" }.count, 1)
        XCTAssertEqual(model.onlineClientBookmarkSaveImpactSummary(for: user).replacementCount, 1)
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

    private func makeOnlineUser(
        id: Int,
        channelId: Int,
        databaseId: Int?,
        uniqueIdentifier: String?,
        nickname: String
    ) -> TS3UserSummary {
        TS3UserSummary(
            id: id,
            channelId: channelId,
            databaseId: databaseId,
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            isCurrentUser: false,
            isInputMuted: false,
            isOutputMuted: false,
            isAway: false,
            awayMessage: nil,
            isChannelCommander: false,
            isPrioritySpeaker: false,
            isTalker: false,
            isRequestingTalkPower: false,
            talkRequestMessage: nil,
            talkPower: nil,
            channelGroupId: nil,
            serverGroups: [],
            description: nil,
            avatarHash: nil,
            avatarURL: nil,
            iconId: nil,
            iconURL: nil,
            version: nil,
            platform: nil,
            country: nil,
            ipAddress: nil,
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            idleTimeSeconds: nil,
            connectedSeconds: nil
        )
    }

    private func makeChannel(id: Int, parentId: Int?, name: String) -> TS3ChannelSummary {
        TS3ChannelSummary(
            id: id,
            parentId: parentId,
            name: name,
            isDefault: false,
            isPasswordProtected: false,
            isPermanent: true,
            isCurrent: false
        )
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
