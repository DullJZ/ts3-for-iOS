import XCTest
@testable import TS3iOSApp

final class TS3ComplaintArchiveTests: XCTestCase {
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
