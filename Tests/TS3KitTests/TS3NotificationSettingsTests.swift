import XCTest
@testable import TS3iOSApp

final class TS3NotificationSettingsTests: XCTestCase {
    @MainActor
    func testNotificationSettingsPreviewSanitizesImportedRulesAndQuietHours() throws {
        let model = TS3AppModel()
        let data = Data("""
        {
          "isEnabled": true,
          "soundEnabled": false,
          "privateMessagesEnabled": false,
          "pokesEnabled": true,
          "activityEnabled": true,
          "mutedServerKeys": [" alpha ", "", "alpha", "beta"],
          "mutedContactUniqueIdentifiers": ["", " user-1 ", "user-1"],
          "quietHoursEnabled": true,
          "quietHoursStartMinute": -25,
          "quietHoursEndMinute": 1888
        }
        """.utf8)

        let preview = try model.notificationSettingsPreview(from: data)

        XCTAssertEqual(preview.lines, [
            "Notifications: Enabled",
            "Notification sounds: Off",
            "Notification event types: pokes, activity",
            "Quiet hours: 00:00-23:59",
            "Muted notification servers: 2",
            "Muted notification contacts: 1"
        ])
        XCTAssertEqual(preview.candidates.map(\.id), ["base", "muted-rules", "quiet-hours"])
        XCTAssertEqual(preview.candidates.map(\.title), [
            "Notification Preferences",
            "Muted Servers and Contacts",
            "Quiet Hours"
        ])
        XCTAssertEqual(preview.candidates.first?.notificationsEnabled, true)
        XCTAssertEqual(preview.candidates.first?.soundEnabled, false)
        XCTAssertEqual(preview.candidates.first?.eventTypeCount, 2)
        XCTAssertEqual(preview.candidates[1].mutedServerCount, 2)
        XCTAssertEqual(preview.candidates[1].mutedContactCount, 1)
        XCTAssertEqual(preview.candidates[2].quietHoursEnabled, true)
        XCTAssertTrue(preview.containsSetting(id: "muted-rules"))
        XCTAssertFalse(preview.containsSetting(id: "missing"))
    }

    @MainActor
    func testNotificationSettingsRestoreImpactSummaryCountsSelectedGroups() throws {
        let model = TS3AppModel()
        let data = Data("""
        {
          "isEnabled": false,
          "soundEnabled": false,
          "privateMessagesEnabled": false,
          "pokesEnabled": true,
          "activityEnabled": true,
          "mutedServerKeys": [" alpha ", "", "alpha", "beta"],
          "mutedContactUniqueIdentifiers": ["", " user-1 ", "user-1"],
          "quietHoursEnabled": true,
          "quietHoursStartMinute": 1320,
          "quietHoursEndMinute": 420
        }
        """.utf8)

        let preview = try model.notificationSettingsPreview(from: data)
        let summary = TS3NotificationSettingsRestoreImpactSummary(
            preview: preview,
            selectedSettingIds: ["base", "muted-rules", "quiet-hours"]
        )

        XCTAssertEqual(summary.selectedSettingCount, 3)
        XCTAssertTrue(summary.baseSettingsSelected)
        XCTAssertTrue(summary.mutedRulesSelected)
        XCTAssertTrue(summary.quietHoursSelected)
        XCTAssertEqual(summary.notificationsEnabled, false)
        XCTAssertEqual(summary.soundEnabled, false)
        XCTAssertEqual(summary.eventTypeCount, 2)
        XCTAssertEqual(summary.mutedServerCount, 2)
        XCTAssertEqual(summary.mutedContactCount, 1)
        XCTAssertEqual(summary.quietHoursEnabled, true)
        XCTAssertTrue(summary.hasSelection)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "selected=3 | base=true | mutedRules=true | quietHours=true | notificationsEnabled=false | soundEnabled=false | eventTypes=2 | mutedServers=2 | mutedContacts=1 | quietHoursEnabled=true | needsAttention=true"
        )

        let quietOnly = TS3NotificationSettingsRestoreImpactSummary(
            preview: preview,
            selectedSettingIds: ["quiet-hours"]
        )
        XCTAssertEqual(quietOnly.selectedSettingCount, 1)
        XCTAssertFalse(quietOnly.baseSettingsSelected)
        XCTAssertFalse(quietOnly.mutedRulesSelected)
        XCTAssertTrue(quietOnly.quietHoursSelected)
        XCTAssertNil(quietOnly.notificationsEnabled)
        XCTAssertEqual(quietOnly.eventTypeCount, 0)
        XCTAssertEqual(quietOnly.mutedServerCount, 0)
        XCTAssertEqual(quietOnly.mutedContactCount, 0)
        XCTAssertEqual(quietOnly.quietHoursEnabled, true)
        XCTAssertTrue(quietOnly.needsAttention)
        XCTAssertEqual(
            quietOnly.clipboardSummary,
            "selected=1 | base=false | mutedRules=false | quietHours=true | notificationsEnabled=notSelected | soundEnabled=notSelected | eventTypes=0 | mutedServers=0 | mutedContacts=0 | quietHoursEnabled=true | needsAttention=true"
        )
    }

    @MainActor
    func testNotificationSettingsImportCanRestoreSelectedGroups() throws {
        let model = TS3AppModel()
        model.resetNotificationSettings()
        model.applyDirectNotificationPreset()
        model.setNotificationServerMuted(true, key: "local-server")
        model.setContactNotificationsMuted(
            true,
            contact: TS3ContactEntry(
                uniqueIdentifier: "local-contact",
                nickname: "Local",
                status: .friend,
                note: "",
                updatedAt: Date(timeIntervalSince1970: 0)
            )
        )
        model.setNotificationQuietHoursEnabled(false)
        model.setNotificationQuietHours(startMinute: 21 * 60, endMinute: 6 * 60)

        let data = Data("""
        {
          "isEnabled": true,
          "soundEnabled": false,
          "privateMessagesEnabled": false,
          "pokesEnabled": false,
          "activityEnabled": true,
          "mutedServerKeys": [" imported-server ", "imported-server"],
          "mutedContactUniqueIdentifiers": [" imported-contact "],
          "quietHoursEnabled": true,
          "quietHoursStartMinute": -5,
          "quietHoursEndMinute": 1600
        }
        """.utf8)

        try model.importNotificationSettings(
            from: data,
            options: TS3NotificationSettingsImportOptions(
                baseSettings: false,
                mutedRules: true,
                quietHours: false
            )
        )

        XCTAssertTrue(model.privateMessageNotificationsEnabled)
        XCTAssertTrue(model.pokeNotificationsEnabled)
        XCTAssertFalse(model.activityNotificationsEnabled)
        XCTAssertTrue(model.notificationSoundEnabled)
        XCTAssertEqual(model.mutedNotificationServerKeys, ["imported-server"])
        XCTAssertEqual(model.mutedNotificationContactUniqueIdentifiers, ["imported-contact"])
        XCTAssertFalse(model.notificationQuietHoursEnabled)
        XCTAssertEqual(model.notificationQuietHoursStartMinute, 21 * 60)
        XCTAssertEqual(model.notificationQuietHoursEndMinute, 6 * 60)

        try model.importNotificationSettings(
            from: data,
            options: TS3NotificationSettingsImportOptions(
                baseSettings: true,
                mutedRules: false,
                quietHours: true
            )
        )

        XCTAssertFalse(model.privateMessageNotificationsEnabled)
        XCTAssertFalse(model.pokeNotificationsEnabled)
        XCTAssertTrue(model.activityNotificationsEnabled)
        XCTAssertFalse(model.notificationSoundEnabled)
        XCTAssertEqual(model.mutedNotificationServerKeys, ["imported-server"])
        XCTAssertEqual(model.mutedNotificationContactUniqueIdentifiers, ["imported-contact"])
        XCTAssertTrue(model.notificationQuietHoursEnabled)
        XCTAssertEqual(model.notificationQuietHoursStartMinute, 0)
        XCTAssertEqual(model.notificationQuietHoursEndMinute, 23 * 60 + 59)
    }
}
