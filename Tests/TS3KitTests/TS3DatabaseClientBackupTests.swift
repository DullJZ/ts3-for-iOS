import XCTest
@testable import TS3iOSApp

final class TS3DatabaseClientBackupTests: XCTestCase {
    func testDatabaseClientFilterPresetSummaryAndAccessibilityText() {
        let preset = TS3DatabaseClientFilterPreset(
            name: "Active DB Clients",
            recordFilter: "withUniqueId",
            sortMode: "lastConnected",
            sortAscending: false,
            localFilterText: "ops",
            batchSize: 250
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Active DB Clients | recordFilter=withUniqueId | sortMode=lastConnected | sortAscending=false | batchSize=250 | localFilter=ops"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Database client filter withUniqueId. Sort by lastConnected. Descending. Batch size 250. Filter ops"
        )
    }

    func testDatabaseClientSummaryCopyAndAccessibilityText() {
        let client = TS3DatabaseClientSummary(
            id: 7,
            uniqueIdentifier: "uid-b",
            nickname: "Beta",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastConnectedAt: Date(timeIntervalSince1970: 1_700_000_100),
            totalConnections: 5,
            description: "Has note",
            lastIP: "203.0.113.7"
        )

        XCTAssertEqual(
            client.backupSummary,
            "db=7 | nickname=Beta | uid=uid-b | connections=5 | lastIP=203.0.113.7 | description=true | created=1700000000 | lastConnected=1700000100"
        )
        XCTAssertEqual(
            client.clipboardSummary,
            "db=7 | nickname=Beta | uid=uid-b | connections=5 | lastIP=203.0.113.7 | description=true | created=1700000000 | lastConnected=1700000100 | descriptionText=Has note"
        )
        XCTAssertEqual(
            client.accessibilityValue,
            "Database client 7. Nickname Beta. Unique identifier available. 5 connections. Last IP available. Description available. Created date available. Last connected date available"
        )
    }

    func testDatabaseClientListSummaryDeduplicatesAndCountsVisibleRecords() {
        let beta = TS3DatabaseClientSummary(
            id: 7,
            uniqueIdentifier: "uid-b",
            nickname: "Beta",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastConnectedAt: Date(timeIntervalSince1970: 1_700_000_100),
            totalConnections: 5,
            description: "Has note",
            lastIP: "203.0.113.7"
        )
        let alpha = TS3DatabaseClientSummary(
            id: 6,
            uniqueIdentifier: nil,
            nickname: "Alpha",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )
        let duplicate = TS3DatabaseClientSummary(
            id: 7,
            uniqueIdentifier: "ignored",
            nickname: "Duplicate",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            lastConnectedAt: Date(timeIntervalSince1970: 1_800_000_100),
            totalConnections: 10,
            description: "Ignored",
            lastIP: "198.51.100.9"
        )

        let summary = TS3DatabaseClientListSummary(clients: [beta, alpha, duplicate])

        XCTAssertEqual(summary.totalCount, 2)
        XCTAssertEqual(summary.uniqueIdentifierCount, 1)
        XCTAssertEqual(summary.descriptionCount, 1)
        XCTAssertEqual(summary.lastIPCount, 1)
        XCTAssertEqual(summary.connectionCount, 1)
        XCTAssertEqual(summary.createdCount, 1)
        XCTAssertEqual(summary.lastConnectedCount, 1)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "databaseClients=2 | withUID=1 | withDescription=1 | withLastIP=1 | withConnections=1 | withCreatedDate=1 | withLastConnectedDate=1 | latestConnection=2023-11-14T22:15:00Z | needsAttention=true"
        )
    }

    func testDatabaseClientActionSummaryCountsAvailableActions() {
        let client = TS3DatabaseClientSummary(
            id: 7,
            uniqueIdentifier: "uid-b",
            nickname: "Beta",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )

        let summary = TS3DatabaseClientActionSummary(
            record: client,
            isOnline: true,
            canSendOfflineMessage: true,
            canBan: true,
            contactStatus: .friend,
            hasContactNote: true,
            serverGroupCount: 3,
            canSaveBookmark: true
        )

        XCTAssertTrue(summary.hasUniqueIdentifier)
        XCTAssertEqual(summary.identityActionCount, 5)
        XCTAssertEqual(summary.contactActionCount, 5)
        XCTAssertEqual(summary.messagingActionCount, 3)
        XCTAssertEqual(summary.adminActionCount, 8)
        XCTAssertEqual(summary.onlineActionCount, 3)
        XCTAssertEqual(summary.bookmarkActionCount, 3)
        XCTAssertEqual(summary.availableActionCount, 24)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "db=7 | nickname=Beta | actions=24 | identity=5 | contact=5 | messaging=3 | admin=8 | online=3 | bookmark=3 | status=friend | note=true | uid=true | bookmarkSave=true | needsAttention=false"
        )
    }

    func testDatabaseClientActionSummaryFlagsMissingUniqueIdentifier() {
        let client = TS3DatabaseClientSummary(
            id: 6,
            uniqueIdentifier: " ",
            nickname: "Alpha",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )

        let summary = TS3DatabaseClientActionSummary(
            record: client,
            isOnline: false,
            canSendOfflineMessage: false,
            canBan: false,
            contactStatus: .neutral,
            hasContactNote: false,
            serverGroupCount: 3
        )

        XCTAssertFalse(summary.hasUniqueIdentifier)
        XCTAssertEqual(summary.identityActionCount, 3)
        XCTAssertEqual(summary.contactActionCount, 0)
        XCTAssertEqual(summary.messagingActionCount, 0)
        XCTAssertEqual(summary.adminActionCount, 4)
        XCTAssertEqual(summary.onlineActionCount, 1)
        XCTAssertEqual(summary.bookmarkActionCount, 2)
        XCTAssertEqual(summary.availableActionCount, 9)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "db=6 | nickname=Alpha | actions=9 | identity=3 | contact=0 | messaging=0 | admin=4 | online=1 | bookmark=2 | status=neutral | note=false | uid=false | bookmarkSave=false | needsAttention=true"
        )
    }

    func testDatabaseClientOfficialActionAuditSummaryCountsOfficialAreas() {
        let client = TS3DatabaseClientSummary(
            id: 7,
            uniqueIdentifier: "uid-b",
            nickname: "Beta",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )
        let actionSummary = TS3DatabaseClientActionSummary(
            record: client,
            isOnline: true,
            canSendOfflineMessage: true,
            canBan: true,
            contactStatus: .friend,
            hasContactNote: true,
            serverGroupCount: 3,
            canSaveBookmark: true
        )
        let audit = TS3DatabaseClientOfficialActionAuditSummary(actionSummary: actionSummary)

        XCTAssertEqual(audit.totalActionCount, 27)
        XCTAssertEqual(audit.availableAreaCount, 6)
        XCTAssertEqual(audit.blockedAreaCount, 0)
        XCTAssertFalse(audit.needsAttention)
        XCTAssertEqual(
            audit.clipboardSummary,
            "db=7 | nickname=Beta | officialActions=27 | availableOfficialAreas=6 | blockedOfficialAreas=0 | uid=true | online=true | offlineMessage=true | canBan=true | bookmark=true | areas=identityLookup:5,contactManagement:5,messaging:3,administration:8,onlineContext:3,bookmark:3 | needsAttention=false"
        )
    }

    func testDatabaseClientOfficialActionAuditSummaryFlagsBlockedAreas() {
        let client = TS3DatabaseClientSummary(
            id: 6,
            uniqueIdentifier: " ",
            nickname: "Alpha",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )
        let actionSummary = TS3DatabaseClientActionSummary(
            record: client,
            isOnline: false,
            canSendOfflineMessage: false,
            canBan: false,
            contactStatus: .neutral,
            hasContactNote: false,
            serverGroupCount: 3
        )
        let audit = TS3DatabaseClientOfficialActionAuditSummary(actionSummary: actionSummary)

        XCTAssertEqual(audit.totalActionCount, 10)
        XCTAssertEqual(audit.availableAreaCount, 4)
        XCTAssertEqual(audit.blockedAreaCount, 2)
        XCTAssertTrue(audit.needsAttention)
        XCTAssertEqual(
            audit.clipboardSummary,
            "db=6 | nickname=Alpha | officialActions=10 | availableOfficialAreas=4 | blockedOfficialAreas=2 | uid=false | online=false | offlineMessage=false | canBan=false | bookmark=false | areas=identityLookup:3,administration:4,onlineContext:1,bookmark:2 | needsAttention=true"
        )
    }

    func testDatabaseClientActionReadinessSummaryCountsRequirements() {
        let client = TS3DatabaseClientSummary(
            id: 7,
            uniqueIdentifier: "uid-b",
            nickname: "Beta",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )
        let actionSummary = TS3DatabaseClientActionSummary(
            record: client,
            isOnline: true,
            canSendOfflineMessage: true,
            canBan: true,
            contactStatus: .friend,
            hasContactNote: true,
            serverGroupCount: 3,
            canSaveBookmark: true
        )
        let readiness = TS3DatabaseClientActionReadinessSummary(actionSummary: actionSummary)

        XCTAssertEqual(readiness.satisfiedRequirementCount, 6)
        XCTAssertEqual(readiness.totalRequirementCount, 6)
        XCTAssertEqual(readiness.missingRequirementCount, 0)
        XCTAssertEqual(readiness.missingRequirements, [])
        XCTAssertEqual(readiness.blockedOfficialAreaCount, 0)
        XCTAssertFalse(readiness.needsAttention)
        XCTAssertEqual(
            readiness.clipboardSummary,
            "db=7 | nickname=Beta | readiness=6/6 | missingRequirements=0 | blockedOfficialAreas=0 | requirements=uniqueIdentifier:true,onlineClient:true,offlineMessage:true,banPermission:true,serverGroups:true,bookmarkSave:true | missing=none | needsAttention=false"
        )
    }

    func testDatabaseClientActionReadinessSummaryFlagsMissingRequirements() {
        let client = TS3DatabaseClientSummary(
            id: 6,
            uniqueIdentifier: " ",
            nickname: "Alpha",
            createdAt: nil,
            lastConnectedAt: nil,
            totalConnections: nil,
            description: nil,
            lastIP: nil
        )
        let actionSummary = TS3DatabaseClientActionSummary(
            record: client,
            isOnline: false,
            canSendOfflineMessage: false,
            canBan: false,
            contactStatus: .neutral,
            hasContactNote: false,
            serverGroupCount: 3
        )
        let readiness = TS3DatabaseClientActionReadinessSummary(actionSummary: actionSummary)

        XCTAssertEqual(readiness.satisfiedRequirementCount, 0)
        XCTAssertEqual(readiness.totalRequirementCount, 6)
        XCTAssertEqual(readiness.missingRequirementCount, 6)
        XCTAssertEqual(
            readiness.missingRequirements,
            [.uniqueIdentifier, .onlineClient, .offlineMessage, .banPermission, .serverGroups, .bookmarkSave]
        )
        XCTAssertEqual(readiness.blockedOfficialAreaCount, 2)
        XCTAssertTrue(readiness.needsAttention)
        XCTAssertEqual(
            readiness.clipboardSummary,
            "db=6 | nickname=Alpha | readiness=0/6 | missingRequirements=6 | blockedOfficialAreas=2 | requirements=uniqueIdentifier:false,onlineClient:false,offlineMessage:false,banPermission:false,serverGroups:false,bookmarkSave:false | missing=uniqueIdentifier,onlineClient,offlineMessage,banPermission,serverGroups,bookmarkSave | needsAttention=true"
        )
    }

    @MainActor
    func testDatabaseClientBackupPreviewSanitizesCountsAndSummaries() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            {
              "id": 7,
              "uniqueIdentifier": " uid-b ",
              "nickname": " Beta ",
              "createdAt": 1700000000,
              "lastConnectedAt": 1700000100,
              "totalConnections": 5,
              "description": " Has note ",
              "lastIP": " 203.0.113.7 "
            },
            {
              "id": 6,
              "uniqueIdentifier": "",
              "nickname": " Alpha ",
              "description": "   "
            },
            {
              "id": 7,
              "nickname": "Duplicate"
            },
            {
              "id": 0,
              "nickname": "Invalid"
            },
            {
              "id": 9,
              "nickname": "   "
            }
          ]
        }
        """

        let preview = try model.databaseClientBackupPreview(from: Data(backupJSON.utf8))

        XCTAssertEqual(preview.clientCount, 2)
        XCTAssertEqual(preview.skippedClientCount, 3)
        XCTAssertEqual(preview.uniqueIdentifierCount, 1)
        XCTAssertEqual(preview.descriptionCount, 1)
        XCTAssertEqual(preview.lastIPCount, 1)
        XCTAssertEqual(preview.connectionCount, 1)
        XCTAssertEqual(preview.fieldSummaries, [
            "field=connections count=1",
            "field=created count=1",
            "field=description count=1",
            "field=lastConnected count=1",
            "field=lastIP count=1",
            "field=uid count=1"
        ])
        XCTAssertEqual(preview.firstNickname, "Alpha")
        XCTAssertEqual(preview.firstDatabaseId, 6)
        XCTAssertEqual(
            preview.clientSummaries,
            [
                "db=6 | nickname=Alpha",
                "db=7 | nickname=Beta | uid=uid-b | connections=5 | lastIP=203.0.113.7 | description=true | created=2678307200 | lastConnected=2678307300"
            ]
        )
        XCTAssertEqual(preview.candidates.map(\.id), [6, 7])
        XCTAssertEqual(preview.candidates.last?.nickname, "Beta")
        XCTAssertEqual(preview.candidates.last?.uniqueIdentifier, "uid-b")
        XCTAssertEqual(preview.candidates.last?.description, "Has note")
        XCTAssertEqual(preview.candidates.last?.lastIP, "203.0.113.7")
        XCTAssertEqual(preview.candidates.last?.totalConnections, 5)
        XCTAssertNotNil(preview.candidates.last?.createdAt)
        XCTAssertNotNil(preview.candidates.last?.lastConnectedAt)
        XCTAssertEqual(
            preview.candidates.map(\.summary),
            [
                "db=6 | nickname=Alpha",
                "db=7 | nickname=Beta | uid=uid-b | connections=5 | lastIP=203.0.113.7 | description=true | created=2678307200 | lastConnected=2678307300"
            ]
        )
        XCTAssertTrue(preview.containsClient(id: 7))
        XCTAssertFalse(preview.containsClient(id: 9))
        XCTAssertEqual(
            preview.clipboardSummary,
            (preview.fieldSummaries + preview.clientSummaries).joined(separator: "\n")
        )
        XCTAssertTrue(preview.hasClients)
    }

    @MainActor
    func testDatabaseClientImportImpactSummaryCountsSelectedClients() throws {
        let model = TS3AppModel()
        let backupJSON = """
        {
          "entries": [
            {
              "id": 7,
              "uniqueIdentifier": " uid-b ",
              "nickname": " Beta ",
              "createdAt": 1700000000,
              "lastConnectedAt": 1700000100,
              "totalConnections": 5,
              "description": " Has note ",
              "lastIP": " 203.0.113.7 "
            },
            {
              "id": 6,
              "uniqueIdentifier": "",
              "nickname": " Alpha ",
              "description": "   "
            },
            {
              "id": 7,
              "nickname": "Duplicate"
            },
            {
              "id": 0,
              "nickname": "Invalid"
            }
          ]
        }
        """

        let preview = try model.databaseClientBackupPreview(from: Data(backupJSON.utf8))
        let summary = TS3DatabaseClientImportImpactSummary(
            preview: preview,
            selectedClientIds: Set(preview.candidates.map(\.id))
        )

        XCTAssertEqual(summary.selectedClientCount, 2)
        XCTAssertEqual(summary.uniqueIdentifierCount, 1)
        XCTAssertEqual(summary.missingUniqueIdentifierCount, 1)
        XCTAssertEqual(summary.descriptionCount, 1)
        XCTAssertEqual(summary.lastIPCount, 1)
        XCTAssertEqual(summary.connectionCount, 1)
        XCTAssertEqual(summary.createdDateCount, 1)
        XCTAssertEqual(summary.lastConnectedDateCount, 1)
        XCTAssertEqual(summary.skippedClientCount, 2)
        XCTAssertTrue(summary.hasSelection)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "selected=2 | uid=1 | missingUid=1 | descriptions=1 | lastIP=1 | connections=1 | createdDates=1 | lastConnectedDates=1 | skippedBackupClients=2 | needsAttention=true"
        )
    }

    @MainActor
    func testDatabaseClientBackupImportReplacesLocalCachedClients() throws {
        let model = TS3AppModel()
        model.databaseClients = [
            TS3DatabaseClientSummary(
                id: 1,
                uniqueIdentifier: "old",
                nickname: "Old",
                createdAt: nil,
                lastConnectedAt: nil,
                totalConnections: nil,
                description: nil,
                lastIP: nil
            )
        ]
        let backupJSON = """
        {
          "entries": [
            {
              "id": 12,
              "uniqueIdentifier": " uid-z ",
              "nickname": " Zed "
            },
            {
              "id": 11,
              "nickname": " Ada "
            }
          ]
        }
        """

        try model.importDatabaseClientBackup(from: Data(backupJSON.utf8))

        XCTAssertEqual(model.databaseClients.map(\.id), [11, 12])
        XCTAssertEqual(model.databaseClients.map(\.nickname), ["Ada", "Zed"])
        XCTAssertEqual(model.databaseClients.last?.uniqueIdentifier, "uid-z")
        XCTAssertEqual(model.lastError, nil)
    }

    @MainActor
    func testDatabaseClientBackupImportCanRestoreSelectedClients() throws {
        let model = TS3AppModel()
        model.databaseClients = [
            TS3DatabaseClientSummary(
                id: 1,
                uniqueIdentifier: "old",
                nickname: "Old",
                createdAt: nil,
                lastConnectedAt: nil,
                totalConnections: nil,
                description: nil,
                lastIP: nil
            )
        ]
        let backupJSON = """
        {
          "entries": [
            {
              "id": 12,
              "uniqueIdentifier": " uid-z ",
              "nickname": " Zed "
            },
            {
              "id": 11,
              "nickname": " Ada "
            },
            {
              "id": 14,
              "nickname": " Mina "
            }
          ]
        }
        """

        try model.importDatabaseClientBackup(from: Data(backupJSON.utf8), selectedClientIds: [12, 14])

        XCTAssertEqual(model.databaseClients.map(\.id), [14, 12])
        XCTAssertEqual(model.databaseClients.map(\.nickname), ["Mina", "Zed"])
        XCTAssertEqual(model.databaseClients.last?.uniqueIdentifier, "uid-z")
        XCTAssertEqual(model.lastError, nil)
    }

    @MainActor
    func testDatabaseClientFilterPresetImportPreviewSanitizesCandidates() throws {
        let model = TS3AppModel()
        let existingName = "Database Existing Preview Preset"
        let importedName = "Database Sanitized Preview Preset"
        deleteDatabaseFilterPresets(named: existingName, in: model)
        deleteDatabaseFilterPresets(named: importedName, in: model)
        defer {
            deleteDatabaseFilterPresets(named: existingName, in: model)
            deleteDatabaseFilterPresets(named: importedName, in: model)
        }
        model.saveDatabaseClientFilterPreset(
            name: existingName,
            recordFilter: "withUniqueId",
            sortMode: "databaseId",
            sortAscending: true,
            localFilterText: "old",
            batchSize: 50
        )
        let longFilter = String(repeating: "x", count: 140)
        let data = Data("""
        [
          {
            "id": "11111111-1111-1111-1111-111111111111",
            "name": "  \(importedName)  ",
            "recordFilter": "bad-filter",
            "sortMode": "bad-sort",
            "sortAscending": false,
            "localFilterText": "  \(longFilter)  ",
            "batchSize": 5000,
            "updatedAt": 0
          },
          {
            "id": "22222222-2222-2222-2222-222222222222",
            "name": "   ",
            "recordFilter": "withDescription",
            "sortMode": "lastIP",
            "sortAscending": true,
            "localFilterText": "ignored",
            "batchSize": 25,
            "updatedAt": 1
          },
          {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "\(existingName.lowercased())",
            "recordFilter": "withConnections",
            "sortMode": "connections",
            "sortAscending": false,
            "localFilterText": "replace",
            "batchSize": 75,
            "updatedAt": 2
          }
        ]
        """.utf8)

        let preview = try model.databaseClientFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertTrue(preview.hasPresets)
        XCTAssertEqual(preview.candidates.count, 2)
        XCTAssertTrue(preview.containsPreset(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!))
        XCTAssertFalse(preview.containsPreset(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!))
        XCTAssertTrue(preview.clipboardSummary.contains("Imported database client filter presets: 3"))
        XCTAssertTrue(preview.presetSummaries.contains { summary in
            summary.contains("name=\(importedName)")
                && summary.contains("recordFilter=all")
                && summary.contains("sortMode=nickname")
                && summary.contains("batchSize=1000")
                && summary.contains("localFilter=\(String(longFilter.prefix(120)))")
        })
    }

    @MainActor
    func testDatabaseClientFilterPresetImportRestoresOnlySelectedPresets() throws {
        let model = TS3AppModel()
        let unchangedName = "Database Unchanged Preset"
        let replacedName = "Database Replace Preset"
        let skippedName = "Database Skipped Preset"
        deleteDatabaseFilterPresets(named: unchangedName, in: model)
        deleteDatabaseFilterPresets(named: replacedName, in: model)
        deleteDatabaseFilterPresets(named: skippedName, in: model)
        defer {
            deleteDatabaseFilterPresets(named: unchangedName, in: model)
            deleteDatabaseFilterPresets(named: replacedName, in: model)
            deleteDatabaseFilterPresets(named: skippedName, in: model)
        }
        model.saveDatabaseClientFilterPreset(
            name: unchangedName,
            recordFilter: "withUniqueId",
            sortMode: "databaseId",
            sortAscending: true,
            localFilterText: "old",
            batchSize: 50
        )
        model.saveDatabaseClientFilterPreset(
            name: replacedName,
            recordFilter: "withUniqueId",
            sortMode: "databaseId",
            sortAscending: true,
            localFilterText: "old",
            batchSize: 50
        )
        let data = Data("""
        [
          {
            "id": "33333333-3333-3333-3333-333333333333",
            "name": "\(replacedName.lowercased())",
            "recordFilter": "withConnections",
            "sortMode": "connections",
            "sortAscending": false,
            "localFilterText": "new",
            "batchSize": 75,
            "updatedAt": 2
          },
          {
            "id": "44444444-4444-4444-4444-444444444444",
            "name": "\(skippedName)",
            "recordFilter": "withDescription",
            "sortMode": "lastIP",
            "sortAscending": true,
            "localFilterText": "skip",
            "batchSize": 25,
            "updatedAt": 3
          }
        ]
        """.utf8)

        XCTAssertEqual(
            try model.importDatabaseClientFilterPresets(
                from: data,
                selectedPresetIds: [UUID(uuidString: "33333333-3333-3333-3333-333333333333")!]
            ),
            1
        )

        let matchingPresets = model.databaseClientFilterPresets.filter {
            $0.name.caseInsensitiveCompare(replacedName) == .orderedSame
        }
        let preset = try XCTUnwrap(matchingPresets.first)
        XCTAssertEqual(matchingPresets.count, 1)
        XCTAssertEqual(preset.name, replacedName.lowercased())
        XCTAssertEqual(preset.recordFilter, "withConnections")
        XCTAssertEqual(preset.sortMode, "connections")
        XCTAssertFalse(preset.sortAscending)
        XCTAssertEqual(preset.localFilterText, "new")
        XCTAssertEqual(preset.batchSize, 75)
        XCTAssertTrue(model.databaseClientFilterPresets.contains { preset in
            preset.name == unchangedName
                && preset.recordFilter == "withUniqueId"
                && preset.localFilterText == "old"
                && preset.batchSize == 50
        })
        XCTAssertFalse(model.databaseClientFilterPresets.contains { preset in
            preset.name == skippedName
        })
        XCTAssertFalse(try model.databaseClientFilterPresetsExportData().isEmpty)
    }

    @MainActor
    private func deleteDatabaseFilterPresets(named name: String, in model: TS3AppModel) {
        for preset in model.databaseClientFilterPresets
            where preset.name.caseInsensitiveCompare(name) == .orderedSame {
            model.deleteDatabaseClientFilterPreset(preset)
        }
    }
}
