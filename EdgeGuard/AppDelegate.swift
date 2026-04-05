import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var hotkeyManager: GlobalHotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Belt-and-suspenders with LSUIElement in Info.plist
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController()

        hotkeyManager = GlobalHotkeyManager { [weak self] in
            self?.menuBarController?.toggleUniversalControl()
        }
    }
}
