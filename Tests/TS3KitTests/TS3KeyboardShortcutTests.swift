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
}
