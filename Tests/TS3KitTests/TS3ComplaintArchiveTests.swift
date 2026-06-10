import XCTest
@testable import TS3iOSApp

final class TS3ComplaintArchiveTests: XCTestCase {
    func testComplaintDraftValidatorRejectsMissingTargetEmptyAndMultilineMessage() {
        XCTAssertEqual(
            TS3ComplaintDraftValidator.validationMessages(
                targetName: " ",
                targetClientId: nil,
                targetDatabaseId: nil,
                message: " \n "
            ),
            [
                "Select a target user before submitting a complaint.",
                "Complaint message is required before submitting.",
                "Complaint message must be a single line."
            ]
        )
    }

    func testComplaintDraftValidatorBuildsAuditableSummary() {
        let messages = TS3ComplaintDraftValidator.validationMessages(
            targetName: " Target ",
            targetClientId: 12,
            targetDatabaseId: 22,
            message: " Abuse "
        )
        let summary = TS3ComplaintDraftValidator.creationSummary(
            targetName: " Target ",
            targetClientId: 12,
            targetDatabaseId: 22,
            message: " Abuse "
        )

        XCTAssertTrue(messages.isEmpty)
        XCTAssertEqual(summary, "target=Target | clientId=12 | databaseId=22 | message=Abuse")
    }

    func testComplaintDraftValidatorSummarizesMissingMessage() {
        let summary = TS3ComplaintDraftValidator.creationSummary(
            targetName: "Target",
            targetClientId: 12,
            targetDatabaseId: nil,
            message: " "
        )

        XCTAssertEqual(summary, "target=Target | clientId=12 | message=Missing")
    }

    func testComplaintSummaryCopyAndAccessibilityText() {
        let complaint = TS3ComplaintSummary(
            id: "complaint",
            targetClientDatabaseId: 22,
            targetName: "Target",
            sourceClientDatabaseId: 44,
            sourceName: "Reporter",
            message: "Abuse",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(complaint.sourceTitle, "Reporter")
        XCTAssertEqual(
            complaint.clipboardSummary,
            "sourceDb=44 | targetDb=22 | sourceName=Reporter | targetName=Target | timestamp=1700000000 | message=Abuse"
        )
        XCTAssertEqual(
            complaint.accessibilityValue,
            "Source database ID 44. Target database ID 22. Target Target. Created date available. Abuse"
        )
    }

    func testComplaintSummaryFallbackTextOmitsEmptyOptionalFields() {
        let complaint = TS3ComplaintSummary(
            id: "complaint",
            targetClientDatabaseId: 22,
            targetName: nil,
            sourceClientDatabaseId: 44,
            sourceName: nil,
            message: nil,
            timestamp: nil
        )

        XCTAssertEqual(complaint.sourceTitle, "Client DB 44")
        XCTAssertEqual(complaint.clipboardSummary, "sourceDb=44 | targetDb=22")
        XCTAssertEqual(complaint.accessibilityValue, "Source database ID 44. Target database ID 22")
    }

    @MainActor
    func testComplaintArchivePreviewSanitizesCountsAndFirstDetails() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": "first",
              "targetClientDatabaseId": 22,
              "targetName": " Target ",
              "sourceClientDatabaseId": 44,
              "sourceName": " Reporter ",
              "message": " Abuse ",
              "timestamp": 1700000000
            },
            {
              "id": "duplicate",
              "targetClientDatabaseId": 22,
              "targetName": "Target",
              "sourceClientDatabaseId": 44,
              "sourceName": "Reporter",
              "message": "Abuse",
              "timestamp": 1700000000
            },
            {
              "id": "second",
              "targetClientDatabaseId": 23,
              "sourceClientDatabaseId": 45,
              "message": " "
            },
            {
              "id": "invalid",
              "targetClientDatabaseId": 0,
              "sourceClientDatabaseId": 45,
              "message": "missing target"
            }
          ]
        }
        """

        let preview = try model.complaintArchivePreview(from: Data(archiveJSON.utf8))

        XCTAssertEqual(preview.complaintCount, 2)
        XCTAssertEqual(preview.skippedComplaintCount, 2)
        XCTAssertEqual(preview.targetCount, 2)
        XCTAssertEqual(preview.namedSourceCount, 1)
        XCTAssertEqual(preview.anonymousSourceCount, 1)
        XCTAssertEqual(preview.messageCount, 1)
        XCTAssertEqual(preview.firstTargetName, "Target")
        XCTAssertEqual(preview.firstSourceName, "Reporter")
        XCTAssertEqual(preview.firstMessage, "Abuse")
        XCTAssertEqual(
            preview.complaintSummaries,
            [
                "sourceDb=44 | targetDb=22 | sourceName=Reporter | targetName=Target | timestamp=2678307200 | message=Abuse",
                "sourceDb=45 | targetDb=23"
            ]
        )
        XCTAssertEqual(preview.clipboardSummary, preview.complaintSummaries.joined(separator: "\n"))
        XCTAssertTrue(preview.hasComplaints)
    }

    @MainActor
    func testComplaintArchiveImportReplacesLocalCachedComplaints() throws {
        let model = TS3AppModel()
        let archiveJSON = """
        {
          "entries": [
            {
              "id": "",
              "targetClientDatabaseId": 22,
              "targetName": " Target ",
              "sourceClientDatabaseId": 44,
              "sourceName": " Reporter ",
              "message": " Abuse "
            }
          ]
        }
        """

        try model.importComplaintArchive(from: Data(archiveJSON.utf8))

        XCTAssertEqual(model.complaintEntries.count, 1)
        XCTAssertEqual(model.complaintEntries.first?.targetName, "Target")
        XCTAssertEqual(model.complaintEntries.first?.sourceName, "Reporter")
        XCTAssertEqual(model.complaintEntries.first?.message, "Abuse")
        XCTAssertEqual(model.lastError, nil)
    }
}
