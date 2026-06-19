import XCTest
@testable import TS3iOSApp

final class TS3ServerSettingsDraftValidatorTests: XCTestCase {
    func testServerSettingsDraftValidatorRejectsInvalidToggleAliases() {
        let messages = validationMessages(
            autostart: "maybe",
            logClient: "sometimes",
            weblistEnabled: "public"
        )

        XCTAssertEqual(
            messages,
            [
                "Autostart must be enabled, disabled, true, false, 1, or 0.",
                "Client log must be enabled, disabled, true, false, 1, or 0.",
                "Server list must be listed, hidden, true, false, 1, or 0."
            ]
        )
    }

    func testServerSettingsDraftValidatorAcceptsToggleAliasesAndEmptyValues() {
        let aliases: [String?] = [
            "enabled",
            "disabled",
            "listed",
            "hidden",
            "true",
            "false",
            "yes",
            "no",
            "1",
            "0",
            "",
            "   ",
            nil
        ]

        for alias in aliases {
            XCTAssertTrue(
                validationMessages(
                    autostart: alias,
                    logClient: alias,
                    logQuery: alias,
                    logChannel: alias,
                    logPermissions: alias,
                    logServer: alias,
                    logFileTransfer: alias,
                    weblistEnabled: alias
                ).isEmpty,
                "Expected alias \(String(describing: alias)) to be accepted."
            )
        }
    }

    func testServerSettingsDraftValidatorKeepsNumericDraftValidation() {
        let messages = validationMessages(port: "voice")

        XCTAssertEqual(messages, ["Server port must be numeric."])
    }

    func testServerSettingsDraftValidatorRejectsInvalidPluginBlock() {
        let messages = validationMessages(antiFloodPointsNeededPluginBlock: "plugins")

        XCTAssertEqual(messages, ["Anti-flood plugin block must be numeric."])
    }

    func testServerSettingsDraftValidatorAcceptsOfficialEnumAliases() {
        XCTAssertTrue(
            validationMessages(
                hostMessageMode: "modal-quit",
                hostBannerMode: "keep aspect ratio",
                codecEncryptionMode: "per-channel"
            ).isEmpty
        )
        XCTAssertEqual(TS3HostMessageMode.value(forDraft: "modal-quit"), 3)
        XCTAssertEqual(TS3HostBannerMode.value(forDraft: "keep aspect ratio"), 2)
        XCTAssertEqual(TS3CodecEncryptionMode.value(forDraft: "per-channel"), 0)
    }

    func testServerSettingsDraftValidatorRejectsInvalidEnumAliases() {
        let messages = validationMessages(
            hostMessageMode: "popup",
            hostBannerMode: "crop",
            codecEncryptionMode: "mandatory"
        )

        XCTAssertEqual(
            messages,
            [
                "Host message mode must be none, log, modal, modal quit, or numeric.",
                "Host banner mode must be no adjustment, ignore aspect ratio, keep aspect ratio, or numeric.",
                "Codec encryption mode must be per channel, disabled, enabled, or numeric."
            ]
        )
    }

    func testServerSettingsDraftValidatorAcceptsAbsoluteBrandingURLs() {
        XCTAssertTrue(
            validationMessages(
                hostBannerURL: "https://example.com/banner",
                hostBannerGraphicsURL: "https://example.com/banner.png",
                hostButtonURL: "ts3server://voice.example.com?port=9987",
                hostButtonGraphicsURL: "https://example.com/button.png"
            ).isEmpty
        )
    }

    func testServerSettingsDraftValidatorRejectsInvalidBrandingURLs() {
        let messages = validationMessages(
            hostBannerURL: "example.com/banner",
            hostBannerGraphicsURL: "https:///banner.png",
            hostButtonURL: "not a url",
            hostButtonGraphicsURL: "button.png"
        )

        XCTAssertEqual(
            messages,
            [
                "Banner link URL must be a valid absolute URL or empty.",
                "Banner image URL must be a valid absolute URL or empty.",
                "Button link URL must be a valid absolute URL or empty.",
                "Button image URL must be a valid absolute URL or empty."
            ]
        )
    }

    func testServerSettingsImpactSummaryCountsAreasAndValidationIssues() {
        let summary = TS3ServerSettingsImpactSummary(
            areaChangeCounts: [
                .general: 2,
                .hostBranding: 0,
                .limitsAndSecurity: 1,
                .defaultGroups: 1,
                .serverLogOptions: 3
            ],
            validationIssueCount: 2
        )

        XCTAssertEqual(summary.totalChangeCount, 7)
        XCTAssertEqual(summary.affectedAreaCount, 4)
        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertTrue(summary.needsReview)
        XCTAssertEqual(
            summary.clipboardSummary,
            "changes=7 | affectedAreas=4 | validationIssues=2 | areas=general:2,limitsAndSecurity:1,defaultGroups:1,serverLogOptions:3 | needsReview=true"
        )
    }

    func testServerSettingsImpactSummaryOmitsEmptyAreas() {
        let summary = TS3ServerSettingsImpactSummary(
            areaChangeCounts: [
                .general: 0,
                .hostBranding: -1
            ],
            validationIssueCount: -4
        )

        XCTAssertEqual(summary.totalChangeCount, 0)
        XCTAssertEqual(summary.affectedAreaCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertFalse(summary.needsReview)
        XCTAssertEqual(
            summary.clipboardSummary,
            "changes=0 | affectedAreas=0 | validationIssues=0 | areas=none | needsReview=false"
        )
    }

    func testServerSettingsCoverageSummaryCountsCoveredAndChangedAreas() {
        let summary = TS3ServerSettingsCoverageSummary(
            coveredAreas: [
                .general,
                .hostBranding,
                .hostBranding,
                .limitsAndSecurity,
                .defaultGroups
            ],
            changedAreaCounts: [
                .general: 2,
                .hostBranding: 0,
                .limitsAndSecurity: 1,
                .serverLogOptions: 3
            ],
            validationIssueCount: 2
        )

        XCTAssertEqual(summary.coveredAreaCount, 4)
        XCTAssertEqual(summary.totalOfficialAreaCount, 6)
        XCTAssertEqual(summary.uncoveredAreaCount, 2)
        XCTAssertEqual(summary.changedAreaCount, 3)
        XCTAssertEqual(summary.totalChangeCount, 6)
        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "coveredAreas=4/6 | uncoveredAreas=2 | changedAreas=3 | changes=6 | validationIssues=2 | covered=general,hostBranding,limitsAndSecurity,defaultGroups | changed=general:2,limitsAndSecurity:1,serverLogOptions:3 | needsAttention=true"
        )
    }

    func testServerSettingsCoverageSummaryHandlesCompleteCleanCoverage() {
        let summary = TS3ServerSettingsCoverageSummary(
            changedAreaCounts: [:],
            validationIssueCount: -1
        )

        XCTAssertEqual(summary.coveredAreaCount, 6)
        XCTAssertEqual(summary.totalOfficialAreaCount, 6)
        XCTAssertEqual(summary.uncoveredAreaCount, 0)
        XCTAssertEqual(summary.changedAreaCount, 0)
        XCTAssertEqual(summary.totalChangeCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "coveredAreas=6/6 | uncoveredAreas=0 | changedAreas=0 | changes=0 | validationIssues=0 | covered=general,hostBranding,limitsAndSecurity,defaultGroups,antiFloodAndComplaints,serverLogOptions | changed=none | needsAttention=false"
        )
    }

    func testServerSettingsFieldCoverageSummaryCountsTrackedFieldsAndChanges() {
        let summary = TS3ServerSettingsFieldCoverageSummary(
            areaFieldCounts: [
                .general: 11,
                .hostBranding: 9,
                .limitsAndSecurity: 9,
                .defaultGroups: 3,
                .antiFloodAndComplaints: 9,
                .serverLogOptions: 6
            ],
            changedAreaCounts: [
                .general: 2,
                .limitsAndSecurity: 1,
                .serverLogOptions: 3
            ],
            validationIssueCount: 2
        )

        XCTAssertEqual(summary.trackedFieldCount, 47)
        XCTAssertEqual(summary.changedFieldCount, 6)
        XCTAssertEqual(summary.trackedAreaCount, 6)
        XCTAssertEqual(summary.totalAreaCount, 6)
        XCTAssertEqual(summary.missingTrackedAreaCount, 0)
        XCTAssertEqual(summary.changedAreaCount, 3)
        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "trackedFields=47 | changedFields=6 | trackedAreas=6/6 | missingTrackedAreas=0 | changedAreas=3 | validationIssues=2 | areas=general:11/2,hostBranding:9/0,limitsAndSecurity:9/1,defaultGroups:3/0,antiFloodAndComplaints:9/0,serverLogOptions:6/3 | needsAttention=true"
        )
    }

    func testServerSettingsFieldCoverageSummaryFlagsMissingTrackedAreas() {
        let summary = TS3ServerSettingsFieldCoverageSummary(
            areaFieldCounts: [
                .general: 2,
                .hostBranding: 0,
                .limitsAndSecurity: -1
            ],
            changedAreaCounts: [
                .general: 1,
                .hostBranding: 4
            ],
            validationIssueCount: -2
        )

        XCTAssertEqual(summary.trackedFieldCount, 2)
        XCTAssertEqual(summary.changedFieldCount, 5)
        XCTAssertEqual(summary.trackedAreaCount, 1)
        XCTAssertEqual(summary.missingTrackedAreaCount, 5)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "trackedFields=2 | changedFields=5 | trackedAreas=1/6 | missingTrackedAreas=5 | changedAreas=2 | validationIssues=0 | areas=general:2/1 | needsAttention=true"
        )
    }

    func testServerSettingsNavigationSummaryOrdersChangedAreasAndPrimaryArea() {
        let summary = TS3ServerSettingsNavigationSummary(
            areaChangeCounts: [
                .general: 2,
                .hostBranding: 4,
                .limitsAndSecurity: 4,
                .defaultGroups: 1,
                .serverLogOptions: 0
            ],
            validationIssueCount: 3
        )

        XCTAssertEqual(summary.changedAreas, [
            .general,
            .hostBranding,
            .limitsAndSecurity,
            .defaultGroups
        ])
        XCTAssertEqual(summary.changedAreaCount, 4)
        XCTAssertEqual(summary.totalChangeCount, 11)
        XCTAssertEqual(summary.validationIssueCount, 3)
        XCTAssertEqual(summary.primaryArea, .hostBranding)
        XCTAssertTrue(summary.shouldReview)
        XCTAssertEqual(
            summary.clipboardSummary,
            "reviewAreas=4 | changes=11 | validationIssues=3 | primaryArea=hostBranding | areas=general:2,hostBranding:4,limitsAndSecurity:4,defaultGroups:1 | shouldReview=true"
        )
    }

    func testServerSettingsNavigationSummaryHandlesCleanDraft() {
        let summary = TS3ServerSettingsNavigationSummary(
            areaChangeCounts: [
                .general: 0,
                .hostBranding: -2
            ],
            validationIssueCount: -1
        )

        XCTAssertTrue(summary.changedAreas.isEmpty)
        XCTAssertEqual(summary.changedAreaCount, 0)
        XCTAssertEqual(summary.totalChangeCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertNil(summary.primaryArea)
        XCTAssertFalse(summary.shouldReview)
        XCTAssertEqual(
            summary.clipboardSummary,
            "reviewAreas=0 | changes=0 | validationIssues=0 | primaryArea=none | areas=none | shouldReview=false"
        )
    }

    func testServerSettingsReviewSummaryDeduplicatesSensitiveChanges() {
        let summary = TS3ServerSettingsReviewSummary(
            reviewItems: [
                " Server Port: 9987 -> 9988 ",
                "Server Port: 9987 -> 9988",
                "Password: Unchanged -> New Password Set"
            ],
            validationIssueCount: 2
        )

        XCTAssertEqual(summary.reviewItems, [
            "Server Port: 9987 -> 9988",
            "Password: Unchanged -> New Password Set"
        ])
        XCTAssertEqual(summary.sensitiveChangeCount, 2)
        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertEqual(summary.totalReviewCount, 4)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "sensitiveChanges=2 | validationIssues=2 | reviewItems=Server Port: 9987 -> 9988 || Password: Unchanged -> New Password Set | needsAttention=true"
        )
    }

    func testServerSettingsReviewSummaryHandlesCleanDraft() {
        let summary = TS3ServerSettingsReviewSummary(
            reviewItems: ["", "   "],
            validationIssueCount: -1
        )

        XCTAssertTrue(summary.reviewItems.isEmpty)
        XCTAssertEqual(summary.sensitiveChangeCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertEqual(summary.totalReviewCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "sensitiveChanges=0 | validationIssues=0 | reviewItems=none | needsAttention=false"
        )
    }

    func testServerSettingsOfficialImpactSummaryCountsAreasAndSensitiveChanges() {
        let summary = TS3ServerSettingsOfficialImpactSummary(
            areaChangeCounts: [
                .availability: 3,
                .accessControl: 2,
                .brandingVisibility: 1,
                .moderationSafety: 0,
                .loggingAudit: 4
            ],
            validationIssueCount: 2,
            sensitiveChangeCount: 5
        )

        XCTAssertEqual(summary.totalChangeCount, 10)
        XCTAssertEqual(summary.affectedAreaCount, 4)
        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertEqual(summary.sensitiveChangeCount, 5)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialChanges=10 | affectedOfficialAreas=4 | sensitiveChanges=5 | validationIssues=2 | areas=availability:3,accessControl:2,brandingVisibility:1,loggingAudit:4 | needsAttention=true"
        )
    }

    func testServerSettingsOfficialImpactSummaryOmitsEmptyAreasAndClampsCounts() {
        let summary = TS3ServerSettingsOfficialImpactSummary(
            areaChangeCounts: [
                .availability: 0,
                .accessControl: -1
            ],
            validationIssueCount: -2,
            sensitiveChangeCount: -3
        )

        XCTAssertEqual(summary.totalChangeCount, 0)
        XCTAssertEqual(summary.affectedAreaCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertEqual(summary.sensitiveChangeCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialChanges=0 | affectedOfficialAreas=0 | sensitiveChanges=0 | validationIssues=0 | areas=none | needsAttention=false"
        )
    }

    func testServerSettingsSaveReadinessSummaryCountsSatisfiedRequirements() {
        let summary = TS3ServerSettingsSaveReadinessSummary(
            impactSummary: TS3ServerSettingsImpactSummary(
                areaChangeCounts: [.general: 2],
                validationIssueCount: 0
            ),
            officialImpactSummary: TS3ServerSettingsOfficialImpactSummary(
                areaChangeCounts: [.brandingVisibility: 1],
                validationIssueCount: 0,
                sensitiveChangeCount: 0
            ),
            reviewSummary: TS3ServerSettingsReviewSummary(
                reviewItems: [],
                validationIssueCount: 0
            ),
            isConnected: true
        )

        XCTAssertEqual(summary.satisfiedRequirementCount, 5)
        XCTAssertEqual(summary.totalRequirementCount, 5)
        XCTAssertEqual(summary.missingRequirementCount, 0)
        XCTAssertEqual(summary.missingRequirements, [])
        XCTAssertTrue(summary.canSave)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "saveReadiness=5/5 | missingRequirements=0 | canSave=true | changes=2 | officialChanges=1 | affectedOfficialAreas=1 | sensitiveChanges=0 | validationIssues=0 | requirements=connected:true,changedDraft:true,validationClean:true,officialImpactAudit:true,sensitiveReview:true | missing=none | needsAttention=false"
        )
    }

    func testServerSettingsSaveReadinessSummaryFlagsBlockedDraft() {
        let summary = TS3ServerSettingsSaveReadinessSummary(
            impactSummary: TS3ServerSettingsImpactSummary(
                areaChangeCounts: [:],
                validationIssueCount: 2
            ),
            officialImpactSummary: TS3ServerSettingsOfficialImpactSummary(
                areaChangeCounts: [:],
                validationIssueCount: 2,
                sensitiveChangeCount: 0
            ),
            reviewSummary: TS3ServerSettingsReviewSummary(
                reviewItems: [],
                validationIssueCount: 2
            ),
            isConnected: false
        )

        XCTAssertEqual(summary.satisfiedRequirementCount, 2)
        XCTAssertEqual(summary.missingRequirementCount, 3)
        XCTAssertEqual(summary.missingRequirements, [.connected, .changedDraft, .validationClean])
        XCTAssertFalse(summary.canSave)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "saveReadiness=2/5 | missingRequirements=3 | canSave=false | changes=0 | officialChanges=0 | affectedOfficialAreas=0 | sensitiveChanges=0 | validationIssues=2 | requirements=connected:false,changedDraft:false,validationClean:false,officialImpactAudit:true,sensitiveReview:true | missing=connected,changedDraft,validationClean | needsAttention=true"
        )
    }

    func testServerSettingsSaveReadinessSummaryFlagsMissingOfficialImpactAudit() {
        let summary = TS3ServerSettingsSaveReadinessSummary(
            impactSummary: TS3ServerSettingsImpactSummary(
                areaChangeCounts: [.general: 1],
                validationIssueCount: 0
            ),
            officialImpactSummary: TS3ServerSettingsOfficialImpactSummary(
                areaChangeCounts: [:],
                validationIssueCount: 0,
                sensitiveChangeCount: 0
            ),
            reviewSummary: TS3ServerSettingsReviewSummary(
                reviewItems: [],
                validationIssueCount: 0
            ),
            isConnected: true
        )

        XCTAssertEqual(summary.satisfiedRequirementCount, 4)
        XCTAssertEqual(summary.missingRequirementCount, 1)
        XCTAssertEqual(summary.missingRequirements, [.officialImpactAudit])
        XCTAssertTrue(summary.canSave)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "saveReadiness=4/5 | missingRequirements=1 | canSave=true | changes=1 | officialChanges=0 | affectedOfficialAreas=0 | sensitiveChanges=0 | validationIssues=0 | requirements=connected:true,changedDraft:true,validationClean:true,officialImpactAudit:false,sensitiveReview:true | missing=officialImpactAudit | needsAttention=true"
        )
    }

    func testServerSettingsDraftImportImpactSummaryCountsOfficialAndSensitiveChanges() {
        let impact = TS3ServerSettingsImpactSummary(
            areaChangeCounts: [
                .general: 2,
                .limitsAndSecurity: 1,
                .serverLogOptions: 1
            ],
            validationIssueCount: 0
        )
        let official = TS3ServerSettingsOfficialImpactSummary(
            areaChangeCounts: [
                .availability: 2,
                .accessControl: 1,
                .loggingAudit: 1
            ],
            validationIssueCount: 0,
            sensitiveChangeCount: 2
        )
        let review = TS3ServerSettingsReviewSummary(
            reviewItems: ["Server port: 9987 -> 9988", "Needed security level: 8 -> 12"],
            validationIssueCount: 0
        )

        let summary = TS3ServerSettingsDraftImportImpactSummary(
            impactSummary: impact,
            officialImpactSummary: official,
            reviewSummary: review
        )

        XCTAssertEqual(summary.totalChangeCount, 4)
        XCTAssertEqual(summary.editorAreaCount, 3)
        XCTAssertEqual(summary.officialAreaCount, 3)
        XCTAssertEqual(summary.sensitiveChangeCount, 2)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertTrue(summary.canImport)
        XCTAssertTrue(summary.appliesOnSave)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "changes=4 | editorAreas=3 | officialAreas=3 | sensitiveChanges=2 | validationIssues=0 | canImport=true | appliesOnSave=true | needsAttention=true"
        )
    }

    func testServerSettingsDraftImportImpactSummaryBlocksInvalidDraft() {
        let impact = TS3ServerSettingsImpactSummary(
            areaChangeCounts: [:],
            validationIssueCount: 1
        )
        let official = TS3ServerSettingsOfficialImpactSummary(
            areaChangeCounts: [:],
            validationIssueCount: 2,
            sensitiveChangeCount: 0
        )
        let review = TS3ServerSettingsReviewSummary(
            reviewItems: [],
            validationIssueCount: 0
        )

        let summary = TS3ServerSettingsDraftImportImpactSummary(
            impactSummary: impact,
            officialImpactSummary: official,
            reviewSummary: review
        )

        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertFalse(summary.canImport)
        XCTAssertFalse(summary.appliesOnSave)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "changes=0 | editorAreas=0 | officialAreas=0 | sensitiveChanges=0 | validationIssues=2 | canImport=false | appliesOnSave=false | needsAttention=true"
        )
    }

    private func validationMessages(
        name: String = "Guild Voice",
        port: String = "9987",
        autostart: String? = nil,
        maxClients: String = "32",
        reservedSlots: String = "2",
        hostMessageMode: String = "0",
        hostBannerURL: String = "",
        hostBannerGraphicsURL: String = "",
        hostBannerMode: String = "",
        hostBannerGraphicsInterval: String = "",
        hostButtonURL: String = "",
        hostButtonGraphicsURL: String = "",
        iconId: String = "",
        downloadQuota: String = "",
        uploadQuota: String = "",
        maxDownloadTotalBandwidth: String = "",
        maxUploadTotalBandwidth: String = "",
        complainAutoBanCount: String = "",
        complainAutoBanTime: String = "",
        complainRemoveTime: String = "",
        minClientsInChannelBeforeForcedSilence: String = "",
        prioritySpeakerDimmModificator: String = "",
        antiFloodPointsTickReduce: String = "",
        antiFloodPointsNeededCommandBlock: String = "",
        antiFloodPointsNeededIPBlock: String = "",
        antiFloodPointsNeededPluginBlock: String = "",
        logClient: String? = nil,
        logQuery: String? = nil,
        logChannel: String? = nil,
        logPermissions: String? = nil,
        logServer: String? = nil,
        logFileTransfer: String? = nil,
        weblistEnabled: String? = nil,
        codecEncryptionMode: String = "",
        defaultServerGroupId: String = "",
        defaultChannelGroupId: String = "",
        defaultChannelAdminGroupId: String = "",
        neededIdentitySecurityLevel: String = "",
        minClientVersion: String = "",
        minAndroidVersion: String = "",
        minIOSVersion: String = ""
    ) -> [String] {
        TS3ServerSettingsDraftValidator.validationMessages(
            name: name,
            port: port,
            autostart: autostart,
            maxClients: maxClients,
            reservedSlots: reservedSlots,
            hostMessageMode: hostMessageMode,
            hostBannerURL: hostBannerURL,
            hostBannerGraphicsURL: hostBannerGraphicsURL,
            hostBannerMode: hostBannerMode,
            hostBannerGraphicsInterval: hostBannerGraphicsInterval,
            hostButtonURL: hostButtonURL,
            hostButtonGraphicsURL: hostButtonGraphicsURL,
            iconId: iconId,
            downloadQuota: downloadQuota,
            uploadQuota: uploadQuota,
            maxDownloadTotalBandwidth: maxDownloadTotalBandwidth,
            maxUploadTotalBandwidth: maxUploadTotalBandwidth,
            complainAutoBanCount: complainAutoBanCount,
            complainAutoBanTime: complainAutoBanTime,
            complainRemoveTime: complainRemoveTime,
            minClientsInChannelBeforeForcedSilence: minClientsInChannelBeforeForcedSilence,
            prioritySpeakerDimmModificator: prioritySpeakerDimmModificator,
            antiFloodPointsTickReduce: antiFloodPointsTickReduce,
            antiFloodPointsNeededCommandBlock: antiFloodPointsNeededCommandBlock,
            antiFloodPointsNeededIPBlock: antiFloodPointsNeededIPBlock,
            antiFloodPointsNeededPluginBlock: antiFloodPointsNeededPluginBlock,
            logClient: logClient,
            logQuery: logQuery,
            logChannel: logChannel,
            logPermissions: logPermissions,
            logServer: logServer,
            logFileTransfer: logFileTransfer,
            weblistEnabled: weblistEnabled,
            codecEncryptionMode: codecEncryptionMode,
            defaultServerGroupId: defaultServerGroupId,
            defaultChannelGroupId: defaultChannelGroupId,
            defaultChannelAdminGroupId: defaultChannelAdminGroupId,
            neededIdentitySecurityLevel: neededIdentitySecurityLevel,
            minClientVersion: minClientVersion,
            minAndroidVersion: minAndroidVersion,
            minIOSVersion: minIOSVersion
        )
    }
}
