import XCTest
@testable import TS3iOSApp

final class TS3WhisperActivationLogTests: XCTestCase {
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
