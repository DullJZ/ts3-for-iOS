import SwiftUI
import TS3Kit
import UniformTypeIdentifiers

struct DebugLogView: View {
    private enum LevelFilter: String, CaseIterable, Identifiable {
        case all
        case debug
        case info
        case warning
        case error

        var id: String { rawValue }

        var titleKey: LocalizedStringKey {
            switch self {
            case .all: return "debug.level.all"
            case .debug: return "debug.level.debug"
            case .info: return "debug.level.info"
            case .warning: return "debug.level.warning"
            case .error: return "debug.level.error"
            }
        }

        func includes(_ level: TS3LogLevel) -> Bool {
            switch self {
            case .all:
                return true
            case .debug:
                return level == .debug
            case .info:
                return level == .info
            case .warning:
                return level == .warning
            case .error:
                return level == .error
            }
        }
    }

    @EnvironmentObject private var model: TS3AppModel
    @State private var isExportingLogs = false
    @State private var isExportingDiagnosticReport = false
    @State private var isConfirmingClearLogs = false
    @State private var logDocument = TS3TextFileDocument()
    @State private var diagnosticReportDocument = TS3TextFileDocument()
    @State private var searchText = ""
    @State private var levelFilter: LevelFilter = .all

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("debug.filter")) {
                    Picker("debug.level", selection: $levelFilter) {
                        ForEach(LevelFilter.allCases) { filter in
                            Text(filter.titleKey).tag(filter)
                        }
                    }
                    TextField("debug.searchLogs", text: $searchText)
                        .disableAutocorrection(true)
                    ServerInfoDetailRow(
                        label: NSLocalizedString("debug.visible", comment: ""),
                        value: String(
                            format: NSLocalizedString("debug.visibleCountFormat", comment: ""),
                            filteredLogs.count,
                            model.logs.count
                        )
                    )
                    let accessibilityAudit = model.platformAccessibilityCoverageAuditSummary
                    ServerInfoDetailRow(
                        label: NSLocalizedString("debug.accessibilityAudit", comment: ""),
                        value: String(
                            format: NSLocalizedString("debug.accessibilityAuditFormat", comment: ""),
                            accessibilityAudit.coveredOfficialAreaCount,
                            accessibilityAudit.officialAreaTotal,
                            accessibilityAudit.missingOfficialAreaCount
                        )
                    )
                    Text(accessibilityAuditText(accessibilityAudit))
                        .font(.caption)
                        .foregroundColor(accessibilityAudit.needsAttention ? .orange : .secondary)
                    Button("debug.copyAccessibilityAudit") {
                        TS3PlatformSupport.copyToPasteboard(accessibilityAudit.clipboardSummary)
                    }
                }

                Section(header: Text("debug.logs")) {
                    if filteredLogs.isEmpty {
                        Text("debug.noMatchingLogs")
                            .foregroundColor(.secondary)
                    }
                    ForEach(filteredLogs) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(timeFormatter.string(from: entry.timestamp)) [\(entry.level.rawValue)]")
                                .font(.caption)
                                .foregroundColor(color(for: entry.level))
                            Text(entry.message)
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("debug.title")
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("debug.close") {
                        model.isShowingDebug = false
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("debug.copy") {
                        copyVisibleLogs()
                    }
                    .disabled(filteredLogs.isEmpty)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("debug.export") {
                        logDocument = TS3TextFileDocument(data: Data(logTranscript(from: filteredLogs).utf8))
                        isExportingLogs = true
                    }
                    .disabled(filteredLogs.isEmpty)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("debug.diagnosticReport") {
                        diagnosticReportDocument = TS3TextFileDocument(data: model.diagnosticReportData())
                        isExportingDiagnosticReport = true
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("debug.clear") {
                        isConfirmingClearLogs = true
                    }
                    .disabled(model.logs.isEmpty)
                }
            }
            .alert(isPresented: $isConfirmingClearLogs) {
                Alert(
                    title: Text("debug.clearAlert.title"),
                    message: Text("debug.clearAlert.message"),
                    primaryButton: .destructive(Text("debug.clear")) {
                        model.clearLogs()
                    },
                    secondaryButton: .cancel(Text("common.cancel"))
                )
            }
            .fileExporter(
                isPresented: $isExportingLogs,
                document: logDocument,
                contentType: .plainText,
                defaultFilename: "ts3-debug-log"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingDiagnosticReport,
                document: diagnosticReportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-diagnostic-report"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
        }
    }

    private var filteredLogs: [TS3LogEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return model.logs.filter { entry in
            guard levelFilter.includes(entry.level) else { return false }
            guard !query.isEmpty else { return true }
            return entry.message.localizedCaseInsensitiveContains(query)
                || entry.level.rawValue.localizedCaseInsensitiveContains(query)
                || timeFormatter.string(from: entry.timestamp).localizedCaseInsensitiveContains(query)
        }
    }

    private func color(for level: TS3LogLevel) -> Color {
        switch level {
        case .info:
            return .secondary
        case .warning:
            return .orange
        case .error:
            return .red
        case .debug:
            return .blue
        }
    }

    private func copyVisibleLogs() {
        TS3PlatformSupport.copyToPasteboard(logTranscript(from: filteredLogs))
    }

    private func accessibilityAuditText(_ summary: TS3PlatformAccessibilityCoverageAuditSummary) -> String {
        [
            String(format: NSLocalizedString("debug.accessibilityAuditActionsFormat", comment: ""), summary.officialActionCount),
            String(format: NSLocalizedString("debug.accessibilityAuditLocalizedFormat", comment: ""), summary.localizedSurfaceCount),
            String(format: NSLocalizedString("debug.accessibilityAuditVoiceOverFormat", comment: ""), summary.voiceOverRowActionSurfaceCount),
            String(format: NSLocalizedString("debug.accessibilityAuditCatalystFormat", comment: ""), summary.catalystMenuGroupCount),
            String(format: NSLocalizedString("debug.accessibilityAuditDynamicTypeFormat", comment: ""), summary.hasDynamicTypeAuditPending ? NSLocalizedString("common.yes", comment: "") : NSLocalizedString("common.no", comment: ""))
        ].joined(separator: " · ")
    }

    private func logTranscript(from entries: [TS3LogEntry]) -> String {
        entries.map { entry in
            "\(timeFormatter.string(from: entry.timestamp)) [\(entry.level.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
    }
}
