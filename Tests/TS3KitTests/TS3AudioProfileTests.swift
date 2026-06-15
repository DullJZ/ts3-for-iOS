import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3AudioProfileTests: XCTestCase {
    func testVoiceActivationCalibrationSummaryReportsGateMarginAndRecommendation() {
        let openSummary = TS3VoiceActivationCalibrationSummary(
            inputLevel: 0.040,
            threshold: 0.030,
            isGateOpen: true
        )

        XCTAssertEqual(openSummary.suggestedThreshold, 0.054, accuracy: 0.0001)
        XCTAssertEqual(openSummary.margin, 0.010, accuracy: 0.0001)
        XCTAssertEqual(openSummary.marginText, "+0.010")
        XCTAssertEqual(openSummary.state, "open")
        XCTAssertEqual(openSummary.recommendation, "raise threshold if background noise opens the gate")
        XCTAssertEqual(
            openSummary.clipboardSummary,
            "input=0.040 | threshold=0.030 | margin=+0.010 | gate=open | suggestedThreshold=0.054 | recommendation=raise threshold if background noise opens the gate"
        )

        let closedSummary = TS3VoiceActivationCalibrationSummary(
            inputLevel: 0.020,
            threshold: 0.030,
            isGateOpen: false
        )

        XCTAssertEqual(closedSummary.marginText, "-0.010")
        XCTAssertEqual(closedSummary.state, "closed")
        XCTAssertEqual(closedSummary.recommendation, "lower threshold or increase input gain if speech does not open the gate")
    }

    func testVoiceActivationCalibrationSummaryHandlesIdleNearThresholdAndClamp() {
        let idleSummary = TS3VoiceActivationCalibrationSummary(
            inputLevel: 0,
            threshold: 0.030,
            isGateOpen: false
        )
        XCTAssertEqual(idleSummary.suggestedThreshold, 0.001, accuracy: 0.0001)
        XCTAssertEqual(idleSummary.recommendation, "capture idle")

        let nearThresholdSummary = TS3VoiceActivationCalibrationSummary(
            inputLevel: 0.031,
            threshold: 0.030,
            isGateOpen: true
        )
        XCTAssertTrue(nearThresholdSummary.isNearThreshold)
        XCTAssertEqual(nearThresholdSummary.recommendation, "near threshold")

        let loudSummary = TS3VoiceActivationCalibrationSummary(
            inputLevel: 0.8,
            threshold: 0.5,
            isGateOpen: true
        )
        XCTAssertEqual(loudSummary.suggestedThreshold, 0.5, accuracy: 0.0001)
    }

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
    func testAudioSettingsImportPreviewReportsSanitizedValues() throws {
        let model = TS3AppModel()
        let data = Data("""
        {
          "playbackVolume": 6,
          "inputGain": -1,
          "transmitMode": "invalid-mode",
          "voiceActivationThreshold": 0.8,
          "prefersSpeakerOutput": false,
          "whisperActivationMode": "invalid-whisper"
        }
        """.utf8)

        let preview = try model.audioSettingsImportPreview(from: data)

        XCTAssertEqual(preview.playbackVolumeText, "400%")
        XCTAssertEqual(preview.inputGainText, "0%")
        XCTAssertEqual(preview.transmitModeTitle, "Push To Talk")
        XCTAssertEqual(preview.voiceActivationThresholdText, "0.500")
        XCTAssertFalse(preview.prefersSpeakerOutput)
        XCTAssertEqual(preview.whisperActivationModeTitle, "Hold to Whisper")
        XCTAssertEqual(preview.adjustedSettingCount, 5)
        XCTAssertEqual(
            preview.adjustmentSummaries,
            ["playbackVolume", "inputGain", "transmitMode", "voiceActivationThreshold", "whisperActivationMode"]
        )
        XCTAssertEqual(
            preview.clipboardSummary,
            """
            Transmit mode: Push To Talk
            Playback volume: 400%
            Input gain: 0%
            Voice activation threshold: 0.500
            Default to speaker: No
            Whisper activation mode: Hold to Whisper
            Adjusted settings: playbackVolume,inputGain,transmitMode,voiceActivationThreshold,whisperActivationMode
            adjusted field=playbackVolume
            adjusted field=inputGain
            adjusted field=transmitMode
            adjusted field=voiceActivationThreshold
            adjusted field=whisperActivationMode
            """
        )

        try model.importAudioSettings(from: data)

        XCTAssertEqual(model.playbackVolume, 4)
        XCTAssertEqual(model.inputGain, 0)
        XCTAssertEqual(model.audioTransmitMode, .pushToTalk)
        XCTAssertEqual(model.voiceActivationThreshold, 0.5)
        XCTAssertFalse(model.prefersSpeakerOutput)
        XCTAssertEqual(model.whisperActivationMode, .holdToWhisper)
    }

    @MainActor
    func testAudioProfileImportMergesByNameAndSanitizesValues() throws {
        let model = TS3AppModel()
        model.deleteAudioProfiles(model.audioProfiles)
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
            ),
            TS3AudioProfile(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                name: "   ",
                playbackVolume: 1,
                inputGain: 1,
                transmitMode: TS3AudioTransmitMode.pushToTalk.rawValue,
                voiceActivationThreshold: 0.03,
                updatedAt: Date(timeIntervalSince1970: 1_700_000_030)
            )
        ]
        let data = try JSONEncoder().encode(importedProfiles)

        let preview = try model.audioProfilesImportPreview(from: data)

        XCTAssertEqual(preview.importedProfileCount, 3)
        XCTAssertEqual(preview.usableProfileCount, 2)
        XCTAssertEqual(preview.newProfileCount, 1)
        XCTAssertEqual(preview.replacedProfileCount, 1)
        XCTAssertEqual(preview.skippedProfileCount, 1)
        XCTAssertEqual(preview.adjustedProfileCount, 1)
        XCTAssertEqual(
            preview.adjustmentSummaries,
            ["adjusted name=raid fields=name,playback,input,mode,threshold"]
        )
        XCTAssertEqual(
            preview.profileSummaries,
            [
                "name=Voice Activation | mode=Voice Activation | input=170% | playback=250% | threshold=0.120",
                "name=raid | mode=Push To Talk | input=0% | playback=400% | threshold=0.001"
            ]
        )
        XCTAssertEqual(preview.candidates.map(\.id), ["voice activation", "raid"])
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "name=Voice Activation | mode=Voice Activation | input=170% | playback=250% | threshold=0.120",
                "name=raid | mode=Push To Talk | input=0% | playback=400% | threshold=0.001"
            ]
        )
        XCTAssertTrue(preview.containsProfile(id: "raid"))
        XCTAssertFalse(preview.containsProfile(id: "music"))
        XCTAssertEqual(
            preview.clipboardSummary,
            """
            Imported profiles: 3
            Usable profiles: 2
            New profiles: 1
            Replacing profiles: 1
            Skipped profiles: 1
            Adjusted profiles: 1
            adjusted name=raid fields=name,playback,input,mode,threshold
            name=Voice Activation | mode=Voice Activation | input=170% | playback=250% | threshold=0.120
            name=raid | mode=Push To Talk | input=0% | playback=400% | threshold=0.001
            """
        )
        XCTAssertTrue(preview.hasProfiles)

        let importedCount = try model.importAudioProfiles(from: data)

        XCTAssertEqual(importedCount, 3)
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

    @MainActor
    func testAudioProfileImportCanRestoreSelectedProfiles() throws {
        let model = TS3AppModel()
        model.deleteAudioProfiles(model.audioProfiles)
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

        let importedCount = try model.importAudioProfiles(from: data, selectedProfileIds: ["voice activation"])

        XCTAssertEqual(importedCount, 2)
        XCTAssertEqual(Set(model.audioProfiles.map(\.name)), ["Voice Activation", "Raid", "Music"])
        XCTAssertTrue(model.audioProfiles.contains { $0.name == "Raid" })

        let voiceActivation = try XCTUnwrap(model.audioProfiles.first { $0.name == "Voice Activation" })
        XCTAssertEqual(voiceActivation.playbackVolume, 2.5)
        XCTAssertEqual(voiceActivation.inputGain, 1.7)
        XCTAssertEqual(voiceActivation.transmitMode, TS3AudioTransmitMode.voiceActivation.rawValue)
        XCTAssertEqual(voiceActivation.voiceActivationThreshold, 0.12)
        XCTAssertEqual(model.lastError, nil)
        model.deleteAudioProfiles(model.audioProfiles)
    }

    @MainActor
    func testUserPlaybackImportPreviewReportsSanitizedPreferences() throws {
        let model = TS3AppModel()
        model.resetUserPlaybackPreferences()
        model.userPlaybackPreferences = [
            "uid:existing": TS3UserPlaybackPreference(volume: 0.5, isMuted: false)
        ]

        let importedPreferences = [
            " uid:existing ": TS3UserPlaybackPreference(volume: 6, isMuted: true),
            "client:muted": TS3UserPlaybackPreference(volume: 1, isMuted: true),
            "uid:new": TS3UserPlaybackPreference(volume: 0.25, isMuted: false),
            "uid:default": TS3UserPlaybackPreference(volume: 1, isMuted: false),
            "   ": TS3UserPlaybackPreference(volume: 0.5, isMuted: false)
        ]
        let data = try JSONEncoder().encode(importedPreferences)

        let preview = try model.userPlaybackPreferencesImportPreview(from: data)

        XCTAssertEqual(preview.importedPreferenceCount, 5)
        XCTAssertEqual(preview.usablePreferenceCount, 3)
        XCTAssertEqual(preview.newPreferenceCount, 2)
        XCTAssertEqual(preview.replacedPreferenceCount, 1)
        XCTAssertEqual(preview.skippedPreferenceCount, 2)
        XCTAssertEqual(preview.adjustedPreferenceCount, 1)
        XCTAssertEqual(preview.mutedPreferenceCount, 2)
        XCTAssertEqual(
            preview.adjustmentSummaries,
            ["adjusted key=uid:existing fields=key,volume"]
        )
        XCTAssertEqual(
            preview.preferenceSummaries,
            [
                "key=client:muted | volume=100% | muted=true",
                "key=uid:existing | volume=400% | muted=true",
                "key=uid:new | volume=25% | muted=false"
            ]
        )
        XCTAssertEqual(preview.candidates.map(\.id), ["client:muted", "uid:existing", "uid:new"])
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "key=client:muted | volume=100% | muted=true",
                "key=uid:existing | volume=400% | muted=true",
                "key=uid:new | volume=25% | muted=false"
            ]
        )
        XCTAssertTrue(preview.containsPreference(id: "uid:existing"))
        XCTAssertFalse(preview.containsPreference(id: "uid:default"))
        XCTAssertEqual(
            preview.clipboardSummary,
            """
            Imported playback preferences: 5
            Usable playback preferences: 3
            New playback preferences: 2
            Replacing playback preferences: 1
            Skipped playback preferences: 2
            Adjusted playback preferences: 1
            Muted playback preferences: 2
            adjusted key=uid:existing fields=key,volume
            key=client:muted | volume=100% | muted=true
            key=uid:existing | volume=400% | muted=true
            key=uid:new | volume=25% | muted=false
            """
        )
        XCTAssertTrue(preview.hasPreferences)

        try model.importUserPlaybackPreferences(from: data)

        XCTAssertEqual(model.userPlaybackPreferences.count, 3)
        XCTAssertEqual(model.userPlaybackPreferences["uid:existing"]?.volume, 4)
        XCTAssertEqual(model.userPlaybackPreferences["uid:existing"]?.isMuted, true)
        XCTAssertEqual(model.userPlaybackPreferences["client:muted"]?.volume, 1)
        XCTAssertEqual(model.userPlaybackPreferences["client:muted"]?.isMuted, true)
        XCTAssertEqual(model.userPlaybackPreferences["uid:new"]?.volume, 0.25)
        XCTAssertEqual(model.userPlaybackPreferences["uid:new"]?.isMuted, false)
        XCTAssertNil(model.userPlaybackPreferences["uid:default"])
    }

    @MainActor
    func testUserPlaybackImportCanRestoreSelectedPreferences() throws {
        let model = TS3AppModel()
        model.resetUserPlaybackPreferences()
        model.userPlaybackPreferences = [
            "uid:old": TS3UserPlaybackPreference(volume: 0.5, isMuted: false)
        ]
        let importedPreferences = [
            "uid:first": TS3UserPlaybackPreference(volume: 0.25, isMuted: false),
            "uid:second": TS3UserPlaybackPreference(volume: 2, isMuted: true),
            "client:third": TS3UserPlaybackPreference(volume: 6, isMuted: true)
        ]
        let data = try JSONEncoder().encode(importedPreferences)

        try model.importUserPlaybackPreferences(from: data, selectedPreferenceIds: ["uid:second", "client:third"])

        XCTAssertEqual(Set(model.userPlaybackPreferences.keys), ["uid:second", "client:third"])
        XCTAssertEqual(model.userPlaybackPreferences["uid:second"]?.volume, 2)
        XCTAssertEqual(model.userPlaybackPreferences["uid:second"]?.isMuted, true)
        XCTAssertEqual(model.userPlaybackPreferences["client:third"]?.volume, 4)
        XCTAssertEqual(model.userPlaybackPreferences["client:third"]?.isMuted, true)
        XCTAssertNil(model.userPlaybackPreferences["uid:first"])
        XCTAssertNil(model.userPlaybackPreferences["uid:old"])
        XCTAssertEqual(model.lastError, nil)
        model.resetUserPlaybackPreferences()
    }
}
