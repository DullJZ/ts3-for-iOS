import XCTest
@testable import TS3iOSApp
import TS3Kit

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
        model.contacts = []
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
        model.contacts = []
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

    @MainActor
    func testComplaintSourceContactActionsUseLoadedDatabaseClient() throws {
        let model = TS3AppModel()
        model.contacts = []
        model.databaseClients = []
        model.clients = []
        let complaint = makeComplaint(sourceDatabaseId: 77, sourceName: "Reported")
        model.databaseClients = [
            makeDatabaseClient(id: 77, uniqueIdentifier: "source-uid", nickname: "Loaded Source")
        ]

        model.setComplaintSourceContactStatus(.blocked, for: complaint)

        let contact = try XCTUnwrap(model.contacts.first { $0.uniqueIdentifier == "source-uid" })
        XCTAssertEqual(contact.nickname, "Loaded Source")
        XCTAssertEqual(contact.status, .blocked)
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testComplaintSourceContactActionsFallbackToOnlineUser() throws {
        let model = TS3AppModel()
        model.contacts = []
        model.databaseClients = []
        model.clients = []
        let complaint = makeComplaint(sourceDatabaseId: 44, sourceName: "Online Source")
        model.clients = [
            makeUser(id: 5, uniqueIdentifier: "online-uid", nickname: "Online Source")
        ]

        model.setComplaintSourceContactStatus(.friend, for: complaint)

        let contact = try XCTUnwrap(model.contacts.first { $0.uniqueIdentifier == "online-uid" })
        XCTAssertEqual(contact.nickname, "Online Source")
        XCTAssertEqual(contact.status, .friend)
    }

    @MainActor
    func testComplaintSourceContactActionsRequireLoadedSourceIdentity() {
        let model = TS3AppModel()
        model.contacts = []
        model.databaseClients = []
        model.clients = []
        let complaint = makeComplaint(sourceDatabaseId: 77, sourceName: "Unknown")

        model.setComplaintSourceContactStatus(.ignored, for: complaint)

        XCTAssertTrue(model.contacts.isEmpty)
        XCTAssertEqual(model.lastError, "Load the source database client before changing contact status.")
    }

    @MainActor
    func testGroupMemberContactNoteUsesDatabaseRecordIdentity() throws {
        let model = TS3AppModel()
        model.contacts = []
        let member = TS3GroupClientSummary(client: TS3GroupClient(
            clientDatabaseId: 99,
            uniqueIdentifier: "group-member-uid",
            nickname: "Group Member",
            channelId: 12
        ))
        let record = TS3DatabaseClientSummary(groupClient: member)

        model.setContactStatus(.friend, for: record)
        model.setContactNote("trusted operator", for: record)

        let contact = try XCTUnwrap(model.contacts.first { $0.uniqueIdentifier == "group-member-uid" })
        XCTAssertEqual(contact.nickname, "Group Member")
        XCTAssertEqual(contact.status, .friend)
        XCTAssertEqual(contact.note, "trusted operator")
        XCTAssertEqual(model.contactNote(for: record), "trusted operator")
    }

    @MainActor
    func testGroupMemberRecordResolvesOnlineUserForPokeAndPrivateMessageActions() throws {
        let model = TS3AppModel()
        model.clients = [
            makeUser(id: 7, databaseId: 99, uniqueIdentifier: "group-member-uid", nickname: "Online Member"),
            makeUser(id: 8, databaseId: 100, uniqueIdentifier: "other-uid", nickname: "Other")
        ]
        let member = TS3GroupClientSummary(client: TS3GroupClient(
            clientDatabaseId: 99,
            uniqueIdentifier: "group-member-uid",
            nickname: "Group Member",
            channelId: 12
        ))
        let record = TS3DatabaseClientSummary(groupClient: member)

        let onlineUser = try XCTUnwrap(model.onlineUser(for: record))

        XCTAssertEqual(onlineUser.id, 7)
        XCTAssertEqual(onlineUser.nickname, "Online Member")
    }

    @MainActor
    func testDatabaseClientActionAvailabilityUsesUniqueIdentifierAndOnlinePresence() {
        let model = TS3AppModel()
        model.clients = [
            makeUser(id: 7, databaseId: 99, uniqueIdentifier: "loaded-uid", nickname: "Online Client")
        ]
        let loadedRecord = makeDatabaseClient(id: 99, uniqueIdentifier: "loaded-uid", nickname: "Loaded")
        let offlineRecord = makeDatabaseClient(id: 100, uniqueIdentifier: "offline-uid", nickname: "Offline")
        let missingIdentityRecord = makeDatabaseClient(id: 101, uniqueIdentifier: nil, nickname: "Missing")

        XCTAssertTrue(model.canSendOfflineMessage(to: loadedRecord))
        XCTAssertTrue(model.canBanDatabaseClient(loadedRecord))
        XCTAssertTrue(model.hasOnlineClientActions(for: loadedRecord))

        XCTAssertTrue(model.canSendOfflineMessage(to: offlineRecord))
        XCTAssertTrue(model.canBanDatabaseClient(offlineRecord))
        XCTAssertFalse(model.hasOnlineClientActions(for: offlineRecord))

        XCTAssertFalse(model.canSendOfflineMessage(to: missingIdentityRecord))
        XCTAssertFalse(model.canBanDatabaseClient(missingIdentityRecord))
        XCTAssertFalse(model.hasOnlineClientActions(for: missingIdentityRecord))
    }

    @MainActor
    func testPokeEventResolvesOnlineSenderByClientIdThenUniqueIdentifier() throws {
        let model = TS3AppModel()
        model.clients = [
            makeUser(id: 7, uniqueIdentifier: "sender-uid", nickname: "Runtime Sender"),
            makeUser(id: 8, uniqueIdentifier: "fallback-uid", nickname: "Fallback Sender")
        ]
        let runtimePoke = TS3PokeSummary(
            senderId: 7,
            senderName: "Old Runtime Name",
            senderUniqueIdentifier: "fallback-uid",
            message: "ping",
            isOwnPoke: false
        )
        let fallbackPoke = TS3PokeSummary(
            senderId: nil,
            senderName: "Old Fallback Name",
            senderUniqueIdentifier: "fallback-uid",
            message: "ping",
            isOwnPoke: false
        )

        let runtimeSender = try XCTUnwrap(model.onlineUser(for: runtimePoke))
        let fallbackSender = try XCTUnwrap(model.onlineUser(for: fallbackPoke))

        XCTAssertEqual(runtimeSender.id, 7)
        XCTAssertEqual(runtimeSender.nickname, "Runtime Sender")
        XCTAssertEqual(fallbackSender.id, 8)
        XCTAssertEqual(fallbackSender.nickname, "Fallback Sender")
    }

    private func makeUser(
        id: Int = 12,
        databaseId: Int? = 44,
        uniqueIdentifier: String?,
        nickname: String = "Tester",
        isCurrentUser: Bool = false
    ) -> TS3UserSummary {
        TS3UserSummary(
            id: id,
            channelId: 5,
            databaseId: databaseId,
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

    private func makeDatabaseClient(id: Int, uniqueIdentifier: String?, nickname: String) -> TS3DatabaseClientSummary {
        TS3DatabaseClientSummary(
            id: id,
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )
    }

    private func makeComplaint(sourceDatabaseId: Int, sourceName: String?) -> TS3ComplaintSummary {
        TS3ComplaintSummary(entry: TS3ComplaintEntry(
            targetClientDatabaseId: 12,
            targetName: "Target",
            sourceClientDatabaseId: sourceDatabaseId,
            sourceName: sourceName,
            message: "Complaint",
            timestamp: nil
        ))
    }
}
