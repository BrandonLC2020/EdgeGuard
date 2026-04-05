import AppKit
import ServiceManagement

/// Owns the NSStatusItem and the NSMenu. Reads system state from UniversalControlService
/// and reflects it in the icon and menu item checkmarks.
@MainActor
final class MenuBarController: NSObject {

    private let statusItem: NSStatusItem
    private let service = UniversalControlService()

    // Strong references to items updated dynamically after menu is built
    private let ucItem: NSMenuItem
    private let magicEdgesItem: NSMenuItem
    private let launchAtLoginItem: NSMenuItem

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        ucItem = NSMenuItem(
            title: "Universal Control Enabled",
            action: #selector(handleToggleUC),
            keyEquivalent: ""
        )
        magicEdgesItem = NSMenuItem(
            title: "Require 'Push' to Connect",
            action: #selector(handleToggleMagicEdges),
            keyEquivalent: ""
        )
        launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(handleToggleLaunchAtLogin),
            keyEquivalent: ""
        )

        super.init()

        statusItem.menu = buildMenu()

        // Optimistic initial state (macOS ships with UC enabled)
        ucItem.state = .on
        magicEdgesItem.state = .on
        updateIcon(ucEnabled: true)

        // Load actual state asynchronously
        Task { await refreshState() }
    }

    // MARK: - Menu Construction

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        ucItem.target = self
        menu.addItem(ucItem)

        // Indented to visually indicate it's a sub-option of Universal Control
        magicEdgesItem.target = self
        magicEdgesItem.indentationLevel = 1
        menu.addItem(magicEdgesItem)

        menu.addItem(.separator())

        let severItem = NSMenuItem(
            title: "Sever All Connections",
            action: #selector(handleSeverAll),
            keyEquivalent: ""
        )
        severItem.target = self
        menu.addItem(severItem)

        menu.addItem(.separator())

        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        // Quit uses the standard NSApplication action via the responder chain
        menu.addItem(NSMenuItem(
            title: "Quit EdgeGuard",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        return menu
    }

    // MARK: - State Management

    /// Reads current system state and updates the menu and icon to match.
    func refreshState() async {
        do {
            let state = try await service.fetchState()
            syncLaunchAtLoginState()
            updateMenuAndIcon(state: state)
        } catch {
            // Leave UI in current state if we can't read system prefs
        }
    }

    private func updateMenuAndIcon(state: UCState) {
        ucItem.state = state.universalControlEnabled ? .on : .off
        magicEdgesItem.state = state.magicEdgesEnabled ? .on : .off
        magicEdgesItem.isEnabled = state.universalControlEnabled
        updateIcon(ucEnabled: state.universalControlEnabled)
    }

    private func updateIcon(ucEnabled: Bool) {
        let symbolName = "cursorarrow.and.square.on.square"
        if ucEnabled {
            let image = NSImage(
                systemSymbolName: symbolName,
                accessibilityDescription: "EdgeGuard: Universal Control enabled"
            )
            image?.isTemplate = true
            statusItem.button?.image = image
        } else {
            let config = NSImage.SymbolConfiguration(paletteColors: [.systemRed])
            let image = NSImage(
                systemSymbolName: symbolName,
                accessibilityDescription: "EdgeGuard: Universal Control disabled"
            )?.withSymbolConfiguration(config)
            statusItem.button?.image = image
        }
    }

    // MARK: - Public API (called by GlobalHotkeyManager)

    func toggleUniversalControl() {
        Task {
            do {
                let current = try await service.fetchState()
                try await service.setUniversalControlEnabled(!current.universalControlEnabled)
                let updated = try await service.fetchState()
                updateMenuAndIcon(state: updated)
            } catch {
                showError(error)
            }
        }
    }

    // MARK: - Menu Actions

    @objc private func handleToggleUC() {
        toggleUniversalControl()
    }

    @objc private func handleToggleMagicEdges() {
        Task {
            do {
                let current = try await service.fetchState()
                try await service.setMagicEdgesEnabled(!current.magicEdgesEnabled)
                let updated = try await service.fetchState()
                updateMenuAndIcon(state: updated)
            } catch {
                showError(error)
            }
        }
    }

    @objc private func handleSeverAll() {
        Task {
            do {
                try await service.severAllConnections()
            } catch {
                showError(error)
            }
        }
    }

    @objc private func handleToggleLaunchAtLogin() {
        setLaunchAtLogin(!AppSettings.shared.launchAtLogin)
    }

    // MARK: - Launch at Login (SMAppService)

    private func setLaunchAtLogin(_ enabled: Bool) {
        let smService = SMAppService.mainApp
        do {
            if enabled {
                try smService.register()
            } else {
                try smService.unregister()
            }
            AppSettings.shared.launchAtLogin = enabled
            launchAtLoginItem.state = enabled ? .on : .off
        } catch {
            // Registration may be denied by the user; sync back the real state
            syncLaunchAtLoginState()
        }
    }

    private func syncLaunchAtLoginState() {
        let isEnabled = SMAppService.mainApp.status == .enabled
        AppSettings.shared.launchAtLogin = isEnabled
        launchAtLoginItem.state = isEnabled ? .on : .off
    }

    // MARK: - Error Handling

    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "EdgeGuard Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
