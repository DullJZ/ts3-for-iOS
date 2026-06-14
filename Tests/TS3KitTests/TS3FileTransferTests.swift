import XCTest
@testable import TS3Kit
@testable import TS3iOSApp

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

    func testFileTransferSummaryCopyAndAccessibilityText() {
        let transfer = TS3FileTransferSummary(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
            direction: .download,
            channelId: 31,
            name: "raid-plan.txt",
            remotePath: "/docs/raid-plan.txt",
            localPath: "/tmp/raid-plan.txt",
            progress: 0.625,
            state: .transferring,
            detail: "512 KiB of 819 KiB",
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            completedAt: nil
        )

        XCTAssertEqual(
            transfer.clipboardSummary,
            "Download Transferring | raid-plan.txt | /docs/raid-plan.txt | 512 KiB of 819 KiB | progress=63% | /tmp/raid-plan.txt"
        )
        XCTAssertEqual(
            transfer.accessibilityValue,
            "Download. Transferring. 512 KiB of 819 KiB. Remote path /docs/raid-plan.txt. Progress 63 percent. Local path available"
        )
    }

    func testCompletedFileTransferAccessibilityOmitsProgress() {
        let transfer = TS3FileTransferSummary(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
            direction: .upload,
            channelId: 32,
            name: "patch.bin",
            remotePath: "/patches/patch.bin",
            localPath: nil,
            progress: 1,
            state: .completed,
            detail: "Uploaded",
            startedAt: Date(timeIntervalSince1970: 1_700_000_100),
            completedAt: Date(timeIntervalSince1970: 1_700_000_200)
        )

        XCTAssertEqual(
            transfer.accessibilityValue,
            "Upload. Completed. Uploaded. Remote path /patches/patch.bin"
        )
    }

    func testFileEntrySummaryCopyAndAccessibilityText() {
        let entry = TS3FileEntrySummary(entry: TS3FileEntry(
            channelId: 41,
            path: "/mods/map.dat",
            parentPath: "/mods/",
            name: "map.dat",
            size: 2_048,
            modifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
            type: 1,
            incompleteSize: 512
        ))

        XCTAssertEqual(entry.sizeText, "2.0 KB")
        XCTAssertEqual(
            entry.clipboardSummary,
            "name=map.dat | type=file | path=/mods/map.dat | parent=/mods/ | channelId=41 | size=2.0 KB | status=uploading | partial=512 B | modifiedAt=1700000000"
        )
        XCTAssertEqual(
            entry.accessibilityValue,
            "File. Remote path /mods/map.dat. Size 2.0 KB. Still uploading. Modified date available"
        )
    }

    func testDirectoryFileEntrySummaryOmitsFileOnlyDetails() {
        let entry = TS3FileEntrySummary(entry: TS3FileEntry(
            channelId: 42,
            path: "/recordings/",
            parentPath: "/",
            name: "recordings",
            size: 0,
            modifiedAt: nil,
            type: 0,
            incompleteSize: nil
        ))

        XCTAssertEqual(
            entry.clipboardSummary,
            "name=recordings | type=directory | path=/recordings/ | parent=/ | channelId=42"
        )
        XCTAssertEqual(
            entry.accessibilityValue,
            "Directory. Remote path /recordings/"
        )
    }

    func testFileMovePreviewDetectsConflictInKnownDestinationDirectory() throws {
        let source = fileEntry(
            channelId: 51,
            path: "/mods/map.dat",
            parentPath: "/mods/",
            name: "map.dat"
        )
        let existingDestination = fileEntry(
            channelId: 51,
            path: "/archive/MAP.dat",
            parentPath: "/archive/",
            name: "MAP.dat"
        )

        let preview = try XCTUnwrap(TS3FileMovePreview.previews(
            for: [source],
            destinationDirectory: "archive",
            knownDestinationEntries: [existingDestination]
        ).first)

        XCTAssertEqual(preview.newPath, "/archive/map.dat")
        XCTAssertEqual(preview.conflict?.id, existingDestination.id)
        XCTAssertTrue(preview.isBlocking)
        XCTAssertFalse(preview.isUnchanged)
    }

    func testFileMovePreviewDetectsDuplicateSelectedDestinationNames() {
        let first = fileEntry(
            channelId: 52,
            path: "/a/readme.txt",
            parentPath: "/a/",
            name: "readme.txt"
        )
        let second = fileEntry(
            channelId: 52,
            path: "/b/README.txt",
            parentPath: "/b/",
            name: "README.txt"
        )

        let previews = TS3FileMovePreview.previews(
            for: [first, second],
            destinationDirectory: "/merged/",
            knownDestinationEntries: []
        )

        XCTAssertEqual(previews.map(\.newPath), ["/merged/readme.txt", "/merged/README.txt"])
        XCTAssertTrue(previews.allSatisfy(\.duplicatesSelectedName))
        XCTAssertTrue(previews.allSatisfy(\.isBlocking))
    }

    func testFileMovePreviewBlocksMovingDirectoryIntoItself() throws {
        let entry = fileEntry(
            channelId: 53,
            path: "/recordings/",
            parentPath: "/",
            name: "recordings",
            isDirectory: true
        )

        let preview = try XCTUnwrap(TS3FileMovePreview.previews(
            for: [entry],
            destinationDirectory: "/recordings/live/",
            knownDestinationEntries: []
        ).first)

        XCTAssertEqual(preview.newPath, "/recordings/live/recordings")
        XCTAssertTrue(preview.isMovingDirectoryIntoItself)
        XCTAssertTrue(preview.isBlocking)
    }

    private func fileEntry(
        channelId: Int,
        path: String,
        parentPath: String,
        name: String,
        isDirectory: Bool = false
    ) -> TS3FileEntrySummary {
        TS3FileEntrySummary(entry: TS3FileEntry(
            channelId: channelId,
            path: path,
            parentPath: parentPath,
            name: name,
            size: 0,
            modifiedAt: nil,
            type: isDirectory ? 0 : 1,
            incompleteSize: nil
        ))
    }
}
