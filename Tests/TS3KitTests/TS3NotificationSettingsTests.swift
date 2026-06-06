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
    }
}
