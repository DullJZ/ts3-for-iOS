import XCTest
@testable import TS3iOSApp

final class TS3WhisperActivationLogTests: XCTestCase {
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
