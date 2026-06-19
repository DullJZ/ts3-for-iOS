import XCTest
@testable import TS3Kit

final class TS3CommandTests: XCTestCase {
    func testStringEscapingRoundTripsProtocolSpecialCharacters() throws {
        let value = #" leading / path | slash \ "# + "\t\n\r\u{000C}" + " trailing "

        let escaped = TS3String.escape(value)
        let unescaped = try TS3String.unescape(escaped)

        XCTAssertEqual(unescaped, value)
    }

    func testSingleParameterBuildPreservesIntentionalWhitespace() {
        let parameter = TS3CommandSingleParameter(name: "msg", value: "  spaced text  ")

        XCTAssertEqual(parameter.build(), "msg=\\s\\sspaced\\stext\\s\\s")
    }

    func testParserKeepsExplicitEmptyValues() throws {
        let command = try TS3MultiCommand.parse("clientupdate client_away_message=")
            .simplifyOne()

        XCTAssertEqual(command.get("client_away_message")?.value, "")
    }

    func testParserPropagatesFirstMultiCommandParameters() throws {
        let multi = try TS3MultiCommand.parse("notifyclientmoved clid=7 ctid=2 reasonmsg=hello\\sworld|clid=9")

        XCTAssertEqual(multi.commands.count, 2)
        XCTAssertEqual(multi.commands[0].get("reasonmsg")?.value, "hello world")
        XCTAssertEqual(multi.commands[1].get("ctid")?.value, "2")
        XCTAssertEqual(multi.commands[1].get("reasonmsg")?.value, "hello world")
    }

    func testBanDeleteCommandUsesServerQueryName() {
        let command = TS3SingleCommand(name: "bandel", parameters: [
            TS3CommandSingleParameter(name: "banid", value: "42")
        ])

        XCTAssertEqual(command.build(), "bandel banid=42")
    }

    func testServerGroupPermissionCommandBuildsOfficialParameters() {
        let command = TS3SingleCommand(name: "servergroupaddperm", parameters: [
            TS3CommandSingleParameter(name: "sgid", value: "6"),
            TS3CommandSingleParameter(name: "permsid", value: "i_client_kick_from_server_power"),
            TS3CommandSingleParameter(name: "permvalue", value: "75"),
            TS3CommandSingleParameter(name: "permnegated", value: "0"),
            TS3CommandSingleParameter(name: "permskip", value: "1")
        ])

        XCTAssertEqual(
            command.build(),
            "servergroupaddperm sgid=6 permsid=i_client_kick_from_server_power permvalue=75 permnegated=0 permskip=1"
        )
    }

    func testChannelClientPermissionCommandBuildsOfficialParameters() {
        let command = TS3SingleCommand(name: "channelclientaddperm", parameters: [
            TS3CommandSingleParameter(name: "cid", value: "12"),
            TS3CommandSingleParameter(name: "cldbid", value: "44"),
            TS3CommandSingleParameter(name: "permsid", value: "b_client_is_priority_speaker"),
            TS3CommandSingleParameter(name: "permvalue", value: "1"),
            TS3CommandSingleParameter(name: "permskip", value: "0")
        ])

        XCTAssertEqual(
            command.build(),
            "channelclientaddperm cid=12 cldbid=44 permsid=b_client_is_priority_speaker permvalue=1 permskip=0"
        )
    }

    func testPermissionParserKeepsInheritanceFlags() throws {
        let command = try TS3MultiCommand.parse(
            "channelgrouppermlist permsid=i_client_needed_kick_from_channel_power permvalue=50 permnegated=1 permskip=1"
        ).simplifyOne()

        let permission = TS3Client.permission(from: command)

        XCTAssertEqual(permission?.name, "i_client_needed_kick_from_channel_power")
        XCTAssertEqual(permission?.value, 50)
        XCTAssertEqual(permission?.isNegated, true)
        XCTAssertEqual(permission?.isSkipped, true)
    }

    func testChannelParserKeepsOfficialInfoAndPopulationFields() throws {
        let command = try TS3MultiCommand.parse(
            """
            channelinfo cid=12 pid=1 channel_order=3 channel_name=Raid\\sRoom channel_unique_identifier=abc123 channel_name_phonetic=raid channel_topic=Tonight channel_description=Bring\\sbuffs channel_filepath=files\\/raid channel_banner_gfx_url=https:\\/\\/example.com\\/raid.png channel_banner_mode=2 channel_flag_default=0 channel_flag_password=1 channel_flag_permanent=1 channel_flag_semi_permanent=0 channel_forced_silence=1 channel_needed_talk_power=20 channel_needed_join_power=25 channel_needed_subscribe_power=10 channel_needed_modify_power=35 channel_needed_delete_power=40 channel_needed_description_view_power=30 channel_codec=4 channel_codec_quality=10 channel_codec_latency_factor=1 channel_codec_is_unencrypted=0 channel_delete_delay=3600 channel_seconds_empty=42 channel_maxclients=12 channel_maxfamilyclients=24 channel_flag_maxclients_unlimited=0 channel_flag_maxfamilyclients_unlimited=0 channel_flag_maxfamilyclients_inherited=1 channel_icon_id=456 total_clients=7 total_clients_family=19 channel_flag_are_subscribed=1
            """
        ).simplifyOne()

        let channel = try XCTUnwrap(TS3Client.channel(from: command))

        XCTAssertEqual(channel.id, 12)
        XCTAssertEqual(channel.parentId, 1)
        XCTAssertEqual(channel.order, 3)
        XCTAssertEqual(channel.name, "Raid Room")
        XCTAssertEqual(channel.uniqueIdentifier, "abc123")
        XCTAssertEqual(channel.phoneticName, "raid")
        XCTAssertEqual(channel.topic, "Tonight")
        XCTAssertEqual(channel.description, "Bring buffs")
        XCTAssertEqual(channel.filePath, "files/raid")
        XCTAssertEqual(channel.bannerGraphicsURL, "https://example.com/raid.png")
        XCTAssertEqual(channel.bannerMode, 2)
        XCTAssertEqual(channel.isDefault, false)
        XCTAssertEqual(channel.isPasswordProtected, true)
        XCTAssertEqual(channel.isPermanent, true)
        XCTAssertEqual(channel.isSemiPermanent, false)
        XCTAssertEqual(channel.isForcedSilence, true)
        XCTAssertEqual(channel.neededTalkPower, 20)
        XCTAssertEqual(channel.neededJoinPower, 25)
        XCTAssertEqual(channel.neededSubscribePower, 10)
        XCTAssertEqual(channel.neededModifyPower, 35)
        XCTAssertEqual(channel.neededDeletePower, 40)
        XCTAssertEqual(channel.neededDescriptionViewPower, 30)
        XCTAssertEqual(channel.codec, 4)
        XCTAssertEqual(channel.codecQuality, 10)
        XCTAssertEqual(channel.codecLatencyFactor, 1)
        XCTAssertEqual(channel.isCodecUnencrypted, false)
        XCTAssertEqual(channel.deleteDelaySeconds, 3600)
        XCTAssertEqual(channel.secondsEmpty, 42)
        XCTAssertEqual(channel.maxClients, 12)
        XCTAssertEqual(channel.maxFamilyClients, 24)
        XCTAssertEqual(channel.maxClientsUnlimited, false)
        XCTAssertEqual(channel.maxFamilyClientsUnlimited, false)
        XCTAssertEqual(channel.maxFamilyClientsInherited, true)
        XCTAssertEqual(channel.iconId, 456)
        XCTAssertEqual(channel.totalClients, 7)
        XCTAssertEqual(channel.totalClientsFamily, 19)
        XCTAssertEqual(channel.isSubscribed, true)
    }

    func testChannelCreateCommandBuildsOfficialAdvancedParameters() {
        let command = TS3Client.channelCreateCommand(
            name: "Raid Room",
            parentId: 5,
            permanent: false,
            semiPermanent: true,
            phoneticName: "raid",
            topic: "Tonight",
            description: "Bring buffs | food",
            filePath: "files/raid",
            password: "room pass",
            codec: 4,
            codecQuality: 10,
            codecLatencyFactor: 1,
            isCodecUnencrypted: false,
            bannerGraphicsURL: "https://example.com/banner.png",
            bannerMode: 2,
            neededTalkPower: 20,
            neededJoinPower: 25,
            neededSubscribePower: 10,
            neededModifyPower: 35,
            neededDeletePower: 40,
            neededDescriptionViewPower: 30,
            order: 4,
            deleteDelaySeconds: 3600,
            maxClients: 12,
            maxFamilyClients: 24,
            maxClientsUnlimited: false,
            maxFamilyClientsUnlimited: false,
            maxFamilyClientsInherited: true,
            iconId: 456
        )

        XCTAssertEqual(
            command.build(),
            "channelcreate channel_name=Raid\\sRoom cpid=5 channel_name_phonetic=raid channel_topic=Tonight channel_description=Bring\\sbuffs\\s\\p\\sfood channel_filepath=files\\/raid channel_password=room\\spass channel_needed_talk_power=20 channel_needed_join_power=25 channel_needed_subscribe_power=10 channel_needed_modify_power=35 channel_needed_delete_power=40 channel_needed_description_view_power=30 channel_order=4 channel_codec=4 channel_codec_quality=10 channel_codec_latency_factor=1 channel_codec_is_unencrypted=0 channel_banner_gfx_url=https:\\/\\/example.com\\/banner.png channel_banner_mode=2 channel_delete_delay=3600 channel_maxclients=12 channel_maxfamilyclients=24 channel_flag_maxclients_unlimited=0 channel_flag_maxfamilyclients_unlimited=0 channel_flag_maxfamilyclients_inherited=1 channel_icon_id=456 channel_flag_semi_permanent=1"
        )
    }

    func testChannelCreateCommandOmitsEmptyPassword() {
        let command = TS3Client.channelCreateCommand(
            name: "Open Room",
            parentId: nil,
            permanent: true,
            semiPermanent: true,
            phoneticName: nil,
            topic: nil,
            description: nil,
            filePath: nil,
            password: "",
            codec: nil,
            codecQuality: nil,
            codecLatencyFactor: nil,
            isCodecUnencrypted: nil,
            neededTalkPower: nil,
            neededJoinPower: nil,
            neededSubscribePower: nil,
            neededModifyPower: nil,
            neededDeletePower: nil,
            neededDescriptionViewPower: nil,
            order: nil,
            deleteDelaySeconds: nil,
            maxClients: nil,
            maxFamilyClients: nil,
            maxClientsUnlimited: nil,
            maxFamilyClientsUnlimited: nil,
            maxFamilyClientsInherited: nil,
            iconId: nil
        )

        XCTAssertEqual(command.build(), "channelcreate channel_name=Open\\sRoom channel_flag_permanent=1")
        XCTAssertNil(command.get("channel_password"))
    }

    func testChannelEditCommandBuildsOfficialAdvancedParametersAndEmptyPassword() {
        let command = TS3Client.channelEditCommand(
            channelId: 7,
            name: "Quiet Room",
            phoneticName: "quiet",
            topic: "",
            description: "Updated description",
            filePath: "",
            password: "",
            isDefault: false,
            isPermanent: true,
            isSemiPermanent: false,
            neededTalkPower: 15,
            neededJoinPower: 17,
            neededSubscribePower: 5,
            neededModifyPower: 19,
            neededDeletePower: 23,
            neededDescriptionViewPower: 11,
            codec: 5,
            codecQuality: 7,
            codecLatencyFactor: 2,
            isCodecUnencrypted: true,
            bannerGraphicsURL: "",
            bannerMode: 1,
            order: 3,
            deleteDelaySeconds: 0,
            maxClients: 8,
            maxFamilyClients: 16,
            maxClientsUnlimited: true,
            maxFamilyClientsUnlimited: false,
            maxFamilyClientsInherited: false,
            iconId: 789
        )

        XCTAssertEqual(
            command.build(),
            "channeledit cid=7 channel_name=Quiet\\sRoom channel_name_phonetic=quiet channel_topic= channel_description=Updated\\sdescription channel_filepath= channel_password= channel_needed_talk_power=15 channel_needed_join_power=17 channel_needed_subscribe_power=5 channel_needed_modify_power=19 channel_needed_delete_power=23 channel_needed_description_view_power=11 channel_order=3 channel_codec=5 channel_codec_quality=7 channel_codec_latency_factor=2 channel_codec_is_unencrypted=1 channel_banner_gfx_url= channel_banner_mode=1 channel_delete_delay=0 channel_maxclients=8 channel_maxfamilyclients=16 channel_flag_maxclients_unlimited=1 channel_flag_maxfamilyclients_unlimited=0 channel_flag_maxfamilyclients_inherited=0 channel_icon_id=789 channel_flag_default=0 channel_flag_permanent=1 channel_flag_semi_permanent=0"
        )
    }

    func testChannelCodecConstraintsMatchEditableRanges() {
        XCTAssertTrue(TS3ChannelCodecConstraints.isValidQuality(nil))
        XCTAssertTrue(TS3ChannelCodecConstraints.isValidQuality(0))
        XCTAssertTrue(TS3ChannelCodecConstraints.isValidQuality(10))
        XCTAssertFalse(TS3ChannelCodecConstraints.isValidQuality(-1))
        XCTAssertFalse(TS3ChannelCodecConstraints.isValidQuality(11))

        XCTAssertTrue(TS3ChannelCodecConstraints.isValidLatencyFactor(nil))
        XCTAssertTrue(TS3ChannelCodecConstraints.isValidLatencyFactor(1))
        XCTAssertTrue(TS3ChannelCodecConstraints.isValidLatencyFactor(10))
        XCTAssertFalse(TS3ChannelCodecConstraints.isValidLatencyFactor(0))
        XCTAssertFalse(TS3ChannelCodecConstraints.isValidLatencyFactor(11))
    }

    func testChannelCodecPresetsUseEditableRanges() {
        XCTAssertEqual(TS3ChannelCodecPreset.voice.codec, 4)
        XCTAssertEqual(TS3ChannelCodecPreset.music.codec, 5)
        XCTAssertEqual(TS3ChannelCodecPreset.compatibilityVoice.codec, 1)

        for preset in TS3ChannelCodecPreset.allPresets {
            XCTAssertTrue(TS3ChannelCodecConstraints.isValidQuality(preset.quality))
            XCTAssertTrue(TS3ChannelCodecConstraints.isValidLatencyFactor(preset.latencyFactor))
        }
    }

    func testChannelCodecDiagnosticsFlagLegacyAndUnencryptedChoices() {
        XCTAssertTrue(TS3ChannelCodecConstraints.diagnosticMessages(codec: 4, isCodecUnencrypted: false).isEmpty)

        let legacyMessages = TS3ChannelCodecConstraints.diagnosticMessages(codec: 1, isCodecUnencrypted: true)

        XCTAssertEqual(legacyMessages.count, 2)
        XCTAssertTrue(legacyMessages[0].contains("Legacy Speex/CELT"))
        XCTAssertTrue(legacyMessages[1].contains("Voice encryption is disabled"))
    }

    func testGroupCopyCommandsUseDistinctServerAndChannelParameterNames() {
        let serverCommand = TS3SingleCommand(name: "servergroupcopy", parameters: [
            TS3CommandSingleParameter(name: "ssgid", value: "6"),
            TS3CommandSingleParameter(name: "tsgid", value: "0"),
            TS3CommandSingleParameter(name: "name", value: "Moderators"),
            TS3CommandSingleParameter(name: "type", value: "1")
        ])
        let channelCommand = TS3SingleCommand(name: "channelgroupcopy", parameters: [
            TS3CommandSingleParameter(name: "scgid", value: "5"),
            TS3CommandSingleParameter(name: "tcgid", value: "0"),
            TS3CommandSingleParameter(name: "name", value: "Channel Admin"),
            TS3CommandSingleParameter(name: "type", value: "1")
        ])

        XCTAssertEqual(serverCommand.build(), "servergroupcopy ssgid=6 tsgid=0 name=Moderators type=1")
        XCTAssertEqual(channelCommand.build(), "channelgroupcopy scgid=5 tcgid=0 name=Channel\\sAdmin type=1")
    }

    func testTemporaryServerPasswordCommandEscapesDescriptionAndChannelPassword() {
        let command = TS3SingleCommand(name: "servertemppasswordadd", parameters: [
            TS3CommandSingleParameter(name: "pw", value: "guest pass"),
            TS3CommandSingleParameter(name: "duration", value: "3600"),
            TS3CommandSingleParameter(name: "desc", value: "Raid Room | Guests"),
            TS3CommandSingleParameter(name: "tcid", value: "7"),
            TS3CommandSingleParameter(name: "tcpw", value: "room pass")
        ])

        XCTAssertEqual(
            command.build(),
            "servertemppasswordadd pw=guest\\spass duration=3600 desc=Raid\\sRoom\\s\\p\\sGuests tcid=7 tcpw=room\\spass"
        )
    }

    func testPrivilegeKeyCreateCommandBuildsCustomSetAndDescription() {
        let command = TS3SingleCommand(name: "privilegekeyadd", parameters: [
            TS3CommandSingleParameter(name: "tokentype", value: "0"),
            TS3CommandSingleParameter(name: "tokenid1", value: "6"),
            TS3CommandSingleParameter(name: "tokenid2", value: "0"),
            TS3CommandSingleParameter(name: "tokendescription", value: "One time admin"),
            TS3CommandSingleParameter(name: "tokencustomset", value: "ident=ios")
        ])

        XCTAssertEqual(
            command.build(),
            "privilegekeyadd tokentype=0 tokenid1=6 tokenid2=0 tokendescription=One\\stime\\sadmin tokencustomset=ident=ios"
        )
    }

    func testBanAddCommandRequiresOfficialTargetFieldsAndEscapesReason() {
        let command = TS3SingleCommand(name: "banadd", parameters: [
            TS3CommandSingleParameter(name: "uid", value: "abc/def"),
            TS3CommandSingleParameter(name: "mytsid", value: "myts id"),
            TS3CommandSingleParameter(name: "lastnickname", value: "Recent Guest"),
            TS3CommandSingleParameter(name: "banreason", value: "spam | abuse"),
            TS3CommandSingleParameter(name: "time", value: "600")
        ])

        XCTAssertEqual(
            command.build(),
            "banadd uid=abc\\/def mytsid=myts\\sid lastnickname=Recent\\sGuest banreason=spam\\s\\p\\sabuse time=600"
        )
    }

    func testServerEditCommandBuildsOfficialVirtualServerParameters() {
        let edit = TS3ServerEdit(
            name: "Clan Server",
            phoneticName: "clan",
            port: 9989,
            machineId: "machine-a",
            isAutoStartEnabled: true,
            welcomeMessage: "Welcome | Read rules",
            maxClients: 64,
            reservedSlots: 4,
            password: "guest pass",
            hostMessage: "Maintenance soon",
            hostMessageMode: 2,
            hostBannerURL: "https://example.com",
            hostBannerGraphicsURL: "https://example.com/banner.png",
            hostBannerMode: 2,
            hostBannerGraphicsInterval: 60,
            hostButtonTooltip: "Website",
            hostButtonURL: "https://example.com/forum",
            hostButtonGraphicsURL: "https://example.com/button.png",
            iconId: 12345,
            downloadQuota: 1_048_576,
            uploadQuota: 2_097_152,
            maxDownloadTotalBandwidth: 512_000,
            maxUploadTotalBandwidth: 256_000,
            complainAutoBanCount: 5,
            complainAutoBanTime: 600,
            complainRemoveTime: 86_400,
            minClientsInChannelBeforeForcedSilence: 12,
            prioritySpeakerDimmModificator: 0.5,
            antiFloodPointsTickReduce: 25,
            antiFloodPointsNeededCommandBlock: 150,
            antiFloodPointsNeededIPBlock: 250,
            antiFloodPointsNeededPluginBlock: 350,
            isClientLoggingEnabled: true,
            isQueryLoggingEnabled: false,
            isChannelLoggingEnabled: true,
            isPermissionLoggingEnabled: true,
            isServerLoggingEnabled: false,
            isFileTransferLoggingEnabled: true,
            isWeblistEnabled: true,
            codecEncryptionMode: 1,
            defaultServerGroupId: 8,
            defaultChannelGroupId: 9,
            defaultChannelAdminGroupId: 10,
            neededIdentitySecurityLevel: 24,
            minClientVersion: 15_000,
            minAndroidVersion: 15_100,
            minIOSVersion: 15_200
        )

        let command = TS3Client.serverEditCommand(for: edit)

        XCTAssertEqual(
            command.build(),
            "serveredit virtualserver_name=Clan\\sServer virtualserver_name_phonetic=clan virtualserver_port=9989 virtualserver_machine_id=machine-a virtualserver_autostart=1 virtualserver_welcomemessage=Welcome\\s\\p\\sRead\\srules virtualserver_maxclients=64 virtualserver_reserved_slots=4 virtualserver_password=guest\\spass virtualserver_hostmessage=Maintenance\\ssoon virtualserver_hostmessage_mode=2 virtualserver_hostbanner_url=https:\\/\\/example.com virtualserver_hostbanner_gfx_url=https:\\/\\/example.com\\/banner.png virtualserver_hostbanner_mode=2 virtualserver_hostbanner_gfx_interval=60 virtualserver_hostbutton_tooltip=Website virtualserver_hostbutton_url=https:\\/\\/example.com\\/forum virtualserver_hostbutton_gfx_url=https:\\/\\/example.com\\/button.png virtualserver_icon_id=12345 virtualserver_download_quota=1048576 virtualserver_upload_quota=2097152 virtualserver_max_download_total_bandwidth=512000 virtualserver_max_upload_total_bandwidth=256000 virtualserver_complain_autoban_count=5 virtualserver_complain_autoban_time=600 virtualserver_complain_remove_time=86400 virtualserver_min_clients_in_channel_before_forced_silence=12 virtualserver_priority_speaker_dimm_modificator=0.5 virtualserver_antiflood_points_tick_reduce=25 virtualserver_antiflood_points_needed_command_block=150 virtualserver_antiflood_points_needed_ip_block=250 virtualserver_antiflood_points_needed_plugin_block=350 virtualserver_log_client=1 virtualserver_log_query=0 virtualserver_log_channel=1 virtualserver_log_permissions=1 virtualserver_log_server=0 virtualserver_log_filetransfer=1 virtualserver_weblist_enabled=1 virtualserver_codec_encryption_mode=1 virtualserver_default_server_group=8 virtualserver_default_channel_group=9 virtualserver_default_channel_admin_group=10 virtualserver_needed_identity_security_level=24 virtualserver_min_client_version=15000 virtualserver_min_android_version=15100 virtualserver_min_ios_version=15200"
        )
    }

    func testEmptyServerEditCommandBuildsNoParameters() {
        let command = TS3Client.serverEditCommand(for: TS3ServerEdit())

        XCTAssertEqual(command.build(), "serveredit")
        XCTAssertTrue(command.parameters.isEmpty)
    }

    func testServerInfoStoresOfficialVirtualServerLogOptions() {
        let info = TS3ServerInfo(
            uniqueIdentifier: nil,
            name: "Example",
            platform: nil,
            version: nil,
            clientsOnline: nil,
            maxClients: nil,
            reservedSlots: nil,
            channelsOnline: nil,
            uptimeSeconds: nil,
            welcomeMessage: nil,
            antiFloodPointsNeededPluginBlock: 350,
            isClientLoggingEnabled: true,
            isQueryLoggingEnabled: false,
            isChannelLoggingEnabled: true,
            isPermissionLoggingEnabled: false,
            isServerLoggingEnabled: true,
            isFileTransferLoggingEnabled: false
        )

        XCTAssertEqual(info.isClientLoggingEnabled, true)
        XCTAssertEqual(info.isQueryLoggingEnabled, false)
        XCTAssertEqual(info.isChannelLoggingEnabled, true)
        XCTAssertEqual(info.isPermissionLoggingEnabled, false)
        XCTAssertEqual(info.isServerLoggingEnabled, true)
        XCTAssertEqual(info.isFileTransferLoggingEnabled, false)
        XCTAssertEqual(info.antiFloodPointsNeededPluginBlock, 350)
    }

    func testServerInfoParsesOfficialVirtualServerTrafficCounters() throws {
        let command = try TS3MultiCommand.parse(
            """
            serverinfo virtualserver_id=7 virtualserver_name=Example virtualserver_month_bytes_downloaded=1024 virtualserver_month_bytes_uploaded=2048 virtualserver_total_bytes_downloaded=4096 virtualserver_total_bytes_uploaded=8192 connection_bytes_received_month=1 connection_bytes_sent_month=2 connection_bytes_received_total=3 connection_bytes_sent_total=4 connection_bandwidth_received_last_second_total=128 connection_bandwidth_sent_last_second_total=256 connection_bandwidth_received_last_minute_total=512 connection_bandwidth_sent_last_minute_total=1024
            """
        ).simplifyOne()

        let info = try XCTUnwrap(TS3Client.serverInfo(from: command, fallbackName: "example.com"))

        XCTAssertEqual(info.serverId, 7)
        XCTAssertEqual(info.monthlyBytesDownloaded, 1024)
        XCTAssertEqual(info.monthlyBytesUploaded, 2048)
        XCTAssertEqual(info.totalBytesDownloaded, 4096)
        XCTAssertEqual(info.totalBytesUploaded, 8192)
        XCTAssertEqual(info.bandwidthReceivedLastSecond, 128)
        XCTAssertEqual(info.bandwidthSentLastSecond, 256)
        XCTAssertEqual(info.bandwidthReceivedLastMinute, 512)
        XCTAssertEqual(info.bandwidthSentLastMinute, 1024)
    }

    func testLogViewCommandBuildsOfficialPaginationParameters() {
        let command = TS3Client.logViewCommand(
            limit: 250,
            reverse: false,
            instance: true,
            beginPosition: 500
        )

        XCTAssertEqual(command.build(), "logview lines=250 reverse=0 instance=1 begin_pos=500")
    }

    func testListCommandsBuildOptionsForNamesAndPermissionIds() {
        let groupClients = TS3SingleCommand(name: "servergroupclientlist", parameters: [
            TS3CommandSingleParameter(name: "sgid", value: "6"),
            TS3CommandOption(name: "names")
        ])
        let permissions = TS3SingleCommand(name: "channelpermlist", parameters: [
            TS3CommandSingleParameter(name: "cid", value: "12"),
            TS3CommandOption(name: "permsid")
        ])

        XCTAssertEqual(groupClients.build(), "servergroupclientlist sgid=6 -names")
        XCTAssertEqual(permissions.build(), "channelpermlist cid=12 -permsid")
    }
}
