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
}
