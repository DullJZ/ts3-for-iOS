import SwiftUI
import TS3Kit

struct DebugLogView: View {
    @EnvironmentObject private var model: TS3AppModel

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
                    Button("清空") {
                        model.clearLogs()
                    }
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
