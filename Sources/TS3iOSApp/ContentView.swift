import SwiftUI
import TS3Kit

struct ContentView: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        NavigationView {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("调试") {
                        model.isShowingDebug = true
                    }
                }
            }
            .sheet(isPresented: $model.isShowingDebug) {
                DebugLogView()
                    .environmentObject(model)
            }
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
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        Form {
            Section(header: Text("Server")) {
                TextField("Host (e.g. ts.example.com)", text: $model.serverHost)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                TextField("Port", text: $model.serverPort)
                    .keyboardType(.numberPad)
                SecureField("Server Password (optional)", text: $model.serverPassword)
            }

            Section(header: Text("Profile")) {
                TextField("Nickname", text: $model.nickname)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
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
    }
}

struct ChannelListView: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text(model.connectedStatus)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
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
            .listStyle(.insetGrouped)

            TalkControlBar()
        }
        .navigationTitle("Channels")
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
                    }
                    HStack(spacing: 6) {
                        Text("\(members.count) user\(members.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        model.joinChannel(channel)
                    }
                    .buttonStyle(TS3BorderedButtonStyle())
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
    }
}

struct ChannelMemberRow: View {
    let member: TS3UserSummary

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: member.isCurrentUser ? "person.crop.circle.fill" : "person.fill")
                .foregroundColor(member.isCurrentUser ? .accentColor : .secondary)
            Text(member.nickname)
                .font(.subheadline)
                .foregroundColor(.primary)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
