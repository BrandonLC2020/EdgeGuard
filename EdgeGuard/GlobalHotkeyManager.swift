import AppKit

/// Registers a global ⌘⌥⌃X keyboard shortcut and fires an action closure on match.
/// Prompts for Accessibility permission on first use; does not register if permission is denied.
@MainActor
final class GlobalHotkeyManager {
    // nonisolated(unsafe) so deinit (non-isolated) can remove the monitor safely.
    nonisolated(unsafe) private var monitor: Any?
    private let action: @MainActor () -> Void

    init(action: @MainActor @escaping () -> Void) {
        self.action = action
        setupMonitor()
    }

    private func setupMonitor() {
        guard checkAccessibilityPermission() else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Extract values before crossing actor boundary
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let char = event.charactersIgnoringModifiers?.lowercased()
            let isTargetCombo = flags == [.command, .option, .control] && char == "x"
            if isTargetCombo {
                Task { @MainActor [weak self] in self?.action() }
            }
        }
    }

    /// Returns whether Accessibility is already granted.
    /// Passing `kAXTrustedCheckOptionPrompt = true` opens System Settings on denial.
    private func checkAccessibilityPermission() -> Bool {
        // Use the literal string to avoid the non-Sendable global kAXTrustedCheckOptionPrompt
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let opts = [key: kCFBooleanTrue] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}
