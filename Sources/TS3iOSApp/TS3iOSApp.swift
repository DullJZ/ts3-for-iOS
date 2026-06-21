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

                Button("connect.reconnect") {
                    model.reconnect()
                }
                .ts3KeyboardShortcut("reconnect-server", in: model)
                .disabled(model.state == .connecting || model.lastConnectionSnapshot == nil)

                Button("channels.disconnect") {
                    model.disconnect()
                }
                .ts3KeyboardShortcut("disconnect-server", in: model)
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

            CommandMenu("catalyst.menu.profile") {
                Button(model.isAway
                       ? NSLocalizedString("selfStatus.clearAway", comment: "")
                       : NSLocalizedString("selfStatus.setAway", comment: "")) {
                    model.toggleAway()
                }
                .ts3KeyboardShortcut("toggle-away", in: model)
                .disabled(model.state != .connected)

                Button("serverTools.applyNickname") {
                    model.updateNickname(to: model.nickname)
                }
                .ts3KeyboardShortcut("apply-nickname", in: model)
                .disabled(model.state != .connected)

                Button("catalyst.selfStatus") {
                    model.isShowingSelfStatus = true
                }
                .ts3KeyboardShortcut("self-status", in: model)
                .disabled(model.state != .connected)
            }

            CommandMenu("catalyst.menu.channels") {
                Button("channels.newChannel") {
                    model.showCreateChannel()
                }
                .ts3KeyboardShortcut("create-channel", in: model)
                .disabled(model.state != .connected)

                Button("channelActions.channelInfo") {
                    model.showCurrentChannelInformation()
                }
                .ts3KeyboardShortcut("view-current-channel-info", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.sendChannelMessage") {
                    model.showCurrentChannelMessage()
                }
                .ts3KeyboardShortcut("message-current-channel", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.editChannel") {
                    model.showCurrentChannelEditor()
                }
                .ts3KeyboardShortcut("edit-current-channel", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.editChannelPermissions") {
                    model.showCurrentChannelPermissions()
                }
                .ts3KeyboardShortcut("edit-current-channel-permissions", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.createChannelPrivilegeKey") {
                    model.showCurrentChannelPrivilegeKey()
                }
                .ts3KeyboardShortcut("create-current-channel-privilege-key", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil || model.channelGroups.isEmpty)

                Button("channelActions.moveChannel") {
                    model.showCurrentChannelMove()
                }
                .ts3KeyboardShortcut("move-current-channel", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button((model.currentChannel?.isSubscribed ?? false)
                       ? NSLocalizedString("channelActions.unsubscribeChannel", comment: "")
                       : NSLocalizedString("channelActions.subscribeChannel", comment: "")) {
                    model.toggleCurrentChannelSubscription()
                }
                .ts3KeyboardShortcut("toggle-current-channel-subscription", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.setAsDefaultChannel") {
                    model.setCurrentChannelAsDefault()
                }
                .ts3KeyboardShortcut("set-current-channel-default", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.whisperToChannel") {
                    model.enableWhisperToCurrentChannel()
                }
                .ts3KeyboardShortcut("whisper-current-channel", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Menu("common.copy") {
                    Button("channelActions.copyChannelSummary") {
                        model.copyCurrentChannelSummary()
                    }
                    .ts3KeyboardShortcut("copy-current-channel-summary", in: model)

                    Button("channelActions.copyChannelName") {
                        model.copyCurrentChannelName()
                    }
                    .ts3KeyboardShortcut("copy-current-channel-name", in: model)

                    Button("channelActions.copyChannelPath") {
                        model.copyCurrentChannelPath()
                    }
                    .ts3KeyboardShortcut("copy-current-channel-path", in: model)

                    Button("channelActions.copyChannelId") {
                        model.copyCurrentChannelId()
                    }
                    .ts3KeyboardShortcut("copy-current-channel-id", in: model)

                    Button("channelActions.copyChannelInviteLink") {
                        model.copyCurrentChannelInviteLink()
                    }
                    .ts3KeyboardShortcut("copy-current-channel-invite", in: model)

                    Button("channelActions.copyFullChannelInviteLink") {
                        model.copyCurrentChannelFullInviteLink()
                    }
                    .ts3KeyboardShortcut("copy-current-channel-full-invite", in: model)

                    Button("channelActions.copyDeleteImpact") {
                        model.copyCurrentChannelDeleteImpact(force: false)
                    }
                    .ts3KeyboardShortcut("copy-current-channel-delete-impact", in: model)

                    Button("channelActions.copyForceDeleteImpact") {
                        model.copyCurrentChannelDeleteImpact(force: true)
                    }
                    .ts3KeyboardShortcut("copy-current-channel-force-delete-impact", in: model)
                }
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.deleteChannel") {
                    model.confirmCurrentChannelDelete(force: false)
                }
                .ts3KeyboardShortcut("delete-current-channel", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("channelActions.forceDeleteChannel") {
                    model.confirmCurrentChannelDelete(force: true)
                }
                .ts3KeyboardShortcut("force-delete-current-channel", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)

                Button("serverTools.subscribeAllChannels") {
                    model.setAllChannelsSubscribed(true)
                }
                .ts3KeyboardShortcut("subscribe-all-channels", in: model)
                .disabled(model.state != .connected)

                Button("serverTools.unsubscribeAllChannels") {
                    model.setAllChannelsSubscribed(false)
                }
                .ts3KeyboardShortcut("unsubscribe-all-channels", in: model)
                .disabled(model.state != .connected)

                Button("channels.subscriptionPresets") {
                    model.isShowingSubscriptionPresets = true
                }
                .ts3KeyboardShortcut("manage-subscription-presets", in: model)
                .disabled(model.state != .connected)

                Button("channelActions.browseChannelFiles") {
                    model.showCurrentChannelFileBrowser()
                }
                .ts3KeyboardShortcut("browse-files", in: model)
                .disabled(model.state != .connected || model.currentChannel == nil)
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

                Menu("common.copy") {
                    Button("serverInfo.copy") {
                        model.copyCurrentServerSummary()
                    }
                    .ts3KeyboardShortcut("copy-server-summary", in: model)

                    Button("serverInfo.copyHealthSummary") {
                        model.copyCurrentServerHealthSummary()
                    }
                    .ts3KeyboardShortcut("copy-server-health", in: model)
                }
                .disabled(model.state != .connected)

                Button("channels.talkRequests") {
                    model.showTalkRequests()
                }
                .ts3KeyboardShortcut("open-talk-requests", in: model)
                .disabled(model.state != .connected || !model.clients.contains { $0.isRequestingTalkPower })

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

                Button("catalyst.audioSettings") {
                    model.isShowingAudioSettings = true
                }
                .ts3KeyboardShortcut("audio-settings", in: model)
            }
        }
        #endif
    }
}
