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
                handleMiddleMouseDown(event: event)
                return nil // Consume the event
            }

        case .otherMouseUp:
            if buttonNumber == 2 && isScrollModeActive {
                handleMiddleMouseUp(event: event)
                return nil // Consume the event
            }

        case .mouseMoved, .otherMouseDragged:
            if isScrollModeActive {
                handleMouseMoved(event: event)
            }

        default:
            break
        }

        return Unmanaged.passRetained(event)
    }

    private func handleMiddleMouseDown(event: CGEvent) {
        // Hold mode - activate on mouse down
        activateScrollMode(at: event.location)
    }

    private func handleMiddleMouseUp(event: CGEvent) {
        // Hold mode - deactivate on mouse up (release)
        deactivateScrollMode()
    }

    private func handleMouseMoved(event: CGEvent) {
        guard isScrollModeActive else { return }

        let currentPoint = event.location
        scrollController?.updateScroll(from: anchorPoint, to: currentPoint)
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
}
