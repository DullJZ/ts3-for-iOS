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
    case editDescription
    case complain
    case kickChannel
    case kickServer
    case ban

    var id: String {
        switch self {
        case .privateMessage: return "privateMessage"
        case .offlineMessage: return "offlineMessage"
        case .poke: return "poke"
        case .editDescription: return "editDescription"
        case .complain: return "complain"
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
            UserAvatarView(user: member)
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
                if !member.isCurrentUser {
                    Button("Complain") {
                        actionMode = .complain
                    }
                }
                Button("Whisper to User") {
                    model.enableWhisperToClient(member)
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
                Menu("Move To") {
                    ForEach(model.channels) { channel in
                        Button(channel.name) {
                            model.moveUser(member, to: channel)
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
        case .privateMessage: return "Private Message"
        case .offlineMessage: return "Offline Message"
        case .poke: return "Poke"
        case .editDescription: return "Edit Description"
        case .complain: return "Complain"
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
        case .editDescription: return "Description"
        case .complain: return "Complaint"
        case .kickChannel, .kickServer, .ban: return "Reason"
        }
    }

    var actionTitle: String {
        switch mode {
        case .privateMessage: return "Send"
        case .offlineMessage: return "Send"
        case .poke: return "Poke"
        case .editDescription: return "Save"
        case .complain: return "Submit Complaint"
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
                Section {
                    Button(actionTitle) {
                        switch mode {
                        case .privateMessage:
                            model.sendPrivateMessage(text, to: user)
                        case .offlineMessage:
                            model.sendOfflineMessage(to: user, subject: subject, message: text)
                        case .poke:
                            model.pokeUser(user, message: text)
                        case .editDescription:
                            model.editUserDescription(user, description: text)
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
            .navigationTitle(title)
            .ts3InlineNavigationTitle()
            .onAppear {
                if mode == .editDescription {
                    text = user.description ?? ""
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
        case .privateMessage, .poke, .complain:
            return textIsEmpty
        case .offlineMessage:
            return textIsEmpty || subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .editDescription, .kickChannel, .kickServer:
            return false
        case .ban:
            return banDuration == .custom && TS3BanDuration.customSeconds(from: customBanMinutes) == nil
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
    @State private var isShowingServerEditor = false
    @State private var isShowingServerInfo = false
    @State private var isShowingComplaints = false
    @State private var isShowingClientDatabase = false
    @State private var isShowingServerLogs = false
    @State private var isShowingPrivilegeKeys = false
    @State private var isShowingGroupManagement = false

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
                            limit: Int(lineLimit.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 100,
                            reverse: reverseOrder,
                            instance: instanceLogs
                        )
                    }
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
                            limit: Int(lineLimit.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 100,
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
                    limit: Int(lineLimit.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 100,
                    reverse: reverseOrder,
                    instance: instanceLogs
                )
            }
        }
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
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct ServerInformationSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overview")) {
                    ServerInfoDetailRow(label: "Name", value: model.serverInfo.name)
                    ServerInfoDetailRow(label: "Status", value: model.serverInfo.status)
                    ServerInfoDetailRow(label: "Unique ID", value: model.serverInfo.uniqueIdentifier, monospaced: true)
                    ServerInfoDetailRow(label: "Machine ID", value: model.serverInfo.machineId, monospaced: true)
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
        }
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

    private func deleteGroup(force: Bool) {
        switch target {
        case .server:
            model.deleteServerGroup(group, force: force)
        case .channel:
            model.deleteChannelGroup(group, force: force)
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

                if let selected = model.selectedDatabaseClient {
                    Section(header: Text("Selected Client")) {
                        DatabaseClientDetailRows(record: selected)
                        if !model.clientLocations.isEmpty {
                            ForEach(model.clientLocations) { location in
                                Text(location.nickname ?? "Client \(location.clientId)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Button("Resolve Database ID From UID") {
                            model.resolveDatabaseIdForSelectedClient()
                        }
                        .disabled(selected.uniqueIdentifier == nil)
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
            hostButtonGraphicsURL: hostButtonGraphicsURL
        )
    }
}

struct FileBrowserSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var directoryName = ""
    @State private var isShowingFileImporter = false

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

                Section(header: Text("Transfer")) {
                    Button {
                        isShowingFileImporter = true
                    } label: {
                        Label("Upload File", systemImage: "square.and.arrow.up")
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
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.uploadFile(from: url)
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
    @State private var permissionNegated = false
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

    var displayedPermissions: [TS3PermissionSummary] {
        model.permissionEditScope == .ownClient ? model.ownClientPermissions : model.scopedPermissions
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
                }

                Section(header: Text("\(model.permissionEditScope.title) Permissions")) {
                    if displayedPermissions.isEmpty {
                        Text("No permissions")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(displayedPermissions) { permission in
                            PermissionRow(permission: permission) {
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
                        .disabled(model.permissionEditScope == .ownClient || model.permissionEditScope == .channel)
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
        }
    }
}

struct PermissionRow: View {
    let permission: TS3PermissionSummary
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

struct ComplaintListSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var model: TS3AppModel
    @State private var isConfirmingDeleteAll = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("User")) {
                    if model.clients.filter({ !$0.isCurrentUser }).isEmpty {
                        Text("No other users")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("User", selection: selectedUserId) {
                            ForEach(model.clients.filter { !$0.isCurrentUser }) { user in
                                Text(user.nickname).tag(user.id)
                            }
                        }
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
    @State private var isShowingAudioSettings = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text(model.talkStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
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
