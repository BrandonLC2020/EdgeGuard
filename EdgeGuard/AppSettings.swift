import Foundation

/// Stores EdgeGuard's own preferences in UserDefaults.
/// System state (UC on/off) is NOT stored here — always read live from UniversalControlService.
@MainActor
final class AppSettings {
    static let shared = AppSettings()

    var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: "launchAtLogin") }
        set { UserDefaults.standard.set(newValue, forKey: "launchAtLogin") }
    }

    var globalHotkeyEnabled: Bool {
        get {
            // Returns false when key is absent; default should be true, so check explicitly.
            guard UserDefaults.standard.object(forKey: "globalHotkeyEnabled") != nil else {
                return true
            }
            return UserDefaults.standard.bool(forKey: "globalHotkeyEnabled")
        }
        set { UserDefaults.standard.set(newValue, forKey: "globalHotkeyEnabled") }
    }

    private init() {}
}
