import XCTest
@testable import TS3iOSApp

final class TS3ChannelDraftValidatorTests: XCTestCase {
    func testChannelDraftValidatorRejectsNonNumericOrder() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            neededTalkPower: "20",
            neededJoinPower: "25",
            neededSubscribePower: "10",
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

    func testChannelDraftValidatorRejectsInvalidTypeAndCodecAliases() {
        let messages = TS3ChannelDraftValidator.validationMessages(
            name: "Raid Room",
            channelType: "sticky",
            neededTalkPower: "",
            neededJoinPower: "",
            neededSubscribePower: "",
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
}
