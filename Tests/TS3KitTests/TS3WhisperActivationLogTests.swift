import XCTest
@testable import TS3iOSApp

final class TS3WhisperActivationLogTests: XCTestCase {
    func testWhisperPresetListSummaryDeduplicatesAndCountsVisiblePresets() throws {
        let channelId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000021"))
        let clientId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000022"))
        let mixedId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000023"))
        let emptyId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000024"))
        let latest = Date(timeIntervalSince1970: 1_700_000_000)
        let channelPreset = TS3WhisperPreset(
            id: channelId,
            name: "Channels",
            channelIds: [1, 1, 2, -1],
            clientIds: [],
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        let summary = TS3WhisperPresetListSummary(presets: [
            channelPreset,
            channelPreset,
            TS3WhisperPreset(
                id: clientId,
                name: "Users",
                channelIds: [],
                clientIds: [7, 7, 8, 0],
                updatedAt: Date(timeIntervalSince1970: 20)
            ),
            TS3WhisperPreset(
                id: mixedId,
                name: "Mixed",
                channelIds: [2, 3],
                clientIds: [8, 9],
                updatedAt: latest
            ),
            TS3WhisperPreset(
                id: emptyId,
                name: "Empty",
                channelIds: [],
                clientIds: [],
                updatedAt: Date(timeIntervalSince1970: 30)
            )
        ])

        XCTAssertEqual(summary.totalCount, 4)
        XCTAssertEqual(summary.channelOnlyCount, 1)
        XCTAssertEqual(summary.clientOnlyCount, 1)
        XCTAssertEqual(summary.mixedCount, 1)
        XCTAssertEqual(summary.emptyCount, 1)
        XCTAssertEqual(summary.totalChannelTargets, 4)
        XCTAssertEqual(summary.totalClientTargets, 4)
        XCTAssertEqual(summary.distinctChannelTargets, 3)
        XCTAssertEqual(summary.distinctClientTargets, 3)
        XCTAssertEqual(summary.largestTargetCount, 4)
        XCTAssertEqual(summary.latestUpdatedAt, latest)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "whisperPresets=4 | channelOnly=1 | clientOnly=1 | mixed=1 | empty=1 | channelTargets=4 | clientTargets=4 | distinctChannels=3 | distinctClients=3 | largestPresetTargets=4 | latestUpdated=2023-11-14T22:13:20Z | needsAttention=true"
        )
    }

    func testWhisperOfficialCoverageAuditSummaryCountsCoveredAreas() throws {
        let channelPreset = TS3WhisperPreset(
            id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000031")),
            name: "Channels",
            channelIds: [1, 2],
            clientIds: [],
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        let userPreset = TS3WhisperPreset(
            id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000032")),
            name: "Users",
            channelIds: [],
            clientIds: [7, 8],
            updatedAt: Date(timeIntervalSince1970: 20)
        )
        let presetSummary = TS3WhisperPresetListSummary(presets: [channelPreset, userPreset])

        let summary = TS3WhisperOfficialCoverageAuditSummary(
            presetSummary: presetSummary,
            routeDescription: "Whisper list: 2 channels, 2 users",
            hasActiveRoute: true,
            activationMode: .holdToWhisper,
            activationLogCount: 3,
            hasFilterPresets: true,
            selectedChannelCount: 2,
            selectedClientCount: 2,
            availableChannelCount: 5,
            availableClientCount: 4,
            availableServerGroupCount: 2,
            availableChannelGroupCount: 1
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 7)
        XCTAssertEqual(summary.officialAreaTotal, 7)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 16)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=7/7 | missingOfficialAreas=0 | officialActions=16 | routeActive=true | route=Whisper list: 2 channels, 2 users | activationMode=Hold to Whisper | activationEvents=3 | visiblePresets=2 | selectedChannels=2 | selectedClients=2 | availableChannels=5 | availableClients=4 | serverGroups=2 | channelGroups=1 | filterPresets=true | needsAttention=false"
        )
    }

    func testWhisperOfficialCoverageAuditSummaryFlagsMissingAreas() {
        let presetSummary = TS3WhisperPresetListSummary(presets: [])

        let summary = TS3WhisperOfficialCoverageAuditSummary(
            presetSummary: presetSummary,
            routeDescription: "Voice to current channel",
            hasActiveRoute: false,
            activationMode: .tapToToggle,
            activationLogCount: 0,
            hasFilterPresets: false,
            selectedChannelCount: 0,
            selectedClientCount: 0,
            availableChannelCount: 0,
            availableClientCount: 0,
            availableServerGroupCount: 0,
            availableChannelGroupCount: 0
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 1)
        XCTAssertEqual(summary.officialAreaTotal, 7)
        XCTAssertEqual(summary.missingOfficialAreaCount, 6)
        XCTAssertEqual(summary.officialActionCount, 16)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=1/7 | missingOfficialAreas=6 | officialActions=16 | routeActive=false | route=Voice to current channel | activationMode=Tap to Toggle | activationEvents=0 | visiblePresets=0 | selectedChannels=0 | selectedClients=0 | availableChannels=0 | availableClients=0 | serverGroups=0 | channelGroups=0 | filterPresets=false | needsAttention=true"
        )
    }

    func testWhisperPresetDeleteImpactSummaryCountsVisibleDeletionRisk() throws {
        let channelPreset = TS3WhisperPreset(
            id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000041")),
            name: "Channels",
            channelIds: [1, 1, 2, -1],
            clientIds: [],
            updatedAt: Date(timeIntervalSince1970: 10)
        )
        let summary = TS3WhisperPresetDeleteImpactSummary(
            presets: [
                channelPreset,
                channelPreset,
                TS3WhisperPreset(
                    id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000042")),
                    name: "Users",
                    channelIds: [],
                    clientIds: [7, 7, 8, 0],
                    updatedAt: Date(timeIntervalSince1970: 20)
                ),
                TS3WhisperPreset(
                    id: try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000043")),
                    name: "Mixed",
                    channelIds: [2, 3],
                    clientIds: [8, 9],
                    updatedAt: Date(timeIntervalSince1970: 30)
                )
            ],
            scope: .visible
        )

        XCTAssertEqual(summary.presetCount, 3)
        XCTAssertEqual(summary.listSummary.channelOnlyCount, 1)
        XCTAssertEqual(summary.listSummary.clientOnlyCount, 1)
        XCTAssertEqual(summary.listSummary.mixedCount, 1)
        XCTAssertEqual(summary.listSummary.emptyCount, 0)
        XCTAssertEqual(summary.targetReferenceCount, 8)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=visible | deleteWhisperPresets=3 | channelOnly=1 | clientOnly=1 | mixed=1 | empty=0 | channelTargets=4 | clientTargets=4 | distinctChannels=3 | distinctClients=3 | largestPresetTargets=4 | needsAttention=true"
        )
    }

    func testWhisperPresetDeleteImpactSummaryFlagsEmptyAndLargeDeletion() throws {
        let empty = TS3WhisperPresetDeleteImpactSummary(presets: [], scope: .visible)

        XCTAssertEqual(empty.presetCount, 0)
        XCTAssertTrue(empty.needsAttention)

        let largeDeletion = TS3WhisperPresetDeleteImpactSummary(
            presets: (1...10).map { index in
                TS3WhisperPreset(
                    name: "Preset \(index)",
                    channelIds: [],
                    clientIds: [index],
                    updatedAt: Date(timeIntervalSince1970: TimeInterval(index))
                )
            },
            scope: .visible
        )

        XCTAssertEqual(largeDeletion.presetCount, 10)
        XCTAssertTrue(largeDeletion.needsAttention)

        let emptyPreset = TS3WhisperPresetDeleteImpactSummary(
            presets: [
                TS3WhisperPreset(
                    name: "Empty",
                    channelIds: [],
                    clientIds: [],
                    updatedAt: Date(timeIntervalSince1970: 1)
                )
            ],
            scope: .single
        )

        XCTAssertEqual(emptyPreset.listSummary.emptyCount, 1)
        XCTAssertTrue(emptyPreset.needsAttention)
    }

    @MainActor
    func testWhisperPresetBackupPreviewSanitizesCandidates() throws {
        let existingId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        let newId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        let invalidId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000003"))
        let model = TS3AppModel()
        model.saveWhisperPreset(name: "Existing", channelIds: [1], clientIds: [])
        let backup = [
            TS3WhisperPreset(
                id: existingId,
                name: " Existing ",
                channelIds: [3, 3, -1],
                clientIds: [8, 0],
                updatedAt: Date(timeIntervalSince1970: 30)
            ),
            TS3WhisperPreset(
                id: newId,
                name: " Squad ",
                channelIds: [],
                clientIds: [11, 11, 12],
                updatedAt: Date(timeIntervalSince1970: 20)
            ),
            TS3WhisperPreset(
                id: invalidId,
                name: " Invalid ",
                channelIds: [],
                clientIds: [],
                updatedAt: Date(timeIntervalSince1970: 10)
            )
        ]
        let data = try JSONEncoder().encode(backup)

        let preview = try model.whisperPresetBackupPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=Existing | channels=1 | clients=1",
            "name=Squad | channels=0 | clients=2"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped whisper presets: 1"))
    }

    @MainActor
    func testWhisperPresetBackupImportCanRestoreSelectedPresets() throws {
        let selectedId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000011"))
        let unselectedId = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000012"))
        let suffix = UUID().uuidString
        let existingName = "Existing \(suffix)"
        let unselectedName = "New Backup \(suffix)"
        let model = TS3AppModel()
        model.saveWhisperPreset(name: existingName, channelIds: [1], clientIds: [])
        let backup = [
            TS3WhisperPreset(
                id: selectedId,
                name: " \(existingName) ",
                channelIds: [4, 4],
                clientIds: [7],
                updatedAt: Date(timeIntervalSince1970: 40)
            ),
            TS3WhisperPreset(
                id: unselectedId,
                name: unselectedName,
                channelIds: [9],
                clientIds: [],
                updatedAt: Date(timeIntervalSince1970: 50)
            )
        ]
        let data = try JSONEncoder().encode(backup)

        try model.importWhisperPresetBackup(from: data, selectedPresetIds: [selectedId])

        let restored = try XCTUnwrap(model.whisperPresets.first { $0.id == selectedId })
        XCTAssertEqual(restored.name, existingName)
        XCTAssertEqual(restored.channelIds, [4])
        XCTAssertEqual(restored.clientIds, [7])
        XCTAssertFalse(model.whisperPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    @MainActor
    func testWhisperActivationLogRecordsFailuresAndRouteChanges() throws {
        let model = TS3AppModel()

        model.beginCurrentWhisperActivation()
        model.enableWhisperToServer()

        XCTAssertEqual(model.whisperActivationLog.count, 2)
        XCTAssertEqual(model.whisperActivationLog.first?.action, "Route changed")
        XCTAssertEqual(model.whisperActivationLog.last?.action, "Start failed: no whisper target")

        let exported = String(data: model.whisperActivationLogData(), encoding: .utf8)
        XCTAssertTrue(try XCTUnwrap(exported).contains("Whisper to server"))

        model.clearWhisperActivationLog()

        XCTAssertTrue(model.whisperActivationLog.isEmpty)
        XCTAssertEqual(String(data: model.whisperActivationLogData(), encoding: .utf8), "")
    }

    @MainActor
    func testWhisperActivationLogKeepsMostRecentTwentyEvents() {
        let model = TS3AppModel()

        for index in 1...25 {
            model.enableWhisperToChannel(id: index)
        }

        XCTAssertEqual(model.whisperActivationLog.count, 20)
        XCTAssertEqual(model.whisperActivationLog.first?.routeDescription, "Whisper to Channel 25")
        XCTAssertEqual(model.whisperActivationLog.last?.routeDescription, "Whisper to Channel 6")
    }

    @MainActor
    func testWhisperActivationModeExportsAndImportsWithAudioSettings() throws {
        let model = TS3AppModel()

        model.updateWhisperActivationMode(.tapToToggle)

        let exported = String(data: try model.audioSettingsExportData(), encoding: .utf8)
        XCTAssertTrue(try XCTUnwrap(exported).contains("\"whisperActivationMode\" : \"tapToToggle\""))

        let imported = TS3AppModel()
        try imported.importAudioSettings(from: Data("""
        {
          "playbackVolume": 1.0,
          "inputGain": 1.0,
          "transmitMode": "pushToTalk",
          "voiceActivationThreshold": 0.03,
          "prefersSpeakerOutput": true,
          "whisperActivationMode": "tapToToggle"
        }
        """.utf8))

        XCTAssertEqual(imported.whisperActivationMode, .tapToToggle)
    }

    @MainActor
    func testLegacyAudioSettingsDefaultWhisperActivationModeToHold() throws {
        let model = TS3AppModel()

        try model.importAudioSettings(from: Data("""
        {
          "playbackVolume": 1.0,
          "inputGain": 1.0,
          "transmitMode": "pushToTalk",
          "voiceActivationThreshold": 0.03,
          "prefersSpeakerOutput": true
        }
        """.utf8))

        XCTAssertEqual(model.whisperActivationMode, .holdToWhisper)
    }
}
