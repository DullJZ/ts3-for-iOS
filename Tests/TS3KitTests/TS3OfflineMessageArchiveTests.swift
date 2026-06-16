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

    func testOfflineMessageDraftCoverageSummaryCountsLookupAndContentFields() {
        let validationMessages = TS3OfflineMessageDraftValidator.validationMessages(
            recipientName: "Online User",
            recipientUniqueIdentifier: nil,
            subject: "Hello",
            message: "Catch you later",
            allowsRecipientLookup: true
        )
        let summary = TS3OfflineMessageDraftCoverageSummary(
            recipientName: "Online User",
            recipientUniqueIdentifier: nil,
            subject: "Hello",
            message: "Catch you later",
            allowsRecipientLookup: true,
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.recipientFieldCount, 2)
        XCTAssertEqual(summary.requiredContentFieldCount, 2)
        XCTAssertTrue(summary.hasRecipientName)
        XCTAssertFalse(summary.hasRecipientUniqueIdentifier)
        XCTAssertTrue(summary.allowsRecipientLookup)
        XCTAssertTrue(summary.hasSubject)
        XCTAssertTrue(summary.hasBody)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "recipientFields=2 | recipientName=true | recipientUid=false | recipientLookup=true | contentFields=2/2 | subject=true | body=true | validationIssues=0 | needsAttention=false"
        )
    }

    func testOfflineMessageDraftCoverageSummaryFlagsInvalidDraft() {
        let validationMessages = TS3OfflineMessageDraftValidator.validationMessages(
            recipientName: " ",
            recipientUniqueIdentifier: nil,
            subject: "Hello\nagain",
            message: " "
        )
        let summary = TS3OfflineMessageDraftCoverageSummary(
            recipientName: " ",
            recipientUniqueIdentifier: nil,
            subject: "Hello\nagain",
            message: " ",
            allowsRecipientLookup: false,
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.recipientFieldCount, 0)
        XCTAssertEqual(summary.requiredContentFieldCount, 1)
        XCTAssertFalse(summary.hasRecipientName)
        XCTAssertFalse(summary.hasRecipientUniqueIdentifier)
        XCTAssertFalse(summary.allowsRecipientLookup)
        XCTAssertTrue(summary.hasSubject)
        XCTAssertFalse(summary.hasBody)
        XCTAssertEqual(summary.validationIssueCount, 4)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "recipientFields=0 | recipientName=false | recipientUid=false | recipientLookup=false | contentFields=1/2 | subject=true | body=false | validationIssues=4 | needsAttention=true"
        )
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

    func testOfflineMessageListSummaryDeduplicatesAndCountsVisibleInbox() {
        let summary = TS3OfflineMessageListSummary(messages: [
            TS3OfflineMessageSummary(
                id: 9,
                senderUniqueIdentifier: "uid-a",
                senderName: "Sender A",
                subject: "Unread",
                message: "Body",
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                isRead: false
            ),
            TS3OfflineMessageSummary(
                id: 10,
                senderUniqueIdentifier: nil,
                senderName: nil,
                subject: "Unknown",
                message: nil,
                timestamp: nil,
                isRead: true
            ),
            TS3OfflineMessageSummary(
                id: 11,
                senderUniqueIdentifier: " uid-b ",
                senderName: " ",
                subject: "Replyable",
                message: "   ",
                timestamp: Date(timeIntervalSince1970: 1_700_000_100),
                isRead: false
            ),
            TS3OfflineMessageSummary(
                id: 9,
                senderUniqueIdentifier: "duplicate",
                senderName: "Duplicate",
                subject: "Duplicate",
                message: "Duplicate",
                timestamp: Date(timeIntervalSince1970: 1_700_000_200),
                isRead: true
            )
        ])

        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.readCount, 1)
        XCTAssertEqual(summary.unreadCount, 2)
        XCTAssertEqual(summary.withBodyCount, 1)
        XCTAssertEqual(summary.bodyNotLoadedCount, 2)
        XCTAssertEqual(summary.replyableCount, 2)
        XCTAssertEqual(summary.unknownSenderCount, 1)
        XCTAssertEqual(summary.distinctSenderCount, 3)
        XCTAssertEqual(summary.lowestMessageId, 9)
        XCTAssertEqual(summary.highestMessageId, 11)
        XCTAssertEqual(summary.earliestTimestamp, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(summary.latestTimestamp, Date(timeIntervalSince1970: 1_700_000_100))
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "messages=3 | unread=2 | read=1 | withBody=1 | bodyNotLoaded=2 | replyable=2 | unknownSender=1 | distinctSenders=3 | lowestMessageId=9 | highestMessageId=11 | earliestTimestamp=1700000000 | latestTimestamp=1700000100 | needsAttention=true"
        )
    }

    func testOfflineMessageFilterPresetSummaryAndAccessibilityText() {
        let preset = makeOfflineMessageFilterPreset(
            id: UUID(),
            name: "Unread Inbox",
            readFilter: "unread",
            contentFilter: "canReply",
            sortMode: "sender",
            sortAscending: true,
            searchText: "ops"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Unread Inbox | readFilter=unread | contentFilter=canReply | sortMode=sender | sortAscending=true | search=ops"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Read filter unread. Content filter canReply. Sort by sender. Ascending. Search ops"
        )
    }

    @MainActor
    func testOfflineMessageFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Inbox Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importOfflineMessageFilterPresets(from: encodedOfflineMessageFilterPresets([
            makeOfflineMessageFilterPreset(
                id: existingId,
                name: existingName,
                readFilter: "read",
                contentFilter: "withBody",
                sortMode: "sender",
                sortAscending: true,
                searchText: "keep"
            )
        ]))
        let data = try encodedOfflineMessageFilterPresets([
            makeOfflineMessageFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                readFilter: "invalidRead",
                contentFilter: "invalidContent",
                sortMode: "invalidSort",
                sortAscending: false,
                searchText: "  search value  "
            ),
            makeOfflineMessageFilterPreset(
                id: newId,
                name: " Reply Inbox \(suffix) ",
                readFilter: "unread",
                contentFilter: "canReply",
                sortMode: "subject",
                sortAscending: true,
                searchText: String(repeating: "x", count: 140)
            ),
            makeOfflineMessageFilterPreset(
                id: invalidId,
                name: "   ",
                readFilter: "read",
                contentFilter: "withBody",
                sortMode: "id",
                sortAscending: true,
                searchText: "ignored"
            )
        ])

        let preview = try model.offlineMessageFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | readFilter=all | contentFilter=all | sortMode=timestamp | sortAscending=false | search=search value",
            "name=Reply Inbox \(suffix) | readFilter=unread | contentFilter=canReply | sortMode=subject | sortAscending=true | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped offline message filter presets: 1"))
    }

    @MainActor
    func testOfflineMessageFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Inbox Filter \(suffix)"
        let selectedName = "Selected Inbox Filter \(suffix)"
        let unselectedName = "Unselected Inbox Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importOfflineMessageFilterPresets(from: encodedOfflineMessageFilterPresets([
            makeOfflineMessageFilterPreset(
                id: existingId,
                name: existingName,
                readFilter: "read",
                contentFilter: "withBody",
                sortMode: "sender",
                sortAscending: true,
                searchText: "keep"
            )
        ]))
        let data = try encodedOfflineMessageFilterPresets([
            makeOfflineMessageFilterPreset(
                id: existingId,
                name: existingName,
                readFilter: "unread",
                contentFilter: "canReply",
                sortMode: "subject",
                sortAscending: false,
                searchText: "replace"
            ),
            makeOfflineMessageFilterPreset(
                id: selectedId,
                name: selectedName,
                readFilter: "unread",
                contentFilter: "unknownSender",
                sortMode: "id",
                sortAscending: true,
                searchText: "ops"
            ),
            makeOfflineMessageFilterPreset(
                id: unselectedId,
                name: unselectedName,
                readFilter: "all",
                contentFilter: "bodyNotLoaded",
                sortMode: "timestamp",
                sortAscending: false,
                searchText: "away"
            )
        ])

        let restoredCount = try model.importOfflineMessageFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.offlineMessageFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.readFilter, "read")
        XCTAssertEqual(existing.contentFilter, "withBody")
        XCTAssertEqual(existing.sortMode, "sender")
        XCTAssertEqual(existing.sortAscending, true)
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.offlineMessageFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.readFilter, "unread")
        XCTAssertEqual(selected.contentFilter, "unknownSender")
        XCTAssertEqual(selected.sortMode, "id")
        XCTAssertEqual(selected.sortAscending, true)
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.offlineMessageFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func encodedOfflineMessageFilterPresets(_ presets: [TS3OfflineMessageFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeOfflineMessageFilterPreset(
        id: UUID,
        name: String,
        readFilter: String,
        contentFilter: String,
        sortMode: String,
        sortAscending: Bool,
        searchText: String
    ) -> TS3OfflineMessageFilterPreset {
        TS3OfflineMessageFilterPreset(
            id: id,
            name: name,
            readFilter: readFilter,
            contentFilter: contentFilter,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
