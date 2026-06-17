import XCTest
@testable import TS3iOSApp

final class TS3PlatformAccessibilityAuditTests: XCTestCase {
    func testPlatformAccessibilityCoverageAuditSummaryCountsCoveredAreas() {
        let summary = TS3PlatformAccessibilityCoverageAuditSummary(
            localizedSurfaceCount: 18,
            voiceOverRowActionSurfaceCount: 24,
            catalystMenuGroupCount: 5,
            dynamicTypeResponsiveSurfaceCount: 6,
            hasSharedSwiftUISheets: true,
            hasCompactVoiceStatus: true,
            hasVoiceOverGlobalVoiceState: true,
            hasVoiceOverRowActions: true,
            hasLocalizedAdminSurfaces: true,
            hasCatalystMenuCoverage: true,
            hasCopyableAuditSummaries: true,
            hasDiagnosticExport: true,
            hasDynamicTypeCoverage: true,
            hasDenseAdministrationDynamicTypeAuditPending: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 9)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 9)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 20)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=9/9 | missingOfficialAreas=0 | officialActions=20 | localizedSurfaces=18 | voiceOverRowActionSurfaces=24 | catalystMenuGroups=5 | dynamicTypeResponsiveSurfaces=6 | sharedSwiftUISheets=true | compactVoiceStatus=true | voiceOverGlobalVoiceState=true | voiceOverRowActions=true | localizedAdminSurfaces=true | catalystMenuCoverage=true | copyableAuditSummaries=true | diagnosticExport=true | dynamicTypeCoverage=true | denseAdministrationDynamicTypeAuditPending=true | needsAttention=true"
        )
    }

    func testPlatformAccessibilityCoverageAuditSummaryFlagsMissingAreas() {
        let summary = TS3PlatformAccessibilityCoverageAuditSummary(
            localizedSurfaceCount: 4,
            voiceOverRowActionSurfaceCount: 2,
            catalystMenuGroupCount: 1,
            dynamicTypeResponsiveSurfaceCount: 0,
            hasSharedSwiftUISheets: true,
            hasCompactVoiceStatus: false,
            hasVoiceOverGlobalVoiceState: false,
            hasVoiceOverRowActions: true,
            hasLocalizedAdminSurfaces: false,
            hasCatalystMenuCoverage: true,
            hasCopyableAuditSummaries: false,
            hasDiagnosticExport: true,
            hasDynamicTypeCoverage: false,
            hasDenseAdministrationDynamicTypeAuditPending: false
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 4)
        XCTAssertEqual(summary.missingOfficialAreaCount, 5)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=4/9 | missingOfficialAreas=5 | officialActions=20 | localizedSurfaces=4 | voiceOverRowActionSurfaces=2 | catalystMenuGroups=1 | dynamicTypeResponsiveSurfaces=0 | sharedSwiftUISheets=true | compactVoiceStatus=false | voiceOverGlobalVoiceState=false | voiceOverRowActions=true | localizedAdminSurfaces=false | catalystMenuCoverage=true | copyableAuditSummaries=false | diagnosticExport=true | dynamicTypeCoverage=false | denseAdministrationDynamicTypeAuditPending=false | needsAttention=true"
        )
    }

    @MainActor
    func testDiagnosticReportIncludesPlatformAccessibilityAudit() {
        let model = TS3AppModel()
        let report = String(data: model.diagnosticReportData(), encoding: .utf8) ?? ""

        XCTAssertTrue(report.contains("Platform Accessibility Coverage"))
        XCTAssertTrue(report.contains("Official Areas: 9/9"))
        XCTAssertTrue(report.contains("Dynamic Type Responsive Surfaces: 6"))
        XCTAssertTrue(report.contains("Dynamic Type Coverage: Yes"))
        XCTAssertTrue(report.contains("Dense Administration Dynamic Type Audit Pending: Yes"))
        XCTAssertTrue(report.contains(model.platformAccessibilityCoverageAuditSummary.clipboardSummary))
    }
}
