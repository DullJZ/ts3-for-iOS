import XCTest
@testable import TS3iOSApp

final class TS3SelfStatusProfileTests: XCTestCase {
    func testSelfStatusProfileSummariesUseAuditableValues() {
        let profile = TS3SelfStatusProfile(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            name: "Raid Lead",
            status: TS3SelfStatusBackup(
                nickname: "Lead",
                description: "Ready",
                isAway: true,
                awayMessage: "Planning",
                isInputMuted: true,
                isOutputMuted: false,
                isChannelCommander: true,
                talkRequestMessage: "Need voice",
                iconId: 42
            ),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_040)
        )

        XCTAssertEqual(
            profile.displaySummary,
            "Lead, away, mic muted, commander, talk request"
        )
        XCTAssertEqual(
            profile.clipboardSummary,
            "name=Raid Lead | nickname=Lead | presence=away | micMuted=true | soundMuted=false | commander=true | talkRequest=true"
        )
        XCTAssertEqual(
            profile.accessibilityValue,
            "Away. Nickname Lead. Microphone muted. Sound active. Channel commander. Talk request enabled"
        )
    }

    @MainActor
    func testSelfStatusProfileImportPreviewSanitizesCandidates() throws {
        let existingId = UUID()
        let newId = UUID()
        let invalidId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Status \(suffix)"
        let model = TS3AppModel()
        try model.importSelfStatusProfiles(from: encodedProfiles([
            makeProfile(id: existingId, name: existingName, nickname: "Local", isAway: false)
        ]))
        let data = try encodedProfiles([
            makeProfile(id: existingId, name: " \(existingName) ", nickname: " Imported ", isAway: true),
            makeProfile(id: newId, name: " Raid Lead \(suffix) ", nickname: "Lead", isAway: true, isInputMuted: true),
            makeProfile(id: invalidId, name: "   ", nickname: "Invalid", isAway: false)
        ])

        let preview = try model.selfStatusProfilesImportPreview(from: data)

        XCTAssertEqual(preview.importedProfileCount, 3)
        XCTAssertEqual(preview.usableProfileCount, 2)
        XCTAssertEqual(preview.newProfileCount, 1)
        XCTAssertEqual(preview.replacedProfileCount, 1)
        XCTAssertEqual(preview.skippedProfileCount, 1)
        XCTAssertEqual(preview.candidates.map(\.id), [existingId, newId])
        XCTAssertTrue(preview.profileSummaries.contains { $0.contains("name=\(existingName)") && $0.contains("nickname=Imported") })
        XCTAssertTrue(preview.containsProfile(id: newId))
        XCTAssertFalse(preview.containsProfile(id: invalidId))
        XCTAssertTrue(preview.clipboardSummary.contains("Skipped status profiles: 1"))
    }

    @MainActor
    func testSelfStatusProfileImportCanRestoreSelectedProfiles() throws {
        let existingId = UUID()
        let selectedId = UUID()
        let unselectedId = UUID()
        let suffix = UUID().uuidString
        let existingName = "Existing Status \(suffix)"
        let selectedName = "Selected Status \(suffix)"
        let unselectedName = "Unselected Status \(suffix)"
        let model = TS3AppModel()
        try model.importSelfStatusProfiles(from: encodedProfiles([
            makeProfile(id: existingId, name: existingName, nickname: "Local", isAway: false)
        ]))
        let data = try encodedProfiles([
            makeProfile(id: existingId, name: existingName, nickname: "Imported", isAway: true),
            makeProfile(id: selectedId, name: selectedName, nickname: "Selected", isAway: true, isInputMuted: true),
            makeProfile(id: unselectedId, name: unselectedName, nickname: "Skip", isAway: false)
        ])

        try model.importSelfStatusProfiles(from: data, selectedProfileIds: [selectedId])

        let selected = try XCTUnwrap(model.selfStatusProfiles.first { $0.id == selectedId })
        XCTAssertEqual(selected.name, selectedName)
        XCTAssertEqual(selected.status.nickname, "Selected")
        XCTAssertTrue(selected.status.isAway)
        XCTAssertTrue(selected.status.isInputMuted)
        let existing = try XCTUnwrap(model.selfStatusProfiles.first { $0.id == existingId })
        XCTAssertEqual(existing.status.nickname, "Local")
        XCTAssertFalse(existing.status.isAway)
        XCTAssertFalse(model.selfStatusProfiles.contains { $0.id == unselectedId || $0.name == unselectedName })
        XCTAssertEqual(model.lastError, nil)
    }

    private func encodedProfiles(_ profiles: [TS3SelfStatusProfile]) throws -> Data {
        try JSONEncoder().encode(profiles)
    }

    private func makeProfile(
        id: UUID,
        name: String,
        nickname: String,
        isAway: Bool,
        isInputMuted: Bool = false
    ) -> TS3SelfStatusProfile {
        TS3SelfStatusProfile(
            id: id,
            name: name,
            status: TS3SelfStatusBackup(
                nickname: nickname,
                description: "",
                isAway: isAway,
                awayMessage: isAway ? "Away" : "",
                isInputMuted: isInputMuted,
                isOutputMuted: false,
                isChannelCommander: false,
                talkRequestMessage: "",
                iconId: nil
            ),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }
}
