import SwiftUI
import TS3Kit
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject private var model: TS3AppModel

    private var debugButton: some View {
        Button {
            model.isShowingDebug = true
        } label: {
            Label("调试", systemImage: "ladybug")
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        model.isShowingKeyboardShortcuts = true
                    } label: {
                        Label("快捷键", systemImage: "keyboard")
                    }
                    .buttonStyle(TS3BorderedButtonStyle())
                    .ts3KeyboardShortcut("show-shortcuts", in: model)
                    debugButton
                        .buttonStyle(TS3BorderedButtonStyle())
                        .ts3KeyboardShortcut("show-debug-log", in: model)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    switch model.state {
                    case .disconnected:
                        ConnectView(allowsConnectionActions: true)
                    case .connecting:
                        ConnectingView()
                    case .connected:
                        ChannelListView()
                    }
                }
            }
            .sheet(isPresented: $model.isShowingDebug) {
                DebugLogView()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingKeyboardShortcuts) {
                KeyboardShortcutsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingConnectionManager) {
                ConnectionManagerSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingIdentity) {
                IdentityManagementSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingClientMigration) {
                ClientMigrationSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingNotificationSettings) {
                NotificationSettingsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingChat) {
                ChatSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingOfflineMessages) {
                OfflineMessagesSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingEvents) {
                EventsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingWhisper) {
                WhisperSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingServerLogs) {
                ServerLogsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingServerInfo) {
                ServerInformationSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingServerEditor) {
                ServerSettingsEditorSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingGroupManagement) {
                GroupManagementSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingSubscriptionPresets) {
                ChannelSubscriptionPresetsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingContacts) {
                ContactsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingClientDatabase) {
                ClientDatabaseSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingBans) {
                BanListSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingFiles) {
                FileBrowserSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingPermissions) {
                PermissionsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingPrivilegeKeys) {
                PrivilegeKeysSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingComplaints) {
                ComplaintListSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingAudioSettings) {
                AudioSettingsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $model.isShowingSelfStatus) {
                SelfStatusSheet()
                    .environmentObject(model)
            }
        }
        .ts3InlineNavigationTitle()
    }
}

struct TS3KeyboardShortcutSummary: Identifiable {
    let id = UUID()
    let group: String
    let action: String
    let keys: String
}

private struct TS3KeyboardShortcutDescriptor {
    let key: KeyEquivalent
    let modifiers: EventModifiers

    init?(_ rawValue: String) {
        let parts = rawValue
            .split(separator: "-")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let keyName = parts.last else { return nil }

        var modifiers: EventModifiers = []
        for modifier in parts.dropLast() {
            switch modifier.lowercased() {
            case "command", "cmd", "⌘":
                modifiers.insert(.command)
            case "shift", "⇧":
                modifiers.insert(.shift)
            case "option", "alt", "⌥":
                modifiers.insert(.option)
            case "control", "ctrl", "⌃":
                modifiers.insert(.control)
            default:
                return nil
            }
        }

        guard let key = Self.keyEquivalent(for: keyName) else { return nil }
        self.key = key
        self.modifiers = modifiers
    }

    private static func keyEquivalent(for keyName: String) -> KeyEquivalent? {
        switch keyName.lowercased() {
        case "return", "enter":
            return .return
        case "escape", "esc":
            return .escape
        case "space":
            return .space
        case "tab":
            return .tab
        case "delete", "backspace":
            return .delete
        default:
            guard keyName.count == 1, let character = keyName.first else { return nil }
            return KeyEquivalent(character)
        }
    }
}

private extension View {
    @ViewBuilder
    func ts3KeyboardShortcut(_ actionId: String, in model: TS3AppModel) -> some View {
        if let shortcut = model.keyboardShortcuts.first(where: { $0.actionId == actionId }),
           shortcut.isEnabled,
           let descriptor = TS3KeyboardShortcutDescriptor(shortcut.keys) {
            self.keyboardShortcut(descriptor.key, modifiers: descriptor.modifiers)
        } else {
            self
        }
    }
}

struct KeyboardShortcutsSheet: View {
    private enum ShortcutConfirmation: Identifiable {
        case importBackup(URL)
        case enableAll
        case disableAll
        case resetDisabled
        case resetAll

        var id: String {
            switch self {
            case .importBackup: return "importBackup"
            case .enableAll: return "enableAll"
            case .disableAll: return "disableAll"
            case .resetDisabled: return "resetDisabled"
            case .resetAll: return "resetAll"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isExportingShortcuts = false
    @State private var isExportingShortcutBackup = false
    @State private var isImportingShortcutBackup = false
    @State private var confirmation: ShortcutConfirmation?
    @State private var shortcutsDocument = TS3TextFileDocument()
    @State private var shortcutBackupDocument = TS3BookmarkFileDocument()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Actions")) {
                    ForEach(model.keyboardShortcuts) { shortcut in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(shortcut.action)
                                        .font(.subheadline.weight(.semibold))
                                    Text(shortcut.group)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: shortcutEnabledBinding(shortcut))
                                    .labelsHidden()
                            }
                            TextField("Keys", text: shortcutKeysBinding(shortcut))
                                .font(.system(.body, design: .monospaced))
                                .ts3PlainTextField()
                            if shortcut.keys != shortcut.defaultKeys {
                                Button("Reset to \(shortcut.defaultKeys)") {
                                    model.updateKeyboardShortcut(
                                        shortcut,
                                        keys: shortcut.defaultKeys,
                                        isEnabled: shortcut.isEnabled
                                    )
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Export")) {
                    Button("Copy Shortcuts") {
                        TS3PlatformSupport.copyToPasteboard(shortcutsSnapshot)
                    }
                    Button("Export Shortcuts") {
                        shortcutsDocument = TS3TextFileDocument(data: Data(shortcutsSnapshot.utf8))
                        isExportingShortcuts = true
                    }
                    Button("Export Shortcut Backup") {
                        exportShortcutBackup()
                    }
                    Button("Import Shortcut Backup") {
                        isImportingShortcutBackup = true
                    }
                }

                Section(header: Text("Manage")) {
                    Button("Enable All Shortcuts") {
                        confirmation = .enableAll
                    }
                    Button("Disable All Shortcuts") {
                        confirmation = .disableAll
                    }
                    Button("Reset Disabled Shortcuts") {
                        confirmation = .resetDisabled
                    }
                    Button("Reset Shortcuts") {
                        confirmation = .resetAll
                    }
                }
            }
            .navigationTitle("Keyboard Shortcuts")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingShortcuts,
                document: shortcutsDocument,
                contentType: .plainText,
                defaultFilename: "ts3-keyboard-shortcuts"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingShortcutBackup,
                document: shortcutBackupDocument,
                contentType: .json,
                defaultFilename: "ts3-keyboard-shortcuts"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingShortcutBackup,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    confirmation = .importBackup(url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(item: $confirmation) { confirmation in
                switch confirmation {
                case .importBackup(let url):
                    return Alert(
                        title: Text("Import Shortcut Backup?"),
                        message: Text("This replaces current keyboard shortcut settings with the selected backup."),
                        primaryButton: .destructive(Text("Import")) {
                            importShortcutBackup(from: url)
                        },
                        secondaryButton: .cancel()
                    )
                case .enableAll:
                    return Alert(
                        title: Text("Enable All Shortcuts?"),
                        message: Text("This enables every configured keyboard shortcut."),
                        primaryButton: .default(Text("Enable")) {
                            model.setAllKeyboardShortcutsEnabled(true)
                        },
                        secondaryButton: .cancel()
                    )
                case .disableAll:
                    return Alert(
                        title: Text("Disable All Shortcuts?"),
                        message: Text("This disables every configured keyboard shortcut until they are re-enabled."),
                        primaryButton: .destructive(Text("Disable")) {
                            model.setAllKeyboardShortcutsEnabled(false)
                        },
                        secondaryButton: .cancel()
                    )
                case .resetDisabled:
                    return Alert(
                        title: Text("Reset Disabled Shortcuts?"),
                        message: Text("This re-enables disabled keyboard shortcuts and restores their default keys."),
                        primaryButton: .destructive(Text("Reset")) {
                            model.resetDisabledKeyboardShortcuts()
                        },
                        secondaryButton: .cancel()
                    )
                case .resetAll:
                    return Alert(
                        title: Text("Reset Keyboard Shortcuts?"),
                        message: Text("This restores all keyboard shortcuts to their default keys and enabled state."),
                        primaryButton: .destructive(Text("Reset")) {
                            model.resetKeyboardShortcuts()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private var shortcutsSnapshot: String {
        model.keyboardShortcuts.map { shortcut in
            let state = shortcut.isEnabled ? "enabled" : "disabled"
            return "\(shortcut.group): \(shortcut.action) - \(shortcut.keys) [\(state)]"
        }.joined(separator: "\n")
    }

    private func shortcutKeysBinding(_ shortcut: TS3KeyboardShortcutBinding) -> Binding<String> {
        Binding(
            get: { model.keyboardShortcuts.first { $0.actionId == shortcut.actionId }?.keys ?? shortcut.keys },
            set: { model.updateKeyboardShortcut(shortcut, keys: $0, isEnabled: shortcut.isEnabled) }
        )
    }

    private func shortcutEnabledBinding(_ shortcut: TS3KeyboardShortcutBinding) -> Binding<Bool> {
        Binding(
            get: { model.keyboardShortcuts.first { $0.actionId == shortcut.actionId }?.isEnabled ?? shortcut.isEnabled },
            set: { model.updateKeyboardShortcut(shortcut, keys: shortcut.keys, isEnabled: $0) }
        )
    }

    private func exportShortcutBackup() {
        do {
            shortcutBackupDocument = TS3BookmarkFileDocument(data: try model.keyboardShortcutsExportData())
            isExportingShortcutBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importShortcutBackup(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importKeyboardShortcuts(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ConnectingView: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        VStack(spacing: 16) {
            ProgressView("Connecting to server...")
            Button("Cancel") {
                model.disconnect()
            }
            .buttonStyle(TS3BorderedButtonStyle())
        }
        .padding()
    }
}

struct ConnectView: View {
    private enum ConnectionFilter: String, CaseIterable, Identifiable {
        case all
        case withPassword
        case withDefaultChannel
        case withPrivilegeKey

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Entries"
            case .withPassword: return "With Password"
            case .withDefaultChannel: return "With Default Channel"
            case .withPrivilegeKey: return "With Privilege Key"
            }
        }
    }

    private enum ConnectionSortMode: String, CaseIterable, Identifiable {
        case savedOrder
        case name
        case host
        case nickname
        case port

        var id: String { rawValue }

        var title: String {
            switch self {
            case .savedOrder: return "Saved Order"
            case .name: return "Name"
            case .host: return "Host"
            case .nickname: return "Nickname"
            case .port: return "Port"
            }
        }
    }

    private enum DeleteConfirmation: Identifiable {
        case clearRecent
        case visibleRecent
        case visibleBookmarks
        case deleteAllFilterPresets

        var id: String {
            switch self {
            case .clearRecent: return "clearRecent"
            case .visibleRecent: return "visibleRecent"
            case .visibleBookmarks: return "visibleBookmarks"
            case .deleteAllFilterPresets: return "deleteAllFilterPresets"
            }
        }
    }

    @EnvironmentObject private var model: TS3AppModel
    let allowsConnectionActions: Bool
    @State private var bookmarkName = ""
    @State private var bookmarkFolder = ""
    @State private var connectionPresetName = ""
    @State private var serverURLText = ""
    @State private var connectionSearchText = ""
    @State private var connectionFilter: ConnectionFilter = .all
    @State private var connectionSortMode: ConnectionSortMode = .savedOrder
    @State private var connectionSortAscending = true
    @State private var bookmarkFolderFilter = ""
    @State private var editingBookmark: TS3BookmarkSummary?
    @State private var isShowingIdentity = false
    @State private var isShowingBookmarkImporter = false
    @State private var isExportingBookmarks = false
    @State private var isImportingConnectionPresets = false
    @State private var isExportingConnectionPresets = false
    @State private var isImportingRecentConnections = false
    @State private var isExportingRecentConnections = false
    @State private var isImportingRecoverySettings = false
    @State private var isExportingRecoverySettings = false
    @State private var isExportingRecoverySnapshot = false
    @State private var isImportingClientPackage = false
    @State private var isExportingClientPackage = false
    @State private var deleteConfirmation: DeleteConfirmation?
    @State private var bookmarkExportDocument = TS3BookmarkFileDocument()
    @State private var connectionPresetsDocument = TS3BookmarkFileDocument()
    @State private var recentConnectionsDocument = TS3BookmarkFileDocument()
    @State private var recoverySettingsDocument = TS3TextFileDocument()
    @State private var recoverySnapshotDocument = TS3TextFileDocument()
    @State private var clientPackageDocument = TS3BookmarkFileDocument()

    private var autoReconnectBinding: Binding<Bool> {
        Binding(
            get: { model.autoReconnectEnabled },
            set: { model.setAutoReconnectEnabled($0) }
        )
    }

    private var autoReconnectInitialDelayBinding: Binding<Int> {
        Binding(
            get: { model.autoReconnectInitialDelaySeconds },
            set: {
                model.updateConnectionRecoveryPolicy(
                    initialDelaySeconds: $0,
                    maxDelaySeconds: model.autoReconnectMaxDelaySeconds,
                    maxAttempts: model.autoReconnectMaxAttempts
                )
            }
        )
    }

    private var autoReconnectMaxDelayBinding: Binding<Int> {
        Binding(
            get: { model.autoReconnectMaxDelaySeconds },
            set: {
                model.updateConnectionRecoveryPolicy(
                    initialDelaySeconds: model.autoReconnectInitialDelaySeconds,
                    maxDelaySeconds: $0,
                    maxAttempts: model.autoReconnectMaxAttempts
                )
            }
        )
    }

    private var autoReconnectMaxAttemptsBinding: Binding<Int> {
        Binding(
            get: { model.autoReconnectMaxAttempts },
            set: {
                model.updateConnectionRecoveryPolicy(
                    initialDelaySeconds: model.autoReconnectInitialDelaySeconds,
                    maxDelaySeconds: model.autoReconnectMaxDelaySeconds,
                    maxAttempts: $0
                )
            }
        )
    }

    private var displayedRecentConnections: [TS3ConnectionSnapshot] {
        let entries = model.recentConnections.filter { snapshot in
            matchesConnectionFilter(
                serverPassword: snapshot.serverPassword,
                defaultChannel: snapshot.defaultChannel,
                privilegeKey: snapshot.privilegeKey
            ) && matchesConnectionSearch(
                name: snapshot.host,
                host: snapshot.host,
                port: snapshot.port,
                nickname: snapshot.nickname,
                defaultChannel: snapshot.defaultChannel
            )
        }
        return sortedRecentConnections(entries)
    }

    private var displayedBookmarks: [TS3BookmarkSummary] {
        let entries = model.bookmarks.filter { bookmark in
            matchesBookmarkFolder(bookmark.folder) && matchesConnectionFilter(
                serverPassword: bookmark.serverPassword,
                defaultChannel: bookmark.defaultChannel,
                privilegeKey: bookmark.privilegeKey
            ) && (
                matchesConnectionSearch(
                    name: bookmark.name,
                    host: bookmark.host,
                    port: bookmark.port,
                    nickname: bookmark.nickname,
                    defaultChannel: bookmark.defaultChannel
                ) || isSearchingConnections && containsConnectionSearch(bookmark.folder)
            )
        }
        return sortedBookmarks(entries)
    }

    private var bookmarkFolders: [String] {
        Array(Set(model.bookmarks.map { $0.folder.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        Form {
            if !model.recentConnections.isEmpty || !model.bookmarks.isEmpty {
                Section(header: Text("Saved Connections")) {
                    Picker("Filter", selection: $connectionFilter) {
                        ForEach(ConnectionFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $connectionSortMode) {
                        ForEach(ConnectionSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    if !bookmarkFolders.isEmpty {
                        Picker("Bookmark Folder", selection: $bookmarkFolderFilter) {
                            Text("All Folders").tag("")
                            Text("Unfiled").tag("__unfiled__")
                            ForEach(bookmarkFolders, id: \.self) { folder in
                                Text(folder).tag(folder)
                            }
                        }
                    }
                    Toggle("Ascending", isOn: $connectionSortAscending)
                    TextField("Search saved servers", text: $connectionSearchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $connectionPresetName)
                        Button("Save Current Filters") {
                            model.saveConnectionFilterPreset(
                                name: connectionPresetName,
                                connectionFilter: connectionFilter.rawValue,
                                sortMode: connectionSortMode.rawValue,
                                sortAscending: connectionSortAscending,
                                bookmarkFolderFilter: bookmarkFolderFilter,
                                searchText: connectionSearchText
                            )
                            connectionPresetName = ""
                        }
                        .disabled(connectionPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.connectionFilterPresets.isEmpty {
                            Text("No saved connection filter presets")
                        } else {
                            ForEach(model.connectionFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyConnectionPreset(preset)
                                    }
                                    Button("Use Name") {
                                        connectionPresetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteConnectionFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(connectionPresetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportConnectionPresets()
                        }
                        .disabled(model.connectionFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingConnectionPresets = true
                        }
                        Button("Delete All Presets") {
                            deleteConfirmation = .deleteAllFilterPresets
                        }
                        .disabled(model.connectionFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasSavedConnectionOptions {
                        Button("Clear Saved Connection Filters") {
                            connectionFilter = .all
                            connectionSortMode = .savedOrder
                            connectionSortAscending = true
                            bookmarkFolderFilter = ""
                            connectionSearchText = ""
                        }
                    }
                }
            }

            if !model.recentConnections.isEmpty {
                Section(header: Text("Recent Servers")) {
                    if displayedRecentConnections.isEmpty {
                        Text("No matching recent servers")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(displayedRecentConnections) { snapshot in
                            HStack {
                                Button {
                                    model.applyRecentConnection(snapshot)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(snapshot.host)
                                        Text("\(snapshot.nickname) · \(snapshot.port)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.borderless)
                                Spacer()
                                let recentBookmark = TS3BookmarkSummary(
                                    id: snapshot.id,
                                    name: snapshot.host,
                                    folder: "",
                                    host: snapshot.host,
                                    port: snapshot.port,
                                    nickname: snapshot.nickname,
                                    serverPassword: snapshot.serverPassword,
                                    defaultChannel: snapshot.defaultChannel,
                                    defaultChannelPassword: snapshot.defaultChannelPassword,
                                    privilegeKey: snapshot.privilegeKey
                                )
                                Menu {
                                    Button("Copy Safe Invite Link") {
                                        model.copyInviteLink(for: recentBookmark)
                                    }
                                    Button("Copy Full Invite Link") {
                                        model.copyFullInviteLink(for: recentBookmark)
                                    }
                                } label: {
                                    Image(systemName: "link")
                                }
                                .buttonStyle(.borderless)
                                Button {
                                    model.applyRecentConnection(snapshot)
                                    model.connect()
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .buttonStyle(.borderless)
                                Button {
                                    model.applyRecentConnection(snapshot)
                                    model.saveCurrentBookmark(name: snapshot.host)
                                } label: {
                                    Image(systemName: "bookmark")
                                }
                                .buttonStyle(.borderless)
                                Button {
                                    model.deleteRecentConnection(snapshot)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    Button("Clear Recent Servers") {
                        deleteConfirmation = .clearRecent
                    }
                    .foregroundColor(.red)
                    Menu {
                        Button("Save Visible as Bookmarks") {
                            model.saveBookmarks(from: displayedRecentConnections, folder: bookmarkFolder)
                        }
                        .disabled(displayedRecentConnections.isEmpty)
                        Button("Delete Visible Recent Servers") {
                            deleteConfirmation = .visibleRecent
                        }
                        .disabled(displayedRecentConnections.isEmpty)
                    } label: {
                        Label("Visible Recent Servers", systemImage: "clock.arrow.circlepath")
                    }
                    Button("Export Recent Servers") {
                        exportRecentConnections()
                    }
                    Button("Import Recent Servers") {
                        isImportingRecentConnections = true
                    }
                }
            }

            if !model.bookmarks.isEmpty {
                Section(header: Text("Bookmarks")) {
                    if displayedBookmarks.isEmpty {
                        Text("No matching bookmarks")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(displayedBookmarks) { bookmark in
                            HStack {
                                Button {
                                    model.applyBookmark(bookmark)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bookmark.name)
                                        Text(bookmarkSubtitle(bookmark))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.borderless)
                                Spacer()
                                Button {
                                    model.applyBookmark(bookmark)
                                    model.connect()
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .buttonStyle(.borderless)
                                Menu {
                                    Button("Copy Safe Invite Link") {
                                        model.copyInviteLink(for: bookmark)
                                    }
                                    Button("Copy Full Invite Link") {
                                        model.copyFullInviteLink(for: bookmark)
                                    }
                                } label: {
                                    Image(systemName: "link")
                                }
                                .buttonStyle(.borderless)
                                Button {
                                    editingBookmark = bookmark
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)
                                Button {
                                    model.deleteBookmark(bookmark)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    Menu {
                        Button("Move Visible to Folder") {
                            model.moveBookmarks(displayedBookmarks, toFolder: bookmarkFolder)
                        }
                        .disabled(displayedBookmarks.isEmpty)
                        Button("Move Visible to Unfiled") {
                            model.moveBookmarks(displayedBookmarks, toFolder: "")
                        }
                        .disabled(displayedBookmarks.isEmpty)
                        Button("Delete Visible Bookmarks") {
                            deleteConfirmation = .visibleBookmarks
                        }
                        .disabled(displayedBookmarks.isEmpty)
                    } label: {
                        Label("Visible Bookmarks", systemImage: "folder")
                    }
                }
            }

            Section(header: Text("Invitation Link")) {
                TextField("ts3server://host?nickname=...", text: $serverURLText)
                    .ts3URLTextField()
                Button("Import Link") {
                    model.applyServerURL(serverURLText)
                    serverURLText = ""
                }
                .disabled(serverURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section(header: Text("Server")) {
                TextField("Host (e.g. ts.example.com)", text: $model.serverHost)
                    .ts3URLTextField()
                TextField("Port", text: $model.serverPort)
                    .ts3NumericKeyboard()
                SecureField("Server Password (optional)", text: $model.serverPassword)
                TextField("Default Channel (optional)", text: $model.defaultChannel)
                    .ts3PlainTextField()
                SecureField("Channel Password (optional)", text: $model.defaultChannelPassword)
            }

            Section(header: Text("Profile")) {
                TextField("Nickname", text: $model.nickname)
                    .ts3PlainTextField()
                SecureField("Privilege Key (optional)", text: $model.privilegeKey)
                Button("Manage Identity") {
                    isShowingIdentity = true
                }
            }

            Section(header: Text("Bookmark")) {
                TextField("Bookmark Name", text: $bookmarkName)
                TextField("Folder (optional)", text: $bookmarkFolder)
                    .ts3PlainTextField()
                Button("Save Current Server") {
                    model.saveCurrentBookmark(name: bookmarkName, folder: bookmarkFolder)
                    bookmarkName = ""
                    bookmarkFolder = ""
                }
                .disabled(model.serverHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Copy Invite Link") {
                    model.copyCurrentInviteLink()
                }
                .disabled(model.serverHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Copy Full Invite Link") {
                    model.copyCurrentFullInviteLink()
                }
                .disabled(model.serverHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Copy Connection Summary") {
                    model.copyCurrentConnectionSummary()
                }
                .disabled(model.serverHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Import Bookmarks") {
                    isShowingBookmarkImporter = true
                }
                Button("Export Bookmarks") {
                    exportBookmarks()
                }
                .disabled(model.bookmarks.isEmpty)
                Text("Bookmark backups include saved passwords and privilege keys.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Client Migration")) {
                Button("Export Client Package") {
                    exportClientPackage()
                }
                Button("Import Client Package") {
                    isImportingClientPackage = true
                }
                Text("Client packages include bookmarks, recent servers, contacts, notifications, recovery, audio, status, playback, and whisper presets.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Notifications")) {
                Button("Notification Settings") {
                    model.isShowingNotificationSettings = true
                }
                Text("Configure alerts for private messages, pokes, and server activity.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let error = model.lastError {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }

            if let snapshot = model.lastConnectionSnapshot {
                Section(header: Text("Recent Connection")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(snapshot.title)
                        if let message = model.lastDisconnectMessage, !message.isEmpty {
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button("Reconnect") {
                        model.reconnect()
                    }
                    .disabled(snapshot.host.isEmpty || snapshot.nickname.isEmpty)
                }
            }

            Section(header: Text("Connection Recovery")) {
                Toggle("Reconnect Automatically", isOn: autoReconnectBinding)
                Stepper(
                    "Initial Delay: \(model.autoReconnectInitialDelaySeconds)s",
                    value: autoReconnectInitialDelayBinding,
                    in: 1...300
                )
                Stepper(
                    "Max Delay: \(model.autoReconnectMaxDelaySeconds)s",
                    value: autoReconnectMaxDelayBinding,
                    in: 1...600
                )
                Stepper(
                    model.autoReconnectMaxAttempts == 0
                        ? "Max Attempts: Unlimited"
                        : "Max Attempts: \(model.autoReconnectMaxAttempts)",
                    value: autoReconnectMaxAttemptsBinding,
                    in: 0...100
                )
                if let status = model.autoReconnectStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if model.autoReconnectIsScheduled {
                    Button("Cancel Scheduled Reconnect") {
                        model.cancelScheduledReconnect()
                    }
                    .foregroundColor(.red)
                }
                Button("Copy Recovery Snapshot") {
                    TS3PlatformSupport.copyToPasteboard(connectionRecoverySnapshot)
                }
                Button("Export Recovery Snapshot") {
                    recoverySnapshotDocument = TS3TextFileDocument(data: Data(connectionRecoverySnapshot.utf8))
                    isExportingRecoverySnapshot = true
                }
                Button("Export Recovery Settings") {
                    exportRecoverySettings()
                }
                Button("Import Recovery Settings") {
                    isImportingRecoverySettings = true
                }
            }

            if allowsConnectionActions {
                Section {
                    Button(action: {
                        model.connect()
                    }) {
                        Text("Connect")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(model.serverHost.isEmpty || model.nickname.isEmpty ? .gray : .accentColor)
                    }
                    .buttonStyle(.borderless)
                    .contentShape(Rectangle())
                    .disabled(model.serverHost.isEmpty || model.nickname.isEmpty)
                }
            }
        }
        .navigationTitle(allowsConnectionActions ? "TS3 Connect" : "Connection Manager")
        .sheet(isPresented: $isShowingIdentity) {
            IdentityManagementSheet()
                .environmentObject(model)
        }
        .sheet(item: $editingBookmark) { bookmark in
            BookmarkEditorSheet(bookmark: bookmark)
                .environmentObject(model)
        }
        .fileImporter(
            isPresented: $isShowingBookmarkImporter,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importBookmarks(from: url)
            } else if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExportingBookmarks,
            document: bookmarkExportDocument,
            contentType: .json,
            defaultFilename: "ts3-bookmarks"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImportingConnectionPresets,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importConnectionPresets(from: url)
            } else if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExportingConnectionPresets,
            document: connectionPresetsDocument,
            contentType: .json,
            defaultFilename: "ts3-connection-filter-presets"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImportingRecentConnections,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importRecentConnections(from: url)
            } else if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExportingRecentConnections,
            document: recentConnectionsDocument,
            contentType: .json,
            defaultFilename: "ts3-recent-servers"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImportingRecoverySettings,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importRecoverySettings(from: url)
            } else if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExportingRecoverySettings,
            document: recoverySettingsDocument,
            contentType: .json,
            defaultFilename: "ts3-connection-recovery-settings"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExportingRecoverySnapshot,
            document: recoverySnapshotDocument,
            contentType: .plainText,
            defaultFilename: "ts3-connection-recovery"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImportingClientPackage,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importClientPackage(from: url)
            } else if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExportingClientPackage,
            document: clientPackageDocument,
            contentType: .json,
            defaultFilename: "ts3-client-package"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .alert(item: $deleteConfirmation) { confirmation in
            switch confirmation {
            case .clearRecent:
                return Alert(
                    title: Text("Clear Recent Servers?"),
                    message: Text("This removes the local connection history on this device."),
                    primaryButton: .destructive(Text("Clear")) {
                        model.clearRecentConnections()
                    },
                    secondaryButton: .cancel()
                )
            case .visibleRecent:
                return Alert(
                    title: Text("Delete Visible Recent Servers?"),
                    message: Text("This removes \(displayedRecentConnections.count) recent server entries from this device."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteRecentConnections(displayedRecentConnections)
                    },
                    secondaryButton: .cancel()
                )
            case .visibleBookmarks:
                return Alert(
                    title: Text("Delete Visible Bookmarks?"),
                    message: Text("This removes \(displayedBookmarks.count) saved bookmarks from this device."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteBookmarks(displayedBookmarks)
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAllFilterPresets:
                return Alert(
                    title: Text("Delete All Connection Filter Presets?"),
                    message: Text("This removes \(model.connectionFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllConnectionFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var connectionRecoverySnapshot: String {
        var rows = [
            "Auto Reconnect: \(model.autoReconnectEnabled ? "Enabled" : "Disabled")",
            "Initial Delay: \(model.autoReconnectInitialDelaySeconds)s",
            "Max Delay: \(model.autoReconnectMaxDelaySeconds)s",
            "Max Attempts: \(model.autoReconnectMaxAttempts == 0 ? "Unlimited" : String(model.autoReconnectMaxAttempts))",
            "Connection State: \(model.connectedStatus)"
        ]
        if let status = model.autoReconnectStatus, !status.isEmpty {
            rows.append("Recovery Status: \(status)")
        }
        if let snapshot = model.lastConnectionSnapshot {
            rows.append("Last Server: \(snapshot.host):\(snapshot.port)")
            rows.append("Last Nickname: \(snapshot.nickname)")
        }
        if let message = model.lastDisconnectMessage, !message.isEmpty {
            rows.append("Last Disconnect: \(message)")
        }
        rows.append("Recent Servers: \(model.recentConnections.count)")
        rows.append("Bookmarks: \(model.bookmarks.count)")
        return rows.joined(separator: "\n")
    }

    private func exportBookmarks() {
        do {
            bookmarkExportDocument = TS3BookmarkFileDocument(data: try model.bookmarksExportData())
            isExportingBookmarks = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importBookmarks(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importBookmarks(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyConnectionPreset(_ preset: TS3ConnectionFilterPreset) {
        connectionFilter = ConnectionFilter(rawValue: preset.connectionFilter) ?? .all
        connectionSortMode = ConnectionSortMode(rawValue: preset.sortMode) ?? .savedOrder
        connectionSortAscending = preset.sortAscending
        bookmarkFolderFilter = preset.bookmarkFolderFilter
        connectionSearchText = preset.searchText
        connectionPresetName = preset.name
    }

    private func connectionPresetSummary(_ preset: TS3ConnectionFilterPreset) -> String {
        var parts = [
            (ConnectionFilter(rawValue: preset.connectionFilter) ?? .all).title,
            "Sort \((ConnectionSortMode(rawValue: preset.sortMode) ?? .savedOrder).title)"
        ]
        if !preset.sortAscending {
            parts.append("Descending")
        }
        if !preset.bookmarkFolderFilter.isEmpty {
            parts.append("Folder \(folderFilterTitle(preset.bookmarkFolderFilter))")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func folderFilterTitle(_ value: String) -> String {
        value == "__unfiled__" ? "Unfiled" : value
    }

    private func exportConnectionPresets() {
        do {
            connectionPresetsDocument = TS3BookmarkFileDocument(data: try model.connectionFilterPresetsExportData())
            isExportingConnectionPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importConnectionPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importConnectionFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func exportRecentConnections() {
        do {
            recentConnectionsDocument = TS3BookmarkFileDocument(data: try model.recentConnectionsExportData())
            isExportingRecentConnections = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importRecentConnections(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importRecentConnections(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func exportRecoverySettings() {
        do {
            recoverySettingsDocument = TS3TextFileDocument(data: try model.connectionRecoverySettingsExportData())
            isExportingRecoverySettings = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importRecoverySettings(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importConnectionRecoverySettings(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func exportClientPackage() {
        do {
            clientPackageDocument = TS3BookmarkFileDocument(data: try model.clientMigrationPackageExportData())
            isExportingClientPackage = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importClientPackage(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importClientMigrationPackage(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private var normalizedConnectionSearchText: String {
        connectionSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearchingConnections: Bool {
        !normalizedConnectionSearchText.isEmpty
    }

    private var hasSavedConnectionOptions: Bool {
        isSearchingConnections
            || connectionFilter != .all
            || connectionSortMode != .savedOrder
            || !connectionSortAscending
            || !bookmarkFolderFilter.isEmpty
    }

    private func matchesBookmarkFolder(_ folder: String) -> Bool {
        let folder = folder.trimmingCharacters(in: .whitespacesAndNewlines)
        switch bookmarkFolderFilter {
        case "":
            return true
        case "__unfiled__":
            return folder.isEmpty
        default:
            return folder.caseInsensitiveCompare(bookmarkFolderFilter) == .orderedSame
        }
    }

    private func matchesConnectionFilter(serverPassword: String, defaultChannel: String, privilegeKey: String) -> Bool {
        switch connectionFilter {
        case .all:
            return true
        case .withPassword:
            return !serverPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .withDefaultChannel:
            return !defaultChannel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .withPrivilegeKey:
            return !privilegeKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func matchesConnectionSearch(name: String, host: String, port: String, nickname: String, defaultChannel: String) -> Bool {
        !isSearchingConnections
            || containsConnectionSearch(name)
            || containsConnectionSearch(host)
            || containsConnectionSearch(port)
            || containsConnectionSearch(nickname)
            || containsConnectionSearch(defaultChannel)
    }

    private func containsConnectionSearch(_ value: String) -> Bool {
        value.lowercased().contains(normalizedConnectionSearchText)
    }

    private func bookmarkSubtitle(_ bookmark: TS3BookmarkSummary) -> String {
        let server = "\(bookmark.host):\(bookmark.port)"
        let folder = bookmark.folder.trimmingCharacters(in: .whitespacesAndNewlines)
        return folder.isEmpty ? server : "\(folder) · \(server)"
    }

    private func sortedBookmarks(_ bookmarks: [TS3BookmarkSummary]) -> [TS3BookmarkSummary] {
        guard connectionSortMode != .savedOrder else { return bookmarks }
        return bookmarks.sorted { lhs, rhs in
            compareConnectionEntries(
                lhsName: lhs.name,
                lhsHost: lhs.host,
                lhsNickname: lhs.nickname,
                lhsPort: lhs.port,
                rhsName: rhs.name,
                rhsHost: rhs.host,
                rhsNickname: rhs.nickname,
                rhsPort: rhs.port
            )
        }
    }

    private func sortedRecentConnections(_ snapshots: [TS3ConnectionSnapshot]) -> [TS3ConnectionSnapshot] {
        guard connectionSortMode != .savedOrder else { return snapshots }
        return snapshots.sorted { lhs, rhs in
            compareConnectionEntries(
                lhsName: lhs.host,
                lhsHost: lhs.host,
                lhsNickname: lhs.nickname,
                lhsPort: lhs.port,
                rhsName: rhs.host,
                rhsHost: rhs.host,
                rhsNickname: rhs.nickname,
                rhsPort: rhs.port
            )
        }
    }

    private func compareConnectionEntries(
        lhsName: String,
        lhsHost: String,
        lhsNickname: String,
        lhsPort: String,
        rhsName: String,
        rhsHost: String,
        rhsNickname: String,
        rhsPort: String
    ) -> Bool {
        let comparison: ComparisonResult
        switch connectionSortMode {
        case .savedOrder:
            return false
        case .name:
            comparison = lhsName.localizedCaseInsensitiveCompare(rhsName)
        case .host:
            comparison = lhsHost.localizedCaseInsensitiveCompare(rhsHost)
        case .nickname:
            comparison = lhsNickname.localizedCaseInsensitiveCompare(rhsNickname)
        case .port:
            comparison = comparePorts(lhsPort, rhsPort)
        }

        if comparison == .orderedSame {
            return lhsHost.localizedCaseInsensitiveCompare(rhsHost) == .orderedAscending
        }
        return connectionSortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
    }

    private func comparePorts(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsPort = Int(lhs.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let rhsPort = Int(rhs.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        if lhsPort == rhsPort {
            return .orderedSame
        }
        return lhsPort < rhsPort ? .orderedAscending : .orderedDescending
    }
}

struct ConnectionManagerSheet: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ConnectView(allowsConnectionActions: false)
                .toolbar {
                    ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
}

struct TS3BookmarkFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .data] }
    static var writableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct TS3TextFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .data] }
    static var writableContentTypes: [UTType] { [.plainText] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BookmarkEditorSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var bookmark: TS3BookmarkSummary

    init(bookmark: TS3BookmarkSummary) {
        _bookmark = State(initialValue: bookmark)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bookmark")) {
                    TextField("Name", text: $bookmark.name)
                        .ts3PlainTextField()
                    TextField("Folder", text: $bookmark.folder)
                        .ts3PlainTextField()
                    TextField("Host", text: $bookmark.host)
                        .ts3URLTextField()
                    TextField("Port", text: $bookmark.port)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                }

                Section(header: Text("Profile")) {
                    TextField("Nickname", text: $bookmark.nickname)
                        .ts3PlainTextField()
                    SecureField("Server Password", text: $bookmark.serverPassword)
                    TextField("Default Channel", text: $bookmark.defaultChannel)
                        .ts3PlainTextField()
                    SecureField("Channel Password", text: $bookmark.defaultChannelPassword)
                    SecureField("Privilege Key", text: $bookmark.privilegeKey)
                }
            }
            .navigationTitle("Edit Bookmark")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Apply") {
                        model.applyBookmark(bookmark)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!canSubmit)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Connect") {
                        model.applyBookmark(bookmark)
                        model.connect()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!canSubmit)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Save") {
                        model.updateBookmark(bookmark)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!canSubmit)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var canSubmit: Bool {
        !bookmark.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !bookmark.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Int(bookmark.port.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
}

struct ChannelListView: View {
    private enum ChannelConfirmation: Identifiable {
        case unsubscribeAll
        case deleteAllFilterPresets

        var id: String {
            switch self {
            case .unsubscribeAll: return "unsubscribeAll"
            case .deleteAllFilterPresets: return "deleteAllFilterPresets"
            }
        }
    }

    private enum ChannelTreeFilter: String, CaseIterable, Identifiable {
        case all
        case current
        case `default`
        case passwordProtected
        case unsubscribed
        case populated
        case empty
        case mutedUsers
        case awayUsers
        case talkRequests

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Channels"
            case .current: return "Current Channel"
            case .default: return "Default Channel"
            case .passwordProtected: return "Password Protected"
            case .unsubscribed: return "Unsubscribed"
            case .populated: return "With Users"
            case .empty: return "Empty"
            case .mutedUsers: return "Muted Users"
            case .awayUsers: return "Away Users"
            case .talkRequests: return "Talk Requests"
            }
        }

        func matches(channel: TS3ChannelSummary, members: [TS3UserSummary]) -> Bool {
            switch self {
            case .all:
                return true
            case .current:
                return channel.isCurrent
            case .default:
                return channel.isDefault
            case .passwordProtected:
                return channel.isPasswordProtected
            case .unsubscribed:
                return channel.isSubscribed == false
            case .populated:
                return !members.isEmpty
            case .empty:
                return members.isEmpty
            case .mutedUsers:
                return members.contains { $0.isInputMuted || $0.isOutputMuted }
            case .awayUsers:
                return members.contains { $0.isAway }
            case .talkRequests:
                return members.contains { $0.isRequestingTalkPower }
            }
        }

        func matches(user: TS3UserSummary) -> Bool {
            switch self {
            case .mutedUsers:
                return user.isInputMuted || user.isOutputMuted
            case .awayUsers:
                return user.isAway
            case .talkRequests:
                return user.isRequestingTalkPower
            case .all, .current, .default, .passwordProtected, .unsubscribed, .populated, .empty:
                return true
            }
        }
    }

    private enum ChannelMemberSortMode: String, CaseIterable, Identifiable {
        case nickname
        case clientId
        case talkPower
        case status

        var id: String { rawValue }

        var title: String {
            switch self {
            case .nickname: return "Nickname"
            case .clientId: return "Client ID"
            case .talkPower: return "Talk Power"
            case .status: return "Status"
            }
        }
    }

    @EnvironmentObject private var model: TS3AppModel
    @State private var isShowingServerTools = false
    @State private var isShowingChat = false
    @State private var isShowingEvents = false
    @State private var isShowingWhisper = false
    @State private var isShowingCreateChannel = false
    @State private var isShowingDisconnect = false
    @State private var isShowingSubscriptionPresets = false
    @State private var isExportingChannelTree = false
    @State private var isImportingChannelTreePresets = false
    @State private var isExportingChannelTreePresets = false
    @State private var channelTreeDocument = TS3TextFileDocument()
    @State private var channelTreePresetsDocument = TS3BookmarkFileDocument()
    @State private var channelSearchText = ""
    @State private var channelTreeFilter: ChannelTreeFilter = .all
    @State private var channelTreeSortMode: ChannelTreeItem.SiblingSortMode = .serverOrder
    @State private var channelTreeSortAscending = true
    @State private var channelMemberSortMode: ChannelMemberSortMode = .nickname
    @State private var channelMemberSortAscending = true
    @State private var channelCurrentUserFirst = true
    @State private var channelTreePresetName = ""
    @State private var confirmation: ChannelConfirmation?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(model.connectedStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    isShowingChat = true
                } label: {
                    ChatButtonLabel(unreadCount: model.unreadChatMessageCount)
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button {
                    isShowingServerTools = true
                } label: {
                    Label("Tools", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button {
                    isShowingEvents = true
                } label: {
                    EventsButtonLabel(unreadCount: model.unreadPokeCount + model.unreadActivityCount)
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button {
                    isShowingWhisper = true
                } label: {
                    WhisperButtonLabel(isActive: model.whisperRoute != .none)
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button("Disconnect") {
                    isShowingDisconnect = true
                }
                .buttonStyle(TS3BorderedButtonStyle())
            }
            .padding(.horizontal)

            ServerHeaderView()
                .padding(.horizontal)

            CurrentChannelCard()
                .padding(.horizontal)

            ChannelSearchField(text: $channelSearchText)
                .padding(.horizontal)

            HStack(spacing: 10) {
                Picker("Filter", selection: $channelTreeFilter) {
                    ForEach(ChannelTreeFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Picker("Sort", selection: $channelTreeSortMode) {
                    ForEach(ChannelTreeItem.SiblingSortMode.allCases) { sortMode in
                        Text(sortMode.title).tag(sortMode)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Toggle("Ascending", isOn: $channelTreeSortAscending)

                Menu {
                    Picker("Sort Members", selection: $channelMemberSortMode) {
                        ForEach(ChannelMemberSortMode.allCases) { sortMode in
                            Text(sortMode.title).tag(sortMode)
                        }
                    }
                    Toggle("Member Ascending", isOn: $channelMemberSortAscending)
                    Toggle("Current User First", isOn: $channelCurrentUserFirst)
                } label: {
                    Label("Members", systemImage: "person.2")
                }

                Menu {
                    TextField("Preset Name", text: $channelTreePresetName)
                    Button("Save Current Filters") {
                        model.saveChannelTreeFilterPreset(
                            name: channelTreePresetName,
                            treeFilter: channelTreeFilter.rawValue,
                            sortMode: channelTreeSortMode.rawValue,
                            sortAscending: channelTreeSortAscending,
                            memberSortMode: channelMemberSortMode.rawValue,
                            memberSortAscending: channelMemberSortAscending,
                            currentUserFirst: channelCurrentUserFirst,
                            searchText: channelSearchText
                        )
                        channelTreePresetName = ""
                    }
                    .disabled(channelTreePresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if model.channelTreeFilterPresets.isEmpty {
                        Text("No saved channel tree filter presets")
                    } else {
                        ForEach(model.channelTreeFilterPresets) { preset in
                            Menu {
                                Button("Apply Preset") {
                                    applyChannelTreePreset(preset)
                                }
                                Button("Use Name") {
                                    channelTreePresetName = preset.name
                                }
                                Button("Delete Preset") {
                                    model.deleteChannelTreeFilterPreset(preset)
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(preset.name)
                                    Text(channelTreePresetSummary(preset))
                                }
                            }
                        }
                    }
                    Divider()
                    Button("Export Presets") {
                        exportChannelTreePresets()
                    }
                    .disabled(model.channelTreeFilterPresets.isEmpty)
                    Button("Import Presets") {
                        isImportingChannelTreePresets = true
                    }
                    Button("Delete All Presets") {
                        confirmation = .deleteAllFilterPresets
                    }
                    .disabled(model.channelTreeFilterPresets.isEmpty)
                } label: {
                    Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                }

                if hasChannelTreeOptions {
                    Button("Clear") {
                        channelTreeFilter = .all
                        channelTreeSortMode = .serverOrder
                        channelTreeSortAscending = true
                        channelMemberSortMode = .nickname
                        channelMemberSortAscending = true
                        channelCurrentUserFirst = true
                        channelSearchText = ""
                    }
                    .buttonStyle(TS3BorderedButtonStyle())
                }
            }
            .padding(.horizontal)

            List {
                Section(header: Text(channelSectionTitle)) {
                    ForEach(channelTree) { item in
                        ChannelRow(channel: item.channel, members: members(in: item.channel.id))
                            .padding(.leading, CGFloat(item.depth) * 18)
                            .listRowBackground(item.channel.isCurrent ? Color.accentColor.opacity(0.08) : Color.clear)
                    }
                    if channelTree.isEmpty {
                        Text("No matching channels or users")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .ts3ChannelListStyle()

            TalkControlBar()
        }
        .navigationTitle("Channels")
        .toolbar {
            ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                Menu {
                    Button("Copy Visible Channel Tree") {
                        TS3PlatformSupport.copyToPasteboard(channelTreeSnapshot)
                    }
                    .disabled(channelTree.isEmpty)
                    Button("Export Visible Channel Tree") {
                        channelTreeDocument = TS3TextFileDocument(data: Data(channelTreeSnapshot.utf8))
                        isExportingChannelTree = true
                    }
                    .disabled(channelTree.isEmpty)
                    Button("Subscribe Visible Channels") {
                        model.setChannelsSubscribed(visibleChannels, isSubscribed: true)
                    }
                    .disabled(!canSubscribeVisibleChannels)
                    Button("Unsubscribe Visible Channels") {
                        model.setChannelsSubscribed(visibleChannels, isSubscribed: false)
                    }
                    .disabled(!canUnsubscribeVisibleChannels)
                    Button("Subscribe All Channels") {
                        model.setAllChannelsSubscribed(true)
                    }
                    Button("Unsubscribe All Channels") {
                        confirmation = .unsubscribeAll
                    }
                    Button("Subscription Presets") {
                        isShowingSubscriptionPresets = true
                    }
                } label: {
                    Label("Channel Tools", systemImage: "list.bullet.rectangle")
                }
            }
            ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                Button {
                    isShowingCreateChannel = true
                } label: {
                    Label("New Channel", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingChat) {
            ChatSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingServerTools) {
            ServerToolsSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingEvents) {
            EventsSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingWhisper) {
            WhisperSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingDisconnect) {
            DisconnectSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingCreateChannel) {
            ChannelEditorSheet(mode: .create(parent: model.currentChannel))
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingSubscriptionPresets) {
            ChannelSubscriptionPresetsSheet()
                .environmentObject(model)
        }
        .fileExporter(
            isPresented: $isExportingChannelTree,
            document: channelTreeDocument,
            contentType: .plainText,
            defaultFilename: "ts3-channel-tree"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExportingChannelTreePresets,
            document: channelTreePresetsDocument,
            contentType: .json,
            defaultFilename: "ts3-channel-tree-filter-presets"
        ) { result in
            if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .fileImporter(
            isPresented: $isImportingChannelTreePresets,
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                importChannelTreePresets(from: url)
            } else if case .failure(let error) = result {
                model.lastError = error.localizedDescription
            }
        }
        .alert(item: $confirmation) { confirmation in
            switch confirmation {
            case .unsubscribeAll:
                return Alert(
                    title: Text("Unsubscribe All Channels?"),
                    message: Text("This unsubscribes from every visible server channel."),
                    primaryButton: .destructive(Text("Unsubscribe")) {
                        model.setAllChannelsSubscribed(false)
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAllFilterPresets:
                return Alert(
                    title: Text("Delete All Channel Tree Filter Presets?"),
                    message: Text("This removes \(model.channelTreeFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllChannelTreeFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var channelTree: [ChannelTreeItem] {
        ChannelTreeItem.flatten(
            channels: filteredChannels,
            sortMode: channelTreeSortMode,
            sortAscending: channelTreeSortAscending
        )
    }

    private var visibleChannels: [TS3ChannelSummary] {
        channelTree.map(\.channel)
    }

    private var canSubscribeVisibleChannels: Bool {
        visibleChannels.contains { $0.isSubscribed != true }
    }

    private var canUnsubscribeVisibleChannels: Bool {
        visibleChannels.contains { $0.isSubscribed != false }
    }

    private var channelSectionTitle: String {
        hasChannelTreeFilters ? "Filtered Channels" : "Channels"
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasChannelTreeFilters: Bool {
        isSearching || channelTreeFilter != .all
    }

    private var hasChannelTreeOptions: Bool {
        hasChannelTreeFilters
            || channelTreeSortMode != .serverOrder
            || !channelTreeSortAscending
            || channelMemberSortMode != .nickname
            || !channelMemberSortAscending
            || !channelCurrentUserFirst
    }

    private var normalizedSearchText: String {
        channelSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var filteredChannels: [TS3ChannelSummary] {
        guard hasChannelTreeFilters else { return model.channels }
        let matchingChannelIds = Set(model.channels.filter(channelMatchesFilters).map(\.id))
        let matchingMemberChannelIds = Set(model.clients.filter(userMatchesFilters).map(\.channelId))
        var included = matchingChannelIds.union(matchingMemberChannelIds)

        let channelsById = Dictionary(uniqueKeysWithValues: model.channels.map { ($0.id, $0) })
        for channelId in included {
            var parentId = normalizedParentId(channelsById[channelId]?.parentId)
            while let id = parentId, let parent = channelsById[id] {
                included.insert(id)
                parentId = normalizedParentId(parent.parentId)
            }
        }

        return model.channels.filter { included.contains($0.id) }
    }

    private var channelTreeSnapshot: String {
        channelTree.map { item in
            let channel = item.channel
            let prefix = String(repeating: "  ", count: item.depth)
            let users = members(in: channel.id)
            var details = [
                "id=\(channel.id)",
                "users=\(users.count)"
            ]
            if channel.isCurrent {
                details.append("current")
            }
            if channel.isDefault {
                details.append("default")
            }
            if channel.isPasswordProtected {
                details.append("password")
            }
            if channel.isSubscribed == false {
                details.append("unsubscribed")
            }
            let memberText = users.isEmpty
                ? ""
                : "\n" + users.map { "\(prefix)  - \($0.nickname) [clientId=\($0.id)]" }.joined(separator: "\n")
            return "\(prefix)\(channel.name) (\(details.joined(separator: ", ")))\(memberText)"
        }
        .joined(separator: "\n")
    }

    private func members(in channelId: Int) -> [TS3UserSummary] {
        let members = model.members(in: channelId)
        guard hasChannelTreeFilters,
              !channelMatchesFilters(model.channels.first { $0.id == channelId }) else {
            return sortedMembers(members)
        }
        return sortedMembers(members.filter(userMatchesFilters))
    }

    private func channelMatchesFilters(_ channel: TS3ChannelSummary?) -> Bool {
        guard let channel else { return false }
        let channelMembers = model.members(in: channel.id)
        let matchesState = channelTreeFilter.matches(channel: channel, members: channelMembers)
        let matchesSearch = !isSearching || channelMatchesSearch(channel)
        return matchesState && matchesSearch
    }

    private func userMatchesFilters(_ user: TS3UserSummary) -> Bool {
        channelTreeFilter.matches(user: user) && (!isSearching || userMatchesSearch(user))
    }

    private func channelMatchesSearch(_ channel: TS3ChannelSummary?) -> Bool {
        guard let channel else { return false }
        return containsSearch(channel.name)
            || containsSearch(channel.topic)
            || containsSearch(channel.description)
            || containsSearch(channel.phoneticName)
    }

    private func userMatchesSearch(_ user: TS3UserSummary) -> Bool {
        containsSearch(user.nickname)
            || containsSearch(user.uniqueIdentifier)
            || containsSearch(user.description)
            || containsSearch(user.country)
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func normalizedParentId(_ parentId: Int?) -> Int? {
        guard let parentId, parentId > 0 else { return nil }
        return parentId
    }

    private func applyChannelTreePreset(_ preset: TS3ChannelTreeFilterPreset) {
        channelTreeFilter = ChannelTreeFilter(rawValue: preset.treeFilter) ?? .all
        channelTreeSortMode = ChannelTreeItem.SiblingSortMode(rawValue: preset.sortMode) ?? .serverOrder
        channelTreeSortAscending = preset.sortAscending
        channelMemberSortMode = ChannelMemberSortMode(rawValue: preset.memberSortMode) ?? .nickname
        channelMemberSortAscending = preset.memberSortAscending
        channelCurrentUserFirst = preset.currentUserFirst
        channelSearchText = preset.searchText
        channelTreePresetName = preset.name
    }

    private func channelTreePresetSummary(_ preset: TS3ChannelTreeFilterPreset) -> String {
        var parts = [
            (ChannelTreeFilter(rawValue: preset.treeFilter) ?? .all).title,
            "Sort \((ChannelTreeItem.SiblingSortMode(rawValue: preset.sortMode) ?? .serverOrder).title)",
            "Members \((ChannelMemberSortMode(rawValue: preset.memberSortMode) ?? .nickname).title)"
        ]
        if !preset.sortAscending {
            parts.append("Channels Descending")
        }
        if !preset.memberSortAscending {
            parts.append("Members Descending")
        }
        if !preset.currentUserFirst {
            parts.append("No Current User Pin")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func sortedMembers(_ members: [TS3UserSummary]) -> [TS3UserSummary] {
        members.sorted { lhs, rhs in
            if channelCurrentUserFirst, lhs.isCurrentUser != rhs.isCurrentUser {
                return lhs.isCurrentUser && !rhs.isCurrentUser
            }
            let comparison = memberComparison(lhs, rhs)
            if comparison == .orderedSame {
                return lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname) == .orderedAscending
            }
            return channelMemberSortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func memberComparison(_ lhs: TS3UserSummary, _ rhs: TS3UserSummary) -> ComparisonResult {
        switch channelMemberSortMode {
        case .nickname:
            return lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname)
        case .clientId:
            return compareInts(lhs.id, rhs.id)
        case .talkPower:
            return compareInts(lhs.talkPower ?? Int.min, rhs.talkPower ?? Int.min)
        case .status:
            return compareInts(memberStatusRank(lhs), memberStatusRank(rhs))
        }
    }

    private func memberStatusRank(_ user: TS3UserSummary) -> Int {
        if user.isRequestingTalkPower { return 0 }
        if user.isPrioritySpeaker { return 1 }
        if user.isChannelCommander { return 2 }
        if user.isTalker { return 3 }
        if user.isAway { return 4 }
        if user.isInputMuted || user.isOutputMuted { return 5 }
        return 6
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs { return .orderedSame }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func exportChannelTreePresets() {
        do {
            channelTreePresetsDocument = TS3BookmarkFileDocument(data: try model.channelTreeFilterPresetsExportData())
            isExportingChannelTreePresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importChannelTreePresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importChannelTreeFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ChannelSubscriptionPresetsSheet: View {
    private enum SubscriptionConfirmation: Identifiable {
        case unsubscribeAll
        case deleteAllPresets

        var id: String {
            switch self {
            case .unsubscribeAll: return "unsubscribeAll"
            case .deleteAllPresets: return "deleteAllPresets"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var presetName = ""
    @State private var isImportingPresets = false
    @State private var isExportingPresets = false
    @State private var confirmation: SubscriptionConfirmation?
    @State private var presetsDocument = TS3BookmarkFileDocument()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Subscriptions")) {
                    Text("Subscribed Channels: \(subscribedChannelCount)")
                        .foregroundColor(.secondary)
                    TextField("Preset Name", text: $presetName)
                        .ts3PlainTextField()
                    Button("Save Current Subscriptions") {
                        model.saveCurrentChannelSubscriptionPreset(name: presetName)
                        presetName = ""
                    }
                    .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Subscribe All Channels") {
                        model.setAllChannelsSubscribed(true)
                    }
                    Button("Unsubscribe All Channels") {
                        confirmation = .unsubscribeAll
                    }
                }

                Section(header: Text("Presets")) {
                    if model.channelSubscriptionPresets.isEmpty {
                        Text("No saved subscription presets")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.channelSubscriptionPresets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(presetSummary(preset))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button("Apply Preset") {
                                        model.applyChannelSubscriptionPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteChannelSubscriptionPreset(preset)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Backup")) {
                    Button("Export Presets") {
                        exportPresets()
                    }
                    .disabled(model.channelSubscriptionPresets.isEmpty)
                    Button("Import Presets") {
                        isImportingPresets = true
                    }
                    Button("Delete All Presets") {
                        confirmation = .deleteAllPresets
                    }
                    .disabled(model.channelSubscriptionPresets.isEmpty)
                }
            }
            .navigationTitle("Subscription Presets")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-channel-subscription-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(item: $confirmation) { confirmation in
                switch confirmation {
                case .unsubscribeAll:
                    return Alert(
                        title: Text("Unsubscribe All Channels?"),
                        message: Text("This unsubscribes from every visible server channel."),
                        primaryButton: .destructive(Text("Unsubscribe")) {
                            model.setAllChannelsSubscribed(false)
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteAllPresets:
                    return Alert(
                        title: Text("Delete All Subscription Presets?"),
                        message: Text("This removes \(model.channelSubscriptionPresets.count) saved local subscription presets."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteAllChannelSubscriptionPresets()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private var subscribedChannelCount: Int {
        model.channels.filter { $0.isSubscribed == true }.count
    }

    private func presetSummary(_ preset: TS3ChannelSubscriptionPreset) -> String {
        let availableCount = preset.channelIds.filter { id in
            model.channels.contains { $0.id == id }
        }.count
        return "\(preset.channelIds.count) channels · \(availableCount) available"
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.channelSubscriptionPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importChannelSubscriptionPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ChannelSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search channels or users", text: $text)
                .ts3PlainTextField()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.10))
        .cornerRadius(8)
    }
}

struct DisconnectSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var reason = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Disconnect")) {
                    TextField("Message", text: $reason)
                        .ts3PlainTextField()
                    Button("Disconnect") {
                        model.disconnect(reason: reason)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Disconnect")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ServerHeaderView: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                ServerIconView(server: model.serverInfo)
                VStack(alignment: .leading, spacing: 4) {
                    Text(serverName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if let statusLine {
                        Text(statusLine)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            if let welcomeMessage {
                Text(welcomeMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if let hostMessage {
                Text(hostMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if let bannerImageURL {
                ServerRemoteImageLinkView(
                    url: bannerImageURL,
                    linkURL: bannerLinkURL,
                    maxHeight: 90,
                    accessibilityLabel: "Server banner"
                )
            }

            if let hostButtonImageURL {
                ServerRemoteImageLinkView(
                    url: hostButtonImageURL,
                    linkURL: hostButtonLinkURL,
                    maxHeight: 32,
                    accessibilityLabel: hostButtonTitle
                )
            }

            if !linkActions.isEmpty {
                HStack(spacing: 8) {
                    ForEach(linkActions) { action in
                        Button(action.title) {
                            TS3PlatformSupport.openURL(action.url)
                        }
                        .buttonStyle(TS3BorderedButtonStyle())
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var serverName: String {
        model.serverInfo.name.isEmpty ? model.serverHost : model.serverInfo.name
    }

    private var statusLine: String? {
        var parts: [String] = []
        if let clients = model.serverInfo.clientsOnline {
            if let maxClients = model.serverInfo.maxClients {
                parts.append("\(clients)/\(maxClients) clients")
            } else {
                parts.append("\(clients) clients")
            }
        }
        if let channels = model.serverInfo.channelsOnline {
            parts.append("\(channels) channels")
        }
        if let uptime = model.serverInfo.uptimeSeconds {
            parts.append(ServerInfoRows.uptimeText(uptime))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    private var welcomeMessage: String? {
        nonEmpty(model.serverInfo.welcomeMessage)
    }

    private var hostMessage: String? {
        nonEmpty(model.serverInfo.hostMessage)
    }

    private var bannerImageURL: URL? {
        parsedURL(model.serverInfo.hostBannerGraphicsURL)
    }

    private var bannerLinkURL: URL? {
        parsedURL(model.serverInfo.hostBannerURL)
    }

    private var hostButtonImageURL: URL? {
        parsedURL(model.serverInfo.hostButtonGraphicsURL)
    }

    private var hostButtonLinkURL: URL? {
        parsedURL(model.serverInfo.hostButtonURL)
    }

    private var hostButtonTitle: String {
        nonEmpty(model.serverInfo.hostButtonTooltip) ?? "Host button"
    }

    private var linkActions: [ServerHeaderLinkAction] {
        var actions: [ServerHeaderLinkAction] = []
        if let url = parsedURL(model.serverInfo.hostBannerURL) {
            actions.append(ServerHeaderLinkAction(title: "Banner Link", url: url))
        }
        if let url = parsedURL(model.serverInfo.hostBannerGraphicsURL) {
            actions.append(ServerHeaderLinkAction(title: "Banner Image", url: url))
        }
        if let url = parsedURL(model.serverInfo.hostButtonURL) {
            actions.append(ServerHeaderLinkAction(title: nonEmpty(model.serverInfo.hostButtonTooltip) ?? "Host Link", url: url))
        }
        if let url = parsedURL(model.serverInfo.hostButtonGraphicsURL) {
            actions.append(ServerHeaderLinkAction(title: "Host Image", url: url))
        }
        return actions
    }

    private func nonEmpty(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func parsedURL(_ value: String?) -> URL? {
        guard let text = nonEmpty(value) else { return nil }
        return URL(string: text)
    }
}

struct ServerRemoteImageLinkView: View {
    let url: URL
    let linkURL: URL?
    let maxHeight: CGFloat
    let accessibilityLabel: String
    @State private var image: TS3PlatformImage?
    @State private var requestedURL: URL?

    var body: some View {
        Group {
            if let image {
                Button {
                    if let linkURL {
                        TS3PlatformSupport.openURL(linkURL)
                    }
                } label: {
                    Image(ts3PlatformImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(maxHeight: maxHeight)
                }
                .buttonStyle(.plain)
                .disabled(linkURL == nil)
                .accessibilityLabel(accessibilityLabel)
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: url) { _ in
            image = nil
            loadImage()
        }
    }

    private func loadImage() {
        guard requestedURL != url else { return }
        requestedURL = url
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data, let loadedImage = TS3PlatformImage(data: data) else { return }
            DispatchQueue.main.async {
                if requestedURL == url {
                    image = loadedImage
                }
            }
        }.resume()
    }
}

struct ServerIconView: View {
    let server: TS3ServerInfoSummary

    var body: some View {
        Group {
            if let image = platformImage {
                Image(ts3PlatformImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: server.passwordProtected ? "lock.shield" : "server.rack")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.accentColor)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityLabel("Server icon")
    }

    private var platformImage: TS3PlatformImage? {
        guard let iconURL = server.iconURL else { return nil }
        return TS3PlatformImage(contentsOfFile: iconURL.path)
    }
}

struct ServerHeaderLinkAction: Identifiable {
    let title: String
    let url: URL

    var id: String { "\(title)-\(url.absoluteString)" }
}

struct ChannelTreeItem: Identifiable {
    enum SiblingSortMode: String, CaseIterable, Identifiable {
        case serverOrder
        case name
        case channelId

        var id: String { rawValue }

        var title: String {
            switch self {
            case .serverOrder: return "Server Order"
            case .name: return "Name"
            case .channelId: return "Channel ID"
            }
        }
    }

    let channel: TS3ChannelSummary
    let depth: Int

    var id: Int { channel.id }

    static func flatten(
        channels: [TS3ChannelSummary],
        sortMode: SiblingSortMode = .serverOrder,
        sortAscending: Bool = true
    ) -> [ChannelTreeItem] {
        let children = Dictionary(grouping: channels) { channel in
            normalizedParentId(channel.parentId)
        }
        var visited: Set<Int> = []
        var result: [ChannelTreeItem] = []

        appendChildren(
            of: nil,
            depth: 0,
            children: children,
            sortMode: sortMode,
            sortAscending: sortAscending,
            visited: &visited,
            result: &result
        )

        let remaining = channels
            .filter { !visited.contains($0.id) }
            .sorted { compareChannels($0, $1, sortMode: sortMode, sortAscending: sortAscending) }
        for channel in remaining {
            appendChannel(
                channel,
                depth: 0,
                children: children,
                sortMode: sortMode,
                sortAscending: sortAscending,
                visited: &visited,
                result: &result
            )
        }
        return result
    }

    private static func appendChildren(
        of parentId: Int?,
        depth: Int,
        children: [Int?: [TS3ChannelSummary]],
        sortMode: SiblingSortMode,
        sortAscending: Bool,
        visited: inout Set<Int>,
        result: inout [ChannelTreeItem]
    ) {
        let sortedChildren = sortedSiblings(
            children[parentId] ?? [],
            sortMode: sortMode,
            sortAscending: sortAscending
        )
        for channel in sortedChildren {
            appendChannel(
                channel,
                depth: depth,
                children: children,
                sortMode: sortMode,
                sortAscending: sortAscending,
                visited: &visited,
                result: &result
            )
        }
    }

    private static func appendChannel(
        _ channel: TS3ChannelSummary,
        depth: Int,
        children: [Int?: [TS3ChannelSummary]],
        sortMode: SiblingSortMode,
        sortAscending: Bool,
        visited: inout Set<Int>,
        result: inout [ChannelTreeItem]
    ) {
        guard !visited.contains(channel.id) else { return }
        visited.insert(channel.id)
        result.append(ChannelTreeItem(channel: channel, depth: depth))
        appendChildren(
            of: channel.id,
            depth: depth + 1,
            children: children,
            sortMode: sortMode,
            sortAscending: sortAscending,
            visited: &visited,
            result: &result
        )
    }

    private static func normalizedParentId(_ parentId: Int?) -> Int? {
        guard let parentId, parentId > 0 else { return nil }
        return parentId
    }

    private static func sortedSiblings(
        _ channels: [TS3ChannelSummary],
        sortMode: SiblingSortMode,
        sortAscending: Bool
    ) -> [TS3ChannelSummary] {
        switch sortMode {
        case .serverOrder:
            let ordered = orderedSiblings(channels)
            return sortAscending ? ordered : Array(ordered.reversed())
        case .name, .channelId:
            return channels.sorted {
                compareChannels($0, $1, sortMode: sortMode, sortAscending: sortAscending)
            }
        }
    }

    private static func orderedSiblings(_ channels: [TS3ChannelSummary]) -> [TS3ChannelSummary] {
        let ids = Set(channels.map(\.id))
        let byPreviousId = Dictionary(grouping: channels) { channel -> Int? in
            guard let previousId = channel.order, ids.contains(previousId) else { return nil }
            return previousId
        }
        var visited: Set<Int> = []
        var result: [TS3ChannelSummary] = []

        func appendChain(startingAt channel: TS3ChannelSummary) {
            var current: TS3ChannelSummary? = channel
            while let channel = current, !visited.contains(channel.id) {
                visited.insert(channel.id)
                result.append(channel)
                current = byPreviousId[channel.id]?.sorted(by: stableChannelSort).first {
                    !visited.contains($0.id)
                }
            }
        }

        for channel in (byPreviousId[nil] ?? []).sorted(by: stableChannelSort) {
            appendChain(startingAt: channel)
        }

        for channel in channels.sorted(by: stableChannelSort) where !visited.contains(channel.id) {
            appendChain(startingAt: channel)
        }

        return result
    }

    private static func stableChannelSort(_ lhs: TS3ChannelSummary, _ rhs: TS3ChannelSummary) -> Bool {
        lhs.id < rhs.id
    }

    private static func compareChannels(
        _ lhs: TS3ChannelSummary,
        _ rhs: TS3ChannelSummary,
        sortMode: SiblingSortMode,
        sortAscending: Bool
    ) -> Bool {
        let comparison: ComparisonResult
        switch sortMode {
        case .serverOrder:
            comparison = lhs.id == rhs.id ? .orderedSame : (lhs.id < rhs.id ? .orderedAscending : .orderedDescending)
        case .name:
            comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
        case .channelId:
            comparison = lhs.id == rhs.id ? .orderedSame : (lhs.id < rhs.id ? .orderedAscending : .orderedDescending)
        }
        if comparison == .orderedSame {
            return stableChannelSort(lhs, rhs)
        }
        return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
    }
}

struct CurrentChannelCard: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Channel")
                .font(.caption)
                .foregroundColor(.secondary)

            if let channel = model.currentChannel {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(channel.name)
                            .font(.headline)
                        if let topic = channel.topic, !topic.isEmpty {
                            Text(topic)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        model.setDefaultChannel(channel)
                    } label: {
                        Image(systemName: "pin")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Set current channel as default")
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.secondary)
                    Text("Current channel not available yet.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.10))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ChannelRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary
    let members: [TS3UserSummary]
    @State private var joinPassword = ""
    @State private var defaultChannelPassword = ""
    @State private var fullInviteChannelPassword = ""
    @State private var isShowingJoinPassword = false
    @State private var isShowingDefaultChannelPassword = false
    @State private var isShowingFullInvitePassword = false
    @State private var isShowingInfo = false
    @State private var isShowingChannelMessage = false
    @State private var isShowingEdit = false
    @State private var isShowingMove = false
    @State private var isShowingPermissions = false
    @State private var isShowingFiles = false
    @State private var isShowingPrivilegeKeys = false
    @State private var isConfirmingDelete = false
    @State private var isConfirmingForcedDelete = false

    private var channelPath: String {
        model.channelPath(for: channel)
    }

    private var channelClipboardSummary: String {
        var parts = [
            "channelId=\(channel.id)",
            "name=\(channel.name)",
            "path=\(channelPath)"
        ]
        if let topic = channel.topic, !topic.isEmpty {
            parts.append("topic=\(topic)")
        }
        if let description = channel.description, !description.isEmpty {
            parts.append("description=\(description)")
        }
        if let iconId = channel.iconId, iconId != 0 {
            parts.append("iconId=\(iconId)")
        }
        parts.append("members=\(members.count)")
        return parts.joined(separator: " | ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(channel.name)
                            .fontWeight(channel.isCurrent ? .semibold : .regular)
                        if channel.isCurrent {
                            Text("Current")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        if channel.isDefault {
                            Image(systemName: "house.fill")
                                .foregroundColor(.secondary)
                        }
                        if let iconId = channel.iconId, iconId != 0 {
                            ChannelIconView(channel: channel)
                        }
                        if channel.isPasswordProtected {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                        }
                        if channel.isSubscribed == false {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        Text("\(members.count) user\(members.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let power = channel.neededTalkPower {
                            Text("Talk \(power)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let codecQuality = channel.codecQuality {
                            Text("Quality \(codecQuality)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let limitText = channelLimitText {
                            Text(limitText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let topic = channel.topic, !topic.isEmpty {
                        Text(topic)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if channel.isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                } else {
                    Button("Join") {
                        if channel.isPasswordProtected {
                            isShowingJoinPassword = true
                        } else {
                            model.joinChannel(channel)
                        }
                    }
                    .buttonStyle(TS3BorderedButtonStyle())
                }
                Menu {
                    Button("Channel Info") {
                        isShowingInfo = true
                    }
                    Button("Copy Channel Summary") {
                        TS3PlatformSupport.copyToPasteboard(channelClipboardSummary)
                    }
                    Button("Copy Channel Name") {
                        TS3PlatformSupport.copyToPasteboard(channel.name)
                    }
                    Button("Copy Channel Path") {
                        TS3PlatformSupport.copyToPasteboard(channelPath)
                    }
                    Button("Copy Channel Invite Link") {
                        model.copyInviteLink(for: channel)
                    }
                    Button("Copy Full Channel Invite Link") {
                        if channel.isPasswordProtected {
                            fullInviteChannelPassword = ""
                            isShowingFullInvitePassword = true
                        } else {
                            model.copyFullInviteLink(for: channel)
                        }
                    }
                    Button("Copy Channel ID") {
                        TS3PlatformSupport.copyToPasteboard("\(channel.id)")
                    }
                    Button("Send Channel Message") {
                        isShowingChannelMessage = true
                    }
                    if let isSubscribed = channel.isSubscribed {
                        Button(isSubscribed ? "Unsubscribe Channel" : "Subscribe Channel") {
                            model.setChannelSubscribed(channel, isSubscribed: !isSubscribed)
                        }
                    } else {
                        Button("Subscribe Channel") {
                            model.setChannelSubscribed(channel, isSubscribed: true)
                        }
                    }
                    Button("Edit Channel") {
                        isShowingEdit = true
                    }
                    Button("Edit Channel Permissions") {
                        model.selectChannelPermissions(channel)
                        isShowingPermissions = true
                    }
                    Button("Browse Channel Files") {
                        model.openFileBrowser(channel: channel)
                        isShowingFiles = true
                    }
                    if !model.channelGroups.isEmpty {
                        Button("Create Channel Privilege Key") {
                            isShowingPrivilegeKeys = true
                        }
                    }
                    Button("Move Channel") {
                        isShowingMove = true
                    }
                    Button("Set as Default Channel") {
                        if channel.isPasswordProtected {
                            defaultChannelPassword = ""
                            isShowingDefaultChannelPassword = true
                        } else {
                            model.setDefaultChannel(channel)
                        }
                    }
                    Button("Whisper to Channel") {
                        model.enableWhisperToChannel(id: channel.id)
                    }
                    Button("Delete Channel") {
                        isConfirmingDelete = true
                    }
                    Button("Force Delete Channel") {
                        isConfirmingForcedDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }

            if members.isEmpty {
                Text("No users in this channel")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(members) { member in
                        ChannelMemberRow(member: member)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isShowingJoinPassword) {
            JoinChannelPasswordSheet(channel: channel, password: $joinPassword)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingDefaultChannelPassword) {
            DefaultChannelPasswordSheet(channel: channel, password: $defaultChannelPassword)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingFullInvitePassword) {
            FullChannelInvitePasswordSheet(channel: channel, password: $fullInviteChannelPassword)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingInfo) {
            ChannelInformationSheet(channel: channel, memberCount: members.count)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingChannelMessage) {
            ChannelMessageSheet(channel: channel)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingEdit) {
            ChannelEditorSheet(mode: .edit(channel))
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingMove) {
            MoveChannelSheet(channel: channel)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingPermissions) {
            PermissionsSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingFiles) {
            FileBrowserSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingPrivilegeKeys) {
            PrivilegeKeysSheet(
                initialTargetType: .channelGroup,
                initialChannelGroupId: model.channelGroups.first?.id,
                initialChannelId: channel.id
            )
            .environmentObject(model)
        }
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete Channel"),
                message: Text(channel.name),
                primaryButton: .destructive(Text("Delete")) {
                    model.deleteChannel(channel, force: false)
                },
                secondaryButton: .cancel()
            )
        }
        .background(
            EmptyView().alert(isPresented: $isConfirmingForcedDelete) {
                Alert(
                    title: Text("Force Delete Channel"),
                    message: Text(channel.name),
                    primaryButton: .destructive(Text("Force Delete")) {
                        model.deleteChannel(channel, force: true)
                    },
                    secondaryButton: .cancel()
                )
            }
        )
    }

    private var channelLimitText: String? {
        if channel.maxClientsUnlimited == true {
            return nil
        }
        if let maxClients = channel.maxClients, maxClients >= 0 {
            return "Limit \(maxClients)"
        }
        if channel.maxFamilyClientsInherited == true || channel.maxFamilyClientsUnlimited == true {
            return nil
        }
        if let maxFamilyClients = channel.maxFamilyClients, maxFamilyClients >= 0 {
            return "Family \(maxFamilyClients)"
        }
        return nil
    }
}

struct MoveChannelSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary
    @State private var selectedParentId: Int?
    @State private var selectedOrderId: Int?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(channel.name)) {
                    Picker("Parent", selection: $selectedParentId) {
                        Text("Root").tag(Optional<Int>.none)
                        ForEach(parentOptions) { parent in
                            Text(parent.name).tag(Optional(parent.id))
                        }
                    }
                    Picker("Position", selection: $selectedOrderId) {
                        Text("First").tag(Optional<Int>.none)
                        ForEach(siblingOptions) { sibling in
                            Text("After \(sibling.name)").tag(Optional(sibling.id))
                        }
                    }
                }
                Section {
                    Button("Move Channel") {
                        model.moveChannel(channel, toParentId: selectedParentId, order: selectedOrderId)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Move Channel")
            .ts3InlineNavigationTitle()
            .onAppear {
                selectedParentId = normalizedParentId(channel.parentId)
                selectedOrderId = normalizedOrderId(channel.order)
            }
            .onChange(of: selectedParentId) { _ in
                selectedOrderId = nil
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var parentOptions: [TS3ChannelSummary] {
        ChannelTreeItem.flatten(channels: model.channels)
            .map(\.channel)
            .filter { candidate in
                candidate.id != channel.id && !isDescendant(candidate, of: channel)
            }
    }

    private var siblingOptions: [TS3ChannelSummary] {
        orderedSiblings(
            model.channels.filter { candidate in
                candidate.id != channel.id
                    && normalizedParentId(candidate.parentId) == selectedParentId
            }
        )
    }

    private var canSubmit: Bool {
        selectedParentId == nil || parentOptions.contains { $0.id == selectedParentId }
    }

    private func isDescendant(_ candidate: TS3ChannelSummary, of channel: TS3ChannelSummary) -> Bool {
        var parent = normalizedParentId(candidate.parentId)
        while let parentId = parent {
            if parentId == channel.id {
                return true
            }
            parent = normalizedParentId(model.channels.first { $0.id == parentId }?.parentId)
        }
        return false
    }

    private func normalizedParentId(_ parentId: Int?) -> Int? {
        guard let parentId, parentId > 0 else { return nil }
        return parentId
    }

    private func normalizedOrderId(_ orderId: Int?) -> Int? {
        guard let orderId, orderId > 0 else { return nil }
        return orderId
    }

    private func orderedSiblings(_ channels: [TS3ChannelSummary]) -> [TS3ChannelSummary] {
        let ids = Set(channels.map(\.id))
        let byPreviousId = Dictionary(grouping: channels) { channel -> Int? in
            guard let previousId = channel.order, ids.contains(previousId) else { return nil }
            return previousId
        }
        var visited: Set<Int> = []
        var result: [TS3ChannelSummary] = []

        func stableSort(_ lhs: TS3ChannelSummary, _ rhs: TS3ChannelSummary) -> Bool {
            if lhs.order != rhs.order {
                return (lhs.order ?? Int.min) < (rhs.order ?? Int.min)
            }
            if lhs.name != rhs.name {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.id < rhs.id
        }

        func appendChain(startingAt channel: TS3ChannelSummary) {
            var current: TS3ChannelSummary? = channel
            while let channel = current, !visited.contains(channel.id) {
                visited.insert(channel.id)
                result.append(channel)
                current = byPreviousId[channel.id]?.sorted(by: stableSort).first {
                    !visited.contains($0.id)
                }
            }
        }

        for channel in (byPreviousId[nil] ?? []).sorted(by: stableSort) {
            appendChain(startingAt: channel)
        }
        for channel in channels.sorted(by: stableSort) where !visited.contains(channel.id) {
            appendChain(startingAt: channel)
        }
        return result
    }
}

struct ChannelInformationSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary
    let memberCount: Int
    @State private var isExportingSnapshot = false
    @State private var snapshotDocument = TS3TextFileDocument()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Snapshot")) {
                    Button("Copy Channel Information") {
                        TS3PlatformSupport.copyToPasteboard(informationSnapshot)
                    }
                    .disabled(informationSnapshot.isEmpty)
                    Button("Export Channel Information") {
                        snapshotDocument = TS3TextFileDocument(data: Data(informationSnapshot.utf8))
                        isExportingSnapshot = true
                    }
                    .disabled(informationSnapshot.isEmpty)
                }

                Section(header: Text(channel.name)) {
                    ServerInfoDetailRow(label: "Channel ID", value: String(channel.id))
                    ServerInfoDetailRow(label: "Parent", value: parentName)
                    ServerInfoDetailRow(label: "Order After", value: orderName)
                    ServerInfoDetailRow(label: "Type", value: channelTypeText)
                    ServerInfoDetailRow(label: "Default", value: yesNo(channel.isDefault))
                    ServerInfoDetailRow(label: "Password", value: channel.isPasswordProtected ? "Protected" : "Not Protected")
                    ServerInfoDetailRow(label: "Subscribed", value: channel.isSubscribed.map(yesNo))
                    ServerInfoDetailRow(label: "Icon ID", value: channel.iconId.map(String.init))
                    ServerInfoDetailRow(label: "Members", value: String(memberCount))
                }

                Section(header: Text("Text")) {
                    ServerInfoDetailRow(label: "Phonetic Name", value: channel.phoneticName)
                    ServerInfoDetailRow(label: "Topic", value: channel.topic)
                    ServerInfoDetailRow(label: "Description", value: channel.description)
                }

                Section(header: Text("Audio")) {
                    ServerInfoDetailRow(label: "Codec", value: TS3ChannelCodec.title(for: channel.codec))
                    ServerInfoDetailRow(label: "Codec Quality", value: TS3ChannelCodecQuality.title(for: channel.codecQuality))
                    ServerInfoDetailRow(label: "Needed Talk Power", value: channel.neededTalkPower.map(String.init))
                    ServerInfoDetailRow(label: "Needed Subscribe Power", value: channel.neededSubscribePower.map(String.init))
                }

                Section(header: Text("Limits")) {
                    ServerInfoDetailRow(label: "Max Clients", value: maxClientsText)
                    ServerInfoDetailRow(label: "Max Family Clients", value: maxFamilyClientsText)
                    ServerInfoDetailRow(label: "Delete Delay", value: channel.deleteDelaySeconds.map { "\($0)s" })
                }
            }
            .fileExporter(
                isPresented: $isExportingSnapshot,
                document: snapshotDocument,
                contentType: .plainText,
                defaultFilename: "ts3-channel-\(channel.id)"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .navigationTitle("Channel Info")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var parentName: String {
        guard let parentId = normalizedId(channel.parentId) else { return "Root" }
        return model.channels.first { $0.id == parentId }?.name ?? "Channel \(parentId)"
    }

    private var orderName: String? {
        guard let orderId = normalizedId(channel.order) else { return "First" }
        return model.channels.first { $0.id == orderId }?.name ?? "Channel \(orderId)"
    }

    private var channelTypeText: String {
        if channel.isPermanent {
            return TS3ChannelType.permanent.title
        }
        if channel.isSemiPermanent == true {
            return TS3ChannelType.semiPermanent.title
        }
        return TS3ChannelType.temporary.title
    }

    private var maxClientsText: String? {
        if channel.maxClientsUnlimited == true { return "Unlimited" }
        return channel.maxClients.map(String.init)
    }

    private var maxFamilyClientsText: String? {
        if channel.maxFamilyClientsInherited == true { return "Inherited" }
        if channel.maxFamilyClientsUnlimited == true { return "Unlimited" }
        return channel.maxFamilyClients.map(String.init)
    }

    private func normalizedId(_ id: Int?) -> Int? {
        guard let id, id > 0 else { return nil }
        return id
    }

    private func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private var informationSnapshot: String {
        let rows: [(String, String?)] = [
            ("Channel ID", String(channel.id)),
            ("Name", channel.name),
            ("Path", model.channelPath(for: channel)),
            ("Parent", parentName),
            ("Order After", orderName),
            ("Type", channelTypeText),
            ("Default", yesNo(channel.isDefault)),
            ("Password", channel.isPasswordProtected ? "Protected" : "Not Protected"),
            ("Subscribed", channel.isSubscribed.map(yesNo)),
            ("Icon ID", channel.iconId.map(String.init)),
            ("Members", String(memberCount)),
            ("Phonetic Name", channel.phoneticName),
            ("Topic", channel.topic),
            ("Description", channel.description),
            ("Codec", TS3ChannelCodec.title(for: channel.codec)),
            ("Codec Quality", TS3ChannelCodecQuality.title(for: channel.codecQuality)),
            ("Needed Talk Power", channel.neededTalkPower.map(String.init)),
            ("Needed Subscribe Power", channel.neededSubscribePower.map(String.init)),
            ("Max Clients", maxClientsText),
            ("Max Family Clients", maxFamilyClientsText),
            ("Delete Delay", channel.deleteDelaySeconds.map { "\($0)s" })
        ]
        return rows
            .compactMap { label, value in
                guard let value, !value.isEmpty else { return nil }
                return "\(label): \(value)"
            }
            .joined(separator: "\n")
    }
}

struct ChannelIconView: View {
    let channel: TS3ChannelSummary

    var body: some View {
        Group {
            if let image = platformImage {
                Image(ts3PlatformImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "seal.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 16, height: 16)
        .accessibilityLabel("Icon \(channel.iconId ?? 0)")
    }

    private var platformImage: TS3PlatformImage? {
        guard let iconURL = channel.iconURL else { return nil }
        return TS3PlatformImage(contentsOfFile: iconURL.path)
    }
}

enum UserActionMode: Identifiable {
    case info
    case privateMessage
    case offlineMessage
    case poke
    case editDescription
    case contactNote
    case complain
    case kickChannel
    case kickServer
    case ban

    var id: String {
        switch self {
        case .info: return "info"
        case .privateMessage: return "privateMessage"
        case .offlineMessage: return "offlineMessage"
        case .poke: return "poke"
        case .editDescription: return "editDescription"
        case .contactNote: return "contactNote"
        case .complain: return "complain"
        case .kickChannel: return "kickChannel"
        case .kickServer: return "kickServer"
        case .ban: return "ban"
        }
    }
}

enum DatabaseClientActionMode: Identifiable {
    case offlineMessage
    case contactNote
    case complain
    case ban

    var id: String {
        switch self {
        case .offlineMessage:
            return "offlineMessage"
        case .contactNote:
            return "contactNote"
        case .complain:
            return "complain"
        case .ban:
            return "ban"
        }
    }
}

struct ChannelMemberRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let member: TS3UserSummary
    @State private var actionMode: UserActionMode?
    @State private var isShowingPlaybackSettings = false
    @State private var isShowingPermissions = false
    @State private var isShowingDatabaseClient = false
    @State private var passwordMoveChannel: TS3ChannelSummary?
    @State private var movePassword = ""

    private var memberClipboardSummary: String {
        var parts = [
            "clientId=\(member.id)",
            "nickname=\(member.nickname)",
            "channelId=\(member.channelId)"
        ]
        if let databaseId = member.databaseId {
            parts.append("databaseId=\(databaseId)")
        }
        if let uniqueIdentifier = member.uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("uid=\(uniqueIdentifier)")
        }
        if let ipAddress = member.ipAddress, !ipAddress.isEmpty {
            parts.append("ip=\(ipAddress)")
        }
        if let country = member.country, !country.isEmpty {
            parts.append("country=\(country)")
        }
        if let platform = member.platform, !platform.isEmpty {
            parts.append("platform=\(platform)")
        }
        if let version = member.version, !version.isEmpty {
            parts.append("version=\(version)")
        }
        return parts.joined(separator: " | ")
    }

    var body: some View {
        HStack(spacing: 10) {
            UserAvatarView(user: member)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(member.nickname)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    UserIconView(user: member)
                }
                HStack(spacing: 8) {
                    if contactStatus == .friend {
                        Text("Friend")
                    }
                    if contactStatus == .blocked {
                        Text("Blocked")
                    }
                    if member.isAway {
                        Text(member.awayMessage?.isEmpty == false ? "Away: \(member.awayMessage!)" : "Away")
                    }
                    if member.isInputMuted {
                        Text("Mic muted")
                    }
                    if member.isOutputMuted {
                        Text("Sound muted")
                    }
                    if isPlaybackMuted {
                        Text("Locally muted")
                    } else if playbackPreference.volume != 1 {
                        Text("Volume \(model.playbackVolumePercentText(for: member))")
                    }
                    if member.isChannelCommander {
                        Text("Commander")
                    }
                    if member.isPrioritySpeaker {
                        Text("Priority")
                    }
                    if member.isTalker {
                        Text("Talker")
                    }
                    if member.isRequestingTalkPower {
                        Text("Wants Talk")
                    }
                    if let talkRequestMessage = member.talkRequestMessage, !talkRequestMessage.isEmpty {
                        Text("Request: \(talkRequestMessage)")
                            .lineLimit(2)
                    }
                    if let power = member.talkPower {
                        Text("Talk \(power)")
                    }
                    if let channelGroupId = member.channelGroupId {
                        Text("Channel: \(TS3GroupSummary.name(for: channelGroupId, in: model.channelGroups))")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                if !member.serverGroups.isEmpty {
                    Text("Server: \(serverGroupNames)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let description = member.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if let note = model.contactNote(for: member) {
                    Text("Note: \(note)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            if member.isCurrentUser {
                Text("You")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            Spacer()
            Menu {
                Button("Client Info") {
                    actionMode = .info
                }
                Button("Copy Client Summary") {
                    TS3PlatformSupport.copyToPasteboard(memberClipboardSummary)
                }
                Button("Copy Nickname") {
                    TS3PlatformSupport.copyToPasteboard(member.nickname)
                }
                Button("Copy Client ID") {
                    TS3PlatformSupport.copyToPasteboard("\(member.id)")
                }
                if let databaseId = member.databaseId {
                    Button("Copy Database ID") {
                        TS3PlatformSupport.copyToPasteboard("\(databaseId)")
                    }
                }
                if let uniqueIdentifier = member.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                    Button("Copy Unique ID") {
                        TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                    }
                }
                if let ipAddress = member.ipAddress, !ipAddress.isEmpty {
                    Button("Copy IP Address") {
                        TS3PlatformSupport.copyToPasteboard(ipAddress)
                    }
                }
                Button("Send Private Message") {
                    actionMode = .privateMessage
                }
                Button("Send Offline Message") {
                    actionMode = .offlineMessage
                }
                Button("Poke") {
                    actionMode = .poke
                }
                if !member.isCurrentUser {
                    Button("Complain") {
                        actionMode = .complain
                    }
                }
                Button("Whisper to User") {
                    model.enableWhisperToClient(member)
                }
                if !member.isCurrentUser {
                    Menu("Local Playback") {
                        Button(isPlaybackMuted ? "Unmute Locally" : "Mute Locally") {
                            model.setPlaybackMuted(!isPlaybackMuted, for: member)
                        }
                        .disabled(contactStatus == .blocked)
                        Button("Adjust Volume") {
                            isShowingPlaybackSettings = true
                        }
                        Button("Reset Volume") {
                            model.updatePlaybackVolume(1, for: member)
                            model.setPlaybackMuted(false, for: member)
                        }
                        .disabled(!playbackPreference.isMuted && playbackPreference.volume == 1)
                    }
                }
                Button("Refresh Details") {
                    model.refreshUserDetails(member)
                }
                Button("View Database Client") {
                    if let record = TS3DatabaseClientSummary(user: member) {
                        model.loadDatabaseClientDetails(record)
                        isShowingDatabaseClient = true
                    }
                }
                .disabled(member.databaseId == nil)
                Button("Download Avatar") {
                    model.refreshUserAvatar(member)
                }
                Button("Edit Description") {
                    actionMode = .editDescription
                }
                Button("Edit Channel Client Permissions") {
                    model.selectChannelClientPermissions(member)
                    isShowingPermissions = member.databaseId != nil
                }
                .disabled(member.databaseId == nil)
                if member.uniqueIdentifier != nil {
                    Menu("Contact") {
                        Button("Mark as Friend") {
                            model.setContactStatus(.friend, for: member)
                        }
                        .disabled(contactStatus == .friend)
                        Button("Block Contact") {
                            model.setContactStatus(.blocked, for: member)
                        }
                        .disabled(contactStatus == .blocked)
                        Button("Set Neutral") {
                            model.setContactStatus(.neutral, for: member)
                        }
                        .disabled(contactStatus == .neutral && model.contactNote(for: member) == nil)
                        Button("Edit Note") {
                            actionMode = .contactNote
                        }
                    }
                }
                if member.isPrioritySpeaker {
                    Button("Remove Priority Speaker") {
                        model.setPrioritySpeaker(false, for: member)
                    }
                } else {
                    Button("Grant Priority Speaker") {
                        model.setPrioritySpeaker(true, for: member)
                    }
                }
                if member.isTalker {
                    Button("Remove Talk Power") {
                        model.setTalker(false, for: member)
                    }
                } else {
                    Button(member.isRequestingTalkPower ? "Grant Talk Power" : "Mark As Talker") {
                        model.setTalker(true, for: member)
                    }
                    if member.isRequestingTalkPower {
                        Button("Deny Talk Request") {
                            model.denyTalkRequest(for: member)
                        }
                    }
                }
                Menu("Move To") {
                    ForEach(model.channels) { channel in
                        Button(channel.name) {
                            if channel.isPasswordProtected {
                                movePassword = ""
                                passwordMoveChannel = channel
                            } else {
                                model.moveUser(member, to: channel)
                            }
                        }
                    }
                }
                if !member.isCurrentUser {
                    Button("Kick From Channel") {
                        actionMode = .kickChannel
                    }
                    Button("Kick From Server") {
                        actionMode = .kickServer
                    }
                    Button("Ban") {
                        actionMode = .ban
                    }
                }
                if !availableServerGroups.isEmpty {
                    Menu("Add Server Group") {
                        ForEach(availableServerGroups) { group in
                            Button(group.name) {
                                model.addServerGroup(group, to: member)
                            }
                        }
                    }
                }
                if !assignedServerGroups.isEmpty {
                    Menu("Remove Server Group") {
                        ForEach(assignedServerGroups) { group in
                            Button(group.name) {
                                model.removeServerGroup(group, from: member)
                            }
                        }
                    }
                }
                if !model.channelGroups.isEmpty, let channel = model.channels.first(where: { $0.id == member.channelId }) {
                    Menu("Set Channel Group") {
                        ForEach(model.channelGroups) { group in
                            Button(group.name) {
                                model.setChannelGroup(group, for: member, in: channel)
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .sheet(item: $actionMode) { mode in
            UserActionSheet(mode: mode, user: member)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingPlaybackSettings) {
            UserPlaybackSheet(user: member)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingPermissions) {
            PermissionsSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingDatabaseClient) {
            ClientDatabaseSheet()
                .environmentObject(model)
        }
        .sheet(item: $passwordMoveChannel) { channel in
            MoveUserPasswordSheet(user: member, channel: channel, password: $movePassword)
                .environmentObject(model)
        }
    }

    private var assignedServerGroups: [TS3GroupSummary] {
        model.serverGroups.filter { member.serverGroups.contains($0.id) }
    }

    private var availableServerGroups: [TS3GroupSummary] {
        model.serverGroups.filter { !member.serverGroups.contains($0.id) }
    }

    private var serverGroupNames: String {
        member.serverGroups
            .map { TS3GroupSummary.name(for: $0, in: model.serverGroups) }
            .joined(separator: ", ")
    }

    private var contactStatus: TS3ContactStatus {
        model.contactStatus(for: member)
    }

    private var playbackPreference: TS3UserPlaybackPreference {
        model.userPlaybackPreference(for: member)
    }

    private var isPlaybackMuted: Bool {
        model.isPlaybackMuted(for: member)
    }
}

struct UserActionSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let mode: UserActionMode
    let user: TS3UserSummary
    @State private var subject = ""
    @State private var text = ""
    @State private var banDuration: TS3BanDuration = .permanent
    @State private var customBanMinutes = "60"
    @State private var isExportingInfo = false
    @State private var infoExportDocument = TS3TextFileDocument()

    var title: String {
        switch mode {
        case .info: return "Client Info"
        case .privateMessage: return "Private Message"
        case .offlineMessage: return "Offline Message"
        case .poke: return "Poke"
        case .editDescription: return "Edit Description"
        case .contactNote: return "Contact Note"
        case .complain: return "Complain"
        case .kickChannel: return "Kick From Channel"
        case .kickServer: return "Kick From Server"
        case .ban: return "Ban User"
        }
    }

    var fieldTitle: String {
        switch mode {
        case .info: return "Details"
        case .privateMessage: return "Message"
        case .offlineMessage: return "Message"
        case .poke: return "Poke Message"
        case .editDescription: return "Description"
        case .contactNote: return "Note"
        case .complain: return "Complaint"
        case .kickChannel, .kickServer, .ban: return "Reason"
        }
    }

    var actionTitle: String {
        switch mode {
        case .info: return "Refresh"
        case .privateMessage: return "Send"
        case .offlineMessage: return "Send"
        case .poke: return "Poke"
        case .editDescription: return "Save"
        case .contactNote: return "Save"
        case .complain: return "Submit Complaint"
        case .kickChannel, .kickServer: return "Kick"
        case .ban: return "Ban"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                if mode == .info {
                    Section(header: Text("Snapshot")) {
                        Button("Copy Client Information") {
                            TS3PlatformSupport.copyToPasteboard(infoSnapshot)
                        }
                        .disabled(infoSnapshot.isEmpty)
                        Button("Export Client Information") {
                            infoExportDocument = TS3TextFileDocument(data: Data(infoSnapshot.utf8))
                            isExportingInfo = true
                        }
                        .disabled(infoSnapshot.isEmpty)
                    }

                    UserInfoRows(user: currentUser)
                } else {
                    Section(header: Text(user.nickname)) {
                        if mode == .offlineMessage {
                            TextField("Subject", text: $subject)
                                .ts3PlainTextField()
                        }
                        TextField(fieldTitle, text: $text)
                            .ts3PlainTextField()
                    }
                    if mode == .ban {
                        Section(header: Text("Duration")) {
                            Picker("Duration", selection: $banDuration) {
                                ForEach(TS3BanDuration.allCases) { duration in
                                    Text(duration.title).tag(duration)
                                }
                            }
                            if banDuration == .custom {
                                TextField("Minutes", text: $customBanMinutes)
                                    .ts3PlainTextField()
                            }
                        }
                    }
                    if mode != .info {
                        Section {
                            Button(actionTitle) {
                                switch mode {
                                case .info:
                                    break
                                case .privateMessage:
                                    model.sendPrivateMessage(text, to: user)
                                case .offlineMessage:
                                    model.sendOfflineMessage(to: user, subject: subject, message: text)
                                case .poke:
                                    model.pokeUser(user, message: text)
                                case .editDescription:
                                    model.editUserDescription(user, description: text)
                                case .contactNote:
                                    model.setContactNote(text, for: user)
                                case .complain:
                                    model.complainAboutUser(user, message: text)
                                case .kickChannel:
                                    model.kickUserFromChannel(user, message: text.isEmpty ? nil : text)
                                case .kickServer:
                                    model.kickUserFromServer(user, message: text.isEmpty ? nil : text)
                                case .ban:
                                    model.banUser(
                                        user,
                                        durationSeconds: banDuration.seconds(customMinutes: customBanMinutes),
                                        message: text.isEmpty ? nil : text
                                    )
                                }
                                presentationMode.wrappedValue.dismiss()
                            }
                            .disabled(isActionDisabled)
                        }
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingInfo,
                document: infoExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-client-\(currentUser.id)"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .navigationTitle(title)
            .ts3InlineNavigationTitle()
            .onAppear {
                if mode == .editDescription {
                    text = user.description ?? ""
                }
                if mode == .contactNote {
                    text = model.contactNote(for: user) ?? ""
                }
                if mode == .info {
                    model.refreshUserDetails(user)
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var isActionDisabled: Bool {
        let textIsEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch mode {
        case .info:
            return true
        case .privateMessage, .complain:
            return textIsEmpty
        case .poke:
            return false
        case .offlineMessage:
            return textIsEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .editDescription, .contactNote, .kickChannel, .kickServer:
            return false
        case .ban:
            return banDuration == .custom && TS3BanDuration.customSeconds(from: customBanMinutes) == nil
        }
    }

    private var infoSnapshot: String {
        UserInfoRows.snapshot(for: currentUser, model: model)
    }

    private var currentUser: TS3UserSummary {
        model.clients.first(where: { $0.id == user.id }) ?? user
    }
}

struct UserInfoRows: View {
    @EnvironmentObject private var model: TS3AppModel
    let user: TS3UserSummary

    var body: some View {
        Section(header: Text(user.nickname)) {
            ServerInfoDetailRow(label: "Client ID", value: String(user.id))
            ServerInfoDetailRow(label: "Database ID", value: user.databaseId.map(String.init))
            ServerInfoDetailRow(label: "Unique ID", value: user.uniqueIdentifier, monospaced: true)
            ServerInfoDetailRow(label: "Icon ID", value: user.iconId.map(String.init))
            ServerInfoDetailRow(label: "Avatar Hash", value: user.avatarHash, monospaced: true)
            ServerInfoDetailRow(label: "Avatar Path", value: user.avatarURL?.path, monospaced: true)
            ServerInfoDetailRow(label: "Channel", value: String(user.channelId))
            ServerInfoDetailRow(label: "Country", value: user.country)
            ServerInfoDetailRow(label: "IP Address", value: user.ipAddress)
        }

        Section(header: Text("Contact")) {
            ServerInfoDetailRow(label: "Status", value: model.contactStatus(for: user).title)
            ServerInfoDetailRow(label: "Note", value: model.contactNote(for: user))
        }

        Section(header: Text("Local Playback")) {
            ServerInfoDetailRow(label: "Muted", value: model.isPlaybackMuted(for: user) ? "Yes" : "No")
            ServerInfoDetailRow(label: "Volume", value: model.playbackVolumePercentText(for: user))
        }

        Section(header: Text("Application")) {
            ServerInfoDetailRow(label: "Platform", value: user.platform)
            ServerInfoDetailRow(label: "Version", value: user.version)
        }

        Section(header: Text("Status")) {
            ServerInfoDetailRow(label: "Channel Commander", value: user.isChannelCommander ? "Yes" : "No")
            ServerInfoDetailRow(label: "Priority Speaker", value: user.isPrioritySpeaker ? "Yes" : "No")
            ServerInfoDetailRow(label: "Talker", value: user.isTalker ? "Yes" : "No")
            ServerInfoDetailRow(label: "Requests Talk Power", value: user.isRequestingTalkPower ? "Yes" : "No")
            ServerInfoDetailRow(label: "Talk Request", value: user.talkRequestMessage?.isEmpty == false ? user.talkRequestMessage : nil)
            ServerInfoDetailRow(label: "Talk Power", value: user.talkPower.map(String.init))
        }

        Section(header: Text("Activity")) {
            ServerInfoDetailRow(label: "Connected", value: durationText(user.connectedSeconds))
            ServerInfoDetailRow(label: "Idle", value: durationText(user.idleTimeSeconds))
            ServerInfoDetailRow(label: "Total Connections", value: user.totalConnections.map(String.init))
            ServerInfoDetailRow(label: "Created", value: dateText(user.createdAt))
            ServerInfoDetailRow(label: "Last Connected", value: dateText(user.lastConnectedAt))
        }

        Section(header: Text("Status")) {
            ServerInfoDetailRow(label: "Away", value: user.isAway ? (user.awayMessage?.isEmpty == false ? user.awayMessage : "Yes") : "No")
            ServerInfoDetailRow(label: "Input Muted", value: user.isInputMuted ? "Yes" : "No")
            ServerInfoDetailRow(label: "Output Muted", value: user.isOutputMuted ? "Yes" : "No")
        }
    }

    private func dateText(_ date: Date?) -> String? {
        guard let date else { return nil }
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }

    private func durationText(_ seconds: Int?) -> String? {
        guard let seconds else { return nil }
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m \(seconds % 60)s" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h \(minutes % 60)m" }
        let days = hours / 24
        return "\(days)d \(hours % 24)h"
    }

    static func snapshot(for user: TS3UserSummary, model: TS3AppModel) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        func dateText(_ date: Date?) -> String? {
            guard let date else { return nil }
            return formatter.string(from: date)
        }

        func durationText(_ seconds: Int?) -> String? {
            guard let seconds else { return nil }
            if seconds < 60 { return "\(seconds)s" }
            let minutes = seconds / 60
            if minutes < 60 { return "\(minutes)m \(seconds % 60)s" }
            let hours = minutes / 60
            if hours < 24 { return "\(hours)h \(minutes % 60)m" }
            let days = hours / 24
            return "\(days)d \(hours % 24)h"
        }

        let rows: [(String, String?)] = [
            ("Nickname", user.nickname),
            ("Client ID", String(user.id)),
            ("Database ID", user.databaseId.map(String.init)),
            ("Unique ID", user.uniqueIdentifier),
            ("Icon ID", user.iconId.map(String.init)),
            ("Avatar Hash", user.avatarHash),
            ("Avatar Path", user.avatarURL?.path),
            ("Channel", String(user.channelId)),
            ("Country", user.country),
            ("IP Address", user.ipAddress),
            ("Contact Status", model.contactStatus(for: user).title),
            ("Note", model.contactNote(for: user)),
            ("Locally Muted", model.isPlaybackMuted(for: user) ? "Yes" : "No"),
            ("Playback Volume", model.playbackVolumePercentText(for: user)),
            ("Platform", user.platform),
            ("Version", user.version),
            ("Channel Commander", user.isChannelCommander ? "Yes" : "No"),
            ("Priority Speaker", user.isPrioritySpeaker ? "Yes" : "No"),
            ("Talker", user.isTalker ? "Yes" : "No"),
            ("Requests Talk Power", user.isRequestingTalkPower ? "Yes" : "No"),
            ("Talk Request", user.talkRequestMessage?.isEmpty == false ? user.talkRequestMessage : nil),
            ("Talk Power", user.talkPower.map(String.init)),
            ("Connected", durationText(user.connectedSeconds)),
            ("Idle", durationText(user.idleTimeSeconds)),
            ("Total Connections", user.totalConnections.map(String.init)),
            ("Created", dateText(user.createdAt)),
            ("Last Connected", dateText(user.lastConnectedAt)),
            ("Away", user.isAway ? (user.awayMessage?.isEmpty == false ? user.awayMessage : "Yes") : "No"),
            ("Input Muted", user.isInputMuted ? "Yes" : "No"),
            ("Output Muted", user.isOutputMuted ? "Yes" : "No")
        ]

        return rows
            .compactMap { label, value in
                guard let value, !value.isEmpty else { return nil }
                return "\(label): \(value)"
            }
            .joined(separator: "\n")
    }
}

struct UserIconView: View {
    let user: TS3UserSummary

    @ViewBuilder
    var body: some View {
        if let image = platformImage {
            Image(ts3PlatformImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .accessibilityLabel("Client icon")
        } else if user.iconId != nil && user.iconId != 0 {
            Image(systemName: "seal")
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondary)
                .frame(width: 14, height: 14)
                .accessibilityLabel("Client icon")
        }
    }

    private var platformImage: TS3PlatformImage? {
        guard let iconURL = user.iconURL else { return nil }
        return TS3PlatformImage(contentsOfFile: iconURL.path)
    }
}

struct ContactsSheet: View {
    private enum ContactSortMode: String, CaseIterable, Identifiable {
        case nickname
        case status
        case updated
        case note

        var id: String { rawValue }

        var title: String {
            switch self {
            case .nickname: return "Nickname"
            case .status: return "Status"
            case .updated: return "Updated"
            case .note: return "Note"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var searchText = ""
    @State private var sortMode: ContactSortMode = .nickname
    @State private var sortAscending = true
    @State private var presetName = ""
    @State private var isShowingNewContact = false
    @State private var isExportingContacts = false
    @State private var isImportingContacts = false
    @State private var isExportingPresets = false
    @State private var isImportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var contactsDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()

    private var notedContacts: [TS3ContactEntry] {
        model.contacts
            .filter { !$0.note.isEmpty && $0.status == .neutral }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var filteredFriends: [TS3ContactEntry] {
        filterContacts(model.friendContacts)
    }

    private var filteredBlocked: [TS3ContactEntry] {
        filterContacts(model.blockedContacts)
    }

    private var filteredNotes: [TS3ContactEntry] {
        filterContacts(notedContacts)
    }

    private var visibleContacts: [TS3ContactEntry] {
        var seen = Set<String>()
        return (filteredFriends + filteredBlocked + filteredNotes).filter { contact in
            seen.insert(contact.uniqueIdentifier).inserted
        }
    }

    private var canMarkVisibleFriends: Bool {
        visibleContacts.contains { $0.status != .friend }
    }

    private var canBlockVisibleContacts: Bool {
        visibleContacts.contains { $0.status != .blocked }
    }

    private var canSetVisibleNeutral: Bool {
        visibleContacts.contains { $0.status != .neutral }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add")) {
                    Button("New Contact") {
                        isShowingNewContact = true
                    }
                }

                Section(header: Text("Filters")) {
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(ContactSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Search contacts", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveContactFilterPreset(
                                name: presetName,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.contactFilterPresets.isEmpty {
                            Text("No saved contact filter presets")
                        } else {
                            ForEach(model.contactFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteContactFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.contactFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.contactFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            sortMode = .nickname
                            sortAscending = true
                            searchText = ""
                        }
                    }
                }

                contactSection(title: "Friends", contacts: filteredFriends)
                contactSection(title: "Blocked", contacts: filteredBlocked)
                contactSection(title: "Notes", contacts: filteredNotes)
            }
            .navigationTitle("Contacts")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Menu {
                        Button("Copy Contact Snapshot") {
                            TS3PlatformSupport.copyToPasteboard(contactSnapshot)
                        }
                        .disabled(model.contacts.isEmpty)
                        Button("Export Contact Snapshot") {
                            contactsDocument = TS3TextFileDocument(data: Data(contactSnapshot.utf8))
                            isExportingContacts = true
                        }
                        .disabled(model.contacts.isEmpty)
                        Button("Export Contacts Backup") {
                            exportContacts()
                        }
                        .disabled(model.contacts.isEmpty)
                        Button("Import Contacts Backup") {
                            isImportingContacts = true
                        }
                        Divider()
                        Button("Mark Visible Friends") {
                            model.updateContacts(visibleContacts, status: .friend)
                        }
                        .disabled(!canMarkVisibleFriends)
                        Button("Block Visible Contacts") {
                            model.updateContacts(visibleContacts, status: .blocked)
                        }
                        .disabled(!canBlockVisibleContacts)
                        Button("Set Visible Neutral") {
                            model.updateContacts(visibleContacts, status: .neutral)
                        }
                        .disabled(!canSetVisibleNeutral)
                    } label: {
                        Label("Contacts", systemImage: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingContacts,
                document: contactsDocument,
                contentType: .plainText,
                defaultFilename: "ts3-contacts"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingContacts,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importContacts(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-contact-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Contact Filter Presets?"),
                    message: Text("This removes \(model.contactFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllContactFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $isShowingNewContact) {
                ContactEditorSheet(
                    uniqueIdentifier: "",
                    nickname: "",
                    initialStatus: .neutral,
                    initialNote: "",
                    submit: { uniqueIdentifier, nickname, status, note in
                        model.addContact(
                            uniqueIdentifier: uniqueIdentifier,
                            nickname: nickname,
                            status: status,
                            note: note
                        )
                    }
                )
                .environmentObject(model)
            }
        }
    }

    private func filterContacts(_ contacts: [TS3ContactEntry]) -> [TS3ContactEntry] {
        let entries = contacts.filter { contact in
            !isSearching
                || containsSearch(contact.nickname)
                || containsSearch(contact.uniqueIdentifier)
                || containsSearch(contact.note)
                || containsSearch(contact.status.title)
        }
        return sortedContacts(entries)
    }

    private func containsSearch(_ value: String) -> Bool {
        value.lowercased().contains(normalizedSearchText)
    }

    private var hasLocalFilters: Bool {
        isSearching || sortMode != .nickname || !sortAscending
    }

    private func sortedContacts(_ contacts: [TS3ContactEntry]) -> [TS3ContactEntry] {
        contacts.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .nickname:
                comparison = lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname)
            case .status:
                comparison = lhs.status.title.localizedCaseInsensitiveCompare(rhs.status.title)
            case .updated:
                comparison = lhs.updatedAt.compare(rhs.updatedAt)
            case .note:
                comparison = lhs.note.localizedCaseInsensitiveCompare(rhs.note)
            }

            if comparison == .orderedSame {
                return lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname) == .orderedAscending
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func exportContacts() {
        do {
            contactsDocument = TS3TextFileDocument(data: try model.contactsExportData())
            isExportingContacts = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importContacts(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importContacts(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyPreset(_ preset: TS3ContactFilterPreset) {
        sortMode = ContactSortMode(rawValue: preset.sortMode) ?? .nickname
        sortAscending = preset.sortAscending
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3ContactFilterPreset) -> String {
        var parts = [
            "Sort \((ContactSortMode(rawValue: preset.sortMode) ?? .nickname).title)"
        ]
        if !preset.sortAscending {
            parts.append("Descending")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.contactFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importContactFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private var contactSnapshot: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        func dateText(_ date: Date) -> String {
            formatter.string(from: date)
        }

        return model.contacts
            .sorted { lhs, rhs in
                if lhs.status != rhs.status {
                    return lhs.status.title < rhs.status.title
                }
                return lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname) == .orderedAscending
            }
            .map { contact in
                [
                    "Nickname: \(contact.nickname)",
                    "Unique ID: \(contact.uniqueIdentifier)",
                    "Status: \(contact.status.title)",
                    "Note: \(contact.note.isEmpty ? "-" : contact.note)",
                    "Updated: \(dateText(contact.updatedAt))"
                ]
                .joined(separator: "\n")
            }
            .joined(separator: "\n\n")
    }

    @ViewBuilder
    private func contactSection(title: String, contacts: [TS3ContactEntry]) -> some View {
        Section(header: Text(title)) {
            if contacts.isEmpty {
                Text(isSearching ? "No matching contacts" : "No contacts")
                    .foregroundColor(.secondary)
            } else {
                ForEach(contacts) { contact in
                    ContactRow(contact: contact)
                        .environmentObject(model)
                }
            }
        }
    }
}

struct ContactRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let contact: TS3ContactEntry
    @State private var isEditing = false
    @State private var onlineActionMode: UserActionMode?

    private var onlineUser: TS3UserSummary? {
        model.onlineUser(for: contact)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(contact.nickname)
                        .font(.subheadline.weight(.semibold))
                    Text(contact.status.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(contact.uniqueIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if !contact.note.isEmpty {
                    Text(contact.note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                if let onlineUser {
                    Text("Online as \(onlineUser.nickname)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                }
            }
            Spacer()
            Menu {
                if onlineUser != nil {
                    Button("Send Private Message") {
                        onlineActionMode = .privateMessage
                    }
                    Button("Poke") {
                        onlineActionMode = .poke
                    }
                    Button("Client Info") {
                        onlineActionMode = .info
                    }
                    Divider()
                }
                Button("Edit Contact") {
                    isEditing = true
                }
                Button("Copy Nickname") {
                    TS3PlatformSupport.copyToPasteboard(contact.nickname)
                }
                Button("Copy Unique ID") {
                    TS3PlatformSupport.copyToPasteboard(contact.uniqueIdentifier)
                }
                ForEach(TS3ContactStatus.allCases) { status in
                    Button("Set \(status.title)") {
                        model.updateContact(contact, status: status, note: contact.note)
                    }
                    .disabled(contact.status == status)
                }
                Button("Delete Contact") {
                    model.deleteContact(contact)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
        }
        .sheet(isPresented: $isEditing) {
            ContactEditorSheet(
                uniqueIdentifier: contact.uniqueIdentifier,
                nickname: contact.nickname,
                initialStatus: contact.status,
                initialNote: contact.note,
                submit: { uniqueIdentifier, nickname, status, note in
                    model.addContact(
                        uniqueIdentifier: uniqueIdentifier,
                        nickname: nickname.isEmpty ? contact.nickname : nickname,
                        status: status,
                        note: note
                    )
                }
            )
        }
        .sheet(item: $onlineActionMode) { mode in
            if let onlineUser {
                UserActionSheet(mode: mode, user: onlineUser)
                    .environmentObject(model)
            }
        }
        .contextMenu {
            if onlineUser != nil {
                Button("Send Private Message") {
                    onlineActionMode = .privateMessage
                }
                Button("Poke") {
                    onlineActionMode = .poke
                }
            }
            Button("Copy Nickname") {
                TS3PlatformSupport.copyToPasteboard(contact.nickname)
            }
            Button("Copy Unique ID") {
                TS3PlatformSupport.copyToPasteboard(contact.uniqueIdentifier)
            }
            Button("Edit Contact") {
                isEditing = true
            }
        }
    }
}

struct ContactEditorSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let uniqueIdentifier: String
    let nickname: String
    let submit: (String, String, TS3ContactStatus, String) -> Void
    @State private var status: TS3ContactStatus
    @State private var note: String
    @State private var identifier: String
    @State private var displayName: String

    init(
        uniqueIdentifier: String,
        nickname: String,
        initialStatus: TS3ContactStatus,
        initialNote: String,
        submit: @escaping (String, String, TS3ContactStatus, String) -> Void
    ) {
        self.uniqueIdentifier = uniqueIdentifier
        self.nickname = nickname
        self.submit = submit
        _status = State(initialValue: initialStatus)
        _note = State(initialValue: initialNote)
        _identifier = State(initialValue: uniqueIdentifier)
        _displayName = State(initialValue: nickname)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(displayName.isEmpty ? "Contact" : displayName)) {
                    TextField("Unique ID", text: $identifier)
                        .ts3PlainTextField()
                    TextField("Nickname", text: $displayName)
                        .ts3PlainTextField()
                    Picker("Status", selection: $status) {
                        ForEach(TS3ContactStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                    TextField("Note", text: $note)
                        .ts3PlainTextField()
                }
                Section {
                    Button("Save") {
                        submit(identifier, displayName, status, note)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(uniqueIdentifier.isEmpty ? "New Contact" : "Edit Contact")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct UserPlaybackSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let user: TS3UserSummary

    private var mutedBinding: Binding<Bool> {
        Binding(
            get: { model.isPlaybackMuted(for: user) },
            set: { model.setPlaybackMuted($0, for: user) }
        )
    }

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { model.userPlaybackPreference(for: user).volume },
            set: { model.updatePlaybackVolume($0, for: user) }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(user.nickname)) {
                    Toggle("Mute Locally", isOn: mutedBinding)
                        .disabled(model.contactStatus(for: user) == .blocked)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Playback Volume")
                            Spacer()
                            Text(model.playbackVolumePercentText(for: user))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: volumeBinding, in: 0...4, step: 0.05)
                        HStack {
                            Button("0%") {
                                model.updatePlaybackVolume(0, for: user)
                            }
                            Spacer()
                            Button("100%") {
                                model.updatePlaybackVolume(1, for: user)
                            }
                            Spacer()
                            Button("400%") {
                                model.updatePlaybackVolume(4, for: user)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Local Playback")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct UserAvatarView: View {
    let user: TS3UserSummary

    var body: some View {
        Group {
            if let image = platformImage {
                Image(ts3PlatformImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Image(systemName: user.isCurrentUser ? "person.crop.circle.fill" : "person.fill")
                    .font(.title3)
                    .foregroundColor(user.isCurrentUser ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
            }
        }
        .frame(width: 28, height: 28)
    }

    private var platformImage: TS3PlatformImage? {
        guard let avatarURL = user.avatarURL else { return nil }
        return TS3PlatformImage(contentsOfFile: avatarURL.path)
    }
}

#if canImport(UIKit)
typealias TS3PlatformImage = UIImage
#else
typealias TS3PlatformImage = NSImage
#endif

private extension Image {
    init(ts3PlatformImage image: TS3PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: image)
        #else
        self.init(nsImage: image)
        #endif
    }
}

enum TS3BanDuration: String, CaseIterable, Identifiable {
    case tenMinutes
    case oneHour
    case oneDay
    case oneWeek
    case permanent
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tenMinutes: return "10 Minutes"
        case .oneHour: return "1 Hour"
        case .oneDay: return "1 Day"
        case .oneWeek: return "1 Week"
        case .permanent: return "Permanent"
        case .custom: return "Custom"
        }
    }

    func seconds(customMinutes: String) -> Int? {
        switch self {
        case .tenMinutes: return 10 * 60
        case .oneHour: return 60 * 60
        case .oneDay: return 24 * 60 * 60
        case .oneWeek: return 7 * 24 * 60 * 60
        case .permanent: return nil
        case .custom: return Self.customSeconds(from: customMinutes)
        }
    }

    static func customSeconds(from minutesText: String) -> Int? {
        let trimmed = minutesText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let minutes = Int(trimmed), minutes > 0 else {
            return nil
        }
        return minutes * 60
    }
}

struct ChatSheet: View {
    private enum ChatSenderFilter: String, CaseIterable, Identifiable {
        case all
        case own
        case others

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Senders"
            case .own: return "My Messages"
            case .others: return "Other Users"
            }
        }

        func includes(_ message: TS3ChatMessageSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .own:
                return message.isOwnMessage
            case .others:
                return !message.isOwnMessage
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var message = ""
    @State private var target: TS3TextMessageTargetMode = .channel
    @State private var selectedPrivateClientId = 0
    @State private var filter: ChatMessageFilter = .all
    @State private var senderFilter: ChatSenderFilter = .all
    @State private var newestFirst = false
    @State private var searchText = ""
    @State private var presetName = ""
    @State private var isShowingOfflineMessages = false
    @State private var isConfirmingClearHistory = false
    @State private var isConfirmingClearVisibleHistory = false
    @State private var isExportingTranscript = false
    @State private var isImportingChatHistory = false
    @State private var isExportingChatHistory = false
    @State private var isImportingPresets = false
    @State private var isExportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var transcriptDocument = TS3TextFileDocument()
    @State private var chatHistoryDocument = TS3BookmarkFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Picker("Target", selection: $target) {
                        Text("Channel").tag(TS3TextMessageTargetMode.channel)
                        Text("Server").tag(TS3TextMessageTargetMode.server)
                        Text("Private").tag(TS3TextMessageTargetMode.client)
                    }
                    .pickerStyle(.segmented)

                    if target == .client {
                        if privateMessageTargets.isEmpty {
                            Text("No other users")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Picker("User", selection: $selectedPrivateClientId) {
                                ForEach(privateMessageTargets) { user in
                                    Text(user.nickname).tag(user.id)
                                }
                            }
                        }
                    }

                    Picker("Filter", selection: $filter) {
                        ForEach(ChatMessageFilter.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Sender", selection: $senderFilter) {
                        ForEach(ChatSenderFilter.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }

                    Toggle("Newest First", isOn: $newestFirst)

                    TextField("Search chat", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveChatFilterPreset(
                                name: presetName,
                                messageFilter: filter.rawValue,
                                senderFilter: senderFilter.rawValue,
                                newestFirst: newestFirst,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.chatFilterPresets.isEmpty {
                            Text("No saved chat filter presets")
                        } else {
                            ForEach(model.chatFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteChatFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.chatFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.chatFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    if hasChatFilters {
                        Button("Clear Chat Filters") {
                            filter = .all
                            senderFilter = .all
                            newestFirst = false
                            searchText = ""
                        }
                    }
                }
                .padding()

                List {
                    if filteredMessages.isEmpty {
                        Text(emptyMessageText)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredMessages) { item in
                            ChatMessageRow(item: item, replyUser: replyUser(for: item))
                                .environmentObject(model)
                                .listRowBackground(item.isOwnMessage ? Color.accentColor.opacity(0.08) : Color.clear)
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField("Message", text: $message)
                        .textFieldStyle(.roundedBorder)
                    Button("Send") {
                        switch target {
                        case .server:
                            model.sendServerMessage(message)
                        case .channel:
                            model.sendChannelMessage(message)
                        case .client:
                            if let user = selectedPrivateClient {
                                model.sendPrivateMessage(message, to: user)
                            }
                        }
                        message = ""
                    }
                    .buttonStyle(TS3BorderedButtonStyle(isProminent: true))
                    .disabled(!canSendMessage)
                }
                .padding()
            }
            .navigationTitle("Chat")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItemGroup(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Inbox") {
                        model.refreshOfflineMessages()
                        isShowingOfflineMessages = true
                    }
                    .disabled(model.state != .connected)
                    Button("Clear") {
                        isConfirmingClearHistory = true
                    }
                    .disabled(model.chatMessages.isEmpty)
                    Menu {
                        Button("Export Transcript") {
                            transcriptDocument = TS3TextFileDocument(data: model.chatTranscriptData(messages: filteredMessages))
                            isExportingTranscript = true
                        }
                        .disabled(filteredMessages.isEmpty)
                        Button("Export History Backup") {
                            exportChatHistory()
                        }
                        .disabled(model.chatMessages.isEmpty)
                        Button("Import History Backup") {
                            isImportingChatHistory = true
                        }
                        Divider()
                        Button("Clear Visible History") {
                            isConfirmingClearVisibleHistory = true
                        }
                        .disabled(filteredMessages.isEmpty)
                    } label: {
                        Label("History", systemImage: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingOfflineMessages) {
                OfflineMessagesSheet()
                    .environmentObject(model)
            }
            .fileExporter(
                isPresented: $isExportingTranscript,
                document: transcriptDocument,
                contentType: .plainText,
                defaultFilename: "ts3-chat-transcript"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-chat-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingChatHistory,
                document: chatHistoryDocument,
                contentType: .json,
                defaultFilename: "ts3-chat-history"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingChatHistory,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importChatHistory(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .onAppear {
                model.beginViewingChat()
                selectDefaultPrivateClientIfNeeded()
            }
            .onChange(of: target) { _ in
                selectDefaultPrivateClientIfNeeded()
            }
            .onChange(of: model.clients.map(\.id)) { _ in
                selectDefaultPrivateClientIfNeeded()
            }
            .onDisappear {
                model.endViewingChat()
            }
            .alert(isPresented: $isConfirmingClearHistory) {
                Alert(
                    title: Text("Clear chat history?"),
                    message: Text("This removes locally saved chat messages from this device."),
                    primaryButton: .destructive(Text("Clear History")) {
                        model.clearChatHistory()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingClearVisibleHistory) {
                Alert(
                    title: Text("Clear visible chat history?"),
                    message: Text("This removes \(filteredMessages.count) locally saved messages matching the current filters."),
                    primaryButton: .destructive(Text("Clear Visible")) {
                        model.clearChatMessages(filteredMessages)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Chat Filter Presets?"),
                    message: Text("This removes \(model.chatFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllChatFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var privateMessageTargets: [TS3UserSummary] {
        model.clients.filter { !$0.isCurrentUser }
    }

    private var selectedPrivateClient: TS3UserSummary? {
        privateMessageTargets.first { $0.id == selectedPrivateClientId }
    }

    private var canSendMessage: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && model.state == .connected
            && (target != .client || selectedPrivateClient != nil)
    }

    private var filteredMessages: [TS3ChatMessageSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let messages = model.chatMessages.filter { item in
            filter.includes(item.targetMode)
                && senderFilter.includes(item)
                && (query.isEmpty
                    || item.senderName.localizedCaseInsensitiveContains(query)
                    || item.message.localizedCaseInsensitiveContains(query))
        }
        if newestFirst {
            return messages.sorted { $0.timestamp > $1.timestamp }
        }
        return messages.sorted { $0.timestamp < $1.timestamp }
    }

    private var emptyMessageText: String {
        model.chatMessages.isEmpty ? "No chat messages" : "No matching messages"
    }

    private var hasChatFilters: Bool {
        filter != .all
            || senderFilter != .all
            || newestFirst
            || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func replyUser(for item: TS3ChatMessageSummary) -> TS3UserSummary? {
        guard item.targetMode == .client,
              !item.isOwnMessage,
              let senderId = item.senderId else {
            return nil
        }
        return model.clients.first { $0.id == senderId }
    }

    private func selectDefaultPrivateClientIfNeeded() {
        guard target == .client else { return }
        if !privateMessageTargets.contains(where: { $0.id == selectedPrivateClientId }) {
            selectedPrivateClientId = privateMessageTargets.first?.id ?? 0
        }
    }

    private func exportChatHistory() {
        do {
            chatHistoryDocument = TS3BookmarkFileDocument(data: try model.chatHistoryBackupData())
            isExportingChatHistory = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importChatHistory(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importChatHistoryBackup(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyPreset(_ preset: TS3ChatFilterPreset) {
        filter = ChatMessageFilter(rawValue: preset.messageFilter) ?? .all
        senderFilter = ChatSenderFilter(rawValue: preset.senderFilter) ?? .all
        newestFirst = preset.newestFirst
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3ChatFilterPreset) -> String {
        var parts = [
            (ChatMessageFilter(rawValue: preset.messageFilter) ?? .all).title,
            (ChatSenderFilter(rawValue: preset.senderFilter) ?? .all).title,
            preset.newestFirst ? "Newest" : "Oldest"
        ]
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.chatFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importChatFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ChatMessageRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let item: TS3ChatMessageSummary
    let replyUser: TS3UserSummary?
    @State private var replyTarget: TS3UserSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.senderName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(Self.dateText(item.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(targetModeText(item.targetMode))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(item.message)
                .font(.body)
            if let replyUser {
                Button("Reply") {
                    replyTarget = replyUser
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .accessibilityLabel("Reply to \(replyUser.nickname)")
            }
        }
        .contextMenu {
            Button("Copy Message") {
                TS3PlatformSupport.copyToPasteboard(item.message)
            }
            Button("Copy Sender") {
                TS3PlatformSupport.copyToPasteboard(item.senderName)
            }
            Button("Copy Entry") {
                TS3PlatformSupport.copyToPasteboard(clipboardText)
            }
        }
        .sheet(item: $replyTarget) { user in
            ChatPrivateReplySheet(user: user)
                .environmentObject(model)
        }
    }

    private func targetModeText(_ mode: TS3TextMessageTargetMode) -> String {
        switch mode {
        case .server:
            return "Server"
        case .channel:
            return "Channel"
        case .client:
            return "Private"
        }
    }

    private var clipboardText: String {
        "\(Self.dateText(item.timestamp)) [\(targetModeText(item.targetMode))] \(item.senderName): \(item.message)"
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatPrivateReplySheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let user: TS3UserSummary
    @State private var message = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(user.nickname)) {
                    TextField("Message", text: $message)
                        .ts3PlainTextField()
                }
                Section {
                    Button("Send") {
                        model.sendPrivateMessage(message, to: user)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Private Reply")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ChatButtonLabel: View {
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "message")
            Text("Chat")
            if unreadCount > 0 {
                CountBadge(count: unreadCount, label: "unread messages")
            }
        }
    }
}

struct EventsButtonLabel: View {
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bell")
            Text("Events")
            if unreadCount > 0 {
                CountBadge(count: unreadCount, label: "unread events")
            }
        }
    }
}

struct WhisperButtonLabel: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isActive ? "wave.3.right.circle.fill" : "wave.3.right")
            Text(isActive ? "Whispering" : "Whisper")
        }
    }
}

struct CountBadge: View {
    let count: Int
    let label: String

    var body: some View {
        Text(countText)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.red)
            .clipShape(Capsule())
            .accessibilityLabel("\(count) \(label)")
    }

    private var countText: String {
        count > 99 ? "99+" : String(count)
    }
}

enum ChatMessageFilter: String, CaseIterable, Identifiable {
    case all
    case channel
    case server
    case privateMessage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .channel:
            return "Channel"
        case .server:
            return "Server"
        case .privateMessage:
            return "Private"
        }
    }

    func includes(_ mode: TS3TextMessageTargetMode) -> Bool {
        switch self {
        case .all:
            return true
        case .channel:
            return mode == .channel
        case .server:
            return mode == .server
        case .privateMessage:
            return mode == .client
        }
    }
}

struct EventsSheet: View {
    private enum EventCleanupConfirmation: Identifiable {
        case all
        case activity
        case pokes

        var id: String {
            switch self {
            case .all: return "all"
            case .activity: return "activity"
            case .pokes: return "pokes"
            }
        }

        var title: String {
            switch self {
            case .all: return "Clear Events?"
            case .activity: return "Clear Activity?"
            case .pokes: return "Clear Pokes?"
            }
        }

        func message(activityCount: Int, pokeCount: Int) -> String {
            switch self {
            case .all:
                return "This removes \(activityCount) activity events and \(pokeCount) pokes from local history."
            case .activity:
                return "This removes \(activityCount) activity events from local history."
            case .pokes:
                return "This removes \(pokeCount) pokes from local history."
            }
        }
    }

    private enum EventSourceFilter: String, CaseIterable, Identifiable {
        case all
        case own
        case others

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Sources"
            case .own: return "My Events"
            case .others: return "Other Users"
            }
        }

        func includes(_ event: TS3ActivitySummary) -> Bool {
            switch self {
            case .all:
                return true
            case .own:
                return event.isOwnClient
            case .others:
                return !event.isOwnClient
            }
        }

        func includes(_ poke: TS3PokeSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .own:
                return poke.isOwnPoke
            case .others:
                return !poke.isOwnPoke
            }
        }
    }

    private enum EventFilter: String, CaseIterable, Identifiable {
        case all
        case activity
        case pokes
        case clientMovement
        case channelChanges

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All"
            case .activity: return "Activity"
            case .pokes: return "Pokes"
            case .clientMovement: return "Client Movement"
            case .channelChanges: return "Channel Changes"
            }
        }

        var includesPokes: Bool {
            self == .all || self == .pokes
        }

        func includes(_ event: TS3ActivitySummary) -> Bool {
            switch self {
            case .all, .activity:
                return true
            case .pokes:
                return false
            case .clientMovement:
                switch event.kind {
                case .clientEntered, .clientLeft, .clientMoved:
                    return true
                case .channelCreated, .channelEdited, .channelDeleted, .channelMoved, .channelPasswordChanged, .channelDescriptionChanged:
                    return false
                }
            case .channelChanges:
                switch event.kind {
                case .clientEntered, .clientLeft, .clientMoved:
                    return false
                case .channelCreated, .channelEdited, .channelDeleted, .channelMoved, .channelPasswordChanged, .channelDescriptionChanged:
                    return true
                }
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var eventFilter: EventFilter = .all
    @State private var sourceFilter: EventSourceFilter = .all
    @State private var newestFirst = true
    @State private var searchText = ""
    @State private var presetName = ""
    @State private var isExportingEvents = false
    @State private var isExportingPresets = false
    @State private var isImportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var cleanupConfirmation: EventCleanupConfirmation?
    @State private var eventsDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()

    private var visibleActivityEvents: [TS3ActivitySummary] {
        let events = model.activityEvents.filter { event in
            eventFilter.includes(event) && sourceFilter.includes(event) && (
                !isSearching
                    || containsSearch(event.clientName)
                    || containsSearch(event.invokerName)
                    || containsSearch(event.channelName)
                    || containsSearch(event.reasonMessage)
                    || containsSearch(ActivityEventRow.snapshotMessage(for: event, in: model))
            )
        }
        return sortedActivityEvents(events)
    }

    private var visiblePokeEvents: [TS3PokeSummary] {
        guard eventFilter.includesPokes else { return [] }
        let pokes = model.pokeEvents.filter { poke in
            sourceFilter.includes(poke) && (
                !isSearching
                    || containsSearch(poke.senderName)
                    || containsSearch(poke.senderUniqueIdentifier)
                    || containsSearch(poke.message)
            )
        }
        return sortedPokeEvents(pokes)
    }

    private var hasVisibleEvents: Bool {
        !visibleActivityEvents.isEmpty || !visiblePokeEvents.isEmpty
    }

    private var visibleEventsSnapshot: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        func dateText(_ date: Date) -> String {
            formatter.string(from: date)
        }

        var lines: [String] = []
        if eventFilter != .all {
            lines.append("Type Filter: \(eventFilter.title)")
        }
        if sourceFilter != .all {
            lines.append("Source Filter: \(sourceFilter.title)")
        }
        lines.append("Sort: \(newestFirst ? "Newest First" : "Oldest First")")
        if isSearching {
            lines.append("Search: \(searchText.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if !lines.isEmpty {
            lines.append("")
        }
        if !visibleActivityEvents.isEmpty {
            lines.append("Activity")
            for event in visibleActivityEvents {
                lines.append("[\(dateText(event.timestamp))] \(event.clientName): \(ActivityEventRow.snapshotMessage(for: event, in: model))")
                if let reason = event.reasonMessage, !reason.isEmpty {
                    lines.append("  Reason: \(reason)")
                }
            }
        }
        if !visiblePokeEvents.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("Pokes")
            for poke in visiblePokeEvents {
                lines.append("[\(dateText(poke.timestamp))] \(poke.isOwnPoke ? "Sent to" : "Received from") \(poke.senderName): \(poke.message.isEmpty ? "Poke" : poke.message)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filters")) {
                    Picker("Type", selection: $eventFilter) {
                        ForEach(EventFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Source", selection: $sourceFilter) {
                        ForEach(EventSourceFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Toggle("Newest First", isOn: $newestFirst)
                    TextField("Search events", text: $searchText)
                        .ts3PlainTextField()
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            eventFilter = .all
                            sourceFilter = .all
                            newestFirst = true
                            searchText = ""
                        }
                    }
                }

                Section(header: Text("Filter Presets")) {
                    TextField("Preset Name", text: $presetName)
                        .ts3PlainTextField()
                    Button("Save Current Filters") {
                        model.saveEventFilterPreset(
                            name: presetName,
                            eventFilter: eventFilter.rawValue,
                            sourceFilter: sourceFilter.rawValue,
                            newestFirst: newestFirst,
                            searchText: searchText
                        )
                        presetName = ""
                    }
                    .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if model.eventFilterPresets.isEmpty {
                        Text("No saved event filter presets")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.eventFilterPresets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(presetSummary(preset))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteEventFilterPreset(preset)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                    Button("Export Presets") {
                        exportPresets()
                    }
                    .disabled(model.eventFilterPresets.isEmpty)
                    Button("Import Presets") {
                        isImportingPresets = true
                    }
                    Button("Delete All Presets") {
                        isConfirmingDeletePresets = true
                    }
                    .disabled(model.eventFilterPresets.isEmpty)
                }

                Section(header: Text("Activity")) {
                    if model.activityEvents.isEmpty {
                        Text("No activity")
                            .foregroundColor(.secondary)
                    } else if visibleActivityEvents.isEmpty {
                        Text("No matching activity")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(visibleActivityEvents) { event in
                            ActivityEventRow(event: event)
                                .environmentObject(model)
                        }
                    }
                }
                Section(header: Text("Pokes")) {
                    if model.pokeEvents.isEmpty {
                        Text("No pokes")
                            .foregroundColor(.secondary)
                    } else if visiblePokeEvents.isEmpty {
                        Text("No matching pokes")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(visiblePokeEvents) { poke in
                            PokeEventRow(poke: poke)
                                .environmentObject(model)
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.markEventsRead()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.markEventsRead()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Menu {
                        Button("Copy Event Snapshot") {
                            TS3PlatformSupport.copyToPasteboard(visibleEventsSnapshot)
                        }
                        .disabled(!hasVisibleEvents)
                        Button("Export Event Snapshot") {
                            eventsDocument = TS3TextFileDocument(data: Data(visibleEventsSnapshot.utf8))
                            isExportingEvents = true
                        }
                        .disabled(!hasVisibleEvents)
                        Button("Clear Events") {
                            cleanupConfirmation = .all
                        }
                        .disabled(model.activityEvents.isEmpty && model.pokeEvents.isEmpty)
                        Button("Clear Activity") {
                            cleanupConfirmation = .activity
                        }
                        .disabled(model.activityEvents.isEmpty)
                        Button("Clear Pokes") {
                            cleanupConfirmation = .pokes
                        }
                        .disabled(model.pokeEvents.isEmpty)
                        Button("Export Filter Presets") {
                            exportPresets()
                        }
                        .disabled(model.eventFilterPresets.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingEvents,
                document: eventsDocument,
                contentType: .plainText,
                defaultFilename: "ts3-events"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-event-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Event Filter Presets?"),
                    message: Text("This removes \(model.eventFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllEventFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $cleanupConfirmation) { confirmation in
                Alert(
                    title: Text(confirmation.title),
                    message: Text(confirmation.message(activityCount: model.activityEvents.count, pokeCount: model.pokeEvents.count)),
                    primaryButton: .destructive(Text("Clear")) {
                        switch confirmation {
                        case .all:
                            model.clearEventHistory()
                        case .activity:
                            model.clearActivityEvents()
                        case .pokes:
                            model.clearPokeEvents()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || eventFilter != .all || sourceFilter != .all || !newestFirst
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func sortedActivityEvents(_ events: [TS3ActivitySummary]) -> [TS3ActivitySummary] {
        events.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }
            if lhs.timestamp == rhs.timestamp {
                return lhs.clientName.localizedCaseInsensitiveCompare(rhs.clientName) == .orderedAscending
            }
            return newestFirst ? lhs.timestamp > rhs.timestamp : lhs.timestamp < rhs.timestamp
        }
    }

    private func sortedPokeEvents(_ pokes: [TS3PokeSummary]) -> [TS3PokeSummary] {
        pokes.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }
            if lhs.timestamp == rhs.timestamp {
                return lhs.senderName.localizedCaseInsensitiveCompare(rhs.senderName) == .orderedAscending
            }
            return newestFirst ? lhs.timestamp > rhs.timestamp : lhs.timestamp < rhs.timestamp
        }
    }

    private func applyPreset(_ preset: TS3EventFilterPreset) {
        eventFilter = EventFilter(rawValue: preset.eventFilter) ?? .all
        sourceFilter = EventSourceFilter(rawValue: preset.sourceFilter) ?? .all
        newestFirst = preset.newestFirst
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3EventFilterPreset) -> String {
        var parts = [
            (EventFilter(rawValue: preset.eventFilter) ?? .all).title,
            (EventSourceFilter(rawValue: preset.sourceFilter) ?? .all).title,
            preset.newestFirst ? "Newest" : "Oldest"
        ]
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.eventFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importEventFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ActivityEventRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let event: TS3ActivitySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(titleText)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(Self.dateText(event.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(messageText)
                .font(.body)
            if let detailText {
                Text(detailText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var messageText: String {
        Self.snapshotMessage(for: event, in: model)
    }

    private var titleText: String {
        switch event.kind {
        case .clientEntered, .clientLeft, .clientMoved:
            return event.clientName
        case .channelCreated, .channelEdited, .channelDeleted, .channelMoved, .channelPasswordChanged, .channelDescriptionChanged:
            return event.invokerName?.isEmpty == false ? event.invokerName! : "Server"
        }
    }

    private var detailText: String? {
        if let reason = event.reasonMessage, !reason.isEmpty {
            return reason
        }
        if let invoker = event.invokerName, !invoker.isEmpty, isClientEvent {
            return "by \(invoker)"
        }
        return nil
    }

    private var isClientEvent: Bool {
        switch event.kind {
        case .clientEntered, .clientLeft, .clientMoved:
            return true
        case .channelCreated, .channelEdited, .channelDeleted, .channelMoved, .channelPasswordChanged, .channelDescriptionChanged:
            return false
        }
    }

    private var affectedChannelText: String {
        if let name = event.channelName, !name.isEmpty {
            return name
        }
        return channelText(event.channelId)
    }

    private func channelText(_ channelId: Int?) -> String {
        model.channelName(for: channelId) ?? "the server"
    }

    static func snapshotMessage(for event: TS3ActivitySummary, in model: TS3AppModel) -> String {
        switch event.kind {
        case .clientEntered:
            return "joined \(model.channelName(for: event.toChannelId) ?? "the server")"
        case .clientLeft:
            return "left \(model.channelName(for: event.fromChannelId) ?? "the server")"
        case .clientMoved:
            return "moved from \(model.channelName(for: event.fromChannelId) ?? "the server") to \(model.channelName(for: event.toChannelId) ?? "the server")"
        case .channelCreated:
            return "created \(event.channelName ?? model.channelName(for: event.channelId) ?? "a channel")"
        case .channelEdited:
            return "edited \(event.channelName ?? model.channelName(for: event.channelId) ?? "a channel")"
        case .channelDeleted:
            return "deleted \(event.channelName ?? model.channelName(for: event.channelId) ?? "a channel")"
        case .channelMoved:
            return "moved \(event.channelName ?? model.channelName(for: event.channelId) ?? "a channel") to \(model.channelName(for: event.toChannelId) ?? "the server")"
        case .channelPasswordChanged:
            return "changed the password for \(event.channelName ?? model.channelName(for: event.channelId) ?? "a channel")"
        case .channelDescriptionChanged:
            return "changed the description for \(event.channelName ?? model.channelName(for: event.channelId) ?? "a channel")"
        }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct PokeEventRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let poke: TS3PokeSummary
    @State private var replyTarget: TS3UserSummary?
    @State private var isShowingOfflineReply = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(pokeTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(Self.dateText(poke.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(poke.message.isEmpty ? "Poke" : poke.message)
                .font(.body)
            if onlineSender != nil || poke.senderUniqueIdentifier?.isEmpty == false {
                HStack(spacing: 12) {
                    if let onlineSender {
                        Button("Private Message") {
                            replyTarget = onlineSender
                        }
                        .buttonStyle(.borderless)
                        Button("Poke Back") {
                            model.pokeUser(onlineSender, message: "Poke")
                        }
                        .buttonStyle(.borderless)
                    }
                    if poke.senderUniqueIdentifier?.isEmpty == false {
                        Button("Offline Reply") {
                            isShowingOfflineReply = true
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Copy Poke") {
                TS3PlatformSupport.copyToPasteboard(clipboardSummary)
            }
            Button("Copy Message") {
                TS3PlatformSupport.copyToPasteboard(poke.message.isEmpty ? "Poke" : poke.message)
            }
            Button("Copy User") {
                TS3PlatformSupport.copyToPasteboard(poke.senderName)
            }
            if let uniqueIdentifier = poke.senderUniqueIdentifier, !uniqueIdentifier.isEmpty {
                Button("Copy Unique ID") {
                    TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                }
            }
        }
        .sheet(item: $replyTarget) { user in
            ChatPrivateReplySheet(user: user)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingOfflineReply) {
            PokeOfflineReplySheet(poke: poke)
                .environmentObject(model)
        }
    }

    private var onlineSender: TS3UserSummary? {
        guard let senderId = poke.senderId else { return nil }
        return model.clients.first { $0.id == senderId }
    }

    private var pokeTitle: String {
        "\(poke.isOwnPoke ? "Sent to" : "From") \(poke.senderName)"
    }

    private var clipboardSummary: String {
        "\(Self.dateText(poke.timestamp)) \(poke.isOwnPoke ? "Sent to" : "Received from") \(poke.senderName): \(poke.message.isEmpty ? "Poke" : poke.message)"
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct PokeOfflineReplySheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let poke: TS3PokeSummary
    @State private var subject = "Re: Poke"
    @State private var message = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(poke.senderName)) {
                    TextField("Subject", text: $subject)
                        .ts3PlainTextField()
                    TextField("Message", text: $message)
                        .ts3PlainTextField()
                }
            }
            .navigationTitle("Offline Reply")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Send") {
                        if let uniqueIdentifier = poke.senderUniqueIdentifier {
                            model.sendOfflineMessage(
                                toUniqueIdentifier: uniqueIdentifier,
                                subject: subject,
                                message: message
                            )
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(isSendDisabled)
                }
            }
        }
    }

    private var isSendDisabled: Bool {
        poke.senderUniqueIdentifier?.isEmpty != false
            || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct OfflineMessagesSheet: View {
    private enum OfflineContentFilter: String, CaseIterable, Identifiable {
        case all
        case withBody
        case bodyNotLoaded
        case canReply
        case unknownSender

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Messages"
            case .withBody: return "With Body"
            case .bodyNotLoaded: return "Body Not Loaded"
            case .canReply: return "Can Reply"
            case .unknownSender: return "Unknown Sender"
            }
        }

        func matches(_ message: TS3OfflineMessageSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .withBody:
                return message.message?.isEmpty == false
            case .bodyNotLoaded:
                return message.message?.isEmpty != false
            case .canReply:
                return message.senderUniqueIdentifier?.isEmpty == false
            case .unknownSender:
                return message.senderName?.isEmpty != false && message.senderUniqueIdentifier?.isEmpty != false
            }
        }
    }

    private enum OfflineSortMode: String, CaseIterable, Identifiable {
        case timestamp
        case sender
        case subject
        case id

        var id: String { rawValue }

        var title: String {
            switch self {
            case .timestamp: return "Timestamp"
            case .sender: return "Sender"
            case .subject: return "Subject"
            case .id: return "Message ID"
            }
        }
    }

    private enum ReadFilter: String, CaseIterable, Identifiable {
        case all
        case unread
        case read

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Messages"
            case .unread: return "Unread"
            case .read: return "Read"
            }
        }

        func matches(_ message: TS3OfflineMessageSummary) -> Bool {
            switch self {
            case .all: return true
            case .unread: return !message.isRead
            case .read: return message.isRead
            }
        }
    }

    private enum DeleteConfirmation: Identifiable {
        case visible
        case read
        case deleteAllFilterPresets

        var id: String {
            switch self {
            case .visible: return "visible"
            case .read: return "read"
            case .deleteAllFilterPresets: return "deleteAllFilterPresets"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var searchText = ""
    @State private var readFilter: ReadFilter = .all
    @State private var contentFilter: OfflineContentFilter = .all
    @State private var sortMode: OfflineSortMode = .timestamp
    @State private var sortAscending = false
    @State private var presetName = ""
    @State private var isExportingInbox = false
    @State private var isExportingPresets = false
    @State private var isImportingPresets = false
    @State private var deleteConfirmation: DeleteConfirmation?
    @State private var inboxDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()

    private var canUseServerInboxActions: Bool {
        model.state == .connected
    }

    private var filteredMessages: [TS3OfflineMessageSummary] {
        let messages = model.offlineMessages.filter { message in
            readFilter.matches(message) && contentFilter.matches(message) && (
                !isSearching
                    || containsSearch(message.subject)
                    || containsSearch(message.senderName)
                    || containsSearch(message.senderUniqueIdentifier)
                    || containsSearch(message.message)
                    || containsSearch(message.isRead ? "read" : "unread")
            )
        }
        return sortedMessages(messages)
    }

    private var visibleInboxSnapshot: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        func dateText(_ date: Date?) -> String? {
            guard let date else { return nil }
            return formatter.string(from: date)
        }

        return filteredMessages.map { message in
            var rows = [
                "Message ID: \(message.id)",
                "Read: \(message.isRead ? "Yes" : "No")",
                "Sender: \(message.senderName ?? message.senderUniqueIdentifier ?? "Unknown sender")",
                "Subject: \(message.subject)"
            ]
            if let senderUniqueIdentifier = message.senderUniqueIdentifier, !senderUniqueIdentifier.isEmpty {
                rows.append("Sender UID: \(senderUniqueIdentifier)")
            }
            if let timestamp = dateText(message.timestamp) {
                rows.append("Timestamp: \(timestamp)")
            }
            if let body = message.message, !body.isEmpty {
                rows.append("Message: \(body)")
            }
            return rows.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Search")) {
                    Picker("Status", selection: $readFilter) {
                        ForEach(ReadFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Content", selection: $contentFilter) {
                        ForEach(OfflineContentFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(OfflineSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Search inbox", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveOfflineMessageFilterPreset(
                                name: presetName,
                                readFilter: readFilter.rawValue,
                                contentFilter: contentFilter.rawValue,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.offlineMessageFilterPresets.isEmpty {
                            Text("No saved inbox filter presets")
                        } else {
                            ForEach(model.offlineMessageFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteOfflineMessageFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.offlineMessageFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            deleteConfirmation = .deleteAllFilterPresets
                        }
                        .disabled(model.offlineMessageFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            readFilter = .all
                            contentFilter = .all
                            sortMode = .timestamp
                            sortAscending = false
                            searchText = ""
                        }
                    }
                }

                if !canUseServerInboxActions {
                    Section {
                        Text("Showing locally cached offline messages. Connect to refresh, load message bodies, reply, mark read, or delete from the server.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if model.offlineMessages.isEmpty {
                    Text("No offline messages")
                        .foregroundColor(.secondary)
                } else if filteredMessages.isEmpty {
                    Text("No matching messages")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredMessages) { message in
                        OfflineMessageRow(message: message)
                            .environmentObject(model)
                    }
                }
            }
            .navigationTitle("Inbox")
            .ts3InlineNavigationTitle()
            .onAppear {
                if canUseServerInboxActions {
                    model.refreshOfflineMessages()
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshOfflineMessages()
                    }
                    .disabled(!canUseServerInboxActions)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Menu {
                        Button("Copy Inbox Snapshot") {
                            TS3PlatformSupport.copyToPasteboard(visibleInboxSnapshot)
                        }
                        .disabled(filteredMessages.isEmpty)
                        Button("Export Inbox Snapshot") {
                            inboxDocument = TS3TextFileDocument(data: Data(visibleInboxSnapshot.utf8))
                            isExportingInbox = true
                        }
                        .disabled(filteredMessages.isEmpty)
                        Button("Load Visible Message Bodies") {
                            model.loadOfflineMessageBodies(filteredMessages)
                        }
                        .disabled(!canUseServerInboxActions || !hasBodyPlaceholders)
                        Button("Mark All Read") {
                            model.markAllOfflineMessagesRead()
                        }
                        .disabled(!canUseServerInboxActions || filteredMessages.allSatisfy(\.isRead))
                        Button("Mark Visible Read") {
                            model.markOfflineMessages(filteredMessages, read: true)
                        }
                        .disabled(!canUseServerInboxActions || !filteredMessages.contains { !$0.isRead })
                        Button("Mark Visible Unread") {
                            model.markOfflineMessages(filteredMessages, read: false)
                        }
                        .disabled(!canUseServerInboxActions || !filteredMessages.contains { $0.isRead })
                        Button("Delete Visible Messages") {
                            deleteConfirmation = .visible
                        }
                        .disabled(!canUseServerInboxActions || filteredMessages.isEmpty)
                        Button("Delete Read Messages") {
                            deleteConfirmation = .read
                        }
                        .disabled(!canUseServerInboxActions || readMessages.isEmpty)
                        Button("Export Filter Presets") {
                            exportPresets()
                        }
                        .disabled(model.offlineMessageFilterPresets.isEmpty)
                        Button("Delete All Filter Presets") {
                            deleteConfirmation = .deleteAllFilterPresets
                        }
                        .disabled(model.offlineMessageFilterPresets.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingInbox,
                document: inboxDocument,
                contentType: .plainText,
                defaultFilename: "ts3-offline-inbox"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-offline-message-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(item: $deleteConfirmation) { confirmation in
                switch confirmation {
                case .visible:
                    return Alert(
                        title: Text("Delete Visible Messages?"),
                        message: Text("This removes \(filteredMessages.count) offline messages from the server."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteOfflineMessages(filteredMessages)
                        },
                        secondaryButton: .cancel()
                    )
                case .read:
                    return Alert(
                        title: Text("Delete Read Messages?"),
                        message: Text("This removes \(readMessages.count) read offline messages from the server."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteOfflineMessages(readMessages)
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteAllFilterPresets:
                    return Alert(
                        title: Text("Delete All Inbox Filter Presets?"),
                        message: Text("This removes \(model.offlineMessageFilterPresets.count) saved local filter presets."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteAllOfflineMessageFilterPresets()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || readFilter != .all || contentFilter != .all || sortMode != .timestamp || sortAscending
    }

    private var hasBodyPlaceholders: Bool {
        filteredMessages.contains { $0.message?.isEmpty != false }
    }

    private var readMessages: [TS3OfflineMessageSummary] {
        model.offlineMessages.filter(\.isRead)
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func sortedMessages(_ messages: [TS3OfflineMessageSummary]) -> [TS3OfflineMessageSummary] {
        messages.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .timestamp:
                comparison = compareDates(lhs.timestamp, rhs.timestamp)
            case .sender:
                comparison = senderText(lhs).localizedCaseInsensitiveCompare(senderText(rhs))
            case .subject:
                comparison = lhs.subject.localizedCaseInsensitiveCompare(rhs.subject)
            case .id:
                comparison = compareInts(lhs.id, rhs.id)
            }

            if comparison == .orderedSame {
                return lhs.id < rhs.id
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compareDates(_ lhs: Date?, _ rhs: Date?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs.compare(rhs)
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        }
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func senderText(_ message: TS3OfflineMessageSummary) -> String {
        message.senderName ?? message.senderUniqueIdentifier ?? ""
    }

    private func applyPreset(_ preset: TS3OfflineMessageFilterPreset) {
        readFilter = ReadFilter(rawValue: preset.readFilter) ?? .all
        contentFilter = OfflineContentFilter(rawValue: preset.contentFilter) ?? .all
        sortMode = OfflineSortMode(rawValue: preset.sortMode) ?? .timestamp
        sortAscending = preset.sortAscending
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3OfflineMessageFilterPreset) -> String {
        var parts = [
            (ReadFilter(rawValue: preset.readFilter) ?? .all).title,
            (OfflineContentFilter(rawValue: preset.contentFilter) ?? .all).title,
            (OfflineSortMode(rawValue: preset.sortMode) ?? .timestamp).title,
            preset.sortAscending ? "Ascending" : "Descending"
        ]
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.offlineMessageFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importOfflineMessageFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct OfflineMessageRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let message: TS3OfflineMessageSummary
    @State private var isShowingReply = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(message.subject)
                            .font(.subheadline.weight(message.isRead ? .regular : .semibold))
                        if !message.isRead {
                            Text("Unread")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.accentColor)
                        }
                    }
                    Text(message.senderName ?? message.senderUniqueIdentifier ?? "Unknown sender")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let timestamp = message.timestamp {
                    Text(Self.dateText(timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let body = message.message, !body.isEmpty {
                Text(body)
                    .font(.body)
            } else {
                Button("Open Message") {
                    model.openOfflineMessage(message)
                }
                .buttonStyle(TS3BorderedButtonStyle())
                .disabled(!canUseServerActions)
            }

            HStack {
                if canReply {
                    Button("Reply") {
                        isShowingReply = true
                    }
                    .buttonStyle(.borderless)
                    .disabled(!canUseServerActions)
                }
                Button(message.isRead ? "Mark Unread" : "Mark Read") {
                    model.markOfflineMessage(message, read: !message.isRead)
                }
                .buttonStyle(.borderless)
                .disabled(!canUseServerActions)
                if canCopyBody {
                    Button("Copy") {
                        TS3PlatformSupport.copyToPasteboard(message.message ?? "")
                    }
                    .buttonStyle(.borderless)
                }
                Spacer()
                Button("Delete") {
                    model.deleteOfflineMessage(message)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .disabled(!canUseServerActions)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $isShowingReply) {
            OfflineMessageReplySheet(message: message)
                .environmentObject(model)
        }
        .contextMenu {
            Button("Copy Subject") {
                TS3PlatformSupport.copyToPasteboard(message.subject)
            }
            if let body = message.message, !body.isEmpty {
                Button("Copy Message") {
                    TS3PlatformSupport.copyToPasteboard(body)
                }
            }
            if let sender = message.senderName ?? message.senderUniqueIdentifier, !sender.isEmpty {
                Button("Copy Sender") {
                    TS3PlatformSupport.copyToPasteboard(sender)
                }
            }
        }
    }

    private var canReply: Bool {
        message.senderUniqueIdentifier?.isEmpty == false
    }

    private var canUseServerActions: Bool {
        model.state == .connected
    }

    private var canCopyBody: Bool {
        message.message?.isEmpty == false
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct OfflineMessageReplySheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let message: TS3OfflineMessageSummary
    @State private var subject: String
    @State private var replyText = ""

    init(message: TS3OfflineMessageSummary) {
        self.message = message
        _subject = State(initialValue: Self.replySubject(for: message.subject))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(message.senderName ?? "Recipient")) {
                    TextField("Subject", text: $subject)
                        .ts3PlainTextField()
                    TextField("Message", text: $replyText)
                        .ts3PlainTextField()
                }
            }
            .navigationTitle("Reply")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Send") {
                        if let uniqueIdentifier = message.senderUniqueIdentifier {
                            model.sendOfflineMessage(
                                toUniqueIdentifier: uniqueIdentifier,
                                subject: subject,
                                message: replyText
                            )
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(isSendDisabled)
                }
            }
        }
    }

    private var isSendDisabled: Bool {
        message.senderUniqueIdentifier?.isEmpty != false
            || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func replySubject(for subject: String) -> String {
        let trimmed = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("re:") {
            return trimmed
        }
        return trimmed.isEmpty ? "Re:" : "Re: \(trimmed)"
    }
}

struct ServerToolsSheet: View {
    private struct NotificationSettingsImportConfirmation: Identifiable {
        let url: URL
        let id = UUID()
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var nickname = ""
    @State private var bookmarkName = ""
    @State private var bookmarkFolder = ""
    @State private var privilegeKey = ""
    @State private var importedIdentity = ""
    @State private var isShowingBanList = false
    @State private var isShowingPermissions = false
    @State private var isShowingFiles = false
    @State private var isShowingServerEditor = false
    @State private var isShowingServerInfo = false
    @State private var isShowingComplaints = false
    @State private var isShowingClientDatabase = false
    @State private var isShowingServerLogs = false
    @State private var isShowingPrivilegeKeys = false
    @State private var isShowingGroupManagement = false
    @State private var isShowingContacts = false
    @State private var isImportingNotificationSettings = false
    @State private var isExportingNotificationSettings = false
    @State private var isConfirmingResetNotificationSettings = false
    @State private var pendingNotificationSettingsImport: NotificationSettingsImportConfirmation?
    @State private var notificationSettingsDocument = TS3TextFileDocument()

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { model.notificationsEnabled },
            set: { model.setNotificationsEnabled($0) }
        )
    }

    private var privateMessageNotificationsBinding: Binding<Bool> {
        Binding(
            get: { model.privateMessageNotificationsEnabled },
            set: { model.setPrivateMessageNotificationsEnabled($0) }
        )
    }

    private var notificationSoundBinding: Binding<Bool> {
        Binding(
            get: { model.notificationSoundEnabled },
            set: { model.setNotificationSoundEnabled($0) }
        )
    }

    private var pokeNotificationsBinding: Binding<Bool> {
        Binding(
            get: { model.pokeNotificationsEnabled },
            set: { model.setPokeNotificationsEnabled($0) }
        )
    }

    private var activityNotificationsBinding: Binding<Bool> {
        Binding(
            get: { model.activityNotificationsEnabled },
            set: { model.setActivityNotificationsEnabled($0) }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server")) {
                    ServerInfoRows()
                    Button("Refresh Channels and Clients") {
                        model.refreshServerView()
                    }
                    .ts3KeyboardShortcut("refresh-server", in: model)
                    Button("Subscribe All Channels") {
                        model.setAllChannelsSubscribed(true)
                    }
                    Button("Unsubscribe All Channels") {
                        model.setAllChannelsSubscribed(false)
                    }
                    Button("Refresh Server Info") {
                        model.refreshServerInfo()
                    }
                    Button("View Server Information") {
                        model.refreshServerInfo()
                        isShowingServerInfo = true
                    }
                    Button("View Server Logs") {
                        model.refreshServerLogs()
                        isShowingServerLogs = true
                    }
                    .ts3KeyboardShortcut("view-server-logs", in: model)
                    Button("Edit Server Settings") {
                        isShowingServerEditor = true
                    }
                    Button("Refresh Permission Groups") {
                        model.refreshGroups()
                    }
                    Button("Manage Permission Groups") {
                        model.refreshGroups()
                        isShowingGroupManagement = true
                    }
                    Button("View Permissions") {
                        model.refreshPermissionList()
                        model.refreshOwnClientPermissions()
                        isShowingPermissions = true
                    }
                    Button("Manage Privilege Keys") {
                        model.refreshPrivilegeKeys()
                        isShowingPrivilegeKeys = true
                    }
                    Button("Browse Client Database") {
                        model.refreshClientDatabase()
                        isShowingClientDatabase = true
                    }
                    Button("Manage Contacts") {
                        isShowingContacts = true
                    }
                    .ts3KeyboardShortcut("manage-contacts", in: model)
                    Button("Browse Channel Files") {
                        model.openFileBrowser()
                        isShowingFiles = true
                    }
                    Button("Manage Bans") {
                        model.refreshBanList()
                        isShowingBanList = true
                    }
                    Button("Manage Complaints") {
                        if let user = model.clients.first(where: { !$0.isCurrentUser }) {
                            model.refreshComplaints(for: user)
                        }
                        isShowingComplaints = true
                    }
                }

                Section(header: Text("Current Server Bookmark")) {
                    TextField("Bookmark Name", text: $bookmarkName)
                        .ts3PlainTextField()
                    TextField("Folder (optional)", text: $bookmarkFolder)
                        .ts3PlainTextField()
                    Button("Save Current Server") {
                        model.saveCurrentBookmark(name: bookmarkName, folder: bookmarkFolder)
                        bookmarkName = ""
                        bookmarkFolder = ""
                    }
                    Button("Copy Invite Link") {
                        model.copyCurrentInviteLink()
                    }
                    Button("Copy Full Invite Link") {
                        model.copyCurrentFullInviteLink()
                    }
                    Button("Copy Connection Summary") {
                        model.copyCurrentConnectionSummary()
                    }
                    Text("Full invite links include saved passwords and privilege keys.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Connection Manager")) {
                    Button("Open Connection Manager") {
                        model.isShowingConnectionManager = true
                    }
                    Text("Manage bookmarks, recent servers, recovery settings, and connection backups.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Client Migration")) {
                    Button("Open Client Migration") {
                        model.isShowingClientMigration = true
                    }
                    Text("Export or import a client package with bookmarks, contacts, profiles, notifications, and presets.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Profile")) {
                    TextField("Nickname", text: $nickname)
                        .ts3PlainTextField()
                    Button("Apply Nickname") {
                        model.updateNickname(to: nickname.isEmpty ? model.nickname : nickname)
                    }
                    .ts3KeyboardShortcut("apply-nickname", in: model)
                    TextField("Away Message", text: $model.awayMessage)
                    Button(model.isAway ? "Clear Away" : "Set Away") {
                        model.toggleAway()
                    }
                    .ts3KeyboardShortcut("toggle-away", in: model)
                    Button(model.isInputMuted ? "Unmute Microphone" : "Mute Microphone") {
                        model.toggleInputMuted()
                    }
                    .ts3KeyboardShortcut("toggle-input-muted", in: model)
                    Button(model.isOutputMuted ? "Unmute Sound" : "Mute Sound") {
                        model.toggleOutputMuted()
                    }
                    .ts3KeyboardShortcut("toggle-output-muted", in: model)
                }

                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: notificationsBinding)
                    Toggle("Sound", isOn: notificationSoundBinding)
                        .disabled(!model.notificationsEnabled)
                    Toggle("Private Messages", isOn: privateMessageNotificationsBinding)
                        .disabled(!model.notificationsEnabled)
                    Toggle("Pokes", isOn: pokeNotificationsBinding)
                        .disabled(!model.notificationsEnabled)
                    Toggle("Server Activity", isOn: activityNotificationsBinding)
                        .disabled(!model.notificationsEnabled)
                    Button("Direct Messages Preset") {
                        model.applyDirectNotificationPreset()
                    }
                    Button("Silent Direct Messages Preset") {
                        model.applyDirectNotificationPreset(soundEnabled: false)
                    }
                    Button("All Events Preset") {
                        model.applyAllEventsNotificationPreset()
                    }
                    Button("Export Notification Settings") {
                        exportNotificationSettings()
                    }
                    Button("Import Notification Settings") {
                        isImportingNotificationSettings = true
                    }
                    Button("Reset Notification Settings") {
                        isConfirmingResetNotificationSettings = true
                    }
                    Text("Notifications are shown when the app is not active.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Privilege Key")) {
                    SecureField("Privilege Key", text: $privilegeKey)
                    Button("Use Privilege Key") {
                        model.usePrivilegeKey(privilegeKey)
                        privilegeKey = ""
                    }
                }

                Section(header: Text("Identity")) {
                    IdentitySummaryRows(importedIdentity: $importedIdentity)
                }

                if !model.serverGroups.isEmpty || !model.channelGroups.isEmpty {
                    Section(header: Text("Permission Groups")) {
                        ForEach(model.serverGroups) { group in
                            Text("Server: \(group.name)")
                        }
                        ForEach(model.channelGroups) { group in
                            Text("Channel: \(group.name)")
                        }
                    }
                }
            }
            .navigationTitle("Server Tools")
            .ts3InlineNavigationTitle()
            .onAppear {
                nickname = model.nickname
                bookmarkName = model.serverHost
                Task { @MainActor in
                    await model.refreshIdentitySummary()
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingBanList) {
                BanListSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingPermissions) {
                PermissionsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingPrivilegeKeys) {
                PrivilegeKeysSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingGroupManagement) {
                GroupManagementSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingFiles) {
                FileBrowserSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingServerEditor) {
                ServerSettingsEditorSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingServerInfo) {
                ServerInformationSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingComplaints) {
                ComplaintListSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingClientDatabase) {
                ClientDatabaseSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingContacts) {
                ContactsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingServerLogs) {
                ServerLogsSheet()
                    .environmentObject(model)
            }
            .fileImporter(
                isPresented: $isImportingNotificationSettings,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingNotificationSettingsImport = NotificationSettingsImportConfirmation(url: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingNotificationSettings,
                document: notificationSettingsDocument,
                contentType: .json,
                defaultFilename: "ts3-notification-settings"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingResetNotificationSettings) {
                Alert(
                    title: Text("Reset Notification Settings?"),
                    message: Text("This restores local notification preferences to their default values."),
                    primaryButton: .destructive(Text("Reset")) {
                        model.resetNotificationSettings()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $pendingNotificationSettingsImport) { confirmation in
                Alert(
                    title: Text("Import Notification Settings?"),
                    message: Text("This replaces current local notification preferences with the selected settings file."),
                    primaryButton: .destructive(Text("Import")) {
                        importNotificationSettings(from: confirmation.url)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func exportNotificationSettings() {
        do {
            notificationSettingsDocument = TS3TextFileDocument(data: try model.notificationSettingsExportData())
            isExportingNotificationSettings = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importNotificationSettings(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importNotificationSettings(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ServerLogsSheet: View {
    private enum LogLevelFilter: String, CaseIterable, Identifiable {
        case all
        case info
        case warning
        case error
        case debug

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Levels"
            case .info: return "Info"
            case .warning: return "Warning"
            case .error: return "Error"
            case .debug: return "Debug"
            }
        }

        func matches(_ level: String?) -> Bool {
            guard self != .all else { return true }
            return level?.caseInsensitiveCompare(rawValue) == .orderedSame
        }
    }

    private enum LogConfirmation: Identifiable {
        case clearAllResults
        case clearVisibleResults
        case deleteAllPresets

        var id: String {
            switch self {
            case .clearAllResults: return "clearAllResults"
            case .clearVisibleResults: return "clearVisibleResults"
            case .deleteAllPresets: return "deleteAllPresets"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var lineLimit = "100"
    @State private var reverseOrder = true
    @State private var instanceLogs = false
    @State private var levelFilter: LogLevelFilter = .all
    @State private var searchText = ""
    @State private var newLogLevel: TS3LogLevel = .info
    @State private var newLogMessage = ""
    @State private var isExportingLogs = false
    @State private var logExportDocument = TS3TextFileDocument()
    @State private var isExportingSnapshot = false
    @State private var snapshotDocument = TS3TextFileDocument()
    @State private var presetName = ""
    @State private var isImportingPresets = false
    @State private var isExportingPresets = false
    @State private var confirmation: LogConfirmation?
    @State private var presetDocument = TS3BookmarkFileDocument()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Controls")) {
                    TextField("Lines", text: $lineLimit)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    Toggle("Reverse Order", isOn: $reverseOrder)
                    Toggle("Instance Logs", isOn: $instanceLogs)
                    Picker("Level Filter", selection: $levelFilter) {
                        ForEach(LogLevelFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    TextField("Search logs", text: $searchText)
                        .ts3PlainTextField()
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            levelFilter = .all
                            searchText = ""
                        }
                    }
                    Button("Refresh") {
                        model.refreshServerLogs(
                            limit: parsedLineLimit,
                            reverse: reverseOrder,
                            instance: instanceLogs
                        )
                    }
                    Button("Copy Visible Logs") {
                        TS3PlatformSupport.copyToPasteboard(filteredTranscript)
                    }
                    .disabled(filteredEntries.isEmpty)
                    Button("Export Visible Logs") {
                        logExportDocument = TS3TextFileDocument(data: Data(filteredTranscript.utf8))
                        isExportingLogs = true
                    }
                    .disabled(filteredEntries.isEmpty)
                    Button("Copy Snapshot") {
                        TS3PlatformSupport.copyToPasteboard(snapshot)
                    }
                    .disabled(model.serverLogEntries.isEmpty)
                    Button("Export Snapshot") {
                        snapshotDocument = TS3TextFileDocument(data: Data(snapshot.utf8))
                        isExportingSnapshot = true
                    }
                    .disabled(model.serverLogEntries.isEmpty)
                    Button("Clear Results") {
                        confirmation = .clearAllResults
                    }
                    .disabled(model.serverLogEntries.isEmpty)
                    Button("Clear Visible Results") {
                        confirmation = .clearVisibleResults
                    }
                    .disabled(filteredEntries.isEmpty)
                }

                Section(header: Text("Query Presets")) {
                    TextField("Preset Name", text: $presetName)
                        .ts3PlainTextField()
                    Button("Save Current Query") {
                        model.saveServerLogQueryPreset(
                            name: presetName,
                            limit: parsedLineLimit,
                            reverse: reverseOrder,
                            instance: instanceLogs,
                            levelFilter: levelFilter.rawValue,
                            searchText: searchText
                        )
                        presetName = ""
                    }
                    .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Export Query Presets") {
                        exportPresets()
                    }
                    .disabled(model.serverLogQueryPresets.isEmpty)
                    Button("Import Query Presets") {
                        isImportingPresets = true
                    }
                    Button("Delete All Query Presets") {
                        confirmation = .deleteAllPresets
                    }
                    .disabled(model.serverLogQueryPresets.isEmpty)
                    if model.serverLogQueryPresets.isEmpty {
                        Text("No saved log query presets")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.serverLogQueryPresets) { preset in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.name)
                                            .font(.subheadline.weight(.semibold))
                                        Text(presetSummary(preset))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Menu {
                                        Button("Apply and Refresh") {
                                            applyPreset(preset, refresh: true)
                                        }
                                        Button("Apply Only") {
                                            applyPreset(preset, refresh: false)
                                        }
                                        Button("Delete Preset") {
                                            model.deleteServerLogQueryPreset(preset)
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Add Entry")) {
                    Picker("Level", selection: $newLogLevel) {
                        ForEach(Self.logLevels, id: \.self) { level in
                            Text(Self.logLevelTitle(level)).tag(level)
                        }
                    }
                    TextField("Message", text: $newLogMessage)
                        .ts3PlainTextField()
                    Button("Write Server Log Entry") {
                        model.addServerLogEntry(
                            level: newLogLevel,
                            message: newLogMessage,
                            limit: parsedLineLimit,
                            reverse: reverseOrder,
                            instance: instanceLogs
                        )
                        newLogMessage = ""
                    }
                    .disabled(newLogMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section(header: Text("Server Log")) {
                    if filteredEntries.isEmpty {
                        Text(isSearching ? "No matching log entries" : "No log entries")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredEntries) { entry in
                            ServerLogRow(entry: entry)
                        }
                    }
                }
            }
            .navigationTitle("Server Logs")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshServerLogs(
                            limit: parsedLineLimit,
                            reverse: reverseOrder,
                            instance: instanceLogs
                        )
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                model.refreshServerLogs(
                    limit: parsedLineLimit,
                    reverse: reverseOrder,
                    instance: instanceLogs
                )
            }
            .fileExporter(
                isPresented: $isExportingLogs,
                document: logExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-server-logs"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingSnapshot,
                document: snapshotDocument,
                contentType: .plainText,
                defaultFilename: "ts3-server-log-snapshot"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetDocument,
                contentType: .json,
                defaultFilename: "ts3-server-log-query-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(item: $confirmation) { confirmation in
                switch confirmation {
                case .clearAllResults:
                    return Alert(
                        title: Text("Clear Log Results?"),
                        message: Text("This removes \(model.serverLogEntries.count) server log results from the local view."),
                        primaryButton: .destructive(Text("Clear")) {
                            model.clearServerLogResults()
                        },
                        secondaryButton: .cancel()
                    )
                case .clearVisibleResults:
                    return Alert(
                        title: Text("Clear Visible Log Results?"),
                        message: Text("This removes \(filteredEntries.count) currently visible server log results from the local view."),
                        primaryButton: .destructive(Text("Clear")) {
                            model.clearServerLogResults(filteredEntries)
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteAllPresets:
                    return Alert(
                        title: Text("Delete All Log Query Presets?"),
                        message: Text("This removes \(model.serverLogQueryPresets.count) saved local query presets."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteAllServerLogQueryPresets()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private var parsedLineLimit: Int {
        Int(lineLimit.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 100
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || levelFilter != .all
    }

    private var filteredEntries: [TS3ServerLogSummary] {
        return model.serverLogEntries.filter { entry in
            levelFilter.matches(entry.level) && (
                !isSearching
                    || containsSearch(entry.message)
                    || containsSearch(entry.level)
                    || containsSearch(entry.channel)
            )
        }
    }

    private var filteredTranscript: String {
        Self.transcript(from: filteredEntries)
    }

    private var snapshot: String {
        var lines = [
            "Limit: \(parsedLineLimit)",
            "Reverse: \(reverseOrder ? "Yes" : "No")",
            "Instance: \(instanceLogs ? "Yes" : "No")"
        ]
        if levelFilter != .all {
            lines.append("Level Filter: \(levelFilter.title)")
        }
        if isSearching {
            lines.append("Search: \(searchText.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if !filteredEntries.isEmpty {
            lines.append("")
            lines.append(filteredTranscript)
        }
        return lines.joined(separator: "\n")
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func applyPreset(_ preset: TS3ServerLogQueryPreset, refresh: Bool) {
        lineLimit = String(preset.limit)
        reverseOrder = preset.reverse
        instanceLogs = preset.instance
        levelFilter = LogLevelFilter(rawValue: preset.levelFilter) ?? .all
        searchText = preset.searchText
        presetName = preset.name
        if refresh {
            model.refreshServerLogs(
                limit: preset.limit,
                reverse: preset.reverse,
                instance: preset.instance
            )
        }
    }

    private func exportPresets() {
        do {
            presetDocument = TS3BookmarkFileDocument(data: try model.serverLogQueryPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importServerLogQueryPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func presetSummary(_ preset: TS3ServerLogQueryPreset) -> String {
        var parts = [
            "Limit \(preset.limit)",
            preset.reverse ? "Reverse" : "Forward",
            preset.instance ? "Instance" : "Server"
        ]
        if preset.levelFilter != LogLevelFilter.all.rawValue {
            parts.append((LogLevelFilter(rawValue: preset.levelFilter) ?? .all).title)
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private static let logLevels: [TS3LogLevel] = [.info, .warning, .error, .debug]

    private static func logLevelTitle(_ level: TS3LogLevel) -> String {
        switch level {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    private static func transcript(from entries: [TS3ServerLogSummary]) -> String {
        entries.map(\.clipboardText).joined(separator: "\n")
    }
}

struct ServerLogRow: View {
    let entry: TS3ServerLogSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let timestamp = entry.timestamp {
                    Text(Self.dateText(timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let level = entry.level, !level.isEmpty {
                    Text(level)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let channel = entry.channel, !channel.isEmpty {
                    Text(channel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(entry.message)
                .font(.subheadline)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Copy Message") {
                TS3PlatformSupport.copyToPasteboard(entry.message)
            }
            Button("Copy Raw Line") {
                TS3PlatformSupport.copyToPasteboard(entry.rawLine)
            }
            Button("Copy Entry") {
                TS3PlatformSupport.copyToPasteboard(entry.clipboardText)
            }
        }
    }

    fileprivate static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

private extension TS3ServerLogSummary {
    var clipboardText: String {
        var parts: [String] = []
        if let timestamp {
            parts.append(ServerLogRow.dateText(timestamp))
        }
        if let level, !level.isEmpty {
            parts.append(level)
        }
        if let channel, !channel.isEmpty {
            parts.append(channel)
        }
        parts.append(message)
        return parts.joined(separator: " | ")
    }
}

struct ServerInformationSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isExportingInfo = false
    @State private var infoExportDocument = TS3TextFileDocument()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Snapshot")) {
                    Button("Copy Server Information") {
                        TS3PlatformSupport.copyToPasteboard(informationSnapshot)
                    }
                    .disabled(informationSnapshot.isEmpty)
                    Button("Export Server Information") {
                        infoExportDocument = TS3TextFileDocument(data: Data(informationSnapshot.utf8))
                        isExportingInfo = true
                    }
                    .disabled(informationSnapshot.isEmpty)
                }

                Section(header: Text("Overview")) {
                    ServerInfoDetailRow(label: "Name", value: model.serverInfo.name)
                    ServerInfoDetailRow(label: "Status", value: model.serverInfo.status)
                    ServerInfoDetailRow(label: "Unique ID", value: model.serverInfo.uniqueIdentifier, monospaced: true)
                    ServerInfoDetailRow(label: "Machine ID", value: model.serverInfo.machineId, monospaced: true)
                    ServerInfoDetailRow(label: "Icon ID", value: model.serverInfo.iconId.map(String.init))
                    ServerInfoDetailRow(label: "Platform", value: model.serverInfo.platform)
                    ServerInfoDetailRow(label: "Version", value: model.serverInfo.version)
                    ServerInfoDetailRow(label: "Created", value: model.serverInfo.createdAt.map(Self.dateText))
                    ServerInfoDetailRow(label: "Uptime", value: model.serverInfo.uptimeSeconds.map(ServerInfoRows.uptimeText))
                    ServerInfoDetailRow(label: "Password", value: model.serverInfo.passwordProtected ? "Protected" : "Not Protected")
                    if let message = model.serverInfo.welcomeMessage, !message.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome Message")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(message)
                                .font(.footnote)
                        }
                    }
                }

                Section(header: Text("Population")) {
                    ServerInfoDetailRow(label: "Clients", value: clientsText)
                    ServerInfoDetailRow(label: "Query Clients", value: model.serverInfo.clientsInQuery.map(String.init))
                    ServerInfoDetailRow(label: "Channels", value: model.serverInfo.channelsOnline.map(String.init))
                    ServerInfoDetailRow(label: "Client Connections", value: model.serverInfo.clientConnections.map(String.init))
                    ServerInfoDetailRow(label: "Query Connections", value: model.serverInfo.queryClientConnections.map(String.init))
                }

                Section(header: Text("Default Groups")) {
                    ServerInfoDetailRow(label: "Server Group", value: groupName(model.serverInfo.defaultServerGroupId, groups: model.serverGroups))
                    ServerInfoDetailRow(label: "Channel Group", value: groupName(model.serverInfo.defaultChannelGroupId, groups: model.channelGroups))
                    ServerInfoDetailRow(label: "Channel Admin", value: groupName(model.serverInfo.defaultChannelAdminGroupId, groups: model.channelGroups))
                }

                Section(header: Text("Limits")) {
                    ServerInfoDetailRow(label: "Reserved Slots", value: model.serverInfo.reservedSlots.map(String.init))
                    ServerInfoDetailRow(label: "Download Quota", value: model.serverInfo.downloadQuota.map(Self.byteText))
                    ServerInfoDetailRow(label: "Upload Quota", value: model.serverInfo.uploadQuota.map(Self.byteText))
                    ServerInfoDetailRow(label: "File Transfer Port", value: model.serverInfo.fileTransferPort.map(String.init))
                    ServerInfoDetailRow(label: "File Base", value: model.serverInfo.fileBase)
                    ServerInfoDetailRow(label: "Codec Encryption", value: model.serverInfo.codecEncryptionMode.map(TS3CodecEncryptionMode.title))
                }

                Section(header: Text("Anti-Flood and Complaints")) {
                    ServerInfoDetailRow(label: "Auto-Ban Count", value: model.serverInfo.complainAutoBanCount.map(String.init))
                    ServerInfoDetailRow(label: "Auto-Ban Time", value: model.serverInfo.complainAutoBanTime.map(Self.durationText))
                    ServerInfoDetailRow(label: "Complaint Remove Time", value: model.serverInfo.complainRemoveTime.map(Self.durationText))
                    ServerInfoDetailRow(label: "Forced Silence Clients", value: model.serverInfo.minClientsInChannelBeforeForcedSilence.map(String.init))
                    ServerInfoDetailRow(label: "Priority Speaker Dimming", value: model.serverInfo.prioritySpeakerDimmModificator.map(Self.decimalText))
                }

                Section(header: Text("Traffic")) {
                    ServerInfoDetailRow(label: "Month Downloaded", value: model.serverInfo.monthlyBytesDownloaded.map(Self.byteText))
                    ServerInfoDetailRow(label: "Month Uploaded", value: model.serverInfo.monthlyBytesUploaded.map(Self.byteText))
                    ServerInfoDetailRow(label: "Total Downloaded", value: model.serverInfo.totalBytesDownloaded.map(Self.byteText))
                    ServerInfoDetailRow(label: "Total Uploaded", value: model.serverInfo.totalBytesUploaded.map(Self.byteText))
                }

                Section(header: Text("Connection Quality")) {
                    ServerInfoDetailRow(label: "Ping", value: model.serverInfo.totalPing.map { "\(Self.decimalText($0)) ms" })
                    ServerInfoDetailRow(label: "Packet Loss", value: model.serverInfo.totalPacketLossTotal.map(Self.percentText))
                    ServerInfoDetailRow(label: "Speech Loss", value: model.serverInfo.totalPacketLossSpeech.map(Self.percentText))
                    ServerInfoDetailRow(label: "Keepalive Loss", value: model.serverInfo.totalPacketLossKeepalive.map(Self.percentText))
                    ServerInfoDetailRow(label: "Control Loss", value: model.serverInfo.totalPacketLossControl.map(Self.percentText))
                }

                Section(header: Text("Current Connection")) {
                    ServerInfoDetailRow(label: "Ping", value: model.connectionInfo.ping.map { "\(Self.decimalText($0)) ms" })
                    ServerInfoDetailRow(label: "Packet Loss", value: model.connectionInfo.packetLossTotal.map(Self.percentText))
                    ServerInfoDetailRow(label: "Speech Loss", value: model.connectionInfo.packetLossSpeech.map(Self.percentText))
                    ServerInfoDetailRow(label: "Keepalive Loss", value: model.connectionInfo.packetLossKeepalive.map(Self.percentText))
                    ServerInfoDetailRow(label: "Control Loss", value: model.connectionInfo.packetLossControl.map(Self.percentText))
                    ServerInfoDetailRow(label: "Connected", value: model.connectionInfo.connectedSeconds.map(Self.durationText))
                    ServerInfoDetailRow(label: "Idle", value: model.connectionInfo.idleSeconds.map(Self.durationText))
                    ServerInfoDetailRow(label: "Session Downloaded", value: model.connectionInfo.bytesReceived.map(Self.byteText))
                    ServerInfoDetailRow(label: "Session Uploaded", value: model.connectionInfo.bytesSent.map(Self.byteText))
                    ServerInfoDetailRow(label: "Month Downloaded", value: model.connectionInfo.monthlyBytesReceived.map(Self.byteText))
                    ServerInfoDetailRow(label: "Month Uploaded", value: model.connectionInfo.monthlyBytesSent.map(Self.byteText))
                    ServerInfoDetailRow(label: "Total Downloaded", value: model.connectionInfo.totalBytesReceived.map(Self.byteText))
                    ServerInfoDetailRow(label: "Total Uploaded", value: model.connectionInfo.totalBytesSent.map(Self.byteText))
                }

                Section(header: Text("Host Presentation")) {
                    ServerInfoDetailRow(label: "Host Message", value: model.serverInfo.hostMessage)
                    ServerInfoDetailRow(label: "Message Mode", value: model.serverInfo.hostMessageMode.map(TS3HostMessageMode.title))
                    ServerInfoDetailRow(label: "Banner URL", value: model.serverInfo.hostBannerURL)
                    ServerInfoDetailRow(label: "Banner Graphic", value: model.serverInfo.hostBannerGraphicsURL)
                    ServerInfoDetailRow(label: "Button Tooltip", value: model.serverInfo.hostButtonTooltip)
                    ServerInfoDetailRow(label: "Button URL", value: model.serverInfo.hostButtonURL)
                    ServerInfoDetailRow(label: "Button Graphic", value: model.serverInfo.hostButtonGraphicsURL)
                }
            }
            .navigationTitle("Server Information")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshServerInfo()
                model.refreshGroups()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshServerInfo()
                        model.refreshGroups()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingInfo,
                document: infoExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-server-info"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
        }
    }

    private var informationSnapshot: String {
        var rows: [(String, String?)] = []
        rows.append(("Name", model.serverInfo.name))
        rows.append(("Status", model.serverInfo.status))
        rows.append(("Unique ID", model.serverInfo.uniqueIdentifier))
        rows.append(("Machine ID", model.serverInfo.machineId))
        rows.append(("Icon ID", model.serverInfo.iconId.map(String.init)))
        rows.append(("Platform", model.serverInfo.platform))
        rows.append(("Version", model.serverInfo.version))
        rows.append(("Created", model.serverInfo.createdAt.map(Self.dateText)))
        rows.append(("Uptime", model.serverInfo.uptimeSeconds.map(ServerInfoRows.uptimeText)))
        rows.append(("Password", model.serverInfo.passwordProtected ? "Protected" : "Not Protected"))
        rows.append(("Welcome Message", model.serverInfo.welcomeMessage))
        rows.append(("Clients", clientsText))
        rows.append(("Query Clients", model.serverInfo.clientsInQuery.map(String.init)))
        rows.append(("Channels", model.serverInfo.channelsOnline.map(String.init)))
        rows.append(("Client Connections", model.serverInfo.clientConnections.map(String.init)))
        rows.append(("Query Connections", model.serverInfo.queryClientConnections.map(String.init)))
        rows.append(("Default Server Group", groupName(model.serverInfo.defaultServerGroupId, groups: model.serverGroups)))
        rows.append(("Default Channel Group", groupName(model.serverInfo.defaultChannelGroupId, groups: model.channelGroups)))
        rows.append(("Default Channel Admin", groupName(model.serverInfo.defaultChannelAdminGroupId, groups: model.channelGroups)))
        rows.append(("Reserved Slots", model.serverInfo.reservedSlots.map(String.init)))
        rows.append(("Download Quota", model.serverInfo.downloadQuota.map(Self.byteText)))
        rows.append(("Upload Quota", model.serverInfo.uploadQuota.map(Self.byteText)))
        rows.append(("File Transfer Port", model.serverInfo.fileTransferPort.map(String.init)))
        rows.append(("File Base", model.serverInfo.fileBase))
        rows.append(("Codec Encryption", model.serverInfo.codecEncryptionMode.map(TS3CodecEncryptionMode.title)))
        rows.append(("Auto-Ban Count", model.serverInfo.complainAutoBanCount.map(String.init)))
        rows.append(("Auto-Ban Time", model.serverInfo.complainAutoBanTime.map(Self.durationText)))
        rows.append(("Complaint Remove Time", model.serverInfo.complainRemoveTime.map(Self.durationText)))
        rows.append(("Forced Silence Clients", model.serverInfo.minClientsInChannelBeforeForcedSilence.map(String.init)))
        rows.append(("Priority Speaker Dimming", model.serverInfo.prioritySpeakerDimmModificator.map(Self.decimalText)))
        rows.append(("Month Downloaded", model.serverInfo.monthlyBytesDownloaded.map(Self.byteText)))
        rows.append(("Month Uploaded", model.serverInfo.monthlyBytesUploaded.map(Self.byteText)))
        rows.append(("Total Downloaded", model.serverInfo.totalBytesDownloaded.map(Self.byteText)))
        rows.append(("Total Uploaded", model.serverInfo.totalBytesUploaded.map(Self.byteText)))
        rows.append(("Ping", model.serverInfo.totalPing.map { "\(Self.decimalText($0)) ms" }))
        rows.append(("Packet Loss", model.serverInfo.totalPacketLossTotal.map(Self.percentText)))
        rows.append(("Speech Loss", model.serverInfo.totalPacketLossSpeech.map(Self.percentText)))
        rows.append(("Keepalive Loss", model.serverInfo.totalPacketLossKeepalive.map(Self.percentText)))
        rows.append(("Control Loss", model.serverInfo.totalPacketLossControl.map(Self.percentText)))
        rows.append(("Current Ping", model.connectionInfo.ping.map { "\(Self.decimalText($0)) ms" }))
        rows.append(("Current Packet Loss", model.connectionInfo.packetLossTotal.map(Self.percentText)))
        rows.append(("Current Speech Loss", model.connectionInfo.packetLossSpeech.map(Self.percentText)))
        rows.append(("Current Keepalive Loss", model.connectionInfo.packetLossKeepalive.map(Self.percentText)))
        rows.append(("Current Control Loss", model.connectionInfo.packetLossControl.map(Self.percentText)))
        rows.append(("Current Connected", model.connectionInfo.connectedSeconds.map(Self.durationText)))
        rows.append(("Current Idle", model.connectionInfo.idleSeconds.map(Self.durationText)))
        rows.append(("Current Session Downloaded", model.connectionInfo.bytesReceived.map(Self.byteText)))
        rows.append(("Current Session Uploaded", model.connectionInfo.bytesSent.map(Self.byteText)))
        rows.append(("Current Month Downloaded", model.connectionInfo.monthlyBytesReceived.map(Self.byteText)))
        rows.append(("Current Month Uploaded", model.connectionInfo.monthlyBytesSent.map(Self.byteText)))
        rows.append(("Current Total Downloaded", model.connectionInfo.totalBytesReceived.map(Self.byteText)))
        rows.append(("Current Total Uploaded", model.connectionInfo.totalBytesSent.map(Self.byteText)))
        rows.append(("Host Message", model.serverInfo.hostMessage))
        rows.append(("Message Mode", model.serverInfo.hostMessageMode.map(TS3HostMessageMode.title)))
        rows.append(("Banner URL", model.serverInfo.hostBannerURL))
        rows.append(("Banner Graphic", model.serverInfo.hostBannerGraphicsURL))
        rows.append(("Button Tooltip", model.serverInfo.hostButtonTooltip))
        rows.append(("Button URL", model.serverInfo.hostButtonURL))
        rows.append(("Button Graphic", model.serverInfo.hostButtonGraphicsURL))
        return rows.compactMap { label, value in
            guard let value, !value.isEmpty else { return nil }
            return "\(label): \(value)"
        }.joined(separator: "\n")
    }

    private var clientsText: String? {
        guard let clients = model.serverInfo.clientsOnline else { return nil }
        if let maxClients = model.serverInfo.maxClients {
            return "\(clients) / \(maxClients)"
        }
        return String(clients)
    }

    private func groupName(_ id: Int?, groups: [TS3GroupSummary]) -> String? {
        id.map { TS3GroupSummary.name(for: $0, in: groups) }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func byteText(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    private static func durationText(_ seconds: Int) -> String {
        ServerInfoRows.uptimeText(seconds)
    }

    private static func decimalText(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static func percentText(_ value: Double) -> String {
        String(format: "%.2f%%", value * 100)
    }
}

struct ServerInfoDetailRow: View {
    let label: String
    let value: String?
    var monospaced = false

    var body: some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(label)
                Spacer(minLength: 12)
                Text(value)
                    .font(monospaced ? .system(.footnote, design: .monospaced) : .body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
            }
            .contextMenu {
                Button("Copy Value") {
                    TS3PlatformSupport.copyToPasteboard(value)
                }
                Button("Copy Row") {
                    TS3PlatformSupport.copyToPasteboard("\(label): \(value)")
                }
                if let url = parsedURL {
                    Button("Open URL") {
                        TS3PlatformSupport.openURL(url)
                    }
                }
            }
        }
    }

    private var parsedURL: URL? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              ["http", "https", "ts3server", "teamspeak"].contains(scheme) else {
            return nil
        }
        return url
    }
}

enum TS3GroupManagementTarget: String, CaseIterable, Identifiable {
    case server
    case channel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .server:
            return "Server Groups"
        case .channel:
            return "Channel Groups"
        }
    }
}

struct GroupManagementSheet: View {
    private enum GroupTypeFilter: String, CaseIterable, Identifiable {
        case all
        case template
        case regular
        case query
        case unknown

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Groups"
            case .template: return "Template"
            case .regular: return "Regular"
            case .query: return "Query"
            case .unknown: return "Unknown"
            }
        }

        func matches(_ group: TS3GroupSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .template:
                return group.type == .template
            case .regular:
                return group.type == .regular
            case .query:
                return group.type == .query
            case .unknown:
                return group.type == nil
            }
        }
    }

    private enum GroupSortMode: String, CaseIterable, Identifiable {
        case name
        case id
        case type

        var id: String { rawValue }

        var title: String {
            switch self {
            case .name: return "Name"
            case .id: return "ID"
            case .type: return "Type"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var target: TS3GroupManagementTarget = .server
    @State private var newGroupName = ""
    @State private var newGroupType: TS3PermissionGroupDatabaseType = .regular
    @State private var searchText = ""
    @State private var groupTypeFilter: GroupTypeFilter = .all
    @State private var sortMode: GroupSortMode = .name
    @State private var sortAscending = true
    @State private var presetName = ""
    @State private var isExportingGroups = false
    @State private var isExportingPresets = false
    @State private var isImportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var groupsExportDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()

    private var groups: [TS3GroupSummary] {
        switch target {
        case .server:
            return model.serverGroups
        case .channel:
            return model.channelGroups
        }
    }

    private var filteredGroups: [TS3GroupSummary] {
        let entries = groups.filter { group in
            groupTypeFilter.matches(group) && (
                !isSearching
                    || containsSearch(group.name)
                    || containsSearch(group.typeTitle)
                    || String(group.id).contains(normalizedSearchText)
            )
        }
        return sortedGroups(entries)
    }

    private var visibleGroupsSnapshot: String {
        filteredGroups.map { group in
            "groupId=\(group.id) | name=\(group.name) | type=\(group.typeTitle)"
        }
        .joined(separator: "\n")
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Target")) {
                    Picker("Group Type", selection: $target) {
                        ForEach(TS3GroupManagementTarget.allCases) { target in
                            Text(target.title).tag(target)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Create")) {
                    TextField("Group Name", text: $newGroupName)
                        .ts3PlainTextField()
                    Picker("Database Type", selection: $newGroupType) {
                        ForEach(TS3PermissionGroupDatabaseType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    Button("Create Group") {
                        createGroup()
                    }
                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section(header: Text("Filters")) {
                    Picker("Type", selection: $groupTypeFilter) {
                        ForEach(GroupTypeFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(GroupSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Search groups", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveGroupFilterPreset(
                                name: presetName,
                                target: target.rawValue,
                                groupTypeFilter: groupTypeFilter.rawValue,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.groupFilterPresets.isEmpty {
                            Text("No saved group filter presets")
                        } else {
                            ForEach(model.groupFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteGroupFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.groupFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.groupFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            groupTypeFilter = .all
                            sortMode = .name
                            sortAscending = true
                            searchText = ""
                        }
                    }
                    Button("Copy Visible Groups") {
                        TS3PlatformSupport.copyToPasteboard(visibleGroupsSnapshot)
                    }
                    .disabled(filteredGroups.isEmpty)
                    Button("Export Visible Groups") {
                        groupsExportDocument = TS3TextFileDocument(data: Data(visibleGroupsSnapshot.utf8))
                        isExportingGroups = true
                    }
                    .disabled(filteredGroups.isEmpty)
                }

                Section(header: Text(target.title)) {
                    if groups.isEmpty {
                        Text("No groups")
                            .foregroundColor(.secondary)
                    } else if filteredGroups.isEmpty {
                        Text("No matching groups")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredGroups) { group in
                            GroupManagementRow(group: group, target: target)
                                .environmentObject(model)
                        }
                    }
                }
            }
            .navigationTitle("Permission Groups")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshGroups()
            }
            .fileExporter(
                isPresented: $isExportingGroups,
                document: groupsExportDocument,
                contentType: .plainText,
                defaultFilename: target == .server ? "ts3-server-groups" : "ts3-channel-groups"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-group-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Group Filter Presets?"),
                    message: Text("This removes \(model.groupFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllGroupFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshGroups()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func createGroup() {
        switch target {
        case .server:
            model.createServerGroup(name: newGroupName, type: newGroupType)
        case .channel:
            model.createChannelGroup(name: newGroupName, type: newGroupType)
        }
        newGroupName = ""
        newGroupType = .regular
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || groupTypeFilter != .all || sortMode != .name || !sortAscending
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func sortedGroups(_ groups: [TS3GroupSummary]) -> [TS3GroupSummary] {
        groups.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .name:
                comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            case .id:
                comparison = compareInts(lhs.id, rhs.id)
            case .type:
                comparison = lhs.typeTitle.localizedCaseInsensitiveCompare(rhs.typeTitle)
            }

            if comparison == .orderedSame {
                return lhs.id < rhs.id
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func applyPreset(_ preset: TS3GroupFilterPreset) {
        target = TS3GroupManagementTarget(rawValue: preset.target) ?? .server
        groupTypeFilter = GroupTypeFilter(rawValue: preset.groupTypeFilter) ?? .all
        sortMode = GroupSortMode(rawValue: preset.sortMode) ?? .name
        sortAscending = preset.sortAscending
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3GroupFilterPreset) -> String {
        var parts = [
            (TS3GroupManagementTarget(rawValue: preset.target) ?? .server).title,
            (GroupTypeFilter(rawValue: preset.groupTypeFilter) ?? .all).title,
            "Sort \((GroupSortMode(rawValue: preset.sortMode) ?? .name).title)"
        ]
        if !preset.sortAscending {
            parts.append("Descending")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.groupFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importGroupFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct GroupManagementRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let group: TS3GroupSummary
    let target: TS3GroupManagementTarget
    @State private var isShowingMembers = false
    @State private var isShowingPermissions = false
    @State private var isShowingPrivilegeKeys = false
    @State private var isShowingRename = false
    @State private var isShowingCopy = false
    @State private var isConfirmingDelete = false
    @State private var isConfirmingForcedDelete = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 8) {
                    Text("#\(group.id)")
                    Text(group.typeTitle)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            Menu {
                Button("View Members") {
                    refreshMembers()
                    isShowingMembers = true
                }
                Button("Edit Permissions") {
                    model.selectGroupPermissions(group, target: target)
                    isShowingPermissions = true
                }
                Button("Create Privilege Key") {
                    isShowingPrivilegeKeys = true
                }
                .disabled(target == .channel && model.channels.isEmpty)
                Button("Rename") {
                    isShowingRename = true
                }
                Button("Copy") {
                    isShowingCopy = true
                }
                Button("Delete") {
                    isConfirmingDelete = true
                }
                Button("Force Delete") {
                    isConfirmingForcedDelete = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 3)
        .sheet(isPresented: $isShowingMembers) {
            GroupClientListSheet(group: group, target: target)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingPermissions) {
            PermissionsSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingPrivilegeKeys) {
            PrivilegeKeysSheet(
                initialTargetType: privilegeKeyTargetType,
                initialServerGroupId: target == .server ? group.id : nil,
                initialChannelGroupId: target == .channel ? group.id : nil,
                initialChannelId: target == .channel ? model.currentChannel?.id ?? model.channels.first?.id : nil
            )
            .environmentObject(model)
        }
        .sheet(isPresented: $isShowingRename) {
            GroupNameSheet(
                title: "Rename Group",
                actionTitle: "Rename",
                initialName: group.name,
                allowsTypeSelection: false,
                initialType: group.type ?? .regular
            ) { name, _ in
                renameGroup(name: name)
            }
        }
        .sheet(isPresented: $isShowingCopy) {
            GroupNameSheet(
                title: "Copy Group",
                actionTitle: "Copy",
                initialName: "\(group.name) Copy",
                allowsTypeSelection: true,
                initialType: group.type ?? .regular
            ) { name, type in
                copyGroup(name: name, type: type)
            }
        }
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete Group?"),
                message: Text(group.name),
                primaryButton: .destructive(Text("Delete")) {
                    deleteGroup(force: false)
                },
                secondaryButton: .cancel()
            )
        }
        .background(
            EmptyView().alert(isPresented: $isConfirmingForcedDelete) {
                Alert(
                    title: Text("Force Delete Group?"),
                    message: Text(group.name),
                    primaryButton: .destructive(Text("Force Delete")) {
                        deleteGroup(force: true)
                    },
                    secondaryButton: .cancel()
                )
            }
        )
    }

    private func renameGroup(name: String) {
        switch target {
        case .server:
            model.renameServerGroup(group, name: name)
        case .channel:
            model.renameChannelGroup(group, name: name)
        }
    }

    private func copyGroup(name: String, type: TS3PermissionGroupDatabaseType) {
        switch target {
        case .server:
            model.copyServerGroup(group, name: name, type: type)
        case .channel:
            model.copyChannelGroup(group, name: name, type: type)
        }
    }

    private func refreshMembers() {
        switch target {
        case .server:
            model.refreshServerGroupClients(group)
        case .channel:
            model.refreshChannelGroupClients(group)
        }
    }

    private func deleteGroup(force: Bool) {
        switch target {
        case .server:
            model.deleteServerGroup(group, force: force)
        case .channel:
            model.deleteChannelGroup(group, force: force)
        }
    }

    private var privilegeKeyTargetType: TS3PrivilegeKeyTargetType {
        switch target {
        case .server:
            return .serverGroup
        case .channel:
            return .channelGroup
        }
    }
}

struct GroupClientListSheet: View {
    private enum MemberFilter: String, CaseIterable, Identifiable {
        case all
        case online
        case offline
        case withUniqueId
        case withoutUniqueId

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Members"
            case .online: return "Online"
            case .offline: return "Offline"
            case .withUniqueId: return "With Unique ID"
            case .withoutUniqueId: return "Without Unique ID"
            }
        }

        func matches(_ client: TS3GroupClientSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .online:
                return client.channelId != nil
            case .offline:
                return client.channelId == nil
            case .withUniqueId:
                return client.uniqueIdentifier?.isEmpty == false
            case .withoutUniqueId:
                return client.uniqueIdentifier?.isEmpty != false
            }
        }
    }

    private enum MemberSortMode: String, CaseIterable, Identifiable {
        case nickname
        case databaseId
        case channel
        case uniqueId

        var id: String { rawValue }

        var title: String {
            switch self {
            case .nickname: return "Nickname"
            case .databaseId: return "Database ID"
            case .channel: return "Channel"
            case .uniqueId: return "Unique ID"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let group: TS3GroupSummary
    let target: TS3GroupManagementTarget
    @State private var searchText = ""
    @State private var memberFilter: MemberFilter = .all
    @State private var sortMode: MemberSortMode = .nickname
    @State private var sortAscending = true
    @State private var newMemberDatabaseId = ""
    @State private var newMemberChannelId: Int?
    @State private var presetName = ""
    @State private var isExportingMembers = false
    @State private var isExportingPresets = false
    @State private var isImportingPresets = false
    @State private var isConfirmingRemoveVisible = false
    @State private var isConfirmingDeletePresets = false
    @State private var membersExportDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()

    private var filteredClients: [TS3GroupClientSummary] {
        let clients = model.groupClients.filter { client in
            memberFilter.matches(client) && (
                !isSearching
                    || containsSearch(client.displayName)
                    || containsSearch(client.uniqueIdentifier)
                    || client.channelId.map { String($0).contains(normalizedSearchText) } == true
                    || String(client.clientDatabaseId).contains(normalizedSearchText)
                    || client.channelId.flatMap { model.channelName(for: $0) }?.lowercased().contains(normalizedSearchText) == true
            )
        }
        return sortedClients(clients)
    }

    private var visibleMembersSnapshot: String {
        filteredClients.map { client in
            var parts = [
                "clientDb=\(client.clientDatabaseId)",
                "nickname=\(client.displayName)"
            ]
            if let uniqueIdentifier = client.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                parts.append("uid=\(uniqueIdentifier)")
            }
            if let channelId = client.channelId {
                parts.append("channel=\(model.channelName(for: channelId) ?? "Channel \(channelId)")")
            }
            return parts.joined(separator: " | ")
        }
        .joined(separator: "\n")
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Filters")) {
                    Picker("Status", selection: $memberFilter) {
                        ForEach(MemberFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(MemberSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Search members", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveGroupClientFilterPreset(
                                name: presetName,
                                memberFilter: memberFilter.rawValue,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.groupClientFilterPresets.isEmpty {
                            Text("No saved group member filter presets")
                        } else {
                            ForEach(model.groupClientFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteGroupClientFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.groupClientFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.groupClientFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            memberFilter = .all
                            sortMode = .nickname
                            sortAscending = true
                            searchText = ""
                        }
                    }
                    Button("Copy Visible Members") {
                        TS3PlatformSupport.copyToPasteboard(visibleMembersSnapshot)
                    }
                    .disabled(filteredClients.isEmpty)
                    Button("Export Visible Members") {
                        membersExportDocument = TS3TextFileDocument(data: Data(visibleMembersSnapshot.utf8))
                        isExportingMembers = true
                    }
                    .disabled(filteredClients.isEmpty)
                    if target == .server {
                        TextField("Client Database ID", text: $newMemberDatabaseId)
                            .ts3NumericKeyboard()
                        Button("Add Member by Database ID") {
                            addMemberByDatabaseId()
                        }
                        .disabled(parsedNewMemberDatabaseId == nil)
                        Button("Remove Visible Members") {
                            isConfirmingRemoveVisible = true
                        }
                        .disabled(filteredClients.isEmpty)
                        .foregroundColor(.red)
                    } else {
                        Picker("Channel", selection: newMemberChannelBinding) {
                            Text("Select Channel").tag(0)
                            ForEach(model.channels) { channel in
                                Text(channel.name).tag(channel.id)
                            }
                        }
                        TextField("Client Database ID", text: $newMemberDatabaseId)
                            .ts3NumericKeyboard()
                        Button("Set Channel Group by Database ID") {
                            setChannelGroupByDatabaseId()
                        }
                        .disabled(parsedNewMemberDatabaseId == nil || selectedNewMemberChannelId == nil)
                    }
                }

                if model.groupClients.isEmpty {
                    Text("No members")
                        .foregroundColor(.secondary)
                } else if filteredClients.isEmpty {
                    Text("No matching members")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredClients) { client in
                        GroupClientRow(group: group, target: target, client: client)
                            .environmentObject(model)
                    }
                }
            }
            .navigationTitle(model.groupClientListTitle)
            .ts3InlineNavigationTitle()
            .fileExporter(
                isPresented: $isExportingMembers,
                document: membersExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-group-members"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-group-client-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $isConfirmingRemoveVisible) {
                Alert(
                    title: Text("Remove Visible Members?"),
                    message: Text("This removes \(filteredClients.count) members from \(group.name)."),
                    primaryButton: .destructive(Text("Remove")) {
                        model.removeServerGroup(group, from: filteredClients)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Group Member Filter Presets?"),
                    message: Text("This removes \(model.groupClientFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllGroupClientFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || memberFilter != .all || sortMode != .nickname || !sortAscending
    }

    private var parsedNewMemberDatabaseId: Int? {
        let trimmed = newMemberDatabaseId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let databaseId = Int(trimmed), databaseId > 0 else { return nil }
        return databaseId
    }

    private var selectedNewMemberChannelId: Int? {
        if let channelId = newMemberChannelId, model.channels.contains(where: { $0.id == channelId }) {
            return channelId
        }
        return nil
    }

    private var newMemberChannelBinding: Binding<Int> {
        Binding(
            get: { selectedNewMemberChannelId ?? 0 },
            set: { newMemberChannelId = $0 == 0 ? nil : $0 }
        )
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func addMemberByDatabaseId() {
        guard let databaseId = parsedNewMemberDatabaseId else { return }
        model.addServerGroup(group, toClientDatabaseId: databaseId)
        newMemberDatabaseId = ""
    }

    private func setChannelGroupByDatabaseId() {
        guard let databaseId = parsedNewMemberDatabaseId,
              let channelId = selectedNewMemberChannelId else { return }
        model.setChannelGroup(group, channelId: channelId, clientDatabaseId: databaseId)
        newMemberDatabaseId = ""
    }

    private func sortedClients(_ clients: [TS3GroupClientSummary]) -> [TS3GroupClientSummary] {
        clients.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .nickname:
                comparison = lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName)
            case .databaseId:
                comparison = compareInts(lhs.clientDatabaseId, rhs.clientDatabaseId)
            case .channel:
                comparison = channelDisplayName(lhs).localizedCaseInsensitiveCompare(channelDisplayName(rhs))
            case .uniqueId:
                comparison = (lhs.uniqueIdentifier ?? "").localizedCaseInsensitiveCompare(rhs.uniqueIdentifier ?? "")
            }

            if comparison == .orderedSame {
                return lhs.clientDatabaseId < rhs.clientDatabaseId
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func channelDisplayName(_ client: TS3GroupClientSummary) -> String {
        guard let channelId = client.channelId else { return "" }
        return model.channelName(for: channelId) ?? "Channel \(channelId)"
    }

    private func applyPreset(_ preset: TS3GroupClientFilterPreset) {
        memberFilter = MemberFilter(rawValue: preset.memberFilter) ?? .all
        sortMode = MemberSortMode(rawValue: preset.sortMode) ?? .nickname
        sortAscending = preset.sortAscending
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3GroupClientFilterPreset) -> String {
        var parts = [
            (MemberFilter(rawValue: preset.memberFilter) ?? .all).title,
            "Sort \((MemberSortMode(rawValue: preset.sortMode) ?? .nickname).title)"
        ]
        if !preset.sortAscending {
            parts.append("Descending")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.groupClientFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importGroupClientFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct GroupClientRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let group: TS3GroupSummary
    let target: TS3GroupManagementTarget
    let client: TS3GroupClientSummary
    @State private var isShowingInfo = false
    @State private var isConfirmingRemove = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(client.displayName)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 8) {
                    Text("DB \(client.clientDatabaseId)")
                    if let channelId = client.channelId {
                        Text(model.channelName(for: channelId) ?? "Channel \(channelId)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                if let uniqueIdentifier = client.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                    Text(uniqueIdentifier)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer()
            Menu {
                Button("Info") {
                    isShowingInfo = true
                }
                Button("Copy Nickname") {
                    TS3PlatformSupport.copyToPasteboard(client.displayName)
                }
                Button("Copy Database ID") {
                    TS3PlatformSupport.copyToPasteboard("\(client.clientDatabaseId)")
                }
                if let uniqueIdentifier = client.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                    Button("Copy Unique ID") {
                        TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                    }
                    Menu("Contact") {
                        Button("Mark as Friend") {
                            model.setContactStatus(.friend, for: databaseRecord)
                        }
                        .disabled(model.contactStatus(for: databaseRecord) == .friend)
                        Button("Block Contact") {
                            model.setContactStatus(.blocked, for: databaseRecord)
                        }
                        .disabled(model.contactStatus(for: databaseRecord) == .blocked)
                        Button("Set Neutral") {
                            model.setContactStatus(.neutral, for: databaseRecord)
                        }
                        .disabled(model.contactStatus(for: databaseRecord) == .neutral && model.contactNote(for: databaseRecord) == nil)
                    }
                }
                Button("Load Database Details") {
                    model.loadDatabaseClientDetails(databaseRecord)
                }
                if target == .server {
                    Button("Remove From Group") {
                        isConfirmingRemove = true
                    }
                } else if memberCanChangeChannelGroup {
                    Menu("Set Channel Group") {
                        ForEach(model.channelGroups) { channelGroup in
                            Button(channelGroup.name) {
                                model.setChannelGroup(channelGroup, for: client)
                            }
                            .disabled(channelGroup.id == group.id)
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 3)
        .sheet(isPresented: $isShowingInfo) {
            GroupClientInfoSheet(group: group, target: target, client: client)
                .environmentObject(model)
        }
        .alert(isPresented: $isConfirmingRemove) {
            Alert(
                title: Text("Remove Member?"),
                message: Text("\(client.displayName) from \(group.name)"),
                primaryButton: .destructive(Text("Remove")) {
                    model.removeServerGroup(group, from: client)
                },
                secondaryButton: .cancel()
            )
        }
        .contextMenu {
            Button("Info") {
                isShowingInfo = true
            }
            Button("Copy Nickname") {
                TS3PlatformSupport.copyToPasteboard(client.displayName)
            }
            Button("Copy Database ID") {
                TS3PlatformSupport.copyToPasteboard("\(client.clientDatabaseId)")
            }
            if let uniqueIdentifier = client.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                Button("Copy Unique ID") {
                    TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                }
            }
            Button("Load Database Details") {
                model.loadDatabaseClientDetails(databaseRecord)
            }
            if target == .server {
                Button("Remove From Group") {
                    isConfirmingRemove = true
                }
                .foregroundColor(.red)
            } else if memberCanChangeChannelGroup {
                ForEach(model.channelGroups) { channelGroup in
                    Button("Set Channel Group: \(channelGroup.name)") {
                        model.setChannelGroup(channelGroup, for: client)
                    }
                    .disabled(channelGroup.id == group.id)
                }
            }
        }
    }

    private var memberCanChangeChannelGroup: Bool {
        target == .channel && client.channelId != nil && !model.channelGroups.isEmpty
    }

    private var databaseRecord: TS3DatabaseClientSummary {
        TS3DatabaseClientSummary(groupClient: client)
    }
}

struct GroupClientInfoSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let group: TS3GroupSummary
    let target: TS3GroupManagementTarget
    let client: TS3GroupClientSummary

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(client.displayName)) {
                    infoRow("Group", value: group.name)
                    infoRow("Group Type", value: target.title)
                    infoRow("Database ID", value: "\(client.clientDatabaseId)")
                    if let uniqueIdentifier = client.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                        infoRow("Unique ID", value: uniqueIdentifier)
                    }
                    if let channelId = client.channelId {
                        infoRow("Channel", value: model.channelName(for: channelId) ?? "Channel \(channelId)")
                    }
                }
                Section {
                    Button("Copy Nickname") {
                        TS3PlatformSupport.copyToPasteboard(client.displayName)
                    }
                    Button("Copy Database ID") {
                        TS3PlatformSupport.copyToPasteboard("\(client.clientDatabaseId)")
                    }
                    if let uniqueIdentifier = client.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                        Button("Copy Unique ID") {
                            TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                        }
                    }
                    Button("Load Database Details") {
                        model.loadDatabaseClientDetails(TS3DatabaseClientSummary(groupClient: client))
                    }
                }
            }
            .navigationTitle("Member Info")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct GroupNameSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let title: String
    let actionTitle: String
    let allowsTypeSelection: Bool
    let submit: (String, TS3PermissionGroupDatabaseType) -> Void
    @State private var name: String
    @State private var type: TS3PermissionGroupDatabaseType

    init(
        title: String,
        actionTitle: String,
        initialName: String,
        allowsTypeSelection: Bool,
        initialType: TS3PermissionGroupDatabaseType,
        submit: @escaping (String, TS3PermissionGroupDatabaseType) -> Void
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.allowsTypeSelection = allowsTypeSelection
        self.submit = submit
        _name = State(initialValue: initialName)
        _type = State(initialValue: initialType)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Group Name", text: $name)
                        .ts3PlainTextField()
                    if allowsTypeSelection {
                        Picker("Database Type", selection: $type) {
                            ForEach(TS3PermissionGroupDatabaseType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button(actionTitle) {
                        submit(name, type)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ClientDatabaseSheet: View {
    private struct DatabaseBackupImportConfirmation: Identifiable {
        let url: URL
        let id = UUID()
    }

    private enum DatabaseRecordFilter: String, CaseIterable, Identifiable {
        case all
        case withUniqueId
        case withoutUniqueId
        case withDescription
        case withLastIP
        case withConnections

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Records"
            case .withUniqueId: return "With Unique ID"
            case .withoutUniqueId: return "Without Unique ID"
            case .withDescription: return "With Description"
            case .withLastIP: return "With Last IP"
            case .withConnections: return "With Connections"
            }
        }

        func matches(_ record: TS3DatabaseClientSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .withUniqueId:
                return record.uniqueIdentifier?.isEmpty == false
            case .withoutUniqueId:
                return record.uniqueIdentifier?.isEmpty != false
            case .withDescription:
                return record.description?.isEmpty == false
            case .withLastIP:
                return record.lastIP?.isEmpty == false
            case .withConnections:
                return record.totalConnections != nil
            }
        }
    }

    private enum DatabaseRecordSortMode: String, CaseIterable, Identifiable {
        case nickname
        case databaseId
        case created
        case lastConnected
        case connections
        case lastIP

        var id: String { rawValue }

        var title: String {
            switch self {
            case .nickname: return "Nickname"
            case .databaseId: return "Database ID"
            case .created: return "Created"
            case .lastConnected: return "Last Connected"
            case .connections: return "Connections"
            case .lastIP: return "Last IP"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var searchText = ""
    @State private var uniqueIdSearchText = ""
    @State private var localFilterText = ""
    @State private var recordFilter: DatabaseRecordFilter = .all
    @State private var sortMode: DatabaseRecordSortMode = .nickname
    @State private var sortAscending = true
    @State private var databaseBatchSize = "100"
    @State private var presetName = ""
    @State private var isShowingDescriptionEditor = false
    @State private var actionMode: DatabaseClientActionMode?
    @State private var isShowingPermissions = false
    @State private var isShowingComplaints = false
    @State private var isConfirmingDelete = false
    @State private var isExportingDatabase = false
    @State private var isExportingDatabaseBackup = false
    @State private var isExportingPresets = false
    @State private var isImportingDatabase = false
    @State private var isImportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var databaseExportDocument = TS3TextFileDocument()
    @State private var databaseBackupDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()
    @State private var pendingDatabaseBackupImport: DatabaseBackupImportConfirmation?

    var displayedRecords: [TS3DatabaseClientSummary] {
        let source = model.databaseSearchResults.isEmpty ? model.databaseClients : model.databaseSearchResults
        let filtered = source.filter { record in
            recordFilter.matches(record) && (
                !isLocalFiltering
                    || containsLocalFilter(record.nickname)
                    || containsLocalFilter(record.uniqueIdentifier)
                    || containsLocalFilter(record.description)
                    || containsLocalFilter(record.lastIP)
                    || String(record.id).contains(normalizedLocalFilterText)
                    || record.totalConnections.map { String($0).contains(normalizedLocalFilterText) } == true
            )
        }
        return sortedRecords(filtered)
    }

    private var visibleContactEntries: [TS3ContactEntry] {
        displayedRecords.compactMap { record in
            guard let uniqueIdentifier = record.uniqueIdentifier, !uniqueIdentifier.isEmpty else { return nil }
            if var existing = model.contact(for: record) {
                existing.nickname = record.nickname
                return existing
            }
            return TS3ContactEntry(
                uniqueIdentifier: uniqueIdentifier,
                nickname: record.nickname,
                status: .neutral,
                note: "",
                updatedAt: Date()
            )
        }
    }

    private var canMarkVisibleFriends: Bool {
        visibleContactEntries.contains { $0.status != .friend }
    }

    private var canBlockVisibleContacts: Bool {
        visibleContactEntries.contains { $0.status != .blocked }
    }

    private var canSetVisibleNeutral: Bool {
        visibleContactEntries.contains { $0.status != .neutral }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Search")) {
                    TextField("Nickname", text: $searchText)
                        .ts3PlainTextField()
                    HStack {
                        Button("Search") {
                            model.searchClientDatabase(pattern: searchText)
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Spacer()
                        Button("Clear") {
                            searchText = ""
                            uniqueIdSearchText = ""
                            model.databaseSearchResults = []
                            model.clientLocations = []
                        }
                    }
                    TextField("Unique ID", text: $uniqueIdSearchText)
                        .ts3PlainTextField()
                    Button("Find by Unique ID") {
                        model.findDatabaseClient(uniqueIdentifier: uniqueIdSearchText)
                    }
                    .disabled(uniqueIdSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section(header: Text("List View")) {
                    Picker("Filter", selection: $recordFilter) {
                        ForEach(DatabaseRecordFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(DatabaseRecordSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Filter loaded records", text: $localFilterText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current View") {
                            model.saveDatabaseClientFilterPreset(
                                name: presetName,
                                recordFilter: recordFilter.rawValue,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                localFilterText: localFilterText,
                                batchSize: parsedDatabaseBatchSize
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.databaseClientFilterPresets.isEmpty {
                            Text("No saved database filter presets")
                        } else {
                            ForEach(model.databaseClientFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteDatabaseClientFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.databaseClientFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.databaseClientFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalViewOptions {
                        Button("Clear List View") {
                            recordFilter = .all
                            sortMode = .nickname
                            sortAscending = true
                            localFilterText = ""
                        }
                    }
                }

                Section(header: Text("Database Range")) {
                    TextField("Batch Size", text: $databaseBatchSize)
                        .ts3NumericKeyboard()
                    HStack {
                        Text("\(model.databaseClients.count) loaded")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Load More") {
                            model.loadMoreClientDatabaseRecords(limit: parsedDatabaseBatchSize)
                        }
                        .disabled(!model.databaseSearchResults.isEmpty || !model.canLoadMoreDatabaseClients)
                    }
                }

                if !model.clientLocations.isEmpty {
                    Section(header: Text("Online Locations")) {
                        ForEach(model.clientLocations) { location in
                            DatabaseClientLocationRow(location: location)
                                .environmentObject(model)
                        }
                    }
                }

                if let selected = model.selectedDatabaseClient {
                    Section(header: Text("Selected Client")) {
                        DatabaseClientDetailRows(record: selected)
                        Button("Copy Selected Snapshot") {
                            TS3PlatformSupport.copyToPasteboard(databaseClientSnapshot(for: selected))
                        }
                        Button("Export Selected Snapshot") {
                            databaseExportDocument = TS3TextFileDocument(data: Data(databaseClientSnapshot(for: selected).utf8))
                            isExportingDatabase = true
                        }
                        Button("Export Database Backup") {
                            exportDatabaseBackup()
                        }
                        Button("Copy Nickname") {
                            TS3PlatformSupport.copyToPasteboard(selected.nickname)
                        }
                        Button("Copy Database ID") {
                            TS3PlatformSupport.copyToPasteboard("\(selected.id)")
                        }
                        if let uniqueIdentifier = selected.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                            Button("Copy Unique ID") {
                                TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                            }
                            Menu("Contact") {
                                Button("Mark as Friend") {
                                    model.setContactStatus(.friend, for: selected)
                                }
                                .disabled(model.contactStatus(for: selected) == .friend)
                                Button("Block Contact") {
                                    model.setContactStatus(.blocked, for: selected)
                                }
                                .disabled(model.contactStatus(for: selected) == .blocked)
                                Button("Set Neutral") {
                                    model.setContactStatus(.neutral, for: selected)
                                }
                                .disabled(model.contactStatus(for: selected) == .neutral && model.contactNote(for: selected) == nil)
                                Button("Edit Note") {
                                    actionMode = .contactNote
                                }
                            }
                            if !model.serverGroups.isEmpty {
                                Menu("Add Server Group") {
                                    ForEach(model.serverGroups) { group in
                                        Button(group.name) {
                                            model.addServerGroup(group, to: selected)
                                        }
                                    }
                                }
                            }
                        }
                        Button("Resolve Database ID From UID") {
                            model.resolveDatabaseIdForSelectedClient()
                        }
                        .disabled(selected.uniqueIdentifier == nil)
                        Button("Find Online Client") {
                            model.refreshOnlineLocations(for: selected)
                        }
                        .disabled(selected.uniqueIdentifier == nil)
                        Button("Edit Description") {
                            isShowingDescriptionEditor = true
                        }
                        Button("Edit Client Permissions") {
                            model.selectDatabaseClientPermissions(selected)
                            isShowingPermissions = true
                        }
                        Button("Send Offline Message") {
                            actionMode = .offlineMessage
                        }
                        .disabled(selected.uniqueIdentifier == nil)
                        Button("Submit Complaint") {
                            actionMode = .complain
                        }
                        Button("View Complaints") {
                            model.refreshComplaints(for: selected)
                            isShowingComplaints = true
                        }
                        Button("Ban Unique ID") {
                            actionMode = .ban
                        }
                        .disabled(selected.uniqueIdentifier == nil)
                        Button("Delete Database Record") {
                            isConfirmingDelete = true
                        }
                    }
                }

                Section(header: Text(model.databaseSearchResults.isEmpty ? "Database Clients" : "Search Results")) {
                    if displayedRecords.isEmpty {
                        Text("No clients")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(displayedRecords) { record in
                            DatabaseClientRow(record: record)
                                .environmentObject(model)
                        }
                    }
                }
            }
            .navigationTitle("Client Database")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshClientDatabase(limit: parsedDatabaseBatchSize)
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Menu {
                        Button("Copy Visible Database Snapshot") {
                            TS3PlatformSupport.copyToPasteboard(databaseSnapshot)
                        }
                        .disabled(displayedRecords.isEmpty)
                        Button("Export Visible Database Snapshot") {
                            databaseExportDocument = TS3TextFileDocument(data: Data(databaseSnapshot.utf8))
                            isExportingDatabase = true
                        }
                        .disabled(displayedRecords.isEmpty)
                        Button("Import Database Backup") {
                            isImportingDatabase = true
                        }
                        Divider()
                        Button("Mark Visible Friends") {
                            model.updateContacts(visibleContactEntries, status: .friend)
                        }
                        .disabled(!canMarkVisibleFriends)
                        Button("Block Visible Contacts") {
                            model.updateContacts(visibleContactEntries, status: .blocked)
                        }
                        .disabled(!canBlockVisibleContacts)
                        Button("Set Visible Neutral") {
                            model.updateContacts(visibleContactEntries, status: .neutral)
                        }
                        .disabled(!canSetVisibleNeutral)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(item: $actionMode) { mode in
                if let selected = model.selectedDatabaseClient {
                    DatabaseClientActionSheet(mode: mode, record: selected)
                        .environmentObject(model)
                }
            }
            .sheet(isPresented: $isShowingDescriptionEditor) {
                if let selected = model.selectedDatabaseClient {
                    DatabaseClientDescriptionSheet(record: selected) { description in
                        model.editDatabaseClientDescription(selected, description: description)
                    }
                }
            }
            .sheet(isPresented: $isShowingPermissions) {
                PermissionsSheet()
                    .environmentObject(model)
            }
            .sheet(isPresented: $isShowingComplaints) {
                ComplaintListSheet()
                    .environmentObject(model)
            }
            .alert(isPresented: $isConfirmingDelete) {
                Alert(
                    title: Text("Delete Database Record?"),
                    message: Text(model.selectedDatabaseClient?.nickname ?? "Selected client"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let selected = model.selectedDatabaseClient {
                            model.deleteDatabaseClient(selected)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Database Filter Presets?"),
                    message: Text("This removes \(model.databaseClientFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllDatabaseClientFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
            .fileExporter(
                isPresented: $isExportingDatabase,
                document: databaseExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-client-database"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingDatabaseBackup,
                document: databaseBackupDocument,
                contentType: .json,
                defaultFilename: "ts3-client-database-backup"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-database-client-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingDatabase,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingDatabaseBackupImport = DatabaseBackupImportConfirmation(url: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(item: $pendingDatabaseBackupImport) { confirmation in
                Alert(
                    title: Text("Import Database Backup?"),
                    message: Text("This replaces the currently loaded local database client list with the selected backup."),
                    primaryButton: .destructive(Text("Import")) {
                        importDatabaseBackup(from: confirmation.url)
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                databaseBatchSize = String(model.databaseClientBatchSize)
            }
        }
    }

    private var parsedDatabaseBatchSize: Int {
        max(1, Int(databaseBatchSize.trimmingCharacters(in: .whitespacesAndNewlines)) ?? model.databaseClientBatchSize)
    }

    private var normalizedLocalFilterText: String {
        localFilterText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isLocalFiltering: Bool {
        !normalizedLocalFilterText.isEmpty
    }

    private var hasLocalViewOptions: Bool {
        isLocalFiltering || recordFilter != .all || sortMode != .nickname || !sortAscending
    }

    private func containsLocalFilter(_ value: String?) -> Bool {
        guard let value, isLocalFiltering else { return false }
        return value.lowercased().contains(normalizedLocalFilterText)
    }

    private func sortedRecords(_ records: [TS3DatabaseClientSummary]) -> [TS3DatabaseClientSummary] {
        records.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .nickname:
                comparison = lhs.nickname.localizedCaseInsensitiveCompare(rhs.nickname)
            case .databaseId:
                comparison = compareInts(lhs.id, rhs.id)
            case .created:
                comparison = compareDates(lhs.createdAt, rhs.createdAt)
            case .lastConnected:
                comparison = compareDates(lhs.lastConnectedAt, rhs.lastConnectedAt)
            case .connections:
                comparison = compareOptionalInts(lhs.totalConnections, rhs.totalConnections)
            case .lastIP:
                comparison = (lhs.lastIP ?? "").localizedCaseInsensitiveCompare(rhs.lastIP ?? "")
            }

            if comparison == .orderedSame {
                return lhs.id < rhs.id
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compareDates(_ lhs: Date?, _ rhs: Date?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs.compare(rhs)
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        }
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func compareOptionalInts(_ lhs: Int?, _ rhs: Int?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return compareInts(lhs, rhs)
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        }
    }

    private var databaseSnapshot: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        func dateText(_ date: Date?) -> String? {
            guard let date else { return nil }
            return formatter.string(from: date)
        }

        return displayedRecords.map { record in
            var rows = [
                "Database ID: \(record.id)",
                "Nickname: \(record.nickname)"
            ]
            if let uniqueIdentifier = record.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                rows.append("Unique ID: \(uniqueIdentifier)")
            }
            if let createdAt = dateText(record.createdAt) {
                rows.append("Created: \(createdAt)")
            }
            if let lastConnectedAt = dateText(record.lastConnectedAt) {
                rows.append("Last Connected: \(lastConnectedAt)")
            }
            if let totalConnections = record.totalConnections {
                rows.append("Connections: \(totalConnections)")
            }
            if let lastIP = record.lastIP, !lastIP.isEmpty {
                rows.append("Last IP: \(lastIP)")
            }
            if let description = record.description, !description.isEmpty {
                rows.append("Description: \(description)")
            }
            return rows.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
    }

    private func databaseClientSnapshot(for record: TS3DatabaseClientSummary) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        func dateText(_ date: Date?) -> String? {
            guard let date else { return nil }
            return formatter.string(from: date)
        }

        var rows = [
            "Database ID: \(record.id)",
            "Nickname: \(record.nickname)"
        ]
        if let uniqueIdentifier = record.uniqueIdentifier, !uniqueIdentifier.isEmpty {
            rows.append("Unique ID: \(uniqueIdentifier)")
        }
        if let createdAt = dateText(record.createdAt) {
            rows.append("Created: \(createdAt)")
        }
        if let lastConnectedAt = dateText(record.lastConnectedAt) {
            rows.append("Last Connected: \(lastConnectedAt)")
        }
        if let totalConnections = record.totalConnections {
            rows.append("Connections: \(totalConnections)")
        }
        if let lastIP = record.lastIP, !lastIP.isEmpty {
            rows.append("Last IP: \(lastIP)")
        }
        if let description = record.description, !description.isEmpty {
            rows.append("Description: \(description)")
        }
        return rows.joined(separator: "\n")
    }

    private func exportDatabaseBackup() {
        do {
            databaseBackupDocument = TS3TextFileDocument(data: try model.databaseClientBackupData())
            isExportingDatabaseBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyPreset(_ preset: TS3DatabaseClientFilterPreset) {
        recordFilter = DatabaseRecordFilter(rawValue: preset.recordFilter) ?? .all
        sortMode = DatabaseRecordSortMode(rawValue: preset.sortMode) ?? .nickname
        sortAscending = preset.sortAscending
        localFilterText = preset.localFilterText
        databaseBatchSize = String(preset.batchSize)
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3DatabaseClientFilterPreset) -> String {
        var parts = [
            (DatabaseRecordFilter(rawValue: preset.recordFilter) ?? .all).title,
            "Sort \((DatabaseRecordSortMode(rawValue: preset.sortMode) ?? .nickname).title)",
            "Batch \(preset.batchSize)"
        ]
        if !preset.sortAscending {
            parts.append("Descending")
        }
        if !preset.localFilterText.isEmpty {
            parts.append("Filter \(preset.localFilterText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.databaseClientFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importDatabaseClientFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importDatabaseBackup(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importDatabaseClientBackup(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct DatabaseClientLocationRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let location: TS3ClientLocationSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName)
                        .font(.subheadline.weight(.semibold))
                    Text("Client ID \(location.clientId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let channel {
                    Button("Join") {
                        model.joinChannel(channel)
                    }
                    .buttonStyle(TS3BorderedButtonStyle())
                    .disabled(channel.isCurrent)
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "location")
                    .foregroundColor(.secondary)
                Text(channel?.name ?? "Online, channel not visible")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var user: TS3UserSummary? {
        model.clients.first { $0.id == location.clientId }
    }

    private var channel: TS3ChannelSummary? {
        guard let channelId = user?.channelId else { return nil }
        return model.channels.first { $0.id == channelId }
    }

    private var displayName: String {
        user?.nickname ?? location.nickname ?? "Client \(location.clientId)"
    }
}

struct DatabaseClientDescriptionSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let record: TS3DatabaseClientSummary
    let submit: (String) -> Void
    @State private var description: String

    init(record: TS3DatabaseClientSummary, submit: @escaping (String) -> Void) {
        self.record = record
        self.submit = submit
        _description = State(initialValue: record.description ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(record.nickname)) {
                    TextField("Description", text: $description)
                        .ts3PlainTextField()
                }
            }
            .navigationTitle("Edit Description")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Save") {
                        submit(description)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DatabaseClientActionSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let mode: DatabaseClientActionMode
    let record: TS3DatabaseClientSummary
    @State private var subject = ""
    @State private var text = ""
    @State private var duration: TS3BanDuration = .permanent
    @State private var customBanMinutes = "60"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(record.nickname)) {
                    if mode == .offlineMessage {
                        TextField("Subject", text: $subject)
                            .ts3PlainTextField()
                    }
                    TextField(fieldTitle, text: $text)
                        .ts3PlainTextField()
                    if mode == .ban {
                        Picker("Duration", selection: $duration) {
                            ForEach(TS3BanDuration.allCases) { duration in
                                Text(duration.title).tag(duration)
                            }
                        }
                        if duration == .custom {
                            TextField("Minutes", text: $customBanMinutes)
                                .ts3PlainTextField()
                                .ts3NumericKeyboard()
                        }
                    }
                }
                Section {
                    Button(actionTitle) {
                        submit()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(isActionDisabled)
                }
            }
            .navigationTitle(title)
            .ts3InlineNavigationTitle()
            .onAppear {
                if mode == .contactNote, text.isEmpty {
                    text = model.contactNote(for: record) ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .offlineMessage:
            return "Offline Message"
        case .contactNote:
            return "Contact Note"
        case .complain:
            return "Submit Complaint"
        case .ban:
            return "Ban Unique ID"
        }
    }

    private var fieldTitle: String {
        switch mode {
        case .offlineMessage:
            return "Message"
        case .contactNote:
            return "Note"
        case .complain:
            return "Complaint"
        case .ban:
            return "Reason"
        }
    }

    private var actionTitle: String {
        switch mode {
        case .offlineMessage:
            return "Send"
        case .contactNote:
            return "Save Note"
        case .complain:
            return "Submit Complaint"
        case .ban:
            return "Ban"
        }
    }

    private var isActionDisabled: Bool {
        let textIsEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch mode {
        case .offlineMessage:
            return textIsEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .contactNote:
            return false
        case .complain:
            return textIsEmpty
        case .ban:
            return duration == .custom && TS3BanDuration.customSeconds(from: customBanMinutes) == nil
        }
    }

    private func submit() {
        switch mode {
        case .offlineMessage:
            model.sendOfflineMessage(to: record, subject: subject, message: text)
        case .contactNote:
            model.setContactNote(text, for: record)
        case .complain:
            model.complainAboutDatabaseClient(record, message: text)
        case .ban:
            model.banDatabaseClient(
                record,
                durationSeconds: duration.seconds(customMinutes: customBanMinutes),
                reason: text.isEmpty ? nil : text
            )
        }
    }
}

struct DatabaseClientRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let record: TS3DatabaseClientSummary

    var body: some View {
        Button {
            model.loadDatabaseClientDetails(record)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(record.nickname)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("DB \(record.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let uniqueIdentifier = record.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                    Text(uniqueIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Copy Nickname") {
                TS3PlatformSupport.copyToPasteboard(record.nickname)
            }
            Button("Copy Database ID") {
                TS3PlatformSupport.copyToPasteboard("\(record.id)")
            }
            if let uniqueIdentifier = record.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                Button("Copy Unique ID") {
                    TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                }
            }
            if !model.serverGroups.isEmpty {
                Menu("Add Server Group") {
                    ForEach(model.serverGroups) { group in
                        Button(group.name) {
                            model.addServerGroup(group, to: record)
                        }
                    }
                }
            }
        }
    }
}

struct DatabaseClientDetailRows: View {
    let record: TS3DatabaseClientSummary

    var body: some View {
        HStack {
            Text("Nickname")
            Spacer()
            Text(record.nickname)
                .foregroundColor(.secondary)
        }
        HStack {
            Text("Database ID")
            Spacer()
            Text("\(record.id)")
                .foregroundColor(.secondary)
        }
        if let uniqueIdentifier = record.uniqueIdentifier, !uniqueIdentifier.isEmpty {
            Text(uniqueIdentifier)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        if let createdAt = record.createdAt {
            HStack {
                Text("Created")
                Spacer()
                Text(Self.dateText(createdAt))
                    .foregroundColor(.secondary)
            }
        }
        if let lastConnectedAt = record.lastConnectedAt {
            HStack {
                Text("Last Connected")
                Spacer()
                Text(Self.dateText(lastConnectedAt))
                    .foregroundColor(.secondary)
            }
        }
        if let totalConnections = record.totalConnections {
            HStack {
                Text("Connections")
                Spacer()
                Text("\(totalConnections)")
                    .foregroundColor(.secondary)
            }
        }
        if let lastIP = record.lastIP, !lastIP.isEmpty {
            HStack {
                Text("Last IP")
                Spacer()
                Text(lastIP)
                    .foregroundColor(.secondary)
            }
        }
        if let description = record.description, !description.isEmpty {
            Text(description)
        }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ServerSettingsEditorSheet: View {
    private struct ServerSettingsDraft: Codable {
        var name: String
        var welcomeMessage: String
        var maxClients: String
        var reservedSlots: String
        var clearPassword: Bool
        var password: String
        var hostMessage: String
        var hostMessageMode: String
        var hostBannerURL: String
        var hostBannerGraphicsURL: String
        var hostButtonTooltip: String
        var hostButtonURL: String
        var hostButtonGraphicsURL: String
        var iconId: String
        var downloadQuota: String
        var uploadQuota: String
        var complainAutoBanCount: String
        var complainAutoBanTime: String
        var complainRemoveTime: String
        var minClientsInChannelBeforeForcedSilence: String
        var prioritySpeakerDimmModificator: String
        var codecEncryptionMode: String
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var name = ""
    @State private var welcomeMessage = ""
    @State private var maxClients = ""
    @State private var reservedSlots = ""
    @State private var password = ""
    @State private var clearPassword = false
    @State private var hostMessage = ""
    @State private var hostMessageMode = "0"
    @State private var hostBannerURL = ""
    @State private var hostBannerGraphicsURL = ""
    @State private var hostButtonTooltip = ""
    @State private var hostButtonURL = ""
    @State private var hostButtonGraphicsURL = ""
    @State private var iconId = ""
    @State private var downloadQuota = ""
    @State private var uploadQuota = ""
    @State private var complainAutoBanCount = ""
    @State private var complainAutoBanTime = ""
    @State private var complainRemoveTime = ""
    @State private var minClientsInChannelBeforeForcedSilence = ""
    @State private var prioritySpeakerDimmModificator = ""
    @State private var codecEncryptionMode: Int?
    @State private var isShowingIconImporter = false
    @State private var isImportingDraft = false
    @State private var isExportingDraft = false
    @State private var isExportingSnapshot = false
    @State private var draftDocument = TS3TextFileDocument()
    @State private var snapshotDocument = TS3TextFileDocument()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Draft")) {
                    Button("Copy Settings Snapshot") {
                        TS3PlatformSupport.copyToPasteboard(settingsSnapshot)
                    }
                    Button("Export Settings Snapshot") {
                        snapshotDocument = TS3TextFileDocument(data: Data(settingsSnapshot.utf8))
                        isExportingSnapshot = true
                    }
                    Button("Export Settings Draft") {
                        exportDraft()
                    }
                    Button("Import Settings Draft") {
                        isImportingDraft = true
                    }
                }

                Section(header: Text("General")) {
                    TextField("Server Name", text: $name)
                        .ts3PlainTextField()
                    TextField("Welcome Message", text: $welcomeMessage)
                        .ts3PlainTextField()
                    TextField("Max Clients", text: $maxClients)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    TextField("Reserved Slots", text: $reservedSlots)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    Toggle("Clear Server Password", isOn: $clearPassword)
                    SecureField("New Server Password", text: $password)
                        .disabled(clearPassword)
                    TextField("Icon ID", text: $iconId)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    Button {
                        isShowingIconImporter = true
                    } label: {
                        Label("Upload Icon", systemImage: "photo")
                    }
                }

                Section(header: Text("Host Message")) {
                    Picker("Mode", selection: $hostMessageMode) {
                        ForEach(TS3HostMessageMode.allCases) { mode in
                            Text(mode.title).tag(String(mode.rawValue))
                        }
                        if let numericMode = Int(hostMessageMode.trimmingCharacters(in: .whitespacesAndNewlines)),
                           TS3HostMessageMode(rawValue: numericMode) == nil {
                            Text(TS3HostMessageMode.title(for: numericMode)).tag(hostMessageMode)
                        }
                    }
                    TextField("Message", text: $hostMessage)
                        .ts3PlainTextField()
                }

                Section(header: Text("Host Banner")) {
                    TextField("Banner Link URL", text: $hostBannerURL)
                        .ts3URLTextField()
                    TextField("Banner Image URL", text: $hostBannerGraphicsURL)
                        .ts3URLTextField()
                }

                Section(header: Text("Host Button")) {
                    TextField("Tooltip", text: $hostButtonTooltip)
                        .ts3PlainTextField()
                    TextField("Button Link URL", text: $hostButtonURL)
                        .ts3URLTextField()
                    TextField("Button Image URL", text: $hostButtonGraphicsURL)
                        .ts3URLTextField()
                }

                Section(header: Text("Limits")) {
                    TextField("Download Quota Bytes", text: $downloadQuota)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    TextField("Upload Quota Bytes", text: $uploadQuota)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    Picker("Codec Encryption", selection: $codecEncryptionMode) {
                        Text("Unchanged").tag(Int?.none)
                        ForEach(TS3CodecEncryptionMode.allCases) { mode in
                            Text(mode.title).tag(Optional(mode.rawValue))
                        }
                        if let codecEncryptionMode,
                           TS3CodecEncryptionMode(rawValue: codecEncryptionMode) == nil {
                            Text(TS3CodecEncryptionMode.title(for: codecEncryptionMode)).tag(Optional(codecEncryptionMode))
                        }
                    }
                }

                Section(header: Text("Anti-Flood and Complaints")) {
                    TextField("Auto-Ban Complaint Count", text: $complainAutoBanCount)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    TextField("Auto-Ban Seconds", text: $complainAutoBanTime)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    TextField("Complaint Remove Seconds", text: $complainRemoveTime)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    TextField("Forced Silence Client Count", text: $minClientsInChannelBeforeForcedSilence)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    TextField("Priority Speaker Dimming", text: $prioritySpeakerDimmModificator)
                        .ts3PlainTextField()
                }
            }
            .navigationTitle("Server Settings")
            .ts3InlineNavigationTitle()
            .onAppear(perform: loadCurrentValues)
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Reset") {
                        loadCurrentValues()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Save") {
                        save()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!isDraftValid)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingIconImporter,
                allowedContentTypes: [.image, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.uploadServerIcon(from: url) { uploadedIconId in
                        iconId = String(uploadedIconId)
                    }
                }
            }
            .fileImporter(
                isPresented: $isImportingDraft,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importDraft(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingDraft,
                document: draftDocument,
                contentType: .json,
                defaultFilename: "ts3-server-settings-draft"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingSnapshot,
                document: snapshotDocument,
                contentType: .plainText,
                defaultFilename: "ts3-server-settings"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
        }
    }

    private var currentDraft: ServerSettingsDraft {
        ServerSettingsDraft(
            name: name,
            welcomeMessage: welcomeMessage,
            maxClients: maxClients,
            reservedSlots: reservedSlots,
            clearPassword: clearPassword,
            password: password,
            hostMessage: hostMessage,
            hostMessageMode: hostMessageMode,
            hostBannerURL: hostBannerURL,
            hostBannerGraphicsURL: hostBannerGraphicsURL,
            hostButtonTooltip: hostButtonTooltip,
            hostButtonURL: hostButtonURL,
            hostButtonGraphicsURL: hostButtonGraphicsURL,
            iconId: iconId,
            downloadQuota: downloadQuota,
            uploadQuota: uploadQuota,
            complainAutoBanCount: complainAutoBanCount,
            complainAutoBanTime: complainAutoBanTime,
            complainRemoveTime: complainRemoveTime,
            minClientsInChannelBeforeForcedSilence: minClientsInChannelBeforeForcedSilence,
            prioritySpeakerDimmModificator: prioritySpeakerDimmModificator,
            codecEncryptionMode: codecEncryptionMode.map(String.init) ?? ""
        )
    }

    private var settingsSnapshot: String {
        let draft = currentDraft
        var rows: [(String, String)] = [
            ("Server Name", draft.name),
            ("Welcome Message", draft.welcomeMessage),
            ("Max Clients", draft.maxClients),
            ("Reserved Slots", draft.reservedSlots),
            ("Password", draft.clearPassword ? "Clear Password" : (draft.password.isEmpty ? "Unchanged" : "New Password Set")),
            ("Icon ID", draft.iconId),
            ("Host Message Mode", hostMessageModeTitle(draft.hostMessageMode)),
            ("Host Message", draft.hostMessage),
            ("Banner Link URL", draft.hostBannerURL),
            ("Banner Image URL", draft.hostBannerGraphicsURL),
            ("Host Button Tooltip", draft.hostButtonTooltip),
            ("Host Button URL", draft.hostButtonURL),
            ("Host Button Image URL", draft.hostButtonGraphicsURL),
            ("Download Quota Bytes", draft.downloadQuota),
            ("Upload Quota Bytes", draft.uploadQuota),
            ("Codec Encryption Mode", codecEncryptionModeTitle(draft.codecEncryptionMode)),
            ("Auto-Ban Complaint Count", draft.complainAutoBanCount),
            ("Auto-Ban Seconds", draft.complainAutoBanTime),
            ("Complaint Remove Seconds", draft.complainRemoveTime),
            ("Forced Silence Client Count", draft.minClientsInChannelBeforeForcedSilence),
            ("Priority Speaker Dimming", draft.prioritySpeakerDimmModificator)
        ]
        rows.append(("Draft Valid", isDraftValid ? "Yes" : "No"))
        return rows.compactMap { label, value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return "\(label): \(trimmed)"
        }.joined(separator: "\n")
    }

    private func loadCurrentValues() {
        name = model.serverInfo.name
        welcomeMessage = model.serverInfo.welcomeMessage ?? ""
        maxClients = model.serverInfo.maxClients.map(String.init) ?? ""
        reservedSlots = model.serverInfo.reservedSlots.map(String.init) ?? ""
        password = ""
        clearPassword = false
        hostMessage = model.serverInfo.hostMessage ?? ""
        hostMessageMode = model.serverInfo.hostMessageMode.map(String.init) ?? "0"
        hostBannerURL = model.serverInfo.hostBannerURL ?? ""
        hostBannerGraphicsURL = model.serverInfo.hostBannerGraphicsURL ?? ""
        hostButtonTooltip = model.serverInfo.hostButtonTooltip ?? ""
        hostButtonURL = model.serverInfo.hostButtonURL ?? ""
        hostButtonGraphicsURL = model.serverInfo.hostButtonGraphicsURL ?? ""
        iconId = model.serverInfo.iconId.map(String.init) ?? ""
        downloadQuota = model.serverInfo.downloadQuota.map(String.init) ?? ""
        uploadQuota = model.serverInfo.uploadQuota.map(String.init) ?? ""
        complainAutoBanCount = model.serverInfo.complainAutoBanCount.map(String.init) ?? ""
        complainAutoBanTime = model.serverInfo.complainAutoBanTime.map(String.init) ?? ""
        complainRemoveTime = model.serverInfo.complainRemoveTime.map(String.init) ?? ""
        minClientsInChannelBeforeForcedSilence = model.serverInfo.minClientsInChannelBeforeForcedSilence.map(String.init) ?? ""
        prioritySpeakerDimmModificator = model.serverInfo.prioritySpeakerDimmModificator.map(Self.decimalText) ?? ""
        codecEncryptionMode = model.serverInfo.codecEncryptionMode
    }

    private var isDraftValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isOptionalInt(maxClients)
            && isOptionalInt(reservedSlots)
            && isOptionalInt(hostMessageMode)
            && isOptionalInt(iconId)
            && isOptionalInt64(downloadQuota)
            && isOptionalInt64(uploadQuota)
            && isOptionalInt(complainAutoBanCount)
            && isOptionalInt(complainAutoBanTime)
            && isOptionalInt(complainRemoveTime)
            && isOptionalInt(minClientsInChannelBeforeForcedSilence)
            && isOptionalDouble(prioritySpeakerDimmModificator)
    }

    private func save() {
        model.editServerSettings(
            name: name,
            welcomeMessage: welcomeMessage,
            maxClients: Int(maxClients.trimmingCharacters(in: .whitespacesAndNewlines)),
            reservedSlots: Int(reservedSlots.trimmingCharacters(in: .whitespacesAndNewlines)),
            password: clearPassword ? "" : (password.isEmpty ? nil : password),
            hostMessage: hostMessage,
            hostMessageMode: Int(hostMessageMode),
            hostBannerURL: hostBannerURL,
            hostBannerGraphicsURL: hostBannerGraphicsURL,
            hostButtonTooltip: hostButtonTooltip,
            hostButtonURL: hostButtonURL,
            hostButtonGraphicsURL: hostButtonGraphicsURL,
            iconId: Int(iconId.trimmingCharacters(in: .whitespacesAndNewlines)),
            downloadQuota: Int64(downloadQuota.trimmingCharacters(in: .whitespacesAndNewlines)),
            uploadQuota: Int64(uploadQuota.trimmingCharacters(in: .whitespacesAndNewlines)),
            complainAutoBanCount: Int(complainAutoBanCount.trimmingCharacters(in: .whitespacesAndNewlines)),
            complainAutoBanTime: Int(complainAutoBanTime.trimmingCharacters(in: .whitespacesAndNewlines)),
            complainRemoveTime: Int(complainRemoveTime.trimmingCharacters(in: .whitespacesAndNewlines)),
            minClientsInChannelBeforeForcedSilence: Int(minClientsInChannelBeforeForcedSilence.trimmingCharacters(in: .whitespacesAndNewlines)),
            prioritySpeakerDimmModificator: Double(prioritySpeakerDimmModificator.trimmingCharacters(in: .whitespacesAndNewlines)),
            codecEncryptionMode: codecEncryptionMode
        )
    }

    private func exportDraft() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            draftDocument = TS3TextFileDocument(data: try encoder.encode(currentDraft))
            isExportingDraft = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importDraft(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let draft = try JSONDecoder().decode(ServerSettingsDraft.self, from: Data(contentsOf: url))
            applyDraft(draft)
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyDraft(_ draft: ServerSettingsDraft) {
        name = draft.name
        welcomeMessage = draft.welcomeMessage
        maxClients = draft.maxClients
        reservedSlots = draft.reservedSlots
        clearPassword = draft.clearPassword
        password = draft.password
        hostMessage = draft.hostMessage
        hostMessageMode = draft.hostMessageMode
        hostBannerURL = draft.hostBannerURL
        hostBannerGraphicsURL = draft.hostBannerGraphicsURL
        hostButtonTooltip = draft.hostButtonTooltip
        hostButtonURL = draft.hostButtonURL
        hostButtonGraphicsURL = draft.hostButtonGraphicsURL
        iconId = draft.iconId
        downloadQuota = draft.downloadQuota
        uploadQuota = draft.uploadQuota
        complainAutoBanCount = draft.complainAutoBanCount
        complainAutoBanTime = draft.complainAutoBanTime
        complainRemoveTime = draft.complainRemoveTime
        minClientsInChannelBeforeForcedSilence = draft.minClientsInChannelBeforeForcedSilence
        prioritySpeakerDimmModificator = draft.prioritySpeakerDimmModificator
        codecEncryptionMode = Int(draft.codecEncryptionMode.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func hostMessageModeTitle(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let numericValue = Int(trimmed) else { return trimmed }
        return TS3HostMessageMode.title(for: numericValue)
    }

    private func codecEncryptionModeTitle(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let numericValue = Int(trimmed) else { return trimmed }
        return TS3CodecEncryptionMode.title(for: numericValue)
    }

    private func isOptionalInt(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Int(trimmed) != nil
    }

    private func isOptionalInt64(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Int64(trimmed) != nil
    }

    private func isOptionalDouble(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Double(trimmed) != nil
    }

    private static func decimalText(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

struct FileBrowserSheet: View {
    private enum TransferConfirmation: Identifiable {
        case cancelActive
        case clearCompleted
        case clearFailed
        case clearInactive
        case deleteAllBookmarks
        case deleteAllFilterPresets

        var id: String {
            switch self {
            case .cancelActive: return "cancel-active"
            case .clearCompleted: return "clear-completed"
            case .clearFailed: return "clear-failed"
            case .clearInactive: return "clear-inactive"
            case .deleteAllBookmarks: return "delete-all-bookmarks"
            case .deleteAllFilterPresets: return "delete-all-filter-presets"
            }
        }
    }

    private enum FileSortMode: String, CaseIterable, Identifiable {
        case name
        case type
        case size
        case modified

        var id: String { rawValue }

        var title: String {
            switch self {
            case .name: return "Name"
            case .type: return "Type"
            case .size: return "Size"
            case .modified: return "Modified"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var directoryName = ""
    @State private var bookmarkName = ""
    @State private var presetName = ""
    @State private var pathText = "/"
    @State private var searchText = ""
    @State private var sortMode: FileSortMode = .name
    @State private var sortAscending = true
    @State private var selectedEntryIDs: Set<String> = []
    @State private var isShowingFileImporter = false
    @State private var isExportingDownloadedFile = false
    @State private var downloadedFileDocument = TS3DownloadedFileDocument()
    @State private var downloadedFileExportName = "download"
    @State private var isExportingDirectorySnapshot = false
    @State private var isExportingTransferSnapshot = false
    @State private var isImportingBookmarks = false
    @State private var isExportingBookmarks = false
    @State private var isImportingPresets = false
    @State private var isExportingPresets = false
    @State private var directorySnapshotDocument = TS3TextFileDocument()
    @State private var transferSnapshotDocument = TS3TextFileDocument()
    @State private var bookmarksDocument = TS3BookmarkFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()
    @State private var pendingUploadURLs: [URL] = []
    @State private var uploadOverwriteNames: [String] = []
    @State private var isShowingUploadConflictActions = false
    @State private var transferConfirmation: TransferConfirmation?
    @State private var isConfirmingSelectedDelete = false
    @State private var isMovingSelectedEntries = false
    @State private var selectedMoveDestinationDirectory = "/"

    var selectedChannel: TS3ChannelSummary? {
        guard let channelId = model.fileBrowserChannelId else { return nil }
        return model.channels.first { $0.id == channelId }
    }

    var body: some View {
        NavigationView {
            List {
                if !model.channels.isEmpty {
                    Section(header: Text("Channel")) {
                        Picker("Channel", selection: channelSelection) {
                            ForEach(model.channels) { channel in
                                Text(channel.name).tag(channel.id)
                            }
                        }
                        SecureField("File Password", text: $model.fileBrowserPassword)
                            .ts3PlainTextField()
                    }
                }

                Section(header: Text("Path")) {
                    HStack {
                        TextField("/", text: $pathText)
                            .ts3PlainTextField()
                        Button("Go") {
                            model.jumpToFileDirectory(pathText)
                            pathText = model.fileBrowserPath
                        }
                        .buttonStyle(.borderless)
                        .disabled(pathText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Button("Copy Current Path") {
                        TS3PlatformSupport.copyToPasteboard(model.fileBrowserPath)
                    }
                }

                Section(header: Text("File Bookmarks")) {
                    TextField("Bookmark Name", text: $bookmarkName)
                        .ts3PlainTextField()
                    Button("Save Current Location") {
                        model.saveCurrentFileBrowserBookmark(name: bookmarkName)
                        bookmarkName = ""
                    }
                    .disabled(bookmarkName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if model.fileBrowserBookmarks.isEmpty {
                        Text("No saved file bookmarks")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.fileBrowserBookmarks) { bookmark in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bookmark.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(fileBookmarkSummary(bookmark))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button("Open Bookmark") {
                                        model.applyFileBrowserBookmark(bookmark)
                                    }
                                    Button("Use Name") {
                                        bookmarkName = bookmark.name
                                    }
                                    Button("Delete Bookmark") {
                                        model.deleteFileBrowserBookmark(bookmark)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                    Button("Export Bookmarks") {
                        exportBookmarks()
                    }
                    .disabled(model.fileBrowserBookmarks.isEmpty)
                    Button("Import Bookmarks") {
                        isImportingBookmarks = true
                    }
                    Button("Delete All Bookmarks") {
                        transferConfirmation = .deleteAllBookmarks
                    }
                    .foregroundColor(.red)
                    .disabled(model.fileBrowserBookmarks.isEmpty)
                }

                Section(header: Text("Search")) {
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(FileSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Search files", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveFileBrowserFilterPreset(
                                name: presetName,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.fileBrowserFilterPresets.isEmpty {
                            Text("No saved file filter presets")
                        } else {
                            ForEach(model.fileBrowserFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteFileBrowserFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.fileBrowserFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            transferConfirmation = .deleteAllFilterPresets
                        }
                        .disabled(model.fileBrowserFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            sortMode = .name
                            sortAscending = true
                            searchText = ""
                        }
                    }
                }

                Section(header: Text(model.fileBrowserPath)) {
                    if model.fileBrowserPath != "/" {
                        Button("Parent Directory") {
                            model.leaveFileDirectory()
                        }
                    }

                    if !visibleFileEntries.isEmpty {
                        Menu {
                            Button("Select Visible Files") {
                                selectedEntryIDs.formUnion(visibleFiles.map(\.id))
                            }
                            .disabled(visibleFiles.isEmpty)
                            Button("Select Visible Entries") {
                                selectedEntryIDs.formUnion(visibleFileEntries.map(\.id))
                            }
                            Button("Deselect Visible Entries") {
                                selectedEntryIDs.subtract(visibleFileEntries.map(\.id))
                            }
                            .disabled(selectedEntries.isEmpty)
                        } label: {
                            Label("Visible Selection", systemImage: "checklist")
                        }
                    }

                    if hasSelection {
                        HStack {
                            Text("\(selectedEntries.count) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear") {
                                selectedEntryIDs.removeAll()
                            }
                            .buttonStyle(.borderless)
                        }

                        HStack(spacing: 12) {
                            Button("Download Selected") {
                                model.downloadFileEntries(selectedEntries)
                            }
                            .buttonStyle(.borderless)
                            .disabled(selectedEntries.allSatisfy(\.isDirectory))
                            Button("Move Selected") {
                                selectedMoveDestinationDirectory = model.fileBrowserPath
                                isMovingSelectedEntries = true
                            }
                            .buttonStyle(.borderless)
                            .disabled(selectedEntries.isEmpty)
                            Button("Delete Selected") {
                                isConfirmingSelectedDelete = true
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                            .disabled(selectedEntries.isEmpty)
                        }
                        .font(.caption)
                    }

                    if visibleFileEntries.isEmpty {
                        Text(isSearching ? "No matching files" : "No files")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(visibleFileEntries) { entry in
                            FileEntryRow(
                                entry: entry,
                                isSelected: selectedEntryIDs.contains(entry.id),
                                onSelect: {
                                    if entry.isDirectory {
                                        model.enterFileDirectory(entry)
                                    } else {
                                        toggleSelection(for: entry)
                                    }
                                },
                                onSelectionToggle: {
                                    toggleSelection(for: entry)
                                }
                            )
                                .environmentObject(model)
                        }
                    }
                }

                Section(header: Text("New Directory")) {
                    TextField("Directory Name", text: $directoryName)
                        .ts3PlainTextField()
                    Button("Create Directory") {
                        model.createFileDirectory(named: directoryName)
                        directoryName = ""
                    }
                    .disabled(directoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section(header: Text("Transfer")) {
                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("Upload Files", systemImage: "square.and.arrow.up")
                    }
                    .disabled(model.fileBrowserChannelId == nil)

                    if let status = model.fileTransferStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let progress = model.fileTransferProgress {
                        ProgressView(value: progress)
                    }

                    if !model.fileTransfers.isEmpty {
                        HStack(spacing: 12) {
                            Button("Copy Queue") {
                                TS3PlatformSupport.copyToPasteboard(transferQueueSnapshot)
                            }
                            .buttonStyle(.borderless)
                            Button("Export Queue") {
                                transferSnapshotDocument = TS3TextFileDocument(data: Data(transferQueueSnapshot.utf8))
                                isExportingTransferSnapshot = true
                            }
                            .buttonStyle(.borderless)
                            Button("Retry Failed") {
                                model.retryFailedFileTransfers()
                            }
                            .buttonStyle(.borderless)
                            .disabled(!model.fileTransfers.contains { $0.canRetry })
                            Button("Cancel Active") {
                                transferConfirmation = .cancelActive
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                            .disabled(!model.fileTransfers.contains { $0.canCancel })
                        }
                        .font(.caption)
                        Menu("Clear Transfers") {
                            Button("Clear Completed") {
                                transferConfirmation = .clearCompleted
                            }
                            .disabled(!model.fileTransfers.contains { $0.state == .completed })
                            Button("Clear Failed or Cancelled") {
                                transferConfirmation = .clearFailed
                            }
                            .disabled(!model.fileTransfers.contains { $0.state == .failed || $0.state == .cancelled })
                            Button("Clear All Inactive") {
                                transferConfirmation = .clearInactive
                            }
                            .disabled(!model.fileTransfers.contains { !$0.canCancel })
                        }
                        ForEach(model.fileTransfers) { transfer in
                            FileTransferRow(transfer: transfer)
                                .environmentObject(model)
                        }
                    }

                    if let downloadedFile = model.lastDownloadedFile {
                        Divider()
                        Text("Last download: \(downloadedFile.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Button("Open") {
                                model.openLastDownloadedFile()
                            }
                            .buttonStyle(.borderless)
                            Button("Copy Path") {
                                TS3PlatformSupport.copyToPasteboard(downloadedFile.url.path)
                            }
                            .buttonStyle(.borderless)
                            Button("Export") {
                                exportDownloadedFile(downloadedFile)
                            }
                            .buttonStyle(.borderless)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle(selectedChannel?.name ?? "Files")
            .ts3InlineNavigationTitle()
            .onAppear {
                if model.fileBrowserChannelId == nil {
                    model.openFileBrowser()
                } else {
                    model.refreshFileList()
                }
                pathText = model.fileBrowserPath
            }
            .onChange(of: model.fileBrowserPath) { newPath in
                pathText = newPath
                selectedEntryIDs.removeAll()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Menu {
                        Button("Copy Directory Snapshot") {
                            TS3PlatformSupport.copyToPasteboard(directorySnapshot)
                        }
                        .disabled(visibleFileEntries.isEmpty)
                        Button("Export Directory Snapshot") {
                            directorySnapshotDocument = TS3TextFileDocument(data: Data(directorySnapshot.utf8))
                            isExportingDirectorySnapshot = true
                        }
                        .disabled(visibleFileEntries.isEmpty)
                        Button("Refresh") {
                            model.refreshFileList()
                        }
                        Button("Export File Bookmarks") {
                            exportBookmarks()
                        }
                        .disabled(model.fileBrowserBookmarks.isEmpty)
                    } label: {
                        Label("Directory", systemImage: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    handleSelectedUploadFiles(urls)
                }
            }
            .fileExporter(
                isPresented: $isExportingDownloadedFile,
                document: downloadedFileDocument,
                contentType: .data,
                defaultFilename: downloadedFileExportName
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingDirectorySnapshot,
                document: directorySnapshotDocument,
                contentType: .plainText,
                defaultFilename: "ts3-directory-snapshot"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingTransferSnapshot,
                document: transferSnapshotDocument,
                contentType: .plainText,
                defaultFilename: "ts3-transfer-queue"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingBookmarks,
                document: bookmarksDocument,
                contentType: .json,
                defaultFilename: "ts3-file-bookmarks"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingBookmarks,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importBookmarks(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-file-browser-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .sheet(isPresented: $isShowingUploadConflictActions) {
                UploadConflictSheet(
                    message: uploadOverwriteMessage,
                    canResume: !resumablePendingUploadURLs.isEmpty,
                    resume: {
                        resumePendingUploads()
                    },
                    overwrite: {
                        model.uploadFiles(pendingUploadURLs, overwrite: true)
                        clearPendingUploads()
                    },
                    cancel: {
                        clearPendingUploads()
                    }
                )
            }
            .alert(isPresented: $isConfirmingSelectedDelete) {
                Alert(
                    title: Text("Delete Selected Entries?"),
                    message: Text("\(selectedEntries.count) selected entries will be deleted from the server."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteFileEntries(selectedEntries)
                        selectedEntryIDs.removeAll()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $isMovingSelectedEntries) {
                MoveFileEntriesSheet(
                    entries: selectedEntries,
                    destinationDirectory: $selectedMoveDestinationDirectory,
                    onMove: {
                        model.moveFileEntries(selectedEntries, toDirectory: selectedMoveDestinationDirectory)
                        selectedEntryIDs.removeAll()
                    }
                )
            }
            .alert(item: $transferConfirmation) { confirmation in
                switch confirmation {
                case .cancelActive:
                    return Alert(
                        title: Text("Cancel Active Transfers?"),
                        message: Text("Active uploads and downloads will be stopped."),
                        primaryButton: .destructive(Text("Cancel Transfers")) {
                            model.cancelActiveFileTransfers()
                        },
                        secondaryButton: .cancel()
                    )
                case .clearCompleted:
                    return Alert(
                        title: Text("Clear Completed Transfers?"),
                        message: Text("Completed transfer records will be removed from the queue."),
                        primaryButton: .destructive(Text("Clear")) {
                            model.clearSuccessfulFileTransfers()
                        },
                        secondaryButton: .cancel()
                    )
                case .clearFailed:
                    return Alert(
                        title: Text("Clear Failed Transfers?"),
                        message: Text("Failed and cancelled transfer records will be removed from the queue."),
                        primaryButton: .destructive(Text("Clear")) {
                            model.clearFailedFileTransfers()
                        },
                        secondaryButton: .cancel()
                    )
                case .clearInactive:
                    return Alert(
                        title: Text("Clear Inactive Transfers?"),
                        message: Text("All completed, failed, and cancelled transfer records will be removed from the queue."),
                        primaryButton: .destructive(Text("Clear")) {
                            model.clearInactiveFileTransfers()
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteAllBookmarks:
                    return Alert(
                        title: Text("Delete All File Bookmarks?"),
                        message: Text("This removes \(model.fileBrowserBookmarks.count) saved local file bookmarks."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteAllFileBrowserBookmarks()
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteAllFilterPresets:
                    return Alert(
                        title: Text("Delete All File Filter Presets?"),
                        message: Text("This removes \(model.fileBrowserFilterPresets.count) saved local filter presets."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteAllFileBrowserFilterPresets()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private var uploadOverwriteMessage: String {
        let names = uploadOverwriteNames.prefix(5).joined(separator: ", ")
        if uploadOverwriteNames.count > 5 {
            return "\(names), and \(uploadOverwriteNames.count - 5) more already exist in this channel directory."
        }
        return "\(names) already exist in this channel directory."
    }

    private func handleSelectedUploadFiles(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        let existingNames = Set(model.fileEntries.map { $0.name })
        let conflicts = urls
            .map(\.lastPathComponent)
            .filter { existingNames.contains($0) }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        if conflicts.isEmpty {
            model.uploadFiles(urls)
        } else {
            pendingUploadURLs = urls
            uploadOverwriteNames = conflicts
            isShowingUploadConflictActions = true
        }
    }

    private var resumablePendingUploadURLs: [URL] {
        let partialNames = Set(model.fileEntries.compactMap { entry -> String? in
            (entry.incompleteSize ?? 0) > 0 ? entry.name : nil
        })
        return pendingUploadURLs.filter { partialNames.contains($0.lastPathComponent) }
    }

    private func resumePendingUploads() {
        let resumable = resumablePendingUploadURLs
        let freshUploads = pendingUploadURLs.filter { url in
            !uploadOverwriteNames.contains(url.lastPathComponent)
        }
        if !freshUploads.isEmpty {
            model.uploadFiles(freshUploads)
        }
        if !resumable.isEmpty {
            model.uploadFiles(resumable, resume: true)
        }
        clearPendingUploads()
    }

    private func clearPendingUploads() {
        pendingUploadURLs = []
        uploadOverwriteNames = []
        isShowingUploadConflictActions = false
    }

    private func fileBookmarkSummary(_ bookmark: TS3FileBrowserBookmark) -> String {
        "\(bookmark.channelName) · \(bookmark.path)"
    }

    private func exportBookmarks() {
        do {
            bookmarksDocument = TS3BookmarkFileDocument(data: try model.fileBrowserBookmarksExportData())
            isExportingBookmarks = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importBookmarks(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importFileBrowserBookmarks(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyPreset(_ preset: TS3FileBrowserFilterPreset) {
        sortMode = FileSortMode(rawValue: preset.sortMode) ?? .name
        sortAscending = preset.sortAscending
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3FileBrowserFilterPreset) -> String {
        var parts = [
            "Sort \((FileSortMode(rawValue: preset.sortMode) ?? .name).title)"
        ]
        if !preset.sortAscending {
            parts.append("Descending")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.fileBrowserFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importFileBrowserFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func toggleSelection(for entry: TS3FileEntrySummary) {
        if selectedEntryIDs.contains(entry.id) {
            selectedEntryIDs.remove(entry.id)
        } else {
            selectedEntryIDs.insert(entry.id)
        }
    }

    private var selectedEntries: [TS3FileEntrySummary] {
        visibleFileEntries.filter { selectedEntryIDs.contains($0.id) }
    }

    private var visibleFiles: [TS3FileEntrySummary] {
        visibleFileEntries.filter { !$0.isDirectory }
    }

    private var hasSelection: Bool {
        !selectedEntries.isEmpty
    }

    private func exportDownloadedFile(_ file: TS3DownloadedFileSummary) {
        do {
            downloadedFileDocument = TS3DownloadedFileDocument(data: try Data(contentsOf: file.url))
            downloadedFileExportName = file.name
            isExportingDownloadedFile = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || sortMode != .name || !sortAscending
    }

    private var filteredFileEntries: [TS3FileEntrySummary] {
        guard isSearching else { return model.fileEntries }
        return model.fileEntries.filter { entry in
            containsSearch(entry.name)
                || containsSearch(entry.path)
                || containsSearch(entry.parentPath)
        }
    }

    private var visibleFileEntries: [TS3FileEntrySummary] {
        sortedFileEntries(filteredFileEntries)
    }

    private func sortedFileEntries(_ entries: [TS3FileEntrySummary]) -> [TS3FileEntrySummary] {
        entries.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory {
                return lhs.isDirectory && !rhs.isDirectory
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .name:
                comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            case .type:
                comparison = fileExtension(lhs).localizedCaseInsensitiveCompare(fileExtension(rhs))
            case .size:
                comparison = compare(lhs.size, rhs.size)
            case .modified:
                comparison = compare(lhs.modifiedAt, rhs.modifiedAt)
            }

            if comparison == .orderedSame {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func fileExtension(_ entry: TS3FileEntrySummary) -> String {
        entry.isDirectory ? "" : URL(fileURLWithPath: entry.name).pathExtension
    }

    private func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }

    private func compare(_ lhs: Date?, _ rhs: Date?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return compare(lhs, rhs)
        case (_?, nil):
            return .orderedDescending
        case (nil, _?):
            return .orderedAscending
        case (nil, nil):
            return .orderedSame
        }
    }

    private func containsSearch(_ value: String) -> Bool {
        value.lowercased().contains(normalizedSearchText)
    }

    private static func sizeText(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private var directorySnapshot: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        func dateText(_ date: Date?) -> String? {
            guard let date else { return nil }
            return formatter.string(from: date)
        }

        var lines = [
            "Path: \(model.fileBrowserPath)",
            "Sort: \(sortMode.title) \(sortAscending ? "Ascending" : "Descending")"
        ]
        if isSearching {
            lines.append("Search: \(searchText.trimmingCharacters(in: .whitespacesAndNewlines))")
        }
        if !visibleFileEntries.isEmpty {
            lines.append("")
        }
        let entries = visibleFileEntries.map { entry in
            var rows = [
                "Name: \(entry.name)",
                "Path: \(entry.path)",
                "Type: \(entry.isDirectory ? "Directory" : "File")",
                "Size: \(Self.sizeText(entry.size))"
            ]
            if let modifiedAt = dateText(entry.modifiedAt) {
                rows.append("Modified: \(modifiedAt)")
            }
            if entry.isStillUploading {
                rows.append("Uploading: Yes")
            }
            return rows.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
        if !entries.isEmpty {
            lines.append(entries)
        }
        return lines.joined(separator: "\n")
    }

    private var transferQueueSnapshot: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines = [
            "Path: \(model.fileBrowserPath)",
            "Transfers: \(model.fileTransfers.count)"
        ]
        let activeCount = model.fileTransfers.filter(\.canCancel).count
        if activeCount > 0 {
            lines.append("Active: \(activeCount)")
        }
        if !model.fileTransfers.isEmpty {
            lines.append("")
        }
        let transfers = model.fileTransfers.map { transfer in
            var rows = [
                "Name: \(transfer.name)",
                "Direction: \(transfer.direction.title)",
                "State: \(transfer.state.title)",
                "Remote Path: \(transfer.remotePath)",
                "Detail: \(transfer.detail)",
                "Started: \(formatter.string(from: transfer.startedAt))"
            ]
            if let progress = transfer.progress {
                rows.append("Progress: \(Int((progress * 100).rounded()))%")
            }
            if let localPath = transfer.localPath, !localPath.isEmpty {
                rows.append("Local Path: \(localPath)")
            }
            if let completedAt = transfer.completedAt {
                rows.append("Completed: \(formatter.string(from: completedAt))")
            }
            return rows.joined(separator: "\n")
        }
        .joined(separator: "\n\n")
        if !transfers.isEmpty {
            lines.append(transfers)
        }
        return lines.joined(separator: "\n")
    }

    private var channelSelection: Binding<Int> {
        Binding(
            get: { model.fileBrowserChannelId ?? model.currentChannel?.id ?? model.channels.first?.id ?? 0 },
            set: { channelId in
                if let channel = model.channels.first(where: { $0.id == channelId }) {
                    model.selectFileBrowserChannel(channel)
                }
            }
        )
    }
}

struct FileTransferRow: View {
    private enum RowConfirmation: Identifiable {
        case cancel
        case remove

        var id: String {
            switch self {
            case .cancel: return "cancel"
            case .remove: return "remove"
            }
        }
    }

    @EnvironmentObject private var model: TS3AppModel
    let transfer: TS3FileTransferSummary
    @State private var confirmation: RowConfirmation?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(transfer.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("\(transfer.direction.title) - \(transfer.state.title)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            if let progress = transfer.progress, transfer.state != .completed {
                ProgressView(value: progress)
            }
            Text(transfer.detail)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
            Text(transfer.remotePath)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if transfer.canCancel {
                Button("Cancel") {
                    confirmation = .cancel
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.red)
            } else if transfer.canOpenLocalFile {
                Button("Open Local File") {
                    transfer.openLocalFile()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            } else if transfer.canRetry {
                Button("Retry") {
                    model.retryFileTransfer(transfer)
                }
                .buttonStyle(.borderless)
                .font(.caption)
            } else {
                Button("Remove") {
                    confirmation = .remove
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
        }
        .padding(.vertical, 3)
        .contextMenu {
            if transfer.canCancel {
                Button("Cancel Transfer") {
                    confirmation = .cancel
                }
            }
            if transfer.canRetry {
                Button("Retry Transfer") {
                    model.retryFileTransfer(transfer)
                }
            }
            if !transfer.canCancel {
                Button("Remove Transfer") {
                    confirmation = .remove
                }
            }
            if transfer.canOpenLocalFile {
                Button("Open Local File") {
                    transfer.openLocalFile()
                }
            }
            Button("Copy Remote Path") {
                TS3PlatformSupport.copyToPasteboard(transfer.remotePath)
            }
            if let localPath = transfer.localPath, !localPath.isEmpty {
                Button("Copy Local Path") {
                    TS3PlatformSupport.copyToPasteboard(localPath)
                }
            }
            Button("Copy Status") {
                TS3PlatformSupport.copyToPasteboard(transfer.clipboardSummary)
            }
        }
        .alert(item: $confirmation) { confirmation in
            switch confirmation {
            case .cancel:
                return Alert(
                    title: Text("Cancel Transfer?"),
                    message: Text("\(transfer.name) will be stopped."),
                    primaryButton: .destructive(Text("Cancel Transfer")) {
                        model.cancelFileTransfer(transfer)
                    },
                    secondaryButton: .cancel()
                )
            case .remove:
                return Alert(
                    title: Text("Remove Transfer?"),
                    message: Text("\(transfer.name) will be removed from the queue."),
                    primaryButton: .destructive(Text("Remove")) {
                        model.removeFileTransfer(transfer)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

private extension TS3FileTransferSummary {
    var canOpenLocalFile: Bool {
        direction == .download
            && state == .completed
            && localPath?.isEmpty == false
    }

    func openLocalFile() {
        guard let localPath, !localPath.isEmpty else { return }
        TS3PlatformSupport.openURL(URL(fileURLWithPath: localPath))
    }

    var clipboardSummary: String {
        var parts = [
            "\(direction.title) \(state.title)",
            name,
            remotePath,
            detail
        ]
        if let localPath, !localPath.isEmpty {
            parts.append(localPath)
        }
        return parts.joined(separator: " | ")
    }
}

struct TS3DownloadedFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    static var writableContentTypes: [UTType] { [.data] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct FileEntryRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3FileEntrySummary
    let isSelected: Bool
    let onSelect: () -> Void
    let onSelectionToggle: () -> Void
    @State private var isRenaming = false
    @State private var isMoving = false
    @State private var isConfirmingDelete = false
    @State private var isShowingInfo = false
    @State private var newName = ""
    @State private var destinationDirectory = "/"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                onSelect()
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    Image(systemName: entry.isDirectory ? "folder" : "doc")
                        .foregroundColor(entry.isDirectory ? .accentColor : .secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Text(detailText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            HStack {
                if !entry.isDirectory {
                    Button("Download") {
                        model.downloadFileEntry(entry)
                    }
                    .buttonStyle(.borderless)
                }
                Button(isSelected ? "Deselect" : "Select") {
                    onSelectionToggle()
                }
                .buttonStyle(.borderless)
                Button("Rename") {
                    newName = entry.name
                    isRenaming = true
                }
                .buttonStyle(.borderless)
                Button("Move") {
                    destinationDirectory = model.fileBrowserPath
                    isMoving = true
                }
                .buttonStyle(.borderless)
                Button("Info") {
                    isShowingInfo = true
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Delete") {
                    isConfirmingDelete = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete File Entry?"),
                message: Text(entry.name),
                primaryButton: .destructive(Text("Delete")) {
                    model.deleteFileEntry(entry)
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isRenaming) {
            RenameFileEntrySheet(entry: entry, newName: $newName)
                .environmentObject(model)
        }
        .sheet(isPresented: $isMoving) {
            MoveFileEntrySheet(entry: entry, destinationDirectory: $destinationDirectory)
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingInfo) {
            FileEntryInfoSheet(entry: entry)
        }
        .contextMenu {
            if entry.isDirectory {
                Button("Open Directory") {
                    model.enterFileDirectory(entry)
                }
            } else {
                Button("Download") {
                    model.downloadFileEntry(entry)
                }
            }
            Button(isSelected ? "Deselect" : "Select") {
                onSelectionToggle()
            }
            Button("Copy Name") {
                TS3PlatformSupport.copyToPasteboard(entry.name)
            }
            Button("Copy Path") {
                TS3PlatformSupport.copyToPasteboard(entry.path)
            }
            Button("Copy Parent Path") {
                TS3PlatformSupport.copyToPasteboard(entry.parentPath)
            }
            Button("Copy Size") {
                TS3PlatformSupport.copyToPasteboard(Self.sizeText(entry.size))
            }
            Button("Info") {
                isShowingInfo = true
            }
            Button("Rename") {
                newName = entry.name
                isRenaming = true
            }
            Button("Move") {
                destinationDirectory = model.fileBrowserPath
                isMoving = true
            }
            Button("Delete") {
                isConfirmingDelete = true
            }
            .foregroundColor(.red)
        }
    }

    private var detailText: String {
        var parts: [String] = []
        parts.append(entry.isDirectory ? "Directory" : Self.sizeText(entry.size))
        if entry.isStillUploading {
            parts.append("Uploading")
        }
        if let modifiedAt = entry.modifiedAt {
            parts.append(Self.dateText(modifiedAt))
        }
        return parts.joined(separator: " | ")
    }

    private static func sizeText(_ bytes: Int64) -> String {
        if bytes < 1_024 {
            return "\(bytes) B"
        }
        let kb = Double(bytes) / 1_024
        if kb < 1_024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1_024
        if mb < 1_024 {
            return String(format: "%.1f MB", mb)
        }
        return String(format: "%.1f GB", mb / 1_024)
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FileEntryInfoSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let entry: TS3FileEntrySummary

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(entry.name)) {
                    infoRow("Type", value: entry.isDirectory ? "Directory" : "File")
                    infoRow("Remote Path", value: entry.path)
                    infoRow("Parent Path", value: entry.parentPath)
                    infoRow("Channel ID", value: "\(entry.channelId)")
                    if !entry.isDirectory {
                        infoRow("Size", value: Self.sizeText(entry.size))
                    }
                    if entry.isStillUploading {
                        infoRow("Status", value: "Uploading")
                    }
                    if let modifiedAt = entry.modifiedAt {
                        infoRow("Modified", value: Self.dateText(modifiedAt))
                    }
                }
                Section {
                    Button("Copy Remote Path") {
                        TS3PlatformSupport.copyToPasteboard(entry.path)
                    }
                    Button("Copy Name") {
                        TS3PlatformSupport.copyToPasteboard(entry.name)
                    }
                }
            }
            .navigationTitle("File Info")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private static func sizeText(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct UploadConflictSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let message: String
    let canResume: Bool
    let resume: () -> Void
    let overwrite: () -> Void
    let cancel: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Remote Files Exist")) {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Section {
                    Button("Resume Partial Uploads") {
                        resume()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!canResume)
                    Button("Overwrite Remote Files") {
                        overwrite()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                    Button("Cancel") {
                        cancel()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Upload Conflicts")
            .ts3InlineNavigationTitle()
        }
    }
}

struct RenameFileEntrySheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3FileEntrySummary
    @Binding var newName: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(entry.name)) {
                    TextField("New Name", text: $newName)
                        .ts3PlainTextField()
                }
                Section {
                    Button("Rename") {
                        model.renameFileEntry(entry, to: newName)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Rename")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct MoveFileEntrySheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3FileEntrySummary
    @Binding var destinationDirectory: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(entry.name)) {
                    TextField("Destination Directory", text: $destinationDirectory)
                        .ts3PlainTextField()
                    Text("Enter a remote directory path, for example / or /subfolder/.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section {
                    Button("Move") {
                        model.moveFileEntry(entry, toDirectory: destinationDirectory)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(destinationDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Move")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct MoveFileEntriesSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let entries: [TS3FileEntrySummary]
    @Binding var destinationDirectory: String
    let onMove: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("\(entries.count) Selected Entries")) {
                    TextField("Destination Directory", text: $destinationDirectory)
                        .ts3PlainTextField()
                    Text("Enter a remote directory path, for example / or /subfolder/.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Section(header: Text("Entries")) {
                    ForEach(entries) { entry in
                        HStack {
                            Image(systemName: entry.isDirectory ? "folder" : "doc")
                                .foregroundColor(entry.isDirectory ? .accentColor : .secondary)
                            Text(entry.name)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                Section {
                    Button("Move Selected") {
                        onMove()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(entries.isEmpty || destinationDirectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Move Selected")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct PermissionsSheet: View {
    private struct PermissionBackupImportConfirmation: Identifiable {
        let url: URL
        let id = UUID()
    }

    private enum AssignedPermissionFilter: String, CaseIterable, Identifiable {
        case all
        case negated
        case skipped
        case inherited
        case positiveValue
        case zeroValue
        case negativeValue

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Permissions"
            case .negated: return "Negated"
            case .skipped: return "Skipped"
            case .inherited: return "Inherited"
            case .positiveValue: return "Positive Value"
            case .zeroValue: return "Zero Value"
            case .negativeValue: return "Negative Value"
            }
        }

        func matches(_ permission: TS3PermissionSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .negated:
                return permission.isNegated
            case .skipped:
                return permission.isSkipped
            case .inherited:
                return !permission.isNegated && !permission.isSkipped
            case .positiveValue:
                return permission.value > 0
            case .zeroValue:
                return permission.value == 0
            case .negativeValue:
                return permission.value < 0
            }
        }
    }

    private enum AssignedPermissionSortMode: String, CaseIterable, Identifiable {
        case name
        case value
        case flags

        var id: String { rawValue }

        var title: String {
            switch self {
            case .name: return "Name"
            case .value: return "Value"
            case .flags: return "Flags"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var searchText = ""
    @State private var permissionName = ""
    @State private var permissionValue = "0"
    @State private var permissionNegated = false
    @State private var permissionSkip = false
    @State private var assignedSearchText = ""
    @State private var assignedFilter: AssignedPermissionFilter = .all
    @State private var assignedSortMode: AssignedPermissionSortMode = .name
    @State private var assignedSortAscending = true
    @State private var presetName = ""
    @State private var isExportingPermissionSnapshot = false
    @State private var isExportingPermissionBackup = false
    @State private var isExportingPresets = false
    @State private var isImportingPermissions = false
    @State private var isImportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var permissionExportDocument = TS3TextFileDocument()
    @State private var permissionBackupDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()
    @State private var pendingPermissionBackupImport: PermissionBackupImportConfirmation?
    @State private var isConfirmingDeleteVisible = false

    var filteredPermissionInfos: [TS3PermissionInfoSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return model.permissionInfos }
        return model.permissionInfos.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            String($0.id).contains(query) ||
            ($0.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var displayedPermissions: [TS3PermissionSummary] {
        model.permissionEditScope == .ownClient ? model.ownClientPermissions : model.scopedPermissions
    }

    var filteredDisplayedPermissions: [TS3PermissionSummary] {
        let query = assignedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = displayedPermissions.filter { permission in
            assignedFilter.matches(permission) && (
                query.isEmpty
                    || permission.name.localizedCaseInsensitiveContains(query)
                    || String(permission.value).contains(query)
                    || (permission.isNegated && "negated".localizedCaseInsensitiveContains(query))
                    || (permission.isSkipped && "skipped".localizedCaseInsensitiveContains(query))
            )
        }
        return sortedDisplayedPermissions(filtered)
    }

    var visiblePermissionsSnapshot: String {
        filteredDisplayedPermissions.map(\.clipboardSummary).joined(separator: "\n")
    }

    var exportFilename: String {
        switch model.permissionEditScope {
        case .ownClient:
            return "ts3-own-client-permissions"
        case .databaseClient:
            return "ts3-database-client-permissions"
        case .serverGroup:
            return "ts3-server-group-permissions"
        case .channelGroup:
            return "ts3-channel-group-permissions"
        case .channel:
            return "ts3-channel-permissions"
        case .channelClient:
            return "ts3-channel-client-permissions"
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Permission Target")) {
                    Picker("Target", selection: Binding(
                        get: { model.permissionEditScope },
                        set: { model.selectPermissionScope($0) }
                    )) {
                        ForEach(TS3PermissionEditScope.allCases) { scope in
                            Text(scope.title).tag(scope)
                        }
                    }
                    if model.permissionEditScope == .ownClient, let databaseId = model.ownClientDatabaseId {
                        Text("Database ID \(databaseId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if model.permissionEditScope == .databaseClient {
                        if let databaseId = model.selectedDatabaseClientPermissionId {
                            Text("Database ID \(databaseId)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Picker("Database Client", selection: Binding(
                            get: { model.selectedDatabaseClientPermissionId ?? model.selectedDatabaseClient?.id ?? model.databaseClients.first?.id ?? 0 },
                            set: {
                                model.selectedDatabaseClientPermissionId = $0
                                model.refreshSelectedPermissions()
                            }
                        )) {
                            ForEach(model.databaseClients) { record in
                                Text("\(record.nickname) (#\(record.id))").tag(record.id)
                            }
                        }
                    }
                    if model.permissionEditScope == .serverGroup {
                        Picker("Server Group", selection: Binding(
                            get: { model.selectedServerGroupPermissionId ?? model.serverGroups.first?.id ?? 0 },
                            set: {
                                model.selectedServerGroupPermissionId = $0
                                model.refreshSelectedPermissions()
                            }
                        )) {
                            ForEach(model.serverGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                    }
                    if model.permissionEditScope == .channelGroup {
                        Picker("Channel Group", selection: Binding(
                            get: { model.selectedChannelGroupPermissionId ?? model.channelGroups.first?.id ?? 0 },
                            set: {
                                model.selectedChannelGroupPermissionId = $0
                                model.refreshSelectedPermissions()
                            }
                        )) {
                            ForEach(model.channelGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                    }
                    if model.permissionEditScope == .channel {
                        Picker("Channel", selection: Binding(
                            get: { model.selectedChannelPermissionId ?? model.currentChannel?.id ?? model.channels.first?.id ?? 0 },
                            set: {
                                model.selectedChannelPermissionId = $0
                                model.refreshSelectedPermissions()
                            }
                        )) {
                            ForEach(model.channels) { channel in
                                Text(channel.name).tag(channel.id)
                            }
                        }
                    }
                    if model.permissionEditScope == .channelClient {
                        Picker("Channel", selection: Binding(
                            get: { model.selectedChannelClientPermissionChannelId ?? model.currentChannel?.id ?? model.channels.first?.id ?? 0 },
                            set: {
                                model.selectedChannelClientPermissionChannelId = $0
                                model.selectedChannelClientPermissionClientId = model.members(in: $0).first?.id
                                model.refreshSelectedPermissions()
                            }
                        )) {
                            ForEach(model.channels) { channel in
                                Text(channel.name).tag(channel.id)
                            }
                        }
                        Picker("Client", selection: Binding(
                            get: { model.selectedChannelClientPermissionClientId ?? model.channelClientPermissionMembers().first?.id ?? 0 },
                            set: {
                                model.selectedChannelClientPermissionClientId = $0
                                model.refreshSelectedPermissions()
                            }
                        )) {
                            ForEach(model.channelClientPermissionMembers()) { member in
                                Text(member.nickname).tag(member.id)
                            }
                        }
                    }
                }

                Section(header: Text("\(model.permissionEditScope.title) Permissions")) {
                    Button("Copy Visible Permissions") {
                        TS3PlatformSupport.copyToPasteboard(visiblePermissionsSnapshot)
                    }
                    .disabled(filteredDisplayedPermissions.isEmpty)

                    Button("Export Visible Permissions") {
                        permissionExportDocument = TS3TextFileDocument(data: Data(visiblePermissionsSnapshot.utf8))
                        isExportingPermissionSnapshot = true
                    }
                    .disabled(filteredDisplayedPermissions.isEmpty)

                    Button("Export Permission Backup") {
                        exportPermissionBackup()
                    }
                    .disabled(displayedPermissions.isEmpty)

                    Button("Import Permission Backup") {
                        isImportingPermissions = true
                    }

                    Button("Delete Visible Permissions") {
                        isConfirmingDeleteVisible = true
                    }
                    .disabled(filteredDisplayedPermissions.isEmpty)
                    .foregroundColor(.red)

                    Picker("Filter", selection: $assignedFilter) {
                        ForEach(AssignedPermissionFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $assignedSortMode) {
                        ForEach(AssignedPermissionSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $assignedSortAscending)
                    TextField("Search assigned permissions", text: $assignedSearchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.savePermissionFilterPreset(
                                name: presetName,
                                scope: model.permissionEditScope.rawValue,
                                assignedFilter: assignedFilter.rawValue,
                                assignedSortMode: assignedSortMode.rawValue,
                                assignedSortAscending: assignedSortAscending,
                                assignedSearchText: assignedSearchText,
                                permissionSearchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.permissionFilterPresets.isEmpty {
                            Text("No saved permission filter presets")
                        } else {
                            ForEach(model.permissionFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deletePermissionFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.permissionFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.permissionFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasAssignedPermissionOptions {
                        Button("Clear Permission Filters") {
                            assignedFilter = .all
                            assignedSortMode = .name
                            assignedSortAscending = true
                            assignedSearchText = ""
                        }
                    }

                    if displayedPermissions.isEmpty {
                        Text("No permissions")
                            .foregroundColor(.secondary)
                    } else if filteredDisplayedPermissions.isEmpty {
                        Text("No matching permissions")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredDisplayedPermissions) { permission in
                            PermissionRow(permission: permission) {
                                permissionName = permission.name
                                permissionValue = "\(permission.value)"
                                permissionNegated = permission.isNegated
                                permissionSkip = permission.isSkipped
                            } delete: {
                                model.deleteSelectedPermission(permission)
                            }
                        }
                    }
                }

                Section(header: Text("Add Permission")) {
                    TextField("Permission Name", text: $permissionName)
                        .ts3PlainTextField()
                    TextField("Value", text: $permissionValue)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    Toggle("Negated", isOn: $permissionNegated)
                        .disabled(model.permissionEditScope == .ownClient || model.permissionEditScope == .databaseClient || model.permissionEditScope == .channel || model.permissionEditScope == .channelClient)
                    Toggle("Skip", isOn: $permissionSkip)
                        .disabled(model.permissionEditScope == .channel)
                    Button("Add or Update Permission") {
                        model.addSelectedPermission(
                            name: permissionName,
                            value: Int(permissionValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
                            negated: permissionNegated,
                            skip: permissionSkip
                        )
                    }
                    .disabled(permissionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section(header: Text("Permission Directory")) {
                    TextField("Search", text: $searchText)
                        .ts3PlainTextField()
                    if filteredPermissionInfos.isEmpty {
                        Text("No permissions")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredPermissionInfos) { permission in
                            PermissionInfoRow(permission: permission) {
                                permissionName = permission.name
                                searchText = permission.name
                            } copyName: {
                                TS3PlatformSupport.copyToPasteboard(permission.name)
                            } copyId: {
                                TS3PlatformSupport.copyToPasteboard("\(permission.id)")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Permissions")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshPermissionList()
                model.refreshGroups()
                model.refreshSelectedPermissions()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshPermissionList()
                        model.refreshGroups()
                        model.refreshSelectedPermissions()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingPermissionSnapshot,
                document: permissionExportDocument,
                contentType: .plainText,
                defaultFilename: exportFilename
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPermissionBackup,
                document: permissionBackupDocument,
                contentType: .json,
                defaultFilename: "ts3-permission-backup"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-permission-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPermissions,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingPermissionBackupImport = PermissionBackupImportConfirmation(url: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingDeleteVisible) {
                Alert(
                    title: Text("Delete Visible Permissions?"),
                    message: Text("This removes \(filteredDisplayedPermissions.count) permission entries from the current target."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteSelectedPermissions(filteredDisplayedPermissions)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $pendingPermissionBackupImport) { confirmation in
                Alert(
                    title: Text("Import Permission Backup?"),
                    message: Text("This switches the permission target to the selected backup and refreshes its permissions."),
                    primaryButton: .destructive(Text("Import")) {
                        importPermissionBackup(from: confirmation.url)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Permission Filter Presets?"),
                    message: Text("This removes \(model.permissionFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllPermissionFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func exportPermissionBackup() {
        do {
            permissionBackupDocument = TS3TextFileDocument(data: try model.permissionBackupData())
            isExportingPermissionBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private var hasAssignedPermissionOptions: Bool {
        !assignedSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || assignedFilter != .all
            || assignedSortMode != .name
            || !assignedSortAscending
    }

    private func sortedDisplayedPermissions(_ permissions: [TS3PermissionSummary]) -> [TS3PermissionSummary] {
        permissions.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch assignedSortMode {
            case .name:
                comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            case .value:
                comparison = compareInts(lhs.value, rhs.value)
            case .flags:
                comparison = flagText(lhs).localizedCaseInsensitiveCompare(flagText(rhs))
            }

            if comparison == .orderedSame {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return assignedSortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func flagText(_ permission: TS3PermissionSummary) -> String {
        var flags: [String] = []
        if permission.isNegated {
            flags.append("Negated")
        }
        if permission.isSkipped {
            flags.append("Skipped")
        }
        return flags.isEmpty ? "Inherited" : flags.joined(separator: " ")
    }

    private func applyPreset(_ preset: TS3PermissionFilterPreset) {
        if let scope = TS3PermissionEditScope(rawValue: preset.scope) {
            model.selectPermissionScope(scope)
        }
        assignedFilter = AssignedPermissionFilter(rawValue: preset.assignedFilter) ?? .all
        assignedSortMode = AssignedPermissionSortMode(rawValue: preset.assignedSortMode) ?? .name
        assignedSortAscending = preset.assignedSortAscending
        assignedSearchText = preset.assignedSearchText
        searchText = preset.permissionSearchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3PermissionFilterPreset) -> String {
        var parts = [
            (TS3PermissionEditScope(rawValue: preset.scope) ?? .ownClient).title,
            (AssignedPermissionFilter(rawValue: preset.assignedFilter) ?? .all).title,
            "Sort \((AssignedPermissionSortMode(rawValue: preset.assignedSortMode) ?? .name).title)"
        ]
        if !preset.assignedSortAscending {
            parts.append("Descending")
        }
        if !preset.assignedSearchText.isEmpty {
            parts.append("Assigned \(preset.assignedSearchText)")
        }
        if !preset.permissionSearchText.isEmpty {
            parts.append("Directory \(preset.permissionSearchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.permissionFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importPermissionFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPermissionBackup(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importPermissionBackup(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct PermissionRow: View {
    let permission: TS3PermissionSummary
    let edit: () -> Void
    let delete: () -> Void
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(permission.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text("\(permission.value)")
                    .foregroundColor(.secondary)
            }
            HStack(spacing: 10) {
                if permission.isNegated {
                    Text("Negated")
                }
                if permission.isSkipped {
                    Text("Skipped")
                }
                Spacer()
                Button("Edit") {
                    edit()
                }
                .buttonStyle(.borderless)
                Button("Delete") {
                    isConfirmingDelete = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 3)
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete Permission?"),
                message: Text(permission.name),
                primaryButton: .destructive(Text("Delete")) {
                    delete()
                },
                secondaryButton: .cancel()
            )
        }
        .contextMenu {
            Button("Edit Permission") {
                edit()
            }
            Button("Copy Name") {
                TS3PlatformSupport.copyToPasteboard(permission.name)
            }
            Button("Copy Value") {
                TS3PlatformSupport.copyToPasteboard("\(permission.value)")
            }
            Button("Copy Summary") {
                TS3PlatformSupport.copyToPasteboard(permission.clipboardSummary)
            }
            Button("Delete") {
                isConfirmingDelete = true
            }
            .foregroundColor(.red)
        }
    }
}

struct PermissionInfoRow: View {
    let permission: TS3PermissionInfoSummary
    let select: () -> Void
    let copyName: () -> Void
    let copyId: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(permission.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Text("#\(permission.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let description = permission.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Use Permission") {
                select()
            }
            Button("Copy Name") {
                copyName()
            }
            Button("Copy ID") {
                copyId()
            }
        }
    }
}

private extension TS3PermissionSummary {
    var clipboardSummary: String {
        var parts = [
            "name=\(name)",
            "value=\(value)"
        ]
        if isNegated {
            parts.append("negated=true")
        }
        if isSkipped {
            parts.append("skip=true")
        }
        return parts.joined(separator: " ")
    }
}

struct PrivilegeKeysSheet: View {
    private struct KeyBackupImportConfirmation: Identifiable {
        let url: URL
        let id = UUID()
    }

    private enum KeyFilter: String, CaseIterable, Identifiable {
        case all
        case serverGroup
        case channelGroup
        case unknown
        case withDescription
        case withCustomSet

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Keys"
            case .serverGroup: return "Server Group"
            case .channelGroup: return "Channel Group"
            case .unknown: return "Unknown Type"
            case .withDescription: return "With Description"
            case .withCustomSet: return "With Custom Set"
            }
        }

        func matches(_ key: TS3PrivilegeKeySummary) -> Bool {
            switch self {
            case .all:
                return true
            case .serverGroup:
                return key.type == .serverGroup
            case .channelGroup:
                return key.type == .channelGroup
            case .unknown:
                return key.type == nil
            case .withDescription:
                return key.description?.isEmpty == false
            case .withCustomSet:
                return key.customSet?.isEmpty == false
            }
        }
    }

    private enum KeySortMode: String, CaseIterable, Identifiable {
        case created
        case type
        case group
        case channel
        case description

        var id: String { rawValue }

        var title: String {
            switch self {
            case .created: return "Created"
            case .type: return "Type"
            case .group: return "Group"
            case .channel: return "Channel"
            case .description: return "Description"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let initialTargetType: TS3PrivilegeKeyTargetType?
    let initialServerGroupId: Int?
    let initialChannelGroupId: Int?
    let initialChannelId: Int?
    @State private var targetType: TS3PrivilegeKeyTargetType = .serverGroup
    @State private var selectedServerGroupId = 0
    @State private var selectedChannelGroupId = 0
    @State private var selectedChannelId = 0
    @State private var description = ""
    @State private var customSet = ""
    @State private var searchText = ""
    @State private var keyFilter: KeyFilter = .all
    @State private var sortMode: KeySortMode = .created
    @State private var sortAscending = false
    @State private var presetName = ""
    @State private var isExportingKeys = false
    @State private var isExportingKeyBackup = false
    @State private var isImportingKeyBackup = false
    @State private var isExportingPresets = false
    @State private var isImportingPresets = false
    @State private var keysExportDocument = TS3TextFileDocument()
    @State private var keysBackupDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()
    @State private var pendingKeyBackupImport: KeyBackupImportConfirmation?
    @State private var isConfirmingDeleteAll = false
    @State private var isConfirmingDeletePresets = false

    private var privilegeKeysSnapshot: String {
        filteredPrivilegeKeys.map(\.clipboardSummary).joined(separator: "\n")
    }

    init(
        initialTargetType: TS3PrivilegeKeyTargetType? = nil,
        initialServerGroupId: Int? = nil,
        initialChannelGroupId: Int? = nil,
        initialChannelId: Int? = nil
    ) {
        self.initialTargetType = initialTargetType
        self.initialServerGroupId = initialServerGroupId
        self.initialChannelGroupId = initialChannelGroupId
        self.initialChannelId = initialChannelId
    }

    var body: some View {
        NavigationView {
            List {
                if let key = model.generatedPrivilegeKey {
                    Section(header: Text("Generated Key")) {
                        Text(key)
                            .font(.system(.footnote, design: .monospaced))
                            .lineLimit(3)
                        Button("Use Generated Key") {
                            model.usePrivilegeKey(key)
                        }
                        Button("Copy Generated Key") {
                            TS3PlatformSupport.copyToPasteboard(key)
                        }
                    }
                }

                Section(header: Text("Create")) {
                    Picker("Type", selection: $targetType) {
                        ForEach(TS3PrivilegeKeyTargetType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }

                    if targetType == .serverGroup {
                        Picker("Server Group", selection: $selectedServerGroupId) {
                            ForEach(model.serverGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                    } else {
                        Picker("Channel Group", selection: $selectedChannelGroupId) {
                            ForEach(model.channelGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                        Picker("Channel", selection: $selectedChannelId) {
                            ForEach(model.channels) { channel in
                                Text(channel.name).tag(channel.id)
                            }
                        }
                    }

                    TextField("Description", text: $description)
                        .ts3PlainTextField()
                    TextField("Custom Set", text: $customSet)
                        .ts3PlainTextField()
                    Button("Create Privilege Key") {
                        model.createPrivilegeKey(
                            targetType: targetType,
                            groupId: selectedGroupId,
                            channelId: selectedChannelId == 0 ? nil : selectedChannelId,
                            description: description,
                            customSet: customSet
                        )
                        description = ""
                        customSet = ""
                    }
                    .disabled(!canCreate)
                }

                Section(header: Text("Existing Keys")) {
                    Picker("Type", selection: $keyFilter) {
                        ForEach(KeyFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(KeySortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Search keys", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.savePrivilegeKeyFilterPreset(
                                name: presetName,
                                keyFilter: keyFilter.rawValue,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.privilegeKeyFilterPresets.isEmpty {
                            Text("No saved privilege key filter presets")
                        } else {
                            ForEach(model.privilegeKeyFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deletePrivilegeKeyFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.privilegeKeyFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.privilegeKeyFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            keyFilter = .all
                            sortMode = .created
                            sortAscending = false
                            searchText = ""
                        }
                    }

                    Button("Copy Visible Keys") {
                        TS3PlatformSupport.copyToPasteboard(privilegeKeysSnapshot)
                    }
                    .disabled(filteredPrivilegeKeys.isEmpty)

                    Button("Export Visible Keys") {
                        keysExportDocument = TS3TextFileDocument(data: Data(privilegeKeysSnapshot.utf8))
                        isExportingKeys = true
                    }
                    .disabled(filteredPrivilegeKeys.isEmpty)

                    Button("Export Privilege Key Backup") {
                        exportPrivilegeKeyBackup()
                    }
                    .disabled(model.privilegeKeys.isEmpty)

                    Button("Import Privilege Key Backup") {
                        isImportingKeyBackup = true
                    }

                    Button("Delete Visible Keys") {
                        isConfirmingDeleteAll = true
                    }
                    .disabled(filteredPrivilegeKeys.isEmpty)
                    .foregroundColor(.red)

                    if model.privilegeKeys.isEmpty {
                        Text("No privilege keys")
                            .foregroundColor(.secondary)
                    } else if filteredPrivilegeKeys.isEmpty {
                        Text("No matching privilege keys")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredPrivilegeKeys) { key in
                            PrivilegeKeyRow(key: key)
                                .environmentObject(model)
                        }
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingKeys,
                document: keysExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-privilege-keys"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingKeyBackup,
                document: keysBackupDocument,
                contentType: .json,
                defaultFilename: "ts3-privilege-key-backup"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingKeyBackup,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingKeyBackupImport = KeyBackupImportConfirmation(url: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-privilege-key-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingDeleteAll) {
                Alert(
                    title: Text("Delete Visible Privilege Keys?"),
                    message: Text("This removes \(filteredPrivilegeKeys.count) privilege keys from the server."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deletePrivilegeKeys(filteredPrivilegeKeys)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $pendingKeyBackupImport) { confirmation in
                Alert(
                    title: Text("Import Privilege Key Backup?"),
                    message: Text("This loads the first key from the selected backup into the generated key area for copying or use."),
                    primaryButton: .default(Text("Import")) {
                        importPrivilegeKeyBackup(from: confirmation.url)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Privilege Key Filter Presets?"),
                    message: Text("This removes \(model.privilegeKeyFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllPrivilegeKeyFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
            .navigationTitle("Privilege Keys")
            .ts3InlineNavigationTitle()
            .onAppear {
                applyInitialSelection()
                normalizeSelections()
                model.refreshGroups()
                model.refreshPrivilegeKeys()
            }
            .onChange(of: model.serverGroups.map(\.id)) { _ in
                normalizeSelections()
            }
            .onChange(of: model.channelGroups.map(\.id)) { _ in
                normalizeSelections()
            }
            .onChange(of: model.channels.map(\.id)) { _ in
                normalizeSelections()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshGroups()
                        model.refreshPrivilegeKeys()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }

    private var selectedGroupId: Int {
        targetType == .serverGroup ? selectedServerGroupId : selectedChannelGroupId
    }

    private var canCreate: Bool {
        switch targetType {
        case .serverGroup:
            return selectedServerGroupId != 0
        case .channelGroup:
            return selectedChannelGroupId != 0 && selectedChannelId != 0
        }
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || keyFilter != .all || sortMode != .created || sortAscending
    }

    private var filteredPrivilegeKeys: [TS3PrivilegeKeySummary] {
        let keys = model.privilegeKeys.filter { key in
            keyFilter.matches(key) && (
                !isSearching
                    || containsSearch(key.key)
                    || containsSearch(key.description)
                    || containsSearch(key.customSet)
                    || key.type.map { containsSearch($0.title) || String($0.rawValue).contains(normalizedSearchText) } == true
                    || String(key.groupId).contains(normalizedSearchText)
                    || key.channelId.map { String($0).contains(normalizedSearchText) } == true
            )
        }
        return sortedPrivilegeKeys(keys)
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func sortedPrivilegeKeys(_ keys: [TS3PrivilegeKeySummary]) -> [TS3PrivilegeKeySummary] {
        keys.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .created:
                comparison = compareDates(lhs.createdAt, rhs.createdAt)
            case .type:
                comparison = typeText(lhs).localizedCaseInsensitiveCompare(typeText(rhs))
            case .group:
                comparison = compareInts(lhs.groupId, rhs.groupId)
            case .channel:
                comparison = compareOptionalInts(lhs.channelId, rhs.channelId)
            case .description:
                comparison = (lhs.description ?? "").localizedCaseInsensitiveCompare(rhs.description ?? "")
            }

            if comparison == .orderedSame {
                return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compareDates(_ lhs: Date?, _ rhs: Date?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs.compare(rhs)
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        }
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func compareOptionalInts(_ lhs: Int?, _ rhs: Int?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return compareInts(lhs, rhs)
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        }
    }

    private func typeText(_ key: TS3PrivilegeKeySummary) -> String {
        key.type?.title ?? "Unknown"
    }

    private func normalizeSelections() {
        if selectedServerGroupId == 0 || (!model.serverGroups.isEmpty && !model.serverGroups.contains(where: { $0.id == selectedServerGroupId })) {
            selectedServerGroupId = model.serverGroups.first?.id ?? 0
        }
        if selectedChannelGroupId == 0 || (!model.channelGroups.isEmpty && !model.channelGroups.contains(where: { $0.id == selectedChannelGroupId })) {
            selectedChannelGroupId = model.channelGroups.first?.id ?? 0
        }
        if selectedChannelId == 0 || (!model.channels.isEmpty && !model.channels.contains(where: { $0.id == selectedChannelId })) {
            selectedChannelId = model.currentChannel?.id ?? model.channels.first?.id ?? 0
        }
    }

    private func applyInitialSelection() {
        if let initialTargetType {
            targetType = initialTargetType
        }
        if let initialServerGroupId {
            selectedServerGroupId = initialServerGroupId
        }
        if let initialChannelGroupId {
            selectedChannelGroupId = initialChannelGroupId
        }
        if let initialChannelId {
            selectedChannelId = initialChannelId
        }
    }

    private func exportPrivilegeKeyBackup() {
        do {
            keysBackupDocument = TS3TextFileDocument(data: try model.privilegeKeyBackupData())
            isExportingKeyBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPrivilegeKeyBackup(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importPrivilegeKeyBackup(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyPreset(_ preset: TS3PrivilegeKeyFilterPreset) {
        keyFilter = KeyFilter(rawValue: preset.keyFilter) ?? .all
        sortMode = KeySortMode(rawValue: preset.sortMode) ?? .created
        sortAscending = preset.sortAscending
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3PrivilegeKeyFilterPreset) -> String {
        var parts = [
            (KeyFilter(rawValue: preset.keyFilter) ?? .all).title,
            "Sort \((KeySortMode(rawValue: preset.sortMode) ?? .created).title)"
        ]
        if preset.sortAscending {
            parts.append("Ascending")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.privilegeKeyFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importPrivilegeKeyFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

}

struct PrivilegeKeyRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let key: TS3PrivilegeKeySummary
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(key.key)
                        .font(.system(.footnote, design: .monospaced))
                        .lineLimit(3)
                    Text(targetText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let description = key.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let customSet = key.customSet, !customSet.isEmpty {
                        Text(customSet)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Menu {
                    Button("Use Key") {
                        model.usePrivilegeKey(key.key)
                    }
                    Button("Copy Key") {
                        TS3PlatformSupport.copyToPasteboard(key.key)
                    }
                    Button("Delete Key") {
                        isConfirmingDelete = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            if let createdAt = key.createdAt {
                Text(Self.dateText(createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete Privilege Key?"),
                message: Text(key.key),
                primaryButton: .destructive(Text("Delete")) {
                    model.deletePrivilegeKey(key)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var targetText: String {
        switch key.type {
        case .serverGroup:
            return "\(TS3PrivilegeKeyType.serverGroup.title): \(TS3GroupSummary.name(for: key.groupId, in: model.serverGroups))"
        case .channelGroup:
            let group = TS3GroupSummary.name(for: key.groupId, in: model.channelGroups)
            let channel = key.channelId.flatMap { id in model.channels.first { $0.id == id }?.name } ?? "Any Channel"
            return "\(TS3PrivilegeKeyType.channelGroup.title): \(group) in \(channel)"
        case nil:
            return "Unknown Type: Group \(key.groupId)"
        }
    }

    fileprivate static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension TS3PrivilegeKeySummary {
    var clipboardSummary: String {
        var parts = ["key=\(key)"]
        if let type {
            parts.append("type=\(type.title) (\(type.rawValue))")
        }
        parts.append("groupId=\(groupId)")
        if let channelId {
            parts.append("channelId=\(channelId)")
        }
        if let createdAt {
            parts.append("createdAt=\(PrivilegeKeyRow.dateText(createdAt))")
        }
        if let description, !description.isEmpty {
            parts.append("description=\(description)")
        }
        if let customSet, !customSet.isEmpty {
            parts.append("customSet=\(customSet)")
        }
        return parts.joined(separator: " | ")
    }
}

struct BanListSheet: View {
    private struct BanBackupImportConfirmation: Identifiable {
        let url: URL
        let id = UUID()
    }

    private enum BanFilter: String, CaseIterable, Identifiable {
        case all
        case ip
        case name
        case uniqueIdentifier
        case permanent
        case temporary

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Bans"
            case .ip: return "IP"
            case .name: return "Name"
            case .uniqueIdentifier: return "Unique ID"
            case .permanent: return "Permanent"
            case .temporary: return "Temporary"
            }
        }

        func matches(_ entry: TS3BanEntrySummary) -> Bool {
            switch self {
            case .all:
                return true
            case .ip:
                return entry.ip?.isEmpty == false
            case .name:
                return entry.name?.isEmpty == false || entry.lastNickname?.isEmpty == false
            case .uniqueIdentifier:
                return entry.uniqueIdentifier?.isEmpty == false
            case .permanent:
                return entry.durationSeconds == nil || entry.durationSeconds == 0
            case .temporary:
                return (entry.durationSeconds ?? 0) > 0
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isConfirmingDeleteAll = false
    @State private var isConfirmingDeleteVisible = false
    @State private var isExportingBans = false
    @State private var isExportingBanBackup = false
    @State private var isExportingPresets = false
    @State private var isImportingBans = false
    @State private var isImportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var banExportDocument = TS3TextFileDocument()
    @State private var banBackupDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()
    @State private var pendingBanBackupImport: BanBackupImportConfirmation?
    @State private var searchText = ""
    @State private var banFilter: BanFilter = .all
    @State private var presetName = ""
    @State private var ip = ""
    @State private var name = ""
    @State private var uniqueIdentifier = ""
    @State private var reason = ""
    @State private var duration: TS3BanDuration = .permanent
    @State private var customBanMinutes = "60"

    private var visibleBanSnapshot: String {
        filteredBanEntries.map(\.clipboardSummary).joined(separator: "\n")
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add Ban")) {
                    TextField("IP Address", text: $ip)
                        .ts3PlainTextField()
                    TextField("Name", text: $name)
                        .ts3PlainTextField()
                    TextField("Unique ID", text: $uniqueIdentifier)
                        .ts3PlainTextField()
                    TextField("Reason", text: $reason)
                        .ts3PlainTextField()
                    Picker("Duration", selection: $duration) {
                        ForEach(TS3BanDuration.allCases) { duration in
                            Text(duration.title).tag(duration)
                        }
                    }
                    if duration == .custom {
                        TextField("Minutes", text: $customBanMinutes)
                            .ts3PlainTextField()
                            .ts3NumericKeyboard()
                    }
                    Button("Add Ban Rule") {
                        model.addBan(
                            ip: ip,
                            name: name,
                            uniqueIdentifier: uniqueIdentifier,
                            durationSeconds: duration.seconds(customMinutes: customBanMinutes),
                            reason: reason
                        )
                        clearForm()
                    }
                    .disabled(isAddDisabled)
                }

                Section(header: Text("Filters")) {
                    Picker("Type", selection: $banFilter) {
                        ForEach(BanFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    TextField("Search bans", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveBanFilterPreset(
                                name: presetName,
                                banFilter: banFilter.rawValue,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.banFilterPresets.isEmpty {
                            Text("No saved ban filter presets")
                        } else {
                            ForEach(model.banFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteBanFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.banFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.banFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            banFilter = .all
                            searchText = ""
                        }
                    }
                }

                if model.banEntries.isEmpty {
                    Text("No bans")
                        .foregroundColor(.secondary)
                } else {
                    Section(header: Text("Visible Bans")) {
                        Button("Copy Visible Bans") {
                            TS3PlatformSupport.copyToPasteboard(visibleBanSnapshot)
                        }
                        .disabled(filteredBanEntries.isEmpty)
                        Button("Export Visible Bans") {
                            banExportDocument = TS3TextFileDocument(data: Data(visibleBanSnapshot.utf8))
                            isExportingBans = true
                        }
                        .disabled(filteredBanEntries.isEmpty)
                        Button("Export Ban Backup") {
                            exportBanBackup()
                        }
                        .disabled(model.banEntries.isEmpty)
                        Button("Import Ban Backup") {
                            isImportingBans = true
                        }
                        Button("Delete Visible Bans") {
                            isConfirmingDeleteVisible = true
                        }
                        .foregroundColor(.red)
                        .disabled(filteredBanEntries.isEmpty)
                    }

                    if filteredBanEntries.isEmpty {
                        Text("No matching bans")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredBanEntries) { entry in
                            BanEntryRow(entry: entry)
                                .environmentObject(model)
                        }
                    }
                    Section {
                        Button("Delete All Bans") {
                            isConfirmingDeleteAll = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingBans,
                document: banExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-ban-list"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingBanBackup,
                document: banBackupDocument,
                contentType: .json,
                defaultFilename: "ts3-ban-backup"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-ban-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingBans,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingBanBackupImport = BanBackupImportConfirmation(url: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .navigationTitle("Ban List")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshBanList()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshBanList()
                    }
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $isConfirmingDeleteAll) {
                Alert(
                    title: Text("Delete All Bans?"),
                    message: Text("This removes every ban entry on the server."),
                    primaryButton: .destructive(Text("Delete All")) {
                        model.deleteAllBans()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeleteVisible) {
                Alert(
                    title: Text("Delete Visible Bans?"),
                    message: Text("This removes \(filteredBanEntries.count) ban entries from the server."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteBans(filteredBanEntries)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $pendingBanBackupImport) { confirmation in
                Alert(
                    title: Text("Import Ban Backup?"),
                    message: Text("This adds every ban rule from the selected backup to the server."),
                    primaryButton: .destructive(Text("Import")) {
                        importBanBackup(from: confirmation.url)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Ban Filter Presets?"),
                    message: Text("This removes \(model.banFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllBanFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var isAddDisabled: Bool {
        let hasTarget = !ip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !uniqueIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if duration == .custom && TS3BanDuration.customSeconds(from: customBanMinutes) == nil {
            return true
        }
        return !hasTarget
    }

    private func clearForm() {
        ip = ""
        name = ""
        uniqueIdentifier = ""
        reason = ""
        duration = .permanent
        customBanMinutes = "60"
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || banFilter != .all
    }

    private var filteredBanEntries: [TS3BanEntrySummary] {
        return model.banEntries.filter { entry in
            banFilter.matches(entry) && (
                !isSearching
                    || containsSearch(entry.name)
                    || containsSearch(entry.lastNickname)
                    || containsSearch(entry.ip)
                    || containsSearch(entry.uniqueIdentifier)
                    || containsSearch(entry.invokerName)
                    || containsSearch(entry.reason)
            )
        }
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func applyPreset(_ preset: TS3BanFilterPreset) {
        banFilter = BanFilter(rawValue: preset.banFilter) ?? .all
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3BanFilterPreset) -> String {
        var parts = [
            (BanFilter(rawValue: preset.banFilter) ?? .all).title
        ]
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.banFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importBanFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func exportBanBackup() {
        do {
            banBackupDocument = TS3TextFileDocument(data: try model.banBackupData())
            isExportingBanBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importBanBackup(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importBanBackup(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ComplaintListSheet: View {
    private enum ComplaintFilter: String, CaseIterable, Identifiable {
        case all
        case namedSource
        case anonymousSource
        case withMessage
        case withoutMessage
        case withTimestamp

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Complaints"
            case .namedSource: return "Named Source"
            case .anonymousSource: return "Anonymous Source"
            case .withMessage: return "With Message"
            case .withoutMessage: return "Without Message"
            case .withTimestamp: return "With Date"
            }
        }

        func matches(_ entry: TS3ComplaintSummary) -> Bool {
            switch self {
            case .all:
                return true
            case .namedSource:
                return entry.sourceName?.isEmpty == false
            case .anonymousSource:
                return entry.sourceName?.isEmpty != false
            case .withMessage:
                return entry.message?.isEmpty == false
            case .withoutMessage:
                return entry.message?.isEmpty != false
            case .withTimestamp:
                return entry.timestamp != nil
            }
        }
    }

    private enum ComplaintSortMode: String, CaseIterable, Identifiable {
        case date
        case source
        case sourceDatabaseId
        case message

        var id: String { rawValue }

        var title: String {
            switch self {
            case .date: return "Date"
            case .source: return "Source"
            case .sourceDatabaseId: return "Source DB"
            case .message: return "Message"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isConfirmingDeleteAll = false
    @State private var isConfirmingDeleteVisible = false
    @State private var isExportingComplaints = false
    @State private var isExportingPresets = false
    @State private var isImportingPresets = false
    @State private var isConfirmingDeletePresets = false
    @State private var complaintExportDocument = TS3TextFileDocument()
    @State private var presetsDocument = TS3BookmarkFileDocument()
    @State private var searchText = ""
    @State private var complaintFilter: ComplaintFilter = .all
    @State private var sortMode: ComplaintSortMode = .date
    @State private var sortAscending = false
    @State private var presetName = ""

    private var complaintSnapshot: String {
        filteredComplaintEntries.map(\.clipboardSummary).joined(separator: "\n")
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("User")) {
                    if let target = model.complaintTarget {
                        ServerInfoDetailRow(label: "Selected", value: target.nickname)
                        if let databaseId = target.databaseId {
                            ServerInfoDetailRow(label: "Database ID", value: String(databaseId))
                        }
                    }
                    if !model.clients.filter({ !$0.isCurrentUser }).isEmpty {
                        Picker("User", selection: selectedUserId) {
                            ForEach(model.clients.filter { !$0.isCurrentUser }) { user in
                                Text(user.nickname).tag(user.id)
                            }
                        }
                    } else if model.complaintTarget == nil {
                        Text("No other users")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Filters")) {
                    Picker("Type", selection: $complaintFilter) {
                        ForEach(ComplaintFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Sort By", selection: $sortMode) {
                        ForEach(ComplaintSortMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Toggle("Ascending", isOn: $sortAscending)
                    TextField("Search complaints", text: $searchText)
                        .ts3PlainTextField()
                    Menu {
                        TextField("Preset Name", text: $presetName)
                        Button("Save Current Filters") {
                            model.saveComplaintFilterPreset(
                                name: presetName,
                                complaintFilter: complaintFilter.rawValue,
                                sortMode: sortMode.rawValue,
                                sortAscending: sortAscending,
                                searchText: searchText
                            )
                            presetName = ""
                        }
                        .disabled(presetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.complaintFilterPresets.isEmpty {
                            Text("No saved complaint filter presets")
                        } else {
                            ForEach(model.complaintFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyPreset(preset)
                                    }
                                    Button("Use Name") {
                                        presetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteComplaintFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(presetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportPresets()
                        }
                        .disabled(model.complaintFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingPresets = true
                        }
                        Button("Delete All Presets") {
                            isConfirmingDeletePresets = true
                        }
                        .disabled(model.complaintFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            complaintFilter = .all
                            sortMode = .date
                            sortAscending = false
                            searchText = ""
                        }
                    }
                }

                Section(header: Text("Complaints")) {
                    if model.complaintEntries.isEmpty {
                        Text("No complaints")
                            .foregroundColor(.secondary)
                    } else {
                        Button("Copy Visible Complaints") {
                            TS3PlatformSupport.copyToPasteboard(complaintSnapshot)
                        }
                        .disabled(filteredComplaintEntries.isEmpty)

                        Button("Export Visible Complaints") {
                            complaintExportDocument = TS3TextFileDocument(data: Data(complaintSnapshot.utf8))
                            isExportingComplaints = true
                        }
                        .disabled(filteredComplaintEntries.isEmpty)

                        Button("Delete Visible Complaints") {
                            isConfirmingDeleteVisible = true
                        }
                        .foregroundColor(.red)
                        .disabled(filteredComplaintEntries.isEmpty)

                        if filteredComplaintEntries.isEmpty {
                            Text("No matching complaints")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(filteredComplaintEntries) { entry in
                                ComplaintEntryRow(entry: entry)
                                    .environmentObject(model)
                            }
                        }
                    }
                }

                if !model.complaintEntries.isEmpty {
                    Section {
                        Button("Delete All Complaints") {
                            isConfirmingDeleteAll = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingComplaints,
                document: complaintExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-complaints"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresets,
                document: presetsDocument,
                contentType: .json,
                defaultFilename: "ts3-complaint-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .navigationTitle("Complaints")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        if let target = model.complaintTarget {
                            model.refreshComplaints(for: target)
                        }
                    }
                    .disabled(model.complaintTarget == nil)
                }
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $isConfirmingDeleteAll) {
                Alert(
                    title: Text("Delete All Complaints?"),
                    message: Text(model.complaintTarget?.nickname ?? "Selected user"),
                    primaryButton: .destructive(Text("Delete All")) {
                        model.deleteAllComplaintsForCurrentTarget()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeleteVisible) {
                Alert(
                    title: Text("Delete Visible Complaints?"),
                    message: Text(model.complaintTarget?.nickname ?? "Selected user"),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteComplaints(filteredComplaintEntries)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeletePresets) {
                Alert(
                    title: Text("Delete All Complaint Filter Presets?"),
                    message: Text("This removes \(model.complaintFilterPresets.count) saved local filter presets."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAllComplaintFilterPresets()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private var selectedUserId: Binding<Int> {
        Binding(
            get: { model.complaintTarget?.id ?? model.clients.first(where: { !$0.isCurrentUser })?.id ?? 0 },
            set: { userId in
                if let user = model.clients.first(where: { $0.id == userId }) {
                    model.refreshComplaints(for: user)
                }
            }
        )
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var hasLocalFilters: Bool {
        isSearching || complaintFilter != .all || sortMode != .date || sortAscending
    }

    private var filteredComplaintEntries: [TS3ComplaintSummary] {
        let entries = model.complaintEntries.filter { entry in
            complaintFilter.matches(entry) && (
                !isSearching
                    || containsSearch(entry.targetName)
                    || containsSearch(entry.sourceName)
                    || containsSearch(entry.message)
                    || String(entry.targetClientDatabaseId).contains(normalizedSearchText)
                    || String(entry.sourceClientDatabaseId).contains(normalizedSearchText)
            )
        }
        return sortedComplaintEntries(entries)
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private func sortedComplaintEntries(_ entries: [TS3ComplaintSummary]) -> [TS3ComplaintSummary] {
        entries.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }

            let comparison: ComparisonResult
            switch sortMode {
            case .date:
                comparison = compareDates(lhs.timestamp, rhs.timestamp)
            case .source:
                comparison = sourceDisplayName(lhs).localizedCaseInsensitiveCompare(sourceDisplayName(rhs))
            case .sourceDatabaseId:
                comparison = compareInts(lhs.sourceClientDatabaseId, rhs.sourceClientDatabaseId)
            case .message:
                comparison = (lhs.message ?? "").localizedCaseInsensitiveCompare(rhs.message ?? "")
            }

            if comparison == .orderedSame {
                return lhs.sourceClientDatabaseId < rhs.sourceClientDatabaseId
            }
            return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
        }
    }

    private func compareDates(_ lhs: Date?, _ rhs: Date?) -> ComparisonResult {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs.compare(rhs)
        case (nil, nil):
            return .orderedSame
        case (nil, _):
            return .orderedAscending
        case (_, nil):
            return .orderedDescending
        }
    }

    private func compareInts(_ lhs: Int, _ rhs: Int) -> ComparisonResult {
        if lhs == rhs {
            return .orderedSame
        }
        return lhs < rhs ? .orderedAscending : .orderedDescending
    }

    private func sourceDisplayName(_ entry: TS3ComplaintSummary) -> String {
        if let sourceName = entry.sourceName, !sourceName.isEmpty {
            return sourceName
        }
        return "Client DB \(entry.sourceClientDatabaseId)"
    }

    private func applyPreset(_ preset: TS3ComplaintFilterPreset) {
        complaintFilter = ComplaintFilter(rawValue: preset.complaintFilter) ?? .all
        sortMode = ComplaintSortMode(rawValue: preset.sortMode) ?? .date
        sortAscending = preset.sortAscending
        searchText = preset.searchText
        presetName = preset.name
    }

    private func presetSummary(_ preset: TS3ComplaintFilterPreset) -> String {
        var parts = [
            (ComplaintFilter(rawValue: preset.complaintFilter) ?? .all).title,
            "Sort \((ComplaintSortMode(rawValue: preset.sortMode) ?? .date).title)"
        ]
        if preset.sortAscending {
            parts.append("Ascending")
        }
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportPresets() {
        do {
            presetsDocument = TS3BookmarkFileDocument(data: try model.complaintFilterPresetsExportData())
            isExportingPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importComplaintFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ComplaintEntryRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3ComplaintSummary
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.sourceName?.isEmpty == false ? entry.sourceName! : "Client DB \(entry.sourceClientDatabaseId)")
                        .font(.subheadline.weight(.semibold))
                    Text("Source DB \(entry.sourceClientDatabaseId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let timestamp = entry.timestamp {
                    Text(Self.dateText(timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if let message = entry.message, !message.isEmpty {
                Text(message)
            }
            Button("Delete Complaint") {
                isConfirmingDelete = true
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding(.vertical, 4)
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete Complaint?"),
                message: Text(entry.sourceName?.isEmpty == false ? entry.sourceName! : "Client DB \(entry.sourceClientDatabaseId)"),
                primaryButton: .destructive(Text("Delete")) {
                    model.deleteComplaint(entry)
                },
                secondaryButton: .cancel()
            )
        }
        .contextMenu {
            Button("Copy Summary") {
                TS3PlatformSupport.copyToPasteboard(entry.clipboardSummary)
            }
            Button("Copy Source DB") {
                TS3PlatformSupport.copyToPasteboard("\(entry.sourceClientDatabaseId)")
            }
            if let sourceName = entry.sourceName, !sourceName.isEmpty {
                Button("Copy Source Name") {
                    TS3PlatformSupport.copyToPasteboard(sourceName)
                }
            }
            if let message = entry.message, !message.isEmpty {
                Button("Copy Message") {
                    TS3PlatformSupport.copyToPasteboard(message)
                }
            }
            Button("Delete Complaint") {
                isConfirmingDelete = true
            }
            .foregroundColor(.red)
        }
    }

    fileprivate static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension TS3ComplaintSummary {
    var clipboardSummary: String {
        var parts = [
            "sourceDb=\(sourceClientDatabaseId)",
            "targetDb=\(targetClientDatabaseId)"
        ]
        if let sourceName, !sourceName.isEmpty {
            parts.append("sourceName=\(sourceName)")
        }
        if let targetName, !targetName.isEmpty {
            parts.append("targetName=\(targetName)")
        }
        if let timestamp {
            parts.append("timestamp=\(ComplaintEntryRow.dateText(timestamp))")
        }
        if let message, !message.isEmpty {
            parts.append("message=\(message)")
        }
        return parts.joined(separator: " | ")
    }
}

struct BanEntryRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3BanEntrySummary
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if let createdAt = entry.createdAt {
                    Text(Self.dateText(createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let reason = entry.reason, !reason.isEmpty {
                Text(reason)
                    .font(.body)
            }

            VStack(alignment: .leading, spacing: 3) {
                if let duration = entry.durationSeconds {
                    Text("Duration: \(Self.durationText(duration))")
                }
                if let invoker = entry.invokerName, !invoker.isEmpty {
                    Text("Invoker: \(invoker)")
                }
                if let enforcements = entry.enforcements {
                    Text("Enforcements: \(enforcements)")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Button("Delete Ban") {
                isConfirmingDelete = true
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding(.vertical, 4)
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete Ban?"),
                message: Text(title),
                primaryButton: .destructive(Text("Delete")) {
                    model.deleteBan(entry)
                },
                secondaryButton: .cancel()
            )
        }
        .contextMenu {
            Button("Copy Summary") {
                TS3PlatformSupport.copyToPasteboard(entry.clipboardSummary)
            }
            if let ip = entry.ip, !ip.isEmpty {
                Button("Copy IP") {
                    TS3PlatformSupport.copyToPasteboard(ip)
                }
            }
            if let uniqueIdentifier = entry.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                Button("Copy Unique ID") {
                    TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                }
            }
            if let reason = entry.reason, !reason.isEmpty {
                Button("Copy Reason") {
                    TS3PlatformSupport.copyToPasteboard(reason)
                }
            }
            Button("Delete Ban") {
                isConfirmingDelete = true
            }
            .foregroundColor(.red)
        }
    }

    private var title: String {
        if let name = entry.name, !name.isEmpty {
            return name
        }
        if let lastNickname = entry.lastNickname, !lastNickname.isEmpty {
            return lastNickname
        }
        if let ip = entry.ip, !ip.isEmpty {
            return ip
        }
        return "Ban \(entry.id)"
    }

    private var subtitle: String {
        [entry.ip, entry.uniqueIdentifier]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " | ")
    }

    fileprivate static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    fileprivate static func durationText(_ seconds: Int) -> String {
        if seconds == 0 {
            return "Permanent"
        }
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

private extension TS3BanEntrySummary {
    var clipboardSummary: String {
        var parts = ["banId=\(id)"]
        if let name, !name.isEmpty {
            parts.append("name=\(name)")
        }
        if let lastNickname, !lastNickname.isEmpty {
            parts.append("lastNickname=\(lastNickname)")
        }
        if let ip, !ip.isEmpty {
            parts.append("ip=\(ip)")
        }
        if let uniqueIdentifier, !uniqueIdentifier.isEmpty {
            parts.append("uid=\(uniqueIdentifier)")
        }
        if let createdAt {
            parts.append("createdAt=\(BanEntryRow.dateText(createdAt))")
        }
        if let durationSeconds {
            parts.append("duration=\(BanEntryRow.durationText(durationSeconds))")
        }
        if let invokerName, !invokerName.isEmpty {
            parts.append("invoker=\(invokerName)")
        }
        if let enforcements {
            parts.append("enforcements=\(enforcements)")
        }
        if let reason, !reason.isEmpty {
            parts.append("reason=\(reason)")
        }
        return parts.joined(separator: " | ")
    }
}

struct WhisperSheet: View {
    private enum WhisperPresetFilter: String, CaseIterable, Identifiable {
        case all
        case channels
        case users
        case mixed

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "All Presets"
            case .channels: return "Channels"
            case .users: return "Users"
            case .mixed: return "Mixed"
            }
        }

        func includes(_ preset: TS3WhisperPreset) -> Bool {
            switch self {
            case .all:
                return true
            case .channels:
                return !preset.channelIds.isEmpty && preset.clientIds.isEmpty
            case .users:
                return preset.channelIds.isEmpty && !preset.clientIds.isEmpty
            case .mixed:
                return !preset.channelIds.isEmpty && !preset.clientIds.isEmpty
            }
        }
    }

    private enum WhisperPresetSort: String, CaseIterable, Identifiable {
        case updated
        case name
        case targets

        var id: String { rawValue }

        var title: String {
            switch self {
            case .updated: return "Recent"
            case .name: return "Name"
            case .targets: return "Targets"
            }
        }
    }

    private enum WhisperConfirmation: Identifiable {
        case deleteVisiblePresets
        case deleteAllFilterPresets

        var id: String {
            switch self {
            case .deleteVisiblePresets: return "deleteVisiblePresets"
            case .deleteAllFilterPresets: return "deleteAllFilterPresets"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var groupWhisperType: TS3GroupWhisperType = .allClients
    @State private var groupWhisperTarget: TS3GroupWhisperTarget = .currentChannel
    @State private var selectedServerGroupId = 0
    @State private var selectedChannelGroupId = 0
    @State private var selectedWhisperChannelIds: Set<Int> = []
    @State private var selectedWhisperClientIds: Set<Int> = []
    @State private var whisperPresetName = ""
    @State private var presetFilter: WhisperPresetFilter = .all
    @State private var presetSort: WhisperPresetSort = .updated
    @State private var filterPresetName = ""
    @State private var searchText = ""
    @State private var isExportingRoute = false
    @State private var isExportingPresetBackup = false
    @State private var isImportingPresetBackup = false
    @State private var isExportingFilterPresets = false
    @State private var isImportingFilterPresets = false
    @State private var confirmation: WhisperConfirmation?
    @State private var routeDocument = TS3TextFileDocument()
    @State private var presetBackupDocument = TS3TextFileDocument()
    @State private var filterPresetsDocument = TS3BookmarkFileDocument()

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var filteredChannels: [TS3ChannelSummary] {
        guard isSearching else { return model.channels }
        return model.channels.filter { channel in
            containsSearch(channel.name)
                || containsSearch(channel.topic)
                || containsSearch(channel.description)
                || containsSearch(channel.phoneticName)
                || String(channel.id).contains(normalizedSearchText)
        }
    }

    private var filteredUsers: [TS3UserSummary] {
        let users = model.clients.filter { !$0.isCurrentUser }
        guard isSearching else { return users }
        return users.filter { user in
            containsSearch(user.nickname)
                || containsSearch(user.uniqueIdentifier)
                || containsSearch(user.description)
                || containsSearch(user.country)
                || String(user.id).contains(normalizedSearchText)
        }
    }

    private var filteredServerGroups: [TS3GroupSummary] {
        guard isSearching else { return model.serverGroups }
        return model.serverGroups.filter { group in
            containsSearch(group.name)
                || containsSearch(group.typeTitle)
                || String(group.id).contains(normalizedSearchText)
        }
    }

    private var filteredChannelGroups: [TS3GroupSummary] {
        guard isSearching else { return model.channelGroups }
        return model.channelGroups.filter { group in
            containsSearch(group.name)
                || containsSearch(group.typeTitle)
                || String(group.id).contains(normalizedSearchText)
        }
    }

    private var filteredWhisperPresets: [TS3WhisperPreset] {
        let presets = model.whisperPresets.filter { preset in
            presetFilter.includes(preset) && (
                !isSearching
                    || containsSearch(preset.name)
                    || containsSearch(presetSummary(preset))
                    || preset.channelIds.contains { String($0).contains(normalizedSearchText) }
                    || preset.clientIds.contains { String($0).contains(normalizedSearchText) }
            )
        }
        return sortedWhisperPresets(presets)
    }

    private var whisperRouteSnapshot: String {
        [
            "Route: \(model.whisperRouteDescription)",
            "Mode: \(model.whisperRoute == .none ? "Voice" : "Whisper")",
            "Preset Filter: \(presetFilter.title)",
            "Preset Sort: \(presetSort.title)",
            "Group Type: \(groupWhisperType.title)",
            "Group Scope: \(groupWhisperTarget.title)",
            "Selected Channels: \(selectedWhisperChannelIds.count)",
            "Selected Users: \(selectedWhisperClientIds.count)",
            "Presets: \(filteredWhisperPresets.count)",
            "Server Groups: \(filteredServerGroups.count)",
            "Channel Groups: \(filteredChannelGroups.count)",
            "Channels: \(filteredChannels.count)",
            "Users: \(filteredUsers.count)"
        ].joined(separator: "\n")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search")) {
                    TextField("Search whisper targets", text: $searchText)
                        .ts3PlainTextField()
                    Picker("Preset Filter", selection: $presetFilter) {
                        ForEach(WhisperPresetFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    Picker("Preset Sort", selection: $presetSort) {
                        ForEach(WhisperPresetSort.allCases) { sort in
                            Text(sort.title).tag(sort)
                        }
                    }
                    Menu {
                        TextField("Preset Name", text: $filterPresetName)
                        Button("Save Current Filters") {
                            model.saveWhisperFilterPreset(
                                name: filterPresetName,
                                presetFilter: presetFilter.rawValue,
                                presetSort: presetSort.rawValue,
                                searchText: searchText
                            )
                            filterPresetName = ""
                        }
                        .disabled(filterPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        if model.whisperFilterPresets.isEmpty {
                            Text("No saved whisper filter presets")
                        } else {
                            ForEach(model.whisperFilterPresets) { preset in
                                Menu {
                                    Button("Apply Preset") {
                                        applyFilterPreset(preset)
                                    }
                                    Button("Use Name") {
                                        filterPresetName = preset.name
                                    }
                                    Button("Delete Preset") {
                                        model.deleteWhisperFilterPreset(preset)
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(preset.name)
                                        Text(filterPresetSummary(preset))
                                    }
                                }
                            }
                        }
                        Divider()
                        Button("Export Presets") {
                            exportFilterPresets()
                        }
                        .disabled(model.whisperFilterPresets.isEmpty)
                        Button("Import Presets") {
                            isImportingFilterPresets = true
                        }
                        Button("Delete All Presets") {
                            confirmation = .deleteAllFilterPresets
                        }
                        .disabled(model.whisperFilterPresets.isEmpty)
                    } label: {
                        Label("Filter Presets", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    if hasLocalFilters {
                        Button("Clear Filters") {
                            searchText = ""
                            presetFilter = .all
                            presetSort = .updated
                        }
                    }
                    Button("Copy Route Snapshot") {
                        TS3PlatformSupport.copyToPasteboard(whisperRouteSnapshot)
                    }
                    Button("Export Route Snapshot") {
                        routeDocument = TS3TextFileDocument(data: Data(whisperRouteSnapshot.utf8))
                        isExportingRoute = true
                    }
                }

                Section(header: Text("Current Route")) {
                    Text(model.whisperRouteDescription)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Quick Actions")) {
                    Button("Whisper to Current Channel") {
                        model.enableWhisperToCurrentChannel()
                    }
                    .disabled(model.currentChannel == nil)
                    Button("Whisper to Server") {
                        model.enableWhisperToServer()
                    }
                    Button("Voice to Current Channel") {
                        model.disableWhisper()
                    }
                }

                Section(header: Text("Whisper List")) {
                    TextField("Preset Name", text: $whisperPresetName)
                        .ts3PlainTextField()
                    Button("Enable Selected Targets") {
                        model.enableWhisperList(
                            channelIds: selectedWhisperChannelIds,
                            clientIds: selectedWhisperClientIds
                        )
                    }
                    .disabled(selectedWhisperChannelIds.isEmpty && selectedWhisperClientIds.isEmpty)
                    Button("Select Current Route") {
                        selectCurrentWhisperRoute()
                    }
                    .disabled(!canSelectCurrentWhisperRoute)
                    Button("Clear Selected Targets") {
                        selectedWhisperChannelIds = []
                        selectedWhisperClientIds = []
                    }
                    .disabled(selectedWhisperChannelIds.isEmpty && selectedWhisperClientIds.isEmpty)
                    Button("Save Selected Targets") {
                        model.saveWhisperPreset(
                            name: whisperPresetName,
                            channelIds: selectedWhisperChannelIds,
                            clientIds: selectedWhisperClientIds
                        )
                        whisperPresetName = ""
                    }
                    .disabled(whisperPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || (selectedWhisperChannelIds.isEmpty && selectedWhisperClientIds.isEmpty))
                    Button("Export Preset Backup") {
                        exportPresetBackup()
                    }
                    .disabled(model.whisperPresets.isEmpty)
                    Button("Import Preset Backup") {
                        isImportingPresetBackup = true
                    }
                    Menu {
                        Button("Select Visible Presets") {
                            selectVisibleWhisperPresets()
                        }
                        .disabled(filteredWhisperPresets.isEmpty)
                        Button("Delete Visible Presets") {
                            confirmation = .deleteVisiblePresets
                        }
                        .disabled(filteredWhisperPresets.isEmpty)
                    } label: {
                        Label("Visible Presets", systemImage: "checklist")
                    }
                }

                Section(header: Text("Presets")) {
                    if model.whisperPresets.isEmpty {
                        Text("No saved whisper presets")
                            .foregroundColor(.secondary)
                    } else if filteredWhisperPresets.isEmpty {
                        Text("No matching whisper presets")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredWhisperPresets) { preset in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.name)
                                            .font(.subheadline.weight(.semibold))
                                        Text(presetSummary(preset))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Menu {
                                        Button("Enable Preset") {
                                            model.enableWhisperPreset(preset)
                                        }
                                        Button("Select Targets") {
                                            selectedWhisperChannelIds = Set(preset.channelIds)
                                            selectedWhisperClientIds = Set(preset.clientIds)
                                            whisperPresetName = preset.name
                                        }
                                        Button("Delete Preset") {
                                            model.deleteWhisperPreset(preset)
                                        }
                                    } label: {
                                        Image(systemName: "ellipsis.circle")
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Group Whisper")) {
                    Picker("Type", selection: $groupWhisperType) {
                        ForEach(Self.groupWhisperTypes, id: \.rawValue) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    Picker("Scope", selection: $groupWhisperTarget) {
                        ForEach(Self.groupWhisperTargets, id: \.rawValue) { target in
                            Text(target.title).tag(target)
                        }
                    }
                    if groupWhisperType == .serverGroup {
                        Picker("Server Group", selection: $selectedServerGroupId) {
                            ForEach(filteredServerGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                        .disabled(filteredServerGroups.isEmpty)
                    }
                    if groupWhisperType == .channelGroup {
                        Picker("Channel Group", selection: $selectedChannelGroupId) {
                            ForEach(filteredChannelGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                        .disabled(filteredChannelGroups.isEmpty)
                    }
                    Button("Enable Group Whisper") {
                        model.enableGroupWhisper(
                            type: groupWhisperType,
                            target: groupWhisperTarget,
                            targetId: selectedGroupWhisperTargetId
                        )
                    }
                    .disabled(!canEnableGroupWhisper)
                }

                if !model.channels.isEmpty {
                    Section(header: Text("Channels")) {
                        if filteredChannels.isEmpty {
                            Text("No matching channels")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(filteredChannels) { channel in
                                HStack {
                                    Toggle("", isOn: channelSelectionBinding(for: channel.id))
                                        .labelsHidden()
                                    Button(channel.name) {
                                        model.enableWhisperToChannel(id: channel.id)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }

                if !model.clients.isEmpty {
                    Section(header: Text("Users")) {
                        if filteredUsers.isEmpty {
                            Text("No matching users")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(filteredUsers) { user in
                                HStack {
                                    Toggle("", isOn: clientSelectionBinding(for: user.id))
                                        .labelsHidden()
                                    Button(user.nickname) {
                                        model.enableWhisperToClient(user)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Whisper")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshGroups()
                updateSelectedGroups()
            }
            .onChange(of: model.serverGroups.map(\.id)) { _ in
                updateSelectedGroups()
            }
            .onChange(of: model.channelGroups.map(\.id)) { _ in
                updateSelectedGroups()
            }
            .fileExporter(
                isPresented: $isExportingRoute,
                document: routeDocument,
                contentType: .plainText,
                defaultFilename: "ts3-whisper-route"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingPresetBackup,
                document: presetBackupDocument,
                contentType: .json,
                defaultFilename: "ts3-whisper-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingPresetBackup,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importPresetBackup(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingFilterPresets,
                document: filterPresetsDocument,
                contentType: .json,
                defaultFilename: "ts3-whisper-filter-presets"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingFilterPresets,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importFilterPresets(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(item: $confirmation) { confirmation in
                switch confirmation {
                case .deleteVisiblePresets:
                    return Alert(
                        title: Text("Delete Visible Whisper Presets?"),
                        message: Text("This removes \(filteredWhisperPresets.count) saved whisper presets."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteWhisperPresets(filteredWhisperPresets)
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteAllFilterPresets:
                    return Alert(
                        title: Text("Delete All Whisper Filter Presets?"),
                        message: Text("This removes \(model.whisperFilterPresets.count) saved local filter presets."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteAllWhisperFilterPresets()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private func exportPresetBackup() {
        do {
            presetBackupDocument = TS3TextFileDocument(data: try model.whisperPresetBackupData())
            isExportingPresetBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importPresetBackup(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importWhisperPresetBackup(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyFilterPreset(_ preset: TS3WhisperFilterPreset) {
        presetFilter = WhisperPresetFilter(rawValue: preset.presetFilter) ?? .all
        presetSort = WhisperPresetSort(rawValue: preset.presetSort) ?? .updated
        searchText = preset.searchText
        filterPresetName = preset.name
    }

    private func filterPresetSummary(_ preset: TS3WhisperFilterPreset) -> String {
        var parts = [
            (WhisperPresetFilter(rawValue: preset.presetFilter) ?? .all).title,
            "Sort \((WhisperPresetSort(rawValue: preset.presetSort) ?? .updated).title)"
        ]
        if !preset.searchText.isEmpty {
            parts.append("Search \(preset.searchText)")
        }
        return parts.joined(separator: " · ")
    }

    private func exportFilterPresets() {
        do {
            filterPresetsDocument = TS3BookmarkFileDocument(data: try model.whisperFilterPresetsExportData())
            isExportingFilterPresets = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importFilterPresets(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            _ = try model.importWhisperFilterPresets(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private static let groupWhisperTypes: [TS3GroupWhisperType] = [
        .allClients,
        .channelCommander,
        .serverGroup,
        .channelGroup
    ]

    private static let groupWhisperTargets: [TS3GroupWhisperTarget] = [
        .allChannels,
        .currentChannel,
        .parentChannel,
        .allParentChannels,
        .channelFamily,
        .completeChannelFamily,
        .subchannels
    ]

    private var selectedGroupWhisperTargetId: Int {
        switch groupWhisperType {
        case .serverGroup:
            return selectedServerGroupId
        case .channelGroup:
            return selectedChannelGroupId
        case .channelCommander, .allClients:
            return 0
        }
    }

    private var canEnableGroupWhisper: Bool {
        switch groupWhisperType {
        case .serverGroup:
            return selectedServerGroupId != 0
        case .channelGroup:
            return selectedChannelGroupId != 0
        case .channelCommander, .allClients:
            return true
        }
    }

    private var canSelectCurrentWhisperRoute: Bool {
        switch model.whisperRoute {
        case .channel, .client, .list:
            return true
        case .none, .server, .group:
            return false
        }
    }

    private func selectCurrentWhisperRoute() {
        switch model.whisperRoute {
        case let .channel(channelId):
            selectedWhisperChannelIds = [channelId]
            selectedWhisperClientIds = []
        case let .client(clientId):
            selectedWhisperChannelIds = []
            selectedWhisperClientIds = [clientId]
        case let .list(channelIds, clientIds):
            selectedWhisperChannelIds = Set(channelIds)
            selectedWhisperClientIds = Set(clientIds)
        case .none, .server, .group:
            break
        }
    }

    private func selectVisibleWhisperPresets() {
        selectedWhisperChannelIds = Set(filteredWhisperPresets.flatMap(\.channelIds))
        selectedWhisperClientIds = Set(filteredWhisperPresets.flatMap(\.clientIds))
        if filteredWhisperPresets.count == 1, let preset = filteredWhisperPresets.first {
            whisperPresetName = preset.name
        }
    }

    private func containsSearch(_ value: String?) -> Bool {
        guard let value, !normalizedSearchText.isEmpty else { return false }
        return value.lowercased().contains(normalizedSearchText)
    }

    private var hasLocalFilters: Bool {
        isSearching || presetFilter != .all || presetSort != .updated
    }

    private func sortedWhisperPresets(_ presets: [TS3WhisperPreset]) -> [TS3WhisperPreset] {
        presets.sorted { lhs, rhs in
            if lhs.id == rhs.id {
                return false
            }
            switch presetSort {
            case .updated:
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            case .name:
                let comparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
                if comparison == .orderedSame {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return comparison == .orderedAscending
            case .targets:
                let lhsTargets = lhs.channelIds.count + lhs.clientIds.count
                let rhsTargets = rhs.channelIds.count + rhs.clientIds.count
                if lhsTargets == rhsTargets {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhsTargets > rhsTargets
            }
        }
    }

    private func updateSelectedGroups() {
        if selectedServerGroupId == 0 || !model.serverGroups.contains(where: { $0.id == selectedServerGroupId }) {
            selectedServerGroupId = model.serverGroups.first?.id ?? 0
        }
        if selectedChannelGroupId == 0 || !model.channelGroups.contains(where: { $0.id == selectedChannelGroupId }) {
            selectedChannelGroupId = model.channelGroups.first?.id ?? 0
        }
    }

    private func presetSummary(_ preset: TS3WhisperPreset) -> String {
        let channelText = preset.channelIds.count == 1 ? "1 channel" : "\(preset.channelIds.count) channels"
        let userText = preset.clientIds.count == 1 ? "1 user" : "\(preset.clientIds.count) users"
        if preset.channelIds.isEmpty {
            return userText
        }
        if preset.clientIds.isEmpty {
            return channelText
        }
        return "\(channelText), \(userText)"
    }

    private func channelSelectionBinding(for channelId: Int) -> Binding<Bool> {
        Binding(
            get: { selectedWhisperChannelIds.contains(channelId) },
            set: { isSelected in
                if isSelected {
                    selectedWhisperChannelIds.insert(channelId)
                } else {
                    selectedWhisperChannelIds.remove(channelId)
                }
            }
        )
    }

    private func clientSelectionBinding(for clientId: Int) -> Binding<Bool> {
        Binding(
            get: { selectedWhisperClientIds.contains(clientId) },
            set: { isSelected in
                if isSelected {
                    selectedWhisperClientIds.insert(clientId)
                } else {
                    selectedWhisperClientIds.remove(clientId)
                }
            }
        )
    }
}

extension TS3GroupWhisperType {
    var title: String {
        switch self {
        case .serverGroup:
            return "Server Group"
        case .channelGroup:
            return "Channel Group"
        case .channelCommander:
            return "Channel Commander"
        case .allClients:
            return "All Clients"
        }
    }
}

extension TS3GroupWhisperTarget {
    var title: String {
        switch self {
        case .allChannels:
            return "All Channels"
        case .currentChannel:
            return "Current Channel"
        case .parentChannel:
            return "Parent Channel"
        case .allParentChannels:
            return "All Parent Channels"
        case .channelFamily:
            return "Channel Family"
        case .completeChannelFamily:
            return "Complete Channel Family"
        case .subchannels:
            return "Subchannels"
        }
    }
}

struct ServerInfoRows: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        if !model.serverInfo.name.isEmpty {
            HStack {
                Text("Name")
                Spacer()
                Text(model.serverInfo.name)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        if let clientsOnline = model.serverInfo.clientsOnline {
            HStack {
                Text("Clients")
                Spacer()
                if let maxClients = model.serverInfo.maxClients {
                    Text("\(clientsOnline) / \(maxClients)")
                        .foregroundColor(.secondary)
                } else {
                    Text("\(clientsOnline)")
                        .foregroundColor(.secondary)
                }
            }
        }
        if let channelsOnline = model.serverInfo.channelsOnline {
            HStack {
                Text("Channels")
                Spacer()
                Text("\(channelsOnline)")
                    .foregroundColor(.secondary)
            }
        }
        if let uptime = model.serverInfo.uptimeSeconds {
            HStack {
                Text("Uptime")
                Spacer()
                Text(Self.uptimeText(uptime))
                    .foregroundColor(.secondary)
            }
        }
        if let version = model.serverInfo.version, !version.isEmpty {
            HStack {
                Text("Version")
                Spacer()
                Text(version)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        if let message = model.serverInfo.welcomeMessage, !message.isEmpty {
            Text(message)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    static func uptimeText(_ seconds: Int) -> String {
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct IdentitySummaryRows: View {
    @EnvironmentObject private var model: TS3AppModel
    @Binding var importedIdentity: String
    @State private var isConfirmingRegenerate = false
    @State private var targetSecurityLevel = "8"

    var body: some View {
        HStack {
            Text("UID")
            Spacer()
            Text(model.identitySummary.uid.isEmpty ? "Unavailable" : model.identitySummary.uid)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        HStack {
            Text("Security")
            Spacer()
            Text("\(model.identitySummary.securityLevel)")
                .foregroundColor(.secondary)
        }
        Button("Refresh Identity") {
            Task { @MainActor in
                await model.refreshIdentitySummary()
            }
        }
        Button("Copy Identity Backup") {
            model.copyIdentityExport()
        }
        .disabled(model.identitySummary.exportString.isEmpty)
        HStack {
            Text("New Security Level")
            Spacer()
            TextField("8", text: $targetSecurityLevel)
                .multilineTextAlignment(.trailing)
                .ts3NumericKeyboard()
        }
        TextField("Identity Backup", text: $importedIdentity)
            .ts3PlainTextField()
        Button("Import Identity") {
            model.importIdentity(importedIdentity)
            importedIdentity = ""
        }
        .disabled(importedIdentity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        Button("Regenerate Identity") {
            isConfirmingRegenerate = true
        }
        .foregroundColor(.red)
        .disabled(model.state != .disconnected || parsedSecurityLevel == nil)
        .alert(isPresented: $isConfirmingRegenerate) {
            Alert(
                title: Text("Regenerate Identity?"),
                message: Text("This replaces your local identity. Servers will treat you as a different client unless you restore a backup."),
                primaryButton: .destructive(Text("Regenerate")) {
                    model.regenerateIdentity(securityLevel: parsedSecurityLevel ?? 8)
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var parsedSecurityLevel: Int? {
        let trimmed = targetSecurityLevel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let level = Int(trimmed), level >= 0, level <= 32 else {
            return nil
        }
        return level
    }
}

struct IdentityManagementSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var importedIdentity = ""
    @State private var isImportingIdentity = false
    @State private var isExportingIdentity = false
    @State private var isExportingIdentitySnapshot = false
    @State private var identityExportDocument = TS3TextFileDocument()
    @State private var identitySnapshotDocument = TS3TextFileDocument()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Identity")) {
                    IdentitySummaryRows(importedIdentity: $importedIdentity)
                    Button("Copy Identity Snapshot") {
                        model.copyIdentitySnapshot()
                    }
                    Button("Export Identity Snapshot") {
                        exportIdentitySnapshot()
                    }
                    Button("Import Identity Backup") {
                        isImportingIdentity = true
                    }
                    Button("Export Identity Backup") {
                        exportIdentityBackup()
                    }
                    .disabled(model.identitySummary.exportString.isEmpty)
                }
            }
            .navigationTitle("Identity")
            .ts3InlineNavigationTitle()
            .onAppear {
                Task { @MainActor in
                    await model.refreshIdentitySummary()
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImportingIdentity,
                allowedContentTypes: [.plainText, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importIdentity(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingIdentity,
                document: identityExportDocument,
                contentType: .plainText,
                defaultFilename: "ts3-identity-backup"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingIdentitySnapshot,
                document: identitySnapshotDocument,
                contentType: .plainText,
                defaultFilename: "ts3-identity-snapshot"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
        }
    }

    private func exportIdentityBackup() {
        guard !model.identitySummary.exportString.isEmpty else { return }
        identityExportDocument = TS3TextFileDocument(data: Data(model.identitySummary.exportString.utf8))
        isExportingIdentity = true
    }

    private func exportIdentitySnapshot() {
        identitySnapshotDocument = TS3TextFileDocument(data: model.identitySnapshotData())
        isExportingIdentitySnapshot = true
    }

    private func importIdentity(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: url)
            guard let exportString = String(data: data, encoding: .utf8) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            model.importIdentity(exportString)
            importedIdentity = ""
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct ClientMigrationSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isImportingClientPackage = false
    @State private var isExportingClientPackage = false
    @State private var clientPackageDocument = TS3BookmarkFileDocument()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client Package")) {
                    Button("Export Client Package") {
                        exportClientPackage()
                    }
                    Button("Import Client Package") {
                        isImportingClientPackage = true
                    }
                    Text("Client packages include bookmarks, recent servers, contacts, notifications, recovery, audio, status, playback, and whisper presets.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Client Migration")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImportingClientPackage,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importClientPackage(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingClientPackage,
                document: clientPackageDocument,
                contentType: .json,
                defaultFilename: "ts3-client-package"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
        }
    }

    private func exportClientPackage() {
        do {
            clientPackageDocument = TS3BookmarkFileDocument(data: try model.clientMigrationPackageExportData())
            isExportingClientPackage = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importClientPackage(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importClientMigrationPackage(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

struct NotificationSettingsSheet: View {
    private struct NotificationSettingsImportConfirmation: Identifiable {
        let url: URL
        let id = UUID()
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isImportingNotificationSettings = false
    @State private var isExportingNotificationSettings = false
    @State private var isConfirmingResetNotificationSettings = false
    @State private var pendingNotificationSettingsImport: NotificationSettingsImportConfirmation?
    @State private var notificationSettingsDocument = TS3TextFileDocument()

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { model.notificationsEnabled },
            set: { model.setNotificationsEnabled($0) }
        )
    }

    private var privateMessageNotificationsBinding: Binding<Bool> {
        Binding(
            get: { model.privateMessageNotificationsEnabled },
            set: { model.setPrivateMessageNotificationsEnabled($0) }
        )
    }

    private var notificationSoundBinding: Binding<Bool> {
        Binding(
            get: { model.notificationSoundEnabled },
            set: { model.setNotificationSoundEnabled($0) }
        )
    }

    private var pokeNotificationsBinding: Binding<Bool> {
        Binding(
            get: { model.pokeNotificationsEnabled },
            set: { model.setPokeNotificationsEnabled($0) }
        )
    }

    private var activityNotificationsBinding: Binding<Bool> {
        Binding(
            get: { model.activityNotificationsEnabled },
            set: { model.setActivityNotificationsEnabled($0) }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: notificationsBinding)
                    Toggle("Sound", isOn: notificationSoundBinding)
                        .disabled(!model.notificationsEnabled)
                    Toggle("Private Messages", isOn: privateMessageNotificationsBinding)
                        .disabled(!model.notificationsEnabled)
                    Toggle("Pokes", isOn: pokeNotificationsBinding)
                        .disabled(!model.notificationsEnabled)
                    Toggle("Server Activity", isOn: activityNotificationsBinding)
                        .disabled(!model.notificationsEnabled)
                    Text("Notifications are shown when the app is not active.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Presets")) {
                    Button("Direct Messages Preset") {
                        model.applyDirectNotificationPreset()
                    }
                    Button("Silent Direct Messages Preset") {
                        model.applyDirectNotificationPreset(soundEnabled: false)
                    }
                    Button("All Events Preset") {
                        model.applyAllEventsNotificationPreset()
                    }
                    Button("Reset Notification Settings") {
                        isConfirmingResetNotificationSettings = true
                    }
                }

                Section(header: Text("Backup")) {
                    Button("Export Notification Settings") {
                        exportNotificationSettings()
                    }
                    Button("Import Notification Settings") {
                        isImportingNotificationSettings = true
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImportingNotificationSettings,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    pendingNotificationSettingsImport = NotificationSettingsImportConfirmation(url: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingNotificationSettings,
                document: notificationSettingsDocument,
                contentType: .json,
                defaultFilename: "ts3-notification-settings"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingResetNotificationSettings) {
                Alert(
                    title: Text("Reset Notification Settings?"),
                    message: Text("This restores local notification preferences to their default values."),
                    primaryButton: .destructive(Text("Reset")) {
                        model.resetNotificationSettings()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $pendingNotificationSettingsImport) { confirmation in
                Alert(
                    title: Text("Import Notification Settings?"),
                    message: Text("This replaces current local notification preferences with the selected settings file."),
                    primaryButton: .destructive(Text("Import")) {
                        importNotificationSettings(from: confirmation.url)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func exportNotificationSettings() {
        do {
            notificationSettingsDocument = TS3TextFileDocument(data: try model.notificationSettingsExportData())
            isExportingNotificationSettings = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importNotificationSettings(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importNotificationSettings(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }
}

enum ChannelEditorMode {
    case create(parent: TS3ChannelSummary?)
    case edit(TS3ChannelSummary)
}

struct ChannelEditorSheet: View {
    private struct ChannelDraft: Codable {
        var name: String
        var phoneticName: String
        var topic: String
        var description: String
        var password: String
        var clearPassword: Bool
        var channelType: String
        var isDefault: Bool
        var neededTalkPower: String
        var neededSubscribePower: String
        var codec: String
        var codecQuality: String
        var deleteDelaySeconds: String
        var maxClients: String
        var maxFamilyClients: String
        var maxClientsUnlimited: Bool
        var maxFamilyClientsUnlimited: Bool
        var maxFamilyClientsInherited: Bool
        var iconId: String
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let mode: ChannelEditorMode
    @State private var name = ""
    @State private var phoneticName = ""
    @State private var topic = ""
    @State private var description = ""
    @State private var password = ""
    @State private var clearPassword = false
    @State private var channelType: TS3ChannelType = .permanent
    @State private var isDefault = false
    @State private var neededTalkPower = ""
    @State private var neededSubscribePower = ""
    @State private var codec: Int?
    @State private var codecQuality = ""
    @State private var deleteDelaySeconds = ""
    @State private var maxClients = ""
    @State private var maxFamilyClients = ""
    @State private var maxClientsUnlimited = true
    @State private var maxFamilyClientsUnlimited = true
    @State private var maxFamilyClientsInherited = false
    @State private var iconId = ""
    @State private var isShowingIconImporter = false
    @State private var isImportingDraft = false
    @State private var isExportingDraft = false
    @State private var isExportingSnapshot = false
    @State private var draftDocument = TS3TextFileDocument()
    @State private var snapshotDocument = TS3TextFileDocument()

    var title: String {
        switch mode {
        case .create: return "New Channel"
        case .edit: return "Edit Channel"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Draft")) {
                    Button("Copy Channel Snapshot") {
                        TS3PlatformSupport.copyToPasteboard(channelDraftSnapshot)
                    }
                    Button("Export Channel Snapshot") {
                        snapshotDocument = TS3TextFileDocument(data: Data(channelDraftSnapshot.utf8))
                        isExportingSnapshot = true
                    }
                    Button("Export Channel Draft") {
                        exportDraft()
                    }
                    Button("Import Channel Draft") {
                        isImportingDraft = true
                    }
                }

                Section(header: Text("Channel")) {
                    TextField("Name", text: $name)
                    TextField("Phonetic Name", text: $phoneticName)
                    TextField("Topic", text: $topic)
                    TextField("Description", text: $description)
                    if case .edit = mode {
                        Toggle("Clear Password", isOn: $clearPassword)
                    }
                    SecureField("Password", text: $password)
                        .disabled(clearPassword)
                    Picker("Type", selection: $channelType) {
                        ForEach(TS3ChannelType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    if case .edit = mode {
                        Toggle("Default Channel", isOn: $isDefault)
                    }
                    TextField("Icon ID", text: $iconId)
                        .ts3NumericKeyboard()
                    Button {
                        isShowingIconImporter = true
                    } label: {
                        Label("Upload Icon", systemImage: "photo")
                    }
                }

                Section(header: Text("Voice")) {
                    Picker("Codec", selection: $codec) {
                        Text("Unchanged").tag(Int?.none)
                        ForEach(TS3ChannelCodec.allCases) { codec in
                            Text(codec.title).tag(Optional(codec.rawValue))
                        }
                    }
                    Picker("Codec Quality", selection: $codecQuality) {
                        Text("Unchanged").tag("")
                        ForEach(TS3ChannelCodecQuality.allCases) { quality in
                            Text(quality.title).tag(String(quality.value))
                        }
                        if let numericQuality = Int(codecQuality.trimmingCharacters(in: .whitespacesAndNewlines)),
                           TS3ChannelCodecQuality.title(for: numericQuality) == "Unknown (\(numericQuality))" {
                            Text(TS3ChannelCodecQuality.title(for: numericQuality) ?? String(numericQuality)).tag(codecQuality)
                        }
                    }
                    TextField("Needed Talk Power", text: $neededTalkPower)
                        .ts3NumericKeyboard()
                    TextField("Needed Subscribe Power", text: $neededSubscribePower)
                        .ts3NumericKeyboard()
                    TextField("Delete Delay Seconds", text: $deleteDelaySeconds)
                        .ts3NumericKeyboard()
                }

                Section(header: Text("Limits")) {
                    Toggle("Unlimited Clients", isOn: $maxClientsUnlimited)
                    if !maxClientsUnlimited {
                        TextField("Max Clients", text: $maxClients)
                            .ts3NumericKeyboard()
                    }
                    Toggle("Inherit Family Limit", isOn: $maxFamilyClientsInherited)
                    if !maxFamilyClientsInherited {
                        Toggle("Unlimited Family Clients", isOn: $maxFamilyClientsUnlimited)
                        if !maxFamilyClientsUnlimited {
                            TextField("Max Family Clients", text: $maxFamilyClients)
                                .ts3NumericKeyboard()
                        }
                    }
                }
                Section {
                    Button(title) {
                        switch mode {
                        case let .create(parent):
                            model.createChannel(
                                name: name,
                                parentId: parent?.id,
                                password: password.isEmpty ? nil : password,
                                channelType: channelType,
                                phoneticName: phoneticName,
                                topic: topic,
                                description: description,
                                neededTalkPower: parsedOptionalInt(neededTalkPower),
                                neededSubscribePower: parsedOptionalInt(neededSubscribePower),
                                codec: codec,
                                codecQuality: parsedOptionalInt(codecQuality),
                                deleteDelaySeconds: parsedOptionalInt(deleteDelaySeconds),
                                maxClients: parsedOptionalInt(maxClients),
                                maxFamilyClients: parsedOptionalInt(maxFamilyClients),
                                maxClientsUnlimited: maxClientsUnlimited,
                                maxFamilyClientsUnlimited: maxFamilyClientsUnlimited,
                                maxFamilyClientsInherited: maxFamilyClientsInherited,
                                iconId: parsedOptionalInt(iconId)
                            )
                        case let .edit(channel):
                            model.editChannel(
                                channel,
                                name: name,
                                phoneticName: phoneticName,
                                topic: topic,
                                description: description,
                                password: clearPassword ? "" : (password.isEmpty ? nil : password),
                                isDefault: isDefault,
                                channelType: channelType,
                                neededTalkPower: parsedOptionalInt(neededTalkPower),
                                neededSubscribePower: parsedOptionalInt(neededSubscribePower),
                                codec: codec,
                                codecQuality: parsedOptionalInt(codecQuality),
                                deleteDelaySeconds: parsedOptionalInt(deleteDelaySeconds),
                                maxClients: parsedOptionalInt(maxClients),
                                maxFamilyClients: parsedOptionalInt(maxFamilyClients),
                                maxClientsUnlimited: maxClientsUnlimited,
                                maxFamilyClientsUnlimited: maxFamilyClientsUnlimited,
                                maxFamilyClientsInherited: maxFamilyClientsInherited,
                                iconId: parsedOptionalInt(iconId)
                            )
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle(title)
            .ts3InlineNavigationTitle()
            .onAppear {
                if case let .edit(channel) = mode {
                    name = channel.name
                    phoneticName = channel.phoneticName ?? ""
                    topic = channel.topic ?? ""
                    description = channel.description ?? ""
                    clearPassword = false
                    channelType = channelType(for: channel)
                    isDefault = channel.isDefault
                    neededTalkPower = channel.neededTalkPower.map(String.init) ?? ""
                    neededSubscribePower = channel.neededSubscribePower.map(String.init) ?? ""
                    codec = channel.codec
                    codecQuality = channel.codecQuality.map(String.init) ?? ""
                    deleteDelaySeconds = channel.deleteDelaySeconds.map(String.init) ?? ""
                    maxClients = channel.maxClients.map(String.init) ?? ""
                    maxFamilyClients = channel.maxFamilyClients.map(String.init) ?? ""
                    maxClientsUnlimited = channel.maxClientsUnlimited ?? true
                    maxFamilyClientsUnlimited = channel.maxFamilyClientsUnlimited ?? true
                    maxFamilyClientsInherited = channel.maxFamilyClientsInherited ?? false
                    iconId = channel.iconId.map(String.init) ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingIconImporter,
                allowedContentTypes: [.image, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    switch mode {
                    case .create:
                        model.uploadDraftChannelIcon(from: url) { uploadedIconId in
                            iconId = String(uploadedIconId)
                        }
                    case let .edit(channel):
                        model.uploadChannelIcon(from: url, for: channel) { uploadedIconId in
                            iconId = String(uploadedIconId)
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $isImportingDraft,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importDraft(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingDraft,
                document: draftDocument,
                contentType: .json,
                defaultFilename: "ts3-channel-draft"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingSnapshot,
                document: snapshotDocument,
                contentType: .plainText,
                defaultFilename: "ts3-channel-settings"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
        }
    }

    private var currentDraft: ChannelDraft {
        ChannelDraft(
            name: name,
            phoneticName: phoneticName,
            topic: topic,
            description: description,
            password: password,
            clearPassword: clearPassword,
            channelType: channelType.rawValue,
            isDefault: isDefault,
            neededTalkPower: neededTalkPower,
            neededSubscribePower: neededSubscribePower,
            codec: codec.map(String.init) ?? "",
            codecQuality: codecQuality,
            deleteDelaySeconds: deleteDelaySeconds,
            maxClients: maxClients,
            maxFamilyClients: maxFamilyClients,
            maxClientsUnlimited: maxClientsUnlimited,
            maxFamilyClientsUnlimited: maxFamilyClientsUnlimited,
            maxFamilyClientsInherited: maxFamilyClientsInherited,
            iconId: iconId
        )
    }

    private var channelDraftSnapshot: String {
        let draft = currentDraft
        var rows: [(String, String)] = [
            ("Mode", title),
            ("Name", draft.name),
            ("Phonetic Name", draft.phoneticName),
            ("Topic", draft.topic),
            ("Description", draft.description),
            ("Password", draft.clearPassword ? "Clear Password" : (draft.password.isEmpty ? "Unchanged" : "New Password Set")),
            ("Type", channelTypeTitle(draft.channelType)),
            ("Default", draft.isDefault ? "Yes" : "No"),
            ("Needed Talk Power", draft.neededTalkPower),
            ("Needed Subscribe Power", draft.neededSubscribePower),
            ("Codec", codecTitle(for: draft.codec)),
            ("Codec Quality", codecQualityTitle(for: draft.codecQuality)),
            ("Delete Delay Seconds", draft.deleteDelaySeconds),
            ("Max Clients", draft.maxClientsUnlimited ? "Unlimited" : draft.maxClients),
            ("Max Family Clients", draft.maxFamilyClientsInherited ? "Inherited" : (draft.maxFamilyClientsUnlimited ? "Unlimited" : draft.maxFamilyClients)),
            ("Icon ID", draft.iconId)
        ]
        rows.append(("Draft Valid", canSubmit ? "Yes" : "No"))
        return rows.compactMap { label, value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return "\(label): \(trimmed)"
        }.joined(separator: "\n")
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isOptionalInt(neededTalkPower)
            && isOptionalInt(neededSubscribePower)
            && isOptionalInt(codecQuality)
            && isOptionalInt(deleteDelaySeconds)
            && isOptionalInt(iconId)
            && (maxClientsUnlimited || isRequiredInt(maxClients))
            && (maxFamilyClientsInherited || maxFamilyClientsUnlimited || isRequiredInt(maxFamilyClients))
    }

    private func channelType(for channel: TS3ChannelSummary) -> TS3ChannelType {
        if channel.isPermanent {
            return .permanent
        }
        if channel.isSemiPermanent == true {
            return .semiPermanent
        }
        return .temporary
    }

    private func parsedOptionalInt(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : Int(trimmed)
    }

    private func exportDraft() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            draftDocument = TS3TextFileDocument(data: try encoder.encode(currentDraft))
            isExportingDraft = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importDraft(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let draft = try JSONDecoder().decode(ChannelDraft.self, from: Data(contentsOf: url))
            applyDraft(draft)
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func applyDraft(_ draft: ChannelDraft) {
        name = draft.name
        phoneticName = draft.phoneticName
        topic = draft.topic
        description = draft.description
        password = draft.password
        clearPassword = draft.clearPassword
        channelType = TS3ChannelType(rawValue: draft.channelType) ?? .permanent
        isDefault = draft.isDefault
        neededTalkPower = draft.neededTalkPower
        neededSubscribePower = draft.neededSubscribePower
        codec = parsedOptionalInt(draft.codec)
        codecQuality = draft.codecQuality
        deleteDelaySeconds = draft.deleteDelaySeconds
        maxClients = draft.maxClients
        maxFamilyClients = draft.maxFamilyClients
        maxClientsUnlimited = draft.maxClientsUnlimited
        maxFamilyClientsUnlimited = draft.maxFamilyClientsUnlimited
        maxFamilyClientsInherited = draft.maxFamilyClientsInherited
        iconId = draft.iconId
    }

    private func channelTypeTitle(_ rawValue: String) -> String {
        (TS3ChannelType(rawValue: rawValue) ?? .permanent).title
    }

    private func codecTitle(for rawValue: String) -> String {
        TS3ChannelCodec.title(for: Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines))) ?? ""
    }

    private func codecQualityTitle(for rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let numericValue = Int(trimmed) else { return trimmed }
        return TS3ChannelCodecQuality.title(for: numericValue) ?? trimmed
    }

    private func isOptionalInt(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || Int(trimmed) != nil
    }

    private func isRequiredInt(_ text: String) -> Bool {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }
}

struct JoinChannelPasswordSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary
    @Binding var password: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(channel.name)) {
                    SecureField("Password", text: $password)
                }
                Section {
                    Button("Join") {
                        model.joinChannel(channel, password: password)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Channel Password")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ChannelMessageSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary
    @State private var message = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(channel.name)) {
                    TextField("Message", text: $message)
                        .ts3PlainTextField()
                }
                Section {
                    Button("Send Message") {
                        model.sendChannelMessage(message, to: channel)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Channel Message")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct FullChannelInvitePasswordSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary
    @Binding var password: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(channel.name)) {
                    SecureField("Channel Password", text: $password)
                        .ts3PlainTextField()
                }
                Section {
                    Button("Copy Full Invite Link") {
                        model.copyFullInviteLink(for: channel, channelPassword: password)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Full Invite Link")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DefaultChannelPasswordSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary
    @Binding var password: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(channel.name)) {
                    SecureField("Password", text: $password)
                        .ts3PlainTextField()
                    Button("Set Default Channel") {
                        model.setDefaultChannel(channel, password: password)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Default Channel")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct MoveUserPasswordSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let user: TS3UserSummary
    let channel: TS3ChannelSummary
    @Binding var password: String

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(channel.name)) {
                    SecureField("Password", text: $password)
                }
                Section {
                    Button("Move User") {
                        model.moveUser(user, to: channel, password: password)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Channel Password")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct TalkControlBar: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(model.talkStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    model.toggleInputMuted()
                } label: {
                    Label(model.isInputMuted ? "Mic Muted" : "Mic", systemImage: model.isInputMuted ? "mic.slash" : "mic")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                .ts3KeyboardShortcut("toggle-input-muted", in: model)
                Button {
                    model.toggleOutputMuted()
                } label: {
                    Label(model.isOutputMuted ? "Sound Muted" : "Sound", systemImage: model.isOutputMuted ? "speaker.slash" : "speaker.wave.2")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                .ts3KeyboardShortcut("toggle-output-muted", in: model)
                Button {
                    model.isShowingSelfStatus = true
                } label: {
                    Label(model.isAway ? "Away" : "Self", systemImage: model.isAway ? "moon.zzz" : "person.crop.circle")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button {
                    model.isShowingAudioSettings = true
                } label: {
                    Label(model.playbackVolumePercentText, systemImage: "slider.horizontal.3")
                }
                .buttonStyle(TS3BorderedButtonStyle())
            }
            if let error = model.lastError {
                Text(error)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
            Button(action: {
                model.toggleTalking()
            }) {
                Text(model.transmitButtonTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TS3BorderedButtonStyle(isProminent: true))
            .ts3KeyboardShortcut("toggle-talk", in: model)
        }
        .padding()
        .alert(item: $model.microphonePermissionPrompt) { prompt in
            Alert(
                title: Text(prompt.title),
                message: Text(prompt.message),
                primaryButton: .default(Text(prompt.confirmTitle)) {
                    model.confirmMicrophonePermissionPrompt(prompt)
                },
                secondaryButton: .cancel {
                    model.dismissMicrophonePermissionPrompt()
                }
            )
        }
    }
}

struct SelfStatusSheet: View {
    private enum SelfStatusConfirmation: Identifiable {
        case importBackup(URL, applyToServer: Bool)
        case deleteAllProfiles
        case resetPresence

        var id: String {
            switch self {
            case .importBackup(_, let applyToServer): return applyToServer ? "importAndApply" : "importBackup"
            case .deleteAllProfiles: return "deleteAllProfiles"
            case .resetPresence: return "resetPresence"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var nickname = ""
    @State private var descriptionText = ""
    @State private var isAway = false
    @State private var awayMessage = ""
    @State private var isInputMuted = false
    @State private var isOutputMuted = false
    @State private var isChannelCommander = false
    @State private var talkRequestMessage = ""
    @State private var selfIconId = ""
    @State private var statusProfileName = ""
    @State private var isShowingIconImporter = false
    @State private var isShowingAvatarImporter = false
    @State private var isConfirmingClearIcon = false
    @State private var isConfirmingClearAvatar = false
    @State private var isExportingStatus = false
    @State private var isExportingStatusBackup = false
    @State private var isImportingStatus = false
    @State private var isImportingAppliedStatus = false
    @State private var isImportingStatusProfiles = false
    @State private var confirmation: SelfStatusConfirmation?
    @State private var statusDocument = TS3TextFileDocument()
    @State private var statusBackupDocument = TS3TextFileDocument()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Snapshot")) {
                    Button("Copy Status Snapshot") {
                        TS3PlatformSupport.copyToPasteboard(statusSnapshot)
                    }
                    Button("Export Status Snapshot") {
                        statusDocument = TS3TextFileDocument(data: Data(statusSnapshot.utf8))
                        isExportingStatus = true
                    }
                    Button("Export Status Backup") {
                        exportStatusBackup()
                    }
                    Button("Import Status Backup") {
                        isImportingStatus = true
                    }
                    Button("Import and Apply Status") {
                        isImportingAppliedStatus = true
                    }
                    Button("Export Profile Backup") {
                        exportStatusProfiles()
                    }
                    .disabled(model.selfStatusProfiles.isEmpty)
                    Button("Import Profile Backup") {
                        isImportingStatusProfiles = true
                    }
                    if let currentUser {
                        Menu("Copy Identifiers") {
                            Button("Copy Client ID") {
                                TS3PlatformSupport.copyToPasteboard("\(currentUser.id)")
                            }
                            if let databaseId = currentUser.databaseId {
                                Button("Copy Database ID") {
                                    TS3PlatformSupport.copyToPasteboard("\(databaseId)")
                                }
                            }
                            if let uniqueIdentifier = currentUser.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                                Button("Copy Unique ID") {
                                    TS3PlatformSupport.copyToPasteboard(uniqueIdentifier)
                                }
                            }
                            if let avatarHash = currentUser.avatarHash, !avatarHash.isEmpty {
                                Button("Copy Avatar Hash") {
                                    TS3PlatformSupport.copyToPasteboard(avatarHash)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Profiles")) {
                    TextField("Profile Name", text: $statusProfileName)
                        .ts3PlainTextField()
                    Button("Save Current Profile") {
                        model.saveCurrentSelfStatusProfile(name: statusProfileName)
                        statusProfileName = ""
                    }
                    .disabled(statusProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Delete All Profiles") {
                        confirmation = .deleteAllProfiles
                    }
                    .disabled(model.selfStatusProfiles.isEmpty)

                    if model.selfStatusProfiles.isEmpty {
                        Text("No saved status profiles")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.selfStatusProfiles) { profile in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(statusProfileSummary(profile))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button("Apply Profile") {
                                        model.applySelfStatusProfile(profile)
                                        refreshDraft()
                                    }
                                    Button("Rename From Profile") {
                                        statusProfileName = profile.name
                                    }
                                    Button("Delete Profile") {
                                        model.deleteSelfStatusProfile(profile)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Profile")) {
                    TextField("Nickname", text: $nickname)
                        .ts3PlainTextField()
                    Button("Update Nickname") {
                        model.updateNickname(to: nickname)
                    }
                    .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 88)
                    Button("Update Description") {
                        if let currentUser {
                            model.editUserDescription(currentUser, description: descriptionText)
                        }
                    }
                    .disabled(currentUser == nil)
                    Button("Refresh Self Details") {
                        if let currentUser {
                            model.refreshUserDetails(currentUser)
                        }
                    }
                    .disabled(currentUser == nil)
                    Button("Download Avatar") {
                        if let currentUser {
                            model.refreshUserAvatar(currentUser)
                        }
                    }
                    .disabled(currentUser == nil)
                }

                Section(header: Text("Status")) {
                    Toggle("Away", isOn: $isAway)
                    if isAway {
                        TextField("Away Message", text: $awayMessage)
                            .ts3PlainTextField()
                    }
                    Button(isAway ? "Set Away" : "Clear Away") {
                        model.setAway(isAway, message: awayMessage)
                    }
                }

                Section(header: Text("Mute")) {
                    Toggle("Microphone Muted", isOn: inputMutedBinding)
                    Toggle("Output Muted", isOn: outputMutedBinding)
                }

                Section(header: Text("Role")) {
                    Toggle("Channel Commander", isOn: channelCommanderBinding)
                    TextField("Icon ID", text: $selfIconId)
                        .ts3NumericKeyboard()
                    Button("Set Client Icon") {
                        model.setSelfIcon(iconId: Int(selfIconId.trimmingCharacters(in: .whitespacesAndNewlines)))
                    }
                    .disabled(!selfIconId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Int(selfIconId.trimmingCharacters(in: .whitespacesAndNewlines)) == nil)
                    Button("Clear Client Icon") {
                        isConfirmingClearIcon = true
                    }
                    .disabled((currentUser?.iconId ?? 0) == 0)
                    Button {
                        isShowingIconImporter = true
                    } label: {
                        Label("Upload Client Icon", systemImage: "photo")
                    }
                    Button {
                        isShowingAvatarImporter = true
                    } label: {
                        Label("Upload Avatar", systemImage: "person.crop.square")
                    }
                    Button("Clear Avatar") {
                        isConfirmingClearAvatar = true
                    }
                    .disabled(currentUser?.avatarHash?.isEmpty ?? true)
                }

                Section(header: Text("Voice Status")) {
                    if let currentUser {
                        Button(currentUser.isPrioritySpeaker ? "Remove Priority Speaker" : "Grant Priority Speaker") {
                            model.setPrioritySpeaker(!currentUser.isPrioritySpeaker, for: currentUser)
                        }
                        Button(currentUser.isTalker ? "Remove Talker" : "Mark As Talker") {
                            model.setTalker(!currentUser.isTalker, for: currentUser)
                        }
                    } else {
                        Text("Current client unavailable")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Reset Presence State") {
                        confirmation = .resetPresence
                    }
                }

                Section(header: Text("Talk Power")) {
                    TextField("Request Message", text: $talkRequestMessage)
                        .ts3PlainTextField()
                        .disabled(model.isRequestingTalkPower)
                    if model.isRequestingTalkPower {
                        Button("Cancel Talk Request") {
                            model.setTalkRequest(false, message: "")
                        }
                    } else {
                        Button("Request Talk Power") {
                            model.setTalkRequest(true, message: talkRequestMessage)
                        }
                        .disabled(talkRequestMessage.count > 50)
                    }
                }
            }
            .navigationTitle("Self Status")
            .ts3InlineNavigationTitle()
            .onAppear {
                refreshDraft()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingIconImporter,
                allowedContentTypes: [.image, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.uploadSelfIcon(from: url) { uploadedIconId in
                        selfIconId = String(uploadedIconId)
                    }
                }
            }
            .alert(isPresented: $isConfirmingClearIcon) {
                Alert(
                    title: Text("Clear Client Icon"),
                    message: Text("Remove the icon from your current client on this server."),
                    primaryButton: .destructive(Text("Clear")) {
                        model.clearSelfIcon()
                        selfIconId = ""
                    },
                    secondaryButton: .cancel()
                )
            }
            .fileImporter(
                isPresented: $isShowingAvatarImporter,
                allowedContentTypes: [.image, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.uploadSelfAvatar(from: url)
                }
            }
            .alert(isPresented: $isConfirmingClearAvatar) {
                Alert(
                    title: Text("Clear Avatar"),
                    message: Text("Remove the avatar from your current client identity on this server."),
                    primaryButton: .destructive(Text("Clear")) {
                        model.clearSelfAvatar()
                    },
                    secondaryButton: .cancel()
                )
            }
            .fileExporter(
                isPresented: $isExportingStatus,
                document: statusDocument,
                contentType: .plainText,
                defaultFilename: "ts3-self-status"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileExporter(
                isPresented: $isExportingStatusBackup,
                document: statusBackupDocument,
                contentType: .json,
                defaultFilename: "ts3-self-status-backup"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingStatus,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    confirmation = .importBackup(url, applyToServer: false)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingAppliedStatus,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    confirmation = .importBackup(url, applyToServer: true)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingStatusProfiles,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importStatusProfiles(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(item: $confirmation) { confirmation in
                switch confirmation {
                case .importBackup(let url, let applyToServer):
                    return Alert(
                        title: Text(applyToServer ? "Import and Apply Status?" : "Import Status Backup?"),
                        message: Text(applyToServer ? "This replaces local self status settings and applies them to the current server." : "This replaces local self status settings with the selected backup."),
                        primaryButton: .destructive(Text("Import")) {
                            importStatusBackup(from: url, applyToServer: applyToServer)
                        },
                        secondaryButton: .cancel()
                    )
                case .deleteAllProfiles:
                    return Alert(
                        title: Text("Delete All Status Profiles?"),
                        message: Text("This removes \(model.selfStatusProfiles.count) saved local status profiles."),
                        primaryButton: .destructive(Text("Delete")) {
                            model.deleteSelfStatusProfiles(model.selfStatusProfiles)
                        },
                        secondaryButton: .cancel()
                    )
                case .resetPresence:
                    return Alert(
                        title: Text("Reset Presence State?"),
                        message: Text("This clears away, talk request, channel commander, priority speaker, and talker state where available."),
                        primaryButton: .destructive(Text("Reset")) {
                            resetPresenceState()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private var statusSnapshot: String {
        var rows = [
            "Nickname: \(model.nickname)",
            "Away: \(model.isAway ? "Yes" : "No")",
            "Microphone Muted: \(model.isInputMuted ? "Yes" : "No")",
            "Output Muted: \(model.isOutputMuted ? "Yes" : "No")",
            "Channel Commander: \(model.isChannelCommander ? "Yes" : "No")",
            "Requesting Talk Power: \(model.isRequestingTalkPower ? "Yes" : "No")"
        ]
        if !model.awayMessage.isEmpty {
            rows.append("Away Message: \(model.awayMessage)")
        }
        if !model.talkRequestMessage.isEmpty {
            rows.append("Talk Request Message: \(model.talkRequestMessage)")
        }
        rows.append("Saved Profiles: \(model.selfStatusProfiles.count)")
        if let selfUser = model.clients.first(where: { $0.isCurrentUser }) {
            rows.append("Client ID: \(selfUser.id)")
            if let databaseId = selfUser.databaseId {
                rows.append("Database ID: \(databaseId)")
            }
            if let uniqueIdentifier = selfUser.uniqueIdentifier, !uniqueIdentifier.isEmpty {
                rows.append("Unique ID: \(uniqueIdentifier)")
            }
            if let channel = model.channelName(for: selfUser.channelId) {
                rows.append("Channel: \(channel)")
            }
            if let iconId = selfUser.iconId {
                rows.append("Icon ID: \(iconId)")
            }
            if let avatarHash = selfUser.avatarHash, !avatarHash.isEmpty {
                rows.append("Avatar Hash: \(avatarHash)")
            }
            if let avatarURL = selfUser.avatarURL {
                rows.append("Avatar Path: \(avatarURL.path)")
            }
            rows.append("Priority Speaker: \(selfUser.isPrioritySpeaker ? "Yes" : "No")")
            rows.append("Talker: \(selfUser.isTalker ? "Yes" : "No")")
        }
        if !model.identitySummary.uid.isEmpty {
            rows.append("Identity UID: \(model.identitySummary.uid)")
            rows.append("Identity Security Level: \(model.identitySummary.securityLevel)")
        }
        if let currentUserDescription = currentUser?.description, !currentUserDescription.isEmpty {
            rows.append("Description: \(currentUserDescription)")
        }
        return rows.joined(separator: "\n")
    }

    private func refreshDraft() {
        nickname = model.nickname
        descriptionText = currentUser?.description ?? ""
        isAway = model.isAway
        awayMessage = model.awayMessage
        isInputMuted = model.isInputMuted
        isOutputMuted = model.isOutputMuted
        isChannelCommander = model.isChannelCommander
        talkRequestMessage = model.talkRequestMessage
        selfIconId = model.clients.first(where: { $0.isCurrentUser })?.iconId.map(String.init) ?? ""
    }

    private func exportStatusBackup() {
        do {
            statusBackupDocument = TS3TextFileDocument(data: try model.selfStatusBackupData())
            isExportingStatusBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func exportStatusProfiles() {
        do {
            statusBackupDocument = TS3TextFileDocument(data: try model.selfStatusProfilesExportData())
            isExportingStatusBackup = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importStatusBackup(from url: URL, applyToServer: Bool) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: url)
            if applyToServer {
                try model.importAndApplySelfStatusBackup(from: data)
            } else {
                try model.importSelfStatusBackup(from: data)
            }
            refreshDraft()
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importStatusProfiles(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importSelfStatusProfiles(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func resetPresenceState() {
        model.setAway(false, message: "")
        model.setTalkRequest(false, message: "")
        model.setChannelCommander(false)
        if let currentUser {
            model.setPrioritySpeaker(false, for: currentUser)
            model.setTalker(false, for: currentUser)
        }
        refreshDraft()
    }

    private func statusProfileSummary(_ profile: TS3SelfStatusProfile) -> String {
        var parts: [String] = []
        if !profile.status.nickname.isEmpty {
            parts.append(profile.status.nickname)
        }
        parts.append(profile.status.isAway ? "away" : "available")
        if profile.status.isInputMuted {
            parts.append("mic muted")
        }
        if profile.status.isOutputMuted {
            parts.append("sound muted")
        }
        if profile.status.isChannelCommander {
            parts.append("commander")
        }
        if !profile.status.talkRequestMessage.isEmpty {
            parts.append("talk request")
        }
        return parts.joined(separator: ", ")
    }

    private var currentUser: TS3UserSummary? {
        model.clients.first(where: { $0.isCurrentUser })
    }

    private var inputMutedBinding: Binding<Bool> {
        Binding(
            get: { isInputMuted },
            set: { value in
                isInputMuted = value
                model.setInputMuted(value)
            }
        )
    }

    private var outputMutedBinding: Binding<Bool> {
        Binding(
            get: { isOutputMuted },
            set: { value in
                isOutputMuted = value
                model.setOutputMuted(value)
            }
        )
    }

    private var channelCommanderBinding: Binding<Bool> {
        Binding(
            get: { isChannelCommander },
            set: { value in
                isChannelCommander = value
                model.setChannelCommander(value)
            }
        )
    }
}

struct AudioSettingsSheet: View {
    private enum AudioConfirmation: Identifiable {
        case importSettings(URL)
        case importUserPlayback(URL)

        var id: String {
            switch self {
            case .importSettings: return "importSettings"
            case .importUserPlayback: return "importUserPlayback"
            }
        }
    }

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var audioProfileName = ""
    @State private var isExportingAudioSettings = false
    @State private var isImportingAudioSettings = false
    @State private var isImportingAudioProfiles = false
    @State private var isImportingUserPlayback = false
    @State private var isConfirmingDeleteProfiles = false
    @State private var isConfirmingResetAudioSettings = false
    @State private var isConfirmingResetUserPlayback = false
    @State private var audioConfirmation: AudioConfirmation?
    @State private var audioSettingsDocument = TS3TextFileDocument()

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { model.playbackVolume },
            set: { model.updatePlaybackVolume($0) }
        )
    }

    private var inputGainBinding: Binding<Double> {
        Binding(
            get: { model.inputGain },
            set: { model.updateInputGain($0) }
        )
    }

    private var thresholdBinding: Binding<Double> {
        Binding(
            get: { model.voiceActivationThreshold },
            set: { model.updateVoiceActivationThreshold($0) }
        )
    }

    private var prefersSpeakerBinding: Binding<Bool> {
        Binding(
            get: { model.prefersSpeakerOutput },
            set: { model.updatePrefersSpeakerOutput($0) }
        )
    }

    private var selectedInputDeviceBinding: Binding<String> {
        Binding(
            get: { model.audioInputDevices.first(where: { $0.isSelected })?.id ?? "" },
            set: { model.selectAudioInputDevice(id: $0.isEmpty ? nil : $0) }
        )
    }

    private var transmitModeBinding: Binding<TS3AudioTransmitMode> {
        Binding(
            get: { model.audioTransmitMode },
            set: { model.updateAudioTransmitMode($0) }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Snapshot")) {
                    Button("Copy Audio Snapshot") {
                        TS3PlatformSupport.copyToPasteboard(audioSettingsSnapshot)
                    }
                    Button("Export Audio Snapshot") {
                        audioSettingsDocument = TS3TextFileDocument(data: Data(audioSettingsSnapshot.utf8))
                        isExportingAudioSettings = true
                    }
                    Button("Export Audio Settings") {
                        exportAudioSettings()
                    }
                    Button("Import Audio Settings") {
                        isImportingAudioSettings = true
                    }
                }

                Section(header: Text("Profiles")) {
                    TextField("Profile Name", text: $audioProfileName)
                        .ts3PlainTextField()
                    Button("Save Current Profile") {
                        model.saveCurrentAudioProfile(name: audioProfileName)
                        audioProfileName = ""
                    }
                    .disabled(audioProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Export Profile Backup") {
                        exportAudioProfiles()
                    }
                    .disabled(model.audioProfiles.isEmpty)
                    Button("Import Profile Backup") {
                        isImportingAudioProfiles = true
                    }
                    Button("Delete All Profiles") {
                        isConfirmingDeleteProfiles = true
                    }
                    .disabled(model.audioProfiles.isEmpty)

                    if model.audioProfiles.isEmpty {
                        Text("No saved audio profiles")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.audioProfiles) { profile in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(profileSummary(profile))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button("Apply Profile") {
                                        model.applyAudioProfile(profile)
                                    }
                                    Button("Rename From Profile") {
                                        audioProfileName = profile.name
                                    }
                                    Button("Delete Profile") {
                                        model.deleteAudioProfile(profile)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Audio Device")) {
                    audioRouteRow(title: "Input Route", value: model.audioInputRoute)
                    audioRouteRow(title: "Output Route", value: model.audioOutputRoute)
                    Toggle("Default to Speaker", isOn: prefersSpeakerBinding)
                    Picker("Input Device", selection: selectedInputDeviceBinding) {
                        Text("System Default").tag("")
                        ForEach(model.audioInputDevices) { device in
                            Text(device.displayName).tag(device.id)
                        }
                    }
                    .disabled(model.audioInputDevices.isEmpty)
                    Button("Refresh Audio Routes") {
                        model.refreshAudioRoutes()
                    }
                }

                Section(header: Text("Transmit Mode")) {
                    Picker("Mode", selection: transmitModeBinding) {
                        ForEach(TS3AudioTransmitMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    HStack(spacing: 10) {
                        Button("PTT Preset") {
                            model.applyAudioPreset(mode: .pushToTalk, inputGain: 1)
                        }
                        .buttonStyle(.borderless)
                        Button("Voice Preset") {
                            model.applyAudioPreset(mode: .voiceActivation, inputGain: 1, threshold: 0.03)
                        }
                        .buttonStyle(.borderless)
                        Button("Continuous") {
                            model.applyAudioPreset(mode: .continuous, inputGain: 1)
                        }
                        .buttonStyle(.borderless)
                    }
                    .font(.caption)
                    if model.audioTransmitMode == .voiceActivation {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Activation Threshold")
                                Spacer()
                                Text(model.voiceActivationThresholdText)
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: thresholdBinding, in: 0.001...0.5, step: 0.001)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Microphone")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Input Gain")
                            Spacer()
                            Text(model.inputGainPercentText)
                                .foregroundColor(.secondary)
                        }
                        Slider(value: inputGainBinding, in: 0...4, step: 0.05)
                        HStack {
                            Button("50%") {
                                model.updateInputGain(0.5)
                            }
                            Spacer()
                            Button("100%") {
                                model.updateInputGain(1)
                            }
                            Spacer()
                            Button("200%") {
                                model.updateInputGain(2)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Received Audio")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Playback Volume")
                            Spacer()
                            Text(model.playbackVolumePercentText)
                                .foregroundColor(.secondary)
                        }

                        Slider(value: volumeBinding, in: 0...4, step: 0.05)

                        HStack {
                            Button("0%") {
                                model.updatePlaybackVolume(0)
                            }
                            Spacer()
                            Button("100%") {
                                model.updatePlaybackVolume(1)
                            }
                            Spacer()
                            Button("400%") {
                                model.updatePlaybackVolume(4)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("User Playback")) {
                    Button("Copy User Playback Snapshot") {
                        TS3PlatformSupport.copyToPasteboard(userPlaybackSnapshot)
                    }
                    .disabled(model.userPlaybackPreferenceSummaries.isEmpty)
                    Button("Export User Playback Snapshot") {
                        audioSettingsDocument = TS3TextFileDocument(data: Data(userPlaybackSnapshot.utf8))
                        isExportingAudioSettings = true
                    }
                    .disabled(model.userPlaybackPreferenceSummaries.isEmpty)
                    Button("Export User Playback Backup") {
                        exportUserPlayback()
                    }
                    .disabled(model.userPlaybackPreferenceSummaries.isEmpty)
                    Button("Import User Playback Backup") {
                        isImportingUserPlayback = true
                    }
                    Button("Reset User Playback") {
                        isConfirmingResetUserPlayback = true
                    }
                    .disabled(model.userPlaybackPreferenceSummaries.isEmpty)

                    if model.userPlaybackPreferenceSummaries.isEmpty {
                        Text("No per-user playback preferences")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.userPlaybackPreferenceSummaries) { preference in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(preference.nickname ?? preference.key)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(preference.isOnline ? "Online" : "Saved")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text(userPlaybackSummary(preference))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }

                Section {
                    Button("Reset Audio Settings") {
                        isConfirmingResetAudioSettings = true
                    }
                }
            }
            .navigationTitle("Audio Settings")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshAudioRoutes()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .fileExporter(
                isPresented: $isExportingAudioSettings,
                document: audioSettingsDocument,
                contentType: .plainText,
                defaultFilename: "ts3-audio-settings"
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingAudioSettings,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    audioConfirmation = .importSettings(url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingAudioProfiles,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    importAudioProfiles(from: url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .fileImporter(
                isPresented: $isImportingUserPlayback,
                allowedContentTypes: [.json, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    audioConfirmation = .importUserPlayback(url)
                } else if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingResetUserPlayback) {
                Alert(
                    title: Text("Reset User Playback?"),
                    message: Text("This clears all local per-user volume and mute overrides."),
                    primaryButton: .destructive(Text("Reset")) {
                        model.resetUserPlaybackPreferences()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingDeleteProfiles) {
                Alert(
                    title: Text("Delete All Audio Profiles?"),
                    message: Text("This removes \(model.audioProfiles.count) saved local audio profiles."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteAudioProfiles(model.audioProfiles)
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $isConfirmingResetAudioSettings) {
                Alert(
                    title: Text("Reset Audio Settings?"),
                    message: Text("This restores the local audio settings to their defaults."),
                    primaryButton: .destructive(Text("Reset")) {
                        model.resetAudioSettings()
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(item: $audioConfirmation) { confirmation in
                switch confirmation {
                case .importSettings(let url):
                    return Alert(
                        title: Text("Import Audio Settings?"),
                        message: Text("This replaces current local audio settings with the selected settings file."),
                        primaryButton: .destructive(Text("Import")) {
                            importAudioSettings(from: url)
                        },
                        secondaryButton: .cancel()
                    )
                case .importUserPlayback(let url):
                    return Alert(
                        title: Text("Import User Playback Backup?"),
                        message: Text("This replaces all local per-user volume and mute overrides with the selected backup."),
                        primaryButton: .destructive(Text("Import")) {
                            importUserPlayback(from: url)
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
        }
    }

    private func exportAudioSettings() {
        do {
            audioSettingsDocument = TS3TextFileDocument(data: try model.audioSettingsExportData())
            isExportingAudioSettings = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func exportAudioProfiles() {
        do {
            audioSettingsDocument = TS3TextFileDocument(data: try model.audioProfilesExportData())
            isExportingAudioSettings = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func exportUserPlayback() {
        do {
            audioSettingsDocument = TS3TextFileDocument(data: try model.userPlaybackPreferencesExportData())
            isExportingAudioSettings = true
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importAudioSettings(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importAudioSettings(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importAudioProfiles(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importAudioProfiles(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private func importUserPlayback(from url: URL) {
        let canAccess = url.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            try model.importUserPlaybackPreferences(from: Data(contentsOf: url))
        } catch {
            model.lastError = error.localizedDescription
        }
    }

    private var audioSettingsSnapshot: String {
        var rows = [
            "Transmit Mode: \(model.audioTransmitMode.title)",
            "Input Gain: \(model.inputGainPercentText)",
            "Playback Volume: \(model.playbackVolumePercentText)",
            "Input Route: \(model.audioInputRoute)",
            "Output Route: \(model.audioOutputRoute)",
            "Default to Speaker: \(model.prefersSpeakerOutput ? "Yes" : "No")",
            "Saved Profiles: \(model.audioProfiles.count)",
            "User Playback Overrides: \(model.userPlaybackPreferenceSummaries.count)"
        ]
        if model.audioTransmitMode == .voiceActivation {
            rows.append("Voice Activation Threshold: \(model.voiceActivationThresholdText)")
        }
        return rows.joined(separator: "\n")
    }

    private var userPlaybackSnapshot: String {
        model.userPlaybackPreferenceSummaries.map { preference in
            let name = preference.nickname ?? preference.key
            return "\(name): \(userPlaybackSummary(preference))"
        }
        .joined(separator: "\n")
    }

    private func audioRouteRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func profileSummary(_ profile: TS3AudioProfile) -> String {
        let mode = TS3AudioTransmitMode.title(for: profile.transmitMode)
        let input = Self.percentText(profile.inputGain)
        let playback = Self.percentText(profile.playbackVolume)
        let threshold = String(format: "%.3f", profile.voiceActivationThreshold)
        return "\(mode), input \(input), playback \(playback), threshold \(threshold)"
    }

    private static func percentText(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func userPlaybackSummary(_ preference: TS3UserPlaybackPreferenceSummary) -> String {
        let volume = Self.percentText(preference.volume)
        let muted = preference.isMuted ? "muted" : "unmuted"
        return "\(volume), \(muted), key \(preference.key)"
    }
}

struct TS3BorderedButtonStyle: ButtonStyle {
    var isProminent = false

    func makeBody(configuration: Configuration) -> some View {
        let accent = Color.accentColor
        let fill = isProminent ? accent : .clear
        let text = isProminent ? Color.white : accent
        return configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minHeight: 36)
            .background(fill.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(text)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(accent, lineWidth: isProminent ? 0 : 1)
            )
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

enum TS3PlatformSupport {
    static var defaultNickname: String {
        #if targetEnvironment(macCatalyst)
        return "Mac"
        #elseif os(macOS)
        return Host.current().localizedName ?? "Mac"
        #else
        return "iOS"
        #endif
    }

    static var toolbarLeadingPlacement: ToolbarItemPlacement {
        #if targetEnvironment(macCatalyst)
        return .automatic
        #elseif os(macOS)
        return .automatic
        #else
        return .navigationBarLeading
        #endif
    }

    static var toolbarTrailingPlacement: ToolbarItemPlacement {
        #if targetEnvironment(macCatalyst)
        return .automatic
        #elseif os(macOS)
        return .automatic
        #else
        return .navigationBarTrailing
        #endif
    }

    static func copyToPasteboard(_ string: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        #elseif canImport(UIKit)
        UIPasteboard.general.string = string
        #endif
    }

    static func openURL(_ url: URL) {
        #if targetEnvironment(macCatalyst)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #elseif canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }

    static func openMicrophoneSettings() {
        #if targetEnvironment(macCatalyst)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            UIApplication.shared.open(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
        #elseif canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

extension View {
    @ViewBuilder
    func ts3InlineNavigationTitle() -> some View {
        #if os(macOS)
        self
        #else
        self.navigationBarTitleDisplayMode(.inline)
        #endif
    }

    @ViewBuilder
    func ts3URLTextField() -> some View {
        #if os(iOS)
        self
            .textContentType(.URL)
            .autocapitalization(.none)
            .disableAutocorrection(true)
        #else
        self
        #endif
    }

    @ViewBuilder
    func ts3PlainTextField() -> some View {
        #if os(iOS)
        self
            .autocapitalization(.none)
            .disableAutocorrection(true)
        #else
        self
        #endif
    }

    @ViewBuilder
    func ts3NumericKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func ts3ChannelListStyle() -> some View {
        #if os(macOS)
        self.listStyle(.inset)
        #else
        self.listStyle(.insetGrouped)
        #endif
    }
}
