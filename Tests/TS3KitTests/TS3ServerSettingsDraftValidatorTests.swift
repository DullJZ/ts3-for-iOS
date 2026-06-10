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
