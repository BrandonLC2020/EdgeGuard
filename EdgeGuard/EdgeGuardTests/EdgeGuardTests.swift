import Testing
import Foundation
@testable import EdgeGuard

// MARK: - AppSettings Tests

// .serialized because all tests share UserDefaults.standard via the AppSettings singleton.
// A new struct instance is created for each @Test, so init() runs as setUp before each test.
@MainActor
@Suite("AppSettings", .serialized)
struct AppSettingsTests {

    init() {
        // Clean slate before each test
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
        UserDefaults.standard.removeObject(forKey: "globalHotkeyEnabled")
    }

    @Test("launchAtLogin defaults to false when key is absent")
    func launchAtLoginDefault() {
        #expect(AppSettings.shared.launchAtLogin == false)
    }

    @Test("globalHotkeyEnabled defaults to true when key is absent")
    func globalHotkeyEnabledDefault() {
        #expect(AppSettings.shared.globalHotkeyEnabled == true)
    }

    @Test("launchAtLogin round-trips correctly")
    func launchAtLoginRoundTrip() {
        AppSettings.shared.launchAtLogin = true
        #expect(AppSettings.shared.launchAtLogin == true)

        AppSettings.shared.launchAtLogin = false
        #expect(AppSettings.shared.launchAtLogin == false)
    }

    @Test("globalHotkeyEnabled round-trips correctly")
    func globalHotkeyEnabledRoundTrip() {
        AppSettings.shared.globalHotkeyEnabled = false
        #expect(AppSettings.shared.globalHotkeyEnabled == false)

        AppSettings.shared.globalHotkeyEnabled = true
        #expect(AppSettings.shared.globalHotkeyEnabled == true)
    }

    @Test("globalHotkeyEnabled explicit false is stored and read back")
    func globalHotkeyEnabledExplicitFalse() {
        // Verifies the key-present-but-false path (different from key-absent default)
        UserDefaults.standard.set(false, forKey: "globalHotkeyEnabled")
        #expect(AppSettings.shared.globalHotkeyEnabled == false)
    }
}
