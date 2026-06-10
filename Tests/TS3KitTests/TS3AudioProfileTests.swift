import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3AudioProfileTests: XCTestCase {
    func testAudioRouteDeviceSummariesAreCopyableAndAccessible() {
        let selectedDevice = TS3AudioRouteDeviceSummary(
            id: "built-in-mic",
            name: "iPhone Microphone",
            type: "MicrophoneBuiltIn",
            isSelected: true
        )
        let availableDevice = TS3AudioRouteDeviceSummary(
            id: "usb-headset",
            name: "USB Headset",
            type: "",
            isSelected: false
        )

        XCTAssertEqual(selectedDevice.displayName, "iPhone Microphone (MicrophoneBuiltIn)")
        XCTAssertEqual(selectedDevice.displaySummary, "iPhone Microphone (MicrophoneBuiltIn), selected")
        XCTAssertEqual(
            selectedDevice.clipboardSummary,
            "name=iPhone Microphone | type=MicrophoneBuiltIn | id=built-in-mic | state=selected"
        )
        XCTAssertEqual(
            selectedDevice.accessibilityValue,
            "selected. Type MicrophoneBuiltIn. Identifier built-in-mic"
        )

        XCTAssertEqual(availableDevice.displayName, "USB Headset")
        XCTAssertEqual(availableDevice.displaySummary, "USB Headset, available")
        XCTAssertEqual(
            availableDevice.clipboardSummary,
            "name=USB Headset | type=Unknown | id=usb-headset | state=available"
        )
        XCTAssertEqual(
            availableDevice.accessibilityValue,
            "available. Type Unknown. Identifier usb-headset"
        )
    }

    func testUserPlaybackPreferenceSummariesUseAuditableValues() {
        let preference = TS3UserPlaybackPreferenceSummary(
            key: "client-uid",
            nickname: "Morgan",
            volume: 0.65,
            isMuted: true,
            isOnline: false
        )

        XCTAssertEqual(preference.displayName, "Morgan")
        XCTAssertEqual(preference.displaySummary, "65%, muted, key client-uid")
        XCTAssertEqual(
            preference.clipboardSummary,
            "name=Morgan | key=client-uid | volume=65% | muted=true | state=saved"
        )
        XCTAssertEqual(
            preference.accessibilityValue,
            "Saved. Playback volume 65%. Muted. Key client-uid"
        )
    }

    func testAudioProfileSummariesUseAuditableValues() {
        let profile = TS3AudioProfile(
            id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            name: "Raid Voice",
            playbackVolume: 1.25,
            inputGain: 0.8,
            transmitMode: TS3AudioTransmitMode.voiceActivation.rawValue,
            voiceActivationThreshold: 0.045,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_030)
        )

        XCTAssertEqual(
            profile.displaySummary,
            "Voice Activation, input 80%, playback 125%, threshold 0.045"
        )
        XCTAssertEqual(
            profile.clipboardSummary,
            "name=Raid Voice | mode=Voice Activation | input=80% | playback=125% | threshold=0.045"
        )
        XCTAssertEqual(
            profile.accessibilityValue,
            "Voice Activation. Input gain 80%. Playback volume 125%. Voice activation threshold 0.045"
        )
    }

    @MainActor
    func testAudioProfileImportMergesByNameAndSanitizesValues() throws {
        let model = TS3AppModel()
        model.updatePlaybackVolume(1.2)
        model.updateInputGain(1.1)
        model.updateAudioTransmitMode(.pushToTalk)
        model.updateVoiceActivationThreshold(0.04)
        model.saveCurrentAudioProfile(name: "Raid")

        model.updatePlaybackVolume(0.8)
        model.updateInputGain(0.9)
        model.updateAudioTransmitMode(.continuous)
        model.updateVoiceActivationThreshold(0.03)
        model.saveCurrentAudioProfile(name: "Music")

        let importedProfiles = [
            TS3AudioProfile(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                name: " raid ",
                playbackVolume: 6,
                inputGain: -1,
                transmitMode: "invalid-mode",
                voiceActivationThreshold: 0,
                updatedAt: Date(timeIntervalSince1970: 1_700_000_010)
            ),
            TS3AudioProfile(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                name: "Voice Activation",
                playbackVolume: 2.5,
                inputGain: 1.7,
                transmitMode: TS3AudioTransmitMode.voiceActivation.rawValue,
                voiceActivationThreshold: 0.12,
                updatedAt: Date(timeIntervalSince1970: 1_700_000_020)
            )
        ]
        let data = try JSONEncoder().encode(importedProfiles)

        let importedCount = try model.importAudioProfiles(from: data)

        XCTAssertEqual(importedCount, 2)
        XCTAssertEqual(model.audioProfiles.count, 3)
        XCTAssertEqual(Set(model.audioProfiles.map(\.name)), ["Voice Activation", "raid", "Music"])
        XCTAssertFalse(model.audioProfiles.contains { $0.name == "Raid" })

        let replacedRaid = try XCTUnwrap(model.audioProfiles.first { $0.name == "raid" })
        XCTAssertEqual(replacedRaid.playbackVolume, 4)
        XCTAssertEqual(replacedRaid.inputGain, 0)
        XCTAssertEqual(replacedRaid.transmitMode, TS3AudioTransmitMode.pushToTalk.rawValue)
        XCTAssertEqual(replacedRaid.voiceActivationThreshold, 0.001)

        let voiceActivation = try XCTUnwrap(model.audioProfiles.first { $0.name == "Voice Activation" })
        XCTAssertEqual(voiceActivation.playbackVolume, 2.5)
        XCTAssertEqual(voiceActivation.inputGain, 1.7)
        XCTAssertEqual(voiceActivation.transmitMode, TS3AudioTransmitMode.voiceActivation.rawValue)
        XCTAssertEqual(voiceActivation.voiceActivationThreshold, 0.12)
    }
}
