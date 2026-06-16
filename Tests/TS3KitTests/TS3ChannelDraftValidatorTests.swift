import XCTest
@testable import TS3iOSApp

final class TS3ChannelDraftValidatorTests: XCTestCase {
    func testChannelDraftValidatorRejectsNonNumericOrder() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            neededTalkPower: "20",
            neededJoinPower: "25",
            neededSubscribePower: "10",
            neededModifyPower: "35",
            neededDeletePower: "40",
            neededDescriptionViewPower: "5",
            codecQuality: "10",
            codecLatencyFactor: "1",
            order: "after-lobby",
            deleteDelaySeconds: "3600",
            iconId: "456",
            maxClients: "12",
            maxClientsUnlimited: false,
            maxFamilyClients: "24",
            maxFamilyClientsUnlimited: false,
            maxFamilyClientsInherited: false
        )

        XCTAssertEqual(messages, ["Position must be numeric."])
    }

    func testChannelDraftValidatorRejectsNonNumericJoinPower() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            neededTalkPower: "",
            neededJoinPower: "join",
            neededSubscribePower: "",
            neededModifyPower: "",
            neededDeletePower: "",
            neededDescriptionViewPower: "",
            codecQuality: "",
            codecLatencyFactor: "",
            order: "",
            deleteDelaySeconds: "",
            iconId: "",
            maxClients: "",
            maxClientsUnlimited: true,
            maxFamilyClients: "",
            maxFamilyClientsUnlimited: true,
            maxFamilyClientsInherited: false
        )

        XCTAssertEqual(messages, ["Needed join power must be numeric."])
    }

    func testChannelDraftValidatorAcceptsOfficialEditableRanges() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            neededTalkPower: "",
            neededJoinPower: "",
            neededSubscribePower: "",
            neededModifyPower: "",
            neededDeletePower: "",
            neededDescriptionViewPower: "",
            codecQuality: "0",
            codecLatencyFactor: "10",
            order: "4",
            deleteDelaySeconds: "",
            iconId: "",
            maxClients: "",
            maxClientsUnlimited: true,
            maxFamilyClients: "",
            maxFamilyClientsUnlimited: true,
            maxFamilyClientsInherited: false
        )

        XCTAssertTrue(messages.isEmpty)
    }

    func testChannelDraftValidatorAcceptsOfficialTypeAndCodecAliases() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            channelType: "semi-permanent",
            neededTalkPower: "",
            neededJoinPower: "",
            neededSubscribePower: "",
            neededModifyPower: "",
            neededDeletePower: "",
            neededDescriptionViewPower: "",
            codec: "opus-music",
            codecQuality: "10",
            codecLatencyFactor: "2",
            bannerMode: "keep-aspect-ratio",
            order: "",
            deleteDelaySeconds: "",
            iconId: "",
            maxClients: "",
            maxClientsUnlimited: true,
            maxFamilyClients: "",
            maxFamilyClientsUnlimited: true,
            maxFamilyClientsInherited: false
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(TS3ChannelType.value(forDraft: "semi-permanent"), .semiPermanent)
        XCTAssertEqual(TS3ChannelCodec.value(forDraft: "opus-music"), TS3ChannelCodec.opusMusic.rawValue)
        XCTAssertEqual(TS3ChannelCodec.value(forDraft: "speex_uwb"), TS3ChannelCodec.speexUltraWideband.rawValue)
        XCTAssertEqual(TS3HostBannerMode.value(forDraft: "keep-aspect-ratio"), TS3HostBannerMode.keepAspect.rawValue)
    }

    func testChannelCodecConfigurationSummaryClassifiesProfilesAndAttentionState() {
        let highQualityVoice = TS3ChannelCodecConfigurationSummary(
            codec: TS3ChannelCodec.opusVoice.rawValue,
            codecQuality: 10,
            codecLatencyFactor: 2,
            isCodecUnencrypted: false
        )
        let lowLatencyVoice = TS3ChannelCodecConfigurationSummary(
            codec: TS3ChannelCodec.opusVoice.rawValue,
            codecQuality: 6,
            codecLatencyFactor: 1,
            isCodecUnencrypted: false
        )
        let riskyCompatibility = TS3ChannelCodecConfigurationSummary(
            codec: TS3ChannelCodec.speexWideband.rawValue,
            codecQuality: 11,
            codecLatencyFactor: 0,
            isCodecUnencrypted: true
        )

        XCTAssertEqual(highQualityVoice.profile, .highQuality)
        XCTAssertFalse(highQualityVoice.needsAttention)
        XCTAssertEqual(lowLatencyVoice.profile, .lowLatency)
        XCTAssertEqual(riskyCompatibility.profile, .compatibility)
        XCTAssertTrue(riskyCompatibility.hasInvalidQuality)
        XCTAssertTrue(riskyCompatibility.hasInvalidLatencyFactor)
        XCTAssertTrue(riskyCompatibility.usesLegacyCodec)
        XCTAssertTrue(riskyCompatibility.disablesVoiceEncryption)
        XCTAssertEqual(
            riskyCompatibility.clipboardSummary,
            "profile=compatibility | codec=1 | quality=11 | latencyFactor=0 | unencrypted=true | needsAttention=true"
        )
    }

    func testChannelLimitSummaryClassifiesDirectAndFamilyLimits() {
        let summary = TS3ChannelLimitSummary(channel: makeChannel(
            totalClients: 9,
            totalClientsFamily: 13,
            maxClients: 10,
            maxFamilyClients: 12,
            maxClientsUnlimited: false,
            maxFamilyClientsUnlimited: false,
            maxFamilyClientsInherited: false,
            deleteDelaySeconds: 3600,
            secondsEmpty: 42
        ))

        XCTAssertEqual(summary.directState, .nearLimit)
        XCTAssertEqual(summary.familyState, .overLimit)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "direct=9/10 | directState=nearLimit | family=13/12 | familyState=overLimit | deleteDelay=3600 | secondsEmpty=42 | needsAttention=true"
        )
    }

    func testChannelLimitSummaryHandlesUnlimitedAndInheritedLimits() {
        let summary = TS3ChannelLimitSummary(channel: makeChannel(
            totalClients: 50,
            totalClientsFamily: 60,
            maxClients: nil,
            maxFamilyClients: 10,
            maxClientsUnlimited: true,
            maxFamilyClientsUnlimited: false,
            maxFamilyClientsInherited: true
        ))

        XCTAssertEqual(summary.directState, .unlimited)
        XCTAssertEqual(summary.familyState, .unknown)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "direct=unlimited | directState=unlimited | family=inherited | familyState=unknown | deleteDelay=unknown | secondsEmpty=unknown | needsAttention=false"
        )
    }

    func testChannelPermissionGateSummaryTracksConfiguredInheritedAndHighestGates() {
        let summary = TS3ChannelPermissionGateSummary(
            neededTalkPower: 20,
            neededJoinPower: nil,
            neededSubscribePower: 5,
            neededModifyPower: 45,
            neededDeletePower: nil,
            neededDescriptionViewPower: nil
        )

        XCTAssertEqual(summary.configuredCount, 3)
        XCTAssertEqual(summary.inheritedCount, 3)
        XCTAssertEqual(summary.highestGate?.id, "i_channel_needed_modify_power")
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "configured=i_channel_needed_talk_power=20,i_channel_needed_subscribe_power=5,i_channel_needed_modify_power=45 | inherited=i_channel_needed_join_power,i_channel_needed_delete_power,i_channel_needed_description_view_power | highest=i_channel_needed_modify_power=45 | needsAttention=true"
        )
    }

    func testChannelEditorImpactSummaryCountsAreasValidationAndCodecWarnings() {
        let summary = TS3ChannelEditorImpactSummary(
            areaChangeCounts: [
                .channel: 3,
                .voice: 2,
                .permissionGates: 0,
                .limits: 1
            ],
            validationIssueCount: 1,
            codecWarningCount: 2
        )

        XCTAssertEqual(summary.totalChangeCount, 6)
        XCTAssertEqual(summary.affectedAreaCount, 3)
        XCTAssertEqual(summary.validationIssueCount, 1)
        XCTAssertEqual(summary.codecWarningCount, 2)
        XCTAssertTrue(summary.needsReview)
        XCTAssertEqual(
            summary.clipboardSummary,
            "changes=6 | affectedAreas=3 | validationIssues=1 | codecWarnings=2 | areas=channel:3,voice:2,limits:1 | needsReview=true"
        )
    }

    func testChannelEditorImpactSummaryOmitsEmptyAreasAndClampsIssueCounts() {
        let summary = TS3ChannelEditorImpactSummary(
            areaChangeCounts: [
                .channel: 0,
                .voice: -1
            ],
            validationIssueCount: -2,
            codecWarningCount: -3
        )

        XCTAssertEqual(summary.totalChangeCount, 0)
        XCTAssertEqual(summary.affectedAreaCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertEqual(summary.codecWarningCount, 0)
        XCTAssertFalse(summary.needsReview)
        XCTAssertEqual(
            summary.clipboardSummary,
            "changes=0 | affectedAreas=0 | validationIssues=0 | codecWarnings=0 | areas=none | needsReview=false"
        )
    }

    func testChannelEditorCoverageSummaryCountsCoveredChangedAreasAndWarnings() {
        let summary = TS3ChannelEditorCoverageSummary(
            coveredAreas: [
                .channel,
                .voice,
                .voice,
                .permissionGates
            ],
            changedAreaCounts: [
                .channel: 2,
                .voice: 1,
                .permissionGates: 0,
                .limits: 3
            ],
            validationIssueCount: 1,
            codecWarningCount: 2
        )

        XCTAssertEqual(summary.coveredAreaCount, 3)
        XCTAssertEqual(summary.totalOfficialAreaCount, 4)
        XCTAssertEqual(summary.uncoveredAreaCount, 1)
        XCTAssertEqual(summary.changedAreaCount, 3)
        XCTAssertEqual(summary.totalChangeCount, 6)
        XCTAssertEqual(summary.validationIssueCount, 1)
        XCTAssertEqual(summary.codecWarningCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "coveredAreas=3/4 | uncoveredAreas=1 | changedAreas=3 | changes=6 | validationIssues=1 | codecWarnings=2 | covered=channel,voice,permissionGates | changed=channel:2,voice:1,limits:3 | needsAttention=true"
        )
    }

    func testChannelEditorCoverageSummaryHandlesCompleteCleanCoverage() {
        let summary = TS3ChannelEditorCoverageSummary(
            changedAreaCounts: [:],
            validationIssueCount: -1,
            codecWarningCount: -2
        )

        XCTAssertEqual(summary.coveredAreaCount, 4)
        XCTAssertEqual(summary.totalOfficialAreaCount, 4)
        XCTAssertEqual(summary.uncoveredAreaCount, 0)
        XCTAssertEqual(summary.changedAreaCount, 0)
        XCTAssertEqual(summary.totalChangeCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertEqual(summary.codecWarningCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "coveredAreas=4/4 | uncoveredAreas=0 | changedAreas=0 | changes=0 | validationIssues=0 | codecWarnings=0 | covered=channel,voice,permissionGates,limits | changed=none | needsAttention=false"
        )
    }

    func testChannelEditorReviewSummaryDeduplicatesSensitiveChanges() {
        let summary = TS3ChannelEditorReviewSummary(
            reviewItems: [
                " Codec: Opus Voice -> Opus Music ",
                "Codec: Opus Voice -> Opus Music",
                "Needed Join Power: 0 -> 25"
            ],
            validationIssueCount: 1,
            codecWarningCount: 2
        )

        XCTAssertEqual(summary.reviewItems, [
            "Codec: Opus Voice -> Opus Music",
            "Needed Join Power: 0 -> 25"
        ])
        XCTAssertEqual(summary.sensitiveChangeCount, 2)
        XCTAssertEqual(summary.validationIssueCount, 1)
        XCTAssertEqual(summary.codecWarningCount, 2)
        XCTAssertEqual(summary.totalReviewCount, 5)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "sensitiveChanges=2 | validationIssues=1 | codecWarnings=2 | reviewItems=Codec: Opus Voice -> Opus Music || Needed Join Power: 0 -> 25 | needsAttention=true"
        )
    }

    func testChannelEditorReviewSummaryHandlesCleanDraft() {
        let summary = TS3ChannelEditorReviewSummary(
            reviewItems: ["", "   "],
            validationIssueCount: -1,
            codecWarningCount: -2
        )

        XCTAssertTrue(summary.reviewItems.isEmpty)
        XCTAssertEqual(summary.sensitiveChangeCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertEqual(summary.codecWarningCount, 0)
        XCTAssertEqual(summary.totalReviewCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "sensitiveChanges=0 | validationIssues=0 | codecWarnings=0 | reviewItems=none | needsAttention=false"
        )
    }

    func testChannelDraftValidatorRejectsInvalidTypeAndCodecAliases() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            channelType: "sticky",
            neededTalkPower: "",
            neededJoinPower: "",
            neededSubscribePower: "",
            neededModifyPower: "",
            neededDeletePower: "",
            neededDescriptionViewPower: "",
            codec: "lossless",
            codecQuality: "",
            codecLatencyFactor: "",
            bannerMode: "stretchy",
            order: "",
            deleteDelaySeconds: "",
            iconId: "",
            maxClients: "",
            maxClientsUnlimited: true,
            maxFamilyClients: "",
            maxFamilyClientsUnlimited: true,
            maxFamilyClientsInherited: false
        )

        XCTAssertEqual(
            messages,
            [
                "Channel type must be temporary, semi-permanent, or permanent.",
                "Codec must be Speex Narrowband, Speex Wideband, Speex Ultra-Wideband, CELT Mono, Opus Voice, Opus Music, or numeric.",
                "Banner mode must be no adjustment, ignore aspect ratio, keep aspect ratio, or numeric."
            ]
        )
    }

    func testChannelDraftValidatorReportsImportBlockingErrorsTogether() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "   ",
            channelType: "sticky",
            neededTalkPower: "voice",
            neededJoinPower: "join",
            neededSubscribePower: "subscribe",
            neededModifyPower: "modify",
            neededDeletePower: "delete",
            neededDescriptionViewPower: "view",
            codec: "lossless",
            codecQuality: "12",
            codecLatencyFactor: "0",
            bannerMode: "stretchy",
            order: "after-lobby",
            deleteDelaySeconds: "soon",
            iconId: "icon",
            maxClients: "",
            maxClientsUnlimited: false,
            maxFamilyClients: "",
            maxFamilyClientsUnlimited: false,
            maxFamilyClientsInherited: false
        )

        XCTAssertEqual(
            messages,
            [
                "Name is required before saving.",
                "Channel type must be temporary, semi-permanent, or permanent.",
                "Needed talk power must be numeric.",
                "Needed join power must be numeric.",
                "Needed subscribe power must be numeric.",
                "Needed modify power must be numeric.",
                "Needed delete power must be numeric.",
                "Needed description view power must be numeric.",
                "Codec must be Speex Narrowband, Speex Wideband, Speex Ultra-Wideband, CELT Mono, Opus Voice, Opus Music, or numeric.",
                "Codec quality must be between 0 and 10.",
                "Codec latency factor must be between 1 and 10.",
                "Banner mode must be no adjustment, ignore aspect ratio, keep aspect ratio, or numeric.",
                "Position must be numeric.",
                "Delete delay must be numeric.",
                "Icon ID must be numeric.",
                "Max clients is required when the client limit is not unlimited.",
                "Max family clients is required when the family limit is not inherited or unlimited."
            ]
        )
    }

    private func makeChannel(
        totalClients: Int?,
        totalClientsFamily: Int?,
        maxClients: Int?,
        maxFamilyClients: Int?,
        maxClientsUnlimited: Bool?,
        maxFamilyClientsUnlimited: Bool?,
        maxFamilyClientsInherited: Bool?,
        deleteDelaySeconds: Int? = nil,
        secondsEmpty: Int? = nil
    ) -> TS3ChannelSummary {
        TS3ChannelSummary(
            id: 12,
            name: "Raid Room",
            topic: nil,
            isDefault: false,
            isPasswordProtected: false,
            isPermanent: true,
            deleteDelaySeconds: deleteDelaySeconds,
            secondsEmpty: secondsEmpty,
            maxClients: maxClients,
            maxFamilyClients: maxFamilyClients,
            maxClientsUnlimited: maxClientsUnlimited,
            maxFamilyClientsUnlimited: maxFamilyClientsUnlimited,
            maxFamilyClientsInherited: maxFamilyClientsInherited,
            totalClients: totalClients,
            totalClientsFamily: totalClientsFamily,
            isCurrent: false
        )
    }
}
