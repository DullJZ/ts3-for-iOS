import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3GroupSummaryTests: XCTestCase {
    func testGroupDraftValidatorRejectsMissingDuplicateMultilineAndNoopRename() {
        let existing = [
            TS3GroupSummary(id: 6, name: "Admins", type: .regular),
            TS3GroupSummary(id: 7, name: "Guests", type: .regular)
        ]

        XCTAssertEqual(
            TS3GroupDraftValidator.validationMessages(
                operation: .rename,
                name: "Admins\n",
                target: .server,
                type: .regular,
                sourceGroup: existing[0],
                existingGroups: existing
            ),
            [
                "Group name must be a single line.",
                "Enter a different group name before renaming."
            ]
        )
        XCTAssertEqual(
            TS3GroupDraftValidator.validationMessages(
                operation: .copy,
                name: " guests ",
                target: .server,
                type: .regular,
                sourceGroup: existing[0],
                existingGroups: existing
            ),
            ["Server group named guests already exists."]
        )
        XCTAssertEqual(
            TS3GroupDraftValidator.validationMessages(
                operation: .create,
                name: " ",
                target: .channel,
                type: .regular,
                sourceGroup: nil,
                existingGroups: []
            ),
            ["Group name is required before create."]
        )
    }

    func testGroupDraftValidatorBuildsAuditableSummaries() {
        let source = TS3GroupSummary(id: 6, name: "Admins", type: .regular)
        let copySummary = TS3GroupDraftValidator.creationSummary(
            operation: .copy,
            name: " Admin Copy ",
            target: .server,
            type: .query,
            sourceGroup: source
        )
        let renameSummary = TS3GroupDraftValidator.creationSummary(
            operation: .rename,
            name: " Operators ",
            target: .channel,
            type: .regular,
            sourceGroup: source
        )

        XCTAssertEqual(
            copySummary,
            "operation=Copy | target=Server Groups | source=Admins (6) | name=Admin Copy | type=Query"
        )
        XCTAssertEqual(
            renameSummary,
            "operation=Rename | target=Channel Groups | source=Admins (6) | newName=Operators"
        )
    }

    func testGroupMemberDraftValidatorRejectsInvalidMemberChanges() {
        let group = TS3GroupSummary(id: 6, name: "Admins", type: .regular)

        XCTAssertEqual(
            TS3GroupMemberDraftValidator.validationMessages(
                operation: .addServerMember,
                target: .server,
                group: group,
                clientDatabaseId: " ",
                channelId: nil
            ),
            ["Client database ID is required before adding a group member."]
        )
        XCTAssertEqual(
            TS3GroupMemberDraftValidator.validationMessages(
                operation: .setChannelGroup,
                target: .channel,
                group: group,
                clientDatabaseId: "abc",
                channelId: nil
            ),
            [
                "Client database ID must be a positive number.",
                "Select a channel before setting a channel group."
            ]
        )
        XCTAssertEqual(
            TS3GroupMemberDraftValidator.validationMessages(
                operation: .addServerMember,
                target: .channel,
                group: TS3GroupSummary(id: 0, name: "Broken", type: nil),
                clientDatabaseId: "42",
                channelId: nil
            ),
            [
                "Select Server Groups before adding a server group member.",
                "Select a valid group before changing membership."
            ]
        )
    }

    func testGroupMemberDraftValidatorBuildsAuditableSummaries() {
        let group = TS3GroupSummary(id: 6, name: "Admins", type: .regular)
        let addSummary = TS3GroupMemberDraftValidator.changeSummary(
            operation: .addServerMember,
            target: .server,
            group: group,
            clientDatabaseId: " 42 ",
            channelId: nil,
            channelName: nil
        )
        let setSummary = TS3GroupMemberDraftValidator.changeSummary(
            operation: .setChannelGroup,
            target: .channel,
            group: group,
            clientDatabaseId: "43",
            channelId: 9,
            channelName: "Lobby"
        )

        XCTAssertEqual(
            addSummary,
            "operation=Add Member | target=Server Groups | group=Admins (6) | clientDb=42"
        )
        XCTAssertEqual(
            setSummary,
            "operation=Set Channel Group | target=Channel Groups | group=Admins (6) | clientDb=43 | channel=Lobby (9)"
        )
    }

    func testGroupClipboardSummaryIncludesIdNameAndType() {
        let group = TS3GroupSummary(id: 6, name: "Admins", type: .regular)

        XCTAssertEqual(group.clipboardSummary, "groupId=6 | name=Admins | type=Regular")
        XCTAssertEqual(
            group.clipboardSummary(target: .server),
            "target=Server Groups | groupId=6 | name=Admins | type=Regular"
        )
        XCTAssertEqual(
            group.accessibilityValue(target: .server),
            "Server Groups group. ID 6. Type Regular."
        )
    }

    func testGroupListSummaryDeduplicatesAndCountsVisibleGroups() {
        let summary = TS3GroupListSummary(
            groups: [
                TS3GroupSummary(id: 6, name: "Admins", type: .regular),
                TS3GroupSummary(id: 7, name: "Query", type: .query),
                TS3GroupSummary(id: 8, name: "Template", type: .template),
                TS3GroupSummary(id: 9, name: "Unknown", type: nil),
                TS3GroupSummary(id: 6, name: "Duplicate", type: .query)
            ],
            target: .server
        )

        XCTAssertEqual(summary.totalCount, 4)
        XCTAssertEqual(summary.templateCount, 1)
        XCTAssertEqual(summary.regularCount, 1)
        XCTAssertEqual(summary.queryCount, 1)
        XCTAssertEqual(summary.unknownTypeCount, 1)
        XCTAssertEqual(summary.lowestGroupId, 6)
        XCTAssertEqual(summary.highestGroupId, 9)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "target=Server Groups | groups=4 | template=1 | regular=1 | query=1 | unknown=1 | lowestGroupId=6 | highestGroupId=9 | needsAttention=true"
        )
    }

    func testGroupClientClipboardSummaryIncludesGroupTargetAndChannel() {
        let group = TS3GroupSummary(id: 6, name: "Admins", type: .regular)
        let client = TS3GroupClientSummary(client: TS3GroupClient(
            clientDatabaseId: 42,
            uniqueIdentifier: "client-uid",
            nickname: "Taylor",
            channelId: 9
        ))

        XCTAssertEqual(
            client.clipboardSummary(group: group, target: .server, channelName: "Lobby"),
            "group=Admins (6) | target=Server Groups | clientDb=42 | nickname=Taylor | uid=client-uid | channel=Lobby (9)"
        )
        XCTAssertEqual(
            client.accessibilityValue(group: group, target: .server, channelName: "Lobby"),
            "Server Groups group Admins. Database ID 42. Channel Lobby. Unique ID client-uid"
        )
    }

    func testGroupClientClipboardSummaryFallsBackWhenNicknameAndChannelNameAreMissing() {
        let group = TS3GroupSummary(id: 7, name: "Guests", type: nil)
        let client = TS3GroupClientSummary(client: TS3GroupClient(
            clientDatabaseId: 43,
            uniqueIdentifier: nil,
            nickname: nil,
            channelId: 10
        ))

        XCTAssertEqual(
            client.clipboardSummary(group: group, target: .channel, channelName: nil),
            "group=Guests (7) | target=Channel Groups | clientDb=43 | nickname=Client 43 | channel=Channel 10 (10)"
        )
        XCTAssertEqual(
            client.accessibilityValue(group: group, target: .channel, channelName: nil),
            "Channel Groups group Guests. Database ID 43. Channel Channel 10"
        )
    }

    func testGroupClientListSummaryDeduplicatesAndCountsVisibleMembers() {
        let summary = TS3GroupClientListSummary(
            clients: [
                TS3GroupClientSummary(client: TS3GroupClient(
                    clientDatabaseId: 42,
                    uniqueIdentifier: "uid-42",
                    nickname: "Taylor",
                    channelId: 9
                )),
                TS3GroupClientSummary(client: TS3GroupClient(
                    clientDatabaseId: 43,
                    uniqueIdentifier: nil,
                    nickname: "Morgan",
                    channelId: nil
                )),
                TS3GroupClientSummary(client: TS3GroupClient(
                    clientDatabaseId: 44,
                    uniqueIdentifier: "",
                    nickname: nil,
                    channelId: 10
                )),
                TS3GroupClientSummary(client: TS3GroupClient(
                    clientDatabaseId: 42,
                    uniqueIdentifier: "duplicate",
                    nickname: "Duplicate",
                    channelId: 11
                ))
            ],
            target: .channel
        )

        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.onlineCount, 2)
        XCTAssertEqual(summary.offlineCount, 1)
        XCTAssertEqual(summary.withUniqueIdCount, 1)
        XCTAssertEqual(summary.withoutUniqueIdCount, 2)
        XCTAssertEqual(summary.channelScopedCount, 2)
        XCTAssertEqual(summary.distinctChannelCount, 2)
        XCTAssertEqual(summary.lowestClientDatabaseId, 42)
        XCTAssertEqual(summary.highestClientDatabaseId, 44)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "target=Channel Groups | members=3 | online=2 | offline=1 | withUid=1 | withoutUid=2 | channelScoped=2 | distinctChannels=2 | lowestClientDb=42 | highestClientDb=44 | needsAttention=true"
        )
    }

    func testGroupFilterPresetSummariesAreCopyableAndAccessible() {
        let preset = TS3GroupFilterPreset(
            name: "Server operators",
            target: "server",
            groupTypeFilter: "regular",
            sortMode: "id",
            sortAscending: false,
            searchText: " admin "
        )

        XCTAssertEqual(
            preset.inlineSummary,
            "Target: Server Groups · Type filter: Regular · Sort: ID Descending · Search: admin"
        )
        XCTAssertEqual(
            preset.clipboardSummary,
            """
            Target: Server Groups
            Type filter: Regular
            Sort: ID Descending
            Search: admin
            """
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Server operators. Target: Server Groups. Type filter: Regular. Sort: ID Descending. Search: admin"
        )
    }

    func testGroupClientFilterPresetSummariesIncludeSelectedChannelName() {
        let preset = TS3GroupClientFilterPreset(
            name: "Lobby online",
            memberFilter: "online",
            channelFilter: "selectedChannel",
            channelId: 9,
            sortMode: "databaseId",
            sortAscending: true,
            searchText: " Taylor "
        )

        XCTAssertEqual(
            preset.inlineSummary(channelName: "Lobby"),
            "Status filter: Online · Channel filter: Lobby (9) · Sort: Database ID Ascending · Search: Taylor"
        )
        XCTAssertEqual(
            preset.clipboardSummary(channelName: "Lobby"),
            """
            Status filter: Online
            Channel filter: Lobby (9)
            Sort: Database ID Ascending
            Search: Taylor
            """
        )
        XCTAssertEqual(
            preset.accessibilityValue(channelName: "Lobby"),
            "Lobby online. Status filter: Online. Channel filter: Lobby (9). Sort: Database ID Ascending. Search: Taylor"
        )

        let fallback = TS3GroupClientFilterPreset(
            name: "Missing channel",
            memberFilter: "withoutUniqueId",
            channelFilter: "selectedChannel",
            channelId: 10,
            sortMode: "uniqueId",
            sortAscending: false,
            searchText: ""
        )
        XCTAssertEqual(
            fallback.inlineSummary(),
            "Status filter: Without Unique ID · Channel filter: Channel 10 (10) · Sort: Unique ID Descending"
        )
    }

    @MainActor
    func testGroupArchivePreviewSanitizesCountsAndFirstDetails() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "serverGroups": [
            { "id": 6, "name": " Admins ", "type": 1 },
            { "id": 6, "name": "Duplicate", "type": 1 },
            { "id": 7, "name": " Query ", "type": 2 },
            { "id": 0, "name": "Invalid", "type": 1 },
            { "id": 8, "name": "   ", "type": 1 }
          ],
          "channelGroups": [
            { "id": 9, "name": " Channel Admin ", "type": 1 },
            { "id": 10, "name": "Template", "type": 0 },
            { "id": 10, "name": "Duplicate", "type": 0 },
            { "id": 11, "name": "Unknown" }
          ]
        }
        """

        let preview = try model.groupArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.serverGroupCount, 2)
        XCTAssertEqual(preview.channelGroupCount, 3)
        XCTAssertEqual(preview.skippedServerGroupCount, 3)
        XCTAssertEqual(preview.skippedChannelGroupCount, 1)
        XCTAssertEqual(preview.regularCount, 2)
        XCTAssertEqual(preview.queryCount, 1)
        XCTAssertEqual(preview.templateCount, 1)
        XCTAssertEqual(preview.unknownTypeCount, 1)
        XCTAssertEqual(preview.firstServerGroupName, "Admins")
        XCTAssertEqual(preview.firstChannelGroupName, "Channel Admin")
        XCTAssertEqual(
            preview.serverGroupTypeSummaries,
            [
                "target=Server Groups type=Query count=1",
                "target=Server Groups type=Regular count=1"
            ]
        )
        XCTAssertEqual(
            preview.channelGroupTypeSummaries,
            [
                "target=Channel Groups type=Regular count=1",
                "target=Channel Groups type=Template count=1",
                "target=Channel Groups type=Unknown count=1"
            ]
        )
        XCTAssertEqual(
            preview.serverGroupSummaries,
            [
                "target=Server Groups | groupId=6 | name=Admins | type=Regular",
                "target=Server Groups | groupId=7 | name=Query | type=Query"
            ]
        )
        XCTAssertEqual(
            preview.channelGroupSummaries,
            [
                "target=Channel Groups | groupId=9 | name=Channel Admin | type=Regular",
                "target=Channel Groups | groupId=10 | name=Template | type=Template",
                "target=Channel Groups | groupId=11 | name=Unknown | type=Unknown"
            ]
        )
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "target=Server Groups | groupId=6 | name=Admins | type=Regular",
                "target=Server Groups | groupId=7 | name=Query | type=Query",
                "target=Channel Groups | groupId=9 | name=Channel Admin | type=Regular",
                "target=Channel Groups | groupId=10 | name=Template | type=Template",
                "target=Channel Groups | groupId=11 | name=Unknown | type=Unknown"
            ]
        )
        XCTAssertEqual(preview.candidates.map(\.id), ["server:6", "server:7", "channel:9", "channel:10", "channel:11"])
        XCTAssertEqual(preview.candidates.filter { $0.target == .server }.count, 2)
        XCTAssertEqual(preview.candidates.filter { $0.target == .channel }.count, 3)
        XCTAssertTrue(preview.containsGroup(id: "channel:9"))
        XCTAssertFalse(preview.containsGroup(id: "server:9"))
        XCTAssertEqual(
            preview.clipboardSummary,
            (
                preview.serverGroupTypeSummaries
                + preview.channelGroupTypeSummaries
                + preview.serverGroupSummaries
                + preview.channelGroupSummaries
            ).joined(separator: "\n")
        )
        XCTAssertTrue(preview.hasGroups)
    }

    @MainActor
    func testGroupArchiveImportReplacesLocalCachedGroups() throws {
        let model = TS3AppModel()
        model.serverGroups = [TS3GroupSummary(id: 1, name: "Old Server", type: .regular)]
        model.channelGroups = [TS3GroupSummary(id: 2, name: "Old Channel", type: .regular)]
        let archiveJSON = """
        {
          "serverGroups": [
            { "id": 12, "name": " Server Operators ", "type": 1 }
          ],
          "channelGroups": [
            { "id": 13, "name": " Channel Voice ", "type": 1 }
          ]
        }
        """

        try model.importGroupArchive(from: Data(archiveJSON.utf8))

        XCTAssertEqual(model.serverGroups.map(\.id), [12])
        XCTAssertEqual(model.serverGroups.first?.name, "Server Operators")
        XCTAssertEqual(model.channelGroups.map(\.id), [13])
        XCTAssertEqual(model.channelGroups.first?.name, "Channel Voice")
        XCTAssertEqual(model.lastError, nil)
    }

    @MainActor
    func testGroupArchiveImportCanRestoreSelectedGroups() throws {
        let model = TS3AppModel()
        model.serverGroups = [TS3GroupSummary(id: 1, name: "Old Server", type: .regular)]
        model.channelGroups = [TS3GroupSummary(id: 2, name: "Old Channel", type: .regular)]
        let archiveJSON = """
        {
          "serverGroups": [
            { "id": 12, "name": " Server Operators ", "type": 1 },
            { "id": 13, "name": " Server Guests ", "type": 1 }
          ],
          "channelGroups": [
            { "id": 12, "name": " Channel Voice ", "type": 1 },
            { "id": 14, "name": " Channel Admin ", "type": 1 }
          ]
        }
        """

        try model.importGroupArchive(
            from: Data(archiveJSON.utf8),
            selectedGroupIds: ["server:13", "channel:12"]
        )

        XCTAssertEqual(model.serverGroups.map(\.id), [13])
        XCTAssertEqual(model.serverGroups.first?.name, "Server Guests")
        XCTAssertEqual(model.channelGroups.map(\.id), [12])
        XCTAssertEqual(model.channelGroups.first?.name, "Channel Voice")
        XCTAssertEqual(model.lastError, nil)
    }
}
