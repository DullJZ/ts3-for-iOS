import XCTest
@testable import TS3Kit

final class TS3FileTransferTests: XCTestCase {
    func testDownloadInitCommandBuildsSeekPositionAndChannelPassword() {
        let command = TS3Client.fileDownloadInitCommand(
            channelId: 12,
            path: "/Music/raid plan.txt",
            clientTransferId: 77,
            seekPosition: 4096,
            password: "channel secret"
        )

        XCTAssertEqual(
            command.build(),
            "ftinitdownload clientftfid=77 name=\\/Music\\/raid\\splan.txt cid=12 seekpos=4096 cpw=z8o0VoSQy9OpqujAQ4xPq6KVo2k="
        )
    }

    func testUploadInitCommandBuildsResumeAndOverwriteFlags() {
        let command = TS3Client.fileUploadInitCommand(
            channelId: 15,
            path: "/patches/client.bin",
            clientTransferId: 9,
            size: 1_048_576,
            overwrite: true,
            resume: true,
            password: nil
        )

        XCTAssertEqual(
            command.build(),
            "ftinitupload clientftfid=9 name=\\/patches\\/client.bin cid=15 size=1048576 overwrite=1 resume=1"
        )
    }

    func testFileTransferParametersUseServerValuesAndFallbackHost() throws {
        let response = try TS3MultiCommand.parse("serverftfid=42 ftkey=abc123 port=30033 size=8192 seekpos=2048")
            .simplifyOne()

        let parameters = TS3Client.fileTransferParameters(
            from: response,
            fallbackClientTransferId: 7,
            fallbackHost: "voice.example.com"
        )

        XCTAssertEqual(parameters?.clientTransferId, 7)
        XCTAssertEqual(parameters?.serverTransferId, 42)
        XCTAssertEqual(parameters?.key, "abc123")
        XCTAssertEqual(parameters?.host, "voice.example.com")
        XCTAssertEqual(parameters?.port, 30033)
        XCTAssertEqual(parameters?.size, 8192)
        XCTAssertEqual(parameters?.seekPosition, 2048)
    }

    func testFileTransferParametersPreferServerClientTransferIdAndIP() throws {
        let response = try TS3MultiCommand.parse(
            "clientftfid=22 serverftfid=43 ftkey=resume-key ip=files.example.com port=30034"
        ).simplifyOne()

        let parameters = TS3Client.fileTransferParameters(
            from: response,
            fallbackClientTransferId: 7,
            fallbackHost: "voice.example.com"
        )

        XCTAssertEqual(parameters?.clientTransferId, 22)
        XCTAssertEqual(parameters?.serverTransferId, 43)
        XCTAssertEqual(parameters?.key, "resume-key")
        XCTAssertEqual(parameters?.host, "files.example.com")
        XCTAssertEqual(parameters?.port, 30034)
        XCTAssertNil(parameters?.size)
        XCTAssertEqual(parameters?.seekPosition, 0)
    }
}
