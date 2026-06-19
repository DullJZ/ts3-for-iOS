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

    func testKeyboardShortcutBulkEnableAllImpactCountsAffectedShortcutsAndRisks() {
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
                keys: "Command-Option-W",
                isEnabled: false
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
                isEnabled: false
            )
        ]

        let summary = TS3KeyboardShortcutBulkActionImpactSummary(
            action: .enableAll,
            shortcuts: shortcuts,
            defaultShortcuts: shortcuts
        )

        XCTAssertEqual(summary.totalShortcutCount, 4)
        XCTAssertEqual(summary.affectedShortcutCount, 2)
        XCTAssertEqual(summary.enabledBeforeCount, 2)
        XCTAssertEqual(summary.disabledBeforeCount, 2)
        XCTAssertEqual(summary.enabledAfterCount, 4)
        XCTAssertEqual(summary.disabledAfterCount, 0)
        XCTAssertEqual(summary.invalidBeforeCount, 1)
        XCTAssertEqual(summary.invalidAfterCount, 1)
        XCTAssertEqual(summary.duplicateBeforeCount, 0)
        XCTAssertEqual(summary.duplicateAfterCount, 2)
        XCTAssertEqual(summary.catalystMenuAffectedCount, 2)
        XCTAssertEqual(summary.whisperShortcutAffectedCount, 1)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "action=enableAll | shortcuts=4 | affected=2 | enabledBefore=2 | disabledBefore=2 | enabledAfter=4 | disabledAfter=0 | invalidBefore=1 | invalidAfter=1 | duplicateBefore=0 | duplicateAfter=2 | catalystAffected=2 | whisperAffected=1 | iOSGlobalHotkeys=unavailable | needsAttention=true"
        )
    }

    func testKeyboardShortcutBulkDisableAllImpactClearsEnabledRisks() {
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
                actionId: "open-events",
                group: "Messaging",
                action: "Open Events",
                defaultKeys: "Command-Shift-E",
                keys: "Command-Shift-T",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-whisper",
                group: "Messaging",
                action: "Open Whisper",
                defaultKeys: "Command-Shift-W",
                keys: "Hyper-W",
                isEnabled: true
            )
        ]

        let summary = TS3KeyboardShortcutBulkActionImpactSummary(
            action: .disableAll,
            shortcuts: shortcuts,
            defaultShortcuts: shortcuts
        )

        XCTAssertEqual(summary.totalShortcutCount, 3)
        XCTAssertEqual(summary.affectedShortcutCount, 3)
        XCTAssertEqual(summary.enabledBeforeCount, 3)
        XCTAssertEqual(summary.disabledBeforeCount, 0)
        XCTAssertEqual(summary.enabledAfterCount, 0)
        XCTAssertEqual(summary.disabledAfterCount, 3)
        XCTAssertEqual(summary.invalidBeforeCount, 1)
        XCTAssertEqual(summary.invalidAfterCount, 0)
        XCTAssertEqual(summary.duplicateBeforeCount, 2)
        XCTAssertEqual(summary.duplicateAfterCount, 0)
        XCTAssertEqual(summary.catalystMenuAffectedCount, 3)
        XCTAssertEqual(summary.whisperShortcutAffectedCount, 1)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "action=disableAll | shortcuts=3 | affected=3 | enabledBefore=3 | disabledBefore=0 | enabledAfter=0 | disabledAfter=3 | invalidBefore=1 | invalidAfter=0 | duplicateBefore=2 | duplicateAfter=0 | catalystAffected=3 | whisperAffected=1 | iOSGlobalHotkeys=unavailable | needsAttention=false"
        )
    }

    func testKeyboardShortcutBulkResetAllImpactRestoresDefaultKeysAndEnabledState() {
        let defaults = [
            TS3KeyboardShortcutBinding(
                actionId: "open-chat",
                group: "Messaging",
                action: "Open Chat",
                defaultKeys: "Command-Shift-T"
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-events",
                group: "Messaging",
                action: "Open Events",
                defaultKeys: "Command-Shift-E"
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-whisper",
                group: "Messaging",
                action: "Open Whisper",
                defaultKeys: "Command-Shift-W"
            ),
            TS3KeyboardShortcutBinding(
                actionId: "toggle-talk",
                group: "Voice",
                action: "Talk / Stop Talking",
                defaultKeys: "Command-T"
            )
        ]
        let current = [
            TS3KeyboardShortcutBinding(
                actionId: "open-chat",
                group: "Messaging",
                action: "Open Chat",
                defaultKeys: "Command-Shift-T",
                keys: "Command-Option-T",
                isEnabled: false
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-events",
                group: "Messaging",
                action: "Open Events",
                defaultKeys: "Command-Shift-E",
                keys: "Command-Shift-E",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-whisper",
                group: "Messaging",
                action: "Open Whisper",
                defaultKeys: "Command-Shift-W",
                keys: "Hyper-W",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "toggle-talk",
                group: "Voice",
                action: "Talk / Stop Talking",
                defaultKeys: "Command-T",
                keys: "Command-Shift-E",
                isEnabled: true
            )
        ]

        let summary = TS3KeyboardShortcutBulkActionImpactSummary(
            action: .resetAll,
            shortcuts: current,
            defaultShortcuts: defaults
        )

        XCTAssertEqual(summary.totalShortcutCount, 4)
        XCTAssertEqual(summary.affectedShortcutCount, 3)
        XCTAssertEqual(summary.enabledBeforeCount, 3)
        XCTAssertEqual(summary.disabledBeforeCount, 1)
        XCTAssertEqual(summary.enabledAfterCount, 4)
        XCTAssertEqual(summary.disabledAfterCount, 0)
        XCTAssertEqual(summary.invalidBeforeCount, 1)
        XCTAssertEqual(summary.invalidAfterCount, 0)
        XCTAssertEqual(summary.duplicateBeforeCount, 2)
        XCTAssertEqual(summary.duplicateAfterCount, 0)
        XCTAssertEqual(summary.catalystMenuAffectedCount, 3)
        XCTAssertEqual(summary.whisperShortcutAffectedCount, 1)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "action=resetAll | shortcuts=4 | affected=3 | enabledBefore=3 | disabledBefore=1 | enabledAfter=4 | disabledAfter=0 | invalidBefore=1 | invalidAfter=0 | duplicateBefore=2 | duplicateAfter=0 | catalystAffected=3 | whisperAffected=1 | iOSGlobalHotkeys=unavailable | needsAttention=false"
        )
    }

    func testKeyboardShortcutBulkResetDisabledImpactLeavesEnabledCustomShortcutsAlone() {
        let defaults = [
            TS3KeyboardShortcutBinding(
                actionId: "open-chat",
                group: "Messaging",
                action: "Open Chat",
                defaultKeys: "Command-Shift-T"
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-whisper",
                group: "Messaging",
                action: "Open Whisper",
                defaultKeys: "Command-Shift-W"
            ),
            TS3KeyboardShortcutBinding(
                actionId: "toggle-talk",
                group: "Voice",
                action: "Talk / Stop Talking",
                defaultKeys: "Command-T"
            ),
            TS3KeyboardShortcutBinding(
                actionId: "start-whisper-activation",
                group: "Voice",
                action: "Start Temporary Whisper",
                defaultKeys: "Command-Option-H"
            )
        ]
        let current = [
            TS3KeyboardShortcutBinding(
                actionId: "open-chat",
                group: "Messaging",
                action: "Open Chat",
                defaultKeys: "Command-Shift-T",
                keys: "Command-Option-T",
                isEnabled: false
            ),
            TS3KeyboardShortcutBinding(
                actionId: "open-whisper",
                group: "Messaging",
                action: "Open Whisper",
                defaultKeys: "Command-Shift-W",
                keys: "Hyper-W",
                isEnabled: false
            ),
            TS3KeyboardShortcutBinding(
                actionId: "toggle-talk",
                group: "Voice",
                action: "Talk / Stop Talking",
                defaultKeys: "Command-T",
                keys: "Command-Option-T",
                isEnabled: true
            ),
            TS3KeyboardShortcutBinding(
                actionId: "start-whisper-activation",
                group: "Voice",
                action: "Start Temporary Whisper",
                defaultKeys: "Command-Option-H",
                keys: "Hyper-H",
                isEnabled: true
            )
        ]

        let summary = TS3KeyboardShortcutBulkActionImpactSummary(
            action: .resetDisabled,
            shortcuts: current,
            defaultShortcuts: defaults
        )

        XCTAssertEqual(summary.totalShortcutCount, 4)
        XCTAssertEqual(summary.affectedShortcutCount, 2)
        XCTAssertEqual(summary.enabledBeforeCount, 2)
        XCTAssertEqual(summary.disabledBeforeCount, 2)
        XCTAssertEqual(summary.enabledAfterCount, 4)
        XCTAssertEqual(summary.disabledAfterCount, 0)
        XCTAssertEqual(summary.invalidBeforeCount, 1)
        XCTAssertEqual(summary.invalidAfterCount, 1)
        XCTAssertEqual(summary.duplicateBeforeCount, 0)
        XCTAssertEqual(summary.duplicateAfterCount, 0)
        XCTAssertEqual(summary.catalystMenuAffectedCount, 2)
        XCTAssertEqual(summary.whisperShortcutAffectedCount, 1)
        XCTAssertTrue(summary.hasChanges)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "action=resetDisabled | shortcuts=4 | affected=2 | enabledBefore=2 | disabledBefore=2 | enabledAfter=4 | disabledAfter=0 | invalidBefore=1 | invalidAfter=1 | duplicateBefore=0 | duplicateAfter=0 | catalystAffected=2 | whisperAffected=1 | iOSGlobalHotkeys=unavailable | needsAttention=true"
        )
    }

    func testKeyboardShortcutOfficialCoverageAuditSummaryCountsCoveredAreas() {
        let capability = TS3KeyboardShortcutCapabilitySummary(shortcuts: [
            TS3KeyboardShortcutBinding(
                actionId: "open-chat",
                group: "Messaging",
                action: "Open Chat",
                defaultKeys: "Command-Shift-T",
                keys: "Command-Shift-T",
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
                actionId: "open-whisper",
                group: "Messaging",
                action: "Open Whisper",
                defaultKeys: "Command-Shift-W",
                keys: "Command-Shift-W",
                isEnabled: true
            )
        ])
        let summary = TS3KeyboardShortcutOfficialCoverageAuditSummary(
            capabilitySummary: capability,
            hasEditableBindings: true,
            hasRecorder: true,
            hasValidationWarnings: true,
            hasDuplicateWarnings: true,
            hasImportExport: true,
            hasSelectableRestore: true,
            hasBulkMaintenance: true,
            hasCatalystMenus: true,
            hasWhisperShortcuts: true,
            documentsIOSLimitations: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 10)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 10)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 24)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=10/10 | missingOfficialAreas=0 | officialActions=24 | shortcuts=3 | enabled=3 | validEnabled=3 | invalidEnabled=0 | duplicateEnabled=2 | catalystMenu=3 | whisper=1 | editableBindings=true | recorder=true | validationWarnings=true | duplicateWarnings=true | importExport=true | selectableRestore=true | bulkMaintenance=true | catalystMenus=true | whisperShortcuts=true | iOSGlobalHotkeys=unavailable | documentsIOSLimitations=true | needsAttention=true"
        )
    }

    func testKeyboardShortcutOfficialCoverageAuditSummaryFlagsMissingAreas() {
        let capability = TS3KeyboardShortcutCapabilitySummary(shortcuts: [
            TS3KeyboardShortcutBinding(
                actionId: "show-shortcuts",
                group: "Global",
                action: "Show Keyboard Shortcuts",
                defaultKeys: "Command-/",
                keys: "Command-/",
                isEnabled: true
            )
        ])
        let summary = TS3KeyboardShortcutOfficialCoverageAuditSummary(
            capabilitySummary: capability,
            hasEditableBindings: true,
            hasRecorder: false,
            hasValidationWarnings: false,
            hasDuplicateWarnings: false,
            hasImportExport: false,
            hasSelectableRestore: false,
            hasBulkMaintenance: true,
            hasCatalystMenus: true,
            hasWhisperShortcuts: false,
            documentsIOSLimitations: true
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 4)
        XCTAssertEqual(summary.missingOfficialAreaCount, 6)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=4/10 | missingOfficialAreas=6 | officialActions=24 | shortcuts=1 | enabled=1 | validEnabled=1 | invalidEnabled=0 | duplicateEnabled=0 | catalystMenu=1 | whisper=0 | editableBindings=true | recorder=false | validationWarnings=false | duplicateWarnings=false | importExport=false | selectableRestore=false | bulkMaintenance=true | catalystMenus=true | whisperShortcuts=false | iOSGlobalHotkeys=unavailable | documentsIOSLimitations=true | needsAttention=true"
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
        XCTAssertEqual(preview.selectableShortcutCount, 4)
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "action=Talk / Stop Talking | group=Voice | keys=Hyper-T | enabled=true | changed=true | invalid=true | duplicate=false",
                "action=Mute / Unmute Sound | group=Voice | keys=Command-Shift-S | enabled=false | changed=true | invalid=false | duplicate=false",
                "action=Open Chat | group=Messaging | keys=Command-Option-T | enabled=true | changed=true | invalid=false | duplicate=true",
                "action=Open Events | group=Messaging | keys=Command-Option-T | enabled=true | changed=true | invalid=false | duplicate=true"
            ]
        )
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
            Selectable shortcuts: 4
            Changed shortcuts: 4
            Disabled shortcuts: 1
            Invalid enabled shortcuts: 1
            Duplicate enabled shortcuts: 2
            Unknown imported shortcuts: 1
            candidate action=Talk / Stop Talking | group=Voice | keys=Hyper-T | enabled=true | changed=true | invalid=true | duplicate=false
            candidate action=Mute / Unmute Sound | group=Voice | keys=Command-Shift-S | enabled=false | changed=true | invalid=false | duplicate=false
            candidate action=Open Chat | group=Messaging | keys=Command-Option-T | enabled=true | changed=true | invalid=false | duplicate=true
            candidate action=Open Events | group=Messaging | keys=Command-Option-T | enabled=true | changed=true | invalid=false | duplicate=true
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

    @MainActor
    func testKeyboardShortcutRestoreImpactSummaryCountsSelectedRisks() throws {
        let model = TS3AppModel()
        model.resetKeyboardShortcuts()
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
            "actionId": "start-whisper-activation",
            "group": "Voice",
            "action": "Start Temporary Whisper",
            "defaultKeys": "Command-Option-H",
            "keys": "Command-Option-H",
            "isEnabled": true
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
        let summary = TS3KeyboardShortcutRestoreImpactSummary(
            preview: preview,
            selectedActionIds: ["open-chat", "open-events", "toggle-talk", "toggle-output-muted", "start-whisper-activation"]
        )

        XCTAssertEqual(summary.selectedShortcutCount, 5)
        XCTAssertEqual(summary.changedShortcutCount, 4)
        XCTAssertEqual(summary.enabledShortcutCount, 4)
        XCTAssertEqual(summary.disabledShortcutCount, 1)
        XCTAssertEqual(summary.invalidShortcutCount, 1)
        XCTAssertEqual(summary.duplicateShortcutCount, 2)
        XCTAssertEqual(summary.catalystMenuShortcutCount, 3)
        XCTAssertEqual(summary.whisperShortcutCount, 1)
        XCTAssertEqual(summary.unknownShortcutCount, 1)
        XCTAssertTrue(summary.hasSelection)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "selected=5 | changed=4 | enabled=4 | disabled=1 | invalid=1 | duplicate=2 | catalystMenu=3 | whisper=1 | unknownImported=1 | iOSGlobalHotkeys=unavailable | needsAttention=true"
        )
    }

    @MainActor
    func testKeyboardShortcutImportCanRestoreSelectedActionsOnly() throws {
        let model = TS3AppModel()
        model.resetKeyboardShortcuts()
        let openChat = try XCTUnwrap(model.keyboardShortcuts.first { $0.actionId == "open-chat" })
        let openEvents = try XCTUnwrap(model.keyboardShortcuts.first { $0.actionId == "open-events" })
        model.updateKeyboardShortcut(openChat, keys: "Command-Option-C", isEnabled: true)
        model.updateKeyboardShortcut(openEvents, keys: "Command-Option-E", isEnabled: false)
        let backupJSON = """
        [
          {
            "actionId": "open-chat",
            "group": "Messaging",
            "action": "Open Chat",
            "defaultKeys": "Command-Shift-T",
            "keys": "Command-Shift-X",
            "isEnabled": false
          },
          {
            "actionId": "open-events",
            "group": "Messaging",
            "action": "Open Events",
            "defaultKeys": "Command-Shift-E",
            "keys": "Command-Shift-Y",
            "isEnabled": true
          }
        ]
        """

        try model.importKeyboardShortcuts(
            from: Data(backupJSON.utf8),
            selectedActionIds: ["open-chat"]
        )

        let restoredChat = try XCTUnwrap(model.keyboardShortcuts.first { $0.actionId == "open-chat" })
        let preservedEvents = try XCTUnwrap(model.keyboardShortcuts.first { $0.actionId == "open-events" })
        XCTAssertEqual(restoredChat.keys, "Command-Shift-X")
        XCTAssertFalse(restoredChat.isEnabled)
        XCTAssertEqual(preservedEvents.keys, "Command-Option-E")
        XCTAssertFalse(preservedEvents.isEnabled)
    }
}
