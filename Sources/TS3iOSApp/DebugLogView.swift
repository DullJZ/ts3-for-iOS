import SwiftUI
import TS3Kit
import UniformTypeIdentifiers

struct DebugLogView: View {
    @EnvironmentObject private var model: TS3AppModel
    @State private var isExportingLogs = false
    @State private var isConfirmingClearLogs = false
    @State private var logDocument = TS3TextFileDocument()

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    var body: some View {
        NavigationView {
            List {
                ForEach(model.logs) { entry in
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
            .navigationTitle("调试日志")
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("关闭") {
                        model.isShowingDebug = false
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("复制全部") {
                        copyAllLogs()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("导出") {
                        logDocument = TS3TextFileDocument(data: model.debugLogData())
                        isExportingLogs = true
                    }
                    .disabled(model.logs.isEmpty)
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

    private func copyAllLogs() {
        let text = model.logs.map { entry in
            "\(timeFormatter.string(from: entry.timestamp)) [\(entry.level.rawValue)] \(entry.message)"
        }.joined(separator: "\n")
        TS3PlatformSupport.copyToPasteboard(text)
    }
}
