import XCTest
@testable import TS3iOSApp

final class TS3ServerHealthSummaryTests: XCTestCase {
    func testServerHealthSummaryReportsCriticalConnectionAndQuota() {
        var server = TS3ServerInfoSummary.empty
        server.totalPing = 80
        server.totalPacketLossTotal = 0.01
        server.downloadQuota = 1_000
        server.monthlyBytesDownloaded = 1_050
        server.uploadQuota = 2_000
        server.monthlyBytesUploaded = 1_700
        let connection = TS3ConnectionInfoSummary(
            ping: 260,
            packetLossTotal: 0.01
        )

        let summary = TS3ServerHealthSummary(serverInfo: server, connectionInfo: connection)

        XCTAssertEqual(summary.connectionState, .critical)
        XCTAssertEqual(summary.serverQualityState, .good)
        XCTAssertEqual(summary.downloadQuotaState, .critical)
        XCTAssertEqual(summary.uploadQuotaState, .warning)
        XCTAssertEqual(summary.overallState, .critical)
        XCTAssertEqual(
            summary.clipboardSummary,
            "overall=critical | connection=critical | connectionPing=260.00 | connectionLoss=1.00% | serverQuality=good | serverPing=80.00 | serverLoss=1.00% | downloadQuota=1050/1000 (105.00%) | downloadQuotaState=critical | uploadQuota=1700/2000 (85.00%) | uploadQuotaState=warning"
        )
    }

    func testServerHealthSummaryHandlesUnknownAndGoodStates() {
        var server = TS3ServerInfoSummary.empty
        server.totalPing = 40
        server.totalPacketLossTotal = 0.001
        server.downloadQuota = 10_000
        server.monthlyBytesDownloaded = 2_500
        let connection = TS3ConnectionInfoSummary()

        let summary = TS3ServerHealthSummary(serverInfo: server, connectionInfo: connection)

        XCTAssertEqual(summary.connectionState, .unknown)
        XCTAssertEqual(summary.serverQualityState, .good)
        XCTAssertEqual(summary.downloadQuotaState, .good)
        XCTAssertEqual(summary.uploadQuotaState, .unknown)
        XCTAssertEqual(summary.overallState, .good)
        XCTAssertEqual(summary.quotaUsagePercent(used: 2_500, quota: 10_000), 0.25)
    }
}
