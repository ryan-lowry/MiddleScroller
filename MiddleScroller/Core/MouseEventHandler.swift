//
//  MouseEventHandler.swift
//  MiddleScroller
//

import Cocoa
import CoreGraphics

protocol MouseEventHandlerDelegate: AnyObject {
    func didActivateScrollMode(at point: CGPoint)
    func didDeactivateScrollMode()
}

final class MouseEventHandler {

    weak var delegate: MouseEventHandlerDelegate?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var scrollController: ScrollController?

    private var isScrollModeActive = false
    private var anchorPoint: CGPoint = .zero

    // Click passthrough detection
    private let clickThresholdMs: TimeInterval = 0.300
    private let movementThresholdPx: CGFloat = 5.0

    private var middleDownLocation: CGPoint?
    private var clickDecisionTimer: DispatchSourceTimer?
    private var scrollModeActivatedThisPress = false
    private var pendingSyntheticEvents = 0  // Count of synthetic events we're expecting

    // Store reference to self for the C callback
    private var this: Unmanaged<MouseEventHandler>?

    func start() {
        guard eventTap == nil else { return }

        // Create event tap for middle mouse button events and mouse movement
        let eventMask: CGEventMask = (1 << CGEventType.otherMouseDown.rawValue) |
                                      (1 << CGEventType.otherMouseUp.rawValue) |
                                      (1 << CGEventType.mouseMoved.rawValue) |
                                      (1 << CGEventType.otherMouseDragged.rawValue)

        // Store unmanaged reference to self
        this = Unmanaged.passRetained(self)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let handler = Unmanaged<MouseEventHandler>.fromOpaque(refcon).takeUnretainedValue()
                return handler.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: this?.toOpaque()
        )

        guard let eventTap = eventTap else {
            print("Failed to create event tap. Check accessibility permissions.")
            this?.release()
            this = nil
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        scrollController = ScrollController()
    }

    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            CFMachPortInvalidate(eventTap)
        }

        eventTap = nil
        runLoopSource = nil

        // Release the retained reference
        this?.release()
        this = nil

        // Clean up decision state
        cancelClickDecisionTimer()
        resetDecisionState()
        pendingSyntheticEvents = 0

        // Deactivate scroll mode if active
        if isScrollModeActive {
            deactivateScrollMode()
        }

        scrollController?.stop()
        scrollController = nil
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Handle tap disabled event (system can disable taps)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap = eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passRetained(event)
        }

        // Check if it's a middle mouse button event (button 2)
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)

        switch type {
        case .otherMouseDown:
            // Middle button is button 2
            if buttonNumber == 2 {
                print("[DEBUG] otherMouseDown received, pendingSyntheticEvents=\(pendingSyntheticEvents)")
                // Let synthetic clicks pass through
                if pendingSyntheticEvents > 0 {
                    pendingSyntheticEvents -= 1
                    print("[DEBUG] Letting synthetic mouseDown pass through, remaining=\(pendingSyntheticEvents)")
                    return Unmanaged.passRetained(event)
                }
                startClickDecision(event: event)
                return nil // Consume the event
            }

        case .otherMouseUp:
            if buttonNumber == 2 {
                print("[DEBUG] otherMouseUp received, pendingSyntheticEvents=\(pendingSyntheticEvents), middleDownLocation=\(String(describing: middleDownLocation)), isScrollModeActive=\(isScrollModeActive)")
                // Let synthetic clicks pass through
                if pendingSyntheticEvents > 0 {
                    pendingSyntheticEvents -= 1
                    print("[DEBUG] Letting synthetic mouseUp pass through, remaining=\(pendingSyntheticEvents)")
                    return Unmanaged.passRetained(event)
                }
                // Handle release during decision phase or scroll mode
                if middleDownLocation != nil || isScrollModeActive {
                    print("[DEBUG] Calling handleMiddleMouseUp")
                    return handleMiddleMouseUp(event: event)
                }
                print("[DEBUG] otherMouseUp not handled - letting pass through")
            }

        case .mouseMoved, .otherMouseDragged:
            // Check for movement during decision phase or update scroll during scroll mode
            if middleDownLocation != nil || isScrollModeActive {
                handleMouseMoved(event: event)
            }

        default:
            break
        }

        return Unmanaged.passRetained(event)
    }

    private func startClickDecision(event: CGEvent) {
        // Store the down location for movement detection and synthetic click
        middleDownLocation = event.location
        scrollModeActivatedThisPress = false
        print("[DEBUG] startClickDecision at location=\(event.location)")

        // Start the decision timer
        cancelClickDecisionTimer()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + clickThresholdMs)
        timer.setEventHandler { [weak self] in
            self?.clickThresholdExpired()
        }
        clickDecisionTimer = timer
        timer.resume()
        print("[DEBUG] Decision timer started for \(clickThresholdMs)s")
    }

    private func clickThresholdExpired() {
        print("[DEBUG] clickThresholdExpired called, scrollModeActivatedThisPress=\(scrollModeActivatedThisPress), middleDownLocation=\(String(describing: middleDownLocation))")
        // Timer fired - activate scroll mode if not already active
        guard !scrollModeActivatedThisPress, let downLocation = middleDownLocation else {
            print("[DEBUG] clickThresholdExpired - guard failed, returning early")
            return
        }

        print("[DEBUG] Timer expired - activating scroll mode")
        scrollModeActivatedThisPress = true
        activateScrollMode(at: downLocation)
    }

    private func handleMiddleMouseUp(event: CGEvent) -> Unmanaged<CGEvent>? {
        print("[DEBUG] handleMiddleMouseUp called, scrollModeActivatedThisPress=\(scrollModeActivatedThisPress), middleDownLocation=\(String(describing: middleDownLocation))")
        // Cancel the decision timer
        cancelClickDecisionTimer()

        let downLocation = middleDownLocation
        let wasScrollModeActivated = scrollModeActivatedThisPress
        resetDecisionState()

        if wasScrollModeActivated {
            // Was in scroll mode - deactivate and consume the event
            print("[DEBUG] Was in scroll mode - deactivating and consuming event")
            deactivateScrollMode()
            return nil
        } else if let location = downLocation {
            // Quick click without scroll activation - post synthetic click
            print("[DEBUG] Quick click detected - posting synthetic click at \(location)")
            postSyntheticMiddleClick(at: location)
            return nil
        }

        // Shouldn't reach here, but let event pass if we do
        print("[DEBUG] handleMiddleMouseUp - unexpected state, letting event pass")
        return Unmanaged.passRetained(event)
    }

    private func handleMouseMoved(event: CGEvent) {
        let currentPoint = event.location

        // Check for movement during decision phase
        if let downLocation = middleDownLocation, !scrollModeActivatedThisPress {
            let dx = currentPoint.x - downLocation.x
            let dy = currentPoint.y - downLocation.y
            let distance = hypot(dx, dy)

            if distance > movementThresholdPx {
                // Movement threshold exceeded - activate scroll mode
                cancelClickDecisionTimer()
                scrollModeActivatedThisPress = true
                activateScrollMode(at: downLocation)
            }
        }

        // Update scrolling if scroll mode is active
        if isScrollModeActive {
            scrollController?.updateScroll(from: anchorPoint, to: currentPoint)
        }
    }

    private func activateScrollMode(at point: CGPoint) {
        isScrollModeActive = true
        anchorPoint = point
        scrollController?.start()

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didActivateScrollMode(at: point)
        }
    }

    private func deactivateScrollMode() {
        isScrollModeActive = false
        scrollController?.stop()

        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didDeactivateScrollMode()
        }
    }

    // MARK: - Synthetic Click

    private func postSyntheticMiddleClick(at location: CGPoint) {
        print("[DEBUG] postSyntheticMiddleClick START at \(location)")

        // Set counter for expected synthetic events (down + up = 2)
        pendingSyntheticEvents = 2
        print("[DEBUG] Set pendingSyntheticEvents=\(pendingSyntheticEvents)")

        // Create and post middle mouse down event
        if let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .otherMouseDown, mouseCursorPosition: location, mouseButton: .center) {
            print("[DEBUG] Posting synthetic mouseDown")
            mouseDown.post(tap: .cghidEventTap)
        } else {
            print("[DEBUG] ERROR: Failed to create synthetic mouseDown event")
            pendingSyntheticEvents -= 1
        }

        // Create and post middle mouse up event
        if let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .otherMouseUp, mouseCursorPosition: location, mouseButton: .center) {
            print("[DEBUG] Posting synthetic mouseUp")
            mouseUp.post(tap: .cghidEventTap)
        } else {
            print("[DEBUG] ERROR: Failed to create synthetic mouseUp event")
            pendingSyntheticEvents -= 1
        }

        print("[DEBUG] postSyntheticMiddleClick END")
    }

    // MARK: - Cleanup Helpers

    private func cancelClickDecisionTimer() {
        clickDecisionTimer?.cancel()
        clickDecisionTimer = nil
    }

    private func resetDecisionState() {
        middleDownLocation = nil
        scrollModeActivatedThisPress = false
        // Note: Don't reset pendingSyntheticEvents here - they may still be in flight
    }
}
