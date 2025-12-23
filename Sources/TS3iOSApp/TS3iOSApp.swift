import SwiftUI
import TS3Kit

@main
struct TS3iOSApp: App {
    @StateObject private var model = TS3AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
