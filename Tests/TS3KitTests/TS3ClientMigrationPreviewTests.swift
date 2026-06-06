import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3ClientMigrationPreviewTests: XCTestCase {
    @MainActor
    func testClientMigrationPreviewIncludesSettingsDetails() throws {
        let model = TS3AppModel()
        model.resetNotificationSettings()
        model.applyDirectNotificationPreset(soundEnabled: false)
        model.setActivityNotificationsEnabled(true)
        model.setNotificationQuietHoursEnabled(true)
        model.setNotificationQuietHours(startMinute: 21 * 60 + 30, endMinute: 6 * 60 + 15)
        model.setNotificationServerMuted(true, key: "voice.example.test")
        model.updateAudioTransmitMode(.voiceActivation)
        model.awayMessage = "Testing migration"
        model.isAway = true

        let firstShortcut = try XCTUnwrap(model.keyboardShortcuts.first)
        model.updateKeyboardShortcut(firstShortcut, keys: firstShortcut.keys, isEnabled: false)
        let expectedEnabledShortcutCount = model.keyboardShortcuts.filter(\.isEnabled).count
        let expectedTotalShortcutCount = model.keyboardShortcuts.count

        let exported = try model.clientMigrationPackageExportData()
        let preview = try model.clientMigrationPackagePreview(from: exported)

        XCTAssertEqual(preview.schemaVersion, 1)
        XCTAssertTrue(preview.settingsGroups.contains("Notification settings"))
        XCTAssertTrue(preview.settingsGroups.contains("Audio settings"))
        XCTAssertTrue(preview.settingsGroups.contains("Self status"))
        XCTAssertTrue(preview.settingsDetails.contains("Notifications: Disabled"))
        XCTAssertTrue(preview.settingsDetails.contains("Notification sounds: Off"))
        XCTAssertTrue(preview.settingsDetails.contains("Notification event types: private messages, pokes, activity"))
        XCTAssertTrue(preview.settingsDetails.contains("Muted notification servers: 1"))
        XCTAssertTrue(preview.settingsDetails.contains("Quiet hours: 21:30-06:15"))
        XCTAssertTrue(preview.settingsDetails.contains("Keyboard shortcuts: \(expectedEnabledShortcutCount) enabled / \(expectedTotalShortcutCount) total"))
        XCTAssertTrue(preview.settingsDetails.contains("Audio transmit mode: voiceActivation"))
        XCTAssertTrue(preview.settingsDetails.contains("Self status: Away"))
    }
}
