import XCTest
@testable import TS3iOSApp

final class TS3OfflineMessageArchiveTests: XCTestCase {
    @MainActor
    func testOfflineMessageArchivePreviewSanitizesCountsAndFirstDetails() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "messages": [
            {
              "id": 3,
              "senderUniqueIdentifier": "uid-a",
              "senderName": " Sender A ",
              "subject": " Hello ",
              "message": " Body ",
              "timestamp": 1700000000,
              "isRead": false
            },
            {
              "id": 3,
              "senderUniqueIdentifier": "uid-a",
              "senderName": "Sender A",
              "subject": "Duplicate",
              "isRead": true
            },
            {
              "id": 2,
              "subject": "No sender",
              "isRead": true
            },
            {
              "id": 0,
              "subject": "Invalid",
              "isRead": false
            },
            {
              "id": 4,
              "subject": "   ",
              "isRead": false
            }
          ]
        }
        """

        let preview = try model.offlineMessageArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.messageCount, 2)
        XCTAssertEqual(preview.skippedMessageCount, 3)
        XCTAssertEqual(preview.unreadCount, 1)
        XCTAssertEqual(preview.withBodyCount, 1)
        XCTAssertEqual(preview.replyableCount, 1)
        XCTAssertEqual(preview.unknownSenderCount, 1)
        XCTAssertEqual(preview.firstSenderName, "Sender A")
        XCTAssertEqual(preview.firstSubject, "Hello")
        XCTAssertTrue(preview.hasMessages)
    }

    @MainActor
    func testOfflineMessageArchiveImportReplacesLocalCachedInbox() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "messages": [
            {
              "id": 7,
              "senderUniqueIdentifier": "uid-b",
              "senderName": " Sender B ",
              "subject": " Saved ",
              "message": " Cached ",
              "isRead": true
            }
          ]
        }
        """

        try model.importOfflineMessageArchive(from: Data(archiveJSON.utf8))

        XCTAssertEqual(model.offlineMessages.count, 1)
        XCTAssertEqual(model.offlineMessages.first?.id, 7)
        XCTAssertEqual(model.offlineMessages.first?.senderName, "Sender B")
        XCTAssertEqual(model.offlineMessages.first?.subject, "Saved")
        XCTAssertEqual(model.offlineMessages.first?.message, "Cached")
        XCTAssertEqual(model.offlineMessages.first?.isRead, true)
        XCTAssertEqual(model.lastError, nil)
    }
}
