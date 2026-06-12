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
            CommandMenu("catalyst.menu.teamSpeak") {
                Button("catalyst.showKeyboardShortcuts") {
                    model.isShowingKeyboardShortcuts = true
                }
                .ts3KeyboardShortcut("show-shortcuts", in: model)

                Button("catalyst.showDebugLog") {
                    model.isShowingDebug = true
                }
                .ts3KeyboardShortcut("show-debug-log", in: model)

                Button("catalyst.manageIdentity") {
                    model.isShowingIdentity = true
                }
                .ts3KeyboardShortcut("manage-identity", in: model)

                Button("catalyst.connectionManager") {
                    model.isShowingConnectionManager = true
                }
                .ts3KeyboardShortcut("connection-manager", in: model)

                Button("catalyst.clientMigration") {
                    model.isShowingClientMigration = true
                }
                .ts3KeyboardShortcut("client-migration", in: model)

                Button("catalyst.notificationSettings") {
                    model.isShowingNotificationSettings = true
                }
                .ts3KeyboardShortcut("notification-settings", in: model)
            }

            CommandMenu("catalyst.menu.connection") {
                Button("catalyst.refreshChannelsClients") {
                    model.refreshServerView()
                }
                .ts3KeyboardShortcut("refresh-server", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.saveCurrentServerBookmark") {
                    model.saveCurrentBookmark(name: model.serverHost)
                }
                .ts3KeyboardShortcut("save-bookmark", in: model)
                .disabled(model.state != .connected)

                Button("connect.copyInviteLink") {
                    model.copyCurrentInviteLink()
                }
                .ts3KeyboardShortcut("copy-invite", in: model)
                .disabled(model.state != .connected)

                Button("connect.copyFullInviteLink") {
                    model.copyCurrentFullInviteLink()
                }
                .ts3KeyboardShortcut("copy-full-invite", in: model)
                .disabled(model.state != .connected)
            }

            CommandMenu("catalyst.menu.messaging") {
                Button("catalyst.openChat") {
                    model.showChat()
                }
                .ts3KeyboardShortcut("open-chat", in: model)

                Button("catalyst.openOfflineMessages") {
                    model.showOfflineMessages()
                }
                .ts3KeyboardShortcut("open-offline-messages", in: model)

                Button("catalyst.openEvents") {
                    model.showEvents()
                }
                .ts3KeyboardShortcut("open-events", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.openWhisper") {
                    model.showWhisper()
                }
                .ts3KeyboardShortcut("open-whisper", in: model)
                .disabled(model.state != .connected)
            }

            CommandMenu("catalyst.menu.administration") {
                Button("catalyst.viewServerLogs") {
                    model.showServerLogs()
                }
                .ts3KeyboardShortcut("view-server-logs", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.viewServerInformation") {
                    model.showServerInformation()
                }
                .ts3KeyboardShortcut("view-server-info", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.editServerSettings") {
                    model.showServerSettings()
                }
                .ts3KeyboardShortcut("edit-server-settings", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.manageContacts") {
                    model.showContacts()
                }
                .ts3KeyboardShortcut("manage-contacts", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.browseClientDatabase") {
                    model.showClientDatabase()
                }
                .ts3KeyboardShortcut("browse-client-database", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.manageBans") {
                    model.showBanList()
                }
                .ts3KeyboardShortcut("manage-bans", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.browseChannelFiles") {
                    model.showFileBrowser()
                }
                .ts3KeyboardShortcut("browse-files", in: model)
                .disabled(model.state != .connected)

                Button("channels.subscriptionPresets") {
                    model.isShowingSubscriptionPresets = true
                }
                .ts3KeyboardShortcut("manage-subscription-presets", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.viewPermissions") {
                    model.showPermissions()
                }
                .ts3KeyboardShortcut("manage-permissions", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.managePermissionGroups") {
                    model.showGroupManagement()
                }
                .ts3KeyboardShortcut("manage-permission-groups", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.managePrivilegeKeys") {
                    model.showPrivilegeKeys()
                }
                .ts3KeyboardShortcut("manage-privilege-keys", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.manageComplaints") {
                    model.showComplaints()
                }
                .ts3KeyboardShortcut("manage-complaints", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.manageTemporaryPasswords") {
                    model.showTemporaryServerPasswords()
                }
                .ts3KeyboardShortcut("manage-temporary-passwords", in: model)
                .disabled(model.state != .connected)
            }

            CommandMenu("catalyst.menu.voice") {
                Button(model.transmitButtonTitle) {
                    model.toggleTalking()
                }
                .ts3KeyboardShortcut("toggle-talk", in: model)
                .disabled(model.state != .connected)

                Button(model.whisperActivationMode == .holdToWhisper
                       ? NSLocalizedString("catalyst.toggleTemporaryWhisper", comment: "")
                       : (model.isWhisperActivationActive
                          ? NSLocalizedString("catalyst.stopTemporaryWhisper", comment: "")
                          : NSLocalizedString("catalyst.startTemporaryWhisper", comment: ""))) {
                    model.toggleCurrentWhisperActivation()
                }
                .ts3KeyboardShortcut("toggle-whisper-activation", in: model)
                .disabled(model.state != .connected || model.whisperRoute == .none)

                Button("catalyst.startTemporaryWhisper") {
                    model.beginCurrentWhisperActivation()
                }
                .ts3KeyboardShortcut("start-whisper-activation", in: model)
                .disabled(model.state != .connected || model.whisperRoute == .none || model.isWhisperActivationActive)

                Button("catalyst.stopTemporaryWhisper") {
                    model.endWhisperActivation()
                }
                .ts3KeyboardShortcut("stop-whisper-activation", in: model)
                .disabled(!model.isWhisperActivationActive)

                Button(model.isInputMuted
                       ? NSLocalizedString("catalyst.unmuteMicrophone", comment: "")
                       : NSLocalizedString("catalyst.muteMicrophone", comment: "")) {
                    model.toggleInputMuted()
                }
                .ts3KeyboardShortcut("toggle-input-muted", in: model)
                .disabled(model.state != .connected)

                Button(model.isOutputMuted
                       ? NSLocalizedString("catalyst.unmuteSound", comment: "")
                       : NSLocalizedString("catalyst.muteSound", comment: "")) {
                    model.toggleOutputMuted()
                }
                .ts3KeyboardShortcut("toggle-output-muted", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.selfStatus") {
                    model.isShowingSelfStatus = true
                }
                .ts3KeyboardShortcut("self-status", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.audioSettings") {
                    model.isShowingAudioSettings = true
                }
                .ts3KeyboardShortcut("audio-settings", in: model)
            }
        }
        #endif
    }
}
