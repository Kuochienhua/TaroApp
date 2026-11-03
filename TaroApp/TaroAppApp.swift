import SwiftUI

@main
struct TaroAppApp: App {

    /// Initialise at launch so background URLSession reconnects
    /// to any in-progress model download immediately.
    @StateObject private var downloadManager = ModelDownloadManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(downloadManager)
        }
    }
}
