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
    @State private var newChannelName = ""
    @State private var newChannelPassword = ""

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

            List {
                Section(header: Text("Channels")) {
                    ForEach(model.channels) { channel in
                        ChannelRow(channel: channel)
                    }
                }

                Section(header: Text("Create Channel")) {
                    TextField("Channel name", text: $newChannelName)
                    SecureField("Password (optional)", text: $newChannelPassword)
                    Button("Create") {
                        model.createChannel(name: newChannelName, password: newChannelPassword)
                        newChannelName = ""
                        newChannelPassword = ""
                    }
                    .disabled(newChannelName.isEmpty)
                }
            }
            .listStyle(.insetGrouped)

            TalkControlBar()
        }
        .navigationTitle("Channels")
    }
}

struct ChannelRow: View {
    @EnvironmentObject private var model: TS3AppModel
    let channel: TS3ChannelSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                if let topic = channel.topic, !topic.isEmpty {
                    Text(topic)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if channel.isCurrent {
                Text("Joined")
                    .font(.footnote)
                    .foregroundColor(.green)
            } else {
                Button("Join") {
                    model.joinChannel(channel)
                }
                .buttonStyle(TS3BorderedButtonStyle())
            }
        }
    }
}

struct TalkControlBar: View {
    @EnvironmentObject private var model: TS3AppModel

    var body: some View {
        VStack(spacing: 8) {
            Text(model.talkStatus)
                .font(.footnote)
                .foregroundColor(.secondary)
            Button(action: {
                model.toggleTalking()
            }) {
                Text(model.isTalking ? "Stop Talking" : "Push To Talk")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TS3BorderedButtonStyle(isProminent: true))
        }
        .padding()
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
