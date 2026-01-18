# Middle Scroller for macOS - Product Requirements Document

## Overview
A macOS menu bar application that enables Windows-style middle-click anchor scrolling. Users can press the middle mouse button to set an anchor point, then move the mouse to control scroll direction and speed.

## Core Features

### 1. Anchor Scroll Functionality
- [ ] **Toggle activation**: Middle-click to start scroll mode, middle-click again to stop
- [ ] **Anchor point**: Set anchor at the cursor position when activated
- [ ] **Directional scrolling**: Scroll direction based on mouse movement relative to anchor
- [ ] **Horizontal scrolling**: Support left/right scrolling when moving mouse horizontally
- [ ] **Speed scaling**: Scroll speed proportional to distance from anchor point
- [ ] **Dead zone**: Small dead zone near anchor point to prevent accidental scrolling

### 2. Visual Feedback
- [ ] **Windows-style anchor indicator**: Circle with directional arrows overlay
- [ ] **Indicator positioning**: Displayed at anchor point while scroll mode is active
- [ ] **Indicator visibility**: Always on top, visible in all applications

### 3. Menu Bar Application
- [ ] **Menu bar icon**: Status item in macOS menu bar
- [ ] **No dock icon**: App runs as LSUIElement (menu bar only)
- [ ] **Enable/Disable toggle**: Quick toggle from menu bar
- [ ] **Quit option**: Exit application from menu bar

### 4. Preferences
- [ ] **Launch at login**: Option to start automatically on login
- [ ] **Scroll speed multiplier**: Configurable scroll sensitivity
- [ ] **Persist settings**: Save preferences between app launches

### 5. Permissions
- [ ] **Accessibility access**: Request and handle Accessibility permissions
- [ ] **Permission guidance**: Guide user to grant permissions if not enabled

## Technical Requirements

### Platform
- macOS 12.0+ (Monterey and later)
- Swift 5.x
- Native Cocoa/AppKit

### Key Technologies
- `CGEventTap` for global mouse event interception
- `CGEventPost` for scroll event injection
- `NSStatusItem` for menu bar integration
- `NSWindow` for anchor overlay
- `UserDefaults` for preferences persistence
- `SMAppService` for launch at login (macOS 13+) or `LSSharedFileList` for older versions

### Project Structure
```
MiddleScroller/
├── App/
│   ├── AppDelegate.swift
│   ├── main.swift
│   └── MiddleScrollerApp.swift (if using SwiftUI lifecycle)
├── Core/
│   ├── MouseEventHandler.swift
│   ├── ScrollController.swift
│   └── PermissionsManager.swift
├── UI/
│   ├── AnchorOverlayWindow.swift
│   ├── AnchorOverlayView.swift
│   └── StatusBarController.swift
├── Preferences/
│   └── PreferencesManager.swift
├── Resources/
│   ├── Assets.xcassets
│   └── MenuBarIcon.png
├── Info.plist
└── MiddleScroller.entitlements
```

## Scroll Behavior Specification

### Activation
1. User presses middle mouse button
2. Anchor point is set at current cursor position
3. Anchor indicator overlay appears at cursor position
4. Scroll mode is active

### During Scroll Mode
1. Track mouse movement relative to anchor point
2. Calculate scroll vector: `(currentPosition - anchorPosition)`
3. Apply dead zone: If distance < threshold (e.g., 10px), no scroll
4. Calculate scroll speed: `distance * speedMultiplier`
5. Inject scroll events at regular interval (e.g., 60Hz)
6. Scroll direction matches mouse direction from anchor

### Deactivation
1. User presses middle mouse button again
2. Stop scroll event injection
3. Hide anchor indicator overlay
4. Return to normal mouse behavior

## Anchor Indicator Design (Windows-Style)
- Circular indicator (~40px diameter)
- Semi-transparent background
- Four directional arrows (up, down, left, right)
- Center dot or circle
- Arrows indicate available scroll directions

## Version History
| Version | Date | Changes |
|---------|------|---------|
| 0.1.0   | TBD  | Initial implementation |

## Success Criteria
- [ ] Application runs in menu bar without dock icon
- [ ] Middle-click activates/deactivates scroll mode
- [ ] Scrolling works in all applications
- [ ] Visual anchor indicator displays correctly
- [ ] Settings persist between launches
- [ ] Launch at login works correctly
- [ ] Accessibility permissions handled gracefully
