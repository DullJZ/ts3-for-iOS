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
            TS3CommandSingleParameter(name: "banreason", value: "spam | abuse"),
            TS3CommandSingleParameter(name: "time", value: "600")
        ])

        XCTAssertEqual(command.build(), "banadd uid=abc\\/def banreason=spam\\s\\p\\sabuse time=600")
    }

    func testServerEditCommandBuildsOfficialVirtualServerParameters() {
        let edit = TS3ServerEdit(
            name: "Clan Server",
            welcomeMessage: "Welcome | Read rules",
            maxClients: 64,
            reservedSlots: 4,
            password: "guest pass",
            hostMessage: "Maintenance soon",
            hostMessageMode: 2,
            hostBannerURL: "https://example.com",
            hostBannerGraphicsURL: "https://example.com/banner.png",
            hostButtonTooltip: "Website",
            hostButtonURL: "https://example.com/forum",
            hostButtonGraphicsURL: "https://example.com/button.png",
            iconId: 12345,
            downloadQuota: 1_048_576,
            uploadQuota: 2_097_152,
            complainAutoBanCount: 5,
            complainAutoBanTime: 600,
            complainRemoveTime: 86_400,
            minClientsInChannelBeforeForcedSilence: 12,
            prioritySpeakerDimmModificator: 0.5,
            antiFloodPointsTickReduce: 25,
            antiFloodPointsNeededCommandBlock: 150,
            antiFloodPointsNeededIPBlock: 250,
            isWeblistEnabled: true,
            codecEncryptionMode: 1
        )

        let command = TS3Client.serverEditCommand(for: edit)

        XCTAssertEqual(
            command.build(),
            "serveredit virtualserver_name=Clan\\sServer virtualserver_welcomemessage=Welcome\\s\\p\\sRead\\srules virtualserver_maxclients=64 virtualserver_reserved_slots=4 virtualserver_password=guest\\spass virtualserver_hostmessage=Maintenance\\ssoon virtualserver_hostmessage_mode=2 virtualserver_hostbanner_url=https:\\/\\/example.com virtualserver_hostbanner_gfx_url=https:\\/\\/example.com\\/banner.png virtualserver_hostbutton_tooltip=Website virtualserver_hostbutton_url=https:\\/\\/example.com\\/forum virtualserver_hostbutton_gfx_url=https:\\/\\/example.com\\/button.png virtualserver_icon_id=12345 virtualserver_download_quota=1048576 virtualserver_upload_quota=2097152 virtualserver_complain_autoban_count=5 virtualserver_complain_autoban_time=600 virtualserver_complain_remove_time=86400 virtualserver_min_clients_in_channel_before_forced_silence=12 virtualserver_priority_speaker_dimm_modificator=0.5 virtualserver_antiflood_points_tick_reduce=25 virtualserver_antiflood_points_needed_command_block=150 virtualserver_antiflood_points_needed_ip_block=250 virtualserver_weblist_enabled=1 virtualserver_codec_encryption_mode=1"
        )
    }

    func testEmptyServerEditCommandBuildsNoParameters() {
        let command = TS3Client.serverEditCommand(for: TS3ServerEdit())

        XCTAssertEqual(command.build(), "serveredit")
        XCTAssertTrue(command.parameters.isEmpty)
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
