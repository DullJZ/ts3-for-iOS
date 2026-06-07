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
                .ts3KeyboardShortcut("show-shortcuts", in: model)

                Button("Show Debug Log") {
                    model.isShowingDebug = true
                }
                .ts3KeyboardShortcut("show-debug-log", in: model)

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
            }

            CommandMenu("Connection") {
                Button("Refresh Channels and Clients") {
                    model.refreshServerView()
                }
                .ts3KeyboardShortcut("refresh-server", in: model)
                .disabled(model.state != .connected)

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
            }

            CommandMenu("Messaging") {
                Button("Open Chat") {
                    model.showChat()
                }
                .ts3KeyboardShortcut("open-chat", in: model)

                Button("Open Offline Messages") {
                    model.showOfflineMessages()
                }
                .ts3KeyboardShortcut("open-offline-messages", in: model)

                Button("Open Events") {
                    model.showEvents()
                }
                .ts3KeyboardShortcut("open-events", in: model)
                .disabled(model.state != .connected)

                Button("Open Whisper") {
                    model.showWhisper()
                }
                .ts3KeyboardShortcut("open-whisper", in: model)
                .disabled(model.state != .connected)
            }

            CommandMenu("Administration") {
                Button("View Server Logs") {
                    model.showServerLogs()
                }
                .ts3KeyboardShortcut("view-server-logs", in: model)
                .disabled(model.state != .connected)

                Button("View Server Information") {
                    model.showServerInformation()
                }
                .ts3KeyboardShortcut("view-server-info", in: model)
                .disabled(model.state != .connected)

                Button("Edit Server Settings") {
                    model.showServerSettings()
                }
                .ts3KeyboardShortcut("edit-server-settings", in: model)
                .disabled(model.state != .connected)

                Button("Manage Contacts") {
                    model.showContacts()
                }
                .ts3KeyboardShortcut("manage-contacts", in: model)
                .disabled(model.state != .connected)

                Button("Browse Client Database") {
                    model.showClientDatabase()
                }
                .ts3KeyboardShortcut("browse-client-database", in: model)
                .disabled(model.state != .connected)

                Button("Manage Bans") {
                    model.showBanList()
                }
                .ts3KeyboardShortcut("manage-bans", in: model)
                .disabled(model.state != .connected)

                Button("Browse Channel Files") {
                    model.showFileBrowser()
                }
                .ts3KeyboardShortcut("browse-files", in: model)
                .disabled(model.state != .connected)

                Button("Channel Subscription Presets") {
                    model.isShowingSubscriptionPresets = true
                }
                .ts3KeyboardShortcut("manage-subscription-presets", in: model)
                .disabled(model.state != .connected)

                Button("View Permissions") {
                    model.showPermissions()
                }
                .ts3KeyboardShortcut("manage-permissions", in: model)
                .disabled(model.state != .connected)

                Button("Manage Permission Groups") {
                    model.showGroupManagement()
                }
                .ts3KeyboardShortcut("manage-permission-groups", in: model)
                .disabled(model.state != .connected)

                Button("Manage Privilege Keys") {
                    model.showPrivilegeKeys()
                }
                .ts3KeyboardShortcut("manage-privilege-keys", in: model)
                .disabled(model.state != .connected)

                Button("Manage Complaints") {
                    model.showComplaints()
                }
                .ts3KeyboardShortcut("manage-complaints", in: model)
                .disabled(model.state != .connected)

                Button("Manage Temporary Passwords") {
                    model.showTemporaryServerPasswords()
                }
                .ts3KeyboardShortcut("manage-temporary-passwords", in: model)
                .disabled(model.state != .connected)
            }

            CommandMenu("Voice") {
                Button(model.transmitButtonTitle) {
                    model.toggleTalking()
                }
                .ts3KeyboardShortcut("toggle-talk", in: model)
                .disabled(model.state != .connected)

                Button(model.whisperActivationMode == .holdToWhisper
                       ? "Toggle Temporary Whisper"
                       : (model.isWhisperActivationActive ? "Stop Temporary Whisper" : "Start Temporary Whisper")) {
                    model.toggleCurrentWhisperActivation()
                }
                .ts3KeyboardShortcut("toggle-whisper-activation", in: model)
                .disabled(model.state != .connected || model.whisperRoute == .none)

                Button("Start Temporary Whisper") {
                    model.beginCurrentWhisperActivation()
                }
                .ts3KeyboardShortcut("start-whisper-activation", in: model)
                .disabled(model.state != .connected || model.whisperRoute == .none || model.isWhisperActivationActive)

                Button("Stop Temporary Whisper") {
                    model.endWhisperActivation()
                }
                .ts3KeyboardShortcut("stop-whisper-activation", in: model)
                .disabled(!model.isWhisperActivationActive)

                Button(model.isInputMuted ? "Unmute Microphone" : "Mute Microphone") {
                    model.toggleInputMuted()
                }
                .ts3KeyboardShortcut("toggle-input-muted", in: model)
                .disabled(model.state != .connected)

                Button(model.isOutputMuted ? "Unmute Sound" : "Mute Sound") {
                    model.toggleOutputMuted()
                }
                .ts3KeyboardShortcut("toggle-output-muted", in: model)
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
