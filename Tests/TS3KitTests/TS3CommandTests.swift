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
}
