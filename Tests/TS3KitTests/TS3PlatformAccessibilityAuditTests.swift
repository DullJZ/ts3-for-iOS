import XCTest
@testable import TS3iOSApp

final class TS3PlatformAccessibilityAuditTests: XCTestCase {
    func testPlatformAccessibilityCoverageAuditSummaryCountsCoveredAreas() {
        let summary = TS3PlatformAccessibilityCoverageAuditSummary(
            localizedSurfaceCount: 18,
            voiceOverRowActionSurfaceCount: 24,
            catalystMenuGroupCount: 5,
            hasSharedSwiftUISheets: true,
            hasCompactVoiceStatus: true,
            hasVoiceOverGlobalVoiceState: true,
            hasVoiceOverRowActions: true,
            hasLocalizedAdminSurfaces: true,
            hasCatalystMenuCoverage: true,
            hasCopyableAuditSummaries: true,
            hasDiagnosticExport: true,
            hasDynamicTypeAuditPending: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 8)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 8)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 20)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=8/8 | missingOfficialAreas=0 | officialActions=20 | localizedSurfaces=18 | voiceOverRowActionSurfaces=24 | catalystMenuGroups=5 | sharedSwiftUISheets=true | compactVoiceStatus=true | voiceOverGlobalVoiceState=true | voiceOverRowActions=true | localizedAdminSurfaces=true | catalystMenuCoverage=true | copyableAuditSummaries=true | diagnosticExport=true | dynamicTypeAuditPending=true | needsAttention=true"
        )
    }

    func testPlatformAccessibilityCoverageAuditSummaryFlagsMissingAreas() {
        let summary = TS3PlatformAccessibilityCoverageAuditSummary(
            localizedSurfaceCount: 4,
            voiceOverRowActionSurfaceCount: 2,
            catalystMenuGroupCount: 1,
            hasSharedSwiftUISheets: true,
            hasCompactVoiceStatus: false,
            hasVoiceOverGlobalVoiceState: false,
            hasVoiceOverRowActions: true,
            hasLocalizedAdminSurfaces: false,
            hasCatalystMenuCoverage: true,
            hasCopyableAuditSummaries: false,
            hasDiagnosticExport: true,
            hasDynamicTypeAuditPending: false
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 4)
        XCTAssertEqual(summary.missingOfficialAreaCount, 4)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=4/8 | missingOfficialAreas=4 | officialActions=20 | localizedSurfaces=4 | voiceOverRowActionSurfaces=2 | catalystMenuGroups=1 | sharedSwiftUISheets=true | compactVoiceStatus=false | voiceOverGlobalVoiceState=false | voiceOverRowActions=true | localizedAdminSurfaces=false | catalystMenuCoverage=true | copyableAuditSummaries=false | diagnosticExport=true | dynamicTypeAuditPending=false | needsAttention=true"
        )
    }

    @MainActor
    func testDiagnosticReportIncludesPlatformAccessibilityAudit() {
        let model = TS3AppModel()
        let report = String(data: model.diagnosticReportData(), encoding: .utf8) ?? ""

        XCTAssertTrue(report.contains("Platform Accessibility Coverage"))
        XCTAssertTrue(report.contains("Official Areas: 8/8"))
        XCTAssertTrue(report.contains("Dynamic Type Audit Pending: Yes"))
        XCTAssertTrue(report.contains(model.platformAccessibilityCoverageAuditSummary.clipboardSummary))
    }
}
