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
        print("DEBUG: applicationDidFinishLaunching started")

        // Initialize the anchor overlay window
        print("DEBUG: Initializing anchor overlay window")
        anchorOverlayWindow = AnchorOverlayWindow()

        // Initialize mouse event handler
        print("DEBUG: Initializing mouse event handler")
        mouseEventHandler = MouseEventHandler()
        mouseEventHandler?.delegate = self

        // Initialize status bar
        print("DEBUG: Initializing status bar controller")
        statusBarController = StatusBarController()
        print("DEBUG: Status bar controller initialized")

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

        print("DEBUG: applicationDidFinishLaunching completed")
    }

    private func checkPermissionsAndStart() {
        let hasPermissions = PermissionsManager.shared.checkAccessibilityPermissions()
        print("DEBUG: Accessibility permissions: \(hasPermissions)")

        if hasPermissions {
            print("DEBUG: Permissions granted, starting mouse event handler")
            mouseEventHandler?.start()
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        } else {
            print("DEBUG: Requesting accessibility permissions")
            PermissionsManager.shared.requestAccessibilityPermissions()

            // Poll for permissions every 2 seconds
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                if PermissionsManager.shared.checkAccessibilityPermissions() {
                    print("DEBUG: Permissions now granted!")
                    self?.mouseEventHandler?.start()
                    self?.permissionCheckTimer?.invalidate()
                    self?.permissionCheckTimer = nil
                } else {
                    print("DEBUG: Still waiting for permissions...")
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
}
