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

    func testVoiceActivationOfficialCoverageAuditSummaryCountsCoveredAreas() {
        let calibration = TS3VoiceActivationCalibrationSummary(
            inputLevel: 0.050,
            threshold: 0.030,
            isGateOpen: true
        )

        let summary = TS3VoiceActivationOfficialCoverageAuditSummary(
            transmitMode: .voiceActivation,
            calibrationSummary: calibration,
            savedProfileCount: 2,
            hasModeSelection: true,
            hasThresholdControl: true,
            hasLiveInputMeter: true,
            hasCalibrationAction: true,
            hasPresetCoverage: true,
            hasProfilePersistence: true,
            hasDiagnosticsSnapshot: true,
            hasSharedIOSCatalystSurface: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 8)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 8)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 12)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=8/8 | missingOfficialAreas=0 | officialActions=12 | mode=Voice Activation | threshold=0.030 | input=0.050 | gate=open | suggestedThreshold=0.068 | savedProfiles=2 | modeSelection=true | thresholdControl=true | liveMeter=true | calibrationAction=true | presets=true | profilePersistence=true | diagnostics=true | iosCatalystSurface=true | needsAttention=false"
        )
    }

    func testVoiceActivationOfficialCoverageAuditSummaryFlagsMissingAreasAndIdleInput() {
        let calibration = TS3VoiceActivationCalibrationSummary(
            inputLevel: 0,
            threshold: 0.030,
            isGateOpen: false
        )

        let summary = TS3VoiceActivationOfficialCoverageAuditSummary(
            transmitMode: .pushToTalk,
            calibrationSummary: calibration,
            savedProfileCount: 0,
            hasModeSelection: true,
            hasThresholdControl: false,
            hasLiveInputMeter: false,
            hasCalibrationAction: false,
            hasPresetCoverage: true,
            hasProfilePersistence: false,
            hasDiagnosticsSnapshot: true,
            hasSharedIOSCatalystSurface: true
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 4)
        XCTAssertEqual(summary.missingOfficialAreaCount, 4)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=4/8 | missingOfficialAreas=4 | officialActions=12 | mode=Push To Talk | threshold=0.030 | input=0.000 | gate=closed | suggestedThreshold=0.001 | savedProfiles=0 | modeSelection=true | thresholdControl=false | liveMeter=false | calibrationAction=false | presets=true | profilePersistence=false | diagnostics=true | iosCatalystSurface=true | needsAttention=true"
        )
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

    func testAudioDeviceProfileOfficialCoverageAuditSummaryCountsCoveredAreas() {
        let summary = TS3AudioDeviceProfileOfficialCoverageAuditSummary(
            inputDeviceCount: 2,
            savedProfileCount: 3,
            userPlaybackOverrideCount: 4,
            routeAvailabilityNoteCount: 0,
            hasRouteVisibility: true,
            hasInputDeviceSelection: true,
            hasRouteRefresh: true,
            hasSpeakerPreference: true,
            hasProfileSaveApply: true,
            hasProfileImportExport: true,
            hasUserPlaybackOverrides: true,
            hasUserPlaybackImportExport: true,
            hasDiagnosticsSnapshot: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 9)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 9)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 21)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=9/9 | missingOfficialAreas=0 | officialActions=21 | inputDevices=2 | savedProfiles=3 | userPlaybackOverrideCount=4 | routeNotes=0 | routeVisibility=true | inputSelection=true | routeRefresh=true | speakerPreference=true | profileSaveApply=true | profileImportExport=true | userPlaybackOverrides=true | userPlaybackImportExport=true | diagnostics=true | needsAttention=false"
        )
    }

    func testAudioDeviceProfileOfficialCoverageAuditSummaryFlagsRouteLimitationsAndMissingAreas() {
        let summary = TS3AudioDeviceProfileOfficialCoverageAuditSummary(
            inputDeviceCount: 0,
            savedProfileCount: 0,
            userPlaybackOverrideCount: 0,
            routeAvailabilityNoteCount: 2,
            hasRouteVisibility: true,
            hasInputDeviceSelection: false,
            hasRouteRefresh: true,
            hasSpeakerPreference: false,
            hasProfileSaveApply: false,
            hasProfileImportExport: false,
            hasUserPlaybackOverrides: true,
            hasUserPlaybackImportExport: false,
            hasDiagnosticsSnapshot: true
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 4)
        XCTAssertEqual(summary.missingOfficialAreaCount, 5)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=4/9 | missingOfficialAreas=5 | officialActions=21 | inputDevices=0 | savedProfiles=0 | userPlaybackOverrideCount=0 | routeNotes=2 | routeVisibility=true | inputSelection=false | routeRefresh=true | speakerPreference=false | profileSaveApply=false | profileImportExport=false | userPlaybackOverrides=true | userPlaybackImportExport=false | diagnostics=true | needsAttention=true"
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
        XCTAssertEqual(preview.candidates.first?.name, "Voice Activation")
        XCTAssertEqual(preview.candidates.first?.transmitMode, TS3AudioTransmitMode.voiceActivation.rawValue)
        XCTAssertEqual(preview.candidates.first?.playbackVolume, 2.5)
        XCTAssertEqual(preview.candidates.first?.inputGain, 1.7)
        XCTAssertEqual(preview.candidates.first?.voiceActivationThreshold, 0.12)
        XCTAssertFalse(preview.candidates.first?.isReplacing ?? true)
        XCTAssertFalse(preview.candidates.first?.isAdjusted ?? true)
        XCTAssertEqual(preview.candidates.last?.name, "raid")
        XCTAssertEqual(preview.candidates.last?.transmitMode, TS3AudioTransmitMode.pushToTalk.rawValue)
        XCTAssertTrue(preview.candidates.last?.isReplacing ?? false)
        XCTAssertTrue(preview.candidates.last?.isAdjusted ?? false)
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
    func testAudioProfileImportImpactSummaryCountsSelectedProfiles() throws {
        let model = TS3AppModel()
        model.deleteAudioProfiles(model.audioProfiles)
        model.updatePlaybackVolume(1.2)
        model.updateInputGain(1.1)
        model.updateAudioTransmitMode(.pushToTalk)
        model.updateVoiceActivationThreshold(0.04)
        model.saveCurrentAudioProfile(name: "Raid")

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
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                name: "Always On",
                playbackVolume: 0.8,
                inputGain: 0.9,
                transmitMode: TS3AudioTransmitMode.continuous.rawValue,
                voiceActivationThreshold: 0.03,
                updatedAt: Date(timeIntervalSince1970: 1_700_000_030)
            ),
            TS3AudioProfile(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                name: "   ",
                playbackVolume: 1,
                inputGain: 1,
                transmitMode: TS3AudioTransmitMode.pushToTalk.rawValue,
                voiceActivationThreshold: 0.03,
                updatedAt: Date(timeIntervalSince1970: 1_700_000_040)
            )
        ]
        let data = try JSONEncoder().encode(importedProfiles)

        let preview = try model.audioProfilesImportPreview(from: data)
        let summary = TS3AudioProfileImportImpactSummary(
            preview: preview,
            selectedProfileIds: Set(preview.candidates.map(\.id))
        )

        XCTAssertEqual(summary.selectedProfileCount, 3)
        XCTAssertEqual(summary.newProfileCount, 2)
        XCTAssertEqual(summary.replacedProfileCount, 1)
        XCTAssertEqual(summary.adjustedProfileCount, 1)
        XCTAssertEqual(summary.pushToTalkCount, 1)
        XCTAssertEqual(summary.voiceActivationCount, 1)
        XCTAssertEqual(summary.continuousCount, 1)
        XCTAssertEqual(summary.boostedPlaybackCount, 2)
        XCTAssertEqual(summary.boostedInputCount, 1)
        XCTAssertEqual(summary.skippedProfileCount, 1)
        XCTAssertTrue(summary.hasSelection)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "selected=3 | new=2 | replacing=1 | adjusted=1 | pushToTalk=1 | voiceActivation=1 | continuous=1 | boostedPlayback=2 | boostedInput=1 | skipped=1 | needsAttention=true"
        )

        model.deleteAudioProfiles(model.audioProfiles)
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
        XCTAssertEqual(preview.candidates.first?.volume, 1)
        XCTAssertTrue(preview.candidates.first?.isMuted ?? false)
        XCTAssertFalse(preview.candidates.first?.isReplacing ?? true)
        XCTAssertFalse(preview.candidates.first?.isAdjusted ?? true)
        XCTAssertEqual(preview.candidates[1].volume, 4)
        XCTAssertTrue(preview.candidates[1].isMuted)
        XCTAssertTrue(preview.candidates[1].isReplacing)
        XCTAssertTrue(preview.candidates[1].isAdjusted)
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
    func testUserPlaybackImportImpactSummaryCountsSelectedPreferences() throws {
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
        let summary = TS3UserPlaybackImportImpactSummary(
            preview: preview,
            selectedPreferenceIds: Set(preview.candidates.map(\.id))
        )

        XCTAssertEqual(summary.selectedPreferenceCount, 3)
        XCTAssertEqual(summary.newPreferenceCount, 2)
        XCTAssertEqual(summary.replacedPreferenceCount, 1)
        XCTAssertEqual(summary.mutedPreferenceCount, 2)
        XCTAssertEqual(summary.boostedPreferenceCount, 1)
        XCTAssertEqual(summary.loweredPreferenceCount, 1)
        XCTAssertEqual(summary.adjustedPreferenceCount, 1)
        XCTAssertEqual(summary.skippedPreferenceCount, 2)
        XCTAssertTrue(summary.hasSelection)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "selected=3 | new=2 | replacing=1 | muted=2 | boosted=1 | lowered=1 | adjusted=1 | skipped=2 | needsAttention=true"
        )

        model.resetUserPlaybackPreferences()
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
