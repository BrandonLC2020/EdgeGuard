import SwiftUI

@main
struct EdgeGuardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows — the entire UI lives in the NSStatusItem menu.
        // Settings { EmptyView() } satisfies the requirement for at least one scene.
        Settings { EmptyView() }
    }
}
