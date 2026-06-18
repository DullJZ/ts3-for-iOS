import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3PrivilegeKeyBackupTests: XCTestCase {
    func testPrivilegeKeyDraftValidatorRejectsMissingTargetsAndMultilineFields() {
        XCTAssertEqual(
            TS3PrivilegeKeyDraftValidator.validationMessages(
                targetType: .channelGroup,
                groupId: 0,
                channelId: nil,
                description: "Line one\nLine two",
                customSet: "token=one\ntoken=two"
            ),
            [
                "Channel group is required before creating a privilege key.",
                "Channel is required before creating a channel-group privilege key.",
                "Description must be a single line.",
                "Custom set must be a single line."
            ]
        )
    }

    func testPrivilegeKeyDraftValidatorAcceptsValidServerGroupDraftAndBuildsSummary() {
        let messages = TS3PrivilegeKeyDraftValidator.validationMessages(
            targetType: .serverGroup,
            groupId: 6,
            channelId: nil,
            description: "  One time admin  ",
            customSet: "  ident=ios  "
        )
        let summary = TS3PrivilegeKeyDraftValidator.creationSummary(
            targetType: .serverGroup,
            groupId: 6,
            groupName: "Admins",
            channelId: nil,
            channelName: nil,
            description: "  One time admin  ",
            customSet: "  ident=ios  "
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(
            summary,
            "type=Server Group | group=Admins (6) | description=One time admin | customSet=ident=ios"
        )
    }

    func testPrivilegeKeyDraftValidatorIncludesChannelGroupTargetInSummary() {
        let summary = TS3PrivilegeKeyDraftValidator.creationSummary(
            targetType: .channelGroup,
            groupId: 9,
            groupName: "Channel Admin",
            channelId: 12,
            channelName: "Lobby",
            description: "",
            customSet: ""
        )

        XCTAssertEqual(
            summary,
            "type=Channel Group | group=Channel Admin (9) | channel=Lobby (12)"
        )
    }

    func testPrivilegeKeyDraftCoverageSummaryCountsServerGroupOptionalFields() {
        let validationMessages = TS3PrivilegeKeyDraftValidator.validationMessages(
            targetType: .serverGroup,
            groupId: 6,
            channelId: nil,
            description: " One time admin ",
            customSet: " ident=ios "
        )
        let summary = TS3PrivilegeKeyDraftCoverageSummary(
            targetType: .serverGroup,
            groupId: 6,
            channelId: nil,
            description: " One time admin ",
            customSet: " ident=ios ",
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.coveredTargetFieldCount, 1)
        XCTAssertEqual(summary.requiredTargetFieldCount, 1)
        XCTAssertFalse(summary.requiresChannel)
        XCTAssertTrue(summary.hasGroup)
        XCTAssertFalse(summary.hasChannel)
        XCTAssertTrue(summary.hasDescription)
        XCTAssertTrue(summary.hasCustomSet)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "type=serverGroup | targetFields=1/1 | group=true | channelRequired=false | channel=false | description=true | customSet=true | validationIssues=0 | needsAttention=false"
        )
    }

    func testPrivilegeKeyDraftCoverageSummaryFlagsMissingChannelGroupTarget() {
        let validationMessages = TS3PrivilegeKeyDraftValidator.validationMessages(
            targetType: .channelGroup,
            groupId: 0,
            channelId: nil,
            description: "Line one\nLine two",
            customSet: ""
        )
        let summary = TS3PrivilegeKeyDraftCoverageSummary(
            targetType: .channelGroup,
            groupId: 0,
            channelId: nil,
            description: "Line one\nLine two",
            customSet: "",
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.coveredTargetFieldCount, 0)
        XCTAssertEqual(summary.requiredTargetFieldCount, 2)
        XCTAssertTrue(summary.requiresChannel)
        XCTAssertFalse(summary.hasGroup)
        XCTAssertFalse(summary.hasChannel)
        XCTAssertTrue(summary.hasDescription)
        XCTAssertFalse(summary.hasCustomSet)
        XCTAssertEqual(summary.validationIssueCount, 3)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "type=channelGroup | targetFields=0/2 | group=false | channelRequired=true | channel=false | description=true | customSet=false | validationIssues=3 | needsAttention=true"
        )
    }

    @MainActor
    func testPrivilegeKeyBackupPreviewCountsTypesAndFirstKeyDetails() throws {
        let model = TS3AppModel()
        model.serverGroups = [
            TS3GroupSummary(id: 6, name: "Admins", type: .regular)
        ]
        model.channelGroups = [
            TS3GroupSummary(id: 9, name: "Channel Admin", type: .regular)
        ]
        model.privilegeKeys = [
            makeKey(
                key: "server-key",
                type: .serverGroup,
                groupId: 6,
                channelId: nil,
                description: "admins"
            ),
            makeKey(
                key: "channel-key",
                type: .channelGroup,
                groupId: 9,
                channelId: 12,
                customSet: "token_custom"
            ),
            makeKey(key: "unknown-key", type: nil, groupId: 99, channelId: nil)
        ]

        let preview = try model.privilegeKeyBackupPreview(from: model.privilegeKeyBackupData())

        XCTAssertEqual(preview.keyCount, 3)
        XCTAssertEqual(preview.serverGroupCount, 1)
        XCTAssertEqual(preview.channelGroupCount, 1)
        XCTAssertEqual(preview.unknownTypeCount, 1)
        XCTAssertEqual(preview.typeSummaries, [
            "type=Channel Group count=1",
            "type=Server Group count=1",
            "type=Unknown count=1"
        ])
        XCTAssertEqual(preview.targetSummaries, [
            "target=Channel Group group=9 channel=12 count=1",
            "target=Server Group group=6 count=1",
            "target=Unknown group=99 count=1"
        ])
        XCTAssertEqual(preview.firstKey, "server-key")
        XCTAssertEqual(preview.firstType, .serverGroup)
        XCTAssertEqual(preview.firstGroupId, 6)
        XCTAssertEqual(preview.firstDescription, "admins")
        XCTAssertEqual(
            preview.keySummaries,
            [
                "key=server-key | type=Server Group | group=6 | description=admins",
                "key=channel-key | type=Channel Group | group=9 | channel=12 | customSet=token_custom",
                "key=unknown-key | type=Unknown | group=99"
            ]
        )
        XCTAssertEqual(
            preview.clipboardSummary,
            (preview.typeSummaries + preview.targetSummaries + preview.keySummaries).joined(separator: "\n")
        )
    }

    @MainActor
    func testPrivilegeKeyBackupImportUsesFirstUsableUniqueKey() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            { "key": "   ", "type": 0, "groupId": 6 },
            { "key": " first-key ", "type": 0, "groupId": 6 },
            { "key": "first-key", "type": 1, "groupId": 7 },
            { "key": "second-key", "type": 1, "groupId": 8 }
          ]
        }
        """

        let data = Data(backupJSON.utf8)
        let preview = try model.privilegeKeyBackupPreview(from: data)
        try model.importPrivilegeKeyBackup(from: data)

        XCTAssertEqual(preview.keyCount, 2)
        XCTAssertEqual(preview.typeSummaries, [
            "type=Channel Group count=1",
            "type=Server Group count=1"
        ])
        XCTAssertEqual(
            preview.keySummaries,
            [
                "key=first-key | type=Server Group | group=6",
                "key=second-key | type=Channel Group | group=8"
            ]
        )
        XCTAssertEqual(preview.candidates.map(\.key), ["first-key", "second-key"])
        XCTAssertEqual(preview.candidates.first?.type, .serverGroup)
        XCTAssertEqual(preview.candidates.first?.groupId, 6)
        XCTAssertNil(preview.candidates.first?.channelId)
        XCTAssertTrue(preview.containsKey("second-key"))
        XCTAssertFalse(preview.containsKey("missing-key"))
        XCTAssertEqual(model.generatedPrivilegeKey, "first-key")

        try model.importPrivilegeKeyBackup(from: data, selectedKey: "second-key")
        XCTAssertEqual(model.generatedPrivilegeKey, "second-key")

        try model.importPrivilegeKeyBackup(from: data, selectedKey: "missing-key")
        XCTAssertEqual(model.generatedPrivilegeKey, "first-key")
    }

    @MainActor
    func testPrivilegeKeyImportImpactSummaryCountsSelectedCandidateRisk() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            {
              "key": "channel-any-key",
              "type": 1,
              "groupId": 8,
              "description": "Channel admin",
              "customSet": "token_custom"
            }
          ]
        }
        """

        let preview = try model.privilegeKeyBackupPreview(from: Data(backupJSON.utf8))
        let candidate = try XCTUnwrap(preview.candidates.first)
        let impact = TS3PrivilegeKeyImportImpactSummary(candidate: candidate)

        XCTAssertEqual(impact.key, "channel-any-key")
        XCTAssertEqual(impact.type, .channelGroup)
        XCTAssertEqual(impact.groupId, 8)
        XCTAssertNil(impact.channelId)
        XCTAssertTrue(impact.isKnownType)
        XCTAssertFalse(impact.isChannelScoped)
        XCTAssertTrue(impact.isAnyChannelGroupKey)
        XCTAssertTrue(impact.hasDescription)
        XCTAssertTrue(impact.hasCustomSet)
        XCTAssertTrue(impact.needsAttention)
        XCTAssertEqual(
            impact.clipboardSummary,
            "key=channel-any-key | type=Channel Group | groupId=8 | channelId=none | channelScoped=false | anyChannelGroupKey=true | description=true | customSet=true | needsAttention=true"
        )
    }

    @MainActor
    func testPrivilegeKeyBackupExportSanitizesCachedKeys() throws {
        let model = TS3AppModel()
        model.privilegeKeys = [
            makeKey(
                key: " first-key ",
                type: .serverGroup,
                groupId: 6,
                channelId: nil,
                description: " admins ",
                customSet: " "
            ),
            makeKey(
                key: "first-key",
                type: .channelGroup,
                groupId: 7,
                channelId: 12
            ),
            makeKey(
                key: " second-key ",
                type: .channelGroup,
                groupId: 8,
                channelId: 13,
                description: " ",
                customSet: " token_custom "
            ),
            makeKey(
                key: "   ",
                type: .serverGroup,
                groupId: 9,
                channelId: nil
            )
        ]

        let preview = try model.privilegeKeyBackupPreview(from: model.privilegeKeyBackupData())

        XCTAssertEqual(preview.keyCount, 2)
        XCTAssertEqual(
            preview.keySummaries,
            [
                "key=first-key | type=Server Group | group=6 | description=admins",
                "key=second-key | type=Channel Group | group=8 | channel=13 | customSet=token_custom"
            ]
        )
    }

    func testPrivilegeKeySummariesResolveTargetsForCopyAndAccessibility() {
        let key = makeKey(
            key: "channel-key",
            type: .channelGroup,
            groupId: 9,
            channelId: 12,
            description: "Channel admin",
            customSet: "token_custom"
        )
        let serverGroups = [
            TS3GroupSummary(id: 6, name: "Admins", type: .regular)
        ]
        let channelGroups = [
            TS3GroupSummary(id: 9, name: "Channel Admin", type: .regular)
        ]
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

        XCTAssertEqual(
            key.targetSummary(
                serverGroups: serverGroups,
                channelGroups: channelGroups,
                channels: channels
            ),
            "Channel Group: Channel Admin in Lobby"
        )
        XCTAssertEqual(
            key.clipboardSummary(
                serverGroups: serverGroups,
                channelGroups: channelGroups,
                channels: channels
            ),
            "key=channel-key | type=Channel Group (1) | group=Channel Admin (9) | channel=Lobby (12) | createdAt=\(Self.dateText(Date(timeIntervalSince1970: 1_700_000_000))) | description=Channel admin | customSet=token_custom"
        )
        XCTAssertEqual(
            key.accessibilityValue(
                serverGroups: serverGroups,
                channelGroups: channelGroups,
                channels: channels
            ),
            "Channel Group: Channel Admin in Lobby. Channel Lobby, ID 12. Created \(Self.dateText(Date(timeIntervalSince1970: 1_700_000_000))). Description Channel admin. Custom set token_custom"
        )
    }

    func testPrivilegeKeyListSummaryDeduplicatesAndCountsVisibleKeys() {
        let serverKey = makeKey(
            key: "server-key",
            type: .serverGroup,
            groupId: 6,
            channelId: nil,
            description: "admins"
        )
        let channelKey = makeKey(
            key: "channel-key",
            type: .channelGroup,
            groupId: 9,
            channelId: 12,
            customSet: "token_custom"
        )
        let unknownKey = makeKey(key: "unknown-key", type: nil, groupId: 99, channelId: nil)
        let duplicate = makeKey(
            key: "server-key",
            type: .channelGroup,
            groupId: 10,
            channelId: 13,
            customSet: "ignored"
        )

        let summary = TS3PrivilegeKeyListSummary(keys: [serverKey, channelKey, unknownKey, duplicate])

        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.serverGroupCount, 1)
        XCTAssertEqual(summary.channelGroupCount, 1)
        XCTAssertEqual(summary.unknownTypeCount, 1)
        XCTAssertEqual(summary.describedCount, 1)
        XCTAssertEqual(summary.customSetCount, 1)
        XCTAssertEqual(summary.channelScopedCount, 1)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "keys=3 | serverGroup=1 | channelGroup=1 | unknown=1 | withDescription=1 | withCustomSet=1 | channelScoped=1 | latestCreated=2023-11-14T22:13:20Z | needsAttention=true"
        )
    }

    func testPrivilegeKeyDeleteImpactSummaryCountsVisibleDeletionRisk() {
        let serverKey = makeKey(
            key: "server-key",
            type: .serverGroup,
            groupId: 6,
            channelId: nil,
            description: "admins"
        )
        let channelKey = makeKey(
            key: "channel-key",
            type: .channelGroup,
            groupId: 9,
            channelId: 12,
            customSet: "token_custom"
        )
        let unknownKey = makeKey(key: "unknown-key", type: nil, groupId: 99, channelId: nil)
        let duplicate = makeKey(
            key: "server-key",
            type: .channelGroup,
            groupId: 10,
            channelId: 13,
            customSet: "ignored"
        )

        let summary = TS3PrivilegeKeyDeleteImpactSummary(
            keys: [serverKey, channelKey, unknownKey, duplicate],
            scope: .visible
        )

        XCTAssertEqual(summary.keyCount, 3)
        XCTAssertEqual(summary.listSummary.serverGroupCount, 1)
        XCTAssertEqual(summary.listSummary.channelGroupCount, 1)
        XCTAssertEqual(summary.listSummary.unknownTypeCount, 1)
        XCTAssertEqual(summary.listSummary.channelScopedCount, 1)
        XCTAssertEqual(summary.listSummary.describedCount, 1)
        XCTAssertEqual(summary.listSummary.customSetCount, 1)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=visible | deleteKeys=3 | serverGroup=1 | channelGroup=1 | unknown=1 | channelScoped=1 | withDescription=1 | withCustomSet=1 | latestCreated=2023-11-14T22:13:20Z | needsAttention=true"
        )
    }

    func testPrivilegeKeyDeleteImpactSummaryFlagsEmptyAndLargeDeletion() {
        let empty = TS3PrivilegeKeyDeleteImpactSummary(keys: [], scope: .visible)

        XCTAssertEqual(empty.keyCount, 0)
        XCTAssertTrue(empty.needsAttention)
        XCTAssertEqual(
            empty.clipboardSummary,
            "scope=visible | deleteKeys=0 | serverGroup=0 | channelGroup=0 | unknown=0 | channelScoped=0 | withDescription=0 | withCustomSet=0 | latestCreated=none | needsAttention=true"
        )

        let largeDeletion = TS3PrivilegeKeyDeleteImpactSummary(
            keys: (1...10).map { index in
                makeKey(
                    key: "server-key-\(index)",
                    type: .serverGroup,
                    groupId: index,
                    channelId: nil
                )
            },
            scope: .visible
        )

        XCTAssertEqual(largeDeletion.keyCount, 10)
        XCTAssertEqual(largeDeletion.listSummary.unknownTypeCount, 0)
        XCTAssertEqual(largeDeletion.listSummary.customSetCount, 0)
        XCTAssertEqual(largeDeletion.listSummary.channelScopedCount, 0)
        XCTAssertTrue(largeDeletion.needsAttention)
    }

    func testPrivilegeKeyOfficialCoverageAuditSummaryCountsCoveredAreas() {
        let draftSummary = TS3PrivilegeKeyDraftCoverageSummary(
            targetType: .channelGroup,
            groupId: 9,
            channelId: 12,
            description: "Channel admin",
            customSet: "token_custom",
            validationMessages: []
        )
        let listSummary = TS3PrivilegeKeyListSummary(keys: [
            makeKey(key: "server-key", type: .serverGroup, groupId: 6, channelId: nil, description: "admins"),
            makeKey(key: "channel-key", type: .channelGroup, groupId: 9, channelId: 12, customSet: "token_custom")
        ])

        let summary = TS3PrivilegeKeyOfficialCoverageAuditSummary(
            draftCoverageSummary: draftSummary,
            visibleKeySummary: listSummary,
            hasGeneratedKey: true,
            hasLocalFilters: true,
            hasFilterPresets: true,
            hasBackupCoverage: true,
            canMutateServer: true,
            canDeleteVisible: true,
            hasInviteLinkActions: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 8)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 8)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 19)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=8/8 | missingOfficialAreas=0 | officialActions=19 | draftTargets=2/2 | draftType=channelGroup | generatedKey=true | visibleKeys=2 | serverGroup=1 | channelGroup=1 | unknown=0 | channelScoped=1 | localFilters=true | filterPresets=true | backupCoverage=true | serverMutation=true | deleteVisible=true | inviteLinkActions=true | needsAttention=true"
        )
    }

    func testPrivilegeKeyOfficialCoverageAuditSummaryFlagsMissingWorkflowAreas() {
        let draftSummary = TS3PrivilegeKeyDraftCoverageSummary(
            targetType: .channelGroup,
            groupId: 0,
            channelId: nil,
            description: "",
            customSet: "",
            validationMessages: TS3PrivilegeKeyDraftValidator.validationMessages(
                targetType: .channelGroup,
                groupId: 0,
                channelId: nil,
                description: "",
                customSet: ""
            )
        )

        let summary = TS3PrivilegeKeyOfficialCoverageAuditSummary(
            draftCoverageSummary: draftSummary,
            visibleKeySummary: TS3PrivilegeKeyListSummary(keys: []),
            hasGeneratedKey: false,
            hasLocalFilters: false,
            hasFilterPresets: false,
            hasBackupCoverage: false,
            canMutateServer: false,
            canDeleteVisible: false,
            hasInviteLinkActions: false
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 0)
        XCTAssertEqual(summary.missingOfficialAreaCount, 8)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=0/8 | missingOfficialAreas=8 | officialActions=19 | draftTargets=0/2 | draftType=channelGroup | generatedKey=false | visibleKeys=0 | serverGroup=0 | channelGroup=0 | unknown=0 | channelScoped=0 | localFilters=false | filterPresets=false | backupCoverage=false | serverMutation=false | deleteVisible=false | inviteLinkActions=false | needsAttention=true"
        )
    }

    func testPrivilegeKeyConnectionImpactSummaryDescribesReplacementAndInviteLinkImpact() {
        let snapshot = TS3ConnectionSnapshot(
            host: "voice.example.test",
            port: "9987",
            nickname: "Avery",
            serverPassword: "secret",
            defaultChannel: "Ops/Lobby",
            defaultChannelPassword: "channel-secret",
            privilegeKey: "old-key"
        )

        let summary = TS3PrivilegeKeyConnectionImpactSummary(
            key: "  new-key  ",
            source: .generated,
            snapshot: snapshot
        )

        XCTAssertEqual(summary.key, "new-key")
        XCTAssertEqual(summary.source, .generated)
        XCTAssertTrue(summary.hasUsableKey)
        XCTAssertTrue(summary.hasServerTarget)
        XCTAssertTrue(summary.hasServerPassword)
        XCTAssertTrue(summary.hasChannelPassword)
        XCTAssertTrue(summary.isReplacingExistingKey)
        XCTAssertEqual(summary.inviteLinkImpact, "privilegeKey=Configured")
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "key=Configured | source=generated | server=voice.example.test:9987 | nickname=Avery | defaultChannel=Ops/Lobby | serverPassword=Configured | channelPassword=Configured | replacesExistingKey=true | inviteLinkImpact=privilegeKey=Configured | needsAttention=false"
        )
    }

    func testPrivilegeKeyConnectionImpactSummaryFlagsMissingServerTarget() {
        let snapshot = TS3ConnectionSnapshot(
            host: " ",
            port: "",
            nickname: "",
            serverPassword: "",
            defaultChannel: "",
            defaultChannelPassword: "",
            privilegeKey: ""
        )

        let summary = TS3PrivilegeKeyConnectionImpactSummary(
            key: "listed-key",
            source: .listed,
            snapshot: snapshot
        )

        XCTAssertTrue(summary.hasUsableKey)
        XCTAssertFalse(summary.hasServerTarget)
        XCTAssertFalse(summary.isReplacingExistingKey)
        XCTAssertEqual(summary.inviteLinkImpact, "unavailable")
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "key=Configured | source=listed | server=Not set:9987 | nickname=Not set | defaultChannel=None | serverPassword=No | channelPassword=No | replacesExistingKey=false | inviteLinkImpact=unavailable | needsAttention=true"
        )
    }

    @MainActor
    func testSaveCurrentConnectionPrivilegeKeyTrimsAndIgnoresEmptyValues() {
        let model = TS3AppModel()
        model.privilegeKey = "existing-key"

        model.saveCurrentConnectionPrivilegeKey("  saved-key  ")

        XCTAssertEqual(model.privilegeKey, "saved-key")
        XCTAssertNil(model.lastError)

        model.saveCurrentConnectionPrivilegeKey("   ")

        XCTAssertEqual(model.privilegeKey, "saved-key")
    }

    private func makeKey(
        key: String,
        type: TS3PrivilegeKeyType?,
        groupId: Int,
        channelId: Int?,
        description: String? = nil,
        customSet: String? = nil
    ) -> TS3PrivilegeKeySummary {
        TS3PrivilegeKeySummary(entry: TS3PrivilegeKeyEntry(
            key: key,
            type: type,
            groupId: groupId,
            channelId: channelId,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            description: description,
            customSet: customSet
        ))
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
