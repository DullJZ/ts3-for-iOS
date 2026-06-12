import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3ChatTranscriptTests: XCTestCase {
    @MainActor
    func testChatTranscriptIncludesMetadataConversationGroupsAndMultiLineMessages() {
        let model = TS3AppModel()
        model.channels = [
            TS3ChannelSummary(
                id: 12,
                parentId: nil,
                order: nil,
                name: "Lobby",
                phoneticName: nil,
                topic: nil,
                description: nil,
                isDefault: false,
                isPasswordProtected: false,
                isPermanent: true,
                isSemiPermanent: nil,
                neededTalkPower: nil,
                neededJoinPower: nil,
                neededSubscribePower: nil,
                neededDescriptionViewPower: nil,
                codec: nil,
                codecQuality: nil,
                codecLatencyFactor: nil,
                isCodecUnencrypted: nil,
                deleteDelaySeconds: nil,
                maxClients: nil,
                maxFamilyClients: nil,
                maxClientsUnlimited: nil,
                maxFamilyClientsUnlimited: nil,
                maxFamilyClientsInherited: nil,
                iconId: nil,
                iconURL: nil,
                isSubscribed: nil,
                isCurrent: false
            )
        ]

        let generatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let messages = [
            makeMessage(
                id: "00000000-0000-0000-0000-000000000002",
                timestamp: Date(timeIntervalSince1970: 1_700_000_020),
                mode: .channel,
                targetId: 12,
                senderId: 7,
                senderName: "Avery",
                message: "hello\nagain",
                isOwnMessage: false
            ),
            makeMessage(
                id: "00000000-0000-0000-0000-000000000001",
                timestamp: Date(timeIntervalSince1970: 1_700_000_010),
                mode: .server,
                targetId: nil,
                senderId: 1,
                senderName: "Me",
                message: "server note",
                isOwnMessage: true
            )
        ]

        let transcript = model.chatTranscriptText(
            messages: messages,
            title: "Visible Chat",
            filterSummary: "Channel Messages | Other Users",
            generatedAt: generatedAt
        )

        XCTAssertTrue(transcript.contains("TeamSpeak 3 Chat Transcript"))
        XCTAssertTrue(transcript.contains("Generated: 2023-11-14T22:13:20.000Z"))
        XCTAssertTrue(transcript.contains("Scope: Visible Chat"))
        XCTAssertTrue(transcript.contains("Filters: Channel Messages | Other Users"))
        XCTAssertTrue(transcript.contains("Messages: 2"))
        XCTAssertTrue(transcript.contains("## Server Chat"))
        XCTAssertTrue(transcript.contains("2023-11-14T22:13:30.000Z [out] Me: server note"))
        XCTAssertTrue(transcript.contains("## Channel Chat: Lobby (12)"))
        XCTAssertTrue(transcript.contains("2023-11-14T22:13:40.000Z [in] Avery: hello\n    again"))
    }

    @MainActor
    func testEmptyChatTranscriptStillIncludesMetadata() {
        let model = TS3AppModel()
        let transcript = model.chatTranscriptText(
            messages: [],
            title: "Private",
            filterSummary: "Search: missing",
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(
            transcript,
            [
                "TeamSpeak 3 Chat Transcript",
                "Generated: 2023-11-14T22:13:20.000Z",
                "Scope: Private",
                "Filters: Search: missing",
                "Messages: 0"
            ].joined(separator: "\n")
        )
    }

    func testChatFilterPresetSummaryAndAccessibilityText() {
        let preset = makeChatFilterPreset(
            id: UUID(),
            name: "Ops Chat",
            messageFilter: "privateMessage",
            senderFilter: "others",
            newestFirst: true,
            searchText: "ops"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Ops Chat | messageFilter=privateMessage | senderFilter=others | newestFirst=true | search=ops"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Message filter privateMessage. Sender filter others. Newest first. Search ops"
        )
    }

    @MainActor
    func testChatFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Chat Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importChatFilterPresets(from: encodedChatFilterPresets([
            makeChatFilterPreset(id: existingId, name: existingName, messageFilter: "channel", senderFilter: "own", searchText: "keep")
        ]))
        let data = try encodedChatFilterPresets([
            makeChatFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                messageFilter: "invalidMessage",
                senderFilter: "invalidSender",
                searchText: "  search value  "
            ),
            makeChatFilterPreset(
                id: newId,
                name: " Raid Chat \(suffix) ",
                messageFilter: "privateMessage",
                senderFilter: "others",
                newestFirst: true,
                searchText: String(repeating: "x", count: 140)
            ),
            makeChatFilterPreset(
                id: invalidId,
                name: "   ",
                messageFilter: "server",
                senderFilter: "own",
                searchText: "ignored"
            )
        ])

        let preview = try model.chatFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | messageFilter=all | senderFilter=all | newestFirst=false | search=search value",
            "name=Raid Chat \(suffix) | messageFilter=privateMessage | senderFilter=others | newestFirst=true | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped chat filter presets: 1"))
    }

    @MainActor
    func testChatFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Chat Filter \(suffix)"
        let selectedName = "Selected Chat Filter \(suffix)"
        let unselectedName = "Unselected Chat Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importChatFilterPresets(from: encodedChatFilterPresets([
            makeChatFilterPreset(id: existingId, name: existingName, messageFilter: "channel", senderFilter: "own", searchText: "keep")
        ]))
        let data = try encodedChatFilterPresets([
            makeChatFilterPreset(id: existingId, name: existingName, messageFilter: "server", senderFilter: "others", searchText: "replace"),
            makeChatFilterPreset(
                id: selectedId,
                name: selectedName,
                messageFilter: "privateMessage",
                senderFilter: "others",
                newestFirst: true,
                searchText: "ops"
            ),
            makeChatFilterPreset(id: unselectedId, name: unselectedName, messageFilter: "server", senderFilter: "own", searchText: "away")
        ])

        let restoredCount = try model.importChatFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.chatFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.messageFilter, "channel")
        XCTAssertEqual(existing.senderFilter, "own")
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.chatFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.messageFilter, "privateMessage")
        XCTAssertEqual(selected.senderFilter, "others")
        XCTAssertEqual(selected.newestFirst, true)
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.chatFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func makeMessage(
        id: String,
        timestamp: Date,
        mode: TS3TextMessageTargetMode,
        targetId: Int?,
        senderId: Int?,
        senderName: String,
        message: String,
        isOwnMessage: Bool
    ) -> TS3ChatMessageSummary {
        TS3ChatMessageSummary(
            id: UUID(uuidString: id)!,
            timestamp: timestamp,
            targetMode: mode,
            targetId: targetId,
            senderId: senderId,
            senderName: senderName,
            message: message,
            isOwnMessage: isOwnMessage
        )
    }

    private func encodedChatFilterPresets(_ presets: [TS3ChatFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeChatFilterPreset(
        id: UUID,
        name: String,
        messageFilter: String,
        senderFilter: String,
        newestFirst: Bool = false,
        searchText: String
    ) -> TS3ChatFilterPreset {
        TS3ChatFilterPreset(
            id: id,
            name: name,
            messageFilter: messageFilter,
            senderFilter: senderFilter,
            newestFirst: newestFirst,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
