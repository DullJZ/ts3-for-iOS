import XCTest
@testable import TS3iOSApp
import TS3Kit

final class TS3ClientActionTests: XCTestCase {
    func testTalkRequestQueueSummaryCountsRequestScope() {
        let summary = TS3TalkRequestQueueSummary(users: [
            makeUser(
                id: 1,
                uniqueIdentifier: "alpha",
                nickname: "Alpha",
                channelId: 10,
                isRequestingTalkPower: true,
                talkRequestMessage: "Need to brief"
            ),
            makeUser(
                id: 2,
                uniqueIdentifier: "beta",
                nickname: "Beta",
                channelId: 10,
                isRequestingTalkPower: true,
                talkRequestMessage: "   "
            ),
            makeUser(
                id: 3,
                uniqueIdentifier: "gamma",
                nickname: "Gamma",
                channelId: 12,
                isRequestingTalkPower: false,
                talkRequestMessage: "ignored"
            )
        ])

        XCTAssertEqual(summary.requestCount, 2)
        XCTAssertEqual(summary.channelCount, 1)
        XCTAssertEqual(summary.messageCount, 1)
        XCTAssertEqual(summary.requesters, ["Alpha", "Beta"])
        XCTAssertEqual(summary.channelIds, [10])
        XCTAssertTrue(summary.hasRequests)
        XCTAssertTrue(summary.hasMessages)
        XCTAssertEqual(
            summary.clipboardSummary,
            "requests=2 | channels=1 | messages=1 | channelIds=10 | requesters=Alpha,Beta"
        )
    }

    func testTalkRequestQueueSummaryHandlesEmptyQueue() {
        let summary = TS3TalkRequestQueueSummary(users: [
            makeUser(
                id: 1,
                uniqueIdentifier: "alpha",
                nickname: "Alpha",
                channelId: 10,
                isRequestingTalkPower: false
            )
        ])

        XCTAssertEqual(summary.requestCount, 0)
        XCTAssertEqual(summary.channelCount, 0)
        XCTAssertEqual(summary.messageCount, 0)
        XCTAssertFalse(summary.hasRequests)
        XCTAssertFalse(summary.hasMessages)
        XCTAssertEqual(summary.clipboardSummary, "requests=0 | channels=0 | messages=0")
    }

    func testClientModerationReadinessSummaryCountsKickRequirements() {
        let summary = TS3ClientModerationReadinessSummary(
            action: .kickServer,
            targetName: " Guest ",
            targetClientId: 12,
            reason: " Rule violation ",
            isBanPermanent: false,
            isBanCustomDuration: false,
            banDurationSeconds: nil,
            isConnected: true
        )

        XCTAssertEqual(summary.requirements, [.connected, .target, .positiveClientId, .singleLineReason])
        XCTAssertEqual(summary.satisfiedRequirementCount, 4)
        XCTAssertEqual(summary.totalRequirementCount, 4)
        XCTAssertEqual(summary.missingRequirementCount, 0)
        XCTAssertEqual(summary.missingRequirements, [])
        XCTAssertTrue(summary.canSubmit)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "action=kickServer | readiness=4/4 | missingRequirements=0 | canSubmit=true | targetName=true | clientId=true | reason=true | banDuration=n/a | customBanDuration=false | requirements=connected:true,target:true,positiveClientId:true,singleLineReason:true | missing=none | needsAttention=false"
        )
    }

    func testClientModerationReadinessSummaryFlagsDisconnectedInvalidBan() {
        let summary = TS3ClientModerationReadinessSummary(
            action: .ban,
            targetName: " ",
            targetClientId: 0,
            reason: "spam\nabuse",
            isBanPermanent: false,
            isBanCustomDuration: true,
            banDurationSeconds: nil,
            isConnected: false
        )

        XCTAssertEqual(
            summary.requirements,
            [.connected, .target, .positiveClientId, .singleLineReason, .validBanDuration]
        )
        XCTAssertEqual(summary.satisfiedRequirementCount, 0)
        XCTAssertEqual(summary.totalRequirementCount, 5)
        XCTAssertEqual(summary.missingRequirementCount, 5)
        XCTAssertEqual(
            summary.missingRequirements,
            [.connected, .target, .positiveClientId, .singleLineReason, .validBanDuration]
        )
        XCTAssertFalse(summary.canSubmit)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "action=ban | readiness=0/5 | missingRequirements=5 | canSubmit=false | targetName=false | clientId=false | reason=true | banDuration=temporary | customBanDuration=true | requirements=connected:false,target:false,positiveClientId:false,singleLineReason:false,validBanDuration:false | missing=connected,target,positiveClientId,singleLineReason,validBanDuration | needsAttention=true"
        )
    }

    func testClientMoveReadinessSummaryCountsReadyUnprotectedMove() {
        let summary = TS3ClientMoveReadinessSummary(
            targetName: " Guest ",
            targetClientId: 12,
            currentChannelId: 5,
            destinationChannel: makeChannel(id: 10, name: "Lobby", isPasswordProtected: false),
            providedPassword: "",
            hasSavedPassword: false,
            isConnected: true
        )

        XCTAssertEqual(summary.satisfiedRequirementCount, 6)
        XCTAssertEqual(summary.totalRequirementCount, 6)
        XCTAssertEqual(summary.missingRequirementCount, 0)
        XCTAssertEqual(summary.missingRequirements, [TS3ClientMoveRequirement]())
        XCTAssertTrue(summary.canSubmit)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targetName=true | clientId=12 | fromChannel=5 | toChannel=10 | toName=Lobby | readiness=6/6 | missingRequirements=0 | canSubmit=true | sameChannel=false | requiresPassword=false | providedPassword=false | savedPassword=false | requirements=connected:true,target:true,positiveClientId:true,destinationChannel:true,differentChannel:true,channelPassword:true | missing=none | needsAttention=false"
        )
    }

    func testClientMoveReadinessSummaryFlagsMissingChannelPassword() {
        let summary = TS3ClientMoveReadinessSummary(
            targetName: "Guest",
            targetClientId: 12,
            currentChannelId: 5,
            destinationChannel: makeChannel(id: 10, name: "Raid", isPasswordProtected: true),
            providedPassword: " ",
            hasSavedPassword: false,
            isConnected: true
        )

        XCTAssertEqual(summary.satisfiedRequirementCount, 5)
        XCTAssertEqual(summary.totalRequirementCount, 6)
        XCTAssertEqual(summary.missingRequirementCount, 1)
        XCTAssertEqual(summary.missingRequirements, [TS3ClientMoveRequirement.channelPassword])
        XCTAssertFalse(summary.canSubmit)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targetName=true | clientId=12 | fromChannel=5 | toChannel=10 | toName=Raid | readiness=5/6 | missingRequirements=1 | canSubmit=false | sameChannel=false | requiresPassword=true | providedPassword=false | savedPassword=false | requirements=connected:true,target:true,positiveClientId:true,destinationChannel:true,differentChannel:true,channelPassword:false | missing=channelPassword | needsAttention=true"
        )
    }

    func testOnlineClientActionAuditSummaryCountsAvailableAreas() {
        let user = makeUser(
            id: 12,
            databaseId: 44,
            uniqueIdentifier: "user-uid",
            nickname: "Guest",
            channelId: 5,
            serverGroups: [1, 2]
        )
        let summary = TS3OnlineClientActionAuditSummary(
            user: user,
            isConnected: true,
            availableServerGroupCount: 3,
            assignedServerGroupCount: 2,
            channelGroupCount: 4,
            movableChannelCount: 5,
            currentChannelKnown: true
        )

        XCTAssertEqual(summary.availableAreaCount, 7)
        XCTAssertEqual(summary.totalAreaCount, 7)
        XCTAssertEqual(summary.blockedAreaCount, 0)
        XCTAssertEqual(summary.blockedAreas, [TS3OnlineClientActionArea]())
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "clientId=12 | nickname=Guest | connected=true | currentUser=false | uid=true | databaseId=true | currentChannel=true | movableChannels=5 | availableServerGroups=3 | assignedServerGroups=2 | channelGroups=4 | areas=7/7 | blockedAreas=0 | areaStates=identity:true,contact:true,messaging:true,voiceControls:true,moderation:true,administration:true,movement:true | blocked=none | needsAttention=false"
        )
    }

    func testOnlineClientActionAuditSummaryFlagsBlockedAreas() {
        let user = makeUser(
            id: 7,
            databaseId: nil,
            uniqueIdentifier: nil,
            nickname: "Me",
            isCurrentUser: true,
            channelId: 99
        )
        let summary = TS3OnlineClientActionAuditSummary(
            user: user,
            isConnected: true,
            availableServerGroupCount: 0,
            assignedServerGroupCount: 0,
            channelGroupCount: 0,
            movableChannelCount: 0,
            currentChannelKnown: false
        )

        XCTAssertEqual(summary.availableAreaCount, 4)
        XCTAssertEqual(summary.totalAreaCount, 7)
        XCTAssertEqual(summary.blockedAreaCount, 3)
        XCTAssertEqual(summary.blockedAreas, [.contact, .moderation, .movement])
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "clientId=7 | nickname=Me | connected=true | currentUser=true | uid=false | databaseId=false | currentChannel=false | movableChannels=0 | availableServerGroups=0 | assignedServerGroups=0 | channelGroups=0 | areas=4/7 | blockedAreas=3 | areaStates=identity:true,contact:false,messaging:true,voiceControls:true,moderation:false,administration:true,movement:false | blocked=contact,moderation,movement | needsAttention=true"
        )
    }

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

    @MainActor
    func testPokeEventCanCreateContactFromSenderUniqueIdentifier() throws {
        let model = TS3AppModel()
        model.contacts = []
        let poke = TS3PokeSummary(
            senderId: nil,
            senderName: " Offline Sender ",
            senderUniqueIdentifier: " uid-poke ",
            message: "ping",
            isOwnPoke: false
        )

        model.addContact(from: poke, status: .ignored, note: "from poke")

        let contact = try XCTUnwrap(model.contacts.first)
        XCTAssertEqual(contact.uniqueIdentifier, "uid-poke")
        XCTAssertEqual(contact.nickname, "Offline Sender")
        XCTAssertEqual(contact.status, .ignored)
        XCTAssertEqual(contact.note, "from poke")
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testOfflineMessageCanCreateContactFromSenderUniqueIdentifier() throws {
        let model = TS3AppModel()
        model.contacts = []
        let message = TS3OfflineMessageSummary(
            id: 42,
            senderUniqueIdentifier: " uid-message ",
            senderName: " ",
            subject: "hello",
            message: "body",
            timestamp: nil,
            isRead: false
        )

        model.addContact(from: message, status: .blocked, note: "from inbox")

        let contact = try XCTUnwrap(model.contacts.first)
        XCTAssertEqual(contact.uniqueIdentifier, "uid-message")
        XCTAssertEqual(contact.nickname, "uid-message")
        XCTAssertEqual(contact.status, .blocked)
        XCTAssertEqual(contact.note, "from inbox")
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testPrivateChatMessageCanCreateContactFromOnlineSender() throws {
        let model = TS3AppModel()
        model.contacts = []
        model.clients = [
            makeUser(id: 21, uniqueIdentifier: "chat-uid", nickname: "Chat Sender")
        ]
        let message = makeChatMessage(senderId: 21, senderName: "Old Chat Sender")

        let sender = try XCTUnwrap(model.onlineUser(for: message))
        XCTAssertEqual(sender.uniqueIdentifier, "chat-uid")

        model.addContact(from: message, status: .ignored, note: "from chat")

        let contact = try XCTUnwrap(model.contacts.first)
        XCTAssertEqual(contact.uniqueIdentifier, "chat-uid")
        XCTAssertEqual(contact.nickname, "Chat Sender")
        XCTAssertEqual(contact.status, .ignored)
        XCTAssertEqual(contact.note, "from chat")
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testPrivateChatSenderCanOpenTargetedComplaints() throws {
        let model = TS3AppModel()
        model.clients = [
            makeUser(id: 21, databaseId: 77, uniqueIdentifier: "chat-uid", nickname: "Chat Sender")
        ]
        let message = makeChatMessage(senderId: 21, senderName: "Old Chat Sender")

        let sender = try XCTUnwrap(model.onlineUser(for: message))
        model.showComplaints(for: sender)

        XCTAssertTrue(model.isShowingComplaints)
        XCTAssertEqual(model.complaintTarget?.id, 21)
        XCTAssertEqual(model.complaintTarget?.databaseId, 77)
    }

    @MainActor
    func testPrivateChatContactActionRequiresOnlineSenderIdentity() {
        let model = TS3AppModel()
        model.contacts = []
        model.clients = []

        model.addContact(from: makeChatMessage(senderId: 21))

        XCTAssertTrue(model.contacts.isEmpty)
        XCTAssertEqual(model.lastError, "The chat sender is no longer online.")
    }

    @MainActor
    func testOfflineEventContactActionsRequireUniqueIdentifier() {
        let model = TS3AppModel()
        model.contacts = []
        let poke = TS3PokeSummary(
            senderId: nil,
            senderName: "No UID",
            senderUniqueIdentifier: nil,
            message: "ping",
            isOwnPoke: false
        )
        let message = TS3OfflineMessageSummary(
            id: 43,
            senderUniqueIdentifier: " ",
            senderName: "No UID",
            subject: "hello",
            message: nil,
            timestamp: nil,
            isRead: false
        )

        model.addContact(from: poke)
        XCTAssertTrue(model.contacts.isEmpty)
        XCTAssertEqual(model.lastError, "The poke sender did not provide a unique id.")

        model.addContact(from: message)
        XCTAssertTrue(model.contacts.isEmpty)
        XCTAssertEqual(model.lastError, "The offline message sender did not provide a unique id.")
    }

    @MainActor
    func testContactDatabaseLookupRequiresUniqueIdentifier() {
        let model = TS3AppModel()
        let contact = makeContact(uniqueIdentifier: "   ", nickname: "Missing UID")

        model.findDatabaseClient(for: contact)

        XCTAssertEqual(model.lastError, "The contact does not have a unique id.")
        XCTAssertFalse(model.isShowingClientDatabase)
    }

    @MainActor
    func testContactDatabaseLookupUsesTrimmedUniqueIdentifier() {
        let model = TS3AppModel()
        let contact = makeContact(uniqueIdentifier: " contact-uid ", nickname: "Contact")

        model.findDatabaseClient(for: contact)

        XCTAssertEqual(model.lastError, "Connect to a server first.")
        XCTAssertFalse(model.isShowingClientDatabase)
    }

    @MainActor
    func testContactUniqueIdBanUsesBanDraftValidation() {
        let model = TS3AppModel()
        let contact = makeContact(uniqueIdentifier: " contact-uid ", nickname: "Contact")

        model.banContact(contact, durationSeconds: nil, reason: "line one\nline two")

        XCTAssertEqual(model.lastError, "Ban reason must be a single line.")
    }

    private func makeUser(
        id: Int = 12,
        databaseId: Int? = 44,
        uniqueIdentifier: String?,
        nickname: String = "Tester",
        isCurrentUser: Bool = false,
        channelId: Int = 5,
        isRequestingTalkPower: Bool = false,
        talkRequestMessage: String? = nil,
        serverGroups: [Int] = []
    ) -> TS3UserSummary {
        TS3UserSummary(
            id: id,
            channelId: channelId,
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
            isRequestingTalkPower: isRequestingTalkPower,
            talkRequestMessage: talkRequestMessage,
            talkPower: nil,
            channelGroupId: nil,
            serverGroups: serverGroups,
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

    private func makeChannel(id: Int, name: String, isPasswordProtected: Bool) -> TS3ChannelSummary {
        TS3ChannelSummary(
            id: id,
            name: name,
            isDefault: false,
            isPasswordProtected: isPasswordProtected,
            isPermanent: false,
            isCurrent: false
        )
    }

    private func makeContact(uniqueIdentifier: String, nickname: String) -> TS3ContactEntry {
        TS3ContactEntry(
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            status: .friend,
            note: "",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
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

    private func makeChatMessage(
        senderId: Int?,
        senderName: String = "Chat Sender",
        isOwnMessage: Bool = false
    ) -> TS3ChatMessageSummary {
        TS3ChatMessageSummary(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            targetMode: .client,
            targetId: 1,
            senderId: senderId,
            senderName: senderName,
            message: "hello",
            isOwnMessage: isOwnMessage
        )
    }
}
