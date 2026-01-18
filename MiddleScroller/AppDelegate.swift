//
//  AppDelegate.swift
//  MiddleScroller
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var mouseEventHandler: MouseEventHandler?
    private var anchorOverlayWindow: AnchorOverlayWindow?
    private var permissionCheckTimer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Logger.debug("applicationDidFinishLaunching started")

        // Initialize the anchor overlay window
        Logger.debug("Initializing anchor overlay window")
        anchorOverlayWindow = AnchorOverlayWindow()

        // Initialize mouse event handler
        Logger.debug("Initializing mouse event handler")
        mouseEventHandler = MouseEventHandler()
        mouseEventHandler?.delegate = self

        // Initialize status bar
        Logger.debug("Initializing status bar controller")
        statusBarController = StatusBarController()
        Logger.debug("Status bar controller initialized")

        statusBarController?.onToggleEnabled = { [weak self] enabled in
            if enabled {
                self?.mouseEventHandler?.start()
            } else {
                self?.mouseEventHandler?.stop()
                self?.anchorOverlayWindow?.hide()
            }
        }
        statusBarController?.onQuit = {
            NSApplication.shared.terminate(nil)
        }

        // Check accessibility permissions and start if granted
        checkPermissionsAndStart()

        Logger.debug("applicationDidFinishLaunching completed")
    }

    private func checkPermissionsAndStart() {
        let hasPermissions = PermissionsManager.shared.checkAccessibilityPermissions()
        Logger.debug("Accessibility permissions: \(hasPermissions)")

        if hasPermissions {
            Logger.debug("Permissions granted, starting mouse event handler")
            mouseEventHandler?.start()
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        } else {
            Logger.debug("Requesting accessibility permissions")
            PermissionsManager.shared.requestAccessibilityPermissions()

            // Poll for permissions every 2 seconds
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                if PermissionsManager.shared.checkAccessibilityPermissions() {
                    Logger.debug("Permissions now granted!")
                    self?.mouseEventHandler?.start()
                    self?.permissionCheckTimer?.invalidate()
                    self?.permissionCheckTimer = nil
                } else {
                    Logger.debug("Still waiting for permissions...")
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
        mouseEventHandler?.stop()
        anchorOverlayWindow?.orderOut(nil)
        statusBarController?.removeFromStatusBar()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// MARK: - MouseEventHandlerDelegate
extension AppDelegate: MouseEventHandlerDelegate {
    func didActivateScrollMode(at point: CGPoint) {
        anchorOverlayWindow?.show(at: point)
    }

    func didDeactivateScrollMode() {
        anchorOverlayWindow?.hide()
    }
    
    func didFailToStart(error: MouseEventHandlerError) {
        Logger.debug("MouseEventHandler failed to start: \(error.localizedDescription)")
        
        let alert = NSAlert()
        alert.alertStyle = .critical
        
        switch error {
        case .accessibilityPermissionDenied:
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "MiddleScroller needs accessibility access to intercept mouse events.\n\nPlease grant access in System Settings > Privacy & Security > Accessibility."
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Quit")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                PermissionsManager.shared.openAccessibilityPreferences()
            } else {
                NSApplication.shared.terminate(nil)
            }
            
        case .eventTapCreationFailed:
            alert.messageText = "Failed to Start"
            alert.informativeText = "MiddleScroller could not create an event tap. This may be a system issue.\n\nTry restarting the app or your Mac."
            alert.addButton(withTitle: "Quit")
            alert.runModal()
            NSApplication.shared.terminate(nil)
            
        case .eventTapDisabled:
            alert.messageText = "Event Monitoring Disabled"
            alert.informativeText = "The system disabled MiddleScroller's event monitoring. This can happen if the app is unresponsive.\n\nThe app will attempt to recover automatically."
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
