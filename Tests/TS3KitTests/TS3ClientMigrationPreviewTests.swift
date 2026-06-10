import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3ClientMigrationPreviewTests: XCTestCase {
    func testIdentityProfileSummaryAndAccessibilityText() {
        let profile = TS3IdentityProfile(
            name: "Main Identity",
            uid: "identity-uid",
            securityLevel: 24,
            keyOffset: 7,
            exportString: "identity-backup"
        )

        XCTAssertEqual(
            profile.clipboardSummary,
            "name=Main Identity | uid=identity-uid | security=24 | keyOffset=7 | backupLength=15"
        )
        XCTAssertEqual(
            profile.accessibilityValue(isActive: true, canSwitch: true),
            "Active. Security level 24. Key offset 7. UID identity-uid"
        )
        XCTAssertEqual(
            profile.accessibilityValue(isActive: false, canSwitch: false),
            "Saved. Security level 24. Key offset 7. UID identity-uid. Disconnect before switching identities"
        )
    }

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
                identities: false,
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
                identities: false,
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

    @MainActor
    func testClientMigrationImportRestoresNotificationsOnlyWhenSelected() throws {
        let source = TS3AppModel()
        source.resetNotificationSettings()
        source.applyAllEventsNotificationPreset()
        source.setNotificationSoundEnabled(false)
        source.setNotificationQuietHoursEnabled(true)
        source.setNotificationQuietHours(startMinute: 22 * 60, endMinute: 7 * 60)
        source.setNotificationServerMuted(true, key: "voice.example.test")
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        target.resetNotificationSettings()
        target.applyDirectNotificationPreset()
        target.setNotificationSoundEnabled(true)
        target.setNotificationQuietHoursEnabled(false)
        target.setNotificationServerMuted(false, key: "voice.example.test")

        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                identities: false,
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

        XCTAssertTrue(target.privateMessageNotificationsEnabled)
        XCTAssertTrue(target.pokeNotificationsEnabled)
        XCTAssertFalse(target.activityNotificationsEnabled)
        XCTAssertTrue(target.notificationSoundEnabled)
        XCTAssertFalse(target.notificationQuietHoursEnabled)
        XCTAssertFalse(target.mutedNotificationServerKeys.contains("voice.example.test"))

        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                identities: false,
                contacts: false,
                notifications: true,
                chat: false,
                serverAdministration: false,
                channelLayout: false,
                files: false,
                audio: false,
                selfStatus: false,
                whisper: false
            )
        )

        XCTAssertTrue(target.privateMessageNotificationsEnabled)
        XCTAssertTrue(target.pokeNotificationsEnabled)
        XCTAssertTrue(target.activityNotificationsEnabled)
        XCTAssertFalse(target.notificationSoundEnabled)
        XCTAssertTrue(target.notificationQuietHoursEnabled)
        XCTAssertEqual(target.notificationQuietHoursStartMinute, 22 * 60)
        XCTAssertEqual(target.notificationQuietHoursEndMinute, 7 * 60)
        XCTAssertTrue(target.mutedNotificationServerKeys.contains("voice.example.test"))
    }

    func testClientMigrationRestoreOptionsExposeSelectedSectionTitles() {
        let options = TS3ClientMigrationRestoreOptions(
            connections: true,
            identities: false,
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
                identities: false,
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

    @MainActor
    func testClientMigrationCanRestoreIdentityProfilesSeparately() async throws {
        let source = TS3AppModel()
        await source.refreshIdentitySummary()
        source.saveCurrentIdentityProfile(name: "Main Identity")
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                identities: true,
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

        XCTAssertTrue(target.identityProfiles.contains { $0.name == "Main Identity" && $0.uid == source.identitySummary.uid })
        let preview = try target.clientMigrationPackagePreview(from: exported)
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Identity Profiles" && $0.1 >= 1 })
    }

    @MainActor
    func testClientMigrationCanRestoreOnlyChannelLayout() throws {
        let suffix = UUID().uuidString
        let source = TS3AppModel()
        source.channels = [
            makeChannel(id: 41, name: "Ops", isPasswordProtected: false, isSubscribed: true),
            makeChannel(id: 42, name: "Lobby", isPasswordProtected: false, isSubscribed: false)
        ]
        source.saveCurrentChannelSubscriptionPreset(name: "Migration Subs \(suffix)")
        source.saveChannelTreeFilterPreset(
            name: "Migration Tree \(suffix)",
            treeFilter: "subscribed",
            sortMode: "name",
            sortAscending: false,
            memberSortMode: "status",
            memberSortAscending: true,
            currentUserFirst: false,
            searchText: "ops"
        )
        source.setChannelCollapsed(41, isCollapsed: true)
        source.fileBrowserChannelId = 41
        source.fileBrowserPath = "/ops/"
        source.saveCurrentFileBrowserBookmark(name: "Migration File \(suffix)")
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        target.fileBrowserChannelId = 99
        target.fileBrowserPath = "/local/"
        target.saveCurrentFileBrowserBookmark(name: "Local File \(suffix)")
        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                identities: false,
                contacts: false,
                notifications: false,
                chat: false,
                serverAdministration: false,
                channelLayout: true,
                files: false,
                audio: false,
                selfStatus: false,
                whisper: false
            )
        )

        XCTAssertTrue(target.channelSubscriptionPresets.contains { $0.name == "Migration Subs \(suffix)" && $0.channelIds == [41] })
        XCTAssertTrue(target.channelTreeFilterPresets.contains { $0.name == "Migration Tree \(suffix)" && $0.searchText == "ops" })
        XCTAssertTrue(target.isChannelCollapsed(41))
        XCTAssertTrue(target.fileBrowserBookmarks.contains { $0.name == "Local File \(suffix)" && $0.path == "/local/" })

        let preview = try target.clientMigrationPackagePreview(from: exported)
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Channel Subscription Presets" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Channel Tree Filters" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Collapsed Channels" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "File Bookmarks" && $0.1 >= 1 })
    }

    @MainActor
    func testClientMigrationCanRestoreOnlyFilesAndServerAdministrationPresets() throws {
        let suffix = UUID().uuidString
        let source = TS3AppModel()
        source.channels = [makeChannel(id: 51, name: "Files", isPasswordProtected: false)]
        source.fileBrowserChannelId = 51
        source.fileBrowserPath = "/maps/"
        source.saveCurrentFileBrowserBookmark(name: "Migration Bookmark \(suffix)")
        source.saveFileBrowserFilterPreset(
            name: "Migration File Filter \(suffix)",
            sortMode: "size",
            sortAscending: false,
            searchText: ".bsp"
        )
        source.saveServerLogQueryPreset(
            name: "Migration Logs \(suffix)",
            limit: 250,
            beginPosition: 5,
            reverse: true,
            instance: false,
            levelFilter: "warning",
            channelFilter: "51",
            searchText: "permission"
        )
        source.saveBanFilterPreset(name: "Migration Bans \(suffix)", banFilter: "active", searchText: "spam")
        source.saveComplaintFilterPreset(
            name: "Migration Complaints \(suffix)",
            complaintFilter: "open",
            sortMode: "target",
            sortAscending: true,
            searchText: "abuse"
        )
        source.saveTemporaryServerPasswordFilterPreset(
            name: "Migration Temp Passwords \(suffix)",
            passwordFilter: "valid",
            sortMode: "expires",
            sortAscending: false,
            searchText: "event"
        )
        source.saveDatabaseClientFilterPreset(
            name: "Migration Database \(suffix)",
            recordFilter: "named",
            sortMode: "lastConnected",
            sortAscending: false,
            localFilterText: "avery",
            batchSize: 75
        )
        source.savePrivilegeKeyFilterPreset(
            name: "Migration Keys \(suffix)",
            keyFilter: "unused",
            sortMode: "created",
            sortAscending: false,
            searchText: "server"
        )
        source.savePermissionFilterPreset(
            name: "Migration Permissions \(suffix)",
            scope: "serverGroups",
            assignedFilter: "granted",
            assignedSortMode: "name",
            assignedSortAscending: true,
            assignedSearchText: "admin",
            permissionSearchText: "modify"
        )
        source.saveGroupFilterPreset(
            name: "Migration Groups \(suffix)",
            target: "server",
            groupTypeFilter: "normal",
            sortMode: "name",
            sortAscending: true,
            searchText: "moderator"
        )
        source.saveGroupClientFilterPreset(
            name: "Migration Members \(suffix)",
            memberFilter: "online",
            channelFilter: "selectedChannel",
            channelId: 51,
            sortMode: "nickname",
            sortAscending: true,
            searchText: "ops"
        )
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                identities: false,
                contacts: false,
                notifications: false,
                chat: false,
                serverAdministration: true,
                channelLayout: false,
                files: true,
                audio: false,
                selfStatus: false,
                whisper: false
            )
        )

        XCTAssertTrue(target.fileBrowserBookmarks.contains { $0.name == "Migration Bookmark \(suffix)" && $0.path == "/maps/" })
        XCTAssertTrue(target.fileBrowserFilterPresets.contains { $0.name == "Migration File Filter \(suffix)" && $0.searchText == ".bsp" })
        XCTAssertTrue(target.serverLogQueryPresets.contains { $0.name == "Migration Logs \(suffix)" && $0.limit == 250 })
        XCTAssertTrue(target.banFilterPresets.contains { $0.name == "Migration Bans \(suffix)" && $0.searchText == "spam" })
        XCTAssertTrue(target.complaintFilterPresets.contains { $0.name == "Migration Complaints \(suffix)" && $0.searchText == "abuse" })
        XCTAssertTrue(target.temporaryServerPasswordFilterPresets.contains { $0.name == "Migration Temp Passwords \(suffix)" && $0.searchText == "event" })
        XCTAssertTrue(target.databaseClientFilterPresets.contains { $0.name == "Migration Database \(suffix)" && $0.batchSize == 75 })
        XCTAssertTrue(target.privilegeKeyFilterPresets.contains { $0.name == "Migration Keys \(suffix)" && $0.searchText == "server" })
        XCTAssertTrue(target.permissionFilterPresets.contains { $0.name == "Migration Permissions \(suffix)" && $0.permissionSearchText == "modify" })
        XCTAssertTrue(target.groupFilterPresets.contains { $0.name == "Migration Groups \(suffix)" && $0.searchText == "moderator" })
        XCTAssertTrue(target.groupClientFilterPresets.contains { $0.name == "Migration Members \(suffix)" && $0.channelId == 51 })

        let preview = try target.clientMigrationPackagePreview(from: exported)
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "File Bookmarks" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "File Filters" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Server Log Presets" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Group Client Filters" && $0.1 >= 1 })
    }

    @MainActor
    func testClientMigrationCanRestoreSelfStatusAndWhisperSeparately() throws {
        let suffix = UUID().uuidString
        let source = TS3AppModel()
        source.nickname = "MigrationNick-\(suffix)"
        source.awayMessage = "Reviewing migration"
        source.isAway = true
        source.isInputMuted = true
        source.isOutputMuted = false
        source.isChannelCommander = true
        source.talkRequestMessage = "Need migration help"
        source.saveCurrentSelfStatusProfile(name: "Migration Status \(suffix)")
        source.saveWhisperPreset(name: "Migration Whisper \(suffix)", channelIds: [61, 62], clientIds: [7])
        source.saveWhisperFilterPreset(
            name: "Migration Whisper Filter \(suffix)",
            presetFilter: "channels",
            presetSort: "name",
            searchText: "ops"
        )
        source.updateAudioTransmitMode(.voiceActivation)
        let exported = try source.clientMigrationPackageExportData()

        let target = TS3AppModel()
        target.nickname = "TargetNick-\(suffix)"
        target.isAway = false
        target.updateAudioTransmitMode(.pushToTalk)

        try target.importClientMigrationPackage(
            from: exported,
            options: TS3ClientMigrationRestoreOptions(
                connections: false,
                identities: false,
                contacts: false,
                notifications: false,
                chat: false,
                serverAdministration: false,
                channelLayout: false,
                files: false,
                audio: false,
                selfStatus: true,
                whisper: true
            )
        )

        XCTAssertEqual(target.nickname, "MigrationNick-\(suffix)")
        XCTAssertTrue(target.isAway)
        XCTAssertEqual(target.awayMessage, "Reviewing migration")
        XCTAssertTrue(target.isInputMuted)
        XCTAssertTrue(target.isChannelCommander)
        XCTAssertEqual(target.talkRequestMessage, "Need migration help")
        XCTAssertEqual(target.audioTransmitMode, .pushToTalk)
        XCTAssertTrue(target.selfStatusProfiles.contains { $0.name == "Migration Status \(suffix)" && $0.status.isAway })
        XCTAssertTrue(target.whisperPresets.contains { $0.name == "Migration Whisper \(suffix)" && $0.channelIds == [61, 62] && $0.clientIds == [7] })
        XCTAssertTrue(target.whisperFilterPresets.contains { $0.name == "Migration Whisper Filter \(suffix)" && $0.searchText == "ops" })

        let preview = try target.clientMigrationPackagePreview(from: exported)
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Self Status Profiles" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Whisper Presets" && $0.1 >= 1 })
        XCTAssertTrue(preview.itemCounts.contains { $0.0 == "Whisper Filters" && $0.1 >= 1 })
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
        isPasswordProtected: Bool,
        isSubscribed: Bool? = nil
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
            isSubscribed: isSubscribed,
            isCurrent: false
        )
    }
}
