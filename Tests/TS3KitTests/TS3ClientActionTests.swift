import XCTest
@testable import TS3iOSApp

final class TS3ClientActionTests: XCTestCase {
    @MainActor
    func testOnlineUserComplaintAndContactEntryPointsOpenTargetedSheets() {
        let model = TS3AppModel()
        let user = makeUser(uniqueIdentifier: "user-1")

        model.showContacts(for: user)
        model.showComplaints(for: user)

        XCTAssertTrue(model.isShowingContacts)
        XCTAssertTrue(model.isShowingComplaints)
        XCTAssertEqual(model.complaintTarget?.id, user.id)
    }

    @MainActor
    func testOnlineUserContactEntryPointRequiresUniqueIdentifier() {
        let model = TS3AppModel()
        let user = makeUser(uniqueIdentifier: nil)

        model.showContacts(for: user)

        XCTAssertFalse(model.isShowingContacts)
        XCTAssertEqual(model.lastError, "The server did not provide a unique id for Tester.")
    }

    @MainActor
    func testOnlineContactCandidatesSkipCurrentUserAndMissingUniqueIds() {
        let model = TS3AppModel()
        model.clients = [
            makeUser(id: 1, uniqueIdentifier: "self", nickname: "Me", isCurrentUser: true),
            makeUser(id: 2, uniqueIdentifier: "user-2", nickname: "Beta"),
            makeUser(id: 3, uniqueIdentifier: nil, nickname: "Anonymous")
        ]

        XCTAssertEqual(model.onlineContactCandidates.map(\.uniqueIdentifier), ["user-2"])

        model.updateOnlineContacts(status: .friend)

        XCTAssertEqual(model.contacts.count, 1)
        XCTAssertEqual(model.contacts.first?.nickname, "Beta")
        XCTAssertEqual(model.contacts.first?.status, .friend)
    }

    @MainActor
    func testOnlineContactCandidatesRefreshExistingContactNickname() {
        let model = TS3AppModel()
        model.addContact(uniqueIdentifier: "user-2", nickname: "Old", status: .ignored, note: "keep")
        model.clients = [
            makeUser(id: 2, uniqueIdentifier: "user-2", nickname: "New")
        ]

        XCTAssertEqual(model.onlineContactCandidates.first?.nickname, "New")

        model.updateOnlineContacts(status: .blocked)

        XCTAssertEqual(model.contacts.count, 1)
        XCTAssertEqual(model.contacts.first?.nickname, "New")
        XCTAssertEqual(model.contacts.first?.status, .blocked)
        XCTAssertEqual(model.contacts.first?.note, "keep")
    }

    private func makeUser(
        id: Int = 12,
        uniqueIdentifier: String?,
        nickname: String = "Tester",
        isCurrentUser: Bool = false
    ) -> TS3UserSummary {
        TS3UserSummary(
            id: id,
            channelId: 5,
            databaseId: 44,
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            isCurrentUser: isCurrentUser,
            isInputMuted: false,
            isOutputMuted: false,
            isAway: false,
            awayMessage: nil,
            isChannelCommander: false,
            isPrioritySpeaker: false,
            isTalker: false,
            isRequestingTalkPower: false,
            talkRequestMessage: nil,
            talkPower: nil,
            channelGroupId: nil,
            serverGroups: [],
            description: nil,
            avatarHash: nil,
            avatarURL: nil,
            iconId: nil,
            iconURL: nil,
            version: nil,
            platform: nil,
            country: nil,
            ipAddress: nil,
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            idleTimeSeconds: nil,
            connectedSeconds: nil
        )
    }
}
