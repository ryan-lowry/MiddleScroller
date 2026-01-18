//
//  StatusBarController.swift
//  MiddleScroller
//

import Cocoa

final class StatusBarController {

    private var statusItem: NSStatusItem?
    private var isEnabled = true

    var onToggleEnabled: ((Bool) -> Void)?
    var onQuit: (() -> Void)?

    init() {
        print("DEBUG: StatusBarController init")
        setupStatusBar()
    }

    private func setupStatusBar() {
        print("DEBUG: Setting up status bar")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("DEBUG: Status item created: \(statusItem != nil)")

        if let button = statusItem?.button {
            print("DEBUG: Status bar button exists, setting up icon")
            updateIcon()
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            print("DEBUG: Status bar button configured")
        } else {
            print("DEBUG: ERROR - Status bar button is nil!")
        }
    }

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            showMenu()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        // Enable/Disable toggle
        let toggleItem = NSMenuItem(
            title: isEnabled ? "Disable" : "Enable",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences submenu
        let prefsItem = NSMenuItem(title: "Preferences", action: nil, keyEquivalent: "")
        let prefsMenu = NSMenu()

        // Scroll speed submenu
        let speedItem = NSMenuItem(title: "Scroll Speed", action: nil, keyEquivalent: "")
        let speedMenu = NSMenu()

        let speeds: [(String, Double)] = [
            ("Slow", 0.5),
            ("Normal", 1.0),
            ("Fast", 1.5),
            ("Very Fast", 2.0)
        ]

        let currentSpeed = PreferencesManager.shared.scrollSpeedMultiplier

        for (title, value) in speeds {
            let item = NSMenuItem(title: title, action: #selector(setScrollSpeed(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            item.state = abs(currentSpeed - value) < 0.1 ? .on : .off
            speedMenu.addItem(item)
        }

        speedItem.submenu = speedMenu
        prefsMenu.addItem(speedItem)

        // Launch at login
        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        launchItem.state = PreferencesManager.shared.launchAtLogin ? .on : .off
        prefsMenu.addItem(launchItem)

        prefsItem.submenu = prefsMenu
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Check permissions
        let permissionsItem = NSMenuItem(
            title: "Check Accessibility Permissions",
            action: #selector(checkPermissions),
            keyEquivalent: ""
        )
        permissionsItem.target = self
        menu.addItem(permissionsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit MiddleScroller",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        updateIcon()
        onToggleEnabled?(isEnabled)
    }

    @objc private func setScrollSpeed(_ sender: NSMenuItem) {
        if let speed = sender.representedObject as? Double {
            PreferencesManager.shared.scrollSpeedMultiplier = speed
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let current = PreferencesManager.shared.launchAtLogin
        PreferencesManager.shared.launchAtLogin = !current
    }

    @objc private func checkPermissions() {
        if PermissionsManager.shared.checkAccessibilityPermissions() {
            let alert = NSAlert()
            alert.messageText = "Permissions OK"
            alert.informativeText = "MiddleScroller has accessibility permissions."
            alert.alertStyle = .informational
            alert.runModal()
        } else {
            PermissionsManager.shared.showPermissionsRequiredAlert()
        }
    }

    @objc private func quit() {
        onQuit?()
    }

    private func updateIcon() {
        print("DEBUG: updateIcon called")
        if let button = statusItem?.button {
            // Use SF Symbols for the icon
            let symbolName = isEnabled ? "computermouse.fill" : "computermouse"
            print("DEBUG: Looking for SF Symbol: \(symbolName)")
            if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "MiddleScroller") {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
                print("DEBUG: SF Symbol icon set successfully")
            } else {
                // Fallback text if SF Symbol not available
                button.title = isEnabled ? "M⬍" : "M"
                print("DEBUG: Using fallback text icon")
            }
        } else {
            print("DEBUG: ERROR - button is nil in updateIcon")
        }
    }
}
