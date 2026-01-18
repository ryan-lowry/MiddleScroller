//
//  PermissionsManager.swift
//  MiddleScroller
//

import Cocoa
import ApplicationServices

final class PermissionsManager {

    static let shared = PermissionsManager()

    private init() {}

    /// Check if the app has accessibility permissions
    func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Request accessibility permissions by showing the system prompt
    func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Open System Preferences to the Accessibility pane
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Show an alert explaining that accessibility permissions are required
    func showPermissionsRequiredAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "MiddleScroller needs accessibility access to detect mouse events and control scrolling.\n\nPlease grant access in System Preferences > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilityPreferences()
        }
    }
}
