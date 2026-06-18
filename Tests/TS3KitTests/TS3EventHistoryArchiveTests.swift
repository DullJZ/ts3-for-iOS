import XCTest
@testable import TS3iOSApp

final class TS3EventHistoryArchiveTests: XCTestCase {
    func testEventAndPokeRowActionLocalizationKeysExist() throws {
        let keys = [
            "events.activityRow.copySummary",
            "events.activityRow.copyMessage",
            "events.pokeRow.privateMessage",
            "events.pokeRow.pokeBack",
            "events.pokeRow.offlineReply",
            "events.pokeRow.addContact",
            "events.pokeRow.copyPoke",
            "events.pokeRow.copyMessage",
            "events.pokeRow.copyUser",
            "events.pokeRow.copyUniqueId",
            "events.pokeReply.subject",
            "events.pokeReply.message",
            "events.pokeReply.copySummary",
            "events.pokeReply.send",
            "events.pokeReply.defaultSubject"
        ]
        let resourceRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/TS3iOSApp/Resources")
        let localizationFiles = [
            resourceRoot.appendingPathComponent("en.lproj/Localizable.strings"),
            resourceRoot.appendingPathComponent("zh-Hans.lproj/Localizable.strings")
        ]

        for fileURL in localizationFiles {
            let contents = try String(contentsOf: fileURL)
            for key in keys {
                XCTAssertTrue(
                    contents.contains("\"\(key)\" ="),
                    "Missing \(key) in \(fileURL.path)"
                )
            }
        }
    }

    @MainActor
    func testEventHistoryArchivePreviewIncludesCopyableActivityAndPokeSummaries() throws {
        let model = TS3AppModel()
        model.clearEventHistory()
        let archiveJSON = """
        {
          "activityEvents": [
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "timestamp": 1700000000,
              "kind": "clientMoved",
              "clientId": 12,
              "clientName": "Taylor",
              "channelId": 4,
              "channelName": "Lobby",
              "fromChannelId": 2,
              "toChannelId": 4,
              "invokerName": "Admin",
              "reasonId": 5,
              "reasonMessage": "Requested",
              "isOwnClient": false
            },
            {
              "id": "00000000-0000-0000-0000-000000000003",
              "timestamp": 1700000200,
              "kind": "clientMoved",
              "clientId": 13,
              "clientName": "Riley",
              "channelId": 5,
              "channelName": "Ops",
              "fromChannelId": 4,
              "toChannelId": 5,
              "isOwnClient": true
            },
            {
              "id": "00000000-0000-0000-0000-000000000004",
              "timestamp": 1700000300,
              "kind": "clientEntered",
              "clientId": 14,
              "clientName": "Quinn",
              "channelId": 4,
              "channelName": "Lobby",
              "isOwnClient": false
            }
          ],
          "pokeEvents": [
            {
              "id": "00000000-0000-0000-0000-000000000002",
              "timestamp": 1700000100,
              "senderId": 9,
              "senderName": "Morgan",
              "senderUniqueIdentifier": "uid-m",
              "message": "Ping",
              "isOwnPoke": true
            },
            {
              "id": "00000000-0000-0000-0000-000000000005",
              "timestamp": 1700000400,
              "senderId": 10,
              "senderName": "Alex",
              "senderUniqueIdentifier": "uid-a",
              "message": "Hello",
              "isOwnPoke": false
            }
          ]
        }
        """

        let preview = try model.eventHistoryArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.activityCount, 3)
        XCTAssertEqual(preview.pokeCount, 2)
        XCTAssertEqual(preview.currentActivityCount, 0)
        XCTAssertEqual(preview.currentPokeCount, 0)
        XCTAssertEqual(
            preview.activityKindSummaries,
            [
                "activityKind=clientMoved count=2",
                "activityKind=clientEntered count=1"
            ]
        )
        XCTAssertEqual(
            preview.pokeDirectionSummaries,
            [
                "pokeDirection=in count=1",
                "pokeDirection=out count=1"
            ]
        )
        XCTAssertEqual(
            preview.activitySummaries,
            [
                "kind=clientMoved | client=Taylor | clientId=12 | timestamp=2678307200 | own=false | channel=Lobby | channelId=4 | from=2 | to=4 | invoker=Admin | reasonId=5 | reason=Requested",
                "kind=clientMoved | client=Riley | clientId=13 | timestamp=2678307400 | own=true | channel=Ops | channelId=5 | from=4 | to=5",
                "kind=clientEntered | client=Quinn | clientId=14 | timestamp=2678307500 | own=false | channel=Lobby | channelId=4"
            ]
        )
        XCTAssertEqual(
            preview.pokeSummaries,
            [
                "direction=out | sender=Morgan | timestamp=2678307300 | senderId=9 | senderUid=uid-m | message=Ping",
                "direction=in | sender=Alex | timestamp=2678307600 | senderId=10 | senderUid=uid-a | message=Hello"
            ]
        )
        XCTAssertEqual(
            preview.candidates.map(\.id),
            [
                "activity:00000000-0000-0000-0000-000000000001",
                "activity:00000000-0000-0000-0000-000000000003",
                "activity:00000000-0000-0000-0000-000000000004",
                "poke:00000000-0000-0000-0000-000000000002",
                "poke:00000000-0000-0000-0000-000000000005"
            ]
        )
        XCTAssertEqual(preview.candidates.filter { $0.kind == .activity }.count, 3)
        XCTAssertEqual(preview.candidates.filter { $0.kind == .poke }.count, 2)
        XCTAssertTrue(preview.containsEvent(id: "activity:00000000-0000-0000-0000-000000000001"))
        XCTAssertTrue(preview.containsEvent(id: "poke:00000000-0000-0000-0000-000000000002"))
        XCTAssertFalse(preview.containsEvent(id: "activity:00000000-0000-0000-0000-000000000002"))
        XCTAssertEqual(
            preview.clipboardSummary,
            (
                preview.activityKindSummaries
                + preview.pokeDirectionSummaries
                + preview.activitySummaries
                + preview.pokeSummaries
            ).joined(separator: "\n")
        )
        XCTAssertTrue(preview.hasEvents)
    }

    @MainActor
    func testEventHistoryArchiveRestoreCanRestoreSelectedEvents() throws {
        let model = TS3AppModel()
        model.clearEventHistory()
        let archiveJSON = """
        {
          "activityEvents": [
            {
              "id": "00000000-0000-0000-0000-000000000001",
              "timestamp": 1700000000,
              "kind": "clientMoved",
              "clientId": 12,
              "clientName": "Taylor",
              "isOwnClient": false
            },
            {
              "id": "00000000-0000-0000-0000-000000000003",
              "timestamp": 1700000200,
              "kind": "clientEntered",
              "clientId": 13,
              "clientName": "Riley",
              "isOwnClient": true
            }
          ],
          "pokeEvents": [
            {
              "id": "00000000-0000-0000-0000-000000000002",
              "timestamp": 1700000100,
              "senderId": 9,
              "senderName": "Morgan",
              "senderUniqueIdentifier": "uid-m",
              "message": "Ping",
              "isOwnPoke": true
            },
            {
              "id": "00000000-0000-0000-0000-000000000005",
              "timestamp": 1700000400,
              "senderId": 10,
              "senderName": "Alex",
              "senderUniqueIdentifier": "uid-a",
              "message": "Hello",
              "isOwnPoke": false
            }
          ]
        }
        """

        try model.restoreEventHistoryArchive(
            from: Data(archiveJSON.utf8),
            selectedEventIds: [
                "activity:00000000-0000-0000-0000-000000000003",
                "poke:00000000-0000-0000-0000-000000000002"
            ]
        )

        XCTAssertEqual(model.activityEvents.map(\.clientName), ["Riley"])
        XCTAssertEqual(model.pokeEvents.map(\.senderName), ["Morgan"])
        XCTAssertEqual(model.unreadActivityCount, 0)
        XCTAssertEqual(model.unreadPokeCount, 0)
        XCTAssertEqual(model.lastError, nil)
        model.clearEventHistory()
    }

    func testPokeSummaryCopyAndAccessibilityText() {
        let poke = TS3PokeSummary(
            timestamp: Date(timeIntervalSince1970: 1_700_000_100),
            senderId: 9,
            senderName: "Morgan",
            senderUniqueIdentifier: " uid-m ",
            message: " Ping ",
            isOwnPoke: false
        )

        XCTAssertEqual(poke.messageText, "Ping")
        XCTAssertEqual(poke.displayTitle, "From Morgan")
        XCTAssertEqual(
            poke.clipboardSummary,
            "direction=in | sender=Morgan | timestamp=1700000100 | senderId=9 | senderUid=uid-m | message=Ping"
        )
        XCTAssertEqual(
            poke.accessibilityValue,
            "Received from Morgan. Message Ping. Unique ID available"
        )
    }

    func testActivitySummaryCopyAndAccessibilityText() {
        let activity = TS3ActivitySummary(
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            kind: .clientMoved,
            clientId: 12,
            clientName: "Taylor",
            channelId: 4,
            channelName: "Lobby",
            fromChannelId: 2,
            toChannelId: 4,
            invokerName: "Admin",
            reasonId: 5,
            reasonMessage: "Requested",
            isOwnClient: false
        )

        XCTAssertEqual(
            activity.clipboardSummary,
            "kind=clientMoved | client=Taylor | clientId=12 | timestamp=1700000000 | own=false | channel=Lobby | channelId=4 | from=2 | to=4 | invoker=Admin | reasonId=5 | reason=Requested"
        )
        XCTAssertEqual(
            activity.accessibilityValue,
            "Client moved. Client Taylor. Channel Lobby. From channel ID 2. To channel ID 4. Invoker Admin. Reason Requested"
        )
        XCTAssertEqual(
            activity.rowAccessibilityValue(messageText: "moved from Lobby to Support", detailText: "by Admin"),
            "Client moved. Client Taylor. Channel Lobby. From channel ID 2. To channel ID 4. Invoker Admin. Reason Requested. moved from Lobby to Support. by Admin"
        )
    }

    func testPokeSummaryUsesDefaultMessageForBlankPokes() {
        let poke = TS3PokeSummary(
            timestamp: Date(timeIntervalSince1970: 1_700_000_200),
            senderId: nil,
            senderName: "Avery",
            senderUniqueIdentifier: nil,
            message: " ",
            isOwnPoke: true
        )

        XCTAssertEqual(poke.messageText, "Poke")
        XCTAssertEqual(poke.displayTitle, "Sent to Avery")
        XCTAssertEqual(
            poke.clipboardSummary,
            "direction=out | sender=Avery | timestamp=1700000200 | message=Poke"
        )
        XCTAssertEqual(
            poke.accessibilityValue,
            "Sent to Avery. Message Poke"
        )
    }

    func testPokeListSummaryDeduplicatesAndCountsVisiblePokes() {
        let duplicateId = UUID()
        let summary = TS3PokeListSummary(pokes: [
            TS3PokeSummary(
                id: duplicateId,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                senderId: 9,
                senderName: "Morgan",
                senderUniqueIdentifier: "uid-m",
                message: "Ping",
                isOwnPoke: false
            ),
            TS3PokeSummary(
                timestamp: Date(timeIntervalSince1970: 1_700_000_100),
                senderId: nil,
                senderName: "Avery",
                senderUniqueIdentifier: nil,
                message: " ",
                isOwnPoke: true
            ),
            TS3PokeSummary(
                timestamp: Date(timeIntervalSince1970: 1_700_000_200),
                senderId: 10,
                senderName: "Morgan",
                senderUniqueIdentifier: " uid-m ",
                message: "Again",
                isOwnPoke: false
            ),
            TS3PokeSummary(
                id: duplicateId,
                timestamp: Date(timeIntervalSince1970: 1_700_000_300),
                senderId: 11,
                senderName: "Duplicate",
                senderUniqueIdentifier: nil,
                message: "Duplicate",
                isOwnPoke: true
            )
        ])

        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.incomingCount, 2)
        XCTAssertEqual(summary.outgoingCount, 1)
        XCTAssertEqual(summary.withUniqueIdCount, 2)
        XCTAssertEqual(summary.withoutUniqueIdCount, 1)
        XCTAssertEqual(summary.defaultMessageCount, 1)
        XCTAssertEqual(summary.customMessageCount, 2)
        XCTAssertEqual(summary.distinctParticipantCount, 2)
        XCTAssertEqual(summary.earliestTimestamp, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(summary.latestTimestamp, Date(timeIntervalSince1970: 1_700_000_200))
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "pokes=3 | incoming=2 | outgoing=1 | withUid=2 | withoutUid=1 | defaultMessage=1 | customMessage=2 | distinctParticipants=2 | earliestTimestamp=1700000000 | latestTimestamp=1700000200 | needsAttention=true"
        )
    }

    func testPokeClearImpactSummaryReportsVisibleCleanupRisk() {
        let duplicateId = UUID()
        let impact = TS3PokeClearImpactSummary(pokes: [
            TS3PokeSummary(
                id: duplicateId,
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                senderId: 9,
                senderName: "Morgan",
                senderUniqueIdentifier: "uid-m",
                message: "Ping",
                isOwnPoke: false
            ),
            TS3PokeSummary(
                timestamp: Date(timeIntervalSince1970: 1_700_000_100),
                senderId: nil,
                senderName: "Avery",
                senderUniqueIdentifier: nil,
                message: " ",
                isOwnPoke: true
            ),
            TS3PokeSummary(
                timestamp: Date(timeIntervalSince1970: 1_700_000_200),
                senderId: 10,
                senderName: "Morgan",
                senderUniqueIdentifier: " uid-m ",
                message: "Again",
                isOwnPoke: false
            ),
            TS3PokeSummary(
                id: duplicateId,
                timestamp: Date(timeIntervalSince1970: 1_700_000_300),
                senderId: 11,
                senderName: "Duplicate",
                senderUniqueIdentifier: nil,
                message: "Duplicate",
                isOwnPoke: true
            )
        ])

        XCTAssertEqual(impact.clearingCount, 3)
        XCTAssertEqual(impact.incomingCount, 2)
        XCTAssertEqual(impact.outgoingCount, 1)
        XCTAssertEqual(impact.withUniqueIdCount, 2)
        XCTAssertEqual(impact.withoutUniqueIdCount, 1)
        XCTAssertEqual(impact.defaultMessageCount, 1)
        XCTAssertEqual(impact.customMessageCount, 2)
        XCTAssertEqual(impact.distinctParticipantCount, 2)
        XCTAssertEqual(impact.earliestTimestamp, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(impact.latestTimestamp, Date(timeIntervalSince1970: 1_700_000_200))
        XCTAssertTrue(impact.needsAttention)
        XCTAssertEqual(
            impact.clipboardSummary,
            "clearing=3 | incoming=2 | outgoing=1 | withUid=2 | withoutUid=1 | defaultMessage=1 | customMessage=2 | distinctParticipants=2 | earliestTimestamp=1700000000 | latestTimestamp=1700000200 | needsAttention=true"
        )
    }

    func testPokeClearImpactSummaryMarksEmptySelectionForReview() {
        let impact = TS3PokeClearImpactSummary(pokes: [])

        XCTAssertEqual(impact.clearingCount, 0)
        XCTAssertTrue(impact.needsAttention)
        XCTAssertEqual(
            impact.clipboardSummary,
            "clearing=0 | incoming=0 | outgoing=0 | withUid=0 | withoutUid=0 | defaultMessage=0 | customMessage=0 | distinctParticipants=0 | earliestTimestamp=none | latestTimestamp=none | needsAttention=true"
        )
    }

    func testPokeOfficialCoverageAuditSummaryCountsCoveredAreas() {
        let draftSummary = TS3PokeDraftCoverageSummary(
            targetName: "Taylor",
            targetClientId: 12,
            message: "Wake up",
            validationMessages: []
        )
        let pokes = [
            TS3PokeSummary(
                timestamp: Date(timeIntervalSince1970: 1_700_000_000),
                senderId: 12,
                senderName: "Taylor",
                senderUniqueIdentifier: "uid-taylor",
                message: "Wake up",
                isOwnPoke: false
            ),
            TS3PokeSummary(
                timestamp: Date(timeIntervalSince1970: 1_700_000_100),
                senderId: 13,
                senderName: "Avery",
                senderUniqueIdentifier: "uid-avery",
                message: " ",
                isOwnPoke: true
            )
        ]
        let listSummary = TS3PokeListSummary(pokes: pokes)
        let clearImpact = TS3PokeClearImpactSummary(pokes: pokes)

        let summary = TS3PokeOfficialCoverageAuditSummary(
            draftCoverageSummary: draftSummary,
            visiblePokeSummary: listSummary,
            clearImpactSummary: clearImpact,
            hasLocalFilters: true,
            hasFilterPresets: true,
            hasArchiveCoverage: true,
            canSendPoke: true,
            hasPokeBackActions: true,
            hasOfflineReplyActions: true,
            hasContactActions: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 9)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 9)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 18)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=9/9 | missingOfficialAreas=0 | officialActions=18 | draftTargets=2 | customDraftMessage=true | visiblePokes=2 | incoming=1 | outgoing=1 | withUid=2 | customMessages=1 | clearVisible=2 | localFilters=true | filterPresets=true | archiveCoverage=true | sendPoke=true | pokeBack=true | offlineReply=true | contactActions=true | needsAttention=true"
        )
    }

    func testPokeOfficialCoverageAuditSummaryFlagsMissingWorkflowAreas() {
        let emptyList = TS3PokeListSummary(pokes: [])
        let emptyClearImpact = TS3PokeClearImpactSummary(pokes: [])

        let summary = TS3PokeOfficialCoverageAuditSummary(
            draftCoverageSummary: nil,
            visiblePokeSummary: emptyList,
            clearImpactSummary: emptyClearImpact,
            hasLocalFilters: false,
            hasFilterPresets: false,
            hasArchiveCoverage: false,
            canSendPoke: false,
            hasPokeBackActions: false,
            hasOfflineReplyActions: false,
            hasContactActions: false
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 0)
        XCTAssertEqual(summary.missingOfficialAreaCount, 9)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=0/9 | missingOfficialAreas=9 | officialActions=18 | draftTargets=0 | customDraftMessage=false | visiblePokes=0 | incoming=0 | outgoing=0 | withUid=0 | customMessages=0 | clearVisible=0 | localFilters=false | filterPresets=false | archiveCoverage=false | sendPoke=false | pokeBack=false | offlineReply=false | contactActions=false | needsAttention=true"
        )
    }

    func testPokeDraftValidatorRejectsMissingTargetAndMultilineMessage() {
        XCTAssertEqual(
            TS3PokeDraftValidator.validationMessages(
                targetName: " ",
                targetClientId: nil,
                message: "Wake\nup"
            ),
            [
                "Select a client before sending a poke.",
                "Poke message must be a single line."
            ]
        )
        XCTAssertEqual(
            TS3PokeDraftValidator.validationMessages(
                targetName: "Taylor",
                targetClientId: 0,
                message: "Wake up"
            ),
            [
                "Target client id must be positive before sending a poke."
            ]
        )
    }

    func testPokeDraftValidatorSummariesUseDefaultAndCustomMessage() {
        XCTAssertEqual(
            TS3PokeDraftValidator.creationSummary(
                targetName: " Taylor ",
                targetClientId: 12,
                message: " "
            ),
            "target=Taylor | clientId=12 | message=Poke"
        )
        XCTAssertEqual(
            TS3PokeDraftValidator.creationSummary(
                targetName: "Taylor",
                targetClientId: 12,
                message: "Wake up"
            ),
            "target=Taylor | clientId=12 | message=Wake up"
        )
    }

    func testPokeDraftCoverageSummaryCountsTargetAndCustomMessage() {
        let validationMessages = TS3PokeDraftValidator.validationMessages(
            targetName: " Taylor ",
            targetClientId: 12,
            message: " Wake up "
        )
        let summary = TS3PokeDraftCoverageSummary(
            targetName: " Taylor ",
            targetClientId: 12,
            message: " Wake up ",
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.targetFieldCount, 2)
        XCTAssertTrue(summary.hasTargetName)
        XCTAssertTrue(summary.hasTargetClientId)
        XCTAssertTrue(summary.hasCustomMessage)
        XCTAssertEqual(summary.validationIssueCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targetFields=2 | targetName=true | clientId=true | customMessage=true | validationIssues=0 | needsAttention=false"
        )
    }

    func testPokeDraftCoverageSummaryFlagsMissingInvalidDraft() {
        let validationMessages = TS3PokeDraftValidator.validationMessages(
            targetName: " ",
            targetClientId: nil,
            message: "Wake\nup"
        )
        let summary = TS3PokeDraftCoverageSummary(
            targetName: " ",
            targetClientId: nil,
            message: "Wake\nup",
            validationMessages: validationMessages
        )

        XCTAssertEqual(summary.targetFieldCount, 0)
        XCTAssertFalse(summary.hasTargetName)
        XCTAssertFalse(summary.hasTargetClientId)
        XCTAssertTrue(summary.hasCustomMessage)
        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "targetFields=0 | targetName=false | clientId=false | customMessage=true | validationIssues=2 | needsAttention=true"
        )
    }

    func testEventFilterPresetSummaryAndAccessibilityText() {
        let preset = makeEventFilterPreset(
            id: UUID(),
            name: "Ops Events",
            eventFilter: "clientMovement",
            sourceFilter: "others",
            newestFirst: false,
            searchText: "ops"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Ops Events | eventFilter=clientMovement | sourceFilter=others | newestFirst=false | search=ops"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Event filter clientMovement. Source filter others. Oldest first. Search ops"
        )
    }

    @MainActor
    func testEventFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Event Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importEventFilterPresets(from: encodedEventFilterPresets([
            makeEventFilterPreset(id: existingId, name: existingName, eventFilter: "activity", sourceFilter: "own", searchText: "keep")
        ]))
        let data = try encodedEventFilterPresets([
            makeEventFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                eventFilter: "invalidEvent",
                sourceFilter: "invalidSource",
                searchText: "  search value  "
            ),
            makeEventFilterPreset(
                id: newId,
                name: " Raid Events \(suffix) ",
                eventFilter: "clientMovement",
                sourceFilter: "others",
                newestFirst: false,
                searchText: String(repeating: "x", count: 140)
            ),
            makeEventFilterPreset(
                id: invalidId,
                name: "   ",
                eventFilter: "pokes",
                sourceFilter: "own",
                searchText: "ignored"
            )
        ])

        let preview = try model.eventFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | eventFilter=all | sourceFilter=all | newestFirst=true | search=search value",
            "name=Raid Events \(suffix) | eventFilter=clientMovement | sourceFilter=others | newestFirst=false | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped event filter presets: 1"))
    }

    @MainActor
    func testEventFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Event Filter \(suffix)"
        let selectedName = "Selected Event Filter \(suffix)"
        let unselectedName = "Unselected Event Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importEventFilterPresets(from: encodedEventFilterPresets([
            makeEventFilterPreset(id: existingId, name: existingName, eventFilter: "activity", sourceFilter: "own", searchText: "keep")
        ]))
        let data = try encodedEventFilterPresets([
            makeEventFilterPreset(id: existingId, name: existingName, eventFilter: "pokes", sourceFilter: "others", searchText: "replace"),
            makeEventFilterPreset(
                id: selectedId,
                name: selectedName,
                eventFilter: "channelChanges",
                sourceFilter: "others",
                newestFirst: false,
                searchText: "ops"
            ),
            makeEventFilterPreset(id: unselectedId, name: unselectedName, eventFilter: "pokes", sourceFilter: "own", searchText: "away")
        ])

        let restoredCount = try model.importEventFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.eventFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.eventFilter, "activity")
        XCTAssertEqual(existing.sourceFilter, "own")
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.eventFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.eventFilter, "channelChanges")
        XCTAssertEqual(selected.sourceFilter, "others")
        XCTAssertEqual(selected.newestFirst, false)
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.eventFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func encodedEventFilterPresets(_ presets: [TS3EventFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeEventFilterPreset(
        id: UUID,
        name: String,
        eventFilter: String,
        sourceFilter: String,
        newestFirst: Bool = true,
        searchText: String
    ) -> TS3EventFilterPreset {
        TS3EventFilterPreset(
            id: id,
            name: name,
            eventFilter: eventFilter,
            sourceFilter: sourceFilter,
            newestFirst: newestFirst,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
