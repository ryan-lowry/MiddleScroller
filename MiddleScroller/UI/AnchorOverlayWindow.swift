//
//  AnchorOverlayWindow.swift
//  MiddleScroller
//

import Cocoa

final class AnchorOverlayWindow: NSWindow {

    private let overlaySize: CGFloat = 48

    init() {
        let frame = NSRect(x: 0, y: 0, width: overlaySize, height: overlaySize)
        super.init(contentRect: frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)

        // Configure window properties
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver // Always on top
        self.ignoresMouseEvents = true // Click-through
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.hasShadow = false

        // Set up the overlay view
        let overlayView = AnchorOverlayView(frame: frame)
        self.contentView = overlayView
    }

    func show(at point: CGPoint) {
        // Convert from CG coordinates (origin at bottom-left) to screen coordinates
        // CGEvent.location returns coordinates with origin at top-left of main display
        guard let screen = NSScreen.main else { return }

        // CGEvent coordinates have Y=0 at top, NSWindow coordinates have Y=0 at bottom
        let screenHeight = screen.frame.height
        let windowX = point.x - overlaySize / 2
        let windowY = screenHeight - point.y - overlaySize / 2

        self.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        self.orderFront(nil)
    }

    func hide() {
        self.orderOut(nil)
    }
}
