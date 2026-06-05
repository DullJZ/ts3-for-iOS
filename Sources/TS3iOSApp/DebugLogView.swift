import SwiftUI
import TS3Kit
import UniformTypeIdentifiers

struct DebugLogView: View {
    private enum LevelFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"

        var id: String { rawValue }

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
                Section(header: Text("Filter")) {
                    Picker("Level", selection: $levelFilter) {
                        ForEach(LevelFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    TextField("Search logs", text: $searchText)
                        .disableAutocorrection(true)
                    ServerInfoDetailRow(label: "Visible", value: "\(filteredLogs.count) of \(model.logs.count)")
                }

                Section(header: Text("Logs")) {
                    if filteredLogs.isEmpty {
                        Text("No matching log entries")
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
            .navigationTitle("调试日志")
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("关闭") {
                        model.isShowingDebug = false
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("复制") {
                        copyVisibleLogs()
                    }
                    .disabled(filteredLogs.isEmpty)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("导出") {
                        logDocument = TS3TextFileDocument(data: Data(logTranscript(from: filteredLogs).utf8))
                        isExportingLogs = true
                    }
                    .disabled(filteredLogs.isEmpty)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("诊断包") {
                        diagnosticReportDocument = TS3TextFileDocument(data: model.diagnosticReportData())
                        isExportingDiagnosticReport = true
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("清空") {
                        isConfirmingClearLogs = true
                    }
                    .disabled(model.logs.isEmpty)
                }
            }
            .alert(isPresented: $isConfirmingClearLogs) {
                Alert(
                    title: Text("清空调试日志？"),
                    message: Text("这会删除当前会话中显示的所有调试日志。"),
                    primaryButton: .destructive(Text("清空")) {
                        model.clearLogs()
                    },
                    secondaryButton: .cancel(Text("取消"))
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

    private func logTranscript(from entries: [TS3LogEntry]) -> String {
        entries.map { entry in
            "\(timeFormatter.string(from: entry.timestamp)) [\(entry.level.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
    }
}
