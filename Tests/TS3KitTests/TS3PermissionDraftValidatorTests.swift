import XCTest
@testable import TS3iOSApp

final class TS3PermissionDraftValidatorTests: XCTestCase {
    func testPermissionDraftValidatorRejectsMissingNameAndNonNumericValue() {
        let messages = TS3PermissionDraftValidator.validationMessages(
            scope: .serverGroup,
            name: "   ",
            value: "kick"
        )

        XCTAssertEqual(messages, [
            "Permission name is required before saving.",
            "Permission value must be numeric."
        ])
    }

    func testPermissionDraftSummaryKeepsOfficialGroupFlags() {
        let draft = TS3PermissionEditDraft(
            scope: .serverGroup,
            target: "Admins (#6)",
            name: " i_client_kick_power ",
            value: "75",
            negated: true,
            skip: true
        )

        XCTAssertEqual(draft.parsedValue, 75)
        XCTAssertTrue(draft.effectiveNegated)
        XCTAssertTrue(draft.effectiveSkip)
        XCTAssertEqual(
            draft.clipboardSummary,
            "scope=Server Group | target=Admins (#6) | name=i_client_kick_power | value=75 | negated=true | skip=true | effect=Negates earlier grants and blocks lower inherited permissions."
        )
    }

    func testPermissionDraftSummaryDropsUnsupportedChannelFlags() {
        let draft = TS3PermissionEditDraft(
            scope: .channel,
            target: "Lobby (#9)",
            name: "i_channel_needed_join_power",
            value: "30",
            negated: true,
            skip: true
        )

        XCTAssertFalse(draft.effectiveNegated)
        XCTAssertFalse(draft.effectiveSkip)
        XCTAssertEqual(
            draft.clipboardSummary,
            "scope=Channel | target=Lobby (#9) | name=i_channel_needed_join_power | value=30 | effect=Direct value; inherited permissions may still apply around this entry."
        )
    }
}
