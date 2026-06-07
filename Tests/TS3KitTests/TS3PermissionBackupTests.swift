import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3PermissionBackupTests: XCTestCase {
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
        XCTAssertEqual(preview.newPermissionCount, 2)
        XCTAssertEqual(preview.overwritePermissionNames, ["i_channel_join_power"])
        XCTAssertEqual(preview.newPermissionNames, ["b_virtualserver_modify_name", "i_client_kick_power"])
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
        XCTAssertNil(preview.newPermissionCount)
        XCTAssertTrue(preview.overwritePermissionNames.isEmpty)
        XCTAssertTrue(preview.newPermissionNames.isEmpty)
    }

    private func makePermission(_ name: String, value: Int) -> TS3PermissionSummary {
        TS3PermissionSummary(permission: TS3Permission(
            name: name,
            value: value,
            isNegated: false,
            isSkipped: false
        ))
    }
}
