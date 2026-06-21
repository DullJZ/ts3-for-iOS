import XCTest
@testable import TS3iOSApp

final class TS3PlatformAccessibilityAuditTests: XCTestCase {
    func testPlatformAccessibilityCoverageAuditSummaryCountsCoveredAreas() {
        let summary = TS3PlatformAccessibilityCoverageAuditSummary(
            localizedSurfaceCount: 18,
            voiceOverRowActionSurfaceCount: 24,
            catalystMenuGroupCount: 7,
            dynamicTypeResponsiveSurfaceCount: 9,
            denseAdministrationDynamicTypeAuditSummary: TS3DenseAdministrationDynamicTypeAuditSummary(
                totalSurfaceCount: 14,
                responsiveSurfaceCount: 10,
                catalystSharedSurfaceCount: 14,
                responsiveSurfaceNames: [
                    "Debug Log",
                    "Server Logs",
                    "Client Database",
                    "Contacts",
                    "Ban List",
                    "Complaints",
                    "Temporary Passwords",
                    "Privilege Keys",
                    "File Browser",
                    "Offline Messages"
                ],
                pendingSurfaceNames: [
                    "Server Settings",
                    "Channel Editor",
                    "Permission Editor",
                    "Group Management"
                ]
            ),
            hasSharedSwiftUISheets: true,
            hasCompactVoiceStatus: true,
            hasVoiceOverGlobalVoiceState: true,
            hasVoiceOverRowActions: true,
            hasLocalizedAdminSurfaces: true,
            hasCatalystMenuCoverage: true,
            hasCopyableAuditSummaries: true,
            hasDiagnosticExport: true,
            hasDynamicTypeCoverage: true
        )

        XCTAssertEqual(summary.officialAreaTotal, 9)
        XCTAssertEqual(summary.coveredOfficialAreaCount, 9)
        XCTAssertEqual(summary.missingOfficialAreaCount, 0)
        XCTAssertEqual(summary.officialActionCount, 20)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(summary.denseAdministrationDynamicTypeAuditSummary.pendingSurfaceCount, 4)
        XCTAssertEqual(summary.denseAdministrationDynamicTypeAuditSummary.responsiveSurfaceNames.count, 10)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=9/9 | missingOfficialAreas=0 | officialActions=20 | localizedSurfaces=18 | voiceOverRowActionSurfaces=24 | catalystMenuGroups=7 | dynamicTypeResponsiveSurfaces=9 | denseAdminDynamicTypeSurfaces=14 | denseAdminDynamicTypeResponsive=10 | denseAdminDynamicTypePending=4 | denseAdminCatalystSharedSurfaces=14 | sharedSwiftUISheets=true | compactVoiceStatus=true | voiceOverGlobalVoiceState=true | voiceOverRowActions=true | localizedAdminSurfaces=true | catalystMenuCoverage=true | copyableAuditSummaries=true | diagnosticExport=true | dynamicTypeCoverage=true | denseAdministrationDynamicTypeAuditPending=true | needsAttention=true"
        )
    }

    func testDenseAdministrationDynamicTypeAuditSummaryCountsPendingSurfaces() {
        let summary = TS3DenseAdministrationDynamicTypeAuditSummary(
            totalSurfaceCount: 5,
            responsiveSurfaceCount: 3,
            catalystSharedSurfaceCount: 5,
            responsiveSurfaceNames: ["Logs", "Bans", "Complaints"],
            pendingSurfaceNames: ["Permissions", "Groups"]
        )

        XCTAssertEqual(summary.pendingSurfaceCount, 2)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "denseAdminDynamicTypeSurfaces=5 | denseAdminDynamicTypeResponsive=3 | denseAdminDynamicTypePending=2 | denseAdminCatalystSharedSurfaces=5 | denseAdminResponsiveSurfaces=Logs,Bans,Complaints | denseAdminPendingSurfaces=Permissions,Groups | needsAttention=true"
        )
    }

    func testPlatformAccessibilityCoverageAuditSummaryFlagsMissingAreas() {
        let summary = TS3PlatformAccessibilityCoverageAuditSummary(
            localizedSurfaceCount: 4,
            voiceOverRowActionSurfaceCount: 2,
            catalystMenuGroupCount: 1,
            dynamicTypeResponsiveSurfaceCount: 0,
            denseAdministrationDynamicTypeAuditSummary: TS3DenseAdministrationDynamicTypeAuditSummary(
                totalSurfaceCount: 2,
                responsiveSurfaceCount: 2,
                catalystSharedSurfaceCount: 1,
                responsiveSurfaceNames: ["Logs", "Bans"],
                pendingSurfaceNames: []
            ),
            hasSharedSwiftUISheets: true,
            hasCompactVoiceStatus: false,
            hasVoiceOverGlobalVoiceState: false,
            hasVoiceOverRowActions: true,
            hasLocalizedAdminSurfaces: false,
            hasCatalystMenuCoverage: true,
            hasCopyableAuditSummaries: false,
            hasDiagnosticExport: true,
            hasDynamicTypeCoverage: false
        )

        XCTAssertEqual(summary.coveredOfficialAreaCount, 4)
        XCTAssertEqual(summary.missingOfficialAreaCount, 5)
        XCTAssertTrue(summary.needsAttention)
        XCTAssertEqual(
            summary.clipboardSummary,
            "officialAreas=4/9 | missingOfficialAreas=5 | officialActions=20 | localizedSurfaces=4 | voiceOverRowActionSurfaces=2 | catalystMenuGroups=1 | dynamicTypeResponsiveSurfaces=0 | denseAdminDynamicTypeSurfaces=2 | denseAdminDynamicTypeResponsive=2 | denseAdminDynamicTypePending=0 | denseAdminCatalystSharedSurfaces=1 | sharedSwiftUISheets=true | compactVoiceStatus=false | voiceOverGlobalVoiceState=false | voiceOverRowActions=true | localizedAdminSurfaces=false | catalystMenuCoverage=true | copyableAuditSummaries=false | diagnosticExport=true | dynamicTypeCoverage=false | denseAdministrationDynamicTypeAuditPending=false | needsAttention=true"
        )
    }

    @MainActor
    func testDiagnosticReportIncludesPlatformAccessibilityAudit() {
        let model = TS3AppModel()
        let report = String(data: model.diagnosticReportData(), encoding: .utf8) ?? ""

        XCTAssertTrue(report.contains("Platform Accessibility Coverage"))
        XCTAssertTrue(report.contains("Official Areas: 9/9"))
        XCTAssertTrue(report.contains("Dynamic Type Responsive Surfaces: 9"))
        XCTAssertTrue(report.contains("Dense Administration Dynamic Type Surfaces: 14"))
        XCTAssertTrue(report.contains("Dense Administration Dynamic Type Responsive: 10"))
        XCTAssertTrue(report.contains("Dense Administration Dynamic Type Pending: 4"))
        XCTAssertTrue(report.contains("Dense Administration Catalyst Shared Surfaces: 14"))
        XCTAssertTrue(report.contains("Dense Administration Dynamic Type Responsive Surfaces: Debug Log, Server Logs, Client Database, Contacts, Ban List, Complaints, Temporary Passwords, Privilege Keys, File Browser, Offline Messages"))
        XCTAssertTrue(report.contains("Dense Administration Dynamic Type Pending Surfaces: Server Settings, Channel Editor, Permission Editor, Group Management"))
        XCTAssertTrue(report.contains("Dynamic Type Coverage: Yes"))
        XCTAssertTrue(report.contains("Dense Administration Dynamic Type Audit Pending: Yes"))
        XCTAssertTrue(report.contains(model.platformAccessibilityCoverageAuditSummary.denseAdministrationDynamicTypeAuditSummary.clipboardSummary))
        XCTAssertTrue(report.contains(model.platformAccessibilityCoverageAuditSummary.clipboardSummary))
    }
}
