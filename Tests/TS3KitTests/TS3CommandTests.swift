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

    func testClientUpdateCommandsBuildOfficialSelfStatusFields() {
        let nickname = TS3Client.clientUpdateCommand(nickname: "Taylor / Ops | Lead")
        let phonetic = TS3Client.clientUpdateCommand(phoneticNickname: "Tay | Lor")
        let away = TS3Client.clientAwayCommand(isAway: true, message: "Out / lunch | later")
        let back = TS3Client.clientAwayCommand(isAway: false, message: "ignored")
        let inputMuted = TS3Client.clientInputMuteCommand(true)
        let outputUnmuted = TS3Client.clientOutputMuteCommand(false)
        let commander = TS3Client.clientChannelCommanderCommand(true)
        let talkRequest = TS3Client.clientTalkRequestCommand(isRequesting: true, message: "Need / voice | now")
        let cancelTalkRequest = TS3Client.clientTalkRequestCommand(isRequesting: false, message: "ignored")
        let icon = TS3Client.clientIconCommand(iconId: 12345)
        let avatar = TS3Client.clientAvatarFlagCommand("avatar/hash")

        XCTAssertEqual(nickname.build(), "clientupdate client_nickname=Taylor\\s\\/\\sOps\\s\\p\\sLead")
        XCTAssertEqual(phonetic.build(), "clientupdate client_nickname_phonetic=Tay\\s\\p\\sLor")
        XCTAssertEqual(away.build(), "clientupdate client_away=1 client_away_message=Out\\s\\/\\slunch\\s\\p\\slater")
        XCTAssertEqual(back.build(), "clientupdate client_away=0 client_away_message=")
        XCTAssertEqual(inputMuted.build(), "clientupdate client_input_muted=1")
        XCTAssertEqual(outputUnmuted.build(), "clientupdate client_output_muted=0")
        XCTAssertEqual(commander.build(), "clientupdate client_is_channel_commander=1")
        XCTAssertEqual(
            talkRequest.build(),
            "clientupdate client_talk_request=1 client_talk_request_msg=Need\\s\\/\\svoice\\s\\p\\snow"
        )
        XCTAssertEqual(cancelTalkRequest.build(), "clientupdate client_talk_request=0 client_talk_request_msg=")
        XCTAssertEqual(icon.build(), "clientupdate client_icon_id=12345")
        XCTAssertEqual(avatar.build(), "clientupdate client_flag_avatar=avatar\\/hash")
    }

    func testClientActionCommandsBuildOfficialContextMenuFields() {
        let hashedChannelPassword = TS3String.escape(TS3Crypto.hashPassword("room pass"))
        let move = TS3Client.clientMoveCommand(clientId: 7, channelId: 12, password: "room pass")
        let moveWithoutPassword = TS3Client.clientMoveCommand(clientId: 7, channelId: 12, password: "")
        let kick = TS3Client.clientKickCommand(clientId: 7, reason: .server, message: "Too / loud | now")
        let ban = TS3Client.clientBanCommand(clientId: 7, durationSeconds: 600, message: "spam | abuse")
        let permanentBan = TS3Client.clientBanCommand(clientId: 7, durationSeconds: nil, message: nil)
        let poke = TS3Client.clientPokeCommand(clientId: 7, message: "Ping / check | now")
        let description = TS3Client.clientDescriptionEditCommand(clientId: 7, description: "Ops / Lead | notes")
        let talker = TS3Client.clientTalkerEditCommand(clientId: 7, isTalker: true)
        let notTalker = TS3Client.clientTalkerEditCommand(clientId: 7, isTalker: false)

        XCTAssertEqual(move.build(), "clientmove clid=7 cid=12 cpw=\(hashedChannelPassword)")
        XCTAssertEqual(moveWithoutPassword.build(), "clientmove clid=7 cid=12")
        XCTAssertEqual(kick.build(), "clientkick clid=7 reasonid=5 reasonmsg=Too\\s\\/\\sloud\\s\\p\\snow")
        XCTAssertEqual(ban.build(), "banclient clid=7 banreason=spam\\s\\p\\sabuse time=600")
        XCTAssertEqual(permanentBan.build(), "banclient clid=7 banreason=")
        XCTAssertEqual(poke.build(), "clientpoke clid=7 msg=Ping\\s\\/\\scheck\\s\\p\\snow")
        XCTAssertEqual(description.build(), "clientedit clid=7 client_description=Ops\\s\\/\\sLead\\s\\p\\snotes")
        XCTAssertEqual(talker.build(), "clientedit clid=7 client_is_talker=1")
        XCTAssertEqual(notTalker.build(), "clientedit clid=7 client_is_talker=0")
    }

    func testBanDeleteCommandUsesServerQueryName() {
        let command = TS3SingleCommand(name: "bandel", parameters: [
            TS3CommandSingleParameter(name: "banid", value: "42")
        ])

        XCTAssertEqual(command.build(), "bandel banid=42")
    }

    func testPermissionListCommandsBuildOfficialScopeOptions() {
        XCTAssertEqual(TS3Client.permissionListCommand().build(), "permissionlist")
        XCTAssertEqual(
            TS3Client.clientPermissionListCommand(clientDatabaseId: 44).build(),
            "clientpermlist cldbid=44 -permsid"
        )
        XCTAssertEqual(
            TS3Client.serverGroupPermissionListCommand(groupId: 6).build(),
            "servergrouppermlist sgid=6 -permsid"
        )
        XCTAssertEqual(
            TS3Client.channelGroupPermissionListCommand(groupId: 5).build(),
            "channelgrouppermlist cgid=5 -permsid"
        )
        XCTAssertEqual(
            TS3Client.channelPermissionListCommand(channelId: 12).build(),
            "channelpermlist cid=12 -permsid"
        )
        XCTAssertEqual(
            TS3Client.channelClientPermissionListCommand(channelId: 12, clientDatabaseId: 44).build(),
            "channelclientpermlist cid=12 cldbid=44 -permsid"
        )
    }

    func testPermissionMutationCommandsBuildOfficialScopeFields() {
        let clientAdd = TS3Client.clientPermissionAddCommand(
            clientDatabaseId: 44,
            permissionName: "i_client_kick_from_server_power",
            value: 75,
            skip: true
        )
        let clientDelete = TS3Client.clientPermissionDeleteCommand(
            clientDatabaseId: 44,
            permissionName: "i_client_kick_from_server_power"
        )
        let serverGroupAdd = TS3Client.serverGroupPermissionAddCommand(
            groupId: 6,
            permissionName: "i_client_kick_from_server_power",
            value: 75,
            negated: false,
            skip: true
        )
        let serverGroupDelete = TS3Client.serverGroupPermissionDeleteCommand(
            groupId: 6,
            permissionName: "i_client_kick_from_server_power"
        )
        let channelGroupAdd = TS3Client.channelGroupPermissionAddCommand(
            groupId: 5,
            permissionName: "i_channel_join_power",
            value: 50,
            negated: true,
            skip: false
        )
        let channelGroupDelete = TS3Client.channelGroupPermissionDeleteCommand(
            groupId: 5,
            permissionName: "i_channel_join_power"
        )
        let channelAdd = TS3Client.channelPermissionAddCommand(
            channelId: 12,
            permissionName: "i_channel_needed_join_power",
            value: 30
        )
        let channelDelete = TS3Client.channelPermissionDeleteCommand(
            channelId: 12,
            permissionName: "i_channel_needed_join_power"
        )
        let channelClientAdd = TS3Client.channelClientPermissionAddCommand(
            channelId: 12,
            clientDatabaseId: 44,
            permissionName: "b_client_is_priority_speaker",
            value: 1,
            skip: false
        )
        let channelClientDelete = TS3Client.channelClientPermissionDeleteCommand(
            channelId: 12,
            clientDatabaseId: 44,
            permissionName: "b_client_is_priority_speaker"
        )

        XCTAssertEqual(
            clientAdd.build(),
            "clientaddperm cldbid=44 permsid=i_client_kick_from_server_power permvalue=75 permskip=1"
        )
        XCTAssertEqual(clientDelete.build(), "clientdelperm cldbid=44 permsid=i_client_kick_from_server_power")
        XCTAssertEqual(
            serverGroupAdd.build(),
            "servergroupaddperm sgid=6 permsid=i_client_kick_from_server_power permvalue=75 permnegated=0 permskip=1"
        )
        XCTAssertEqual(
            serverGroupDelete.build(),
            "servergroupdelperm sgid=6 permsid=i_client_kick_from_server_power"
        )
        XCTAssertEqual(
            channelGroupAdd.build(),
            "channelgroupaddperm cgid=5 permsid=i_channel_join_power permvalue=50 permnegated=1 permskip=0"
        )
        XCTAssertEqual(channelGroupDelete.build(), "channelgroupdelperm cgid=5 permsid=i_channel_join_power")
        XCTAssertEqual(
            channelAdd.build(),
            "channeladdperm cid=12 permsid=i_channel_needed_join_power permvalue=30"
        )
        XCTAssertEqual(channelDelete.build(), "channeldelperm cid=12 permsid=i_channel_needed_join_power")
        XCTAssertEqual(
            channelClientAdd.build(),
            "channelclientaddperm cid=12 cldbid=44 permsid=b_client_is_priority_speaker permvalue=1 permskip=0"
        )
        XCTAssertEqual(
            channelClientDelete.build(),
            "channelclientdelperm cid=12 cldbid=44 permsid=b_client_is_priority_speaker"
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

    func testGroupManagementCommandsBuildOfficialParameters() {
        let serverAdd = TS3Client.serverGroupAddCommand(name: "Moderators | East", type: .regular)
        let serverCopy = TS3Client.serverGroupCopyCommand(
            sourceGroupId: 6,
            targetGroupId: 0,
            name: "Moderators | Copy",
            type: .query
        )
        let serverRename = TS3Client.serverGroupRenameCommand(groupId: 6, name: "Admins / Ops")
        let serverDelete = TS3Client.serverGroupDeleteCommand(groupId: 6, force: true)
        let channelAdd = TS3Client.channelGroupAddCommand(name: "Channel Template", type: .template)
        let channelCopy = TS3Client.channelGroupCopyCommand(
            sourceGroupId: 5,
            targetGroupId: 10,
            name: "Channel Admin",
            type: .regular
        )
        let channelRename = TS3Client.channelGroupRenameCommand(groupId: 5, name: "Raid Leads")
        let channelDelete = TS3Client.channelGroupDeleteCommand(groupId: 5, force: false)

        XCTAssertEqual(serverAdd.build(), "servergroupadd name=Moderators\\s\\p\\sEast type=1")
        XCTAssertEqual(serverCopy.build(), "servergroupcopy ssgid=6 tsgid=0 name=Moderators\\s\\p\\sCopy type=2")
        XCTAssertEqual(serverRename.build(), "servergrouprename sgid=6 name=Admins\\s\\/\\sOps")
        XCTAssertEqual(serverDelete.build(), "servergroupdel sgid=6 force=1")
        XCTAssertEqual(channelAdd.build(), "channelgroupadd name=Channel\\sTemplate type=0")
        XCTAssertEqual(channelCopy.build(), "channelgroupcopy scgid=5 tcgid=10 name=Channel\\sAdmin type=1")
        XCTAssertEqual(channelRename.build(), "channelgrouprename cgid=5 name=Raid\\sLeads")
        XCTAssertEqual(channelDelete.build(), "channelgroupdel cgid=5 force=0")
    }

    func testGroupMemberCommandsBuildOfficialParameters() {
        let serverList = TS3Client.serverGroupClientListCommand(groupId: 6)
        let channelList = TS3Client.channelGroupClientListCommand(groupId: 5)
        let serverAddClient = TS3Client.serverGroupAddClientCommand(groupId: 6, clientDatabaseId: 42)
        let serverDeleteClient = TS3Client.serverGroupDeleteClientCommand(groupId: 6, clientDatabaseId: 42)
        let channelSetClient = TS3Client.setClientChannelGroupCommand(
            groupId: 5,
            channelId: 12,
            clientDatabaseId: 42
        )

        XCTAssertEqual(serverList.build(), "servergroupclientlist sgid=6 -names")
        XCTAssertEqual(channelList.build(), "channelgroupclientlist cgid=5 -names")
        XCTAssertEqual(serverAddClient.build(), "servergroupaddclient sgid=6 cldbid=42")
        XCTAssertEqual(serverDeleteClient.build(), "servergroupdelclient sgid=6 cldbid=42")
        XCTAssertEqual(channelSetClient.build(), "setclientchannelgroup cgid=5 cid=12 cldbid=42")
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

    func testPrivilegeKeyCommandsBuildOfficialParameters() {
        let list = TS3Client.privilegeKeyListCommand()
        let use = TS3Client.privilegeKeyUseCommand("token / one | use")
        let serverGroupKey = TS3Client.privilegeKeyAddCommand(
            type: .serverGroup,
            groupId: 6,
            channelId: nil,
            description: "One time admin",
            customSet: "ident=ios"
        )
        let channelGroupKey = TS3Client.privilegeKeyAddCommand(
            type: .channelGroup,
            groupId: 5,
            channelId: 12,
            description: "",
            customSet: nil
        )
        let delete = TS3Client.privilegeKeyDeleteCommand("token / old | delete")

        XCTAssertEqual(list.build(), "privilegekeylist")
        XCTAssertEqual(use.build(), "privilegekeyuse token=token\\s\\/\\sone\\s\\p\\suse")
        XCTAssertEqual(
            serverGroupKey.build(),
            "privilegekeyadd tokentype=0 tokenid1=6 tokenid2=0 tokendescription=One\\stime\\sadmin tokencustomset=ident=ios"
        )
        XCTAssertEqual(channelGroupKey.build(), "privilegekeyadd tokentype=1 tokenid1=5 tokenid2=12 tokendescription=")
        XCTAssertEqual(delete.build(), "privilegekeydelete token=token\\s\\/\\sold\\s\\p\\sdelete")
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

    func testConnectionInfoParserKeepsOfficialConnectionQualityAndTrafficFields() throws {
        let command = try TS3MultiCommand.parse(
            """
            serverrequestconnectioninfo connection_ping=42.5 connection_packetloss_total=0.0125 connection_packetloss_speech=0.01 connection_packetloss_keepalive=0.02 connection_packetloss_control=0.03 connection_bytes_received=1024 connection_bytes_sent=2048 connection_bytes_received_month=4096 connection_bytes_sent_month=8192 connection_bytes_received_total=16384 connection_bytes_sent_total=32768 connection_connected_time=125000 client_idle_time=5000
            """
        ).simplifyOne()

        let info = try XCTUnwrap(TS3Client.connectionInfo(from: command))

        XCTAssertEqual(info.ping, 42.5)
        XCTAssertEqual(info.packetLossTotal, 0.0125)
        XCTAssertEqual(info.packetLossSpeech, 0.01)
        XCTAssertEqual(info.packetLossKeepalive, 0.02)
        XCTAssertEqual(info.packetLossControl, 0.03)
        XCTAssertEqual(info.bytesReceived, 1_024)
        XCTAssertEqual(info.bytesSent, 2_048)
        XCTAssertEqual(info.monthlyBytesReceived, 4_096)
        XCTAssertEqual(info.monthlyBytesSent, 8_192)
        XCTAssertEqual(info.totalBytesReceived, 16_384)
        XCTAssertEqual(info.totalBytesSent, 32_768)
        XCTAssertEqual(info.connectedSeconds, 125)
        XCTAssertEqual(info.idleSeconds, 5)
    }

    func testConnectionInfoParserFallsBackToConnectionIdleTime() throws {
        let command = try TS3MultiCommand.parse(
            "serverrequestconnectioninfo connection_connected_time=90000 connection_idle_time=30000"
        ).simplifyOne()

        let info = try XCTUnwrap(TS3Client.connectionInfo(from: command))

        XCTAssertEqual(info.connectedSeconds, 90)
        XCTAssertEqual(info.idleSeconds, 30)
    }

    func testClientInfoParserKeepsOfficialIdentityStatusAndConnectionFields() throws {
        let command = try TS3MultiCommand.parse(
            """
            clientinfo clid=12 cid=5 client_database_id=42 client_nickname=Taylor client_unique_identifier=uid\\/abc client_input_muted=1 client_output_muted=0 client_away=1 client_away_message=Back\\slater client_is_channel_commander=1 client_is_priority_speaker=1 client_is_talker=0 client_talk_request=1 client_talk_request_msg=Need\\svoice client_talk_power=55 client_channel_group_id=8 client_servergroups=6,7,9 client_description=Ops\\slead client_base64HashClientUID=avatarhash client_icon_id=123 client_version=3.6.2\\sBuild\\s123 client_platform=iOS client_country=US connection_client_ip=203.0.113.5 client_created=1700000000 client_lastconnected=1700001000 client_totalconnections=14 client_idle_time=45000 connection_connected_time=125000
            """
        ).simplifyOne()

        let client = try XCTUnwrap(TS3Client.detailedClientInfo(
            from: command,
            fallbackClientId: 99,
            currentClientId: 12
        ))

        XCTAssertEqual(client.id, 12)
        XCTAssertEqual(client.channelId, 5)
        XCTAssertEqual(client.databaseId, 42)
        XCTAssertEqual(client.nickname, "Taylor")
        XCTAssertTrue(client.isCurrentUser)
        XCTAssertEqual(client.uniqueIdentifier, "uid/abc")
        XCTAssertTrue(client.isInputMuted)
        XCTAssertFalse(client.isOutputMuted)
        XCTAssertTrue(client.isAway)
        XCTAssertEqual(client.awayMessage, "Back later")
        XCTAssertTrue(client.isChannelCommander)
        XCTAssertTrue(client.isPrioritySpeaker)
        XCTAssertFalse(client.isTalker)
        XCTAssertTrue(client.isRequestingTalkPower)
        XCTAssertEqual(client.talkRequestMessage, "Need voice")
        XCTAssertEqual(client.talkPower, 55)
        XCTAssertEqual(client.channelGroupId, 8)
        XCTAssertEqual(client.serverGroups, [6, 7, 9])
        XCTAssertEqual(client.description, "Ops lead")
        XCTAssertEqual(client.avatarHash, "avatarhash")
        XCTAssertEqual(client.iconId, 123)
        XCTAssertEqual(client.version, "3.6.2 Build 123")
        XCTAssertEqual(client.platform, "iOS")
        XCTAssertEqual(client.country, "US")
        XCTAssertEqual(client.ipAddress, "203.0.113.5")
        XCTAssertEqual(client.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(client.lastConnectedAt, Date(timeIntervalSince1970: 1_700_001_000))
        XCTAssertEqual(client.totalConnections, 14)
        XCTAssertEqual(client.idleTimeSeconds, 45)
        XCTAssertEqual(client.connectedSeconds, 125)
    }

    func testClientInfoParserPreservesExistingDetailsForPartialResponses() throws {
        let existing = TS3ServerClient(
            id: 33,
            channelId: 9,
            databaseId: 21,
            nickname: "Existing",
            isCurrentUser: false,
            uniqueIdentifier: "uid-old",
            isInputMuted: true,
            isOutputMuted: true,
            isAway: true,
            awayMessage: "Away",
            isChannelCommander: true,
            isPrioritySpeaker: true,
            isTalker: true,
            isRequestingTalkPower: true,
            talkRequestMessage: "Queued",
            talkPower: 15,
            channelGroupId: 2,
            serverGroups: [6],
            description: "Existing description",
            avatarHash: "oldhash",
            iconId: 5,
            version: "3.5",
            platform: "macOS",
            country: "DE",
            ipAddress: "198.51.100.3",
            createdAt: Date(timeIntervalSince1970: 1_600_000_000),
            lastConnectedAt: Date(timeIntervalSince1970: 1_600_001_000),
            totalConnections: 3,
            idleTimeSeconds: 9,
            connectedSeconds: 10
        )
        let command = try TS3MultiCommand.parse(
            "clientinfo client_nickname=Updated client_output_muted=0"
        ).simplifyOne()

        let client = try XCTUnwrap(TS3Client.detailedClientInfo(
            from: command,
            fallbackClientId: 33,
            currentClientId: 1,
            existing: existing,
            currentChannelId: 7
        ))

        XCTAssertEqual(client.id, 33)
        XCTAssertEqual(client.channelId, 9)
        XCTAssertEqual(client.databaseId, 21)
        XCTAssertEqual(client.nickname, "Updated")
        XCTAssertFalse(client.isCurrentUser)
        XCTAssertEqual(client.uniqueIdentifier, "uid-old")
        XCTAssertTrue(client.isInputMuted)
        XCTAssertFalse(client.isOutputMuted)
        XCTAssertTrue(client.isAway)
        XCTAssertEqual(client.awayMessage, "Away")
        XCTAssertTrue(client.isChannelCommander)
        XCTAssertTrue(client.isPrioritySpeaker)
        XCTAssertTrue(client.isTalker)
        XCTAssertTrue(client.isRequestingTalkPower)
        XCTAssertEqual(client.talkRequestMessage, "Queued")
        XCTAssertEqual(client.talkPower, 15)
        XCTAssertEqual(client.channelGroupId, 2)
        XCTAssertEqual(client.serverGroups, [6])
        XCTAssertEqual(client.description, "Existing description")
        XCTAssertEqual(client.avatarHash, "oldhash")
        XCTAssertEqual(client.iconId, 5)
        XCTAssertEqual(client.version, "3.5")
        XCTAssertEqual(client.platform, "macOS")
        XCTAssertEqual(client.country, "DE")
        XCTAssertEqual(client.ipAddress, "198.51.100.3")
        XCTAssertEqual(client.createdAt, Date(timeIntervalSince1970: 1_600_000_000))
        XCTAssertEqual(client.lastConnectedAt, Date(timeIntervalSince1970: 1_600_001_000))
        XCTAssertEqual(client.totalConnections, 3)
        XCTAssertEqual(client.idleTimeSeconds, 9)
        XCTAssertEqual(client.connectedSeconds, 10)
    }

    func testDatabaseClientParserKeepsOfficialListAndInfoFields() throws {
        let command = try TS3MultiCommand.parse(
            """
            clientdblist cldbid=42 client_unique_identifier=uid\\/abc client_nickname=Taylor client_created=1700000000 client_lastconnected=1700001000 client_totalconnections=14 client_description=Ops\\slead client_lastip=203.0.113.5
            """
        ).simplifyOne()

        let client = try XCTUnwrap(TS3Client.databaseClient(from: command))

        XCTAssertEqual(client.id, 42)
        XCTAssertEqual(client.uniqueIdentifier, "uid/abc")
        XCTAssertEqual(client.nickname, "Taylor")
        XCTAssertEqual(client.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(client.lastConnectedAt, Date(timeIntervalSince1970: 1_700_001_000))
        XCTAssertEqual(client.totalConnections, 14)
        XCTAssertEqual(client.description, "Ops lead")
        XCTAssertEqual(client.lastIP, "203.0.113.5")
    }

    func testDatabaseClientParserAcceptsLookupAliasesAndFallbackId() throws {
        let command = try TS3MultiCommand.parse(
            "clientdbinfo cluid=uid\\/fallback client_lastnickname=Recent\\sGuest"
        ).simplifyOne()

        let client = try XCTUnwrap(TS3Client.databaseClient(from: command, fallbackDatabaseId: 77))

        XCTAssertEqual(client.id, 77)
        XCTAssertEqual(client.uniqueIdentifier, "uid/fallback")
        XCTAssertEqual(client.nickname, "Recent Guest")
        XCTAssertNil(client.createdAt)
        XCTAssertNil(client.lastConnectedAt)
        XCTAssertNil(client.totalConnections)
    }

    func testClientLocationParserKeepsOnlineLookupNames() throws {
        let byUID = try TS3MultiCommand.parse(
            "clientgetids clid=12 name=Taylor"
        ).simplifyOne()
        let byFind = try TS3MultiCommand.parse(
            "clientfind clid=13 client_nickname=Jordan"
        ).simplifyOne()

        let uidLocation = try XCTUnwrap(TS3Client.clientLocation(from: byUID))
        let findLocation = try XCTUnwrap(TS3Client.clientLocation(from: byFind))

        XCTAssertEqual(uidLocation.clientId, 12)
        XCTAssertEqual(uidLocation.nickname, "Taylor")
        XCTAssertEqual(findLocation.clientId, 13)
        XCTAssertEqual(findLocation.nickname, "Jordan")
    }

    func testServerInfoParserKeepsOfficialEditableAdministrationFields() throws {
        let command = try TS3MultiCommand.parse(
            """
            serverinfo virtualserver_id=7 virtualserver_unique_identifier=server-uid virtualserver_name=Clan\\sServer virtualserver_platform=Linux virtualserver_version=3.13.7 virtualserver_created=1700000000 virtualserver_clientsonline=12 virtualserver_queryclientsonline=1 virtualserver_maxclients=64 virtualserver_reserved_slots=4 virtualserver_channelsonline=9 virtualserver_uptime=3600 virtualserver_welcomemessage=Welcome\\s\\p\\sRules virtualserver_flag_password=1 virtualserver_name_phonetic=clan virtualserver_status=online virtualserver_machine_id=machine-a virtualserver_autostart=1 virtualserver_codec_encryption_mode=2 virtualserver_weblist_enabled=1 virtualserver_default_server_group=8 virtualserver_default_channel_group=9 virtualserver_default_channel_admin_group=10 virtualserver_filebase=files virtualserver_filetransfer_port=30033 virtualserver_complain_autoban_count=5 virtualserver_complain_autoban_time=600 virtualserver_complain_remove_time=86400 virtualserver_min_clients_in_channel_before_forced_silence=12 virtualserver_priority_speaker_dimm_modificator=0.5 virtualserver_antiflood_points_tick_reduce=25 virtualserver_antiflood_points_needed_command_block=150 virtualserver_antiflood_points_needed_ip_block=250 virtualserver_antiflood_points_needed_plugin_block=350 virtualserver_log_client=1 virtualserver_log_query=0 virtualserver_log_channel=1 virtualserver_log_permissions=0 virtualserver_log_server=1 virtualserver_log_filetransfer=0 virtualserver_client_connections=123 virtualserver_query_client_connections=45 virtualserver_download_quota=1048576 virtualserver_upload_quota=2097152 virtualserver_max_download_total_bandwidth=512000 virtualserver_max_upload_total_bandwidth=256000 virtualserver_total_packetloss_speech=0.1 virtualserver_total_packetloss_keepalive=0.2 virtualserver_total_packetloss_control=0.3 virtualserver_total_packetloss_total=0.4 virtualserver_total_ping=42.5 virtualserver_hostmessage=Maintenance\\ssoon virtualserver_hostmessage_mode=2 virtualserver_hostbanner_url=https:\\/\\/example.com virtualserver_hostbanner_gfx_url=https:\\/\\/example.com\\/banner.png virtualserver_hostbanner_mode=2 virtualserver_hostbanner_gfx_interval=60 virtualserver_hostbutton_tooltip=Website virtualserver_hostbutton_url=https:\\/\\/example.com\\/forum virtualserver_hostbutton_gfx_url=https:\\/\\/example.com\\/button.png virtualserver_icon_id=12345 virtualserver_needed_identity_security_level=24 virtualserver_min_client_version=15000 virtualserver_min_android_version=15100 virtualserver_min_ios_version=15200
            """
        ).simplifyOne()

        let info = try XCTUnwrap(TS3Client.serverInfo(from: command, fallbackName: "fallback"))

        XCTAssertEqual(info.serverId, 7)
        XCTAssertEqual(info.uniqueIdentifier, "server-uid")
        XCTAssertEqual(info.name, "Clan Server")
        XCTAssertEqual(info.platform, "Linux")
        XCTAssertEqual(info.version, "3.13.7")
        XCTAssertEqual(info.createdAt, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(info.clientsOnline, 12)
        XCTAssertEqual(info.clientsInQuery, 1)
        XCTAssertEqual(info.maxClients, 64)
        XCTAssertEqual(info.reservedSlots, 4)
        XCTAssertEqual(info.channelsOnline, 9)
        XCTAssertEqual(info.uptimeSeconds, 3_600)
        XCTAssertEqual(info.welcomeMessage, "Welcome | Rules")
        XCTAssertEqual(info.passwordProtected, true)
        XCTAssertEqual(info.phoneticName, "clan")
        XCTAssertEqual(info.status, "online")
        XCTAssertEqual(info.machineId, "machine-a")
        XCTAssertEqual(info.isAutoStartEnabled, true)
        XCTAssertEqual(info.codecEncryptionMode, 2)
        XCTAssertEqual(info.isWeblistEnabled, true)
        XCTAssertEqual(info.defaultServerGroupId, 8)
        XCTAssertEqual(info.defaultChannelGroupId, 9)
        XCTAssertEqual(info.defaultChannelAdminGroupId, 10)
        XCTAssertEqual(info.fileBase, "files")
        XCTAssertEqual(info.fileTransferPort, 30_033)
        XCTAssertEqual(info.complainAutoBanCount, 5)
        XCTAssertEqual(info.complainAutoBanTime, 600)
        XCTAssertEqual(info.complainRemoveTime, 86_400)
        XCTAssertEqual(info.minClientsInChannelBeforeForcedSilence, 12)
        XCTAssertEqual(info.prioritySpeakerDimmModificator, 0.5)
        XCTAssertEqual(info.antiFloodPointsTickReduce, 25)
        XCTAssertEqual(info.antiFloodPointsNeededCommandBlock, 150)
        XCTAssertEqual(info.antiFloodPointsNeededIPBlock, 250)
        XCTAssertEqual(info.antiFloodPointsNeededPluginBlock, 350)
        XCTAssertEqual(info.isClientLoggingEnabled, true)
        XCTAssertEqual(info.isQueryLoggingEnabled, false)
        XCTAssertEqual(info.isChannelLoggingEnabled, true)
        XCTAssertEqual(info.isPermissionLoggingEnabled, false)
        XCTAssertEqual(info.isServerLoggingEnabled, true)
        XCTAssertEqual(info.isFileTransferLoggingEnabled, false)
        XCTAssertEqual(info.clientConnections, 123)
        XCTAssertEqual(info.queryClientConnections, 45)
        XCTAssertEqual(info.downloadQuota, 1_048_576)
        XCTAssertEqual(info.uploadQuota, 2_097_152)
        XCTAssertEqual(info.maxDownloadTotalBandwidth, 512_000)
        XCTAssertEqual(info.maxUploadTotalBandwidth, 256_000)
        XCTAssertEqual(info.totalPacketLossSpeech, 0.1)
        XCTAssertEqual(info.totalPacketLossKeepalive, 0.2)
        XCTAssertEqual(info.totalPacketLossControl, 0.3)
        XCTAssertEqual(info.totalPacketLossTotal, 0.4)
        XCTAssertEqual(info.totalPing, 42.5)
        XCTAssertEqual(info.hostMessage, "Maintenance soon")
        XCTAssertEqual(info.hostMessageMode, 2)
        XCTAssertEqual(info.hostBannerURL, "https://example.com")
        XCTAssertEqual(info.hostBannerGraphicsURL, "https://example.com/banner.png")
        XCTAssertEqual(info.hostBannerMode, 2)
        XCTAssertEqual(info.hostBannerGraphicsInterval, 60)
        XCTAssertEqual(info.hostButtonTooltip, "Website")
        XCTAssertEqual(info.hostButtonURL, "https://example.com/forum")
        XCTAssertEqual(info.hostButtonGraphicsURL, "https://example.com/button.png")
        XCTAssertEqual(info.iconId, 12_345)
        XCTAssertEqual(info.neededIdentitySecurityLevel, 24)
        XCTAssertEqual(info.minClientVersion, 15_000)
        XCTAssertEqual(info.minAndroidVersion, 15_100)
        XCTAssertEqual(info.minIOSVersion, 15_200)
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
