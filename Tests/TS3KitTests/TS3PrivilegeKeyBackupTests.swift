import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3PrivilegeKeyBackupTests: XCTestCase {
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
        XCTAssertEqual(preview.clipboardSummary, preview.keySummaries.joined(separator: "\n"))
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
        XCTAssertEqual(
            preview.keySummaries,
            [
                "key=first-key | type=Server Group | group=6",
                "key=second-key | type=Channel Group | group=8"
            ]
        )
        XCTAssertEqual(model.generatedPrivilegeKey, "first-key")
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
