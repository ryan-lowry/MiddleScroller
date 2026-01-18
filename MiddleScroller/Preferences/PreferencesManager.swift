//
//  PreferencesManager.swift
//  MiddleScroller
//

import Foundation
import ServiceManagement

final class PreferencesManager {

    static let shared = PreferencesManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let scrollSpeedMultiplier = "scrollSpeedMultiplier"
        static let launchAtLogin = "launchAtLogin"
    }

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.scrollSpeedMultiplier: 1.0,
            Keys.launchAtLogin: false
        ])
    }

    // MARK: - Scroll Speed

    var scrollSpeedMultiplier: Double {
        get { defaults.double(forKey: Keys.scrollSpeedMultiplier) }
        set { defaults.set(newValue, forKey: Keys.scrollSpeedMultiplier) }
    }

    // MARK: - Launch at Login

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin(newValue)
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                Logger.debug("Failed to update launch at login: \(error)")
            }
        } else {
            // Fallback for older macOS versions
            // Note: This uses the deprecated SMLoginItemSetEnabled which requires a helper app
            // For simplicity, we just store the preference - full implementation would need a helper bundle
            Logger.debug("Launch at login requires macOS 13.0 or later for automatic setup")
        }
    }
}
