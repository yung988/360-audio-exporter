import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Transform command-line executable into a foreground GUI app with Dock icon and Menu
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct _360AudioExporterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        Window("360 Audio Exporter", id: "main") {
            MainWindowView()
                .environmentObject(appState)
                .preferredColorScheme(.dark) // sleek dark mode look as mockups show
        }
        .windowStyle(.hiddenTitleBar) // Custom modern layout styling
    }
}
