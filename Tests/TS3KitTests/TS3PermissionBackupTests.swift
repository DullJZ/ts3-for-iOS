import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3PermissionBackupTests: XCTestCase {
    func testPermissionInfoSummaryCopyAndAccessibilityText() {
        let permission = TS3PermissionInfoSummary(info: TS3PermissionInfo(
            id: 101,
            name: "i_channel_join_power",
            description: "Join power"
        ))

        XCTAssertEqual(
            permission.clipboardSummary,
            "permissionId=101 | name=i_channel_join_power | description=Join power"
        )
        XCTAssertEqual(
            permission.accessibilityValue,
            "Permission ID 101. Join power"
        )
    }

    func testPermissionInfoSummaryOmitsEmptyDescription() {
        let permission = TS3PermissionInfoSummary(info: TS3PermissionInfo(
            id: 102,
            name: "b_channel_join_permanent",
            description: nil
        ))

        XCTAssertEqual(permission.clipboardSummary, "permissionId=102 | name=b_channel_join_permanent")
        XCTAssertEqual(permission.accessibilityValue, "Permission ID 102")
    }

    func testPermissionSummaryCopyAndAccessibilityText() {
        let permission = makePermission("i_client_kick_power", value: 75, isNegated: true, isSkipped: true)

        XCTAssertEqual(
            permission.clipboardSummary,
            "name=i_client_kick_power value=75 status=Negated+Skips inherited negated=true skip=true effect=Negates earlier grants and blocks lower inherited permissions."
        )
        XCTAssertEqual(
            permission.accessibilityValue,
            "Value 75. Negated, Skips inherited. Negates earlier grants and blocks lower inherited permissions."
        )
    }

    func testPermissionSummaryDirectAccessibilityText() {
        let permission = makePermission("i_channel_join_power", value: 50)

        XCTAssertEqual(
            permission.accessibilityValue,
            "Value 50. Direct. Direct value; inherited permissions may still apply around this entry."
        )
    }

    @MainActor
    func testPermissionBackupPreviewListsOverwriteAndNewPermissionNames() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .serverGroup
        source.selectedServerGroupPermissionId = 6
        source.scopedPermissions = [
            makePermission("i_channel_join_power", value: 50),
            makePermission("i_client_kick_power", value: 75),
            makePermission("b_virtualserver_modify_name", value: 1)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        target.scopedPermissions = [
            makePermission("i_channel_join_power", value: 25),
            makePermission("i_client_ban_power", value: 60)
        ]

        let preview = try target.permissionBackupPreview(from: backup)

        XCTAssertTrue(preview.targetMatchesCurrentSelection)
        XCTAssertEqual(preview.currentPermissionCount, 2)
        XCTAssertEqual(preview.overwriteCount, 1)
        XCTAssertEqual(preview.changedCount, 1)
        XCTAssertEqual(preview.unchangedCount, 0)
        XCTAssertEqual(preview.newPermissionCount, 2)
        XCTAssertEqual(preview.overwritePermissionNames, ["i_channel_join_power"])
        XCTAssertEqual(preview.changedPermissionNames, ["i_channel_join_power"])
        XCTAssertEqual(preview.changedPermissionDetails, ["i_channel_join_power: value 25 -> 50"])
        XCTAssertTrue(preview.unchangedPermissionNames.isEmpty)
        XCTAssertEqual(preview.newPermissionNames, ["b_virtualserver_modify_name", "i_client_kick_power"])
    }

    @MainActor
    func testPermissionBackupPreviewSeparatesUnchangedExistingPermissions() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .serverGroup
        source.selectedServerGroupPermissionId = 6
        source.scopedPermissions = [
            makePermission("i_channel_join_power", value: 50),
            makePermission("i_client_kick_power", value: 75, isSkipped: true)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        target.scopedPermissions = [
            makePermission("i_channel_join_power", value: 50),
            makePermission("i_client_kick_power", value: 70, isSkipped: true)
        ]

        let preview = try target.permissionBackupPreview(from: backup)

        XCTAssertEqual(preview.overwriteCount, 2)
        XCTAssertEqual(preview.changedCount, 1)
        XCTAssertEqual(preview.unchangedCount, 1)
        XCTAssertEqual(preview.changedPermissionNames, ["i_client_kick_power"])
        XCTAssertEqual(preview.unchangedPermissionNames, ["i_channel_join_power"])
        XCTAssertEqual(preview.changedPermissionDetails, ["i_client_kick_power: value 70 -> 75"])
    }

    @MainActor
    func testPermissionBackupPreviewListsFlagChangeDetails() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .serverGroup
        source.selectedServerGroupPermissionId = 6
        source.scopedPermissions = [
            makePermission("i_client_ban_power", value: 60, isNegated: true, isSkipped: true)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        target.scopedPermissions = [
            makePermission("i_client_ban_power", value: 40)
        ]

        let preview = try target.permissionBackupPreview(from: backup)

        XCTAssertEqual(preview.changedPermissionNames, ["i_client_ban_power"])
        XCTAssertEqual(
            preview.changedPermissionDetails,
            ["i_client_ban_power: value 40 -> 60, negated off -> on, skip off -> on"]
        )
    }

    @MainActor
    func testPermissionBackupPreviewOmitsConflictNamesWhenTargetIsNotLoaded() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .channel
        source.selectedChannelPermissionId = 9
        source.scopedPermissions = [
            makePermission("i_channel_needed_join_power", value: 30)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .channel
        target.selectedChannelPermissionId = 10

        let preview = try target.permissionBackupPreview(from: backup)

        XCTAssertFalse(preview.targetMatchesCurrentSelection)
        XCTAssertNil(preview.overwriteCount)
        XCTAssertNil(preview.changedCount)
        XCTAssertNil(preview.unchangedCount)
        XCTAssertNil(preview.newPermissionCount)
        XCTAssertTrue(preview.overwritePermissionNames.isEmpty)
        XCTAssertTrue(preview.changedPermissionNames.isEmpty)
        XCTAssertTrue(preview.changedPermissionDetails.isEmpty)
        XCTAssertTrue(preview.unchangedPermissionNames.isEmpty)
        XCTAssertTrue(preview.newPermissionNames.isEmpty)
    }

    @MainActor
    func testPermissionBackupRestorePlanCanSelectOnlyChangedPermissions() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .serverGroup
        source.selectedServerGroupPermissionId = 6
        source.scopedPermissions = [
            makePermission("i_channel_join_power", value: 50),
            makePermission("i_client_kick_power", value: 75),
            makePermission("b_virtualserver_modify_name", value: 1)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        target.scopedPermissions = [
            makePermission("i_channel_join_power", value: 25),
            makePermission("i_client_kick_power", value: 75)
        ]

        let plan = try target.permissionBackupRestorePlan(
            from: backup,
            options: TS3PermissionBackupRestoreOptions(
                changedExisting: true,
                newPermissions: false,
                restoreWhenTargetCannotBeCompared: true
            )
        )

        XCTAssertEqual(plan.permissionNames, ["i_channel_join_power"])
        XCTAssertEqual(plan.permissionCount, 1)
        XCTAssertEqual(
            plan.entries,
            [
                TS3PermissionBackupRestoreEntry(
                    name: "i_channel_join_power",
                    value: 50,
                    isNegated: false,
                    isSkipped: false,
                    restoreReason: "changed existing",
                    changeSummary: "value 25 -> 50"
                )
            ]
        )
    }

    @MainActor
    func testPermissionBackupRestorePlanCanSelectOnlyNewPermissions() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .serverGroup
        source.selectedServerGroupPermissionId = 6
        source.scopedPermissions = [
            makePermission("i_channel_join_power", value: 50),
            makePermission("i_client_kick_power", value: 75)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        target.scopedPermissions = [
            makePermission("i_channel_join_power", value: 25)
        ]

        let plan = try target.permissionBackupRestorePlan(
            from: backup,
            options: TS3PermissionBackupRestoreOptions(
                changedExisting: false,
                newPermissions: true,
                restoreWhenTargetCannotBeCompared: true
            )
        )

        XCTAssertEqual(plan.permissionNames, ["i_client_kick_power"])
        XCTAssertEqual(plan.entries.first?.restoreReason, "new permission")
        XCTAssertNil(plan.entries.first?.changeSummary)
    }

    @MainActor
    func testPermissionBackupRestorePlanCanSkipUncomparableTarget() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .channel
        source.selectedChannelPermissionId = 9
        source.scopedPermissions = [
            makePermission("i_channel_needed_join_power", value: 30)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .channel
        target.selectedChannelPermissionId = 10

        let plan = try target.permissionBackupRestorePlan(
            from: backup,
            options: TS3PermissionBackupRestoreOptions(
                changedExisting: true,
                newPermissions: true,
                restoreWhenTargetCannotBeCompared: false
            )
        )

        XCTAssertTrue(plan.permissionNames.isEmpty)
        XCTAssertEqual(plan.permissionCount, 0)
    }

    @MainActor
    func testPermissionBackupRestorePlanLabelsUncomparableEntries() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .channel
        source.selectedChannelPermissionId = 9
        source.scopedPermissions = [
            makePermission("i_channel_needed_join_power", value: 30)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .channel
        target.selectedChannelPermissionId = 10

        let plan = try target.permissionBackupRestorePlan(
            from: backup,
            options: TS3PermissionBackupRestoreOptions(
                changedExisting: true,
                newPermissions: true,
                restoreWhenTargetCannotBeCompared: true
            )
        )

        XCTAssertEqual(plan.permissionNames, ["i_channel_needed_join_power"])
        XCTAssertEqual(plan.entries.first?.restoreReason, "not comparable")
        XCTAssertNil(plan.entries.first?.changeSummary)
        XCTAssertTrue(plan.auditSummary.contains("reason=not comparable"))
    }

    @MainActor
    func testPermissionBackupRestorePlanIncludesAuditableClipboardSummary() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .serverGroup
        source.selectedServerGroupPermissionId = 6
        source.scopedPermissions = [
            makePermission("i_channel_join_power", value: 50),
            makePermission("i_client_kick_power", value: 75, isNegated: true, isSkipped: true)
        ]

        let backup = try source.permissionBackupData()

        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        target.scopedPermissions = [
            makePermission("i_channel_join_power", value: 25)
        ]

        let plan = try target.permissionBackupRestorePlan(
            from: backup,
            options: .all
        )

        XCTAssertEqual(
            plan.clipboardSummary,
            """
            Target: Server Group - Group 6
            Target comparison: Matched current selection
            Restore changed existing: Yes
            Restore new permissions: Yes
            Restore without comparison: Yes
            Selected restore entries: 2
            Changed existing available: 1
            New permissions available: 1
            Unchanged skipped: 0

            name=i_channel_join_power value=50 negated=false skip=false reason=changed existing change=value 25 -> 50
            name=i_client_kick_power value=75 negated=true skip=true reason=new permission
            """
        )
        XCTAssertEqual(plan.auditSummary, plan.clipboardSummary)
    }

    @MainActor
    func testPermissionBackupExportSanitizesBlankAndDuplicatePermissionNames() throws {
        let source = TS3AppModel()
        source.permissionEditScope = .serverGroup
        source.selectedServerGroupPermissionId = 6
        source.scopedPermissions = [
            makePermission(" i_channel_join_power ", value: 25),
            makePermission("i_channel_join_power", value: 50, isNegated: true),
            makePermission("   ", value: 99),
            makePermission("i_client_kick_power", value: 75, isSkipped: true)
        ]

        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        let preview = try target.permissionBackupPreview(from: try source.permissionBackupData())

        XCTAssertEqual(preview.permissionCount, 2)
        XCTAssertEqual(preview.newPermissionNames, ["i_channel_join_power", "i_client_kick_power"])

        let plan = try target.permissionBackupRestorePlan(
            from: try source.permissionBackupData(),
            options: .all
        )

        XCTAssertEqual(
            plan.entries,
            [
                TS3PermissionBackupRestoreEntry(
                    name: "i_channel_join_power",
                    value: 50,
                    isNegated: true,
                    isSkipped: false,
                    restoreReason: "new permission"
                ),
                TS3PermissionBackupRestoreEntry(
                    name: "i_client_kick_power",
                    value: 75,
                    isNegated: false,
                    isSkipped: true,
                    restoreReason: "new permission"
                )
            ]
        )
    }

    @MainActor
    func testPermissionBackupPreviewAndRestorePlanSanitizeLegacyDuplicatePermissions() throws {
        let target = TS3AppModel()
        target.permissionEditScope = .serverGroup
        target.selectedServerGroupPermissionId = 6
        target.scopedPermissions = [
            makePermission("i_channel_join_power", value: 10)
        ]
        let backupJSON = """
        {
          "scope": "serverGroup",
          "selectedServerGroupPermissionId": 6,
          "permissions": [
            { "name": " i_channel_join_power ", "value": 25, "isNegated": false, "isSkipped": false },
            { "name": "i_channel_join_power", "value": 50, "isNegated": true, "isSkipped": false },
            { "name": "   ", "value": 99, "isNegated": false, "isSkipped": false },
            { "name": "i_client_kick_power", "value": 75, "isNegated": false, "isSkipped": true }
          ]
        }
        """
        let data = Data(backupJSON.utf8)

        let preview = try target.permissionBackupPreview(from: data)

        XCTAssertEqual(preview.permissionCount, 2)
        XCTAssertEqual(preview.changedPermissionNames, ["i_channel_join_power"])
        XCTAssertEqual(
            preview.changedPermissionDetails,
            ["i_channel_join_power: value 10 -> 50, negated off -> on"]
        )
        XCTAssertEqual(preview.newPermissionNames, ["i_client_kick_power"])

        let plan = try target.permissionBackupRestorePlan(from: data, options: .all)

        XCTAssertEqual(
            plan.clipboardSummary,
            """
            Target: Server Group - Group 6
            Target comparison: Matched current selection
            Restore changed existing: Yes
            Restore new permissions: Yes
            Restore without comparison: Yes
            Selected restore entries: 2
            Changed existing available: 1
            New permissions available: 1
            Unchanged skipped: 0

            name=i_channel_join_power value=50 negated=true skip=false reason=changed existing change=value 10 -> 50, negated off -> on
            name=i_client_kick_power value=75 negated=false skip=true reason=new permission
            """
        )
    }

    private func makePermission(
        _ name: String,
        value: Int,
        isNegated: Bool = false,
        isSkipped: Bool = false
    ) -> TS3PermissionSummary {
        TS3PermissionSummary(permission: TS3Permission(
            name: name,
            value: value,
            isNegated: isNegated,
            isSkipped: isSkipped
        ))
    }
}
