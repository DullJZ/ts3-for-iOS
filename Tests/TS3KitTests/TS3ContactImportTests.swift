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
        XCTAssertEqual(preview.statusSummaries, [
            "status=Blocked count=2",
            "status=Friend count=1",
            "status=Ignored count=1"
        ])
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
    func testContactImportCanApplyOnlyNewContacts() throws {
        let model = TS3AppModel()
        model.contacts = [
            makeContact(uniqueIdentifier: "uid-existing", nickname: "Existing", status: .friend, note: "old")
        ]
        let backup = [
            makeContact(uniqueIdentifier: "uid-existing", nickname: "Updated", status: .blocked, note: "new"),
            makeContact(uniqueIdentifier: "uid-new", nickname: "New", status: .ignored, note: "note")
        ]

        _ = try model.importContacts(
            from: encodedContacts(backup),
            options: TS3ContactImportOptions(newContacts: true, updatedContacts: false)
        )

        XCTAssertEqual(model.contacts.count, 2)
        XCTAssertEqual(model.contacts.first?.uniqueIdentifier, "uid-new")
        XCTAssertEqual(model.contacts.first?.status, .ignored)
        XCTAssertEqual(model.contacts.first?.note, "note")
        XCTAssertEqual(model.contacts.last?.uniqueIdentifier, "uid-existing")
        XCTAssertEqual(model.contacts.last?.nickname, "Existing")
        XCTAssertEqual(model.contacts.last?.status, .friend)
    }

    @MainActor
    func testContactImportCanApplyOnlyUpdatedContacts() throws {
        let model = TS3AppModel()
        model.contacts = [
            makeContact(uniqueIdentifier: "uid-existing", nickname: "Existing", status: .friend, note: "old")
        ]
        let backup = [
            makeContact(uniqueIdentifier: "uid-existing", nickname: "Updated", status: .blocked, note: "new"),
            makeContact(uniqueIdentifier: "uid-new", nickname: "New", status: .ignored, note: "note")
        ]

        _ = try model.importContacts(
            from: encodedContacts(backup),
            options: TS3ContactImportOptions(newContacts: false, updatedContacts: true)
        )

        XCTAssertEqual(model.contacts.count, 1)
        XCTAssertEqual(model.contacts.first?.uniqueIdentifier, "uid-existing")
        XCTAssertEqual(model.contacts.first?.nickname, "Updated")
        XCTAssertEqual(model.contacts.first?.status, .blocked)
        XCTAssertEqual(model.contacts.first?.note, "new")
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

    @MainActor
    func testAppendNoteToContactsPreservesExistingNotesAndUpdatesOnlySelectedEntries() {
        let model = TS3AppModel()
        let selectedWithNote = makeContact(uniqueIdentifier: "uid-selected-note", nickname: "Selected Note", status: .friend, note: "existing")
        let selectedWithoutNote = makeContact(uniqueIdentifier: "uid-selected-empty", nickname: "Selected Empty", status: .blocked, note: "")
        let unselected = makeContact(uniqueIdentifier: "uid-unselected", nickname: "Unselected", status: .ignored, note: "keep")
        model.contacts = [selectedWithNote, selectedWithoutNote, unselected]

        model.appendNote(" visible audit ", toContacts: [selectedWithNote, selectedWithoutNote, selectedWithNote])

        XCTAssertEqual(model.contacts.first { $0.uniqueIdentifier == "uid-selected-note" }?.note, "existing\nvisible audit")
        XCTAssertEqual(model.contacts.first { $0.uniqueIdentifier == "uid-selected-empty" }?.note, "visible audit")
        XCTAssertEqual(model.contacts.first { $0.uniqueIdentifier == "uid-unselected" }?.note, "keep")
        XCTAssertNil(model.lastError)
    }

    @MainActor
    func testAppendNoteToContactsRejectsEmptyNote() {
        let model = TS3AppModel()
        let contact = makeContact(uniqueIdentifier: "uid-contact", nickname: "Contact", status: .friend, note: "keep")
        model.contacts = [contact]

        model.appendNote("   ", toContacts: [contact])

        XCTAssertEqual(model.contacts.first?.note, "keep")
        XCTAssertEqual(model.lastError, "Enter a note to apply to the selected contacts.")
    }

    func testContactNoteDraftBuildsAuditableSummaryAndDeduplicatesTargets() {
        let first = makeContact(uniqueIdentifier: "uid-first", nickname: "First", status: .friend, note: "existing")
        let second = makeContact(uniqueIdentifier: "uid-second", nickname: "Second", status: .blocked, note: "")
        let draft = TS3ContactNoteDraft(contacts: [first, second, first], note: " follow up ")

        XCTAssertTrue(draft.validationMessages.isEmpty)
        XCTAssertEqual(draft.uniqueContacts.map(\.uniqueIdentifier), ["uid-first", "uid-second"])
        XCTAssertEqual(
            draft.clipboardSummary,
            "contacts=2 | targets=First, Second | note=follow up | appendToExisting=1"
        )
    }

    func testContactNoteDraftRejectsEmptyTargetsAndNote() {
        let draft = TS3ContactNoteDraft(contacts: [], note: "   ")

        XCTAssertEqual(draft.validationMessages, [
            "Select contacts before applying a note.",
            "Enter a note to apply to the selected contacts."
        ])
        XCTAssertEqual(draft.clipboardSummary, "contacts=0 | targets=None | note=Missing")
    }

    func testContactStatusDraftBuildsAuditableSummaryAndDeduplicatesTargets() {
        let first = makeContact(uniqueIdentifier: "uid-first", nickname: "First", status: .friend, note: "")
        let second = makeContact(uniqueIdentifier: "uid-second", nickname: "Second", status: .blocked, note: "")
        let draft = TS3ContactStatusDraft(contacts: [first, second, first], status: .blocked)

        XCTAssertTrue(draft.validationMessages.isEmpty)
        XCTAssertEqual(draft.uniqueContacts.map(\.uniqueIdentifier), ["uid-first", "uid-second"])
        XCTAssertEqual(
            draft.clipboardSummary,
            "contacts=2 | targets=First, Second | status=Blocked | changed=1 | unchanged=1"
        )
        XCTAssertEqual(
            draft.accessibilityValue,
            "Set 2 contacts to Blocked. 1 changed. 1 unchanged. Targets First, Second"
        )
    }

    func testContactStatusDraftRejectsEmptyTargets() {
        let draft = TS3ContactStatusDraft(contacts: [], status: .ignored)

        XCTAssertEqual(draft.validationMessages, ["Select contacts before changing their status."])
        XCTAssertEqual(
            draft.clipboardSummary,
            "contacts=0 | targets=None | status=Ignored | changed=0 | unchanged=0"
        )
    }

    @MainActor
    func testAppendNoteDraftAppliesDeduplicatedVisibleContacts() {
        let model = TS3AppModel()
        let selected = makeContact(uniqueIdentifier: "uid-selected", nickname: "Selected", status: .friend, note: "existing")
        let unselected = makeContact(uniqueIdentifier: "uid-unselected", nickname: "Unselected", status: .ignored, note: "keep")
        model.contacts = [selected, unselected]

        model.appendNote(TS3ContactNoteDraft(contacts: [selected, selected], note: " audited "))

        XCTAssertEqual(model.contacts.first { $0.uniqueIdentifier == "uid-selected" }?.note, "existing\naudited")
        XCTAssertEqual(model.contacts.first { $0.uniqueIdentifier == "uid-unselected" }?.note, "keep")
        XCTAssertNil(model.lastError)
    }

    func testContactSummariesIncludeOnlineNicknameNoteAndStatus() {
        let contact = makeContact(
            uniqueIdentifier: "uid-contact",
            nickname: "Contact",
            status: .blocked,
            note: "Avoid during moderation"
        )

        XCTAssertEqual(
            contact.clipboardSummary(onlineNickname: "Online Contact"),
            "nickname=Contact | uid=uid-contact | status=Blocked | onlineAs=Online Contact | note=Avoid during moderation | updated=\(Self.dateText(Date(timeIntervalSince1970: 1_700_000_000)))"
        )
        XCTAssertEqual(
            contact.accessibilityValue(onlineNickname: "Online Contact"),
            "Status Blocked. Unique ID uid-contact. Online as Online Contact. Note Avoid during moderation. Updated \(Self.dateText(Date(timeIntervalSince1970: 1_700_000_000)))"
        )
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

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
