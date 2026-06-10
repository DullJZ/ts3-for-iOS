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
}
