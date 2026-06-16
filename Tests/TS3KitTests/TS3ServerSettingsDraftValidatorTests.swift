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

    private func validationMessages(
        name: String = "Guild Voice",
        port: String = "9987",
        autostart: String? = nil,
        maxClients: String = "32",
        reservedSlots: String = "2",
        hostMessageMode: String = "0",
        hostBannerMode: String = "",
        hostBannerGraphicsInterval: String = "",
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
            hostBannerMode: hostBannerMode,
            hostBannerGraphicsInterval: hostBannerGraphicsInterval,
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
