import SwiftUI
import TS3Kit

@main
struct TS3iOSApp: App {
    @StateObject private var model = TS3AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .onOpenURL { url in
                    model.applyServerURL(url.absoluteString)
                }
                .onChange(of: scenePhase) { phase in
                    model.setAppActive(phase == .active)
                }
        }
        #if targetEnvironment(macCatalyst) || os(macOS)
        .commands {
            CommandMenu("TeamSpeak") {
                Button("Show Keyboard Shortcuts") {
                    model.isShowingKeyboardShortcuts = true
                }
                .keyboardShortcut("/", modifiers: .command)

                Button("Show Debug Log") {
                    model.isShowingDebug = true
                }
                .keyboardShortcut("L", modifiers: [.command, .shift])

                Button("Manage Identity") {
                    model.isShowingIdentity = true
                }

                Button("Connection Manager") {
                    model.isShowingConnectionManager = true
                }

                Button("Client Migration") {
                    model.isShowingClientMigration = true
                }

                Button("Notification Settings") {
                    model.isShowingNotificationSettings = true
                }

                Divider()

                Button("Refresh Channels and Clients") {
                    model.refreshServerView()
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Divider()

                Button("Save Current Server as Bookmark") {
                    model.saveCurrentBookmark(name: model.serverHost)
                }
                .disabled(model.state != .connected)

                Button("Copy Invite Link") {
                    model.copyCurrentInviteLink()
                }
                .disabled(model.state != .connected)

                Button("Copy Full Invite Link") {
                    model.copyCurrentFullInviteLink()
                }
                .disabled(model.state != .connected)

                Divider()

                Button("Open Chat") {
                    model.showChat()
                }
                .keyboardShortcut("T", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Open Offline Messages") {
                    model.showOfflineMessages()
                }
                .keyboardShortcut("I", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Open Events") {
                    model.showEvents()
                }
                .keyboardShortcut("E", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Open Whisper") {
                    model.showWhisper()
                }
                .keyboardShortcut("W", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Divider()

                Button("View Server Logs") {
                    model.showServerLogs()
                }
                .keyboardShortcut("G", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("View Server Information") {
                    model.showServerInformation()
                }
                .disabled(model.state != .connected)

                Button("Edit Server Settings") {
                    model.showServerSettings()
                }
                .disabled(model.state != .connected)

                Button("Manage Contacts") {
                    model.showContacts()
                }
                .keyboardShortcut("C", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Browse Client Database") {
                    model.showClientDatabase()
                }
                .keyboardShortcut("D", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Manage Bans") {
                    model.showBanList()
                }
                .keyboardShortcut("B", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Browse Channel Files") {
                    model.showFileBrowser()
                }
                .keyboardShortcut("F", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Channel Subscription Presets") {
                    model.isShowingSubscriptionPresets = true
                }
                .disabled(model.state != .connected)

                Button("View Permissions") {
                    model.showPermissions()
                }
                .keyboardShortcut("P", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Manage Permission Groups") {
                    model.showGroupManagement()
                }
                .disabled(model.state != .connected)

                Button("Manage Privilege Keys") {
                    model.showPrivilegeKeys()
                }
                .keyboardShortcut("K", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Manage Complaints") {
                    model.showComplaints()
                }
                .disabled(model.state != .connected)

                Divider()

                Button(model.transmitButtonTitle) {
                    model.toggleTalking()
                }
                .keyboardShortcut("T", modifiers: .command)
                .disabled(model.state != .connected)

                Button(model.isInputMuted ? "Unmute Microphone" : "Mute Microphone") {
                    model.toggleInputMuted()
                }
                .keyboardShortcut("M", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button(model.isOutputMuted ? "Unmute Sound" : "Mute Sound") {
                    model.toggleOutputMuted()
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
                .disabled(model.state != .connected)

                Button("Self Status") {
                    model.isShowingSelfStatus = true
                }
                .disabled(model.state != .connected)

                Button("Audio Settings") {
                    model.isShowingAudioSettings = true
                }
            }
        }
        #endif
    }
}
