//
//  AppDelegate.swift
//  MiddleScroller
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?
    private var mouseEventHandler: MouseEventHandler?
    private var anchorOverlayWindow: AnchorOverlayWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Check accessibility permissions
        if !PermissionsManager.shared.checkAccessibilityPermissions() {
            PermissionsManager.shared.requestAccessibilityPermissions()
        }

        // Initialize the anchor overlay window
        anchorOverlayWindow = AnchorOverlayWindow()

        // Initialize mouse event handler
        mouseEventHandler = MouseEventHandler()
        mouseEventHandler?.delegate = self
        mouseEventHandler?.start()

        // Initialize status bar
        statusBarController = StatusBarController()
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
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        mouseEventHandler?.stop()
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
