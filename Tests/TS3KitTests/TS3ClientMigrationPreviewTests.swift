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

    @MainActor
    func testClientMigrationImportCanRestoreOnlyContacts() throws {
        let source = TS3AppModel()
        source.contacts = [
            makeContact(uniqueIdentifier: "contact-1", nickname: "Avery", status: .friend, note: "squad")
        ]
        source.updateAudioTransmitMode(.voiceActivation)
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        target.contacts = []
        target.updateAudioTransmitMode(.pushToTalk)

        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                contacts: true,
                notifications: false,
                chat: false,
                serverAdministration: false,
                channelLayout: false,
                files: false,
                audio: false,
                selfStatus: false,
                whisper: false
            )
        )

        XCTAssertEqual(target.contacts.map(\.uniqueIdentifier), ["contact-1"])
        XCTAssertEqual(target.contacts.first?.nickname, "Avery")
        XCTAssertEqual(target.audioTransmitMode, .pushToTalk)
    }

    @MainActor
    func testClientMigrationImportCanRestoreOnlyAudio() throws {
        let source = TS3AppModel()
        source.contacts = [
            makeContact(uniqueIdentifier: "contact-1", nickname: "Avery", status: .friend, note: "squad")
        ]
        source.updateAudioTransmitMode(.voiceActivation)
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        target.contacts = []
        target.updateAudioTransmitMode(.pushToTalk)

        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                contacts: false,
                notifications: false,
                chat: false,
                serverAdministration: false,
                channelLayout: false,
                files: false,
                audio: true,
                selfStatus: false,
                whisper: false
            )
        )

        XCTAssertTrue(target.contacts.isEmpty)
        XCTAssertEqual(target.audioTransmitMode, .voiceActivation)
    }

    func testClientMigrationRestoreOptionsExposeSelectedSectionTitles() {
        let options = TS3ClientMigrationRestoreOptions(
            connections: true,
            contacts: false,
            notifications: true,
            chat: false,
            serverAdministration: false,
            channelLayout: true,
            files: false,
            audio: false,
            selfStatus: false,
            whisper: true
        )

        XCTAssertTrue(options.hasSelectedSections)
        XCTAssertEqual(options.selectedSectionTitles, ["Connections", "Notifications", "Channel Layout", "Whisper"])
    }

    @MainActor
    func testSavedChannelPasswordsCanBeSavedUpdatedAndForgotten() {
        let model = TS3AppModel()
        model.serverHost = "voice-\(UUID().uuidString).example.test"
        model.serverPort = "9988"
        let channel = makeChannel(id: 31, name: "Raid Room", isPasswordProtected: true)
        model.channels = [channel]

        model.saveChannelPassword(" first-pass ", for: channel)

        XCTAssertEqual(model.savedChannelPassword(for: channel), "first-pass")
        XCTAssertTrue(model.hasSavedChannelPassword(for: channel))

        model.saveChannelPassword("second-pass", for: channel)

        XCTAssertEqual(model.savedChannelPassword(for: channel), "second-pass")
        XCTAssertEqual(model.savedChannelPasswords.filter { $0.channelPath == "Raid Room" }.count, 1)

        model.forgetSavedChannelPassword(for: channel)

        XCTAssertNil(model.savedChannelPassword(for: channel))
        XCTAssertFalse(model.hasSavedChannelPassword(for: channel))
    }

    @MainActor
    func testClientMigrationImportCanRestoreOnlySavedChannelPasswordsWithConnections() throws {
        let source = TS3AppModel()
        source.serverHost = "voice-\(UUID().uuidString).example.test"
        source.serverPort = "9989"
        let channel = makeChannel(id: 41, name: "Locked Room", isPasswordProtected: true)
        source.channels = [channel]
        source.saveChannelPassword("room-pass", for: channel)
        source.contacts = [
            makeContact(uniqueIdentifier: "contact-1", nickname: "Avery", status: .friend, note: "squad")
        ]
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        target.serverHost = source.serverHost
        target.serverPort = source.serverPort
        target.channels = [channel]
        target.contacts = []

        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: true,
                contacts: false,
                notifications: false,
                chat: false,
                serverAdministration: false,
                channelLayout: false,
                files: false,
                audio: false,
                selfStatus: false,
                whisper: false
            )
        )

        XCTAssertEqual(target.savedChannelPassword(for: channel), "room-pass")
        XCTAssertTrue(target.contacts.isEmpty)
        let preview = try target.clientMigrationPackagePreview(from: exported)
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Saved Channel Passwords" && $0.1 >= 1 })
    }

    private func makeContact(
        uniqueIdentifier: String,
        nickname: String,
        status: TS3ContactStatus,
        note: String
    ) -> TS3ContactEntry {
        TS3ContactEntry(
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            status: status,
            note: note,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private func makeChannel(
        id: Int,
        name: String,
        isPasswordProtected: Bool
    ) -> TS3ChannelSummary {
        TS3ChannelSummary(
            id: id,
            parentId: nil,
            order: nil,
            name: name,
            phoneticName: nil,
            topic: nil,
            description: nil,
            isDefault: false,
            isPasswordProtected: isPasswordProtected,
            isPermanent: true,
            isSemiPermanent: nil,
            neededTalkPower: nil,
            neededSubscribePower: nil,
            neededDescriptionViewPower: nil,
            codec: nil,
            codecQuality: nil,
            codecLatencyFactor: nil,
            isCodecUnencrypted: nil,
            deleteDelaySeconds: nil,
            maxClients: nil,
            maxFamilyClients: nil,
            maxClientsUnlimited: nil,
            maxFamilyClientsUnlimited: nil,
            maxFamilyClientsInherited: nil,
            iconId: nil,
            iconURL: nil,
            isSubscribed: nil,
            isCurrent: false
        )
    }
}
