import XCTest
@testable import TS3iOSApp

final class TS3ContactImportTests: XCTestCase {
    @MainActor
    func testContactImportPreviewCountsNewUpdatedUnchangedInvalidAndDuplicateEntries() throws {
        let model = TS3AppModel()
        model.contacts = [
            makeContact(uniqueIdentifier: "uid-existing", nickname: "Existing", status: .friend, note: "old"),
            makeContact(uniqueIdentifier: "uid-same", nickname: "Same", status: .ignored, note: "keep")
        ]
        let backup = [
            makeContact(uniqueIdentifier: " uid-existing ", nickname: " Existing New ", status: .blocked, note: " updated "),
            makeContact(uniqueIdentifier: "uid-same", nickname: "Same", status: .ignored, note: "keep"),
            makeContact(uniqueIdentifier: "uid-new", nickname: "New", status: .friend, note: ""),
            makeContact(uniqueIdentifier: " ", nickname: "Invalid", status: .friend, note: ""),
            makeContact(uniqueIdentifier: "uid-dup", nickname: "Duplicate Old", status: .friend, note: ""),
            makeContact(uniqueIdentifier: "uid-dup", nickname: "Duplicate New", status: .blocked, note: "latest")
        ]

        let preview = try model.contactImportPreview(from: encodedContacts(backup))

        XCTAssertEqual(preview.importedCount, 6)
        XCTAssertEqual(preview.validCount, 4)
        XCTAssertEqual(preview.invalidCount, 1)
        XCTAssertEqual(preview.duplicateCount, 1)
        XCTAssertEqual(preview.newCount, 2)
        XCTAssertEqual(preview.updatedCount, 1)
        XCTAssertEqual(preview.unchangedCount, 1)
        XCTAssertEqual(preview.newContactNames, ["Duplicate New", "New"])
        XCTAssertEqual(preview.updatedContactNames, ["Existing New"])
        XCTAssertEqual(preview.unchangedContactNames, ["Same"])
    }

    @MainActor
    func testContactImportSkipsInvalidEntriesAndUsesLastDuplicateValue() throws {
        let model = TS3AppModel()
        model.contacts = []
        let backup = [
            makeContact(uniqueIdentifier: "", nickname: "Invalid", status: .friend, note: ""),
            makeContact(uniqueIdentifier: "uid-dup", nickname: "First", status: .friend, note: ""),
            makeContact(uniqueIdentifier: "uid-dup", nickname: "Second", status: .blocked, note: "last")
        ]

        XCTAssertEqual(try model.importContacts(from: encodedContacts(backup)), 3)

        XCTAssertEqual(model.contacts.count, 1)
        XCTAssertEqual(model.contacts.first?.uniqueIdentifier, "uid-dup")
        XCTAssertEqual(model.contacts.first?.nickname, "Second")
        XCTAssertEqual(model.contacts.first?.status, .blocked)
        XCTAssertEqual(model.contacts.first?.note, "last")
    }

    private func makeContact(
        uniqueIdentifier: String,
        nickname: String,
        status: TS3ContactStatus,
        note: String
    ) -> TS3ContactEntry {
        TS3ContactEntry(
            uniqueIdentifier: uniqueIdentifier,
            nickname: nickname,
            status: status,
            note: note,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private func encodedContacts(_ contacts: [TS3ContactEntry]) throws -> Data {
        try JSONEncoder().encode(contacts)
    }
}
