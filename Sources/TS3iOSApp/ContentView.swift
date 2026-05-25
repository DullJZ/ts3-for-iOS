import SwiftUI
import TS3Kit

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
    @State private var isShowingIdentity = false

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
                                model.deleteBookmark(bookmark)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
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
            }

            if let error = model.lastError {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
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
    }
}

struct ChannelListView: View {
    @EnvironmentObject private var model: TS3AppModel
    @State private var isShowingServerTools = false
    @State private var isShowingChat = false
    @State private var isShowingWhisper = false
    @State private var isShowingCreateChannel = false

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
                    Label("Chat", systemImage: "message")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button {
                    isShowingServerTools = true
                } label: {
                    Label("Tools", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button {
                    isShowingWhisper = true
                } label: {
                    Label("Whisper", systemImage: "wave.3.right")
                }
                .buttonStyle(TS3BorderedButtonStyle())
                Button("Disconnect") {
                    model.disconnect()
                }
                .buttonStyle(TS3BorderedButtonStyle())
            }
            .padding(.horizontal)

            CurrentChannelCard()
                .padding(.horizontal)

            List {
                Section(header: Text("Channels")) {
                    ForEach(model.channels) { channel in
                        ChannelRow(channel: channel, members: model.members(in: channel.id))
                            .listRowBackground(channel.isCurrent ? Color.accentColor.opacity(0.08) : Color.clear)
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
        .sheet(isPresented: $isShowingWhisper) {
            WhisperSheet()
                .environmentObject(model)
        }
        .sheet(isPresented: $isShowingCreateChannel) {
            ChannelEditorSheet(mode: .create(parent: model.currentChannel))
                .environmentObject(model)
        }
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
    @State private var isShowingEdit = false
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
                        if channel.isPasswordProtected {
                            Image(systemName: "lock.fill")
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
                    Button("Edit Channel") {
                        isShowingEdit = true
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
        .sheet(isPresented: $isShowingEdit) {
            ChannelEditorSheet(mode: .edit(channel))
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
}

enum UserActionMode: Identifiable {
    case privateMessage
    case offlineMessage
    case poke
    case kickChannel
    case kickServer
    case ban

    var id: String {
        switch self {
        case .privateMessage: return "privateMessage"
        case .offlineMessage: return "offlineMessage"
        case .poke: return "poke"
        case .kickChannel: return "kickChannel"
        case .kickServer: return "kickServer"
        case .ban: return "ban"
        }
    }
}

struct ChannelMemberRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let member: TS3UserSummary
    @State private var actionMode: UserActionMode?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: member.isCurrentUser ? "person.crop.circle.fill" : "person.fill")
                .foregroundColor(member.isCurrentUser ? .accentColor : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.nickname)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                HStack(spacing: 8) {
                    if member.isAway {
                        Text(member.awayMessage?.isEmpty == false ? "Away: \(member.awayMessage!)" : "Away")
                    }
                    if member.isInputMuted {
                        Text("Mic muted")
                    }
                    if member.isOutputMuted {
                        Text("Sound muted")
                    }
                    if let power = member.talkPower {
                        Text("Talk \(power)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
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
                Button("Send Private Message") {
                    actionMode = .privateMessage
                }
                Button("Send Offline Message") {
                    actionMode = .offlineMessage
                }
                Button("Poke") {
                    actionMode = .poke
                }
                Button("Whisper to User") {
                    model.enableWhisperToClient(member)
                }
                Button("Refresh Details") {
                    model.refreshUserDetails(member)
                }
                Menu("Move To") {
                    ForEach(model.channels) { channel in
                        Button(channel.name) {
                            model.moveUser(member, to: channel)
                        }
                    }
                }
                Button("Kick From Channel") {
                    actionMode = .kickChannel
                }
                Button("Kick From Server") {
                    actionMode = .kickServer
                }
                Button("Ban") {
                    actionMode = .ban
                }
                if !model.serverGroups.isEmpty {
                    Menu("Add Server Group") {
                        ForEach(model.serverGroups) { group in
                            Button(group.name) {
                                model.addServerGroup(group, to: member)
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
            .disabled(member.isCurrentUser)
        }
        .sheet(item: $actionMode) { mode in
            UserActionSheet(mode: mode, user: member)
                .environmentObject(model)
        }
    }
}

struct UserActionSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    let mode: UserActionMode
    let user: TS3UserSummary
    @State private var subject = ""
    @State private var text = ""

    var title: String {
        switch mode {
        case .privateMessage: return "Private Message"
        case .offlineMessage: return "Offline Message"
        case .poke: return "Poke"
        case .kickChannel: return "Kick From Channel"
        case .kickServer: return "Kick From Server"
        case .ban: return "Ban User"
        }
    }

    var fieldTitle: String {
        switch mode {
        case .privateMessage: return "Message"
        case .offlineMessage: return "Message"
        case .poke: return "Poke Message"
        case .kickChannel, .kickServer, .ban: return "Reason"
        }
    }

    var actionTitle: String {
        switch mode {
        case .privateMessage: return "Send"
        case .offlineMessage: return "Send"
        case .poke: return "Poke"
        case .kickChannel, .kickServer: return "Kick"
        case .ban: return "Ban"
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(user.nickname)) {
                    if mode == .offlineMessage {
                        TextField("Subject", text: $subject)
                            .ts3PlainTextField()
                    }
                    TextField(fieldTitle, text: $text)
                        .ts3PlainTextField()
                }
                Section {
                    Button(actionTitle) {
                        switch mode {
                        case .privateMessage:
                            model.sendPrivateMessage(text, to: user)
                        case .offlineMessage:
                            model.sendOfflineMessage(to: user, subject: subject, message: text)
                        case .poke:
                            model.pokeUser(user, message: text)
                        case .kickChannel:
                            model.kickUserFromChannel(user, message: text.isEmpty ? nil : text)
                        case .kickServer:
                            model.kickUserFromServer(user, message: text.isEmpty ? nil : text)
                        case .ban:
                            model.banUser(user, message: text.isEmpty ? nil : text)
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(isActionDisabled)
                }
            }
            .navigationTitle(title)
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

    private var isActionDisabled: Bool {
        let textIsEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch mode {
        case .privateMessage, .poke:
            return textIsEmpty
        case .offlineMessage:
            return textIsEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .kickChannel, .kickServer, .ban:
            return false
        }
    }
}

struct ChatSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var message = ""
    @State private var target: TS3TextMessageTargetMode = .channel
    @State private var isShowingOfflineMessages = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Target", selection: $target) {
                    Text("Channel").tag(TS3TextMessageTargetMode.channel)
                    Text("Server").tag(TS3TextMessageTargetMode.server)
                }
                .pickerStyle(.segmented)
                .padding()

                List(model.chatMessages) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.senderName)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(item.targetMode == .server ? "Server" : item.targetMode == .channel ? "Channel" : "Private")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(item.message)
                            .font(.body)
                    }
                    .listRowBackground(item.isOwnMessage ? Color.accentColor.opacity(0.08) : Color.clear)
                }

                HStack(spacing: 8) {
                    TextField("Message", text: $message)
                        .textFieldStyle(.roundedBorder)
                    Button("Send") {
                        if target == .server {
                            model.sendServerMessage(message)
                        } else {
                            model.sendChannelMessage(message)
                        }
                        message = ""
                    }
                    .buttonStyle(TS3BorderedButtonStyle(isProminent: true))
                }
                .padding()
            }
            .navigationTitle("Chat")
            .ts3InlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Inbox") {
                        model.refreshOfflineMessages()
                        isShowingOfflineMessages = true
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
        }
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
                Button(message.isRead ? "Mark Unread" : "Mark Read") {
                    model.markOfflineMessage(message, read: !message.isRead)
                }
                .buttonStyle(.borderless)
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
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Server")) {
                    ServerInfoRows()
                    Button("Refresh Channels and Clients") {
                        model.refreshServerView()
                    }
                    Button("Refresh Server Info") {
                        model.refreshServerInfo()
                    }
                    Button("Refresh Permission Groups") {
                        model.refreshGroups()
                    }
                    Button("View Permissions") {
                        model.refreshPermissionList()
                        model.refreshOwnClientPermissions()
                        isShowingPermissions = true
                    }
                    Button("Browse Channel Files") {
                        model.openFileBrowser()
                        isShowingFiles = true
                    }
                    Button("Manage Bans") {
                        model.refreshBanList()
                        isShowingBanList = true
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
            .sheet(isPresented: $isShowingFiles) {
                FileBrowserSheet()
                    .environmentObject(model)
            }
        }
    }
}

struct FileBrowserSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var directoryName = ""

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
            }
            .navigationTitle(selectedChannel?.name ?? "Files")
            .ts3InlineNavigationTitle()
            .onAppear {
                if model.fileBrowserChannelId == nil {
                    model.openFileBrowser()
                } else {
                    model.refreshFileList()
                }
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

struct FileEntryRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let entry: TS3FileEntrySummary
    @State private var isRenaming = false
    @State private var isConfirmingDelete = false
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
                Button("Rename") {
                    newName = entry.name
                    isRenaming = true
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
    @State private var permissionSkip = false

    var filteredPermissionInfos: [TS3PermissionInfoSummary] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return model.permissionInfos }
        return model.permissionInfos.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            String($0.id).contains(query) ||
            ($0.description?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Current Client Direct Permissions")) {
                    if let databaseId = model.ownClientDatabaseId {
                        Text("Database ID \(databaseId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if model.ownClientPermissions.isEmpty {
                        Text("No direct client permissions")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(model.ownClientPermissions) { permission in
                            PermissionRow(permission: permission)
                                .environmentObject(model)
                        }
                    }
                }

                Section(header: Text("Add Direct Permission")) {
                    TextField("Permission Name", text: $permissionName)
                        .ts3PlainTextField()
                    TextField("Value", text: $permissionValue)
                        .ts3NumericKeyboard()
                        .ts3PlainTextField()
                    Toggle("Skip", isOn: $permissionSkip)
                    Button("Add or Update Permission") {
                        model.addOwnClientPermission(
                            name: permissionName,
                            value: Int(permissionValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0,
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
                            }
                        }
                    }
                }
            }
            .navigationTitle("Permissions")
            .ts3InlineNavigationTitle()
            .onAppear {
                model.refreshPermissionList()
                model.refreshOwnClientPermissions()
            }
            .toolbar {
                ToolbarItem(placement: TS3PlatformSupport.toolbarLeadingPlacement) {
                    Button("Refresh") {
                        model.refreshPermissionList()
                        model.refreshOwnClientPermissions()
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

struct PermissionRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let permission: TS3PermissionSummary
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
                    model.deleteOwnClientPermission(permission)
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct PermissionInfoRow: View {
    let permission: TS3PermissionInfoSummary
    let select: () -> Void

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
    }
}

struct BanListSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        NavigationView {
            List {
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

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Route")) {
                    Text(model.whisperRouteDescription)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Quick Actions")) {
                    Button("Whisper to Server") {
                        model.enableWhisperToServer()
                    }
                    Button("Voice to Current Channel") {
                        model.disableWhisper()
                    }
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

    private static func uptimeText(_ seconds: Int) -> String {
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
    @State private var topic = ""
    @State private var description = ""
    @State private var password = ""
    @State private var permanent = true

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
                    TextField("Topic", text: $topic)
                    TextField("Description", text: $description)
                    SecureField("Password", text: $password)
                    Toggle("Permanent", isOn: $permanent)
                }
                Section {
                    Button(title) {
                        switch mode {
                        case let .create(parent):
                            model.createChannel(
                                name: name,
                                parentId: parent?.id,
                                password: password.isEmpty ? nil : password,
                                permanent: permanent
                            )
                        case let .edit(channel):
                            model.editChannel(
                                channel,
                                name: name,
                                topic: topic,
                                description: description,
                                password: password.isEmpty ? nil : password
                            )
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle(title)
            .ts3InlineNavigationTitle()
            .onAppear {
                if case let .edit(channel) = mode {
                    name = channel.name
                    topic = channel.topic ?? ""
                    description = channel.description ?? ""
                    permanent = channel.isPermanent
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

struct TalkControlBar: View {
    @EnvironmentObject private var model: TS3AppModel
    @State private var isShowingPlaybackVolume = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(model.talkStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    isShowingPlaybackVolume = true
                } label: {
                    Label(model.playbackVolumePercentText, systemImage: "speaker.wave.2.fill")
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
                Text(model.isTalking ? "Stop Talking" : "Push To Talk")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TS3BorderedButtonStyle(isProminent: true))
        }
        .padding()
        .sheet(isPresented: $isShowingPlaybackVolume) {
            PlaybackVolumeSheet()
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

struct PlaybackVolumeSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { model.playbackVolume },
            set: { model.updatePlaybackVolume($0) }
        )
    }

    var body: some View {
        NavigationView {
            Form {
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
            }
            .navigationTitle("Audio Volume")
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
