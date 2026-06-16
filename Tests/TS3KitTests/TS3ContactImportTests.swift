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

    func testContactListSummaryDeduplicatesAndCountsVisibleContacts() {
        let friend = makeContact(uniqueIdentifier: "uid-friend", nickname: "Friend", status: .friend, note: "")
        let blocked = makeContact(uniqueIdentifier: "uid-blocked", nickname: "Blocked", status: .blocked, note: "review")
        let ignored = makeContact(uniqueIdentifier: "uid-ignored", nickname: "Ignored", status: .ignored, note: "")
        let duplicate = makeContact(uniqueIdentifier: "uid-friend", nickname: "Friend Copy", status: .blocked, note: "ignored duplicate")

        let summary = TS3ContactListSummary(
            contacts: [friend, blocked, ignored, duplicate],
            onlineUniqueIdentifiers: ["uid-friend", "uid-ignored"]
        )

        XCTAssertEqual(summary.totalCount, 3)
        XCTAssertEqual(summary.friendCount, 1)
        XCTAssertEqual(summary.blockedCount, 1)
        XCTAssertEqual(summary.ignoredCount, 1)
        XCTAssertEqual(summary.neutralCount, 0)
        XCTAssertEqual(summary.notedCount, 1)
        XCTAssertEqual(summary.onlineCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "contacts=3 | friends=1 | blocked=1 | ignored=1 | neutral=0 | noted=1 | online=2 | latestUpdate=2023-11-14T22:13:20Z | needsAttention=true"
        )
    }

    func testContactBulkActionSummaryCountsVisibleActions() {
        let friend = makeContact(uniqueIdentifier: "uid-friend", nickname: "Friend", status: .friend, note: "")
        let blocked = makeContact(uniqueIdentifier: "uid-blocked", nickname: "Blocked", status: .blocked, note: "review")
        let neutral = makeContact(uniqueIdentifier: "uid-neutral", nickname: "Neutral", status: .neutral, note: "")
        let duplicate = makeContact(uniqueIdentifier: "uid-friend", nickname: "Friend Copy", status: .ignored, note: "")

        let summary = TS3ContactBulkActionSummary(contacts: [friend, blocked, neutral, duplicate])

        XCTAssertEqual(summary.visibleCount, 3)
        XCTAssertEqual(summary.markFriendCount, 2)
        XCTAssertEqual(summary.blockCount, 2)
        XCTAssertEqual(summary.ignoreCount, 3)
        XCTAssertEqual(summary.neutralCount, 2)
        XCTAssertEqual(summary.appendNoteCount, 3)
        XCTAssertEqual(summary.deleteVisibleCount, 3)
        XCTAssertEqual(summary.effectiveActionCount, 6)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "visible=3 | markFriend=2 | block=2 | ignore=3 | neutral=2 | appendNote=3 | deleteVisible=3 | actions=6 | needsAttention=true"
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

    func testContactFilterPresetSummaryAndAccessibilityText() {
        let preset = makeContactFilterPreset(
            id: UUID(),
            name: "Ops Contacts",
            sortMode: "updated",
            sortAscending: false,
            searchText: "ops"
        )

        XCTAssertEqual(
            preset.clipboardSummary,
            "name=Ops Contacts | sort=updated | sortAscending=false | search=ops"
        )
        XCTAssertEqual(
            preset.accessibilityValue,
            "Sort updated. Descending. Search ops"
        )
    }

    @MainActor
    func testContactFilterPresetImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Contact Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importContactFilterPresets(from: encodedContactFilterPresets([
            makeContactFilterPreset(id: existingId, name: existingName, sortMode: "status", searchText: "keep")
        ]))
        let data = try encodedContactFilterPresets([
            makeContactFilterPreset(
                id: existingId,
                name: " \(existingName) ",
                sortMode: "invalidSort",
                searchText: "  search value  "
            ),
            makeContactFilterPreset(
                id: newId,
                name: " Raid Contacts \(suffix) ",
                sortMode: "note",
                sortAscending: false,
                searchText: String(repeating: "x", count: 140)
            ),
            makeContactFilterPreset(
                id: invalidId,
                name: "   ",
                sortMode: "nickname",
                searchText: "ignored"
            )
        ])

        let preview = try model.contactFilterPresetsImportPreview(from: data)

        XCTAssertEqual(preview.importedPresetCount, 3)
        XCTAssertEqual(preview.usablePresetCount, 2)
        XCTAssertEqual(preview.newPresetCount, 1)
        XCTAssertEqual(preview.replacedPresetCount, 1)
        XCTAssertEqual(preview.skippedPresetCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertEqual(preview.presetSummaries, [
            "name=\(existingName) | sort=nickname | sortAscending=true | search=search value",
            "name=Raid Contacts \(suffix) | sort=note | sortAscending=false | search=\(String(repeating: "x", count: 120))"
        ])
        XCTAssertTrue(preview.containsPreset(id: newId))
        XCTAssertFalse(preview.containsPreset(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped contact filter presets: 1"))
    }

    @MainActor
    func testContactFilterPresetImportRestoresOnlySelectedPresets() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Contact Filter \(suffix)"
        let selectedName = "Selected Contact Filter \(suffix)"
        let unselectedName = "Unselected Contact Filter \(suffix)"
        let model = TS3AppModel()
        _ = try model.importContactFilterPresets(from: encodedContactFilterPresets([
            makeContactFilterPreset(id: existingId, name: existingName, sortMode: "status", searchText: "keep")
        ]))
        let data = try encodedContactFilterPresets([
            makeContactFilterPreset(id: existingId, name: existingName, sortMode: "note", searchText: "replace"),
            makeContactFilterPreset(
                id: selectedId,
                name: selectedName,
                sortMode: "updated",
                sortAscending: false,
                searchText: "ops"
            ),
            makeContactFilterPreset(id: unselectedId, name: unselectedName, sortMode: "nickname", searchText: "away")
        ])

        let restoredCount = try model.importContactFilterPresets(
            from: data,
            selectedPresetIds: [selectedId]
        )

        XCTAssertEqual(restoredCount, 1)
        let existing = try XCTUnwrap(model.contactFilterPresets.first { $0.name == existingName })
        XCTAssertEqual(existing.sortMode, "status")
        XCTAssertEqual(existing.searchText, "keep")
        let selected = try XCTUnwrap(model.contactFilterPresets.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.sortMode, "updated")
        XCTAssertEqual(selected.sortAscending, false)
        XCTAssertEqual(selected.searchText, "ops")
        XCTAssertFalse(model.contactFilterPresets.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
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

    private func encodedContactFilterPresets(_ presets: [TS3ContactFilterPreset]) throws -> Data {
        try JSONEncoder().encode(presets)
    }

    private func makeContactFilterPreset(
        id: UUID,
        name: String,
        sortMode: String,
        sortAscending: Bool = true,
        searchText: String
    ) -> TS3ContactFilterPreset {
        TS3ContactFilterPreset(
            id: id,
            name: name,
            sortMode: sortMode,
            sortAscending: sortAscending,
            searchText: searchText,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
