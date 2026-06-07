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

    private func makeUser(uniqueIdentifier: String?) -> TS3UserSummary {
        TS3UserSummary(
            id: 12,
            channelId: 5,
            databaseId: 44,
            uniqueIdentifier: uniqueIdentifier,
            nickname: "Tester",
            isCurrentUser: false,
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
