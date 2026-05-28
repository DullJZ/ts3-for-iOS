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
                    debugButton
                        .buttonStyle(TS3BorderedButtonStyle())
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Group {
                    switch model.state {
                    case .disconnected:
                        ConnectView()
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
        }
        .ts3InlineNavigationTitle()
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
    @EnvironmentObject private var model: TS3AppModel
    @State private var bookmarkName = ""
    @State private var serverURLText = ""
    @State private var editingBookmark: TS3BookmarkSummary?
    @State private var isShowingIdentity = false
    @State private var isShowingBookmarkImporter = false
    @State private var isExportingBookmarks = false
    @State private var bookmarkExportDocument = TS3BookmarkFileDocument()

    var body: some View {
        Form {
            if !model.bookmarks.isEmpty {
                Section(header: Text("Bookmarks")) {
                    ForEach(model.bookmarks) { bookmark in
                        HStack {
                            Button {
                                model.applyBookmark(bookmark)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bookmark.name)
                                    Text("\(bookmark.host):\(bookmark.port)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.borderless)
                            Spacer()
                            Button {
                                model.copyInviteLink(for: bookmark)
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
                Button("Save Current Server") {
                    model.saveCurrentBookmark(name: bookmarkName)
                    bookmarkName = ""
                }
                .disabled(model.serverHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Copy Invite Link") {
                    model.copyCurrentInviteLink()
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
        .navigationTitle("TS3 Connect")
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
    @EnvironmentObject private var model: TS3AppModel
    @State private var isShowingServerTools = false
    @State private var isShowingChat = false
    @State private var isShowingEvents = false
    @State private var isShowingWhisper = false
    @State private var isShowingCreateChannel = false
    @State private var channelSearchText = ""

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
                    model.disconnect()
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
        .sheet(isPresented: $isShowingCreateChannel) {
            ChannelEditorSheet(mode: .create(parent: model.currentChannel))
                .environmentObject(model)
        }
    }

    private var channelTree: [ChannelTreeItem] {
        ChannelTreeItem.flatten(channels: filteredChannels)
    }

    private var channelSectionTitle: String {
        isSearching ? "Search Results" : "Channels"
    }

    private var isSearching: Bool {
        !normalizedSearchText.isEmpty
    }

    private var normalizedSearchText: String {
        channelSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var filteredChannels: [TS3ChannelSummary] {
        guard isSearching else { return model.channels }
        let matchingChannelIds = Set(model.channels.filter(channelMatchesSearch).map(\.id))
        let matchingMemberChannelIds = Set(model.clients.filter(userMatchesSearch).map(\.channelId))
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

    private func members(in channelId: Int) -> [TS3UserSummary] {
        let members = model.members(in: channelId)
        guard isSearching, !channelMatchesSearch(model.channels.first { $0.id == channelId }) else {
            return members
        }
        return members.filter(userMatchesSearch)
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
    let channel: TS3ChannelSummary
    let depth: Int

    var id: Int { channel.id }

    static func flatten(channels: [TS3ChannelSummary]) -> [ChannelTreeItem] {
        let children = Dictionary(grouping: channels) { channel in
            normalizedParentId(channel.parentId)
        }
        var visited: Set<Int> = []
        var result: [ChannelTreeItem] = []

        appendChildren(
            of: nil,
            depth: 0,
            children: children,
            visited: &visited,
            result: &result
        )

        let remaining = channels
            .filter { !visited.contains($0.id) }
            .sorted(by: stableChannelSort)
        for channel in remaining {
            appendChannel(
                channel,
                depth: 0,
                children: children,
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
        visited: inout Set<Int>,
        result: inout [ChannelTreeItem]
    ) {
        let sortedChildren = orderedSiblings(children[parentId] ?? [])
        for channel in sortedChildren {
            appendChannel(
                channel,
                depth: depth,
                children: children,
                visited: &visited,
                result: &result
            )
        }
    }

    private static func appendChannel(
        _ channel: TS3ChannelSummary,
        depth: Int,
        children: [Int?: [TS3ChannelSummary]],
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
            visited: &visited,
            result: &result
        )
    }

    private static func normalizedParentId(_ parentId: Int?) -> Int? {
        guard let parentId, parentId > 0 else { return nil }
        return parentId
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
    @State private var isShowingJoinPassword = false
    @State private var isShowingInfo = false
    @State private var isShowingEdit = false
    @State private var isShowingMove = false
    @State private var isConfirmingDelete = false

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
                    Button("Move Channel") {
                        isShowingMove = true
                    }
                    Button("Set as Default Channel") {
                        model.setDefaultChannel(channel)
                    }
                    Button("Whisper to Channel") {
                        model.enableWhisperToChannel(id: channel.id)
                    }
                    Button("Delete Channel") {
                        isConfirmingDelete = true
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
        .sheet(isPresented: $isShowingInfo) {
            ChannelInformationSheet(channel: channel, memberCount: members.count)
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
        .alert(isPresented: $isConfirmingDelete) {
            Alert(
                title: Text("Delete Channel"),
                message: Text(channel.name),
                primaryButton: .destructive(Text("Delete")) {
                    model.deleteChannel(channel)
                },
                secondaryButton: .cancel()
            )
        }
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

    var body: some View {
        NavigationView {
            Form {
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
                    ServerInfoDetailRow(label: "Codec", value: channel.codec.map(String.init))
                    ServerInfoDetailRow(label: "Codec Quality", value: channel.codecQuality.map(String.init))
                    ServerInfoDetailRow(label: "Needed Talk Power", value: channel.neededTalkPower.map(String.init))
                    ServerInfoDetailRow(label: "Needed Subscribe Power", value: channel.neededSubscribePower.map(String.init))
                }

                Section(header: Text("Limits")) {
                    ServerInfoDetailRow(label: "Max Clients", value: maxClientsText)
                    ServerInfoDetailRow(label: "Max Family Clients", value: maxFamilyClientsText)
                    ServerInfoDetailRow(label: "Delete Delay", value: channel.deleteDelaySeconds.map { "\($0)s" })
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
    @State private var passwordMoveChannel: TS3ChannelSummary?
    @State private var movePassword = ""

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
                Button("Download Avatar") {
                    model.refreshUserAvatar(member)
                }
                Button("Edit Description") {
                    actionMode = .editDescription
                }
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
        case .privateMessage, .poke, .complain:
            return textIsEmpty
        case .offlineMessage:
            return textIsEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .editDescription, .contactNote, .kickChannel, .kickServer:
            return false
        case .ban:
            return banDuration == .custom && TS3BanDuration.customSeconds(from: customBanMinutes) == nil
        }
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
            ServerInfoDetailRow(label: "Channel Commander", value: user.isChannelCommander ? "Yes" : "No")
            ServerInfoDetailRow(label: "Talker", value: user.isTalker ? "Yes" : "No")
            ServerInfoDetailRow(label: "Requests Talk Power", value: user.isRequestingTalkPower ? "Yes" : "No")
            ServerInfoDetailRow(label: "Talk Power", value: user.talkPower.map(String.init))
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel

    private var notedContacts: [TS3ContactEntry] {
        model.contacts
            .filter { !$0.note.isEmpty && $0.status == .neutral }
            .sorted { $0.nickname.localizedCaseInsensitiveCompare($1.nickname) == .orderedAscending }
    }

    var body: some View {
        NavigationView {
            List {
                contactSection(title: "Friends", contacts: model.friendContacts)
                contactSection(title: "Blocked", contacts: model.blockedContacts)
                contactSection(title: "Notes", contacts: notedContacts)
            }
            .navigationTitle("Contacts")
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

    @ViewBuilder
    private func contactSection(title: String, contacts: [TS3ContactEntry]) -> some View {
        Section(header: Text(title)) {
            if contacts.isEmpty {
                Text("No contacts")
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
            }
            Spacer()
            Menu {
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
            ContactEditorSheet(contact: contact)
                .environmentObject(model)
        }
        .contextMenu {
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
    @EnvironmentObject private var model: TS3AppModel
    let contact: TS3ContactEntry
    @State private var status: TS3ContactStatus
    @State private var note: String

    init(contact: TS3ContactEntry) {
        self.contact = contact
        _status = State(initialValue: contact.status)
        _note = State(initialValue: contact.note)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(contact.nickname)) {
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
                        model.updateContact(contact, status: status, note: note)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Edit Contact")
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var message = ""
    @State private var target: TS3TextMessageTargetMode = .channel
    @State private var selectedPrivateClientId = 0
    @State private var filter: ChatMessageFilter = .all
    @State private var searchText = ""
    @State private var isShowingOfflineMessages = false
    @State private var isConfirmingClearHistory = false
    @State private var isExportingTranscript = false
    @State private var transcriptDocument = TS3TextFileDocument()

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

                    TextField("Search chat", text: $searchText)
                        .textFieldStyle(.roundedBorder)
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
                    Button("Clear") {
                        isConfirmingClearHistory = true
                    }
                    .disabled(model.chatMessages.isEmpty)
                    Button("Export") {
                        transcriptDocument = TS3TextFileDocument(data: model.chatTranscriptData(messages: filteredMessages))
                        isExportingTranscript = true
                    }
                    .disabled(filteredMessages.isEmpty)
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
            && (target != .client || selectedPrivateClient != nil)
    }

    private var filteredMessages: [TS3ChatMessageSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return model.chatMessages.filter { item in
            filter.includes(item.targetMode)
                && (query.isEmpty
                    || item.senderName.localizedCaseInsensitiveContains(query)
                    || item.message.localizedCaseInsensitiveContains(query))
        }
    }

    private var emptyMessageText: String {
        model.chatMessages.isEmpty ? "No chat messages" : "No matching messages"
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Activity")) {
                    if model.activityEvents.isEmpty {
                        Text("No activity")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.activityEvents) { event in
                            ActivityEventRow(event: event)
                                .environmentObject(model)
                        }
                    }
                }
                Section(header: Text("Pokes")) {
                    if model.pokeEvents.isEmpty {
                        Text("No pokes")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.pokeEvents) { poke in
                            PokeEventRow(poke: poke)
                                .environmentObject(model)
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.markPokesRead()
            }
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
        switch event.kind {
        case .clientEntered:
            return "joined \(channelText(event.toChannelId))"
        case .clientLeft:
            return "left \(channelText(event.fromChannelId))"
        case .clientMoved:
            return "moved from \(channelText(event.fromChannelId)) to \(channelText(event.toChannelId))"
        case .channelCreated:
            return "created \(affectedChannelText)"
        case .channelEdited:
            return "edited \(affectedChannelText)"
        case .channelDeleted:
            return "deleted \(affectedChannelText)"
        case .channelMoved:
            return "moved \(affectedChannelText) to \(channelText(event.toChannelId))"
        case .channelPasswordChanged:
            return "changed the password for \(affectedChannelText)"
        case .channelDescriptionChanged:
            return "changed the description for \(affectedChannelText)"
        }
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
                Text(poke.senderName)
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        NavigationView {
            List {
                if model.offlineMessages.isEmpty {
                    Text("No offline messages")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(model.offlineMessages) { message in
                        OfflineMessageRow(message: message)
                            .environmentObject(model)
                    }
                }
            }
            .navigationTitle("Inbox")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshOfflineMessages()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshOfflineMessages()
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
            }

            HStack {
                if canReply {
                    Button("Reply") {
                        isShowingReply = true
                    }
                    .buttonStyle(.borderless)
                }
                Button(message.isRead ? "Mark Unread" : "Mark Read") {
                    model.markOfflineMessage(message, read: !message.isRead)
                }
                .buttonStyle(.borderless)
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var nickname = ""
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

    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { model.notificationsEnabled },
            set: { model.setNotificationsEnabled($0) }
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

                Section(header: Text("Profile")) {
                    TextField("Nickname", text: $nickname)
                        .ts3PlainTextField()
                    Button("Apply Nickname") {
                        model.updateNickname(to: nickname.isEmpty ? model.nickname : nickname)
                    }
                    TextField("Away Message", text: $model.awayMessage)
                    Button(model.isAway ? "Clear Away" : "Set Away") {
                        model.toggleAway()
                    }
                    Button(model.isInputMuted ? "Unmute Microphone" : "Mute Microphone") {
                        model.toggleInputMuted()
                    }
                    Button(model.isOutputMuted ? "Unmute Sound" : "Mute Sound") {
                        model.toggleOutputMuted()
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle("Private Messages and Pokes", isOn: notificationsBinding)
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
        }
    }
}

struct ServerLogsSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var lineLimit = "100"
    @State private var reverseOrder = true
    @State private var instanceLogs = false
    @State private var newLogLevel: TS3LogLevel = .info
    @State private var newLogMessage = ""
    @State private var isExportingLogs = false
    @State private var logExportDocument = TS3TextFileDocument()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Controls")) {
                    TextField("Lines", text: $lineLimit)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    Toggle("Reverse Order", isOn: $reverseOrder)
                    Toggle("Instance Logs", isOn: $instanceLogs)
                    Button("Refresh") {
                        model.refreshServerLogs(
                            limit: parsedLineLimit,
                            reverse: reverseOrder,
                            instance: instanceLogs
                        )
                    }
                    Button("Copy Visible Logs") {
                        TS3PlatformSupport.copyToPasteboard(Self.transcript(from: model.serverLogEntries))
                    }
                    .disabled(model.serverLogEntries.isEmpty)
                    Button("Export Visible Logs") {
                        logExportDocument = TS3TextFileDocument(data: Data(Self.transcript(from: model.serverLogEntries).utf8))
                        isExportingLogs = true
                    }
                    .disabled(model.serverLogEntries.isEmpty)
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
                    if model.serverLogEntries.isEmpty {
                        Text("No log entries")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.serverLogEntries) { entry in
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
        }
    }

    private var parsedLineLimit: Int {
        Int(lineLimit.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 100
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
                    ServerInfoDetailRow(label: "Codec Encryption", value: model.serverInfo.codecEncryptionMode.map(String.init))
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

                Section(header: Text("Host Presentation")) {
                    ServerInfoDetailRow(label: "Host Message", value: model.serverInfo.hostMessage)
                    ServerInfoDetailRow(label: "Message Mode", value: model.serverInfo.hostMessageMode.map(String.init))
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
        rows.append(("Codec Encryption", model.serverInfo.codecEncryptionMode.map(String.init)))
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
        rows.append(("Host Message", model.serverInfo.hostMessage))
        rows.append(("Message Mode", model.serverInfo.hostMessageMode.map(String.init)))
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
            }
        }
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var target: TS3GroupManagementTarget = .server
    @State private var newGroupName = ""
    @State private var newGroupType: TS3PermissionGroupDatabaseType = .regular

    private var groups: [TS3GroupSummary] {
        switch target {
        case .server:
            return model.serverGroups
        case .channel:
            return model.channelGroups
        }
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

                Section(header: Text(target.title)) {
                    if groups.isEmpty {
                        Text("No groups")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(groups) { group in
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
}

struct GroupManagementRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let group: TS3GroupSummary
    let target: TS3GroupManagementTarget
    @State private var isShowingMembers = false
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
}

struct GroupClientListSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let group: TS3GroupSummary
    let target: TS3GroupManagementTarget

    var body: some View {
        NavigationView {
            List {
                if model.groupClients.isEmpty {
                    Text("No members")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(model.groupClients) { client in
                        GroupClientRow(group: group, target: target, client: client)
                            .environmentObject(model)
                    }
                }
            }
            .navigationTitle(model.groupClientListTitle)
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
            }
        }
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

extension TS3PermissionGroupDatabaseType {
    var title: String {
        switch self {
        case .template:
            return "Template"
        case .regular:
            return "Regular"
        case .query:
            return "Query"
        }
    }
}

struct ClientDatabaseSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var searchText = ""
    @State private var isShowingDescriptionEditor = false
    @State private var actionMode: DatabaseClientActionMode?
    @State private var isShowingComplaints = false
    @State private var isConfirmingDelete = false

    var displayedRecords: [TS3DatabaseClientSummary] {
        model.databaseSearchResults.isEmpty ? model.databaseClients : model.databaseSearchResults
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
                            model.databaseSearchResults = []
                            model.clientLocations = []
                        }
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
                        }
                        Button("Resolve Database ID From UID") {
                            model.resolveDatabaseIdForSelectedClient()
                        }
                        .disabled(selected.uniqueIdentifier == nil)
                        Button("Edit Description") {
                            isShowingDescriptionEditor = true
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
                        model.refreshClientDatabase()
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
    @State private var codecEncryptionMode = ""
    @State private var isShowingIconImporter = false

    var body: some View {
        NavigationView {
            Form {
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
                        Text("None").tag("0")
                        Text("Log").tag("1")
                        Text("Modal").tag("2")
                        Text("Modal Quit").tag("3")
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
                    TextField("Codec Encryption Mode", text: $codecEncryptionMode)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
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
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
        }
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
        codecEncryptionMode = model.serverInfo.codecEncryptionMode.map(String.init) ?? ""
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
            codecEncryptionMode: Int(codecEncryptionMode.trimmingCharacters(in: .whitespacesAndNewlines))
        )
    }

    private static func decimalText(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

struct FileBrowserSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var directoryName = ""
    @State private var pathText = "/"
    @State private var isShowingFileImporter = false
    @State private var isExportingDownloadedFile = false
    @State private var downloadedFileDocument = TS3DownloadedFileDocument()
    @State private var downloadedFileExportName = "download"
    @State private var pendingUploadURLs: [URL] = []
    @State private var uploadOverwriteNames: [String] = []
    @State private var isConfirmingUploadOverwrite = false

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

                Section(header: Text(model.fileBrowserPath)) {
                    if model.fileBrowserPath != "/" {
                        Button("Parent Directory") {
                            model.leaveFileDirectory()
                        }
                    }

                    if model.fileEntries.isEmpty {
                        Text("No files")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.fileEntries) { entry in
                            FileEntryRow(entry: entry)
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
                        Button("Clear Completed Transfers") {
                            model.clearCompletedFileTransfers()
                        }
                        .disabled(!model.fileTransfers.contains { !$0.canCancel })
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
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshFileList()
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
            .alert(isPresented: $isConfirmingUploadOverwrite) {
                Alert(
                    title: Text("Overwrite Remote Files?"),
                    message: Text(uploadOverwriteMessage),
                    primaryButton: .destructive(Text("Overwrite")) {
                        model.uploadFiles(pendingUploadURLs, overwrite: true)
                        pendingUploadURLs = []
                        uploadOverwriteNames = []
                    },
                    secondaryButton: .cancel {
                        pendingUploadURLs = []
                        uploadOverwriteNames = []
                    }
                )
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
            isConfirmingUploadOverwrite = true
        }
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
    @EnvironmentObject private var model: TS3AppModel
    let transfer: TS3FileTransferSummary

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
                    model.cancelFileTransfer(transfer)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 3)
        .contextMenu {
            if transfer.canCancel {
                Button("Cancel Transfer") {
                    model.cancelFileTransfer(transfer)
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
    }
}

private extension TS3FileTransferSummary {
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
    @State private var isRenaming = false
    @State private var isConfirmingDelete = false
    @State private var isShowingInfo = false
    @State private var newName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                if entry.isDirectory {
                    model.enterFileDirectory(entry)
                }
            } label: {
                HStack(alignment: .top, spacing: 10) {
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
                Button("Rename") {
                    newName = entry.name
                    isRenaming = true
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
            Button("Copy Name") {
                TS3PlatformSupport.copyToPasteboard(entry.name)
            }
            Button("Copy Remote Path") {
                TS3PlatformSupport.copyToPasteboard(entry.path)
            }
            Button("Info") {
                isShowingInfo = true
            }
            Button("Rename") {
                newName = entry.name
                isRenaming = true
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

struct PermissionsSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var searchText = ""
    @State private var permissionName = ""
    @State private var permissionValue = "0"
    @State private var permissionNegated = false
    @State private var permissionSkip = false
    @State private var isExportingPermissions = false
    @State private var permissionExportDocument = TS3TextFileDocument()
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

    var visiblePermissionsSnapshot: String {
        displayedPermissions.map(\.clipboardSummary).joined(separator: "\n")
    }

    var exportFilename: String {
        switch model.permissionEditScope {
        case .ownClient:
            return "ts3-own-client-permissions"
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
                    .disabled(displayedPermissions.isEmpty)

                    Button("Export Visible Permissions") {
                        permissionExportDocument = TS3TextFileDocument(data: Data(visiblePermissionsSnapshot.utf8))
                        isExportingPermissions = true
                    }
                    .disabled(displayedPermissions.isEmpty)

                    Button("Delete Visible Permissions") {
                        isConfirmingDeleteVisible = true
                    }
                    .disabled(displayedPermissions.isEmpty)
                    .foregroundColor(.red)

                    if displayedPermissions.isEmpty {
                        Text("No permissions")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(displayedPermissions) { permission in
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
                        .disabled(model.permissionEditScope == .ownClient || model.permissionEditScope == .channel || model.permissionEditScope == .channelClient)
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
                isPresented: $isExportingPermissions,
                document: permissionExportDocument,
                contentType: .plainText,
                defaultFilename: exportFilename
            ) { result in
                if case .failure(let error) = result {
                    model.lastError = error.localizedDescription
                }
            }
            .alert(isPresented: $isConfirmingDeleteVisible) {
                Alert(
                    title: Text("Delete Visible Permissions?"),
                    message: Text("This removes \(displayedPermissions.count) permission entries from the current target."),
                    primaryButton: .destructive(Text("Delete")) {
                        model.deleteSelectedPermissions(displayedPermissions)
                    },
                    secondaryButton: .cancel()
                )
            }
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var targetType: TS3PrivilegeKeyTargetType = .serverGroup
    @State private var selectedServerGroupId = 0
    @State private var selectedChannelGroupId = 0
    @State private var selectedChannelId = 0
    @State private var description = ""
    @State private var customSet = ""

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
                    if model.privilegeKeys.isEmpty {
                        Text("No privilege keys")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.privilegeKeys) { key in
                            PrivilegeKeyRow(key: key)
                                .environmentObject(model)
                        }
                    }
                }
            }
            .navigationTitle("Privilege Keys")
            .ts3InlineNavigationTitle()
            .onAppear {
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

    private func normalizeSelections() {
        if selectedServerGroupId == 0 || !model.serverGroups.contains(where: { $0.id == selectedServerGroupId }) {
            selectedServerGroupId = model.serverGroups.first?.id ?? 0
        }
        if selectedChannelGroupId == 0 || !model.channelGroups.contains(where: { $0.id == selectedChannelGroupId }) {
            selectedChannelGroupId = model.channelGroups.first?.id ?? 0
        }
        if selectedChannelId == 0 || !model.channels.contains(where: { $0.id == selectedChannelId }) {
            selectedChannelId = model.currentChannel?.id ?? model.channels.first?.id ?? 0
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
            return "Server Group: \(TS3GroupSummary.name(for: key.groupId, in: model.serverGroups))"
        case .channelGroup:
            let group = TS3GroupSummary.name(for: key.groupId, in: model.channelGroups)
            let channel = key.channelId.flatMap { id in model.channels.first { $0.id == id }?.name } ?? "Any Channel"
            return "Channel Group: \(group) in \(channel)"
        case nil:
            return "Group \(key.groupId)"
        }
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct BanListSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isConfirmingDeleteAll = false
    @State private var ip = ""
    @State private var name = ""
    @State private var uniqueIdentifier = ""
    @State private var reason = ""
    @State private var duration: TS3BanDuration = .permanent
    @State private var customBanMinutes = "60"

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

                if model.banEntries.isEmpty {
                    Text("No bans")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(model.banEntries) { entry in
                        BanEntryRow(entry: entry)
                            .environmentObject(model)
                    }
                    Section {
                        Button("Delete All Bans") {
                            isConfirmingDeleteAll = true
                        }
                        .foregroundColor(.red)
                    }
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
}

struct ComplaintListSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isConfirmingDeleteAll = false

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

                Section(header: Text("Complaints")) {
                    if model.complaintEntries.isEmpty {
                        Text("No complaints")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.complaintEntries) { entry in
                            ComplaintEntryRow(entry: entry)
                                .environmentObject(model)
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
}

struct ComplaintEntryRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3ComplaintSummary

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
                model.deleteComplaint(entry)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct BanEntryRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3BanEntrySummary

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
                model.deleteBan(entry)
            }
            .buttonStyle(.borderless)
            .foregroundColor(.red)
            .font(.caption)
        }
        .padding(.vertical, 4)
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

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func durationText(_ seconds: Int) -> String {
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

struct WhisperSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var groupWhisperType: TS3GroupWhisperType = .allClients
    @State private var groupWhisperTarget: TS3GroupWhisperTarget = .currentChannel
    @State private var selectedServerGroupId = 0
    @State private var selectedChannelGroupId = 0

    var body: some View {
        NavigationView {
            Form {
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
                            ForEach(model.serverGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                        .disabled(model.serverGroups.isEmpty)
                    }
                    if groupWhisperType == .channelGroup {
                        Picker("Channel Group", selection: $selectedChannelGroupId) {
                            ForEach(model.channelGroups) { group in
                                Text(group.name).tag(group.id)
                            }
                        }
                        .disabled(model.channelGroups.isEmpty)
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
                        ForEach(model.channels) { channel in
                            Button(channel.name) {
                                model.enableWhisperToChannel(id: channel.id)
                            }
                        }
                    }
                }

                if !model.clients.isEmpty {
                    Section(header: Text("Users")) {
                        ForEach(model.clients.filter { !$0.isCurrentUser }) { user in
                            Button(user.nickname) {
                                model.enableWhisperToClient(user)
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
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarTrailingPlacement) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
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

    private func updateSelectedGroups() {
        if selectedServerGroupId == 0 || !model.serverGroups.contains(where: { $0.id == selectedServerGroupId }) {
            selectedServerGroupId = model.serverGroups.first?.id ?? 0
        }
        if selectedChannelGroupId == 0 || !model.channelGroups.contains(where: { $0.id == selectedChannelGroupId }) {
            selectedChannelGroupId = model.channelGroups.first?.id ?? 0
        }
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
        .disabled(model.state != .disconnected)
        .alert(isPresented: $isConfirmingRegenerate) {
            Alert(
                title: Text("Regenerate Identity?"),
                message: Text("This replaces your local identity. Servers will treat you as a different client unless you restore a backup."),
                primaryButton: .destructive(Text("Regenerate")) {
                    model.regenerateIdentity()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct IdentityManagementSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var importedIdentity = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Identity")) {
                    IdentitySummaryRows(importedIdentity: $importedIdentity)
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
        }
    }
}

enum ChannelEditorMode {
    case create(parent: TS3ChannelSummary?)
    case edit(TS3ChannelSummary)
}

struct ChannelEditorSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let mode: ChannelEditorMode
    @State private var name = ""
    @State private var phoneticName = ""
    @State private var topic = ""
    @State private var description = ""
    @State private var password = ""
    @State private var channelType: TS3ChannelType = .permanent
    @State private var isDefault = false
    @State private var neededTalkPower = ""
    @State private var neededSubscribePower = ""
    @State private var codec = ""
    @State private var codecQuality = ""
    @State private var deleteDelaySeconds = ""
    @State private var maxClients = ""
    @State private var maxFamilyClients = ""
    @State private var maxClientsUnlimited = true
    @State private var maxFamilyClientsUnlimited = true
    @State private var maxFamilyClientsInherited = false
    @State private var iconId = ""
    @State private var isShowingIconImporter = false

    var title: String {
        switch mode {
        case .create: return "New Channel"
        case .edit: return "Edit Channel"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Channel")) {
                    TextField("Name", text: $name)
                    TextField("Phonetic Name", text: $phoneticName)
                    TextField("Topic", text: $topic)
                    TextField("Description", text: $description)
                    SecureField("Password", text: $password)
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
                    TextField("Codec", text: $codec)
                        .ts3NumericKeyboard()
                    TextField("Codec Quality", text: $codecQuality)
                        .ts3NumericKeyboard()
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
                                codec: parsedOptionalInt(codec),
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
                                password: password.isEmpty ? nil : password,
                                isDefault: isDefault,
                                channelType: channelType,
                                neededTalkPower: parsedOptionalInt(neededTalkPower),
                                neededSubscribePower: parsedOptionalInt(neededSubscribePower),
                                codec: parsedOptionalInt(codec),
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
                    channelType = channelType(for: channel)
                    isDefault = channel.isDefault
                    neededTalkPower = channel.neededTalkPower.map(String.init) ?? ""
                    neededSubscribePower = channel.neededSubscribePower.map(String.init) ?? ""
                    codec = channel.codec.map(String.init) ?? ""
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
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isOptionalInt(neededTalkPower)
            && isOptionalInt(neededSubscribePower)
            && isOptionalInt(codec)
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
    @State private var isShowingAudioSettings = false
    @State private var isShowingSelfStatus = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(model.talkStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    isShowingSelfStatus = true
                } label: {
                    Label(model.isAway ? "Away" : "Self", systemImage: model.isAway ? "moon.zzz" : "person.crop.circle")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button {
                    isShowingAudioSettings = true
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
        }
        .padding()
        .sheet(isPresented: $isShowingAudioSettings) {
            AudioSettingsSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingSelfStatus) {
            SelfStatusSheet()
                .environmentObject(model)
        }
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var nickname = ""
    @State private var isAway = false
    @State private var awayMessage = ""
    @State private var isInputMuted = false
    @State private var isOutputMuted = false
    @State private var isChannelCommander = false
    @State private var talkRequestMessage = ""
    @State private var selfIconId = ""
    @State private var isShowingIconImporter = false
    @State private var isShowingAvatarImporter = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    TextField("Nickname", text: $nickname)
                        .ts3PlainTextField()
                    Button("Update Nickname") {
                        model.updateNickname(to: nickname)
                    }
                    .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                nickname = model.nickname
                isAway = model.isAway
                awayMessage = model.awayMessage
                isInputMuted = model.isInputMuted
                isOutputMuted = model.isOutputMuted
                isChannelCommander = model.isChannelCommander
                talkRequestMessage = model.talkRequestMessage
                selfIconId = model.clients.first(where: { $0.isCurrentUser })?.iconId.map(String.init) ?? ""
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
            .fileImporter(
                isPresented: $isShowingAvatarImporter,
                allowedContentTypes: [.image, .data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.uploadSelfAvatar(from: url)
                }
            }
        }
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
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel

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

    private var transmitModeBinding: Binding<TS3AudioTransmitMode> {
        Binding(
            get: { model.audioTransmitMode },
            set: { model.updateAudioTransmitMode($0) }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transmit Mode")) {
                    Picker("Mode", selection: transmitModeBinding) {
                        Text("Push To Talk").tag(TS3AudioTransmitMode.pushToTalk)
                        Text("Continuous").tag(TS3AudioTransmitMode.continuous)
                        Text("Voice Activation").tag(TS3AudioTransmitMode.voiceActivation)
                    }
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

                Section {
                    Button("Reset Audio Settings") {
                        model.resetAudioSettings()
                    }
                }
            }
            .navigationTitle("Audio Settings")
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
