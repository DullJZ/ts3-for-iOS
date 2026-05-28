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
    }
}
