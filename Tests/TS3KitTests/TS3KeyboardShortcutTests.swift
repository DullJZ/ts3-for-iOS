import XCTest
@testable import TS3iOSApp

final class TS3KeyboardShortcutTests: XCTestCase {
    func testKeyboardShortcutBindingSummariesAreCopyableAndAccessible() {
        let shortcut = TS3KeyboardShortcutBinding(
            actionId: "open-chat",
            group: "Messaging",
            action: "Open Chat",
            defaultKeys: "Command-Shift-T",
            keys: "Command-Option-T",
            isEnabled: false
        )

        XCTAssertEqual(shortcut.stateTitle, "Disabled")
        XCTAssertEqual(shortcut.displaySummary, "Command-Option-T · Disabled")
        XCTAssertEqual(
            shortcut.clipboardSummary,
            "group=Messaging | action=Open Chat | keys=Command-Option-T | default=Command-Shift-T | enabled=false"
        )
        XCTAssertEqual(
            shortcut.accessibilityValue,
            "Messaging. Keys Command-Option-T. Disabled. Default Command-Shift-T."
        )
    }

    func testKeyboardShortcutCapabilitySummaryCountsPlatformCoverageAndIssues() {
        let shortcuts = [
            TS3KeyboardShortcutBinding(
                actionId: "open-chat",
                group: "Messaging",
                action: "Open Chat",
                defaultKeys: "Command-Shift-T",
                keys: "Command-Shift-T",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-whisper",
                group: "Messaging",
                action: "Open Whisper",
                defaultKeys: "Command-Shift-W",
                keys: "Command-Shift-W",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "start-whisper-activation",
                group: "Voice",
                action: "Start Temporary Whisper",
                defaultKeys: "Command-Option-H",
                keys: "Hyper-H",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "toggle-talk",
                group: "Voice",
                action: "Talk / Stop Talking",
                defaultKeys: "Command-T",
                keys: "Command-Shift-T",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "show-debug-log",
                group: "Global",
                action: "Show Debug Log",
                defaultKeys: "Command-Shift-L",
                keys: "Command-Shift-L",
                isEnabled: false
            )
        ]

        let summary = TS3KeyboardShortcutCapabilitySummary(shortcuts: shortcuts)

        XCTAssertEqual(summary.totalCount, 5)
        XCTAssertEqual(summary.enabledCount, 4)
        XCTAssertEqual(summary.validEnabledCount, 3)
        XCTAssertEqual(summary.invalidEnabledCount, 1)
        XCTAssertEqual(summary.duplicateEnabledCount, 2)
        XCTAssertEqual(summary.catalystMenuCount, 3)
        XCTAssertEqual(summary.whisperShortcutCount, 1)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "shortcuts=5 | enabled=4 | validEnabled=3 | invalidEnabled=1 | duplicateEnabled=2 | catalystMenu=3 | whisper=1 | iOSGlobalHotkeys=unavailable | needsAttention=true"
        )
    }

    @MainActor
    func testDefaultKeyboardShortcutsAreUniqueAndParseable() {
        var seenActionIds: Set<String> = []
        var seenEnabledKeys: Set<String> = []

        for shortcut in TS3AppModel.defaultKeyboardShortcuts {
            XCTAssertTrue(seenActionIds.insert(shortcut.actionId).inserted, "Duplicate action id \(shortcut.actionId)")
            XCTAssertNotNil(TS3KeyboardShortcutDescriptor(shortcut.defaultKeys), "Invalid default keys for \(shortcut.actionId)")
            XCTAssertTrue(seenEnabledKeys.insert(shortcut.defaultKeys.lowercased()).inserted, "Duplicate keys \(shortcut.defaultKeys)")
        }
    }

    @MainActor
    func testWhisperHoldShortcutUsesConfiguredStartBinding() throws {
        let shortcut = try XCTUnwrap(TS3AppModel.defaultKeyboardShortcuts.first { $0.actionId == "start-whisper-activation" })
        let descriptor = try XCTUnwrap(TS3KeyboardShortcutDescriptor(shortcut.defaultKeys))

        XCTAssertEqual(shortcut.defaultKeys, "Command-Option-H")
        XCTAssertTrue(descriptor.modifiers.contains(.command))
        XCTAssertTrue(descriptor.modifiers.contains(.option))
    }

    @MainActor
    func testKeyboardShortcutImportBackfillsNewCatalystMenuActions() throws {
        let model = TS3AppModel()
        let legacyJSON = """
        [
          {
            "actionId": "show-debug-log",
            "group": "Global",
            "action": "Show Debug Log",
            "defaultKeys": "Command-Shift-L",
            "keys": "Command-Option-L",
            "isEnabled": false
          }
        ]
        """

        try model.importKeyboardShortcuts(from: Data(legacyJSON.utf8))

        let debugShortcut = try XCTUnwrap(model.keyboardShortcuts.first { $0.actionId == "show-debug-log" })
        XCTAssertEqual(debugShortcut.keys, "Command-Option-L")
        XCTAssertFalse(debugShortcut.isEnabled)

        let backfilledIds = [
            "manage-identity",
            "connection-manager",
            "client-migration",
            "notification-settings",
            "reconnect-server",
            "disconnect-server",
            "save-bookmark",
            "copy-invite",
            "copy-full-invite",
            "self-status",
            "audio-settings"
        ]
        for actionId in backfilledIds {
            let shortcut = try XCTUnwrap(model.keyboardShortcuts.first { $0.actionId == actionId })
            XCTAssertEqual(shortcut.keys, shortcut.defaultKeys)
            XCTAssertTrue(shortcut.isEnabled)
            XCTAssertNotNil(TS3KeyboardShortcutDescriptor(shortcut.keys))
        }
    }

    @MainActor
    func testKeyboardShortcutImportPreviewSummarizesChangesWarningsAndLegacyIds() throws {
        let model = TS3AppModel()
        model.resetKeyboardShortcuts()
        model.updateKeyboardShortcut(
            try XCTUnwrap(model.keyboardShortcuts.first { $0.actionId == "open-chat" }),
            keys: "Command-Shift-T",
            isEnabled: true
        )
        let backupJSON = """
        [
          {
            "actionId": "open-chat",
            "group": "Messaging",
            "action": "Open Chat",
            "defaultKeys": "Command-Shift-T",
            "keys": "Command-Option-T",
            "isEnabled": true
          },
          {
            "actionId": "open-events",
            "group": "Messaging",
            "action": "Open Events",
            "defaultKeys": "Command-Shift-E",
            "keys": "Command-Option-T",
            "isEnabled": true
          },
          {
            "actionId": "toggle-talk",
            "group": "Voice",
            "action": "Talk / Stop Talking",
            "defaultKeys": "Command-T",
            "keys": "Hyper-T",
            "isEnabled": true
          },
          {
            "actionId": "toggle-output-muted",
            "group": "Voice",
            "action": "Mute / Unmute Sound",
            "defaultKeys": "Command-Shift-S",
            "keys": "Command-Shift-S",
            "isEnabled": false
          },
          {
            "actionId": "legacy-action",
            "group": "Legacy",
            "action": "Legacy Action",
            "defaultKeys": "Command-L",
            "keys": "Command-L",
            "isEnabled": true
          }
        ]
        """

        let preview = try model.keyboardShortcutsImportPreview(from: Data(backupJSON.utf8))

        XCTAssertEqual(preview.totalShortcutCount, TS3AppModel.defaultKeyboardShortcuts.count)
        XCTAssertEqual(preview.importedShortcutCount, 4)
        XCTAssertEqual(preview.changedCount, 4)
        XCTAssertEqual(preview.disabledCount, 1)
        XCTAssertEqual(preview.invalidShortcutCount, 1)
        XCTAssertEqual(preview.duplicateShortcutCount, 2)
        XCTAssertEqual(preview.unknownShortcutCount, 1)
        XCTAssertEqual(
            preview.changedSummaries,
            [
                "changed action=Talk / Stop Talking keys=Hyper-T enabled=true",
                "changed action=Mute / Unmute Sound keys=Command-Shift-S enabled=false",
                "changed action=Open Chat keys=Command-Option-T enabled=true",
                "changed action=Open Events keys=Command-Option-T enabled=true"
            ]
        )
        XCTAssertEqual(preview.invalidSummaries, ["invalid action=Talk / Stop Talking keys=Hyper-T"])
        XCTAssertEqual(
            preview.duplicateSummaries,
            [
                "duplicate action=Open Chat keys=Command-Option-T",
                "duplicate action=Open Events keys=Command-Option-T"
            ]
        )
        XCTAssertEqual(preview.unknownSummaries, ["unknown actionId=legacy-action"])
        XCTAssertEqual(
            preview.clipboardSummary,
            """
            Shortcuts: \(TS3AppModel.defaultKeyboardShortcuts.count)
            Imported shortcuts: 4
            Changed shortcuts: 4
            Disabled shortcuts: 1
            Invalid enabled shortcuts: 1
            Duplicate enabled shortcuts: 2
            Unknown imported shortcuts: 1
            changed action=Talk / Stop Talking keys=Hyper-T enabled=true
            changed action=Mute / Unmute Sound keys=Command-Shift-S enabled=false
            changed action=Open Chat keys=Command-Option-T enabled=true
            changed action=Open Events keys=Command-Option-T enabled=true
            invalid action=Talk / Stop Talking keys=Hyper-T
            duplicate action=Open Chat keys=Command-Option-T
            duplicate action=Open Events keys=Command-Option-T
            unknown actionId=legacy-action
            """
        )
    }
}
