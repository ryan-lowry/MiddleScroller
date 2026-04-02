//
//  ScrollController.swift
//  MiddleScroller
//

import Cocoa
import CoreGraphics

final class ScrollController {

    private var scrollTimer: Timer?
    private var currentScrollVector: CGVector = .zero

    // Configuration
    private let deadZone: CGFloat = 10.0
    private let scrollInterval: TimeInterval = 1.0 / 60.0 // 60 Hz
    private let maxScrollSpeed: CGFloat = 50.0

    private var speedMultiplier: CGFloat {
        CGFloat(PreferencesManager.shared.scrollSpeedMultiplier)
    }

    func start() {
        guard scrollTimer == nil else { return }

        scrollTimer = Timer.scheduledTimer(withTimeInterval: scrollInterval, repeats: true) { [weak self] _ in
            self?.performScroll()
        }
        RunLoop.current.add(scrollTimer!, forMode: .common)
    }

    func stop() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        currentScrollVector = .zero
    }

    func updateScroll(from anchor: CGPoint, to current: CGPoint) {
        let dx = current.x - anchor.x
        let dy = current.y - anchor.y
        let distance = sqrt(dx * dx + dy * dy)

        // Apply dead zone
        if distance < deadZone {
            currentScrollVector = .zero
            return
        }

        // Calculate scroll speed based on distance from anchor
        // Subtract dead zone from distance for smoother transition
        let effectiveDistance = distance - deadZone

        // Scale factor: more distance = faster scroll
        // In dynamic mode, allow scale to grow up to 10x; in static mode, cap at 1x
        let maxScale: CGFloat = PreferencesManager.shared.isDynamicSpeed ? 10.0 : 1.0
        let scaleFactor = min(effectiveDistance / 100.0, maxScale) * speedMultiplier

        // Calculate scroll amounts
        // Note: macOS scroll coordinates are inverted compared to mouse movement
        // Moving mouse down should scroll down (negative deltaY in scroll events)
        var scrollX = (dx / distance) * scaleFactor * maxScrollSpeed
        var scrollY = (dy / distance) * scaleFactor * maxScrollSpeed

        // Invert Y for natural scrolling direction (move mouse down = scroll content down)
        scrollY = -scrollY

        // Apply threshold for horizontal scrolling to avoid accidental horizontal scroll
        if abs(dx) < abs(dy) * 0.5 {
            scrollX = 0
        }
        if abs(dy) < abs(dx) * 0.5 {
            scrollY = 0
        }

        currentScrollVector = CGVector(dx: scrollX, dy: scrollY)
    }

    private func performScroll() {
        guard currentScrollVector != .zero else { return }

        // Create and post scroll event
        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                         units: .pixel,
                                         wheelCount: 2,
                                         wheel1: Int32(currentScrollVector.dy),
                                         wheel2: Int32(currentScrollVector.dx),
                                         wheel3: 0) else {
            Logger.debug("Failed to create scroll event")
            return
        }
        
        scrollEvent.post(tap: CGEventTapLocation.cgSessionEventTap)
    }
}
