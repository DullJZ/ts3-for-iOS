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
}
