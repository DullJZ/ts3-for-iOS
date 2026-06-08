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

    @MainActor
    func testVisibleContactBackupExportSanitizesSelectedEntries() throws {
        let model = TS3AppModel()
        let exported = try model.contactsExportData([
            makeContact(uniqueIdentifier: " uid-visible ", nickname: " Visible ", status: .friend, note: " note "),
            makeContact(uniqueIdentifier: "", nickname: "Invalid", status: .blocked, note: ""),
            makeContact(uniqueIdentifier: "uid-dup", nickname: "First", status: .ignored, note: ""),
            makeContact(uniqueIdentifier: "uid-dup", nickname: "Second", status: .blocked, note: "latest")
        ])

        let decoded = try JSONDecoder().decode([TS3ContactEntry].self, from: exported)

        XCTAssertEqual(decoded.map(\.uniqueIdentifier), ["uid-visible", "uid-dup"])
        XCTAssertEqual(decoded.first?.nickname, "Visible")
        XCTAssertEqual(decoded.first?.note, "note")
        XCTAssertEqual(decoded.last?.nickname, "Second")
        XCTAssertEqual(decoded.last?.status, .blocked)
    }

    @MainActor
    func testDeleteContactsRemovesOnlySelectedEntries() {
        let model = TS3AppModel()
        let keep = makeContact(uniqueIdentifier: "uid-keep", nickname: "Keep", status: .friend, note: "")
        let removeFriend = makeContact(uniqueIdentifier: "uid-remove-friend", nickname: "Remove Friend", status: .friend, note: "")
        let removeBlocked = makeContact(uniqueIdentifier: "uid-remove-blocked", nickname: "Remove Blocked", status: .blocked, note: "")
        model.contacts = [keep, removeFriend, removeBlocked]

        model.deleteContacts([removeFriend, removeBlocked])

        XCTAssertEqual(model.contacts.map(\.uniqueIdentifier), ["uid-keep"])
        XCTAssertNil(model.lastError)
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
