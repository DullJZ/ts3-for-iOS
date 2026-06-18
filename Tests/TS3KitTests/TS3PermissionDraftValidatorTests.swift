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

    func testPermissionDraftCoverageSummaryTracksSupportedGroupFlags() {
        let draft = TS3PermissionEditDraft(
            scope: .serverGroup,
            target: "Admins (#6)",
            name: " i_client_kick_power ",
            value: "75",
            negated: true,
            skip: true
        )
        let summary = TS3PermissionDraftCoverageSummary(
            draft: draft,
            validationMessages: draft.validationMessages
        )

        XCTAssertEqual(summary.requiredFieldCount, 3)
        XCTAssertEqual(summary.requiredFieldTotal, 3)
        XCTAssertEqual(summary.effectiveFlagCount, 2)
        XCTAssertEqual(summary.unsupportedRequestedFlagCount, 0)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=Server Group | requiredFields=3/3 | target=true | name=true | numericValue=true | supportsNegated=true | usesNegated=true | supportsSkip=true | usesSkip=true | validationIssues=0 | needsAttention=false"
        )
    }

    func testPermissionDraftCoverageSummaryFlagsUnsupportedChannelFlags() {
        let draft = TS3PermissionEditDraft(
            scope: .channel,
            target: "Lobby (#9)",
            name: "i_channel_needed_join_power",
            value: "30",
            negated: true,
            skip: true
        )
        let summary = TS3PermissionDraftCoverageSummary(
            draft: draft,
            validationMessages: draft.validationMessages
        )

        XCTAssertEqual(summary.requiredFieldCount, 3)
        XCTAssertEqual(summary.requiredFieldTotal, 3)
        XCTAssertEqual(summary.effectiveFlagCount, 2)
        XCTAssertEqual(summary.unsupportedRequestedFlagCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=Channel | requiredFields=3/3 | target=true | name=true | numericValue=true | supportsNegated=false | usesNegated=true | supportsSkip=false | usesSkip=true | validationIssues=0 | needsAttention=true"
        )
    }

    func testPermissionDraftCoverageSummaryFlagsMissingFields() {
        let draft = TS3PermissionEditDraft(
            scope: .databaseClient,
            target: " ",
            name: " ",
            value: "kick",
            negated: false,
            skip: false
        )
        let summary = TS3PermissionDraftCoverageSummary(
            draft: draft,
            validationMessages: draft.validationMessages
        )

        XCTAssertEqual(summary.requiredFieldCount, 0)
        XCTAssertEqual(summary.requiredFieldTotal, 3)
        XCTAssertEqual(summary.effectiveFlagCount, 0)
        XCTAssertEqual(summary.validationIssueCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=Database Client | requiredFields=0/3 | target=false | name=false | numericValue=false | supportsNegated=false | usesNegated=false | supportsSkip=true | usesSkip=false | validationIssues=2 | needsAttention=true"
        )
    }

    func testPermissionOfficialEditAuditSummaryCoversOfficialEditAreas() {
        let draft = TS3PermissionEditDraft(
            scope: .serverGroup,
            target: "Admins (#6)",
            name: "i_client_kick_power",
            value: "75",
            negated: true,
            skip: true
        )
        let coverage = TS3PermissionDraftCoverageSummary(
            draft: draft,
            validationMessages: draft.validationMessages
        )
        let audit = TS3PermissionOfficialEditAuditSummary(coverage: coverage)

        XCTAssertEqual(audit.coveredAreaCount, 4)
        XCTAssertEqual(audit.totalOfficialAreaCount, 4)
        XCTAssertEqual(audit.missingAreaCount, 0)
        XCTAssertFalse(audit.needsAttention)
        XCTAssertEqual(
            audit.clipboardSummary,
            "scope=Server Group | officialAreas=4/4 | missingOfficialAreas=0 | requiredFields=3/3 | effectiveFlags=2 | unsupportedFlags=0 | validationIssues=0 | areas=targetScope:1,permissionValue:2,inheritanceFlags:3,validation:1 | needsAttention=false"
        )
    }

    func testPermissionEditReviewSummaryCountsOfficialEditSignals() {
        let draft = TS3PermissionEditDraft(
            scope: .serverGroup,
            target: "Admins (#6)",
            name: "i_client_kick_power",
            value: "75",
            negated: true,
            skip: true
        )
        let coverage = TS3PermissionDraftCoverageSummary(
            draft: draft,
            validationMessages: draft.validationMessages
        )
        let audit = TS3PermissionOfficialEditAuditSummary(coverage: coverage)
        let summary = TS3PermissionEditReviewSummary(audit: audit)

        XCTAssertEqual(summary.reviewAreas, [
            .targetScope,
            .permissionValue,
            .inheritanceFlags,
            .validation
        ])
        XCTAssertEqual(summary.reviewAreaCount, 4)
        XCTAssertEqual(summary.totalReviewSignalCount, 7)
        XCTAssertEqual(summary.primaryArea, .inheritanceFlags)
        XCTAssertTrue(summary.shouldReview)
        XCTAssertFalse(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=Server Group | reviewAreas=4 | reviewSignals=7 | primaryArea=inheritanceFlags | unsupportedFlags=0 | validationIssues=0 | areas=targetScope:1,permissionValue:2,inheritanceFlags:3,validation:1 | needsAttention=false"
        )
    }

    func testPermissionOfficialEditAuditSummaryFlagsMissingAndUnsupportedAreas() {
        let draft = TS3PermissionEditDraft(
            scope: .channel,
            target: " ",
            name: "i_channel_needed_join_power",
            value: "kick",
            negated: true,
            skip: true
        )
        let coverage = TS3PermissionDraftCoverageSummary(
            draft: draft,
            validationMessages: draft.validationMessages
        )
        let audit = TS3PermissionOfficialEditAuditSummary(coverage: coverage)

        XCTAssertEqual(audit.coveredAreaCount, 2)
        XCTAssertEqual(audit.totalOfficialAreaCount, 4)
        XCTAssertEqual(audit.missingAreaCount, 2)
        XCTAssertTrue(audit.needsAttention)
        XCTAssertEqual(
            audit.clipboardSummary,
            "scope=Channel | officialAreas=2/4 | missingOfficialAreas=2 | requiredFields=1/3 | effectiveFlags=2 | unsupportedFlags=2 | validationIssues=1 | areas=permissionValue:1,inheritanceFlags:2 | needsAttention=true"
        )
    }

    func testPermissionEditReviewSummaryIncludesUnsupportedFlagsAndValidationIssues() {
        let draft = TS3PermissionEditDraft(
            scope: .channel,
            target: " ",
            name: "i_channel_needed_join_power",
            value: "kick",
            negated: true,
            skip: true
        )
        let coverage = TS3PermissionDraftCoverageSummary(
            draft: draft,
            validationMessages: draft.validationMessages
        )
        let audit = TS3PermissionOfficialEditAuditSummary(coverage: coverage)
        let summary = TS3PermissionEditReviewSummary(audit: audit)

        XCTAssertEqual(summary.reviewAreas, [
            .permissionValue,
            .inheritanceFlags
        ])
        XCTAssertEqual(summary.reviewAreaCount, 2)
        XCTAssertEqual(summary.totalReviewSignalCount, 6)
        XCTAssertEqual(summary.primaryArea, .inheritanceFlags)
        XCTAssertTrue(summary.shouldReview)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "scope=Channel | reviewAreas=2 | reviewSignals=6 | primaryArea=inheritanceFlags | unsupportedFlags=2 | validationIssues=1 | areas=permissionValue:1,inheritanceFlags:2 | needsAttention=true"
        )
    }
}
