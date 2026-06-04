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

                Divider()

                Button("Refresh Channels and Clients") {
                    model.refreshServerView()
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
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
            }
        }
        #endif
    }
}
