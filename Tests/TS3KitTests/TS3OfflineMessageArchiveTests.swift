import XCTest
@testable import TS3iOSApp

final class TS3OfflineMessageArchiveTests: XCTestCase {
    func testOfflineMessageDraftValidatorRejectsMissingRecipientSubjectBodyAndMultilineSubject() {
        XCTAssertEqual(
            TS3OfflineMessageDraftValidator.validationMessages(
                recipientName: " ",
                recipientUniqueIdentifier: nil,
                subject: "Hello\nagain",
                message: " "
            ),
            [
                "Recipient unique id is required before sending an offline message.",
                "Select a recipient before sending an offline message.",
                "Message is required before sending an offline message.",
                "Subject must be a single line."
            ]
        )
    }

    func testOfflineMessageDraftValidatorAllowsRuntimeRecipientLookupForOnlineUsers() {
        let messages = TS3OfflineMessageDraftValidator.validationMessages(
            recipientName: "Online User",
            recipientUniqueIdentifier: nil,
            subject: "Hello",
            message: "Catch you later",
            allowsRecipientLookup: true
        )
        let summary = TS3OfflineMessageDraftValidator.creationSummary(
            recipientName: "Online User",
            recipientUniqueIdentifier: nil,
            subject: "Hello",
            message: "Catch you later",
            allowsRecipientLookup: true
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(summary, "recipient=Online User | recipientUid=lookup | subject=Hello | body=15 chars")
    }

    func testOfflineMessageDraftValidatorBuildsAuditableSummaryForKnownRecipient() {
        let summary = TS3OfflineMessageDraftValidator.creationSummary(
            recipientName: "Saved User",
            recipientUniqueIdentifier: "uid-saved",
            subject: " Status ",
            message: " Ping me "
        )

        XCTAssertEqual(summary, "recipient=Saved User | recipientUid=uid-saved | subject=Status | body=7 chars")
    }

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
        XCTAssertEqual(preview.readStateSummaries, [
            "read=false count=1",
            "read=true count=1"
        ])
        XCTAssertEqual(preview.senderSummaries, [
            "sender=Sender A count=1",
            "sender=Unknown count=1"
        ])
        XCTAssertEqual(preview.firstSenderName, "Sender A")
        XCTAssertEqual(preview.firstSubject, "Hello")
        XCTAssertEqual(
            preview.messageSummaries,
            [
                "id=3 | read=false | subject=Hello | sender=Sender A | senderUid=uid-a | timestamp=2678307200 | body=true",
                "id=2 | read=true | subject=No sender"
            ]
        )
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "id=3 | read=false | subject=Hello | sender=Sender A | senderUid=uid-a | timestamp=2678307200 | body=true",
                "id=2 | read=true | subject=No sender"
            ]
        )
        XCTAssertEqual(preview.candidates.map(\.id), [3, 2])
        XCTAssertTrue(preview.containsMessage(id: 2))
        XCTAssertFalse(preview.containsMessage(id: 99))
        XCTAssertEqual(
            preview.clipboardSummary,
            (preview.readStateSummaries + preview.senderSummaries + preview.messageSummaries).joined(separator: "\n")
        )
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

    @MainActor
    func testOfflineMessageArchiveImportCanRestoreSelectedMessages() throws {
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
            },
            {
              "id": 8,
              "senderUniqueIdentifier": "uid-c",
              "senderName": " Sender C ",
              "subject": " Keep ",
              "message": " Selected ",
              "isRead": false
            }
          ]
        }
        """
        let data = Data(archiveJSON.utf8)

        try model.importOfflineMessageArchive(from: data, selectedMessageIds: [8])

        XCTAssertEqual(model.offlineMessages.count, 1)
        XCTAssertEqual(model.offlineMessages.first?.id, 8)
        XCTAssertEqual(model.offlineMessages.first?.senderName, "Sender C")
        XCTAssertEqual(model.offlineMessages.first?.subject, "Keep")
        XCTAssertEqual(model.offlineMessages.first?.message, "Selected")
        XCTAssertEqual(model.offlineMessages.first?.isRead, false)
    }

    func testOfflineMessageSummaryCopyAndAccessibilityText() {
        let message = TS3OfflineMessageSummary(
            id: 42,
            senderUniqueIdentifier: "uid-offline",
            senderName: " Sender ",
            subject: "Hello",
            message: "Cached body",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            isRead: false
        )

        XCTAssertEqual(message.senderDisplayName, "Sender")
        XCTAssertEqual(
            message.clipboardSummary,
            "messageId=42 | read=false | subject=Hello | sender=Sender | senderUid=uid-offline | timestamp=1700000000 | body=Cached body"
        )
        XCTAssertEqual(
            message.accessibilityValue,
            "Unread. From Sender. Subject Hello. Message body available"
        )
    }

    func testOfflineMessageSummaryFallsBackToSenderUniqueIdentifierAndBodyState() {
        let message = TS3OfflineMessageSummary(
            id: 9,
            senderUniqueIdentifier: "uid-only",
            senderName: " ",
            subject: "Pending",
            message: nil,
            timestamp: nil,
            isRead: true
        )

        XCTAssertEqual(message.senderDisplayName, "uid-only")
        XCTAssertEqual(
            message.clipboardSummary,
            "messageId=9 | read=true | subject=Pending | sender=uid-only | body=not loaded"
        )
        XCTAssertEqual(
            message.accessibilityValue,
            "Read. From uid-only. Subject Pending. Message body not loaded"
        )
    }
}
